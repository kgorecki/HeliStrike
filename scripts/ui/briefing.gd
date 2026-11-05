extends Control

const HANGAR := "res://scenes/ui/hangar.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.04, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 36)
	margin.add_child(split)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	split.add_child(left)

	left.add_child(ThemeUtil.label("SECRET  //  TASK FORCE HAWK", 13, ThemeUtil.DANGER))
	left.add_child(ThemeUtil.label("MISSION BRIEFING", 16, ThemeUtil.MUTED))
	left.add_child(ThemeUtil.label("OPERATION IRON HAWK", 40, ThemeUtil.AMBER))
	left.add_child(ThemeUtil.label("AH-64E  ·  FOB WATCHTOWER  ·  SECTOR 4B", 14, ThemeUtil.OLIVE))

	var body := """SITUATION
Enemy mechanized elements occupy ridgeline positions
overlooking Route SILVER. Armor and short-range air
defense threaten the planned ground advance.

MISSION
Depart the FARP and destroy all marked ground targets
in sector 4B. Primary: tanks and SAM. Secondary: radar
and the command bunker.

EXECUTION
1. Lift from the pad. Proceed north toward the valley.
2. Engage at standoff with AGM-114 Hellfire missiles.
3. Use the 30mm chain gun for close-in and soft targets.
4. RTB when the area is clear.

SUPPORT / ASSETS
Aircraft: assigned at the FARP hangar
Ordnance: depends on airframe
Wx: Clear, wind light and variable"""

	var text := ThemeUtil.label(body, 15, ThemeUtil.TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(text)

	left.add_child(ThemeUtil.label(
		"CONTROLS   W/S collective   A/D pedals   ARROWS cyclic   MOUSE cyclic if enabled   LMB cannon   RMB / F missile   C camera   ESC pause",
		12,
		ThemeUtil.MUTED
	))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	left.add_child(buttons)

	var start := ThemeUtil.button("SELECT AIRCRAFT", 260)
	start.pressed.connect(_start)
	buttons.add_child(start)

	var back := ThemeUtil.button("BACK", 160)
	back.pressed.connect(_back)
	buttons.add_child(back)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("separation", 12)
	split.add_child(right)

	right.add_child(ThemeUtil.label("AREA OF OPERATIONS", 14, ThemeUtil.MUTED))
	right.add_child(_make_map())
	right.add_child(ThemeUtil.label(
		"LEGEND\n  H   FOB WATCHTOWER\n  +   ENEMY GROUND TARGET\n  N   NORTH / INGRESS",
		13,
		ThemeUtil.MUTED
	))


func _make_map() -> Control:
	var panel := ThemeUtil.panel(Color(0.08, 0.10, 0.07, 1))
	panel.custom_minimum_size = Vector2(420, 360)
	var map := Control.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.draw.connect(func() -> void:
		var r := map.get_rect()
		var pad := 24.0
		var area := Rect2(pad, pad, r.size.x - pad * 2.0, r.size.y - pad * 2.0)
		map.draw_rect(area, Color(0.16, 0.18, 0.12, 1))
		map.draw_rect(area, ThemeUtil.STROKE, false, 1.0)
		for i in 4:
			var x := area.position.x + area.size.x * float(i + 1) / 5.0
			var y := area.position.y + area.size.y * float(i + 1) / 5.0
			map.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color(0.25, 0.3, 0.18, 0.5), 1)
			map.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(0.25, 0.3, 0.18, 0.5), 1)
		var fob := area.position + Vector2(area.size.x * 0.5, area.size.y * 0.82)
		map.draw_circle(fob, 7, ThemeUtil.AMBER)
		var font := ThemeUtil.mono()
		map.draw_string(font, fob + Vector2(10, 5), "FOB", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ThemeUtil.AMBER)
		var targets := [
			Vector2(0.38, 0.28), Vector2(0.52, 0.22), Vector2(0.66, 0.30),
			Vector2(0.30, 0.18), Vector2(0.58, 0.14), Vector2(0.72, 0.20),
			Vector2(0.46, 0.10), Vector2(0.62, 0.08),
		]
		for p in targets:
			var pt := area.position + Vector2(area.size.x * p.x, area.size.y * p.y)
			map.draw_line(pt + Vector2(-5, 0), pt + Vector2(5, 0), ThemeUtil.DANGER, 2)
			map.draw_line(pt + Vector2(0, -5), pt + Vector2(0, 5), ThemeUtil.DANGER, 2)
		map.draw_line(fob, area.position + Vector2(area.size.x * 0.5, area.size.y * 0.34), ThemeUtil.HUD, 1)
		map.draw_string(font, area.position + Vector2(8, 18), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ThemeUtil.HUD)
	)
	panel.add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.resized.connect(map.queue_redraw)
	return panel


func _start() -> void:
	Sfx.play_ui()
	GameState.restore_on_start = false
	if not GameState.has_session():
		GameState.start_new_session()
	GameState.session["heli"] = {}
	GameState.session["destroyed_ids"] = []
	get_tree().change_scene_to_file(HANGAR)


func _back() -> void:
	Sfx.play_ui()
	get_tree().change_scene_to_file(MENU)
