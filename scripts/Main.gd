extends Node


func _ready():
	print("Don't forget to set POSTGREST_HOST and POSTGREST_PORT in res://Database/Controllers/BaseController.gd")
	yield(read_people());


func get_controller(name:String) -> Controller:
	return load("res://Database/Controllers/%s.gd" % [ name ]).new()


func read_people():
	var controller = get_controller("People")
	var people = await controller.read()
	print(people)
