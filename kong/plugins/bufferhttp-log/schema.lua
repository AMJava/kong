return {
  fields = {
    retry_count = {type = "number", default = 10},
    queue_size = {type = "number", default = 1000},
    flush_timeout = {type = "number", default = 2},
    log_bodies = {type = "boolean", default = false},
    connection_timeout = {type = "number", default = 30},
    host = {type = "string", required = true, default = "collector.galileo.mashape.com"},
    port = {type = "number", required = true, default = 443},
    https = {type = "boolean", default = true},
    https_verify = {type = "boolean", default = false}
  }
}
