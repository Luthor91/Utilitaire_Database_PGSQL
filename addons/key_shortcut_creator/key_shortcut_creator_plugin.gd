tool
extends EditorPlugin

const MENU_ITEM = "Key Shortcut Creator"
var dialog: WindowDialog = null

func _enter_tree():
	add_tool_menu_item(MENU_ITEM, self, "open_dialog")

func _exit_tree():
	remove_tool_menu_item(MENU_ITEM)
	if dialog != null:
		dialog.queue_free()

func open_dialog(ud):
	if dialog == null:
		dialog = load("res://addons/key_shortcut_creator/KeyShortcutCreatorDialog.tscn").instance()
		get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()
