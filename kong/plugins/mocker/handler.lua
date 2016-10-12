local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

local cjson = require "cjson"
local meta = require "kong.meta"

--local server_header = _KONG._NAME.."/".._KONG._VERSION
local server_header = meta._NAME.."/"..meta._VERSION

--Extend Base Plugin
local Mocker = BasePlugin:extend()

--Set Priority
Mocker.PRIORITY = 1

local function send_response(status_code,content, headers)
    ngx.status = status_code
    ngx.header["Content-Type"] = "application/json; charset=utf-8"
    ngx.header["Server"] = server_header
  
    if headers then
      for k, v in pairs(headers) do
        ngx.header[k] = v
      end
    end

    if type(content) == "table" then
      ngx.say(cjson.encode(content))
    elseif content then
      ngx.say(cjson.encode {message = content})
    end

    return ngx.exit(status_code)
end

function Mocker:new()
  Mocker.super.new(self, "mocker")
end

function Mocker:access(conf)
  Mocker.super.access(self)
  
  local errorCode = 403
  local errorMessage = "This service is not available right now"
  local headers = {}
  headers["Content-Type"]= "text/html; charset=UTF-8"
  
  if conf.error_code and type(conf.error_code) == "number" then
      errorCode = conf.error_code
  end

  if conf.error_message and type(conf.error_message) == "string" then
      errorMessage = conf.error_message
  end

  send_response(errorCode, errorMessage,headers)

end

function Mocker:body_filter(conf)
  Mocker.super.body_filter(self)

end

function Mocker:log(conf)
  Mocker.super.log(self)

end

return Mocker
