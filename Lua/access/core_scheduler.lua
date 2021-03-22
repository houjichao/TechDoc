---
--- 核心调度器 要加入到 nginx 的 init_worker_by_lua_file配置
---
local access_config_refresher = require "access_config_refresher"
local app_config_refresher = require "app_config_refresher"
local constants = require "constants"

-- 刷新接入层配置的调度器
local ok, err = ngx.timer.at(constants.CONFIG_REFRESH_INTERVAL, access_config_refresher.handler)
if not ok then
    ngx.log(ngx.ERR, "failed to create the access config refresh timer: ", err)
end

-- 刷新网关paasid和paastoken信息的调度器
local ok, err = ngx.timer.at(constants.APP_REFRESH_INTERVAL, app_config_refresher.handler)
if not ok then
    ngx.log(ngx.ERR, "failed to create the app config refresh timer: ", err)
end

-- worker作用域下的lrucache
local lrucache = require "resty.lrucache"
local local_ngx_lru_cache, err = lrucache.new(1000)
if not local_ngx_lru_cache then
    ngx.log(ngx.CRIT, "failed to create the ngx lru cache: " .. (err or "unknown"))
else
    ngx_lru_cache = local_ngx_lru_cache
end

