extends Control

## Timing / charge bar with a five-band readout:
## red → yellow → green → yellow → red. The green range is the sweet spot;
## better stats widen the green and yellow bands.

var value := 0.0
var lo := 0.70
var hi := 0.88
var yellow := 0.06
var caption := ""
var bar_color := Color("#ff7a1a")
var visible_bar := false
var _flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(560, 38)

func setup(v: float, sweet_lo: float, sweet_hi: float, cap: String, color: Color, show_it: bool, yellow_pad: float = 0.06) -> void:
	value = clampf(v, 0.0, 1.0)
	lo = clampf(sweet_lo, 0.01, 0.98)
	hi = clampf(sweet_hi, lo + 0.005, 0.99)
	yellow = clampf(yellow_pad, 0.0, 0.45)
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
	var ylo := maxf(0.0, lo - yellow)
	var yhi := minf(1.0, hi + yellow)

	# Red base, then the two yellow shoulders and the green sweet spot.
	draw_rect(bg, Color("#5c141b"))
	draw_rect(Rect2(Vector2(ylo * w, y), Vector2(maxf(0.0, (lo - ylo)) * w, h)), Color("#d9a72e"))
	draw_rect(Rect2(Vector2(hi * w, y), Vector2(maxf(0.0, (yhi - hi)) * w, h)), Color("#d9a72e"))
	draw_rect(Rect2(Vector2(lo * w, y), Vector2(maxf(2.0, (hi - lo) * w), h)), Color("#42c46e"))

	# A subtle travelled fill so the bar still reads as a charge meter.
	if value > 0.0:
		draw_rect(Rect2(Vector2(0, y), Vector2(value * w, h)), Color(1, 1, 1, 0.08))

	# Border.
	draw_rect(bg, Color(1, 1, 1, 0.24), false, 1.0)

	# Marker: white in the green, gold in the yellow, red outside.
	var mx := value * w
	var mc := Color("#ff5d6c")
	if value >= lo and value <= hi:
		mc = Color("#f4f8ff")
	elif value >= ylo and value <= yhi:
		mc = Color("#ffd45e")
	draw_line(Vector2(mx, y - 6), Vector2(mx, y + h + 6), Color(0, 0, 0, 0.78), 5.0)
	draw_line(Vector2(mx, y - 6), Vector2(mx, y + h + 6), mc, 2.0)
	if _flash > 0.0:
		draw_arc(Vector2(mx, y + h * 0.5), 12.0, 0, TAU, 20, Color(mc.r, mc.g, mc.b, _flash * 0.6), 2.0, true)

	# Caption.
	if caption != "":
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(2, y - 9), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.93, 1.0, 0.92))
		draw_string(f, Vector2(w - 150, y - 9), "GREEN = PERFECT", HORIZONTAL_ALIGNMENT_RIGHT, 150, 11, Color(0.55, 0.95, 0.7, 0.85))
