extends MenuButton

enum Options {
	TUTORIEL
	CONTACT
	INFOS
}

func _ready():
	var mb = self
	# Create the items and set the Id's to the enum values.
	var popup = mb.get_popup()
	popup.add_item("Tutoriel", Options.TUTORIEL)
	popup.add_item("Contact", Options.CONTACT)
	popup.add_item("Test3", Options.INFOS)
	
	# Connect the id pressed signal to the function which will handle the option logic
	popup.connect("id_pressed", self, "_item_selected")

func _item_selected(id: int):
	var _dump;
	match id:
		Options.TUTORIEL:
			_dump = get_tree().change_scene("res://scene/Tutoriel.tscn");
		Options.CONTACT:
			_dump = get_tree().change_scene("res://scene/Contact.tscn");
		Options.INFOS:
			_dump = get_tree().change_scene("res://scene/Information.tscn");
