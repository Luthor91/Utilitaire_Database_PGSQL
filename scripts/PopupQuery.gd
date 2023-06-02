extends MenuButton

enum Options {
	QUERY_WRITTEN,
	QUERY_FORM,
	QUERY_RES
}

func _ready():
	var mb = self
	# Create the items and set the Id's to the enum values.
	var popup = mb.get_popup()
	popup.add_item("Requêtes Ecrites", Options.QUERY_WRITTEN)
	popup.add_item("Requêtes Formulaire", Options.QUERY_FORM)
	popup.add_item("Data Visualisation", Options.QUERY_RES)
	popup.connect("id_pressed", self, "_item_selected")

func _item_selected(id: int):
	if Globals.isConn == false:
		return;
	var _dump;
	match id:
		Options.QUERY_WRITTEN:
			_dump = get_tree().change_scene("res://scene/RequeteEcrite.tscn");
		Options.QUERY_FORM:
			_dump = get_tree().change_scene("res://scene/RequeteFormulaire.tscn");
		Options.QUERY_RES:
			_dump = get_tree().change_scene("res://scene/RequeteVisualisation.tscn");
