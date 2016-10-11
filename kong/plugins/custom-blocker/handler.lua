local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

--Extend Base Plugin
local CustomBlocker = BasePlugin:extend()

--Set Priority
CustomBlocker.PRIORITY = 1

function CustomBlocker:new()
  CustomBlocker.super.new(self, "custom-blocker")
end

function CustomBlocker:access(conf)
  CustomBlocker.super.access(self)
  
  if conf.block_entry then
    responses.send_HTTP_FORBIDDEN("This service is not available right now")
  end

end

function CustomBlocker:body_filter(conf)
  CustomBlocker.super.body_filter(self)

end

function CustomBlocker:log(conf)
  CustomBlocker.super.log(self)

end

return CustomBlocker
