class_name Explosion
extends Node3D

static func spawn(parent: Node, pos: Vector3, scale_mul: float = 1.0) -> void:
	var fx := Explosion.new()
	parent.add_child(fx)
	fx.global_position = pos
	fx._go(scale_mul)


func _go(scale_mul: float) -> void:
	Sfx.play_3d(self, "explosion", global_position, -2.0)
	var parts := GPUParticles3D.new()
	parts.one_shot = true
	parts.emitting = true
	parts.amount = 28
	parts.lifetime = 0.7
	parts.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 80.0
	mat.initial_velocity_min = 6.0 * scale_mul
	mat.initial_velocity_max = 16.0 * scale_mul
	mat.gravity = Vector3(0, -6, 0)
	mat.scale_min = 0.4 * scale_mul
	mat.scale_max = 1.4 * scale_mul
	mat.color = Color(1.0, 0.45, 0.12)
	parts.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.25
	draw.height = 0.5
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(1.0, 0.5, 0.1)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(1.0, 0.35, 0.05)
	draw_mat.emission_energy_multiplier = 3.5
	draw.material = draw_mat
	parts.draw_pass_1 = draw
	add_child(parts)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 6.0 * scale_mul
	light.omni_range = 18.0 * scale_mul
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.45)
	await get_tree().create_timer(1.1).timeout
	queue_free()
