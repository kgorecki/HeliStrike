extends Node3D

const MENU := "res://scenes/ui/main_menu.tscn"
const ControlsOverlay := preload("res://scripts/ui/controls_screen.gd")

var _world: WorldBuilder
var _heli: Helicopter
var _hud: Hud
var _pause: CanvasLayer
var _end: CanvasLayer
var _paused: bool = false
var _ended: bool = false
var _remaining: int = 0
var _total: int = 0
var _destroyed: Array[String] = []
var _status: Label
var _pause_root: Control
var _controls

func _ready() -> void:
	add_to_group("mission")
	_world = WorldBuilder.new()
	_world.build(self)
	_spawn_targets()
	_spawn_heli()
	_hud = Hud.new()
	_hud.heli = _heli
	_hud.total = _total
	_hud.remaining = _remaining
	add_child(_hud)
	_build_pause()
	_build_end()
	GameState.apply_flight_mouse_mode()
	var spec := HeliCatalog.spec(_heli.heli_id)
	_hud.flash(str(spec["title"]), 3.5)


func toggle_pause() -> void:
	if _ended:
		return
	_set_paused(not _paused)


func _process(delta: float) -> void:
	if _ended or _paused or _heli == null:
		return
	GameState.session["time_sec"] = float(GameState.session.get("time_sec", 0.0)) + delta


func _spawn_heli() -> void:
	var saved_id := str(GameState.session.get("heli_id", GameState.selected_heli))
	if GameState.restore_on_start and GameState.has_session():
		var heli_data: Dictionary = GameState.session.get("heli", {})
		saved_id = str(heli_data.get("heli_id", saved_id))
	GameState.selected_heli = HeliCatalog.clamp_id(saved_id)
	_heli = Helicopter.new()
	_heli.name = "Helicopter"
	add_child(_heli)
	var pad_y := _world.height_at(0, 0) + 3.2
	_heli.global_position = Vector3(0, pad_y, 0)
	_heli.crashed.connect(_on_crash)
	if GameState.restore_on_start and GameState.has_session():
		var heli_data: Dictionary = GameState.session.get("heli", {})
		_heli.from_save(heli_data)
		GameState.restore_on_start = false


func _spawn_targets() -> void:
	_destroyed.clear()
	if GameState.has_session():
		var ids: Variant = GameState.session.get("destroyed_ids", [])
		if ids is Array:
			for item in ids:
				_destroyed.append(str(item))

	var specs: Array = [
		{"id": "tank_1", "kind": GroundTarget.Kind.TANK, "pos": Vector2(-70, -430), "hp": 80.0},
		{"id": "tank_2", "kind": GroundTarget.Kind.TANK, "pos": Vector2(55, -490), "hp": 80.0},
		{"id": "tank_3", "kind": GroundTarget.Kind.TANK, "pos": Vector2(190, -530), "hp": 80.0},
		{"id": "sam_1", "kind": GroundTarget.Kind.SAM, "pos": Vector2(-150, -590), "hp": 70.0},
		{"id": "sam_2", "kind": GroundTarget.Kind.SAM, "pos": Vector2(95, -650), "hp": 70.0},
		{"id": "radar_1", "kind": GroundTarget.Kind.RADAR, "pos": Vector2(250, -560), "hp": 45.0},
		{"id": "radar_2", "kind": GroundTarget.Kind.RADAR, "pos": Vector2(-30, -720), "hp": 45.0},
		{"id": "bunker_1", "kind": GroundTarget.Kind.BUNKER, "pos": Vector2(140, -710), "hp": 130.0},
	]
	_total = specs.size()
	_remaining = 0
	for spec in specs:
		var id := str(spec["id"])
		if id in _destroyed:
			continue
		var tgt := GroundTarget.new()
		tgt.setup(spec["kind"], id, spec["hp"])
		var xz: Vector2 = spec["pos"]
		var y := _world.height_at(xz.x, xz.y) + 0.05
		tgt.destroyed.connect(_on_target_destroyed)
		add_child(tgt)
		tgt.position = Vector3(xz.x, y, xz.y)
		var look := Vector3(0, y, 0)
		if look.distance_to(tgt.global_position) > 0.5:
			tgt.look_at(look, Vector3.UP)
		_remaining += 1
	if _remaining == 0:
		call_deferred("_mission_over", true)


func _on_target_destroyed(target: GroundTarget) -> void:
	if not target.target_id in _destroyed:
		_destroyed.append(target.target_id)
	_remaining = maxi(_remaining - 1, 0)
	if _hud:
		_hud.remaining = _remaining
		_hud.flash("%s DESTROYED" % target.label_text())
	_capture()
	if _remaining <= 0:
		_mission_over(true)


func _on_crash() -> void:
	_mission_over(false)


func _capture() -> void:
	if _heli == null:
		return
	GameState.capture_session({
		"active": true,
		"mission_id": "iron_hawk",
		"time_sec": GameState.session.get("time_sec", 0.0),
		"destroyed_ids": _destroyed.duplicate(),
		"heli_id": _heli.heli_id,
		"heli": _heli.to_save(),
	})


func _set_paused(on: bool) -> void:
	_paused = on
	get_tree().paused = on
	_pause.visible = on
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_pause_root()
		_capture()
		_status.text = "MISSION PAUSED"
	else:
		_show_pause_root()
		GameState.rebinding = false
		GameState.apply_flight_mouse_mode()


func _build_pause() -> void:
	_pause = CanvasLayer.new()
	_pause.layer = 20
	_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause.visible = false
	add_child(_pause)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(dim)
	_pause_root = VBoxContainer.new()
	_pause_root.set_anchors_preset(Control.PRESET_CENTER)
	_pause_root.offset_left = -180
	_pause_root.offset_top = -200
	_pause_root.offset_right = 180
	_pause_root.offset_bottom = 200
	_pause_root.add_theme_constant_override("separation", 12)
	_pause.add_child(_pause_root)
	_pause_root.add_child(ThemeUtil.label("PAUSED", 28, ThemeUtil.AMBER, HORIZONTAL_ALIGNMENT_CENTER))
	_status = ThemeUtil.label("", 13, ThemeUtil.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_pause_root.add_child(_status)
	var resume := ThemeUtil.button("RESUME")
	resume.pressed.connect(func() -> void: _set_paused(false))
	_pause_root.add_child(resume)
	var save := ThemeUtil.button("SAVE GAME")
	save.pressed.connect(_save)
	_pause_root.add_child(save)
	var controls := ThemeUtil.button("CONTROLS")
	controls.pressed.connect(_open_controls)
	_pause_root.add_child(controls)
	var abort := ThemeUtil.button("ABORT MISSION")
	abort.pressed.connect(_abort)
	_pause_root.add_child(abort)
	_controls = ControlsOverlay.new()
	_controls.visible = false
	_controls.closed.connect(_show_pause_root)
	_pause.add_child(_controls)


func _open_controls() -> void:
	Sfx.play_ui()
	_pause_root.visible = false
	_controls.visible = true
	_controls.refresh()


func _show_pause_root() -> void:
	if _controls:
		_controls.cancel()
		_controls.visible = false
	if _pause_root:
		_pause_root.visible = true


func _build_end() -> void:
	_end = CanvasLayer.new()
	_end.layer = 25
	_end.process_mode = Node.PROCESS_MODE_ALWAYS
	_end.visible = false
	add_child(_end)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.add_child(dim)
	var box := VBoxContainer.new()
	box.name = "EndBox"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -220
	box.offset_top = -120
	box.offset_right = 220
	box.offset_bottom = 120
	box.add_theme_constant_override("separation", 14)
	_end.add_child(box)
	var title := ThemeUtil.label("", 32, ThemeUtil.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "EndTitle"
	box.add_child(title)
	var sub := ThemeUtil.label("", 14, ThemeUtil.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	sub.name = "EndSub"
	box.add_child(sub)
	var menu := ThemeUtil.button("MAIN MENU")
	menu.pressed.connect(_to_menu)
	box.add_child(menu)


func _save() -> void:
	_capture()
	if GameState.save_to_disk():
		_status.text = "MISSION SAVED"
	else:
		_status.text = "SAVE FAILED"
	Sfx.play_ui()


func _abort() -> void:
	_capture()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU)


func _to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU)


func _mission_over(win: bool) -> void:
	if _ended:
		return
	_ended = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_end.visible = true
	var title := _end.get_node("EndBox/EndTitle") as Label
	var sub := _end.get_node("EndBox/EndSub") as Label
	if win:
		title.text = "MISSION COMPLETE"
		title.add_theme_color_override("font_color", ThemeUtil.HUD)
		sub.text = "ALL GROUND TARGETS DESTROYED"
		GameState.clear_session()
		if FileAccess.file_exists(GameState.SAVE_PATH):
			DirAccess.remove_absolute(GameState.SAVE_PATH)
	else:
		title.text = "AIRCRAFT DOWN"
		title.add_theme_color_override("font_color", ThemeUtil.DANGER)
		sub.text = "HARD LANDING  ·  MISSION FAILED"
