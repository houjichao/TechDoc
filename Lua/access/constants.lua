-- 常量

local _M = {}
_M._VERSION = '1.0.0'

local mt = { __index = _M }

-- 接入层后端地址
_M.ACC_BACKENDS = {
    { host = "127.0.0.1", port = "{access_port}" },
    { host = "127.0.0.1", port = "{access_port}" }
}

-- redis地址
_M.REDIS_HOST = "{redis_host}"
_M.REDIS_PORT = {redis_port}
_M.REDIS_AUTH = "{redis_password}"

-- 从接入层拉取配置信息的接口url
_M.GET_CONFIG_URI = "{access_path}/config/get"

-- 从接入层拉取app信息的接口url
_M.GET_APP_URI = "{access_path}/access/admin/app/list"

_M.SAL_API_KEY = "sal_api"

-- 接入层配置信息刷新频率 单位秒
_M.CONFIG_REFRESH_INTERVAL = 5

-- app信息刷新频率 单位秒
_M.APP_REFRESH_INTERVAL = 3

_M.CONFIG_SHARE_KEY = "config"

-- 配置信息过期时间5分钟
_M.CONFIG_EXPIRE = 300

-- waf日志存放redis的key名
_M.SAL_WAF_LOG_KEY = "waf_log"
-- 最多保存最近10000条waf日志
_M.MAX_WAF_LOG_KEEP_NUMS = 10000

-- 当前登录用户的idset key
_M.USER_ID_SET_KEY = "local_gasc_user_ids"
_M.SESSION_KEY = "{session_cookie_key}:sessions:"
_M.TOKEN_KEY = "{spring_tokens_key}"

--接入层联系人
_M.ACCESS_CONTACT = "广州 chaozzhang 西安 monkeyhu"


-- Waf相关配置
_M.RULE_PATH = "{sal_home}/nginx/access/waf_rules"
_M.ATTACK_LOG_ENABLE = "on"
_M.ATTACK_LOG_DIR = "{sal_home}/nginx/access"
_M.URL_DENY = "on"
_M.PATH_INfO_FIX = "on"
_M.REDIRECT = "on"
_M.COOKIE_MATCH = "on"
_M.POST_MATCH = "on"
_M.WHITE_MODULE = "on"
_M.BLACK_FILE_EXT = { "asp", "php", "jsp" }
_M.IP_WHITE_LIST = {}
_M.IP_BLOCK_LIST = { "1.0.0.1" }
_M.CC_DENY = "off"
_M.CC_RATE = "10000/5000"
_M.SEC_MSG_HTML = [[
<html xmlns="http://www.w3.org/1999/xhtml"><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>接入服务安全提示</title>
<style>
p {
	line-height:20px;
}
ul{ list-style-type:none;}
li{ list-style-type:none;}
</style>
</head>

<body style=" padding:0; margin:0; font:14px/1.5 Microsoft Yahei, 宋体,sans-serif; color:#555;">

  <div style="width:60%;margin:auto;background:#9ad1f9;padding:20px;">
    <h3 style="color:#fff;">接入服务安全提示 </h3>
    <div style="font-size:14px; background:#fff; color:#555; line-height:24px; height:220px; padding:20px 20px 0 20px; overflow-y:auto;">
      <p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;"><span style=" font-weight:600; color:#fc4f03;">您的请求带有不合法参数，已被网站管理员设置拦截！</span></p>
<p style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">可能原因：您提交的内容包含危险的攻击请求</p>
<p style=" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:1; text-indent:0px;">如何解决：</p>
<ul style="margin-top: 0px; margin-bottom: 0px; margin-left: 0px; margin-right: 0px; -qt-list-indent: 1;"><li style=" margin-top:12px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">1）检查提交内容；</li>
<li style=" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;">3）普通网站访客，请联系网站管理员；</li></ul>
    </div>
</div>
</body></html>
]]

return _M