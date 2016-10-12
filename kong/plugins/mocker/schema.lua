return {
  fields = {
    error_code = {type = "number", default = 403},
    error_message = {type = "string", required = true, default = "This service is not available right now"},
    content_type_json = {type = "boolean", default = true},
    use_query_params = {type = "boolean", default = false},
    query_param_mapping = {type = "array", default = { "{['mock1']={['code']={404},['message']={'{Service is Not Available}'}},['mock2']={['code']={403},['message']={'{<html><h1>Service is Not Available</h1></html>}'}}}"},
  }
}
