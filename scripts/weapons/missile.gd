class_name Missile
extends Area3D

var velocity: Vector3 = Vector3.ZERO
var target: GroundTarget
var life: float = 8.0
var accel: float = 90.0
var damage: float = 120.0
var max_range: float = 1400.0
var max_speed: float = 280.0
var guided: bool = true
var body_scale: float = 1.0
var _traveled: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 8
	monitorable = true
	monitoring = true
	life = max_range / maxf(max_speed, 40.0) + 4.0
	var vis := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08 * body_scale
	mesh.bottom_radius = 0.1 * body_scale
	mesh.height = 1.6 * body_scale
	vis.mesh = mesh
	vis.rotation_degrees.x = 90
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.2, 0.16) if guided else Color(0.35, 0.38, 0.28)
	mat.metallic = 0.7
	vis.material_override = mat
	add_child(vis)
	var exhaust := MeshInstance3D.new()
	var smoke := SphereMesh.new()
	smoke.radius = 0.12 * body_scale
	smoke.height = 0.24 * body_scale
	exhaust.mesh = smoke
	exhaust.position.z = 0.9 * body_scale
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(1, 0.55, 0.15) if guided else Color(1, 0.75, 0.35)
	em.emission_enabled = true
	em.emission = Color(1, 0.4, 0.05) if guided else Color(1, 0.6, 0.15)
	em.emission_energy_multiplier = 5.0
	exhaust.material_override = em
	add_child(exhaust)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.2 * maxf(body_scale, 0.6)
	cap.height = 1.7 * body_scale
	shape.shape = cap
	shape.rotation_degrees.x = 90
	add_child(shape)
	body_entered.connect(_on_hit)
	area_entered.connect(_on_area)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0 or _traveled >= max_range:
		_detonate()
		return
	if guided and target and is_instance_valid(target) and target.alive:
		var desired := (target.global_position + Vector3.UP - global_position).normalized()
		var current := velocity.normalized() if velocity.length() > 1.0 else -global_transform.basis.z
		var steered := current.slerp(desired, clampf(2.6 * delta, 0.0, 1.0))
		velocity = steered.normalized() * maxf(velocity.length(), 40.0)
	if velocity.length_squared() < 0.01:
		velocity = -global_transform.basis.z * 40.0
	velocity += velocity.normalized() * accel * delta
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	var step := velocity * delta
	global_position += step
	_traveled += step.length()
	if velocity.length_squared() > 0.1:
		look_at(global_position + velocity, Vector3.UP)


func _on_hit(body: Node) -> void:
	_impact(body)


func _on_area(area: Node) -> void:
	_impact(area)


func _impact(node: Node) -> void:
	var target_hit := node as GroundTarget
	if target_hit == null:
		target_hit = node.get_parent() as GroundTarget
	if target_hit:
		target_hit.apply_damage(damage)
	_detonate()


func _detonate() -> void:
	if is_inside_tree():
		Explosion.spawn(get_parent(), global_position, clampf(damage / 140.0, 0.45, 1.35))
	queue_free()
