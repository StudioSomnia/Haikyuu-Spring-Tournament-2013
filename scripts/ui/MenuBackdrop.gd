extends Control

## Animated, wholly procedural menu artwork: a stylized night gym with a
## perspective court, spotlights, and a floating volleyball.

var t := 0.0
var accent := Color("#ff7a1a")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_accent(c: Color) -> void:
	accent = c
	queue_redraw()

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x < 2 or s.y < 2:
		return
	# Deep gradient background.
	var bands := 48
	for i in range(bands):
		var u := float(i) / float(bands - 1)
		var c := Color("#070a16").lerp(Color("#111a33"), u)
		c = c.lerp(Color(accent.r * 0.09, accent.g * 0.07, accent.b * 0.08, 1.0), 0.35)
		draw_rect(Rect2(0, u * s.y, s.x, s.y / bands + 2.0), c)

	# Spotlight cone from upper right.
	var origin := Vector2(s.x * 0.82, -s.y * 0.1)
	var cone := PackedVector2Array([
		origin + Vector2(-s.x * 0.04, 0),
		origin + Vector2(s.x * 0.07, 0),
		Vector2(s.x * 1.05, s.y * 0.92),
		Vector2(s.x * 0.62, s.y * 0.98)
	])
	draw_colored_polygon(cone, Color(accent.r, accent.g, accent.b, 0.045))
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-s.x * 0.015, 0),
		origin + Vector2(s.x * 0.025, 0),
		Vector2(s.x * 0.88, s.y * 0.7),
		Vector2(s.x * 0.8, s.y * 0.72)
	]), Color(1, 1, 1, 0.03))

	# Sunburst rays, very subtle.
	var center := Vector2(s.x * 0.72, s.y * 0.42)
	for i in range(14):
		var a := TAU * float(i) / 14.0 + t * 0.025
		var p1 := center + Vector2(cos(a), sin(a)) * 90.0
		var p2 := center + Vector2(cos(a), sin(a)) * (s.x * 0.9)
		draw_line(p1, p2, Color(1, 1, 1, 0.018), 2.0)

	_draw_crowd(s)
	_draw_court(s)
	_draw_ball(s)
	_draw_halftone(s)

func _draw_crowd(s: Vector2) -> void:
	# Dark bleachers with tiny cold light dots.
	var base_y := s.y * 0.20
	draw_rect(Rect2(0, base_y, s.x, s.y * 0.16), Color("#080b16"))
	for row in range(5):
		var y := base_y + row * (s.y * 0.031)
		draw_rect(Rect2(0, y, s.x, 2.0), Color(1, 1, 1, 0.035 + row * 0.007))
		var count := 54
		for i in range(count):
			var seed := float(i * 73 + row * 17)
			var x := fmod(seed * 37.13, s.x)
			var flicker := 0.12 + 0.12 * sin(t * 1.7 + seed)
			var c := Color(0.6, 0.72, 1.0, flicker)
			if int(seed) % 7 == 0:
				c = Color(1.0, 0.72, 0.35, flicker)
			draw_circle(Vector2(x, y + 9.0), 2.0, c)

func _draw_court(s: Vector2) -> void:
	# A perspective court seen from behind one baseline.
	var top_y := s.y * 0.40
	var bottom_y := s.y * 1.02
	var top_w := s.x * 0.24
	var bottom_w := s.x * 1.18
	var cx := s.x * 0.56
	var tl := Vector2(cx - top_w * 0.5, top_y)
	var tr := Vector2(cx + top_w * 0.5, top_y)
	var br := Vector2(cx + bottom_w * 0.5, bottom_y)
	var bl := Vector2(cx - bottom_w * 0.5, bottom_y)
	draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]), Color("#16203a"))
	draw_colored_polygon(PackedVector2Array([
		tl.lerp(bl, 0.03), tr.lerp(br, 0.03), tr.lerp(br, 0.47), tl.lerp(bl, 0.47)
	]), Color(accent.r, accent.g, accent.b, 0.10))
	# Court lines.
	var line_col := Color(1, 1, 1, 0.30)
	draw_line(tl, tr, line_col, 2.0)
	draw_line(bl, br, line_col, 2.0)
	draw_line(tl, bl, line_col, 2.0)
	draw_line(tr, br, line_col, 2.0)
	# Net plane.
	var nl := tl.lerp(bl, 0.46)
	var nr := tr.lerp(br, 0.46)
	draw_line(nl, nr, Color(1, 1, 1, 0.55), 5.0)
	for i in range(9):
		var u := float(i + 1) / 10.0
		var a := nl.lerp(nr, u)
		draw_line(a, a - Vector2(0, s.y * (0.035 + u * 0.0)), Color(1, 1, 1, 0.22), 1.0)
	for i in range(4):
		var u := float(i) / 3.0
		var a := nl.lerp(nl + Vector2(0, -s.y * 0.09), u)
		var b := nr.lerp(nr + Vector2(0, -s.y * 0.055), u)
		draw_line(a, b, Color(1, 1, 1, 0.12), 1.0)
	# Attack line and center line.
	for f in [0.25, 0.46, 0.68]:
		var a := tl.lerp(bl, f)
		var b := tr.lerp(br, f)
		draw_line(a, b, Color(1, 1, 1, 0.12), 1.0)

func _draw_ball(s: Vector2) -> void:
	var center := Vector2(s.x * 0.79 + sin(t * 0.7) * 12.0, s.y * 0.30 + sin(t * 0.9) * 9.0)
	var r := s.y * 0.085
	# Soft shadow glow.
	for i in range(5):
		draw_circle(center + Vector2(0, r * 0.9), r * (1.4 + i * 0.3), Color(accent.r, accent.g, accent.b, 0.018))
	draw_circle(center, r * 1.03, Color(0, 0, 0, 0.35))
	draw_circle(center, r, Color("#f4f6fb"))
	# Volleyball panel curves.
	var rot := t * 0.35
	draw_arc(center, r * 0.95, rot, rot + PI * 0.9, 24, Color("#2c7be5"), r * 0.16, true)
	draw_arc(center, r * 0.95, rot + PI, rot + PI * 1.9, 24, Color("#ff7a1a"), r * 0.16, true)
	draw_arc(center + Vector2(-r * 0.12, 0), r * 0.88, rot - 0.7, rot + 1.0, 16, Color("#2c7be5"), r * 0.08, true)
	draw_arc(center, r * 0.62, rot + 0.5, rot + 2.2, 18, Color("#1b2238"), r * 0.05, true)

func _draw_halftone(s: Vector2) -> void:
	var step := 34.0
	var y := 0.0
	var row := 0
	while y < s.y:
		var x := fmod(row * 17.0, step)
		while x < s.x:
			var a := 0.022 + 0.018 * sin(t * 0.8 + x * 0.02 + y * 0.03)
			draw_circle(Vector2(x, y), 1.1, Color(1, 1, 1, a))
			x += step
		y += step
		row += 1
