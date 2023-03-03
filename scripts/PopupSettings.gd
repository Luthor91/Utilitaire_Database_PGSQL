extends MenuButton

enum Options {
	LOGIN
	SETTINGS
	INFOS
}

func _ready():
	var mb = self
	# Create the items and set the Id's to the enum values.
	var popup = mb.get_popup()
	popup.add_item("Connexion", Options.LOGIN)
	popup.add_item("Options", Options.SETTINGS)
	popup.add_item("Informations", Options.INFOS)	
	
	# Connect the id pressed signal to the function which will handle the option logic
	popup.connect("id_pressed", self, "_item_selected")

func _item_selected(id: int):
	var _dump;
	match id:
		Options.LOGIN:
			_dump = get_tree().change_scene("res://scene/Login.tscn");
		Options.SETTINGS:
			if Globals.isConn == false:
				return;
			_dump = get_tree().change_scene("res://scene/Options.tscn");
		Options.INFOS:
			if Globals.isConn == false:
				return;
			_dump = get_tree().change_scene("res://scene/Information.tscn");
