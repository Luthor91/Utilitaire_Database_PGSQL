tool
extends WindowDialog

onready var input_key_button: Button = $VBoxContainer/InputKey
onready var create_button: Button = $VBoxContainer/CreateButton
onready var file_dialog: FileDialog = $FileDialog

var shortcut = ShortCut.new()

func _ready():
	for ext in ResourceSaver.get_recognized_extensions(shortcut):
		file_dialog.add_filter("*.{0} ; {1}".format([ext, ext.to_upper()]))

func _on_Create_pressed():
	file_dialog.popup_centered_ratio()

func _on_InputKey_grabbed_event_updated(event: InputEventKey):
	create_button.disabled = false
	shortcut.shortcut = event

func _on_InputKey_grabbed_event_cleared():
	create_button.disabled = true

func _on_about_to_show():
	input_key_button.call_deferred("grab_focus")

func _on_FileDialog_file_selected(path: String):
	if ResourceSaver.save(path, shortcut, ResourceSaver.FLAG_BUNDLE_RESOURCES) == OK:
		visible = false
		print("Saved shortcut '", shortcut.get_as_text(), "' to path '", path, "'")
