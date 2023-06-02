tool
extends Button

signal grabbed_event_updated(event)
signal grabbed_event_cleared

export(Color) var empty_font_color = Color.gray

var grabbed_event: InputEventKey = null setget set_grabbed_event, get_grabbed_event

func set_grabbed_event(event: InputEventKey):
	grabbed_event = event
	if event == null:
		text = "Press a key..."
		emit_signal("grabbed_event_cleared")
	else:
		text = event.as_text()
		emit_signal("grabbed_event_updated", event)

func get_grabbed_event() -> InputEventKey:
	return grabbed_event

func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")

func _gui_input(event):
	if event is InputEventKey:
		if event.is_pressed() and not event.is_echo():
			set_grabbed_event(event)
			if not event_is_modifier(event):
				var next = get_node_or_null(focus_next)
				if next is Control:
					next.grab_focus()
				else:
					release_focus()
		accept_event()

func event_is_modifier(event: InputEventKey):
	return event.scancode in [KEY_ALT, KEY_CONTROL, KEY_META, KEY_SHIFT]

# Focus Events
func _on_focus_entered():
	set_grabbed_event(null)

func _on_focus_exited():
	pass
