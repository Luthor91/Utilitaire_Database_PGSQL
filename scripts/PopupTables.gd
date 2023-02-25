extends MenuButton

enum Options {
	TABLE_MANAGEMENT
	TABLE_CREATION
}
var _dump;

func _ready():
	var mb = self
	# Create the items and set the Id's to the enum values.
	var popup = mb.get_popup()
	popup.add_item("Gestion Base de Données", Options.TABLE_MANAGEMENT)
	popup.add_item("Création Base de Données", Options.TABLE_CREATION)
	
	# Connect the id pressed signal to the function which will handle the option logic
	popup.connect("id_pressed", self, "_item_selected")

func _item_selected(id: int):
	if Globals.isConn == false:
		return;
	match id:
		Options.TABLE_MANAGEMENT:
			_dump = get_tree().change_scene("res://scene/GestionTable.tscn");
		Options.TABLE_CREATION:
			_dump = get_tree().change_scene("res://scene/CreationTable.tscn");
