extends Node


func object_to_text(obj):
	var json = JSON.new()
	return json.stringify(obj)


func text_to_object(text:String):
	var json = JSON.new()
	var error = json.parse(text)
	if error == OK:
		return json.get_data()
	else:
		return error
	pass


func print(obj, indent = 0, sort_keys = {}):
	print(object_to_text(obj))
