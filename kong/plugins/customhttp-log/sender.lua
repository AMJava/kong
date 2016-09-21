local cjson = require "cjson"
local url = require "socket.url"

local _M = {}

function _M:add_entry(_ngx, req_body_str, resp_body_str)
  if not self.entries then
    return nil, "no entries table"
  elseif not _ngx then
    return nil, "arg #1 (_ngx) must be given"
  elseif req_body_str ~= nil and type(req_body_str) ~= "string" then
    return nil, "arg #2 (req_body_str) must be a string"
  elseif resp_body_str ~= nil and type(resp_body_str) ~= "string" then
    return nil, "arg #3 (resp_body_str) must be a string"
  end
  
  return true
end
