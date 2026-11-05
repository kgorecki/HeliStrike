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
	if ground_ray and ground_ray.is_colliding():
		ground_distance = global_position.y - ground_ray.get_collision_point().y
	else:
		ground_distance = 80.0


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
			if dist > 1400.0:
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
	if missile_cd > 0.0 or missile_ammo <= 0:
		return
	missile_ammo -= 1
	missile_cd = missile_interval
	var spawn: Marker3D = missile_right if pylon_toggle else missile_left
	pylon_toggle = not pylon_toggle
	var m := Missile.new()
	m.process_mode = Node.PROCESS_MODE_PAUSABLE
	m.velocity = aim_direction() * 40.0 + velocity
	if has_lock():
		m.target = locked_target
	get_parent().add_child(m)
	m.global_transform = spawn.global_transform
	m.global_position = spawn.global_position + aim_direction() * 2.0
	Sfx.play_3d(get_parent(), "missile", spawn.global_position, -4.0)
	fired_missile.emit()


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
	missile_ammo = int(data.get("missiles", missile_ammo))
	hull = float(data.get("hull", 100.0))
	camera_mode = int(data.get("camera", 0))
	flight_time = float(data.get("time", 0.0))
	_apply_camera()
