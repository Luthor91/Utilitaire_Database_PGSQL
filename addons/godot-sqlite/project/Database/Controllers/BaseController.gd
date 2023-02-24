extends Node
class_name Controller


const POSTGREST_HOST = "127.0.0.1"
const POSTGREST_PORT = 3000


var _base_name:String


func get_base_url():
	return "http://%s:%s" % [ POSTGREST_HOST, POSTGREST_PORT ]


func read_raw(name:String = "", value:String = ""):
	var url = "%s/%s" % [ get_base_url(), _base_name ]
	if name != "" and value != "":
		url = "%s?%s=eq.%s" % [ url, name, value ]
	print("GET %s" % [ url ])
	return await HttpClient.fetch(url)


func read(name:String = "", value:String = ""):
	return (await read_raw(name, value)).body


func read_by_id(id:String):
	var result = await read("id", id)
	if result.size() == 1:
		return result[0]
	return null

