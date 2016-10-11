local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

--Extend Base Plugin
local Mocker = BasePlugin:extend()

--Set Priority
Mocker.PRIORITY = 1

function Mocker:new()
  Mocker.super.new(self, "mocker")
end

function Mocker:access(conf)
  Mocker.super.access(self)
  
  if conf.block_entry then
    responses.send_HTTP_FORBIDDEN("This service is not available right now")
  end

end

function Mocker:body_filter(conf)
  Mocker.super.body_filter(self)

end

function Mocker:log(conf)
  Mocker.super.log(self)

end

return Mocker
