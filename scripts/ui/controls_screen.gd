class_name ControlsScreen
extends Control

signal closed

var _rows: Dictionary = {}
var _listen_action: String = ""
var _listen_slot: int = -1
var _hint: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	_build()
	set_process_input(true)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dim.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(center)

	var card := ThemeUtil.panel()
	card.custom_minimum_size = Vector2(680, 640)
	center.add_child(card)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	root.add_child(ThemeUtil.label("CONTROLS", 26, ThemeUtil.AMBER, HORIZONTAL_ALIGNMENT_CENTER))
	_hint = ThemeUtil.label(
		"CLICK A BINDING TO REDEFINE   ·   ESC CANCELS   ·   RIGHT-CLICK CLEARS",
		12,
		ThemeUtil.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for action in GameState.ACTIONS:
		list.add_child(_make_row(str(action["id"]), str(action["label"])))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	root.add_child(buttons)

	var restore := ThemeUtil.button("RESTORE DEFAULTS", 220)
	restore.pressed.connect(_restore)
	buttons.add_child(restore)

	var back := ThemeUtil.button("BACK", 160)
	back.pressed.connect(_close)
	buttons.add_child(back)
	refresh()


func _make_row(action_id: String, label: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name := ThemeUtil.label(label, 14, ThemeUtil.TEXT)
	name.custom_minimum_size.x = 210
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var slot0 := ThemeUtil.button("—", 150)
	slot0.custom_minimum_size.y = 40
	var slot1 := ThemeUtil.button("—", 150)
	slot1.custom_minimum_size.y = 40
	_hook_bind_button(slot0, action_id, 0)
	_hook_bind_button(slot1, action_id, 1)
	row.add_child(slot0)
	row.add_child(slot1)
	_rows[action_id] = [slot0, slot1]
	return row


func _hook_bind_button(button: Button, action_id: String, slot: int) -> void:
	button.pressed.connect(func() -> void:
		_begin_listen(action_id, slot)
	)
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
				_cancel_listen()
				GameState.clear_binding(action_id, slot)
				refresh()
				button.accept_event()
	)


func refresh() -> void:
	for action in GameState.ACTIONS:
		var id := str(action["id"])
		if not _rows.has(id):
			continue
		var buttons: Array = _rows[id]
		for i in buttons.size():
			var b: Button = buttons[i]
			if _listen_action == id and _listen_slot == i:
				b.text = "PRESS..."
			else:
				b.text = GameState.bind_label(id, i)


func _begin_listen(action_id: String, slot: int) -> void:
	_listen_action = action_id
	_listen_slot = slot
	GameState.rebinding = true
	_hint.text = "PRESS A KEY OR MOUSE BUTTON   ·   ESC CANCELS"
	refresh()
	set_process_input(false)
	await get_tree().process_frame
	if _listen_action != "":
		set_process_input(true)


func _cancel_listen() -> void:
	_listen_action = ""
	_listen_slot = -1
	GameState.rebinding = false
	set_process_input(true)
	_hint.text = "CLICK A BINDING TO REDEFINE   ·   ESC CANCELS   ·   RIGHT-CLICK CLEARS"
	refresh()


func cancel() -> void:
	_cancel_listen()


func _restore() -> void:
	Sfx.play_ui()
	_cancel_listen()
	GameState.restore_default_bindings()
	refresh()


func _close() -> void:
	_cancel_listen()
	Sfx.play_ui()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _listen_action == "":
		if event.is_pressed() and not event.is_echo() and event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_close()
		return
	if event.is_echo() or not event.is_pressed():
		return
	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cancel_listen()
		return
	if event is InputEventKey or event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		GameState.assign_binding(_listen_action, _listen_slot, event)
		_cancel_listen()
