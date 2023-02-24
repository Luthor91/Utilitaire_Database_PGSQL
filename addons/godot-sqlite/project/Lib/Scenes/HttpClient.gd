extends Node


var http:HTTPRequest


func _ready() -> void:
	http = HTTPRequest.new()
	add_child(http)


func _parse_method(method:String):
	match method.to_upper():
		"GET":
			return HTTPClient.METHOD_GET
		"POST":
			return HTTPClient.METHOD_POST
		"PUT":
			return HTTPClient.METHOD_PUT
		"PATCH":
			return HTTPClient.METHOD_PATCH
		"DELETE":
			return HTTPClient.METHOD_DELETE


func fetch(url:String, options:Dictionary = {}) -> Dictionary:
	var headers = []
	if not options.has("headers"):
		options.headers = {}
	
	headers = _parse_headers(options.headers)
	
	var method = "GET"
	if options.has("method"):
		method = options.method
	
#	Logger.log("[%s] < %s %s" % [ options.headers["x-request-id"], method, url ], "debug")
	
	method = _parse_method(method)
	
	var body = ""
	if options.has("body"):
		body = JsonHelper.object_to_text(options.body)
	
	http.request(url, headers, false, method, body)
	var result = await http.request_completed
	var response = _parse_http_response(result)
	
#	Logger.log("[%s] > %s %s" % [
#		options.headers["x-request-id"], 
#		response.response_code, 
#		JsonHelper.object_to_text(response.body) 
#	], "debug")
	
	return response


func _parse_headers(headers:Dictionary) -> Array:
	var result = []
	for key in headers.keys():
		result.push_back("%s:%s" % [ key, headers[key] ])
	return result


func _parse_http_response(res):
	var body = PackedByteArray(res[3]).get_string_from_ascii()
	var regex = RegEx.new()
	regex.compile("([a-zA-Z\\-]+):\\s:?(.*)")
	
	var headers = {}
	var headers_list = res[2]
	for header in headers_list:
		var entries = header.split(":", true, 1)
		var key = entries[0].strip_edges()
		var value = entries[1].strip_edges()
		headers[key] = value
	
	body = JsonHelper.text_to_object(body)
	
	return {
		"result": res[0],
		"response_code": res[1],
		"headers": headers,
		"body": body
	}

