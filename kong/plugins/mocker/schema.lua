return {
  fields = {
    error_code = {type = "number", default = 403},
    error_message = {type = "string", required = true, default = "This service is not available right now"},
    content_type_json = {type = "boolean", default = true},
    use_query_params = {type = "boolean", default = false},
    query_param_mapping = {type = "array", default = { "{['mock1']={404,'{message=\"Service is Not Available\"}'}}", "{['mock2']={403,'<html><h1>Service is not available</h1></html>'}}"},
  }
}
