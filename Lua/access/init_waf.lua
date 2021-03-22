--- 初始化waf相关

local constants = require "constants"
local redis_util = require "util.redis_util"

local match = string.match
--- 使用ngx.re.find替代ngx.re.match 性能好很多
local ngx_find = ngx.re.find
local unescape = ngx.unescape_uri
local get_headers = ngx.req.get_headers
local option_is_on = function(options) return options == "on" and true or false end
local log_path = constants.ATTACK_LOG_DIR
local rule_path = constants.RULE_PATH
local url_deny_open = option_is_on(constants.URL_DENY)
post_check = option_is_on(constants.POST_MATCH)
local cookie_check = option_is_on(constants.COOKIE_MATCH)
local white_check = option_is_on(constants.WHITE_MATCH)
local path_info_fix = option_is_on(constants.PATH_INfO_FIX)
local attack_log = option_is_on(constants.ATTACK_LOG_ENABLE)
local cc_deny = option_is_on(constants.CC_DENY)
local cc_rate = constants.CC_RATE
local redirect = option_is_on(constants.REDIRECT)
local black_file_ext = constants.BLACK_FILE_EXT
local ip_white_list = constants.IP_WHITE_LIST
local ip_block_list = constants.IP_BLOCK_LIST
local sec_msg_html = constants.SEC_MSG_HTML

function get_client_ip()
    local ip = ngx.var.remote_addr
    return ip ~= nil and ip or "unknown"
end

--- log改写到redis中
function write(log_file, msg)
    --    local fd = io.open(log_file,"ab")
    --    if fd == nil then return end
    --    fd:write(msg)
    --    fd:flush()
    --    fd:close()
    local red = redis_util:get_conn()
    local res, err = red:lpush(constants.SAL_WAF_LOG_KEY, msg)
    if not res then
        ngx.log(ngx.ERR, "failed to write log to redis.", err)
    end
    red:ltrim(constants.SAL_WAF_LOG_KEY, 0, constants.MAX_WAF_LOG_KEEP_NUMS-1)
    redis_util:back_to_pool(red, 10000, 30)
end

function log(method, url, data, rule_tag)
    if attack_log then
        local realIp = get_client_ip()
        local ua = ngx.var.http_user_agent
        local servername = ngx.var.server_name
        local time = ngx.localtime()
        local line = ""
        if ua then
            line = realIp .. " [" .. time .. "] \"" .. method .. " " .. servername .. url .. "\" \"" .. data .. "\"  \"" .. ua .. "\" \"" .. rule_tag .. "\"\n"
        else
            line = realIp .. " [" .. time .. "] \"" .. method .. " " .. servername .. url .. "\" \"" .. data .. "\" - \"" .. rule_tag .. "\"\n"
        end
        local filename = log_path .. '/' .. servername .. "_" .. ngx.today() .. "_sec.log"
        write(filename, line)
    end
end


function read_rule(var)
    file = io.open(rule_path .. '/' .. var, "r")
    if file == nil then
        return
    end
    t = {}
    for line in file:lines() do
        table.insert(t, line)
    end
    file:close()
    return (t)
end

url_rules = read_rule('url')
args_rules = read_rule('args')
ua_rules = read_rule('user-agent')
post_rules = read_rule('post')
cookie_rules = read_rule('cookie')


function say_html()
    if redirect then
        ngx.header.content_type = "text/html"
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say(sec_msg_html)
        ngx.exit(ngx.status)
    end
end

function file_ext_check(ext)
    local items = item_set(black_file_ext)
    ext = string.lower(ext)
    if ext then
        for rule in pairs(items) do
            if ngx.re.find(ext, rule, "isjo") then
                log('POST', ngx.var.request_uri, "-", "file attack with ext " .. ext)
                say_html()
            end
        end
    end
    return false
end

function item_set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

function args()
    for _, rule in pairs(args_rules) do
        local args = ngx.req.get_uri_args()
        local data = nil
        for key, val in pairs(args) do
            if type(val) == 'table' then
                local t = {}
                for k, v in pairs(val) do
                    if v == true then
                        v = ""
                    end
                    table.insert(t, v)
                end
                data = table.concat(t, " ")
            else
                data = val
            end
            if data and type(data) ~= "boolean" and rule ~= "" and ngx_find(unescape(data), rule, "isjo") then
                log('GET', ngx.var.request_uri, "-", rule)
                say_html()
                return true
            end
        end
    end
    return false
end


function url()
    if url_deny_open then
        for _, rule in pairs(url_rules) do
            if rule ~= "" and ngx_find(ngx.var.request_uri, rule, "isjo") then
                log('GET', ngx.var.request_uri, "-", rule)
                say_html()
                return true
            end
        end
    end
    return false
end

function ua()
    local ua = ngx.var.http_user_agent
    if ua ~= nil then
        for _, rule in pairs(ua_rules) do
            if rule ~= "" and ngx_find(ua, rule, "isjo") then
                log('UA', ngx.var.request_uri, "-", rule)
                say_html()
                return true
            end
        end
    end
    return false
end

function body(data)
    for _, rule in pairs(post_rules) do
        if rule ~= "" and data ~= "" and ngx_find(unescape(data), rule, "isjo") then
            log('POST', ngx.var.request_uri, data, rule)
            say_html()
            return true
        end
    end
    return false
end

function cookie()
    local ck = ngx.var.http_cookie
    if cookie_check and ck then
        for _, rule in pairs(cookie_rules) do
            if rule ~= "" and ngx_find(ck, rule, "isjo") then
                log('Cookie', ngx.var.request_uri, "-", rule)
                say_html()
                return true
            end
        end
    end
    return false
end

function deny_cc()
    if cc_deny then
        local uri = ngx.var.uri
        local cc_count = tonumber(string.match(cc_rate, '(.*)/'))
        local cc_seconds = tonumber(string.match(cc_rate, '/(.*)'))
        local token = get_client_ip() .. uri
        local limit = ngx.shared.limit
        local req, _ = limit:get(token)
        if req then
            if req > cc_count then
                ngx.exit(503)
                return true
            else
                limit:incr(token, 1)
            end
        else
            limit:set(token, 1, cc_seconds)
        end
    end
    return false
end

function get_boundary()
    local header = get_headers()["content-type"]
    if not header then
        return nil
    end
    if type(header) == "table" then
        header = header[1]
    end
    local m = match(header, ";%s*boundary=\"([^\"]+)\"")
    if m then
        return m
    end
    return match(header, ";%s*boundary=([^\",;]+)")
end

function white_ip()
    if next(ip_white_list) ~= nil then
        for _, ip in pairs(ip_white_list) do
            if get_client_ip() == ip then
                return true
            end
        end
    end
    return false
end

function block_ip()
    if next(ip_block_list) ~= nil then
        for _, ip in pairs(ip_block_list) do
            if get_client_ip() == ip then
                ngx.exit(403)
                return true
            end
        end
    end
    return false
end

ngx.log(ngx.DEBUG, "waf init done")