-- debug模式下，用于展示错误定位信息，方便排查问题

local debug_util = require ".debug"

local debug = false
if config_info ~= nil and config_info["debug"] ~= nil then
    debug = "true" == tostring(config_info["debug"])
end

if debug then
    debug_util.print_debug_info()
else
    ngx.header.content_type = 'text/html;charset=utf-8';
    if ngx.upstream_status ~= nil and ngx.upstream_status ~= "-" then
        ngx.status = ngx.upstream_status
    end
    ngx.print("<div style='width:270px;margin:auto;padding-top:30px;font-size:18px;'><h3>HTTP ", ngx.status, "</h3><br/>Powered by tgac接入服务~</div>")
end
