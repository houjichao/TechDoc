-- 以简单页面形式输出警告信息

local _M = {}
_M._VERSION = '1.0.0'

local mt = {__index = _M }

function _M:alert(msg)
    ngx.status = ngx.HTTP_GONE
    ngx.header.content_type = 'text/plain;charset=utf-8';
    ngx.say(msg)
    return ngx.exit(200)
end


return _M

