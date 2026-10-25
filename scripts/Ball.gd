class_name VolleyBall
extends Node3D

## Scripted-arc volleyball with a readable trail. The arc is deterministic so
## players and AI can both predict the landing point.

signal arrived(pos: Vector3, info: Dictionary)

var active := false
var held := false
var start := Vector3.ZERO
var end := Vector3.ZERO
var duration := 1.0
var arc := 1.0
var t := 0.0
var kind := "free"
var contact_point := false
var last_touch_team := -1
var last_hitter: Node = null
var target_team := -1
var is_serve := false
var is_attack := false
var spin := Vector3.ZERO

var _mesh_root: Node3D
var _trail: Array[MeshInstance3D] = []
var _history: Array[Vector3] = []
var _trail_mats: Array[StandardMaterial3D] = []

func _ready() -> void:
	_build()

func _build() -> void:
	_mesh_root = Node3D.new()
	add_child(_mesh_root)
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.105
	sm.height = 0.21
	sm.radial_segments = 20
	sm.rings = 12
	sphere.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#f7f8fc")
	mat.roughness = 0.52
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.08
	sphere.material_override = mat
	sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mesh_root.add_child(sphere)

	# Classic panel stripes.
	_panel_ring(0.106, 0.026, Color("#2c7be5"), Vector3(0.4, 0.1, 0.0))
	_panel_ring(0.106, 0.026, Color("#ff7a1a"), Vector3(-0.5, -0.2, 1.0))
	_panel_ring(0.106, 0.018, Color("#1b2238"), Vector3(1.2, 0.4, 0.5))

	for i in range(14):
		var tr := MeshInstance3D.new()
		var tm := SphereMesh.new()
		tm.radius = 0.085
		tm.height = 0.17
		tm.radial_segments = 8
		tm.rings = 4
		tr.mesh = tm
		var tm_mat := StandardMaterial3D.new()
		tm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tm_mat.albedo_color = Color(1, 0.82, 0.5, 0.0)
		tr.material_override = tm_mat
		tr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tr)
		_trail.append(tr)
		_trail_mats.append(tm_mat)
		_history.append(Vector3.ZERO)

func _panel_ring(radius: float, thickness: float, color: Color, rot: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius - thickness
	tm.outer_radius = radius
	tm.rings = 24
	tm.ring_segments = 6
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.5
	mi.material_override = m
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_root.add_child(mi)

func launch(from: Vector3, to: Vector3, dur: float, arc_height: float, flight_kind: String, hitter: Node, team: int, contact: bool = false) -> void:
	start = from
	end = to
	duration = max(0.12, dur)
	arc = arc_height
	t = 0.0
	kind = flight_kind
	contact_point = contact
	last_hitter = hitter
	last_touch_team = team
	target_team = 1 - team
	held = false
	active = true
	visible = true
	is_serve = flight_kind == "serve"
	is_attack = flight_kind == "attack"
	spin = Vector3(randf_range(-8, 8), randf_range(-5, 5), randf_range(-8, 8))
	global_position = from
	_history.clear()
	for i in range(_trail.size()):
		_history.append(from)

func hold_at(pos: Vector3) -> void:
	held = true
	active = false
	visible = true
	global_position = pos
	_mesh_root.rotation = Vector3.ZERO

func hide_ball() -> void:
	visible = false
	active = false
	held = false

func tick(dt: float) -> void:
	if held or not active:
		_update_trail(dt)
		return
	t += dt
	var u := clampf(t / duration, 0.0, 1.0)
	global_position = position_at(u)
	_mesh_root.rotation += spin * dt
	_update_trail(dt)
	if t >= duration:
		active = false
		var info := {
			"kind": kind,
			"contact": contact_point,
			"team": last_touch_team,
			"pos": end
		}
		arrived.emit(end, info)

func position_at(u: float) -> Vector3:
	var p := start.lerp(end, u)
	p.y = lerpf(start.y, end.y, u) + 4.0 * arc * u * (1.0 - u)
	return p

func height_at(distance_u: float) -> float:
	return position_at(clampf(distance_u, 0.0, 1.0)).y

func time_to_cross(z_plane: float) -> float:
	var dz := end.z - start.z
	if absf(dz) < 0.0001:
		return -1.0
	var u := (z_plane - start.z) / dz
	if u < 0.0 or u > 1.0:
		return -1.0
	return u * duration

func crossing(z_plane: float = 0.0) -> Dictionary:
	var u := (z_plane - start.z) / (end.z - start.z) if absf(end.z - start.z) > 0.0001 else -1.0
	if u < 0.0 or u > 1.0:
		return {}
	var p := position_at(u)
	return {"u": u, "time": u * duration, "pos": p}

func predicted_landing() -> Vector3:
	return end

func time_left() -> float:
	return max(0.0, duration - t)

func _update_trail(dt: float) -> void:
	if _trail.is_empty():
		return
	var here := global_position
	# Shift history toward the tail.
	for i in range(_history.size() - 1, 0, -1):
		_history[i] = _history[i - 1]
	_history[0] = here
	var visible_trail := active or held
	for i in range(_trail.size()):
		var off := _history[i] - here
		_trail[i].position = off
		_trail[i].visible = visible_trail and i > 0
		var alpha := (1.0 - float(i) / float(_trail.size())) * 0.22
		var c := _trail_mats[i].albedo_color
		c.a = alpha
		_trail_mats[i].albedo_color = c
		var sc := 1.0 - float(i) / float(_trail.size()) * 0.85
		_trail[i].scale = Vector3(sc, sc, sc)
	# Slow decay when stopped.
	if not active:
		for i in range(_trail.size()):
			_trail[i].visible = false
