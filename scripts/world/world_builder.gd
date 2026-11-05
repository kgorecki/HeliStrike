class_name WorldBuilder
extends RefCounted

const RES := 129
const SPACING := 16.0
const HALF := (RES - 1) * SPACING * 0.5

var _heights: PackedFloat32Array = PackedFloat32Array()
var _noise: FastNoiseLite


func build(parent: Node3D) -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = 17
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.0038
	_noise.fractal_octaves = 4
	_gen_heights()
	_environment(parent)
	_terrain(parent)
	_fob(parent)


func height_at(x: float, z: float) -> float:
	var fx := (x + HALF) / SPACING
	var fz := (z + HALF) / SPACING
	var x0 := clampi(int(floor(fx)), 0, RES - 2)
	var z0 := clampi(int(floor(fz)), 0, RES - 2)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var h00 := _h(x0, z0)
	var h10 := _h(x0 + 1, z0)
	var h01 := _h(x0, z0 + 1)
	var h11 := _h(x0 + 1, z0 + 1)
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func _h(x: int, z: int) -> float:
	return _heights[z * RES + x]


func _gen_heights() -> void:
	_heights.resize(RES * RES)
	for z in RES:
		for x in RES:
			var wx := float(x) * SPACING - HALF
			var wz := float(z) * SPACING - HALF
			var n := _noise.get_noise_2d(wx, wz)
			var h := 2.0 + n * 22.0 + absf(n) * 10.0
			var edge := maxf(absf(wx), absf(wz))
			if edge > 720.0:
				h += (edge - 720.0) * 0.085
			var d := Vector2(wx, wz).length()
			if d < 95.0:
				h = 2.0
			elif d < 170.0:
				h = lerpf(2.0, h, (d - 95.0) / 75.0)
			var valley := Vector2(wx - 40.0, wz + 520.0).length()
			if valley < 220.0:
				h = lerpf(h, 3.5 + n * 4.0, 1.0 - valley / 220.0)
			_heights[z * RES + x] = h


func _environment(parent: Node3D) -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.52, 0.72)
	sky_mat.sky_horizon_color = Color(0.82, 0.66, 0.42)
	sky_mat.ground_horizon_color = Color(0.55, 0.45, 0.28)
	sky_mat.ground_bottom_color = Color(0.22, 0.18, 0.12)
	sky_mat.sun_angle_max = 30.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.72, 0.62, 0.42)
	environment.fog_density = 0.00055
	environment.fog_aerial_perspective = 0.4
	environment.ssao_enabled = true
	environment.ssao_radius = 1.2
	environment.glow_enabled = true
	environment.glow_intensity = 0.25
	env.environment = environment
	parent.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 50, 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 900.0
	parent.add_child(sun)


func _terrain(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.55, 0.45, 0.28)
	sand.roughness = 0.95
	for z in range(RES - 1):
		for x in range(RES - 1):
			var p00 := _vert(x, z)
			var p10 := _vert(x + 1, z)
			var p01 := _vert(x, z + 1)
			var p11 := _vert(x + 1, z + 1)
			_tri(st, p00, p10, p11)
			_tri(st, p00, p11, p01)
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = sand
	parent.add_child(mi)
	mi.create_trimesh_collision()
	var collider := mi.get_child(0)
	if collider is StaticBody3D:
		(collider as StaticBody3D).collision_layer = 1
		(collider as StaticBody3D).collision_mask = 0


func _vert(x: int, z: int) -> Vector3:
	return Vector3(float(x) * SPACING - HALF, _h(x, z), float(z) * SPACING - HALF)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_uv(Vector2(a.x, a.z) * 0.02)
	st.add_vertex(a)
	st.set_uv(Vector2(b.x, b.z) * 0.02)
	st.add_vertex(b)
	st.set_uv(Vector2(c.x, c.z) * 0.02)
	st.add_vertex(c)


func _fob(parent: Node3D) -> void:
	var conc := _mat(Color(0.38, 0.36, 0.32), 0.15)
	var olive := _mat(Color(0.22, 0.26, 0.16), 0.3)
	var mark := _mat(Color(0.85, 0.75, 0.2), 0.1)
	mark.emission_enabled = true
	mark.emission = Color(0.7, 0.55, 0.1)
	mark.emission_energy_multiplier = 0.4

	_static_box(parent, Vector3(28, 0.18, 28), Vector3(0, 2.1, 0), conc)
	_static_box(parent, Vector3(10, 0.05, 1.1), Vector3(0, 2.22, 0), mark)
	_static_box(parent, Vector3(1.1, 0.05, 10), Vector3(0, 2.22, 0), mark)
	_static_box(parent, Vector3(18, 6.5, 12), Vector3(-32, 5.3, 18), olive)
	_static_box(parent, Vector3(4.5, 14, 4.5), Vector3(22, 9.1, 16), olive)
	_static_box(parent, Vector3(3.2, 0.4, 3.2), Vector3(22, 16.3, 16), conc)
	_static_box(parent, Vector3(8, 2.4, 4), Vector3(18, 3.3, -12), olive)
	_static_box(parent, Vector3(8, 2.4, 4), Vector3(28, 3.3, -12), olive)
	_static_box(parent, Vector3(2.2, 2.6, 2.2), Vector3(-16, 3.4, -10), _mat(Color(0.28, 0.22, 0.12), 0.4))
	_static_box(parent, Vector3(2.2, 2.6, 2.2), Vector3(-12, 3.4, -10), _mat(Color(0.28, 0.22, 0.12), 0.4))


func _static_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = pos
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


func _mat(color: Color, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.7
	return m
