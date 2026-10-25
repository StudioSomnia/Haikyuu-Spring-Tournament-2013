class_name UI
extends RefCounted

const BG := Color("#070a16")
const BG2 := Color("#0d1326")
const PANEL := Color(0.078, 0.102, 0.18, 0.94)
const PANEL_LIGHT := Color(0.12, 0.15, 0.25, 0.96)
const LINE := Color(1, 1, 1, 0.10)
const TEXT := Color("#f2f5ff")
const MUTED := Color("#9aa4bf")
const GOLD := Color("#ffc857")
const ORANGE := Color("#ff7a1a")
const CYAN := Color("#39d0e0")
const GREEN := Color("#52d68a")
const RED := Color("#ff5d6c")
const BLUE := Color("#5c9dff")

static func bold_font() -> FontVariation:
	var f := FontVariation.new()
	f.base_font = ThemeDB.fallback_font
	f.variation_embolden = 0.55
	return f

static func label(text: String, size: int = 20, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

static func bold(text: String, size: int = 20, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, size, color, align)
	l.add_theme_font_override("font", bold_font())
	return l

static func panel(bg: Color = PANEL, accent: Color = LINE, radius: int = 14, border: int = 1) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = border
	s.border_width_top = border
	s.border_width_right = border
	s.border_width_bottom = border
	s.border_color = accent
	s.content_margin_left = 18
	s.content_margin_top = 14
	s.content_margin_right = 18
	s.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", s)
	return p

static func button(text: String, accent: Color = ORANGE, size: int = 21, min_height: int = 52) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_height)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", bold_font())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", MUTED)
	_style_button(b, accent)
	return b

static func _style_button(b: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.11, 0.19, 0.92)
	normal.border_width_left = 4
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.45)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.content_margin_left = 20
	normal.content_margin_right = 20

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(accent.r * 0.24, accent.g * 0.24, accent.b * 0.24, 0.96)
	hover.border_color = accent
	hover.border_width_left = 6

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(accent.r * 0.38, accent.g * 0.38, accent.b * 0.38, 1.0)
	pressed.border_color = accent

	var focus := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled", normal)

static func small_button(text: String, accent: Color = CYAN) -> Button:
	return button(text, accent, 16, 38)

static func bar(value: float, color: Color, width: float = 200.0, height: float = 10.0, bg: Color = Color(0, 0, 0, 0.35)) -> ProgressBar:
	var p := ProgressBar.new()
	p.min_value = 0
	p.max_value = 100
	p.value = clampf(value, 0, 100)
	p.show_percentage = false
	p.custom_minimum_size = Vector2(width, height)
	var back := StyleBoxFlat.new()
	back.bg_color = bg
	back.corner_radius_top_left = int(height / 2.0)
	back.corner_radius_top_right = int(height / 2.0)
	back.corner_radius_bottom_left = int(height / 2.0)
	back.corner_radius_bottom_right = int(height / 2.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = int(height / 2.0)
	fill.corner_radius_top_right = int(height / 2.0)
	fill.corner_radius_bottom_left = int(height / 2.0)
	fill.corner_radius_bottom_right = int(height / 2.0)
	p.add_theme_stylebox_override("background", back)
	p.add_theme_stylebox_override("fill", fill)
	return p

static func spacer(h: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

static func hspacer(w: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 0)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func hline(color: Color = LINE, thickness: int = 1) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(0, thickness)
	return r

static func vline(color: Color = LINE, thickness: int = 1) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(thickness, 0)
	return r

static func chip(text: String, color: Color, font_size: int = 15) -> PanelContainer:
	var p := panel(Color(color.r, color.g, color.b, 0.14), Color(color.r, color.g, color.b, 0.5), 6, 1)
	p.add_child(bold(text, font_size, color))
	p.get_theme_stylebox("panel").content_margin_left = 10
	p.get_theme_stylebox("panel").content_margin_right = 10
	p.get_theme_stylebox("panel").content_margin_top = 4
	p.get_theme_stylebox("panel").content_margin_bottom = 4
	return p

static func stat_row(name: String, value: int, color: Color, width: float = 180.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var n := label(name, 14, MUTED)
	n.custom_minimum_size = Vector2(78, 0)
	h.add_child(n)
	var b := bar(value, color, width, 9)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(b)
	var v := bold(str(value), 15, TEXT)
	v.custom_minimum_size = Vector2(26, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	return h

static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

static func join_names(names: Array, max_count: int = 99) -> String:
	var out: Array[String] = []
	for i in range(min(names.size(), max_count)):
		out.append(str(names[i]))
	return ", ".join(out)
