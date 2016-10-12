local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

local cjson = require "cjson"
local meta = require "kong.meta"
local req_get_uri_args = ngx.req.get_uri_args
local ERR = ngx.ERR
local ngx_log = ngx.log

--local server_header = _KONG._NAME.."/".._KONG._VERSION
local server_header = meta._NAME.."/"..meta._VERSION

--Extend Base Plugin
local Mocker = BasePlugin:extend()

--Set Priority
Mocker.PRIORITY = 1

local function send_response(status_code,content, contentTypeJson)
    ngx.status = status_code
    if contentTypeJson then
     ngx.header["Content-Type"] = "application/json; charset=utf-8"
    else
    ngx.header["Content-Type"] = "text/html; charset=UTF-8"    
    end
    
    ngx.header["Server"] = server_header
  
    if contentTypeJson then
        if type(content) == "table" then
          ngx.say(cjson.encode(content))
        elseif content then
          ngx.say(cjson.encode {message = content})
        end
    else
        ngx.say(content)
    end

    ngx.exit(status_code)
end

function Mocker:new()
  Mocker.super.new(self, "mocker")
end

function Mocker:access(conf)
  Mocker.super.access(self)
  
  local errorCode = 403
  local errorMessage = "This service is not available right now"
  local contentTypeJson = true
  local queryValueMAP = {}
    
  if conf.use_query_params and type(conf.use_query_params) == "boolean" then
    ngx_log(ERR, "In query param ", "")
    local querystring = req_get_uri_args()
    local querystringValue = querystring["mock"]
    local mockValue = {}
    
    if querystringValue then
        ngx_log(ERR, "In query param 2", "")
        if conf.query_param_mapping == nil then
            queryValueMAP = {['mock1']={['code']={404},['message']={'{Service is Not Available}'}},['mock2']={['code']={403},['message']={'{<html><h1>Service is Not Available</h1></html>}'}}}
        else
            ngx_log(ERR, "In query param 3", "")
            queryValueMAP = conf.query_param_mapping	
        end
        
        mockValue = queryValueMAP[querystringValue]
        if mockValue then
          local code = mockValue["code"]
          local message = mockValue["message"]
           ngx_log(ERR, "In query param 4"..code, "")
        end
    end
 
        
  else
      if conf.error_code and type(conf.error_code) == "number" then
          errorCode = conf.error_code
      end

      if type(conf.content_type_json) == "boolean" then
          contentTypeJson = conf.content_type_json
      end

      if conf.error_message and type(conf.error_message) == "string" then
          errorMessage = conf.error_message
      end
  end
    
  send_response(errorCode, errorMessage,contentTypeJson)

end

function Mocker:body_filter(conf)
  Mocker.super.body_filter(self)

end

function Mocker:log(conf)
  Mocker.super.log(self)

end

return Mocker
