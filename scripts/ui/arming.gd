extends Control

const MISSION := "res://scenes/world/mission.tscn"
const HANGAR := "res://scenes/ui/hangar.tscn"

var _loadout: Array = []
var _selected: int = 0
var _pylon_buttons: Array[Button] = []
var _cards: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_loadout = _starting_loadout()
	_build()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up") or event.is_action_pressed("pitch_forward"):
		_select_pylon(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("pitch_back"):
		_select_pylon(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("yaw_left") or event.is_action_pressed("roll_left"):
		_cycle_missile(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("yaw_right") or event.is_action_pressed("roll_right"):
		_cycle_missile(1)
		get_viewport().set_input_as_handled()


func _starting_loadout() -> Array:
	var slots := int(HeliCatalog.spec(GameState.selected_heli)["missile_slots"])
	var src: Array = GameState.missile_loadout
	if src.size() != slots:
		src = MissileCatalog.default_for(GameState.selected_heli)
	var out: Array = []
	for i in slots:
		out.append(MissileCatalog.clamp_id(str(src[i])))
	return out


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.04, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 48)
	margin.add_child(split)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 560
	left.add_theme_constant_override("separation", 10)
	split.add_child(left)

	var heli := HeliCatalog.spec(GameState.selected_heli)
	left.add_child(ThemeUtil.label("FARP WATCHTOWER  /  ORDNANCE", 13, ThemeUtil.MUTED))
	left.add_child(ThemeUtil.label("MOUNT MISSILES", 40, ThemeUtil.AMBER))
	left.add_child(ThemeUtil.label(
		"%s  ·  %d PYLONS" % [str(heli["title"]), _loadout.size()],
		16,
		ThemeUtil.OLIVE
	))
	left.add_child(ThemeUtil.label(
		"Each pylon takes one store. In flight, keys 1-4 select a pylon. Each trigger fires one round.",
		14,
		ThemeUtil.TEXT
	))

	var slot_box := VBoxContainer.new()
	slot_box.add_theme_constant_override("separation", 8)
	left.add_child(slot_box)
	for i in _loadout.size():
		var btn := ThemeUtil.button("", 520)
		var slot := i
		btn.pressed.connect(func() -> void: _choose_pylon(slot))
		slot_box.add_child(btn)
		_pylon_buttons.append(btn)

	var launch := ThemeUtil.button("LAUNCH", 280)
	launch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	launch.pressed.connect(_launch)
	left.add_child(launch)
	var back := ThemeUtil.button("BACK", 160)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_back)
	left.add_child(back)
	left.add_child(ThemeUtil.label("ARROWS SELECT PYLON AND STORE", 12, ThemeUtil.MUTED))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	split.add_child(right)
	right.add_child(ThemeUtil.label("STORES", 14, ThemeUtil.MUTED))
	for id in MissileCatalog.IDS:
		var card := _make_card(id)
		right.add_child(card)
		_cards[id] = card


func _make_card(id: String) -> Button:
	var data := MissileCatalog.spec(id)
	var btn := ThemeUtil.button("", 640)
	btn.custom_minimum_size = Vector2(640, 118)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", 15)
	btn.text = "%s\n%s\n%s" % [str(data["title"]), MissileCatalog.summary(id), str(data["blurb"])]
	btn.pressed.connect(func() -> void: _mount(id))
	return btn


func _choose_pylon(index: int) -> void:
	Sfx.play_ui()
	_selected = index
	_refresh()


func _select_pylon(dir: int) -> void:
	Sfx.play_ui()
	_selected = posmod(_selected + dir, _loadout.size())
	_refresh()


func _cycle_missile(dir: int) -> void:
	Sfx.play_ui()
	var current := MissileCatalog.IDS.find(str(_loadout[_selected]))
	if current < 0:
		current = 0
	_loadout[_selected] = MissileCatalog.IDS[posmod(current + dir, MissileCatalog.IDS.size())]
	_refresh()


func _mount(id: String) -> void:
	Sfx.play_ui()
	_loadout[_selected] = MissileCatalog.clamp_id(id)
	_selected = posmod(_selected + 1, _loadout.size())
	_refresh()


func _refresh() -> void:
	GameState.missile_loadout = _loadout.duplicate()
	for i in _loadout.size():
		var data := MissileCatalog.spec(str(_loadout[i]))
		var mark := ">" if i == _selected else " "
		_pylon_buttons[i].text = "%s PYLON %d    %s" % [mark, i + 1, str(data["title"])]
		var col := ThemeUtil.AMBER if i == _selected else ThemeUtil.TEXT
		_pylon_buttons[i].add_theme_color_override("font_color", col)
	var mounted := str(_loadout[_selected])
	for key in _cards.keys():
		var id := str(key)
		var btn := _cards[key] as Button
		var on: bool = id == mounted
		btn.add_theme_color_override("font_color", ThemeUtil.AMBER if on else ThemeUtil.TEXT)


func _launch() -> void:
	Sfx.play_ui()
	GameState.missile_loadout = _loadout.duplicate()
	if not GameState.has_session():
		GameState.start_new_session()
	GameState.session["heli_id"] = GameState.selected_heli
	GameState.session["loadout"] = _loadout.duplicate()
	GameState.session["heli"] = {}
	GameState.session["destroyed_ids"] = []
	GameState.restore_on_start = false
	get_tree().change_scene_to_file(MISSION)


func _back() -> void:
	Sfx.play_ui()
	get_tree().change_scene_to_file(HANGAR)
