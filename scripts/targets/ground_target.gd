class_name GroundTarget
extends StaticBody3D

enum Kind { TANK, SAM, RADAR, BUNKER }

signal destroyed(target: GroundTarget)

var kind: Kind = Kind.TANK
var target_id: String = ""
var max_hp: float = 80.0
var hp: float = 80.0
var alive: bool = true
var _dish: Node3D

func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	add_to_group("ground_target")
	_build()
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitorable = true
	area.monitoring = false
	var area_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.2, 2.8, 5.5)
	area_shape.shape = box
	area_shape.position.y = 1.2
	area.add_child(area_shape)
	add_child(area)


func _process(delta: float) -> void:
	if _dish and alive:
		_dish.rotate_y(delta * 0.8)


func setup(p_kind: Kind, p_id: String, hp_override: float) -> void:
	kind = p_kind
	target_id = p_id
	max_hp = hp_override
	hp = hp_override


func apply_damage(amount: float) -> void:
	if not alive:
		return
	hp -= amount
	if hp <= 0.0:
		_die()


func _die() -> void:
	alive = false
	Explosion.spawn(get_parent(), global_position + Vector3.UP, 1.3)
	destroyed.emit(self)
	remove_from_group("ground_target")
	hide()
	collision_layer = 0
	await get_tree().create_timer(0.2).timeout
	queue_free()


func label_text() -> String:
	match kind:
		Kind.TANK:
			return "TANK"
		Kind.SAM:
			return "SAM"
		Kind.RADAR:
			return "RADAR"
		Kind.BUNKER:
			return "BUNKER"
	return "TARGET"


func _build() -> void:
	match kind:
		Kind.TANK:
			_build_tank()
		Kind.SAM:
			_build_sam()
		Kind.RADAR:
			_build_radar()
		Kind.BUNKER:
			_build_bunker()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.6, 2.4, 5.2)
	col.shape = shape
	col.position.y = 1.1
	add_child(col)


func _mat(color: Color, metallic: float = 0.45) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.55
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _cyl(r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 10
	return m


func _build_tank() -> void:
	var hull := _mat(Color(0.18, 0.28, 0.14))
	var dark := _mat(Color(0.08, 0.1, 0.07), 0.6)
	_mesh(self, _box(Vector3(2.6, 0.9, 4.6)), hull, Vector3(0, 0.85, 0))
	_mesh(self, _box(Vector3(2.0, 0.7, 2.2)), hull, Vector3(0, 1.55, -0.2))
	_mesh(self, _cyl(0.12, 3.2), dark, Vector3(0, 1.55, -2.4), Vector3(deg_to_rad(90), 0, 0))
	_mesh(self, _box(Vector3(0.55, 0.7, 4.4)), dark, Vector3(-1.4, 0.45, 0))
	_mesh(self, _box(Vector3(0.55, 0.7, 4.4)), dark, Vector3(1.4, 0.45, 0))


func _build_sam() -> void:
	var hull := _mat(Color(0.25, 0.24, 0.16))
	var tube := _mat(Color(0.15, 0.16, 0.12), 0.7)
	_mesh(self, _box(Vector3(2.2, 1.1, 4.4)), hull, Vector3(0, 0.9, 0.2))
	_mesh(self, _box(Vector3(2.0, 0.2, 2.4)), hull, Vector3(0, 1.55, -0.4))
	for x in [-0.45, 0.45]:
		_mesh(self, _cyl(0.16, 2.6), tube, Vector3(x, 2.15, -0.2), Vector3(deg_to_rad(70), 0, 0))


func _build_radar() -> void:
	var hull := _mat(Color(0.3, 0.28, 0.18))
	var met := _mat(Color(0.55, 0.55, 0.5), 0.85)
	_mesh(self, _box(Vector3(2.3, 1.4, 3.6)), hull, Vector3(0, 0.9, 0))
	_dish = Node3D.new()
	_dish.position = Vector3(0, 2.0, 0)
	add_child(_dish)
	var dish_mesh := SphereMesh.new()
	dish_mesh.radius = 1.1
	dish_mesh.height = 0.45
	dish_mesh.is_hemisphere = true
	_mesh(_dish, dish_mesh, met, Vector3.ZERO, Vector3(deg_to_rad(-70), 0, 0))


func _build_bunker() -> void:
	var conc := _mat(Color(0.42, 0.4, 0.34), 0.1)
	var sand := _mat(Color(0.45, 0.38, 0.22), 0.0)
	_mesh(self, _box(Vector3(6.5, 1.6, 4.8)), conc, Vector3(0, 0.8, 0))
	_mesh(self, _box(Vector3(7.0, 0.5, 1.0)), sand, Vector3(0, 0.35, -2.6))
	_mesh(self, _box(Vector3(7.0, 0.5, 1.0)), sand, Vector3(0, 0.35, 2.6))
	_mesh(self, _cyl(0.08, 3.4), _mat(Color(0.2, 0.2, 0.2), 0.7), Vector3(1.6, 2.4, 0.4))
