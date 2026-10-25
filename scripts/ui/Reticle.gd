extends Control

## Screen-space aiming reticle.

var valid := true
var active := true
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
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.5)
	var col := tint if valid else Color("#ff4d5e")
	var a := 0.65 + sin(pulse * 5.0) * 0.12
	draw_arc(c, 16.0, 0, TAU, 32, Color(col.r, col.g, col.b, a), 2.0, true)
	draw_arc(c, 7.0, 0, TAU, 20, Color(col.r, col.g, col.b, a * 0.8), 1.2, true)
	draw_circle(c, 2.2, Color(col.r, col.g, col.b, 0.95))
	for d in [Vector2(24, 0), Vector2(-24, 0), Vector2(0, 24), Vector2(0, -24)]:
		draw_line(c + d * 0.55, c + d, Color(col.r, col.g, col.b, a), 2.0)
	if not valid:
		draw_line(c + Vector2(-7, -7), c + Vector2(7, 7), Color(1, 0.3, 0.35, 0.9), 2.0)
		draw_line(c + Vector2(7, -7), c + Vector2(-7, 7), Color(1, 0.3, 0.35, 0.9), 2.0)
