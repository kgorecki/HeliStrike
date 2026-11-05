extends Node3D

const ARMING := "res://scenes/ui/arming.tscn"
const BRIEFING := "res://scenes/ui/briefing.tscn"

var _index: int = 0
var _heli: Node3D
var _title: Label
var _role: Label
var _blurb: Label
var _ordnance: Label
var _stats: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_index = HeliCatalog.IDS.find(GameState.selected_heli)
	if _index < 0:
		_index = 0
	_build_world()
	_build_ui()
	_show_current()


func _process(delta: float) -> void:
	if _heli:
		_heli.rotate_y(delta * 0.22)
		var rotor := _heli.get_node_or_null("MainRotor")
		if rotor:
			rotor.rotate_y(delta * 16.0)
		var tail := _heli.get_node_or_null("TailRotor")
		if tail:
			tail.rotate_y(delta * 32.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("yaw_left") or event.is_action_pressed("roll_left"):
		_cycle(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("yaw_right") or event.is_action_pressed("roll_right"):
		_cycle(1)
		get_viewport().set_input_as_handled()


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.16, 0.22, 0.28)
	sky_mat.sky_horizon_color = Color(0.55, 0.42, 0.28)
	sky_mat.ground_bottom_color = Color(0.14, 0.13, 0.10)
	sky_mat.ground_horizon_color = Color(0.32, 0.28, 0.18)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.5
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.45, 0.4, 0.3)
	environment.fog_density = 0.01
	env.environment = environment
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-32, 50, 0)
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(5, 6, 7)
	fill.light_energy = 2.2
	fill.omni_range = 30.0
	add_child(fill)

	var cam := Camera3D.new()
	cam.position = Vector3(12.5, 4.2, 8.2)
	cam.current = true
	add_child(cam)
	cam.look_at(Vector3(0, 1.4, 0.2))

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.22, 0.22, 0.18)
	ground.material_override = gmat
	add_child(ground)
	var pad := MeshInstance3D.new()
	var pad_mesh := CylinderMesh.new()
	pad_mesh.top_radius = 8.0
	pad_mesh.bottom_radius = 8.0
	pad_mesh.height = 0.08
	pad.mesh = pad_mesh
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.28, 0.3, 0.24)
	pad.material_override = pmat
	pad.position.y = 0.04
	add_child(pad)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.02, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	dim.offset_right = 640
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_bottom", 40)
	layer.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	root.add_child(ThemeUtil.label("FARP WATCHTOWER  /  HANGAR", 13, ThemeUtil.MUTED))
	root.add_child(ThemeUtil.label("SELECT AIRCRAFT", 40, ThemeUtil.AMBER))
	_title = ThemeUtil.label("", 26, ThemeUtil.HUD)
	root.add_child(_title)
	_role = ThemeUtil.label("", 14, ThemeUtil.OLIVE)
	root.add_child(_role)
	_blurb = ThemeUtil.label("", 15, ThemeUtil.TEXT)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size.x = 520
	root.add_child(_blurb)
	_ordnance = ThemeUtil.label("", 14, ThemeUtil.MUTED)
	root.add_child(_ordnance)
	_stats = ThemeUtil.label("", 14, ThemeUtil.TEXT)
	root.add_child(_stats)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	root.add_child(spacer)

	var cycle := HBoxContainer.new()
	cycle.add_theme_constant_override("separation", 12)
	root.add_child(cycle)
	var prev := ThemeUtil.button("<  PREV", 140)
	prev.pressed.connect(func() -> void: _cycle(-1))
	cycle.add_child(prev)
	var next := ThemeUtil.button("NEXT  >", 140)
	next.pressed.connect(func() -> void: _cycle(1))
	cycle.add_child(next)

	var go := ThemeUtil.button("SELECT ORDNANCE", 320)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_start)
	root.add_child(go)
	var back := ThemeUtil.button("BACK", 160)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_back)
	root.add_child(back)
	root.add_child(ThemeUtil.label("A / D  OR  ARROWS TO CYCLE", 12, ThemeUtil.MUTED))


func _show_current() -> void:
	var id := HeliCatalog.IDS[_index]
	var spec := HeliCatalog.spec(id)
	if _heli:
		_heli.queue_free()
		_heli = null
	_heli = HeliBuilder.build_model(id)
	_heli.position = Vector3(0, float(spec.get("preview_y", 1.1)), 0)
	add_child(_heli)
	_title.text = str(spec["title"])
	_role.text = str(spec["role"])
	_blurb.text = str(spec["blurb"])
	_ordnance.text = str(spec["ordnance"])
	_stats.text = "GUN %d RDS    PYLONS %d    HULL %d    VNE %d KM/H" % [
		int(spec["cannon_max"]),
		int(spec["missile_slots"]),
		int(spec["hull"]),
		int(float(spec["max_speed"]) * 3.6),
	]


func _cycle(dir: int) -> void:
	Sfx.play_ui()
	_index = posmod(_index + dir, HeliCatalog.IDS.size())
	_show_current()


func _start() -> void:
	Sfx.play_ui()
	var id := HeliCatalog.IDS[_index]
	GameState.selected_heli = id
	var slots := int(HeliCatalog.spec(id)["missile_slots"])
	if GameState.missile_loadout.size() != slots:
		GameState.missile_loadout = MissileCatalog.default_for(id)
	GameState.save_settings()
	if not GameState.has_session():
		GameState.start_new_session()
	GameState.session["heli_id"] = id
	GameState.session["heli"] = {}
	GameState.session["destroyed_ids"] = []
	GameState.restore_on_start = false
	get_tree().change_scene_to_file(ARMING)


func _back() -> void:
	Sfx.play_ui()
	get_tree().change_scene_to_file(BRIEFING)
