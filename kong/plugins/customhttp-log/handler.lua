local BasePlugin = require "kong.plugins.base_plugin"
local sender = require "kong.plugins.customhttp-log.sender"

local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data

local CustomHttpLogHandler = BasePlugin:extend()

CustomHttpLogHandler.PRIORITY = 1

function CustomHttpLogHandler:new(name)
  CustomHttpLogHandler.super.new(self, name or "customhttp-log")
end

function CustomHttpLogHandler:access(conf)
  CustomHttpLogHandler.super.access(self)

  if conf.log_bodies then
    read_body()
    ngx.ctx.galileo = {req_body = get_body_data()}
  end
end

function CustomHttpLogHandler:body_filter(conf)
  CustomHttpLogHandler.super.body_filter(self)

  if conf.log_bodies then
    local chunk = ngx.arg[1]
    local ctx = ngx.ctx
    local res_body = ctx.galileo and ctx.galileo.res_body or ""
    res_body = res_body .. (chunk or "")
    ctx.galileo.res_body = res_body
  end
end

function CustomHttpLogHandler:log(conf)
  CustomHttpLogHandler.super.log(self)
  
    local ctx = ngx.ctx
    
    local req_body, res_body
    if ctx.galileo then
      req_body = ctx.galileo.req_body
      res_body = ctx.galileo.res_body
    end
    
    sender.add_entry(ngx, req_body, res_body)
end

return CustomHttpLogHandler
