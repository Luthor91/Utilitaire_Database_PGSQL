extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func _on_ButtonContactMail_pressed():
	var _err = OS.shell_open("mailto:lopezkillian0@gmail.com");
	print(_err);


func _on_ButtonContactGithub_pressed():
	var _err = OS.shell_open("https://github.com/Luthor91/Utilitaire_Database_PGSQL");
	print(_err);
