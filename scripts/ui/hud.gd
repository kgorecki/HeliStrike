class_name Hud
extends CanvasLayer

var heli: Helicopter
var remaining: int = 8
var total: int = 8
var message: String = ""
var _msg_time: float = 0.0

@onready var _root: Control = Control.new()

func _ready() -> void:
	layer = 10
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.draw.connect(_on_draw)


func _process(delta: float) -> void:
	if _msg_time > 0.0:
		_msg_time -= delta
		if _msg_time <= 0.0:
			message = ""
	_root.queue_redraw()


func flash(text: String, seconds: float = 2.2) -> void:
	message = text
	_msg_time = seconds


func _on_draw() -> void:
	if heli == null or not is_instance_valid(heli):
		return
	var r := _root.get_rect()
	var cx := r.size.x * 0.5
	var cy := r.size.y * 0.5
	var hud := ThemeUtil.HUD
	var font := ThemeUtil.mono()

	if heli.camera_mode == 0:
		_canopy(_root, r)
	_crosshair(_root, Vector2(cx, cy), hud)
	_draw_compass(_root, Vector2(cx, 36), heli.heading_deg(), font, hud)
	_draw_tape(_root, Vector2(72, cy), "ALT", "%d" % int(heli.altitude_agl()), font, hud, true)
	_draw_tape(_root, Vector2(r.size.x - 72, cy), "SPD", "%d" % int(heli.airspeed_kms()), font, hud, false)

	var col_h := 140.0
	var col_y := cy + 40.0
	_root.draw_rect(Rect2(cx - 8, col_y, 16, col_h), Color(0, 0, 0, 0.35))
	var fill := heli.collective * col_h
	_root.draw_rect(Rect2(cx - 6, col_y + col_h - fill, 12, fill), hud)
	_root.draw_line(Vector2(cx - 12, col_y + col_h * (1.0 - heli.hover_collective)), Vector2(cx + 12, col_y + col_h * (1.0 - heli.hover_collective)), ThemeUtil.AMBER, 1)
	_root.draw_string(font, Vector2(cx - 28, col_y + col_h + 18), "COL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, hud)

	var cam_name := "COCKPIT" if heli.camera_mode == 0 else "CHASE"
	_root.draw_string(font, Vector2(24, r.size.y - 28), "CAM %s   [C]" % cam_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, hud)
	_root.draw_string(font, Vector2(24, 28), "HDG %03d" % int(heli.heading_deg()), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, hud)
	_root.draw_string(font, Vector2(24, 50), "HULL %d%%" % int(heli.hull), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, hud if heli.hull > 35.0 else ThemeUtil.DANGER)

	var ammo := "GUN %03d    MSL  %d/%d" % [heli.cannon_ammo, heli.missile_ammo, heli.missile_max]
	_root.draw_string(font, Vector2(r.size.x - 280, r.size.y - 28), ammo, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, hud)
	var tgt := "TGT  %d / %d" % [remaining, total]
	_root.draw_string(font, Vector2(r.size.x - 200, 28), tgt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ThemeUtil.AMBER)

	if heli.locked_target and is_instance_valid(heli.locked_target):
		var lock_txt := "LOCK" if heli.has_lock() else "LOCKING"
		var lock_col := ThemeUtil.DANGER if heli.has_lock() else ThemeUtil.AMBER
		_root.draw_string(font, Vector2(cx - 30, cy + 48), lock_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, lock_col)

	if message != "":
		_root.draw_string(font, Vector2(cx - 180, cy - 90), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ThemeUtil.AMBER)

	_draw_targets(_root, font)
	_draw_radar(_root, Vector2(r.size.x - 130, r.size.y - 150), font)


func _canopy(c: Control, r: Rect2) -> void:
	var frame := Color(0.04, 0.05, 0.03, 0.55)
	c.draw_rect(Rect2(0, 0, r.size.x, 10), frame)
	c.draw_rect(Rect2(0, r.size.y - 12, r.size.x, 12), frame)
	c.draw_rect(Rect2(0, 0, 10, r.size.y), frame)
	c.draw_rect(Rect2(r.size.x - 10, 0, 10, r.size.y), frame)


func _crosshair(c: Control, p: Vector2, color: Color) -> void:
	c.draw_line(p + Vector2(-16, 0), p + Vector2(-5, 0), color, 1.5)
	c.draw_line(p + Vector2(5, 0), p + Vector2(16, 0), color, 1.5)
	c.draw_line(p + Vector2(0, -16), p + Vector2(0, -5), color, 1.5)
	c.draw_line(p + Vector2(0, 5), p + Vector2(0, 16), color, 1.5)
	c.draw_arc(p, 22, 0, TAU, 32, Color(color, 0.5), 1.0)


func _draw_compass(c: Control, p: Vector2, heading: float, font: Font, color: Color) -> void:
	c.draw_rect(Rect2(p.x - 160, p.y - 16, 320, 28), Color(0, 0, 0, 0.35))
	for i in range(-8, 9):
		var h := heading + float(i) * 10.0
		var x := p.x + float(i) * 18.0
		c.draw_line(Vector2(x, p.y - 6), Vector2(x, p.y + 6), color, 1)
		var wrapped := fposmod(h, 360.0)
		if int(wrapped) % 30 == 0:
			var label := _heading_label(wrapped)
			c.draw_string(font, Vector2(x - 8, p.y + 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	c.draw_line(Vector2(p.x, p.y - 18), Vector2(p.x, p.y + 12), ThemeUtil.AMBER, 2)


func _heading_label(h: float) -> String:
	var d := int(snappedf(h, 30)) % 360
	match d:
		0:
			return "N"
		90:
			return "E"
		180:
			return "S"
		270:
			return "W"
		_:
			return "%03d" % d


func _draw_tape(c: Control, p: Vector2, title: String, value: String, font: Font, color: Color, left: bool) -> void:
	var w := 70.0
	var x := p.x - w if left else p.x
	c.draw_rect(Rect2(x, p.y - 36, w, 52), Color(0, 0, 0, 0.4))
	c.draw_string(font, Vector2(x + 8, p.y - 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	c.draw_string(font, Vector2(x + 8, p.y + 8), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)


func _draw_targets(c: Control, font: Font) -> void:
	if heli == null:
		return
	var cam := heli.active_camera()
	if cam == null:
		return
	for node in get_tree().get_nodes_in_group("ground_target"):
		if not node is GroundTarget:
			continue
		var tgt := node as GroundTarget
		if not tgt.alive:
			continue
		var pos := tgt.global_position + Vector3.UP * 1.5
		if cam.is_position_behind(pos):
			continue
		var sp := cam.unproject_position(pos)
		var locked := heli.locked_target == tgt
		var col := ThemeUtil.DANGER if locked and heli.has_lock() else (ThemeUtil.AMBER if locked else ThemeUtil.HUD)
		var s := 16.0 if locked else 10.0
		c.draw_line(sp + Vector2(-s, -s), sp + Vector2(-s * 0.3, -s), col, 1.5)
		c.draw_line(sp + Vector2(-s, -s), sp + Vector2(-s, -s * 0.3), col, 1.5)
		c.draw_line(sp + Vector2(s, -s), sp + Vector2(s * 0.3, -s), col, 1.5)
		c.draw_line(sp + Vector2(s, -s), sp + Vector2(s, -s * 0.3), col, 1.5)
		c.draw_line(sp + Vector2(-s, s), sp + Vector2(-s * 0.3, s), col, 1.5)
		c.draw_line(sp + Vector2(-s, s), sp + Vector2(-s, s * 0.3), col, 1.5)
		c.draw_line(sp + Vector2(s, s), sp + Vector2(s * 0.3, s), col, 1.5)
		c.draw_line(sp + Vector2(s, s), sp + Vector2(s, s * 0.3), col, 1.5)
		c.draw_string(font, sp + Vector2(s + 4, -s), tgt.label_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)


func _draw_radar(c: Control, p: Vector2, font: Font) -> void:
	var radius := 56.0
	c.draw_circle(p, radius, Color(0, 0, 0, 0.45))
	c.draw_arc(p, radius, 0, TAU, 40, ThemeUtil.HUD, 1.0)
	c.draw_arc(p, radius * 0.5, 0, TAU, 32, Color(ThemeUtil.HUD, 0.35), 1.0)
	c.draw_line(p + Vector2(0, -radius), p + Vector2(0, radius), Color(ThemeUtil.HUD, 0.3), 1)
	c.draw_line(p + Vector2(-radius, 0), p + Vector2(radius, 0), Color(ThemeUtil.HUD, 0.3), 1)
	c.draw_string(font, p + Vector2(-18, radius + 16), "RDR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ThemeUtil.HUD)
	if heli == null:
		return
	var yaw := heli.global_rotation.y
	for node in get_tree().get_nodes_in_group("ground_target"):
		if not node is GroundTarget:
			continue
		var tgt := node as GroundTarget
		var delta := tgt.global_position - heli.global_position
		var local := Vector2(delta.x, delta.z).rotated(yaw)
		var scale := 0.12
		var pt := p + Vector2(local.x, local.y) * scale
		if pt.distance_to(p) > radius - 4.0:
			pt = p + (pt - p).normalized() * (radius - 4.0)
		c.draw_circle(pt, 3, ThemeUtil.DANGER)
	c.draw_circle(p, 3, ThemeUtil.AMBER)
