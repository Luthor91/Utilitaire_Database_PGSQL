extends MenuButton

enum Options {
	USER_MANAGEMENT
	USER_CREATE
	USER_DELETE
}

func _ready():
	var mb = self
	# Create the items and set the Id's to the enum values.
	var popup = mb.get_popup()
	popup.add_item("Gestion Utilisateur", Options.USER_MANAGEMENT)
	popup.add_item("Création Utilisateur", Options.USER_CREATE)
	popup.add_item("Suppression Utilisateur", Options.USER_DELETE)
	popup.connect("id_pressed", self, "_item_selected")

func _item_selected(id: int):
	var _dump;
	if Globals.isConn == false:
		return;
	match id:
		Options.USER_MANAGEMENT:
			_dump = get_tree().change_scene("res://scene/GestionUtilisateur.tscn");
		Options.USER_CREATE:
			_dump = get_tree().change_scene("res://scene/CreationUtilisateur.tscn");
		Options.USER_DELETE:
			_dump = get_tree().change_scene("res://scene/SuppressionUtilisateur.tscn");
