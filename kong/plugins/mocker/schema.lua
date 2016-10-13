return {
  fields = {
    error_code = {type = "number", default = 403},
    error_message = {type = "string", required = true, default = "This service is not available right now"},
    content_type_json = {type = "boolean", default = true},
    use_url_params = {type = "boolean", default = false},
    mock_name_mapping = {type = "string", default = "{['mock1']={['query_param_mappings']={['param1']='1',['param2']='1'},['request_path_mappings']='/customer'}},['mock2']={['query_param_mappings']={['param1']='2',['param2']='2'},['request_path_mappings']='/product'}}"},
    mock_value_mapping = {type = "string", default = "{['mock1']={['code']=404,['contentType']='application/json; charset=utf-8',['message']='{\"message\":\"Service is Not Available\"}'},['mock2']={['code']=403,['contentType']='text/html; charset=UTF-8',['message']='<html><h1>Service is Not Available</h1></html>'}}"},
  }
}
