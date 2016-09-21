local basic_serializer = require "kong.plugins.log-serializers.basic"
local BasePlugin = require "kong.plugins.base_plugin"
local cjson = require "cjson.safe"
local url = require "socket.url"

--Extend Base Plugin
local CustomHttpLogHandler = BasePlugin:extend()

--Set Priority
CustomHttpLogHandler.PRIORITY = 1

--set global variables
local HTTPS = "https"
local resp_get_headers = ngx.resp.get_headers
local req_start_time = ngx.req.start_time
local req_get_method = ngx.req.get_method
local req_get_headers = ngx.req.get_headers
local req_get_uri_args = ngx.req.get_uri_args
local req_raw_header = ngx.req.raw_header
local encode_base64 = ngx.encode_base64
local http_version = ngx.req.http_version

local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local os_date = os.date
local gsub = string.gsub

--request structure
entries = {}

-- Generates http payload .
-- @param `method` http method to be used to send data
-- @param `parsed_url` contains the host details
-- @param `message`  Message to be logged
-- @return `body` http payload
local function generate_post_payload(method, parsed_url, body)
  ngx.log(ngx.ERR, "Error "..tostring(body)..": ", "")
  return string.format(
    "%s %s HTTP/1.1\r\nHost: %s\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: %s\r\n\r\n%s",
    method:upper(), parsed_url.path, parsed_url.host, string.len(body), body)
end

-- Parse host url
-- @param `url`  host url
-- @return `parsed_url`  a table with host details like domain name, port, path etc
local function parse_url(host_url)
  local parsed_url = url.parse(host_url)
  if not parsed_url.port then
    if parsed_url.scheme == "http" then
      parsed_url.port = 80
     elseif parsed_url.scheme == HTTPS then
      parsed_url.port = 443
     end
  end
  if not parsed_url.path then
    parsed_url.path = "/"
  end
  return parsed_url
end

--Hash to array
local function hash_to_array(t)
  local arr = setmetatable({}, cjson.empty_array_mt)
  for k, v in pairs(t) do
    if type(v) == "table" then
      for i = 1, #v do
        arr[#arr+1] = {name = k, value = v[i]}
      end
    else
      arr[#arr+1] = {name = k, value = v}
    end
  end
  return arr
end

--Get Header fields
local function get_header(t, name, default)
  local v = t[name]
  if not v then
    return default
  elseif type(v) == "table" then
    return v[#v]
  end
  return v
end

--Create request method
local function create_req(log_bodies,req_body_str,resp_body_str)
  local http_version = "HTTP/"..http_version()
  
  local post_data, response_content
  local req_body_size, resp_body_size = 0, 0
  
  --Get Request header info
  local request_headers = req_get_headers()
  local request_content_len = get_header(request_headers, "content-length", 0)
  local request_transfer_encoding = get_header(request_headers, "transfer-encoding")
  local request_content_type = get_header(request_headers, "content-type",
                                          "application/octet-stream")

  local req_has_body = tonumber(request_content_len) > 0
                       or request_transfer_encoding ~= nil
                       or request_content_type == "multipart/byteranges"
  
  --Get Response header info
  local resp_headers = resp_get_headers()
  local resp_content_len = get_header(resp_headers, "content-length", 0)
  local resp_transfer_encoding = get_header(resp_headers, "transfer-encoding")
  local resp_content_type = get_header(resp_headers, "content-type",
                            "application/octet-stream")

  local resp_has_body = tonumber(resp_content_len) > 0
                        or resp_transfer_encoding ~= nil
                        or resp_content_type == "multipart/byteranges"     

--Decide to log body or not
 if log_bodies then
    ngx.log(ngx.ERR, "TEST1", "")
    if req_body_str then
      ngx.log(ngx.ERR, "TEST2", "")
      req_body_size = #req_body_str
      post_data = {
        text = encode_base64(req_body_str),
        encoding = "base64",
        mimeType = request_content_type
      }
   end
      if resp_body_str then
        ngx.log(ngx.ERR, "TEST3", "")
      resp_body_size = #resp_body_str
      response_content = {
        text = encode_base64(resp_body_str),
        encoding = "base64",
        mimeType = resp_content_type
      }
    end
end                  
                       
  -- timings
  local send_t = ngx.ctx.KONG_PROXY_LATENCY or 0
  local wait_t = ngx.ctx.KONG_WAITING_TIME or 0
  local receive_t = ngx.ctx.KONG_RECEIVE_TIME or 0
  local idx = 1                   

  -- main request
  entries[idx] = {
    time = send_t + wait_t + receive_t,
    startedDateTime = os_date("!%Y-%m-%dT%TZ", req_start_time()),
    clientIPAddress = ngx.var.remote_addr,
    request = {
      httpVersion = http_version,
      method = req_get_method(),
      url = ngx.var.scheme .. "://" .. ngx.var.host .. ngx.var.request_uri,
      queryString = hash_to_array(req_get_uri_args()),
      headers = hash_to_array(request_headers),
      headersSize = #req_raw_header(),
      bodyCaptured = req_has_body,
      bodySize = req_body_size,
      postData = post_data,
    },
    response = {
      status = ngx.status,
      statusText = "",
      httpVersion = http_version,
      headers = hash_to_array(resp_headers),
      headersSize = 0,
      bodyCaptured = resp_has_body,
      bodySize = resp_body_size,
      content = response_content
    },
    timings = {
      send = send_t,
      wait = wait_t,
      receive = receive_t
    }
  }                       
  return entries[idx]
end

-- Log to a Http end point.
-- @param `premature`
-- @param `conf`     Configuration table, holds http endpoint details
-- @param `message`  Message to be logged
local function log(premature, conf, body, name)
  if premature then return end
  name = "["..name.."] "
  
  local ok, err
  local parsed_url = parse_url(conf.http_endpoint)
  local host = parsed_url.host
  local port = tonumber(parsed_url.port)

  local sock = ngx.socket.tcp()
  sock:settimeout(conf.timeout)

  ok, err = sock:connect(host, port)
  if not ok then
    ngx.log(ngx.ERR, name.."failed to connect to 111"..host..":"..tostring(port)..": ", err)
    return
  end

  if parsed_url.scheme == HTTPS then
    local _, err = sock:sslhandshake(true, host, false)
    if err then
      ngx.log(ngx.ERR, name.."failed to do SSL handshake with "..host..":"..tostring(port)..": ", err)
    end
  end

  ok, err = sock:send(generate_post_payload(conf.method, parsed_url, body))
  if not ok then
    ngx.log(ngx.ERR, name.."failed to send data to "..host..":"..tostring(port)..": ", err)
  end

  ok, err = sock:setkeepalive(conf.keepalive)
  if not ok then
    ngx.log(ngx.ERR, name.."failed to keepalive to "..host..":"..tostring(port)..": ", err)
    return
  end
end

-- Only provide `name` when deriving from this class. Not when initializing an instance.
function CustomHttpLogHandler:new(name)
  CustomHttpLogHandler.super.new(self, name or "http-log")
end

--Needed to get request body
function CustomHttpLogHandler:access(conf)
  CustomHttpLogHandler.super.access(self)

  if not _server_addr then
    _server_addr = ngx.var.server_addr
  end

  if conf.log_bodies then
    read_body()
    ngx.ctx.customhttp = {req_body = get_body_data()}
  end
end

--Needed to get response body
function CustomHttpLogHandler:body_filter(conf)
  CustomHttpLogHandler.super.body_filter(self)

  if conf.log_bodies then
    local chunk = ngx.arg[1]
    local ctx = ngx.ctx
    local res_body = ctx.customhttp and ctx.customhttp.res_body or ""
    res_body = res_body .. (chunk or "")
    ctx.customhttp.res_body = res_body
  end
end

--Convert request to json object
function serialize(request)
  local json = cjson.encode(request)
  return gsub(json, "\\/", "/")
end

--Executed when the last response byte has been sent to the client.
function CustomHttpLogHandler:log(conf)
  local ctx = ngx.ctx
  CustomHttpLogHandler.super.log(self)
  local req_body, res_body
  if ctx.customhttp then
    req_body = ctx.customhttp.req_body
    res_body = ctx.customhttp.res_body
  end
  local request = create_req(conf.log_bodies,req_body,res_body)
  local ok, err = ngx.timer.at(0, log, conf, serialize(request), self._name)
  if not ok then
    ngx.log(ngx.ERR, "["..self._name.."] failed to create timer: ", err)
  end
end

return CustomHttpLogHandler
