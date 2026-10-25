extends Control

## Context bar for charge power and contact timing.

var value := 0.0
var lo := 0.70
var hi := 0.88
var caption := ""
var bar_color := Color("#ff7a1a")
var visible_bar := false
var _flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(560, 38)

func setup(v: float, sweet_lo: float, sweet_hi: float, cap: String, color: Color, show_it: bool) -> void:
	value = clampf(v, 0.0, 1.0)
	lo = sweet_lo
	hi = sweet_hi
	caption = cap
	bar_color = color
	visible_bar = show_it
	_flash = 1.0
	queue_redraw()

func clear() -> void:
	visible_bar = false
	value = 0.0
	caption = ""
	queue_redraw()

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = max(0.0, _flash - delta * 5.0)

func _draw() -> void:
	if not visible_bar:
		return
	var s := size
	var w := s.x
	var h := 12.0
	var y := s.y - h - 2.0
	var bg := Rect2(Vector2(0, y), Vector2(w, h))
	draw_rect(bg, Color(0, 0, 0, 0.55))
	# Sweet spot.
	var sx := lo * w
	var sw := maxf(2.0, (hi - lo) * w)
	draw_rect(Rect2(Vector2(sx, y), Vector2(sw, h)), Color(0.32, 0.90, 0.55, 0.45))
	# Fill.
	var fw := value * w
	if fw > 0.0:
		var c := bar_color
		if value >= lo and value <= hi:
			c = Color("#52d68a")
		elif value > hi:
			c = Color("#ff5d6c")
		draw_rect(Rect2(Vector2(0, y), Vector2(fw, h)), Color(c.r, c.g, c.b, 0.92))
	# Border.
	draw_rect(bg, Color(1, 1, 1, 0.22), false, 1.0)
	# Marker.
	var mx := value * w
	draw_line(Vector2(mx, y - 5), Vector2(mx, y + h + 5), Color(1, 1, 1, 0.95), 2.0)
	if _flash > 0.0:
		draw_arc(Vector2(mx, y + h * 0.5), 12.0, 0, TAU, 20, Color(1, 1, 1, _flash * 0.5), 2.0, true)
	# Caption.
	if caption != "":
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(2, y - 9), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.93, 1.0, 0.9))
		draw_string(f, Vector2(w - 110, y - 9), "SWEET SPOT", HORIZONTAL_ALIGNMENT_LEFT, 110, 11, Color(0.5, 0.95, 0.7, 0.8))
