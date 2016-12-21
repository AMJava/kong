local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.oauth2.access"

local OAuthHandler = BasePlugin:extend()

function OAuthHandler:new()
  OAuthHandler.super.new(self, "oauth2")
end

function OAuthHandler:access(conf)
  OAuthHandler.super.access(self)
  ngx.log(ngx.ERR, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA: "..ngx.ctx.api.request_path, "")
  ngx.log(ngx.ERR, "BBBBBBBBBBBBBBBBBBBBBBBBBBBBB: "..ngx.var.request_uri, "")
  ngx.log(ngx.ERR, "CCCCCCCCCCCCCCCCCCCCCCCCCCCC: "..ngx.ctx.api.request_path, "")
  ngx.log(ngx.ERR, "DDDDDDDDDDDDDDDDDDDDDDDDDDD: "..ngx.ctx.api.request_path, "")
  access.execute(conf)
end

OAuthHandler.PRIORITY = 1000

return OAuthHandler
