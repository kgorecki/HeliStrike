class_name ThemeUtil
extends RefCounted

const BG := Color(0.07, 0.09, 0.06, 0.94)
const PANEL := Color(0.10, 0.13, 0.09, 0.96)
const OLIVE := Color(0.42, 0.49, 0.23)
const AMBER := Color(0.90, 0.70, 0.15)
const HUD := Color(0.24, 1.0, 0.42)
const TEXT := Color(0.80, 0.86, 0.72)
const MUTED := Color(0.55, 0.60, 0.48)
const DANGER := Color(0.95, 0.25, 0.18)
const STROKE := Color(0.27, 0.32, 0.18)


static func mono() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Menlo", "Consolas", "Courier New", "monospace"])
	return font


static func label(text: String, size: int, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", mono())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func button(text: String, min_w: float = 320.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 48)
	b.add_theme_font_override("font", mono())
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", AMBER)
	b.add_theme_color_override("font_pressed_color", AMBER)
	b.add_theme_color_override("font_disabled_color", MUTED)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.15, 0.10, 0.92)
	normal.border_color = STROKE
	normal.set_border_width_all(1)
	normal.set_content_margin_all(12)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.18, 0.22, 0.12, 0.95)
	hover.border_color = OLIVE
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.22, 0.26, 0.12, 1)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.08, 0.09, 0.07, 0.7)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", hover)
	return b


static func panel(color: Color = PANEL) -> Panel:
	var p := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = STROKE
	box.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", box)
	return p
