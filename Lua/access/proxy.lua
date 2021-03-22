--- 实现简易proxy_pass
local http = require "lualib.resty.http"
local reflection_util = require "util.reflection_util"
require "util.string_helper"
local str = require "resty.string"
local resty_sha256 = require "resty.sha256"
local httpc = http.new()
local debug_util = require ".debug"
--local server = require "resty.websocket.server"
--local client = require "resty.websocket.client"
local backend = ngx.var.backend


--local wb,wbc
--local function ws_client()
--    while true do
--        local data, typ, err = wbc:recv_frame()
--    ngx.log(ngx.ERR,"backend data:",data)
--        local _type,_err 		=	''
--        if wbc.fatal then
--            _type	=	'fatal'
--            ngx.log(ngx.ERR," failed to receive frame: ", err)
--            break
--        end
--        local timeout 	=	false
--        if ( err and  string.sub(err,-7) =='timeout') then
--            timeout	=	true
--        end
--        if not err or timeout==false  then
--            ngx.log(ngx.CRIT,typ,",data: ", data,',err: ',err)
--        end
--        _type	=	typ
--        if timeout==true then
--        end
--        if typ == "close" then
--            ngx.log(ngx.ERR,typ, ",data:", data,',err:',err)
--            break
--        elseif typ == "text" then
--            wb:send_text(data)
--        elseif typ == 'ping' then
--            wb:send_ping('')
--        elseif typ == 'pong' then
--            wb:send_pong()
--        elseif typ == 'continuation' then
--        elseif typ == 'binary' then
--
--        end
--    end
--    wb:close()
--end
--
--local backend = ngx.var.backend
--local is_upgrade = ngx.req.get_headers()["connection"]
--if is_upgrade == "Upgrade" then
--    wb, err = server:new {
--        timeout = 5000,
--        max_payload_len = 65535,
--    }
--    if not wb then
--        ngx.log(ngx.ERR, "failed to new websocket: ", err)
--        ngx.exit(444)
--    else
--        local ws_uri = "ws://" .. backend.."/"
--    ngx.log(ngx.ERR,"ws_uri:",ws_uri)
--        wbc, errc = client:new()
--        local ok, err = wbc:connect(ws_uri)
--        if not ok then
--            ngx.log(ngx.ERR, "failed to connect: ", err)
--            return
--        end
--
--        local t2 = ngx.thread.spawn(ws_client)
--        local _type,_err 		=	''
--        while true do
--            local data, typ, err = wb:recv_frame()
--            if wb.fatal then
--                _type	=	'fatal'
--                ngx.log(ngx.ERR," failed to receive frame: ", err)
--                break
--            end
--            local timeout 	=	false
--            if ( err and  string.sub(err,-7) =='timeout') then
--                timeout	=	true
--            end
--            if not err or timeout==false  then
--                ngx.log(ngx.CRIT,typ,",data: ", data,',err: ',err)
--            end
--            _type	=	typ
--            if timeout==true then
--            end
--            if typ == "close" then
--                ngx.log(ngx.ERR,typ, ",data:", data,',err:',err)
--                break
--            elseif typ == "text" then
--
--                wbc:send_text(data)
--                ngx.log(ngx.ERR,"success send to backend.")
--            elseif typ == 'ping' then
--                wbc:send_ping('')
--            elseif typ == 'pong' then
--                wbc:send_pong()
--            elseif typ == 'continuation' then
--            elseif typ == 'binary' then
--
--            end
--
--        end
--
--        ngx.log(ngx.CRIT,'typ:',_type,',logout')
--        wbc:close()
--        ngx.thread.wait(t2)
--    end
--end



local debug = false
if config_info ~= nil and config_info["debug"] ~= nil then
    debug = "true" == tostring(config_info["debug"])
end
local connect_timeout = ngx.ctx.connect_timeout
local proxy_timeout = ngx.ctx.proxy_timeout

-- 设置转发超时
httpc:set_timeouts(connect_timeout ~= nil and tonumber(connect_timeout) * 1000 or nil, nil, proxy_timeout ~= nil and tonumber(proxy_timeout) * 1000 or nil)
if backend == nil then
    backend = ngx.ctx.backend
end
if backend == nil or string.len(backend) < 1 or backend == "default" then
    ngx.header.content_type = 'text/html;charset=utf-8';
    ngx.status = 404
    if debug then
        debug_util.print_debug_info()
    end
    ngx.print("<div style='width:270px;margin:auto;padding-top:30px;font-size:18px;'><h3>HTTP 404</h3><br/>Powered by tgac接入服务~</div>")
    return
end
local host_and_port = string.split(backend, ":")
local host = host_and_port[1]
local port
if #host_and_port == 1 then
    port = 80
else
    port = tonumber(host_and_port[2])
end
local ok, err = httpc:connect(host, port)
if not ok then
    ngx.log(ngx.ERR, err)
    ngx.header.content_type = 'text/html;charset=utf-8';
    ngx.status = 500
    if debug then
        debug_util.print_debug_info(err)
    end
    return
end

if string.startWith(ngx.var.request_uri, "/ebus/") then
    -- 如果是api网关请求 进行签名
    local sha256 = resty_sha256:new()
    local ts = tostring(os.time())
    local nonce = string.random_string(10)
    sha256:update(ts .. ngx.ctx.paas_token .. nonce .. ts)
    local signature = str.to_hex(sha256:final())
    ngx.req.set_header("x-rio-signature", signature)
    ngx.req.set_header("x-rio-timestamp", ts)
    ngx.req.set_header("x-rio-nonce", nonce)
end

local t1 = ngx.now()
-- todo 缓存静态站点请求
local resp, err = httpc:proxy_request()
if debug then
    ngx.ctx.upt = tostring(ngx.now() - t1)
end
if err then
    ngx.log(ngx.ERR, err)
    ngx.header.content_type = 'text/html;charset=utf-8';
    ngx.status = 500
    if debug then
        debug_util.print_debug_info(err)
    end
    return
end
ngx.status = resp.status
ngx.ctx.ups = resp.status
local status = math.modf(resp.status / 100)
if status ~= 2 and status ~= 1 then
    ngx.header.content_type = 'text/html;charset=utf-8';
    if debug then
        debug_util.print_debug_info()
    end
    ngx.print("<div style='width:270px;margin:auto;padding-top:30px;font-size:18px;'><h3>HTTP ", ngx.status, "</h3><br/>Powered by tgac接入服务~</div>")
    httpc:set_keepalive()
    return
end
httpc:proxy_response(resp)
httpc:set_keepalive()
