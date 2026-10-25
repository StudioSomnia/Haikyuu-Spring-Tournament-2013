extends Control

## Screen-space aiming reticle. It stays on screen for the whole rally: bright
## while aiming, dimmed but still outlined when it is only a cursor.

var valid := true
var active := true
var idle := false
var tint := Color("#ffc857")
var pulse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(54, 54)
	size = Vector2(54, 54)
	set_process(true)

func set_state(p: Vector2, is_valid: bool, color: Color) -> void:
	position = p - size * 0.5
	valid = is_valid
	tint = color
	idle = false
	visible = true
	queue_redraw()

func set_idle(p: Vector2) -> void:
	position = p - size * 0.5
	valid = true
	idle = true
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.5)
	var col := tint if valid else Color("#ff4d5e")
	if idle:
		col = Color("#d8e2f5")
	var a := 0.36 if idle else 0.65 + sin(pulse * 5.0) * 0.12
	var outline := Color(0.015, 0.025, 0.05, 0.72 if idle else 0.85)
	# Dark outline first so the reticle reads over the bright court and crowd.
	draw_arc(c, 16.0, 0, TAU, 32, outline, 4.6, true)
	draw_arc(c, 7.0, 0, TAU, 20, outline, 3.4, true)
	for d in [Vector2(24, 0), Vector2(-24, 0), Vector2(0, 24), Vector2(0, -24)]:
		draw_line(c + d * 0.55, c + d, outline, 4.8)
	draw_circle(c, 4.2, outline)

	draw_arc(c, 16.0, 0, TAU, 32, Color(col.r, col.g, col.b, a), 2.0, true)
	draw_arc(c, 7.0, 0, TAU, 20, Color(col.r, col.g, col.b, a * 0.85), 1.3, true)
	draw_circle(c, 2.2, Color(col.r, col.g, col.b, 0.95 if not idle else 0.6))
	for d in [Vector2(24, 0), Vector2(-24, 0), Vector2(0, 24), Vector2(0, -24)]:
		draw_line(c + d * 0.55, c + d, Color(col.r, col.g, col.b, a), 2.0)
	if not valid:
		draw_line(c + Vector2(-7, -7), c + Vector2(7, 7), Color(1, 0.3, 0.35, 0.9), 2.0)
		draw_line(c + Vector2(7, -7), c + Vector2(-7, 7), Color(1, 0.3, 0.35, 0.9), 2.0)
