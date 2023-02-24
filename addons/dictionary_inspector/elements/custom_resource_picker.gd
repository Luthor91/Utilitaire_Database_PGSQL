tool
class_name CustomResourcePicker
extends EditorResourcePicker

const setting_name = "addons/dictionary_inspector/resource_types"

var plugin


func _init(resource, plugin):
	editable = true
	toggle_mode = false
	edited_resource = resource
	self.plugin = plugin


func _ready():
	base_type = get_resource_base_type(edited_resource)
	$"PopupMenu".connect("id_pressed", self, "_the_cooler_handle_menu_selected")


func get_resource_base_type(resource):
	if resource == null:
		return "Resource"
	
	var type = resource.get_class()
	if type == "Resource":
		# Custom classes return the base type,
		# so we need to get the script
		var script_path = resource.get_script().resource_path
		var dir = plugin.get_editor_interface()\
			.get_resource_filesystem()\
			.get_filesystem_path(script_path.get_base_dir())
		var index_in_dir = dir.find_file_index(script_path.get_file())
		type = dir.get_file_script_class_extends(index_in_dir)

		if type == "Resource":
			type = dir.get_file_script_class_name(index_in_dir)

		if type == "":
			var source = resource.get_script().source_code
			var found_extends = source.find("extends ") + 8
			type = source.substr(found_extends, source.find("\n", found_extends + 1) - found_extends)
	
	var parent = ClassDB.get_parent_class(type)
	if type == "":
		return "Resource"

	elif parent in [
		"Texture", "AudioStream", "PrimitiveMesh",
		"Shape", "Shape2D", "Script", "StyleBox",
	]:
		return parent

	elif ClassDB.is_parent_class(type, "InputEvent"):
		# Not always a direct child.
		return "InputEvent"

	else:
		return type


# TODO: implement saving of selected types to reload them later
# func _ready():
#   base_type = get_saved_type()


func set_create_options(menu):
	var icon
	var i = 0
	for x in get_allowed_types():
		if has_icon(x, "EditorIcons"):
			icon = get_icon(x, "EditorIcons")

		else:
			icon = null

		menu.add_icon_item(icon, "New " + x, i + 100)
		i += 1
	
	menu.add_separator()
	menu.add_icon_item(get_icon("Variant", "EditorIcons"), "Change Collection's Resource type", 90001)
	menu.add_icon_item(get_icon("Object", "EditorIcons"), "Reset Base Type", 90002)
	menu.add_separator()


func handle_menu_selected(id):
	if id == 90001:
		for x in get_children():
			x.hide()
		
		var edit = LineEdit.new()
		add_child(edit)
		edit.placeholder_text = "Enter class name..."
		edit.connect("text_entered", self, "_on_classname_submitted", [edit])
		edit.grab_focus()
		edit.size_flags_horizontal = SIZE_EXPAND_FILL

	elif id == 90002:
		_on_classname_submitted("Resource")
	
	elif id >= 100 && id < get_allowed_types().size() + 100:
		var new_res = ClassDB.instance(get_allowed_types()[id - 100])
		emit_signal("resource_changed", new_res)
		edited_resource = new_res

	return false


func _the_cooler_handle_menu_selected(id):
	if id == 2:
		if edited_resource is Script:
			plugin.get_editor_interface().edit_script(edited_resource)

		else:
			plugin.get_editor_interface().edit_resource(edited_resource)


# func get_saved_type():
#   if !ProjectSettings.has_setting(setting_name):
#     return
	
#   var dict = ProjectSettings.get_setting(setting_name)
#   return dict.get(path_to_property, "Resource")


func _on_classname_submitted(new_text, node = null):
	$"PopupMenu".call_deferred("hide")
	if is_instance_valid(node):
		node.queue_free()

	for x in get_children():
		x.show()
	
	if !ClassDB.class_exists(new_text):
		new_text = "Resource"
	
	var property_boxes = get_node("../..").get_children()
	for x in property_boxes:
		for y in x.get_children():
			if y is EditorResourcePicker:
				y.set_base_type(new_text)
	
	# TODO: allow creation of new resources of changed type
	# If Base Type is changed, can't create new instances
	if new_text != "Resource":
		# $"PopupMenu".selected = 0
		handle_menu_selected(0)

	# else:
	# 	get_child(0).grab_focus()

	# var setting_dict = ProjectSettings.get_setting(setting_name)
	# setting_dict[path_to_property] = new_text
	# ProjectSettings.set_setting(setting_name, new_text)  
