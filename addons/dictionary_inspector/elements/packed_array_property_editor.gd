tool
class_name PackedArrayPropertyEditor
extends BaseCollectionPropertyEditor


const array_to_element_type = {
	TYPE_RAW_ARRAY : TYPE_INT,
	TYPE_INT_ARRAY : TYPE_INT,
	TYPE_REAL_ARRAY : TYPE_REAL,
	TYPE_STRING_ARRAY : TYPE_STRING,
	TYPE_VECTOR2_ARRAY : TYPE_VECTOR2,
	TYPE_VECTOR3_ARRAY : TYPE_VECTOR3,
	TYPE_COLOR_ARRAY : TYPE_COLOR,
}


func add_all_properties(collection):
	last_type_v = array_to_element_type.get(typeof(collection), TYPE_REAL)
	for i in collection.size():
		add_child(create_property_container(i))


func create_add_button():
	var button = Button.new()
	button.text = "Add Entry"
	button.icon = get_icon("Add", "EditorIcons")
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.rect_min_size.x = button.get_minimum_size().x + 64.0
	button.connect("pressed", self, "_on_add_button_pressed")

	var result = HBoxContainer.new()
	var color_rect = get_node("../../ColorRect").duplicate()
	color_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	# Grab the Color Rect
	result.add_constant_override("separation", 0)
	result.add_child(color_rect)
	result.add_child(button)
	result.add_child(color_rect.duplicate())
	return result


func create_property_container(index_in_collection):
	var c = init_prop_container.duplicate()
	c.add_child(EditorArrayIndex.new(index_in_collection))
	c.get_child(0).connect("drop_received", self, "_on_item_moved", [c])
	c.add_child(create_property_control_for_type(last_type_v, stored_collection[index_in_collection], c, false))
	var delete_button = Button.new()
	delete_button.text = "X"
	delete_button.connect("pressed", self, "_on_property_deleted", [index_in_collection, c])
	c.add_child(delete_button)

	return c


func _on_add_button_pressed():
	var new_value = get_default_for_class(last_type_v)
	if stored_collection.size() > 0 && (
		last_type_v == TYPE_OBJECT || stored_collection[-1] is Object
	):
		new_value = stored_collection[-1].duplicate()

	stored_collection.append(new_value)
	update_variant(stored_collection.size() - 1, new_value, false)

	var new_node = create_property_container(stored_collection.size() - 1)
	add_child(new_node)
	emit_signal("value_changed", stored_collection)


func _on_property_deleted(key, control):
	stored_collection.remove(key)
	emit_signal("value_changed", stored_collection)
	display(stored_collection, plugin)


func _on_item_moved(from_container, to_container):
	var to_index = get_container_index(to_container)
	var from_index = get_container_index(from_container)
	stored_collection.insert(to_index, stored_collection.pop_at(from_index))

	move_child(from_container, to_index + 1)
	var i = 0
	for x in get_children():
		if x is HBoxContainer && x.get_child(0) is EditorArrayIndex:
			x.get_child(0).value = i
			i += 1
	
	emit_signal("value_changed", stored_collection)
