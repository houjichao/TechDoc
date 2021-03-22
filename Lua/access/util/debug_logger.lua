-- 通过header传递请求链的debug信息

local _M = {}
local mt = {__index = _M}

_M._VERSION = "1.0.0"

function _M.log(line)
    if line~=nil then
        ngx.req.set_header("x-sal-err-trace",(ngx.req.get_headers()["x-sal-err-trace"]~=nil and ngx.req.get_headers()["x-sal-err-trace"].."&#10;" or "") .."...................>> ".. line)
    end
end

return _M