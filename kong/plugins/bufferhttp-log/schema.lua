local function check_mandatory_scope(v, t)
  if not v and t.secure_message then
    return false, "To secure message you also need to add secure patterns"
  end
  return true
end

return {
  fields = {
    retry_count = {type = "number", default = 10},
    queue_size = {type = "number", default = 1000},
    queue_size_mb = {type = "number", default = 20},
    max_msg_size_mb = {type = "number", default = 2},
    max_sending_queue_size_mb = {type = "number", default = 200},
    flush_timeout = {type = "number", default = 2},
    log_bodies = {type = "boolean", default = false},
    connection_timeout = {type = "number", default = 30},
    endpoint = {type = "string", required = true, default = "http://"},
    secure_message = {type = "boolean", default = false},
    secure_patterns = {type = "array", default = { "(assword':)'(.-)'", "(token':)'(.-)'"}, func = check_mandatory_scope },
    https_verify = {type = "boolean", default = false}
  }
}
