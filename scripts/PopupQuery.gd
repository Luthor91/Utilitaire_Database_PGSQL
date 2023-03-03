extends MenuButton

enum Options {
	QUERY_WRITTEN,
	QUERY_VISUAL
}

func _ready():
	var mb = self
	# Create the items and set the Id's to the enum values.
	var popup = mb.get_popup()
	popup.add_item("Requêtes Ecrites", Options.QUERY_WRITTEN)
	popup.add_item("Requêtes Formulaire", Options.QUERY_VISUAL)
	
	# Connect the id pressed signal to the function which will handle the option logic
	popup.connect("id_pressed", self, "_item_selected")

func _item_selected(id: int):
	if Globals.isConn == false:
		return;
	var _dump;
	match id:
		Options.QUERY_WRITTEN:
			_dump = get_tree().change_scene("res://scene/RequeteEcrite.tscn");
		Options.QUERY_VISUAL:
			print("Requêtes Formulaire")
