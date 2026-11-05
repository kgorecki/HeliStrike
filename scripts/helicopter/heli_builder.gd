class_name HeliBuilder
extends RefCounted

static func olive() -> StandardMaterial3D:
	return _mat(Color(0.34, 0.40, 0.22), 0.35, 0.42)


static func olive_dark() -> StandardMaterial3D:
	return _mat(Color(0.22, 0.26, 0.16), 0.4, 0.38)


static func metal() -> StandardMaterial3D:
	return _mat(Color(0.18, 0.19, 0.18), 0.75, 0.35)


static func glass() -> StandardMaterial3D:
	var m := _mat(Color(0.15, 0.22, 0.26, 0.18), 0.05, 0.06)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.06
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func black() -> StandardMaterial3D:
	return _mat(Color(0.04, 0.04, 0.04), 0.45, 0.15)


static func charcoal() -> StandardMaterial3D:
	return _mat(Color(0.16, 0.17, 0.18), 0.4, 0.38)


static func bone() -> StandardMaterial3D:
	return _mat(Color(0.78, 0.76, 0.70), 0.12, 0.55)


static func amber_emit() -> StandardMaterial3D:
	var m := _mat(Color(0.9, 0.65, 0.1), 0.3, 0.2)
	m.emission_enabled = true
	m.emission = Color(0.9, 0.55, 0.05)
	m.emission_energy_multiplier = 1.8
	return m


static func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


static func mesh_at(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func cyl(radius: float, height: float, rings: int = 12) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = rings
	return m


static func sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 8
	return m


static func build_model(kind: String = "apache") -> Node3D:
	var root := Node3D.new()
	root.name = "HeliModel"
	match HeliCatalog.clamp_id(kind):
		"defender":
			_build_defender_airframe(root)
			var main_rotor := _build_main_rotor(5, 4.15, 0.22)
			main_rotor.position = Vector3(0, 2.15, 0.05)
			root.add_child(main_rotor)
			var tail_rotor := _build_tail_rotor(2, 0.85)
			tail_rotor.position = Vector3(-0.32, 1.85, 5.15)
			root.add_child(tail_rotor)
		"bell222":
			_build_bell_airframe(root)
			var main_rotor := _build_main_rotor(2, 6.2, 0.38)
			main_rotor.position = Vector3(0, 2.95, 0.2)
			root.add_child(main_rotor)
			var tail_rotor := _build_tail_rotor(2, 1.15)
			tail_rotor.position = Vector3(-0.45, 2.55, 7.55)
			root.add_child(tail_rotor)
		_:
			_build_apache_airframe(root)
			var main_rotor := _build_main_rotor(4, 7.1, 0.32)
			main_rotor.position = Vector3(0, 2.85, 0.35)
			root.add_child(main_rotor)
			var tail_rotor := _build_tail_rotor(4, 1.35)
			tail_rotor.position = Vector3(-0.55, 2.85, 8.35)
			root.add_child(tail_rotor)
	return root


static func attach(heli: Helicopter, kind: String = "apache") -> void:
	match HeliCatalog.clamp_id(kind):
		"defender":
			_attach_defender(heli)
		"bell222":
			_attach_bell(heli)
		_:
			_attach_apache(heli)


static func _attach_apache(heli: Helicopter) -> void:
	var visual := _visual_root(heli)
	_build_apache_airframe(visual)
	_build_apache_cockpit(visual)
	_add_rotors(heli, visual, Vector3(0, 2.85, 0.35), 4, 7.1, 0.32, Vector3(-0.55, 2.85, 8.35), 4, 1.35, 7.2)
	_add_cockpit_cam(heli, visual, Vector3(0, 1.68, -2.42), -6.0, 78.0)
	_add_chase_cam(heli, 16.5, Vector3(0, 3.8, 0))
	_add_hardpoints(heli, Vector3(0, 0.15, -4.6), Vector3(-2.6, 0.55, 0.6), Vector3(2.6, 0.55, 0.6))
	_add_collision(heli, 1.15, 11.5, Vector3(0, 1.15, 0.6))
	_add_ground_ray(heli)
	_nav_light(visual, Vector3(-2.8, 0.75, 0.4), Color(1, 0.1, 0.08))
	_nav_light(visual, Vector3(2.8, 0.75, 0.4), Color(0.1, 1, 0.15))
	_nav_light(visual, Vector3(0, 1.6, 8.6), Color(1, 1, 1))


static func _attach_defender(heli: Helicopter) -> void:
	var visual := _visual_root(heli)
	_build_defender_airframe(visual)
	_build_defender_cockpit(visual)
	_add_rotors(heli, visual, Vector3(0, 2.15, 0.05), 5, 4.15, 0.22, Vector3(-0.32, 1.85, 5.15), 2, 0.85, 4.2)
	_add_cockpit_cam(heli, visual, Vector3(0, 1.22, -0.15), -8.0, 80.0)
	_add_chase_cam(heli, 11.5, Vector3(0, 2.8, 0))
	_add_hardpoints(heli, Vector3(0.0, 0.45, -1.7), Vector3(-1.55, 0.62, 0.15), Vector3(1.55, 0.62, 0.15))
	_add_collision(heli, 0.85, 6.4, Vector3(0, 0.95, 0.35))
	_add_ground_ray(heli)
	_nav_light(visual, Vector3(-1.6, 0.7, 0.2), Color(1, 0.1, 0.08))
	_nav_light(visual, Vector3(1.6, 0.7, 0.2), Color(0.1, 1, 0.15))
	_nav_light(visual, Vector3(0, 1.5, 5.3), Color(1, 1, 1))


static func _attach_bell(heli: Helicopter) -> void:
	var visual := _visual_root(heli)
	_build_bell_airframe(visual)
	_build_bell_cockpit(visual)
	_add_rotors(heli, visual, Vector3(0, 2.95, 0.2), 2, 6.2, 0.38, Vector3(-0.45, 2.55, 7.55), 2, 1.15, 6.3)
	_add_cockpit_cam(heli, visual, Vector3(0, 1.48, -2.55), -5.0, 76.0)
	_add_chase_cam(heli, 17.5, Vector3(0, 3.6, 0))
	_add_hardpoints(heli, Vector3(0, 0.18, -4.15), Vector3(-2.15, 0.7, 0.35), Vector3(2.15, 0.7, 0.35))
	_add_collision(heli, 1.2, 10.6, Vector3(0, 1.2, 0.4))
	_add_ground_ray(heli)
	_nav_light(visual, Vector3(-1.7, 0.85, -0.2), Color(1, 0.1, 0.08))
	_nav_light(visual, Vector3(1.7, 0.85, -0.2), Color(0.1, 1, 0.15))
	_nav_light(visual, Vector3(0, 2.1, 7.7), Color(1, 1, 1))


static func _visual_root(heli: Helicopter) -> Node3D:
	var visual := Node3D.new()
	visual.name = "Visual"
	heli.add_child(visual)
	return visual


static func _add_rotors(heli: Helicopter, visual: Node3D, main_pos: Vector3, main_blades: int, main_len: float, main_w: float, tail_pos: Vector3, tail_blades: int, tail_len: float, disc_r: float) -> void:
	var main_rotor := _build_main_rotor(main_blades, main_len, main_w)
	main_rotor.position = main_pos
	visual.add_child(main_rotor)
	heli.main_rotor = main_rotor
	var tail_rotor := _build_tail_rotor(tail_blades, tail_len)
	tail_rotor.position = tail_pos
	visual.add_child(tail_rotor)
	heli.tail_rotor = tail_rotor
	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = disc_r
	disc_mesh.bottom_radius = disc_r
	disc_mesh.height = 0.03
	disc_mesh.radial_segments = 24
	disc.mesh = disc_mesh
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.0)
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	disc.material_override = disc_mat
	disc.position = main_pos + Vector3(0, 0.02, 0)
	visual.add_child(disc)
	heli.rotor_disc = disc


static func _add_cockpit_cam(heli: Helicopter, visual: Node3D, pos: Vector3, pitch_deg: float, fov: float) -> void:
	var cockpit := Camera3D.new()
	cockpit.name = "CockpitCamera"
	cockpit.position = pos
	cockpit.rotation_degrees.x = pitch_deg
	cockpit.fov = fov
	cockpit.near = 0.12
	visual.add_child(cockpit)
	heli.cockpit_cam = cockpit


static func _add_chase_cam(heli: Helicopter, length: float, pos: Vector3) -> void:
	var arm := SpringArm3D.new()
	arm.name = "ChaseArm"
	arm.spring_length = length
	arm.position = pos
	arm.rotation_degrees.x = -12.0
	arm.collision_mask = 1
	var chase := Camera3D.new()
	chase.name = "ChaseCamera"
	chase.fov = 70.0
	arm.add_child(chase)
	heli.add_child(arm)
	heli.chase_cam = chase


static func _add_hardpoints(heli: Helicopter, muzzle_pos: Vector3, left: Vector3, right: Vector3) -> void:
	var muzzle := Marker3D.new()
	muzzle.name = "CannonMuzzle"
	muzzle.position = muzzle_pos
	heli.add_child(muzzle)
	heli.cannon_muzzle = muzzle
	var left_pylon := Marker3D.new()
	left_pylon.position = left
	heli.add_child(left_pylon)
	heli.missile_left = left_pylon
	var right_pylon := Marker3D.new()
	right_pylon.position = right
	heli.add_child(right_pylon)
	heli.missile_right = right_pylon


static func _add_collision(heli: Helicopter, radius: float, height: float, pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	col.shape = capsule
	col.rotation_degrees.x = 90
	col.position = pos
	heli.add_child(col)


static func _add_ground_ray(heli: Helicopter) -> void:
	var ray := RayCast3D.new()
	ray.target_position = Vector3(0, -4000, 0)
	ray.position = Vector3(0, 1.0, 0)
	ray.collision_mask = 1
	ray.hit_from_inside = true
	heli.add_child(ray)
	heli.ground_ray = ray


static func _build_apache_airframe(parent: Node3D) -> void:
	var o := olive()
	var d := olive_dark()
	var met := metal()
	var gl := glass()
	var blk := black()
	mesh_at(parent, box(Vector3(1.55, 1.35, 4.6)), o, Vector3(0, 1.05, 1.55))
	mesh_at(parent, box(Vector3(1.15, 0.42, 3.4)), o, Vector3(0, 0.52, -2.15))
	mesh_at(parent, box(Vector3(0.95, 0.5, 1.7)), o, Vector3(0, 0.5, -4.05))
	mesh_at(parent, sphere(0.32), met, Vector3(0, 0.18, -4.85))
	mesh_at(parent, sphere(0.78), gl, Vector3(0, 1.52, -2.95))
	mesh_at(parent, sphere(0.78), gl, Vector3(0, 1.58, -1.45))
	mesh_at(parent, box(Vector3(0.42, 0.42, 7.4)), o, Vector3(0, 1.35, 6.4))
	mesh_at(parent, box(Vector3(0.16, 1.85, 0.85)), d, Vector3(0, 2.35, 8.35))
	mesh_at(parent, box(Vector3(3.1, 0.12, 0.55)), d, Vector3(0, 3.25, 8.35))
	mesh_at(parent, box(Vector3(6.4, 0.12, 1.05)), d, Vector3(0, 0.72, 0.55))
	mesh_at(parent, cyl(0.42, 2.1, 10), met, Vector3(-0.72, 1.85, 1.15), Vector3(0, 0, deg_to_rad(82)))
	mesh_at(parent, cyl(0.42, 2.1, 10), met, Vector3(0.72, 1.85, 1.15), Vector3(0, 0, deg_to_rad(-82)))
	mesh_at(parent, cyl(0.18, 1.4), met, Vector3(0, 0.15, -3.85), Vector3(deg_to_rad(90), 0, 0))
	mesh_at(parent, box(Vector3(0.22, 0.14, 0.7)), blk, Vector3(0, 0.12, -4.45))
	for x in [-1.0, 1.0]:
		mesh_at(parent, cyl(0.28, 0.22, 10), blk, Vector3(x, 0.22, 1.15), Vector3(0, 0, deg_to_rad(90)))
		mesh_at(parent, box(Vector3(0.12, 0.85, 0.12)), met, Vector3(x, 0.7, 1.15))
	mesh_at(parent, cyl(0.16, 0.18, 10), blk, Vector3(0, 0.18, 6.6), Vector3(0, 0, deg_to_rad(90)))
	mesh_at(parent, box(Vector3(0.1, 0.7, 0.1)), met, Vector3(0, 0.55, 6.6))
	for side in [-1.0, 1.0]:
		for i in 2:
			var z := 0.15 + float(i) * 0.85
			mesh_at(parent, box(Vector3(0.18, 0.18, 1.35)), met, Vector3(side * 2.55, 0.52, z))
	mesh_at(parent, cyl(0.22, 0.55), met, Vector3(0, 2.55, 0.35))
	mesh_at(parent, box(Vector3(0.08, 0.35, 1.1)), amber_emit(), Vector3(0, 0.55, -3.2))


static func _build_apache_cockpit(parent: Node3D) -> void:
	mesh_at(parent, box(Vector3(1.05, 0.07, 0.55)), olive_dark(), Vector3(0, 1.12, -2.85))
	mesh_at(parent, box(Vector3(0.05, 0.36, 0.05)), metal(), Vector3(0.2, 1.26, -2.55))
	mesh_at(parent, box(Vector3(0.07, 0.05, 0.28)), metal(), Vector3(-0.38, 1.16, -2.5))


static func _build_defender_airframe(parent: Node3D) -> void:
	var body := black()
	var d := olive_dark()
	var met := metal()
	var gl := glass()
	var blk := black()
	mesh_at(parent, sphere(0.95), body, Vector3(0, 1.05, -0.15))
	mesh_at(parent, box(Vector3(1.35, 1.05, 1.9)), body, Vector3(0, 0.95, 0.55))
	mesh_at(parent, sphere(0.88), gl, Vector3(0, 1.18, -0.55))
	mesh_at(parent, box(Vector3(0.22, 0.22, 4.4)), d, Vector3(0, 1.15, 3.2))
	mesh_at(parent, box(Vector3(0.12, 1.15, 0.55)), d, Vector3(0, 1.7, 5.15))
	mesh_at(parent, box(Vector3(1.7, 0.08, 0.35)), d, Vector3(0, 2.22, 5.15))
	mesh_at(parent, box(Vector3(3.2, 0.08, 0.7)), d, Vector3(0, 0.72, 0.25))
	mesh_at(parent, cyl(0.16, 0.7), met, Vector3(0, 1.85, 0.05))
	for side in [-1.0, 1.0]:
		mesh_at(parent, cyl(0.09, 2.4), met, Vector3(side * 0.55, 0.22, 0.15), Vector3(deg_to_rad(90), 0, 0))
		mesh_at(parent, box(Vector3(0.08, 0.55, 0.08)), met, Vector3(side * 0.55, 0.5, -0.7))
		mesh_at(parent, box(Vector3(0.08, 0.55, 0.08)), met, Vector3(side * 0.55, 0.5, 0.95))
		mesh_at(parent, cyl(0.12, 1.15), met, Vector3(side * 1.45, 0.55, 0.1), Vector3(deg_to_rad(90), 0, 0))
		mesh_at(parent, cyl(0.16, 0.9), blk, Vector3(side * 1.55, 0.7, 0.55), Vector3(deg_to_rad(90), 0, 0))
	mesh_at(parent, box(Vector3(0.06, 0.22, 0.7)), amber_emit(), Vector3(0, 0.55, -1.15))


static func _build_defender_cockpit(parent: Node3D) -> void:
	mesh_at(parent, box(Vector3(0.95, 0.06, 0.45)), olive_dark(), Vector3(0, 0.82, -0.35))
	mesh_at(parent, box(Vector3(0.05, 0.28, 0.05)), metal(), Vector3(0.18, 0.95, -0.15))


static func _build_bell_airframe(parent: Node3D) -> void:
	var hull := charcoal()
	var stripe := bone()
	var met := metal()
	var gl := glass()
	var blk := black()
	mesh_at(parent, box(Vector3(1.7, 1.45, 5.6)), hull, Vector3(0, 1.15, 0.15))
	mesh_at(parent, box(Vector3(1.25, 0.95, 2.4)), hull, Vector3(0, 1.05, -2.85))
	mesh_at(parent, sphere(0.55), hull, Vector3(0, 0.85, -4.05))
	mesh_at(parent, box(Vector3(1.55, 0.12, 5.2)), stripe, Vector3(0, 0.55, 0.1))
	mesh_at(parent, box(Vector3(1.45, 0.55, 2.2)), gl, Vector3(0, 1.55, -2.55))
	for z in [-0.4, 0.7, 1.8]:
		mesh_at(parent, box(Vector3(0.06, 0.55, 0.7)), gl, Vector3(-0.86, 1.35, z))
		mesh_at(parent, box(Vector3(0.06, 0.55, 0.7)), gl, Vector3(0.86, 1.35, z))
	mesh_at(parent, box(Vector3(0.48, 0.48, 5.8)), hull, Vector3(0, 1.55, 5.2))
	mesh_at(parent, box(Vector3(0.14, 1.55, 0.7)), hull, Vector3(0, 2.4, 7.55))
	mesh_at(parent, box(Vector3(2.6, 0.1, 0.5)), hull, Vector3(0, 3.15, 7.55))
	mesh_at(parent, cyl(0.38, 1.7, 10), met, Vector3(-0.55, 2.15, 0.55), Vector3(0, 0, deg_to_rad(78)))
	mesh_at(parent, cyl(0.38, 1.7, 10), met, Vector3(0.55, 2.15, 0.55), Vector3(0, 0, deg_to_rad(-78)))
	mesh_at(parent, cyl(0.16, 0.9), met, Vector3(0, 2.55, 0.2))
	mesh_at(parent, cyl(0.14, 1.1), met, Vector3(0, 0.22, -3.55), Vector3(deg_to_rad(90), 0, 0))
	mesh_at(parent, box(Vector3(0.18, 0.12, 0.55)), blk, Vector3(0, 0.18, -4.15))
	for x in [-0.85, 0.85]:
		mesh_at(parent, cyl(0.22, 0.18, 10), blk, Vector3(x, 0.22, 1.35), Vector3(0, 0, deg_to_rad(90)))
		mesh_at(parent, box(Vector3(0.1, 0.75, 0.1)), met, Vector3(x, 0.65, 1.35))
	mesh_at(parent, cyl(0.16, 0.16, 10), blk, Vector3(0, 0.2, 4.6), Vector3(0, 0, deg_to_rad(90)))
	mesh_at(parent, box(Vector3(0.08, 0.7, 0.08)), met, Vector3(0, 0.55, 4.6))
	for side in [-1.0, 1.0]:
		mesh_at(parent, box(Vector3(0.16, 0.16, 1.2)), met, Vector3(side * 2.05, 0.72, 0.35))
	mesh_at(parent, box(Vector3(0.08, 0.28, 0.9)), amber_emit(), Vector3(0, 0.7, -3.3))


static func _build_bell_cockpit(parent: Node3D) -> void:
	mesh_at(parent, box(Vector3(1.15, 0.07, 0.6)), charcoal(), Vector3(0, 1.05, -2.75))
	mesh_at(parent, box(Vector3(0.05, 0.32, 0.05)), metal(), Vector3(0.22, 1.18, -2.45))
	mesh_at(parent, box(Vector3(0.07, 0.05, 0.3)), metal(), Vector3(-0.4, 1.08, -2.4))


static func _build_main_rotor(blades: int, length: float, width: float) -> Node3D:
	var rotor := Node3D.new()
	rotor.name = "MainRotor"
	mesh_at(rotor, cyl(0.28, 0.16), metal(), Vector3.ZERO)
	for i in blades:
		var blade := Node3D.new()
		blade.rotation.y = float(i) * TAU / float(blades)
		rotor.add_child(blade)
		mesh_at(blade, box(Vector3(width, 0.04, length)), black(), Vector3(0, 0, -length * 0.5))
		mesh_at(blade, box(Vector3(width, 0.045, 0.22)), amber_emit(), Vector3(0, 0, -length + 0.05))
	return rotor


static func _build_tail_rotor(blades: int, length: float) -> Node3D:
	var rotor := Node3D.new()
	rotor.name = "TailRotor"
	rotor.rotation_degrees.z = 90
	for i in blades:
		var blade := Node3D.new()
		blade.rotation.y = float(i) * TAU / float(blades)
		rotor.add_child(blade)
		mesh_at(blade, box(Vector3(0.14, 0.03, length)), black(), Vector3(0, 0, -length * 0.5))
	return rotor


static func _nav_light(parent: Node3D, pos: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = 0.55
	light.omni_range = 3.5
	parent.add_child(light)
	var bulb := MeshInstance3D.new()
	bulb.mesh = sphere(0.05)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	bulb.material_override = mat
	bulb.position = pos
	parent.add_child(bulb)
