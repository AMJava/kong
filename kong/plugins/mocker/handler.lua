
local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

local cjson = require "cjson"
local meta = require "kong.meta"
local req_get_uri_args = ngx.req.get_uri_args
local ngx_log = ngx.log

--local server_header = _KONG._NAME.."/".._KONG._VERSION
local server_header = meta._NAME.."/"..meta._VERSION

--Extend Base Plugin
local Mocker = BasePlugin:extend()

--Set Priority
Mocker.PRIORITY = 1

local function send_response(status_code,content, contentTypeJson,transformMessage)
    ngx.status = status_code
    if contentTypeJson == "application/json; charset=utf-8" then
     ngx.header["Content-Type"] = "application/json; charset=utf-8"
    else
    ngx.header["Content-Type"] = "text/html; charset=UTF-8"    
    end
    
    ngx.header["Server"] = server_header
  
    if contentTypeJson == "application/json; charset=utf-8" and transformMessage then
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
  local errorMessage = "Default Mock JSON Message"
  local contentType = "application/json; charset=utf-8"
  local transformMessage = true
    
  if conf.use_url_params and type(conf.use_url_params) == "boolean" then
    local queryParams = req_get_uri_args()
    local url = ngx.ctx.upstream_url
    local pathIndex = url:find('[^/]/[^/]')
    local path = url:sub(pathIndex + 1)    
		
    local mockValue = {}
    local queryNameMAP = {} 
    local queryValueMAP = {}

    local queryName = ""
    local queryValue = ""
    local mockName = ""
    local loopHelper = false
    local isMatched = false
    local queryParamsCount = 0
    local mapParamsCount = 0
    local queryMapStructure = {}
		
    if conf.mock_name_mapping == nil then
        queryNameMAP = {['?mock1=mock1&mock2=mock2']='mock1',['/product']='mock2'}
    else
        queryNameMAP = loadstring("return "..conf.mock_name_mapping)()
    end
    if conf.mock_value_mapping == nil then
        queryValueMAP = {['mock1']={['code']=404,['contentType']='application/json; charset=utf-8',['message']='{\"message\":\"Default Mock JSON Message\"}'}}
    else
        queryValueMAP = loadstring("return "..conf.mock_value_mapping)()
    end
 
    if queryParams ~= nil or path then
         for keyMAP, valMAP in pairs(queryNameMAP) do
		if type(keyMAP) == "string" then
			ngx.log(ngx.ERR, "TEST 02 "..path,"")
			if string.sub(keyMAP, 0, 1) == "?" then
				ngx.log(ngx.ERR, "TEST 1 ","")
			elseif string.sub(keyMAP, 0, 1) == "/" then
				if path and keyMAP == path then
				isMatched == true
				break
			end
		end
         end
	
    end
		
	if mockName then
	  mockValue = queryValueMAP[mockName]
	end
	
     if mockValue then
	      if mockValue["code"] then
		errorCode = mockValue["code"]
	      end
	      if mockValue["message"] then
		transformMessage = false
		errorMessage = mockValue["message"]
	      end
	       if mockValue["contentType"] then
		contentType = mockValue["contentType"]
	      end
    end       
  else
      if conf.error_code and type(conf.error_code) == "number" then
          errorCode = conf.error_code
      end

      if type(conf.content_type_json) == "boolean" and conf.content_type_json == false then
          contentType = "text/html; charset=UTF-8"
      end

      if conf.error_message and type(conf.error_message) == "string" then
          errorMessage = conf.error_message
      end
  end
    
  send_response(errorCode, errorMessage,contentType,transformMessage)

end

function Mocker:body_filter(conf)
  Mocker.super.body_filter(self)

end

function Mocker:log(conf)
  Mocker.super.log(self)

end

return Mocker
