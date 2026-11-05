extends Node

const SAVE_PATH := "user://HeliStrike_save.json"
const SETTINGS_PATH := "user://HeliStrike_settings.json"
const BIND_SLOTS := 2

const ACTIONS: Array[Dictionary] = [
	{"id": "collective_up", "label": "COLLECTIVE UP"},
	{"id": "collective_down", "label": "COLLECTIVE DOWN"},
	{"id": "pitch_forward", "label": "PITCH FORWARD"},
	{"id": "pitch_back", "label": "PITCH BACK"},
	{"id": "roll_left", "label": "ROLL LEFT"},
	{"id": "roll_right", "label": "ROLL RIGHT"},
	{"id": "yaw_left", "label": "YAW LEFT"},
	{"id": "yaw_right", "label": "YAW RIGHT"},
	{"id": "fire_cannon", "label": "FIRE CANNON"},
	{"id": "fire_missile", "label": "FIRE MISSILE"},
	{"id": "camera_toggle", "label": "CAMERA"},
	{"id": "pause", "label": "PAUSE"},
]

var mouse_sensitivity: float = 1.0
var mouse_steering: bool = true
var invert_y: bool = false
var fullscreen: bool = false
var rebinding: bool = false
## action id -> array of 2 serialized bind specs (or null)
var bindings: Dictionary = {}
var selected_heli: String = "apache"
## Missile id per pylon. Length matches HeliCatalog missile_slots.
var missile_loadout: Array = []

## In-memory mission snapshot. Survives abort so Continue / Save still work.
var session: Dictionary = {}
var restore_on_start: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_actions()
	restore_default_bindings(false)
	load_settings()
	apply_window_mode()


func _unhandled_input(event: InputEvent) -> void:
	if rebinding:
		return
	if event.is_action_pressed("pause"):
		var mission := get_tree().get_first_node_in_group("mission")
		if mission and mission.has_method("toggle_pause"):
			mission.toggle_pause()
			get_viewport().set_input_as_handled()


func has_session() -> bool:
	return bool(session.get("active", false))


func has_disk_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func can_continue() -> bool:
	return has_session() or has_disk_save()


func can_save() -> bool:
	return has_session()


func start_new_session() -> void:
	session = {
		"active": true,
		"mission_id": "iron_hawk",
		"time_sec": 0.0,
		"destroyed_ids": [],
		"heli": {},
		"heli_id": selected_heli,
	}
	restore_on_start = false


func capture_session(data: Dictionary) -> void:
	session = data
	session["active"] = true


func clear_session() -> void:
	session = {}
	restore_on_start = false


func save_to_disk() -> bool:
	if not has_session():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var payload := session.duplicate(true)
	payload["saved_at"] = Time.get_datetime_string_from_system()
	file.store_string(JSON.stringify(payload))
	return true


func load_from_disk() -> bool:
	if not has_disk_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	session = parsed
	session["active"] = true
	restore_on_start = true
	selected_heli = HeliCatalog.clamp_id(str(session.get("heli_id", selected_heli)))
	if session.has("loadout") and session["loadout"] is Array:
		missile_loadout = (session["loadout"] as Array).duplicate()
	return true


func prepare_continue() -> bool:
	if has_session():
		restore_on_start = session.get("heli", {}) != {}
		return true
	return load_from_disk()


func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"mouse_sensitivity": mouse_sensitivity,
		"mouse_steering": mouse_steering,
		"invert_y": invert_y,
		"fullscreen": fullscreen,
		"bindings": bindings,
		"selected_heli": selected_heli,
	}))


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	mouse_sensitivity = float(data.get("mouse_sensitivity", 1.0))
	mouse_steering = bool(data.get("mouse_steering", true))
	invert_y = bool(data.get("invert_y", false))
	fullscreen = bool(data.get("fullscreen", false))
	selected_heli = HeliCatalog.clamp_id(str(data.get("selected_heli", "apache")))
	if data.has("bindings") and data["bindings"] is Dictionary:
		_load_bindings(data["bindings"])


func apply_window_mode() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func apply_flight_mouse_mode() -> void:
	if mouse_steering:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func default_bindings() -> Dictionary:
	return {
		"collective_up": [_key(KEY_W), _mouse(MOUSE_BUTTON_WHEEL_UP)],
		"collective_down": [_key(KEY_S), _mouse(MOUSE_BUTTON_WHEEL_DOWN)],
		"pitch_forward": [_key(KEY_UP), null],
		"pitch_back": [_key(KEY_DOWN), null],
		"roll_left": [_key(KEY_LEFT), null],
		"roll_right": [_key(KEY_RIGHT), null],
		"yaw_left": [_key(KEY_A), null],
		"yaw_right": [_key(KEY_D), null],
		"fire_cannon": [_key(KEY_SPACE), _mouse(MOUSE_BUTTON_LEFT)],
		"fire_missile": [_key(KEY_F), _mouse(MOUSE_BUTTON_RIGHT)],
		"camera_toggle": [_key(KEY_C), null],
		"pause": [_key(KEY_ESCAPE), null],
	}


func restore_default_bindings(persist: bool = true) -> void:
	bindings = default_bindings()
	_apply_bindings()
	if persist:
		save_settings()


func bind_label(action_id: String, slot: int) -> String:
	var spec: Variant = _slot_spec(action_id, slot)
	if spec == null:
		return "—"
	return _spec_label(spec)


func assign_binding(action_id: String, slot: int, event: InputEvent) -> void:
	var spec := _event_to_spec(event)
	if spec.is_empty():
		return
	_clear_spec(spec)
	if not bindings.has(action_id):
		bindings[action_id] = [null, null]
	var slots: Array = bindings[action_id]
	while slots.size() < BIND_SLOTS:
		slots.append(null)
	slots[slot] = spec
	bindings[action_id] = slots
	_apply_bindings()
	save_settings()


func clear_binding(action_id: String, slot: int) -> void:
	if not bindings.has(action_id):
		return
	var slots: Array = bindings[action_id]
	if slot < 0 or slot >= slots.size():
		return
	slots[slot] = null
	bindings[action_id] = slots
	_apply_bindings()
	save_settings()


func _ensure_actions() -> void:
	for action in ACTIONS:
		var id := str(action["id"])
		if not InputMap.has_action(id):
			InputMap.add_action(id)


func _apply_bindings() -> void:
	for action in ACTIONS:
		var id := str(action["id"])
		InputMap.action_erase_events(id)
		var slots: Array = bindings.get(id, [null, null])
		for spec in slots:
			if spec == null:
				continue
			var ev := _spec_to_event(spec)
			if ev:
				InputMap.action_add_event(id, ev)


func _load_bindings(saved: Dictionary) -> void:
	var next := default_bindings()
	for action in ACTIONS:
		var id := str(action["id"])
		if not saved.has(id) or not saved[id] is Array:
			continue
		var loaded: Array = saved[id]
		var slots: Array = [null, null]
		for i in mini(loaded.size(), BIND_SLOTS):
			if loaded[i] is Dictionary:
				slots[i] = loaded[i]
		next[id] = slots
	bindings = next
	_apply_bindings()


func _slot_spec(action_id: String, slot: int) -> Variant:
	var slots: Array = bindings.get(action_id, [null, null])
	if slot < 0 or slot >= slots.size():
		return null
	return slots[slot]


func _clear_spec(spec: Dictionary) -> void:
	for action in ACTIONS:
		var id := str(action["id"])
		var slots: Array = bindings.get(id, [null, null]).duplicate()
		for i in slots.size():
			if slots[i] is Dictionary and _specs_equal(slots[i], spec):
				slots[i] = null
		bindings[id] = slots


func _specs_equal(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("t", "")) == str(b.get("t", "")) and int(a.get("c", -1)) == int(b.get("c", -2))


func _key(code: Key) -> Dictionary:
	return {"t": "k", "c": int(code)}


func _mouse(button: MouseButton) -> Dictionary:
	return {"t": "m", "c": int(button)}


func _event_to_spec(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		if code == KEY_NONE:
			return {}
		return _key(code)
	if event is InputEventMouseButton:
		return _mouse((event as InputEventMouseButton).button_index)
	return {}


func _spec_to_event(spec: Variant) -> InputEvent:
	if not spec is Dictionary:
		return null
	var data: Dictionary = spec
	if str(data.get("t", "")) == "k":
		var ev := InputEventKey.new()
		ev.physical_keycode = int(data.get("c", 0)) as Key
		return ev
	if str(data.get("t", "")) == "m":
		var ev := InputEventMouseButton.new()
		ev.button_index = int(data.get("c", 0)) as MouseButton
		return ev
	return null


func _spec_label(spec: Variant) -> String:
	if not spec is Dictionary:
		return "—"
	var data: Dictionary = spec
	if str(data.get("t", "")) == "k":
		return OS.get_keycode_string(int(data.get("c", 0)) as Key)
	if str(data.get("t", "")) == "m":
		match int(data.get("c", 0)):
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			MOUSE_BUTTON_WHEEL_UP:
				return "WHEEL UP"
			MOUSE_BUTTON_WHEEL_DOWN:
				return "WHEEL DOWN"
			MOUSE_BUTTON_WHEEL_LEFT:
				return "WHEEL LEFT"
			MOUSE_BUTTON_WHEEL_RIGHT:
				return "WHEEL RIGHT"
			_:
				return "MOUSE %d" % int(data.get("c", 0))
	return "—"
