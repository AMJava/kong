return {
  fields = {
    retry_count = {type = "number", default = 10},
    queue_size = {type = "number", default = 1000},
    flush_timeout = {type = "number", default = 2},
    log_bodies = {type = "boolean", default = false},
    connection_timeout = {type = "number", default = 30},
    endpoint = {type = "string", required = true, default = "http://"},
    https_verify = {type = "boolean", default = false}
  }
}
