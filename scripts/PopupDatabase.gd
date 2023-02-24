extends MenuButton

enum Options {
	EXPORT_IMPORT
	DATABASE_MANAGEMENT
	DATABASE_CREATION
}
var _dump;

func _ready():
	var mb = self
	# Create the items and set the Id's to the enum values.
	var popup = mb.get_popup()
	popup.add_item("Export / Import", Options.EXPORT_IMPORT)
	popup.add_item("Gestion Base de Données", Options.DATABASE_MANAGEMENT)
	popup.add_item("Création Base de Données", Options.DATABASE_CREATION)
	
	# Connect the id pressed signal to the function which will handle the option logic
	popup.connect("id_pressed", self, "_item_selected")

func _item_selected(id: int):
	match id:
		Options.EXPORT_IMPORT:
			print("Export / Import")
		Options.DATABASE_MANAGEMENT:
			_dump = get_tree().change_scene("res://scene/GestionDatabase.tscn");
		Options.DATABASE_CREATION:
			_dump = get_tree().change_scene("res://scene/CreationDatabase.tscn");
