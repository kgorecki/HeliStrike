class_name Helicopter
extends CharacterBody3D

signal crashed
signal target_destroyed
signal fired_cannon
signal fired_missile

const GRAVITY := 9.81

var heli_id: String = "apache"
var hover_collective: float = 0.62
var max_thrust: float = 16.8
var max_speed: float = 82.0
var pitch_rate: float = 0.95
var roll_rate: float = 1.15
var yaw_rate: float = 1.35
var cannon_max: int = 450
var missile_max: int = 8
var cannon_interval: float = 0.09
var missile_interval: float = 1.15
var rotor_spin_rate: float = 28.0

var main_rotor: Node3D
var tail_rotor: Node3D
var rotor_disc: MeshInstance3D
var cockpit_cam: Camera3D
var chase_cam: Camera3D
var cannon_muzzle: Marker3D
var missile_left: Marker3D
var missile_right: Marker3D
var ground_ray: RayCast3D

var collective: float = 0.62
var stick: Vector2 = Vector2.ZERO
var camera_mode: int = 0
var cannon_ammo: int = 450
var missile_ammo: int = 8
var hull: float = 100.0
var cannon_cd: float = 0.0
var missile_cd: float = 0.0
var pylon_toggle: bool = false
var _pylons: Array[Dictionary] = []
var _selected_pylon: int = 0
var locked_target: GroundTarget
var lock_timer: float = 0.0
var rotor_rpm: float = 0.0
var alive: bool = true
var flight_time: float = 0.0
var rotor_player: AudioStreamPlayer3D
var ground_distance: float = 20.0

func _ready() -> void:
	add_to_group("heli")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	up_direction = Vector3.UP
	collision_layer = 2
	collision_mask = 1 | 8
	heli_id = HeliCatalog.clamp_id(GameState.selected_heli)
	HeliCatalog.apply(self, heli_id)
	collective = hover_collective
	_install_loadout(GameState.missile_loadout)
	HeliBuilder.attach(self, heli_id)
	_apply_camera()
	rotor_player = Sfx.play_rotor(self)


func _unhandled_input(event: InputEvent) -> void:
	if not alive:
		return
	if event.is_action_pressed("camera_toggle"):
		camera_mode = 1 - camera_mode
		_apply_camera()
		get_viewport().set_input_as_handled()
	var slot := _pylon_from_key(event)
	if slot >= 0:
		_selected_pylon = slot
		get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and GameState.mouse_steering and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		var sens := 0.0024 * GameState.mouse_sensitivity
		var y_sign := -1.0 if GameState.invert_y else 1.0
		stick.x = clampf(stick.x + motion.relative.x * sens, -1.0, 1.0)
		stick.y = clampf(stick.y + motion.relative.y * sens * y_sign, -1.0, 1.0)


func _physics_process(delta: float) -> void:
	if not alive:
		velocity += Vector3.DOWN * GRAVITY * delta
		move_and_slide()
		return

	flight_time += delta
	_read_collective(delta)
	_read_keys(delta)
	stick = stick.move_toward(Vector2.ZERO, 0.85 * delta)
	_fly(delta)
	_update_lock(delta)
	_weapons(delta)
	_spin_rotors(delta)
	_update_audio()


func _read_collective(delta: float) -> void:
	var col := Input.get_axis("collective_down", "collective_up")
	collective = clampf(collective + col * 0.45 * delta, 0.05, 1.0)


func _read_keys(delta: float) -> void:
	var pitch := Input.get_axis("pitch_back", "pitch_forward")
	var roll := Input.get_axis("roll_left", "roll_right")
	if absf(pitch) > 0.05:
		stick.y = clampf(stick.y + pitch * 1.8 * delta, -1.0, 1.0)
	if absf(roll) > 0.05:
		stick.x = clampf(stick.x + roll * 1.8 * delta, -1.0, 1.0)


func _fly(delta: float) -> void:
	var pitch_rate := 0.95
	var roll_rate := 1.15
	var yaw_in := Input.get_axis("yaw_left", "yaw_right")
	rotate_object_local(Vector3.RIGHT, -stick.y * pitch_rate * delta)
	rotate_object_local(Vector3.FORWARD, stick.x * roll_rate * delta)
	rotate_y(-yaw_in * yaw_rate * delta)

	var euler := rotation
	euler.x = clampf(euler.x, deg_to_rad(-55), deg_to_rad(45))
	euler.z = clampf(euler.z, deg_to_rad(-55), deg_to_rad(55))
	rotation = euler

	_probe_ground()
	var thrust := collective * max_thrust
	if ground_distance < 8.0:
		thrust *= lerpf(1.16, 1.0, ground_distance / 8.0)
	var airspeed := Vector3(velocity.x, 0.0, velocity.z).length()
	thrust *= 1.0 + clampf(airspeed / 28.0, 0.0, 0.16)

	var accel := global_transform.basis.y * thrust + Vector3.DOWN * GRAVITY
	velocity += accel * delta

	var forward := -global_transform.basis.z
	var vel_fwd := forward * velocity.dot(forward)
	var vel_rest := velocity - vel_fwd
	velocity = vel_fwd * (1.0 - 0.18 * delta) + vel_rest * (1.0 - 1.55 * delta)

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	var impact := velocity.length()
	move_and_slide()

	if is_on_floor() or ground_distance < 0.55:
		if impact > 22.0 and velocity.y < -8.0:
			_take_damage(100.0)
		elif collective < hover_collective + 0.04:
			velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
			if velocity.y < 0.0:
				velocity.y = 0.0


func _probe_ground() -> void:
	if ground_ray == null:
		ground_distance = maxf(global_position.y, 0.0)
		return
	ground_ray.global_basis = Basis.IDENTITY
	ground_ray.force_raycast_update()
	if ground_ray.is_colliding():
		ground_distance = maxf(global_position.y - ground_ray.get_collision_point().y, 0.0)
	else:
		ground_distance = maxf(global_position.y, 0.0)


func _spin_rotors(delta: float) -> void:
	rotor_rpm = move_toward(rotor_rpm, 1.0, delta * 0.6)
	if main_rotor:
		main_rotor.rotate_y(delta * rotor_spin_rate * rotor_rpm)
	if tail_rotor:
		tail_rotor.rotate_y(delta * 55.0 * rotor_rpm)
	if rotor_disc and rotor_disc.material_override is StandardMaterial3D:
		var mat := rotor_disc.material_override as StandardMaterial3D
		var disc_color := mat.albedo_color
		disc_color.a = rotor_rpm * 0.22
		mat.albedo_color = disc_color


func _update_audio() -> void:
	if rotor_player:
		rotor_player.pitch_scale = 0.75 + rotor_rpm * 0.35 + clampf(collective, 0.0, 1.0) * 0.12


func _update_lock(delta: float) -> void:
	var best: GroundTarget = null
	var best_ang := deg_to_rad(7.0)
	var aim := aim_direction()
	var origin := aim_origin()
	for node in get_tree().get_nodes_in_group("ground_target"):
		if node is GroundTarget and (node as GroundTarget).alive:
			var tgt := node as GroundTarget
			var to := tgt.global_position + Vector3.UP * 1.2 - origin
			var dist := to.length()
			if dist > 1600.0:
				continue
			var ang := aim.angle_to(to.normalized())
			if ang < best_ang:
				best_ang = ang
				best = tgt
	if best == locked_target and best != null:
		lock_timer = minf(lock_timer + delta, 0.85)
	else:
		locked_target = best
		lock_timer = 0.0 if best == null else 0.05


func has_lock() -> bool:
	return locked_target != null and locked_target.alive and lock_timer >= 0.75


func _weapons(delta: float) -> void:
	cannon_cd = maxf(cannon_cd - delta, 0.0)
	missile_cd = maxf(missile_cd - delta, 0.0)
	if Input.is_action_pressed("fire_cannon"):
		_fire_cannon()
	if Input.is_action_just_pressed("fire_missile"):
		_fire_missile()


func _fire_cannon() -> void:
	if cannon_cd > 0.0 or cannon_ammo <= 0:
		return
	cannon_ammo -= 1
	cannon_cd = cannon_interval
	var round := CannonRound.new()
	round.process_mode = Node.PROCESS_MODE_PAUSABLE
	var spread := Vector3(randf_range(-0.012, 0.012), randf_range(-0.008, 0.004), 0.0)
	var dir := (aim_direction() + spread).normalized()
	round.velocity = dir * 420.0 + velocity
	get_parent().add_child(round)
	round.global_position = cannon_muzzle.global_position + dir * 2.4
	round.look_at(round.global_position + dir, Vector3.UP)
	Sfx.play_3d(get_parent(), "cannon", cannon_muzzle.global_position, -6.0)
	fired_cannon.emit()


func _fire_missile() -> void:
	if missile_cd > 0.0 or _selected_pylon < 0 or _selected_pylon >= _pylons.size():
		return
	var slot := _pylons[_selected_pylon]
	if int(slot["remaining"]) <= 0:
		return
	var data := MissileCatalog.spec(str(slot["id"]))
	slot["remaining"] = int(slot["remaining"]) - 1
	_pylons[_selected_pylon] = slot
	missile_ammo = _rounds_left()
	missile_cd = float(data["shot_cd"]) if str(data["kind"]) == "CLUSTER" else missile_interval
	var spread := float(data["spread_deg"])
	var yaw := randf_range(-spread, spread)
	var pitch := randf_range(-spread, spread) * 0.35
	_spawn_missile(data, yaw, pitch)
	Sfx.play_3d(get_parent(), "missile", global_position, -4.0)
	fired_missile.emit()


func _spawn_missile(data: Dictionary, yaw_deg: float, pitch_deg: float) -> void:
	var spawn: Marker3D = missile_right if pylon_toggle else missile_left
	pylon_toggle = not pylon_toggle
	var dir := aim_direction()
	dir = dir.rotated(global_transform.basis.y, deg_to_rad(yaw_deg))
	dir = dir.rotated(global_transform.basis.x, deg_to_rad(pitch_deg))
	var m := Missile.new()
	m.process_mode = Node.PROCESS_MODE_PAUSABLE
	m.damage = float(data["damage"])
	m.max_range = float(data["range"])
	m.max_speed = float(data["speed"])
	m.accel = float(data["accel"])
	m.guided = bool(data["guided"])
	m.body_scale = float(data["scale"])
	m.velocity = dir * float(data["launch_speed"]) + velocity
	if bool(data["guided"]) and has_lock():
		m.target = locked_target
	var parent := get_parent()
	if parent == null or spawn == null:
		return
	parent.add_child(m)
	m.global_position = spawn.global_position + dir * 2.0
	if dir.length_squared() > 0.01:
		m.look_at(m.global_position + dir, Vector3.UP)


func _install_loadout(ids: Array) -> void:
	var src := ids
	if src.size() != missile_max:
		src = MissileCatalog.default_for(heli_id)
	_pylons.clear()
	for i in missile_max:
		var id := MissileCatalog.clamp_id(str(src[i]))
		_pylons.append({
			"id": id,
			"remaining": int(MissileCatalog.spec(id)["count"]),
		})
	_selected_pylon = 0
	missile_ammo = _rounds_left()


func _restore_pylons(saved: Array) -> void:
	_pylons.clear()
	for item in saved:
		if item is Dictionary:
			var row: Dictionary = item
			var id := MissileCatalog.clamp_id(str(row.get("id", "hellfire")))
			var capacity := int(MissileCatalog.spec(id)["count"])
			var remaining := capacity
			if row.has("remaining"):
				remaining = clampi(int(row["remaining"]), 0, capacity)
			elif bool(row.get("spent", false)):
				remaining = 0
			_pylons.append({"id": id, "remaining": remaining})
	if _pylons.is_empty():
		_install_loadout(GameState.missile_loadout)
		return
	missile_max = _pylons.size()
	_selected_pylon = clampi(_selected_pylon, 0, _pylons.size() - 1)
	missile_ammo = _rounds_left()


func _rounds_left() -> int:
	var n := 0
	for slot in _pylons:
		n += int(slot["remaining"])
	return n


func _pylon_from_key(event: InputEvent) -> int:
	if not event is InputEventKey or not event.pressed or event.echo:
		return -1
	var key := event as InputEventKey
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	var slot := -1
	if code >= KEY_1 and code <= KEY_9:
		slot = int(code) - int(KEY_1)
	elif code >= KEY_KP_1 and code <= KEY_KP_9:
		slot = int(code) - int(KEY_KP_1)
	if slot < 0 or slot >= _pylons.size():
		return -1
	return slot


func hud_stores() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for i in _pylons.size():
		var slot: Dictionary = _pylons[i]
		var data := MissileCatalog.spec(str(slot["id"]))
		var tag := "[%d]" % [i + 1] if i == _selected_pylon else str(i + 1)
		parts.append("%s %s %d/%d" % [tag, str(data["short"]), int(slot["remaining"]), int(data["count"])])
	return "  ".join(parts)


func selected_store() -> Dictionary:
	if _selected_pylon < 0 or _selected_pylon >= _pylons.size():
		return {}
	var slot: Dictionary = _pylons[_selected_pylon]
	var data := MissileCatalog.spec(str(slot["id"]))
	return {
		"index": _selected_pylon + 1,
		"title": str(data["title"]),
		"remaining": int(slot["remaining"]),
		"count": int(data["count"]),
		"range": float(data["range"]),
	}


func lock_distance_m() -> float:
	if locked_target == null or not is_instance_valid(locked_target) or not locked_target.alive:
		return -1.0
	return global_position.distance_to(locked_target.global_position)


func aim_origin() -> Vector3:
	if cannon_muzzle:
		return cannon_muzzle.global_position
	return global_position


func aim_direction() -> Vector3:
	return -global_transform.basis.z.normalized()


func active_camera() -> Camera3D:
	return chase_cam if camera_mode == 1 else cockpit_cam


func _apply_camera() -> void:
	if cockpit_cam:
		cockpit_cam.current = camera_mode == 0
	if chase_cam:
		chase_cam.current = camera_mode == 1


func _take_damage(amount: float) -> void:
	if not alive:
		return
	hull = maxf(hull - amount, 0.0)
	if hull <= 0.0:
		alive = false
		crashed.emit()
		Explosion.spawn(get_parent(), global_position + Vector3.UP, 1.6)


func notify_target_down() -> void:
	target_destroyed.emit()


func airspeed_kms() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length() * 3.6


func altitude_agl() -> float:
	return ground_distance


func heading_deg() -> float:
	var fwd := -global_transform.basis.z
	var h := rad_to_deg(atan2(fwd.x, -fwd.z))
	if h < 0.0:
		h += 360.0
	return h


func to_save() -> Dictionary:
	var b := global_transform.basis
	return {
		"x": global_position.x,
		"y": global_position.y,
		"z": global_position.z,
		"basis": [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z],
		"vx": velocity.x,
		"vy": velocity.y,
		"vz": velocity.z,
		"collective": collective,
		"cannon": cannon_ammo,
		"missiles": missile_ammo,
		"pylons": _pylons.duplicate(true),
		"pylon": _selected_pylon,
		"hull": hull,
		"camera": camera_mode,
		"time": flight_time,
		"heli_id": heli_id,
	}


func from_save(data: Dictionary) -> void:
	if data.is_empty():
		return
	global_position = Vector3(float(data.x), float(data.y), float(data.z))
	var arr: Array = data.get("basis", [])
	if arr.size() == 9:
		global_transform.basis = Basis(
			Vector3(arr[0], arr[1], arr[2]),
			Vector3(arr[3], arr[4], arr[5]),
			Vector3(arr[6], arr[7], arr[8])
		)
	velocity = Vector3(float(data.get("vx", 0)), float(data.get("vy", 0)), float(data.get("vz", 0)))
	collective = float(data.get("collective", hover_collective))
	cannon_ammo = int(data.get("cannon", cannon_ammo))
	_selected_pylon = int(data.get("pylon", _selected_pylon))
	if data.has("pylons") and data["pylons"] is Array:
		_restore_pylons(data["pylons"])
	else:
		missile_ammo = int(data.get("missiles", missile_ammo))
	hull = float(data.get("hull", 100.0))
	camera_mode = int(data.get("camera", 0))
	flight_time = float(data.get("time", 0.0))
	_apply_camera()
