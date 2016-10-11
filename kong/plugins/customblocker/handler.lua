-- Buffers request/response bodies if asked so in the plugin's config.
-- Caches the server's address to avoid further syscalls.
--
-- Maintains one ALF Buffer per bufferhttp plugin per worker.

local BasePlugin = require "kong.plugins.base_plugin"
local Buffer = require "kong.plugins.bufferhttp-log.buffer"

local read_body = ngx.req.read_body
local get_body_data = ngx.req.get_body_data
local req_set_header = ngx.req.set_header
local req_get_headers = ngx.req.get_headers
local uuid = require("kong.tools.utils").uuid

local _alf_buffers = {} -- buffers per-api

local BufferHTTPHandler = BasePlugin:extend()

function BufferHTTPHandler:new()
  BufferHTTPHandler.super.new(self, "bufferhttp-log")
end

function BufferHTTPHandler:access(conf)
  BufferHTTPHandler.super.access(self)

end

function BufferHTTPHandler:body_filter(conf)
  BufferHTTPHandler.super.body_filter(self)

end

function BufferHTTPHandler:log(conf)
  BufferHTTPHandler.super.log(self)

end

return BufferHTTPHandler
