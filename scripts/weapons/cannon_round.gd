class_name CannonRound
extends Area3D

var velocity: Vector3 = Vector3.ZERO
var life: float = 2.2

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 8
	monitorable = true
	monitoring = true
	var vis := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.04, 0.04, 1.1)
	vis.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.15)
	mat.emission_energy_multiplier = 4.0
	vis.material_override = mat
	add_child(vis)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.18
	shape.shape = sphere
	add_child(shape)
	body_entered.connect(_on_hit)
	area_entered.connect(_on_area)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	velocity += Vector3.DOWN * 9.81 * 0.15 * delta
	global_position += velocity * delta
	if velocity.length_squared() > 0.1:
		look_at(global_position + velocity, Vector3.UP)


func _on_hit(body: Node) -> void:
	_impact(body)


func _on_area(area: Node) -> void:
	_impact(area)


func _impact(node: Node) -> void:
	var target := node as GroundTarget
	if target == null:
		target = node.get_parent() as GroundTarget
	if target:
		target.apply_damage(18.0)
	queue_free()
