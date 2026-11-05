extends Node3D

const BRIEFING := "res://scenes/ui/briefing.tscn"
const MISSION := "res://scenes/world/mission.tscn"

var _continue_btn: Button
var _save_btn: Button
var _settings_panel: Control
var _heli: Node3D
var _status: Label

func _ready() -> void:
	_build_world()
	_build_ui()
	_refresh_buttons()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if _heli:
		_heli.rotate_y(delta * 0.18)
		var rotor := _heli.get_node_or_null("MainRotor")
		if rotor:
			rotor.rotate_y(delta * 14.0)
		var tail := _heli.get_node_or_null("TailRotor")
		if tail:
			tail.rotate_y(delta * 28.0)


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.24, 0.32)
	sky_mat.sky_horizon_color = Color(0.72, 0.52, 0.32)
	sky_mat.ground_bottom_color = Color(0.16, 0.14, 0.10)
	sky_mat.ground_horizon_color = Color(0.45, 0.36, 0.22)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.45
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.62, 0.5, 0.32)
	environment.fog_density = 0.008
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, 40, 0)
	sun.light_color = Color(1.0, 0.88, 0.7)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(4, 5, 6)
	fill.light_color = Color(0.85, 0.95, 1.0)
	fill.light_energy = 2.4
	fill.omni_range = 28.0
	add_child(fill)

	var cam := Camera3D.new()
	cam.position = Vector3(13.8, 3.6, 5.6)
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(-0.6, 1.35, 0.4))

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.32, 0.28, 0.18)
	ground.material_override = gmat
	ground.position.y = -0.05
	add_child(ground)

	_heli = HeliBuilder.build_model()
	_heli.position = Vector3(0, 1.15, 0)
	add_child(_heli)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.02, 0.78)
	dim.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	dim.offset_right = 620
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_bottom", 48)
	layer.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	root.add_child(ThemeUtil.label("1ST BN  /  TASK FORCE HAWK", 14, ThemeUtil.MUTED))
	var title := ThemeUtil.label("HeliStrike", 64, ThemeUtil.AMBER)
	root.add_child(title)
	root.add_child(ThemeUtil.label("ATTACK HELICOPTER SIMULATOR", 18, ThemeUtil.OLIVE))
	root.add_child(ThemeUtil.label("AH-64E  ·  FORWARD ARMING AND REFUELING POINT", 13, ThemeUtil.MUTED))

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 36
	root.add_child(spacer)

	var new_btn := ThemeUtil.button("NEW GAME")
	new_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	new_btn.pressed.connect(_on_new_game)
	root.add_child(new_btn)

	_continue_btn = ThemeUtil.button("CONTINUE")
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_continue_btn.pressed.connect(_on_continue)
	root.add_child(_continue_btn)

	_save_btn = ThemeUtil.button("SAVE GAME")
	_save_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_save_btn.pressed.connect(_on_save)
	root.add_child(_save_btn)

	var settings_btn := ThemeUtil.button("SETTINGS")
	settings_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	settings_btn.pressed.connect(_toggle_settings)
	root.add_child(settings_btn)

	var quit_btn := ThemeUtil.button("QUIT")
	quit_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	quit_btn.pressed.connect(get_tree().quit)
	root.add_child(quit_btn)

	_status = ThemeUtil.label("", 14, ThemeUtil.MUTED)
	root.add_child(_status)

	var footer := ThemeUtil.label("GODOT 4.6.1   ·   CLASSIFICATION: TRAINING", 12, ThemeUtil.MUTED)
	footer.size_flags_vertical = Control.SIZE_SHRINK_END
	root.add_child(footer)

	_settings_panel = _make_settings()
	layer.add_child(_settings_panel)


func _make_settings() -> Control:
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.visible = false

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			wrap.visible = false
	)
	wrap.add_child(shade)

	var card := ThemeUtil.panel()
	card.custom_minimum_size = Vector2(460, 380)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -230
	card.offset_top = -190
	card.offset_right = 230
	card.offset_bottom = 190
	wrap.add_child(card)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 14)
	var inner := MarginContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left", 24)
	inner.add_theme_constant_override("margin_top", 20)
	inner.add_theme_constant_override("margin_right", 24)
	inner.add_theme_constant_override("margin_bottom", 20)
	card.add_child(inner)
	inner.add_child(box)

	box.add_child(ThemeUtil.label("SETTINGS", 22, ThemeUtil.AMBER))

	var sens_row := HBoxContainer.new()
	sens_row.add_theme_constant_override("separation", 12)
	sens_row.add_child(ThemeUtil.label("MOUSE SENSITIVITY", 14))
	var slider := HSlider.new()
	slider.min_value = 0.3
	slider.max_value = 2.5
	slider.step = 0.05
	slider.value = GameState.mouse_sensitivity
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float) -> void:
		GameState.mouse_sensitivity = v
		GameState.save_settings()
	)
	sens_row.add_child(slider)
	box.add_child(sens_row)

	var steering := CheckBox.new()
	steering.text = "MOUSE STEERING"
	steering.button_pressed = GameState.mouse_steering
	steering.add_theme_font_override("font", ThemeUtil.mono())
	steering.add_theme_color_override("font_color", ThemeUtil.TEXT)
	steering.toggled.connect(func(on: bool) -> void:
		GameState.mouse_steering = on
		GameState.save_settings()
	)
	box.add_child(steering)

	var invert := CheckBox.new()
	invert.text = "INVERT MOUSE Y"
	invert.button_pressed = GameState.invert_y
	invert.add_theme_font_override("font", ThemeUtil.mono())
	invert.add_theme_color_override("font_color", ThemeUtil.TEXT)
	invert.toggled.connect(func(on: bool) -> void:
		GameState.invert_y = on
		GameState.save_settings()
	)
	box.add_child(invert)

	var full := CheckBox.new()
	full.text = "FULLSCREEN"
	full.button_pressed = GameState.fullscreen
	full.add_theme_font_override("font", ThemeUtil.mono())
	full.add_theme_color_override("font_color", ThemeUtil.TEXT)
	full.toggled.connect(func(on: bool) -> void:
		GameState.fullscreen = on
		GameState.apply_window_mode()
		GameState.save_settings()
	)
	box.add_child(full)

	var close := ThemeUtil.button("CLOSE", 180)
	close.pressed.connect(func() -> void: wrap.visible = false)
	box.add_child(close)
	return wrap


func _refresh_buttons() -> void:
	_continue_btn.disabled = not GameState.can_continue()
	_save_btn.disabled = not GameState.can_save()
	if GameState.has_disk_save() and GameState.session.has("saved_at"):
		_status.text = "LAST SAVE  %s" % str(GameState.session.get("saved_at", ""))
	elif GameState.has_session():
		_status.text = "UNSAVED MISSION IN MEMORY"
	else:
		_status.text = "NO SAVE ON DISK"


func _on_new_game() -> void:
	Sfx.play_ui()
	GameState.start_new_session()
	get_tree().change_scene_to_file(BRIEFING)


func _on_continue() -> void:
	Sfx.play_ui()
	if GameState.prepare_continue():
		get_tree().change_scene_to_file(MISSION)


func _on_save() -> void:
	Sfx.play_ui()
	if GameState.save_to_disk():
		_status.text = "MISSION SAVED"
	else:
		_status.text = "NOTHING TO SAVE"
	_refresh_buttons()


func _toggle_settings() -> void:
	Sfx.play_ui()
	_settings_panel.visible = not _settings_panel.visible
