-- debug模式下，用于展示错误定位信息，方便排查问题
local constants = require "constants"
-- local cjson = require "cjson"

local _M = {}

_M._VERSION = "1.0.0"

local mt = { __index = _M }

function _M.print_debug_info(err)
    local headers = ngx.req.get_headers()
    ngx.header.content_type = 'text/html;charset=utf-8';
    local ng_status = tonumber((ngx.var.upstream_status ~= nil and ngx.var.upstream_status ~= '-') and ngx.var.upstream_status or ngx.status)
    ngx.status = ng_status
    ngx.say("<html><head><title>接入服务debug信息</title>")
    ngx.say("<script>function copy(){var input=document.getElementById('debugInfo');try{input.select();	if (document.execCommand('copy')) {document.execCommand('copy');alert('复制成功');}else{alert('复制失败，请手动复制');}} catch(e){alert('复制失败，请手动复制');}}</script>")
    ngx.say("</head><body><div style='width:60%;margin:auto;background:#9ad1f9;padding:20px;'>")
    ngx.say("<h3 style='color:#fff;'>Error: " .. tostring((ngx.var.upstream_status ~= nil and ngx.var.upstream_status ~= '-') and ngx.var.upstream_status or ngx.status) .. ",  Debug信息</h3>")
    ngx.say("<textarea id='debugInfo' style='border:none;width:100%;min-height:300px;'>")
    -- 先判断是否op层请求中断
    if headers["x-sal-site-error"] ~= nil then
        ngx.say("op层出错,请求中断，请查看接入层日志,错误信息" .. headers["x-sal-site-error"]);
    else
        -- 此处增加根据应用判断 根据不同应用的站点 提示联系不同联系人
        -- 当响应头没有网关报错头x-sal-gateway-route-error时，说明为后端业务报错 联系应用联系人 否则联系接入层联系人
        if headers["x-sal-site-appId"] ~= nil then
            if headers["x-sal-site-appId"] == 'error' then
                ngx.say("站点所属应用的应用id不存在！！！！！");
                ngx.say("请检查站点所属应用是否正确  应用是否不存在！！！！！");
            else
                if headers["x-sal-gateway-route-error"] ~= nil then
                    ngx.log(ngx.ERR, "网关gateway报错:请联系接入层负责人")
                    ngx.say("...................>> 网关gateway报错:请联系接入层负责人" .. constants.ACCESS_CONTACT);
                    ngx.say("...................>> 网关gateway报错信息:请联系接入层负责人" .. headers["x-sal-gateway-route-error"]);
                else
                    ngx.log(ngx.ERR, "后端系统报错:请联系业务应用联系人")
                    local appId = headers["x-sal-site-appId"];
                    local appContact = "";
                    for _, v in ipairs(app_info.data) do
                        if v["applicationId"] == appId then
                            appContact = v["appContact"]
                        end
                    end
                    ngx.say("...................>> 后端系统报错:请联系业务应用联系人" .. appContact);
                end
            end
        else
            ngx.log(ngx.ERR, "站点未匹配，请检查站点配置！！！！！")
            ngx.say("站点未匹配，请检查站点配置！！！！！");
            ngx.say("请登录中枢平台，站点模块，检查站点配置！！！！！");
        end
    end

    if ngx.var.upstream_status ~= nil or ngx.ctx.ups ~= nil then
        ngx.say((headers["x-sal-err-trace"] ~= nil and headers["x-sal-err-trace"] or ""))
        ngx.say("...................>> upstream响应时间:" .. tostring(ngx.var.upstream_response_time ~= nil and ngx.var.upstream_response_time or ngx.ctx.upt))
        ngx.say("...................>> upstream响应状态码:" .. tostring((ngx.var.upstream_status ~= nil and ngx.var.upstream_status ~= '-') and ngx.var.upstream_status or ngx.status))
    else
        ngx.say((headers["x-sal-err-trace"] ~= nil and headers["x-sal-err-trace"] or ""))
    end
    if err ~= nil then
        ngx.say(err)
    end
    ngx.say("</textarea><button onclick='copy()'>拷贝错误信息</button>")
    ngx.say("</div>")
    ngx.say("</body></html>")
    return ngx.exit(ng_status)
end

return _M
