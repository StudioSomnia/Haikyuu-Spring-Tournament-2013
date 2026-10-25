class_name PlayerRig
extends Node3D

## A stylized, fully procedural volleyball player. No imported models.

const BODY_HEIGHT := 1.78

var data: Dictionary = {}
var team_id := ""
var side := -1
var team_primary := Color.WHITE
var team_secondary := Color.BLACK
var team_accent := Color.ORANGE
var role := "WS"
var is_libero := false

var body_root: Node3D
var torso: MeshInstance3D
var shorts: MeshInstance3D
var head: MeshInstance3D
var hair: MeshInstance3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var foot_l: MeshInstance3D
var foot_r: MeshInstance3D
var name_label: Label3D
var ring: MeshInstance3D

var velocity := Vector3.ZERO
var move_input := Vector2.ZERO
var target_pos := Vector3.ZERO
var has_target := false
var controlled := false
var speed := 4.2
var stamina := 100.0
var stamina_max := 100.0
var exhausted := false
var recover_time := 0.0

var jump_t := 0.0
var jump_duration := 0.0
var jump_height := 0.0
var is_jumping := false
var jump_offset := 0.0

var anim_time := 0.0
var move_amount := 0.0
var pose := "idle"
var action_name := ""
var action_time := 0.0
var action_duration := 0.0
var action_swing := 0.0

var _bounds := Rect2(-6.0, -11.0, 12.0, 11.0)
var _yaw_target := 0.0
var _arm_l_target := 0.0
var _arm_r_target := 0.0
var _leg_l_target := 0.0
var _leg_r_target := 0.0
var _body_tilt := 0.0
var _body_y := 0.0
var _body_y_smooth := 0.0
var _celebrate := 0.0

func setup(p: Dictionary, colors: Dictionary, team_side: int) -> void:
	data = p.duplicate(true)
	role = str(data.get("role", "WS"))
	is_libero = role == "L"
	side = team_side
	team_primary = colors.get("primary", Color.WHITE)
	team_secondary = colors.get("secondary", Color.BLACK)
	team_accent = colors.get("accent", Color.ORANGE)
	team_id = str(data.get("team_id", ""))
	stamina_max = 80.0 + float(data["stats"]["stamina"]) * 0.2
	stamina = stamina_max
	speed = 3.9 + float(data["stats"]["speed"]) * 0.018
	_build()
	set_name_plate()

func _mat(color: Color, rough: float = 0.8, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = 0.0
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func _mesh(mesh: Mesh, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color, 0.82, emission)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body_root.add_child(mi)
	return mi

func _build() -> void:
	body_root = Node3D.new()
	body_root.name = "Body"
	add_child(body_root)

	var skin := Color.html(str(data.get("skin", "#e3b28e")))
	var hair_col := Color.html(str(data.get("hair", "#2a2520")))
	var jersey := team_primary
	if is_libero:
		jersey = team_accent
	var shorts_col := team_secondary
	if is_libero:
		shorts_col = team_primary.darkened(0.25)

	# Hips / torso.
	shorts = _mesh(_box(Vector3(0.38, 0.26, 0.24)), shorts_col, Vector3(0, 0.88, 0))
	torso = _mesh(_box(Vector3(0.44, 0.52, 0.26)), jersey, Vector3(0, 1.24, 0))
	# Jersey side stripe.
	_mesh(_box(Vector3(0.045, 0.44, 0.27)), team_accent, Vector3(-0.225, 1.25, 0))
	_mesh(_box(Vector3(0.045, 0.44, 0.27)), team_accent, Vector3(0.225, 1.25, 0))
	# Shoulders.
	_mesh(_sphere(0.10), jersey, Vector3(-0.25, 1.42, 0))
	_mesh(_sphere(0.10), jersey, Vector3(0.25, 1.42, 0))

	# Head.
	head = _mesh(_sphere(0.135), skin, Vector3(0, 1.63, 0))
	# Hair cap and fringe.
	hair = _mesh(_sphere(0.145), hair_col, Vector3(0, 1.68, -0.012))
	hair.scale = Vector3(1.02, 0.74, 1.06)
	_mesh(_box(Vector3(0.24, 0.08, 0.10)), hair_col, Vector3(0, 1.59, -0.09))
	# Face dots (simple, readable from broadcast camera).
	var eye_mat := _mat(Color("#171821"), 1.0)
	for sx in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.mesh = _sphere(0.018)
		eye.material_override = eye_mat
		eye.position = Vector3(0.05 * sx, 1.65, -0.125)
		body_root.add_child(eye)

	# Arms.
	arm_l = _limb(Vector3(-0.29, 1.40, 0), Vector3(0.07, 0.32, 0.07), skin, jersey, Vector3(0, 0.30, 0))
	arm_r = _limb(Vector3(0.29, 1.40, 0), Vector3(0.07, 0.32, 0.07), skin, jersey, Vector3(0, 0.30, 0))

	# Legs.
	leg_l = _pivot(Vector3(-0.11, 0.82, 0))
	leg_r = _pivot(Vector3(0.11, 0.82, 0))
	var thigh_l := _mesh(_capsule(0.075, 0.42), skin, Vector3(0, -0.21, 0))
	thigh_l.reparent(leg_l, false)
	var thigh_r := _mesh(_capsule(0.075, 0.42), skin, Vector3(0, -0.21, 0))
	thigh_r.reparent(leg_r, false)
	var shin_l := _mesh(_capsule(0.065, 0.40), skin, Vector3(0, -0.55, 0))
	shin_l.reparent(leg_l, false)
	var shin_r := _mesh(_capsule(0.065, 0.40), skin, Vector3(0, -0.55, 0))
	shin_r.reparent(leg_r, false)
	foot_l = _mesh(_box(Vector3(0.13, 0.08, 0.25)), Color("#f2f4fa"), Vector3(0, -0.76, -0.05))
	foot_l.reparent(leg_l, false)
	foot_r = _mesh(_box(Vector3(0.13, 0.08, 0.25)), Color("#f2f4fa"), Vector3(0, -0.76, -0.05))
	foot_r.reparent(leg_r, false)
	# Kneepads.
	var pad_l := _mesh(_box(Vector3(0.12, 0.12, 0.12)), Color("#1a1f2b"), Vector3(0, -0.37, -0.07))
	pad_l.reparent(leg_l, false)
	var pad_r := _mesh(_box(Vector3(0.12, 0.12, 0.12)), Color("#1a1f2b"), Vector3(0, -0.37, -0.07))
	pad_r.reparent(leg_r, false)

	# Active indicator.
	ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.38
	torus.outer_radius = 0.46
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	var rm := _mat(team_accent, 0.5, 1.8)
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(team_accent.r, team_accent.g, team_accent.b, 0.9)
	ring.material_override = rm
	ring.rotation.x = PI * 0.5
	ring.position.y = 0.015
	ring.visible = false
	add_child(ring)

func _pivot(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	body_root.add_child(n)
	return n

func _limb(pos: Vector3, _size: Vector3, skin: Color, jersey: Color, _shoulder: Vector3) -> Node3D:
	var pivot := _pivot(pos)
	var upper := _mesh(_capsule(0.06, 0.36), jersey, Vector3(0, -0.16, 0))
	upper.reparent(pivot, false)
	var lower := _mesh(_capsule(0.05, 0.34), skin, Vector3(0, -0.46, 0))
	lower.reparent(pivot, false)
	var hand := _mesh(_sphere(0.07), skin, Vector3(0, -0.67, 0))
	hand.reparent(pivot, false)
	return pivot

func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m

func _sphere(r: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 14
	m.rings = 8
	return m

func _capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 4
	return m

func set_name_plate() -> void:
	var parts := str(data.get("name", "")).split(" ")
	var last_name := parts[parts.size() - 1] if parts.size() > 0 else "PLAYER"
	name_label = Label3D.new()
	name_label.text = "#%d  %s" % [int(data.get("number", 0)), last_name.to_upper()]
	name_label.font_size = 42
	name_label.pixel_size = 0.0027
	name_label.outline_size = 10
	name_label.outline_modulate = Color(0, 0, 0, 0.85)
	name_label.modulate = Color(0.9, 0.93, 1.0, 0.9)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.position = Vector3(0, 2.12, 0)
	add_child(name_label)

func set_active(v: bool) -> void:
	controlled = v
	if ring:
		ring.visible = v
	if name_label:
		name_label.modulate = Color(1, 0.92, 0.6, 1.0) if v else Color(0.85, 0.88, 0.98, 0.78)

func set_bounds(min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	_bounds = Rect2(min_x, min_z, max_x - min_x, max_z - min_z)

func set_move_input(v: Vector2) -> void:
	move_input = v.clamp(Vector2(-1, -1), Vector2(1, 1))
	if move_input.length() > 0.01:
		has_target = false

func set_target(p: Vector3) -> void:
	target_pos = p
	has_target = true

func clear_target() -> void:
	has_target = false

func tick(dt: float, bounds_enabled: bool = true) -> void:
	anim_time += dt
	if dt <= 0.0:
		return

	var desired := Vector3.ZERO
	if controlled and move_input.length() > 0.08:
		desired = Vector3(move_input.x, 0, move_input.y)
	elif has_target:
		var to := target_pos - global_position
		to.y = 0
		if to.length() > 0.10:
			desired = to.normalized()
			if to.length() < 0.25:
				desired *= 0.5
			if controlled:
				desired *= 0.78
		else:
			has_target = false

	var sprinting := Input.is_action_pressed("sprint") and controlled and move_input.length() > 0.1
	var spd := speed
	if sprinting and stamina > 2.0:
		spd *= 1.62
		stamina = max(0.0, stamina - dt * 11.5)
	else:
		stamina = min(stamina_max, stamina + dt * 5.5)
	exhausted = stamina < stamina_max * 0.18
	if exhausted:
		spd *= 0.78
	if recover_time > 0.0:
		# Getting up from a dive costs a beat: start slow and ramp back up.
		recover_time = maxf(0.0, recover_time - dt)
		spd *= lerpf(0.45, 1.0, 1.0 - clampf(recover_time / 0.9, 0.0, 1.0))

	var accel := 20.0 if desired.length() > 0.01 else 22.0
	velocity = velocity.move_toward(desired * spd, accel * dt)
	if velocity.length() < 0.02:
		velocity = Vector3.ZERO
	global_position += velocity * dt

	if bounds_enabled:
		global_position.x = clampf(global_position.x, _bounds.position.x, _bounds.position.x + _bounds.size.x)
		global_position.z = clampf(global_position.z, _bounds.position.y, _bounds.position.y + _bounds.size.y)

	if velocity.length() > 0.12:
		_yaw_target = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, _yaw_target, min(1.0, dt * 12.0))
		move_amount = lerpf(move_amount, min(1.0, velocity.length() / max(1.0, speed)), min(1.0, dt * 10.0))
	else:
		move_amount = lerpf(move_amount, 0.0, min(1.0, dt * 10.0))

	_update_jump(dt)
	_update_animation(dt)
	_update_ring(dt)

func _update_jump(dt: float) -> void:
	if not is_jumping:
		jump_offset = lerpf(jump_offset, 0.0, min(1.0, dt * 16.0))
		return
	jump_t += dt
	var u := clampf(jump_t / max(0.05, jump_duration), 0.0, 1.0)
	jump_offset = sin(u * PI) * jump_height
	if u >= 1.0:
		is_jumping = false
		jump_offset = 0.0

func jump(height: float, duration: float) -> void:
	# Cap the leap at half the player's body height. The rig is authored at
	# BODY_HEIGHT, so no call can send a player "flying" above that.
	jump_height = minf(height, BODY_HEIGHT * 0.5)
	jump_duration = duration
	jump_t = 0.0
	is_jumping = true
	stamina = max(0.0, stamina - 2.5)

func play_action(name: String, duration: float) -> void:
	action_name = name
	action_duration = max(0.08, duration)
	action_time = 0.0
	pose = name

func celebrate() -> void:
	_celebrate = 1.6
	pose = "celebrate"

func _update_animation(dt: float) -> void:
	if _celebrate > 0.0:
		_celebrate -= dt
	if action_duration > 0.0:
		action_time += dt
		action_swing = clampf(action_time / action_duration, 0.0, 1.0)
		if action_time >= action_duration:
			action_name = ""
			action_duration = 0.0
			action_swing = 0.0

	var run_cycle := sin(anim_time * 12.0) * move_amount
	var idle_cycle := sin(anim_time * 2.2) * 0.04
	_arm_l_target = -run_cycle * 0.6
	_arm_r_target = run_cycle * 0.6
	_leg_l_target = run_cycle * 0.7
	_leg_r_target = -run_cycle * 0.7
	_body_tilt = move_amount * 0.10
	_body_y = 0.0 + idle_cycle
	_body_tilt = lerpf(_body_tilt, move_amount * 0.10, min(1.0, dt * 8.0))

	if _celebrate > 0.0:
		_arm_l_target = -2.6 + sin(anim_time * 15.0) * 0.15
		_arm_r_target = 2.6 - sin(anim_time * 15.0) * 0.15
		_body_y = abs(sin(anim_time * 10.0)) * 0.12
		_body_tilt = 0.0
	elif is_jumping or jump_offset > 0.05:
		var tuck := clampf(jump_offset / max(0.4, jump_height), 0.0, 1.0)
		_leg_l_target = -0.55 * tuck
		_leg_r_target = -0.55 * tuck
		_arm_l_target = -1.4 * tuck
		_arm_r_target = 1.4 * tuck
		_body_tilt = 0.0
		if action_name == "spike":
			var s := sin(action_swing * PI)
			_arm_r_target = lerpf(-2.9, 1.15, action_swing)
			_arm_l_target = -0.9
			_body_tilt = -0.16 * s
		elif action_name == "block":
			_arm_l_target = -2.95
			_arm_r_target = 2.95
			_body_tilt = 0.0
		elif action_name == "serve":
			_arm_r_target = lerpf(-2.8, 0.9, action_swing)
			_arm_l_target = -0.6
	elif action_name == "receive" or action_name == "dig":
		var s := sin(action_swing * PI)
		_body_y = -0.12 * s
		_body_tilt = 0.38 * s
		_arm_l_target = -1.15 * s
		_arm_r_target = -1.15 * s
		_leg_l_target = 0.45 * s
		_leg_r_target = -0.45 * s
	elif action_name == "set":
		var s := sin(action_swing * PI)
		_arm_l_target = lerpf(-0.4, -2.5, s)
		_arm_r_target = lerpf(-0.4, -2.5, s)
		_body_y = 0.05 * s
	elif action_name == "dive":
		var s := sin(action_swing * PI)
		_body_tilt = 1.25 * s
		_body_y = -0.45 * s
		_arm_l_target = -1.1
		_arm_r_target = -1.1
		_leg_l_target = 0.3
		_leg_r_target = -0.3
	elif action_name == "serve_toss":
		var s := sin(action_swing * PI)
		_arm_l_target = -2.2 * s
		_arm_r_target = -1.6 * s
		_body_tilt = -0.10 * s
		_body_y = 0.04 * s

	# Apply with smooth damping.
	var k := minf(1.0, dt * 14.0)
	arm_l.rotation.x = lerp_angle(arm_l.rotation.x, _arm_l_target, k)
	arm_r.rotation.x = lerp_angle(arm_r.rotation.x, _arm_r_target, k)
	arm_l.rotation.z = lerpf(arm_l.rotation.z, -0.12, k)
	arm_r.rotation.z = lerpf(arm_r.rotation.z, 0.12, k)
	leg_l.rotation.x = lerp_angle(leg_l.rotation.x, _leg_l_target, k)
	leg_r.rotation.x = lerp_angle(leg_r.rotation.x, _leg_r_target, k)
	body_root.rotation.x = lerpf(body_root.rotation.x, _body_tilt, min(1.0, dt * 12.0))
	_body_y_smooth = lerpf(_body_y_smooth, _body_y, min(1.0, dt * 12.0))
	body_root.position.y = _body_y_smooth + jump_offset
	foot_l.rotation.x = leg_l.rotation.x * -0.4
	foot_r.rotation.x = leg_r.rotation.x * -0.4

func _update_ring(dt: float) -> void:
	if ring.visible:
		ring.rotation.z += dt * 1.4
		ring.position.y = 0.015 + sin(anim_time * 4.0) * 0.01

func start_dive(dir: Vector3) -> void:
	play_action("dive", 0.42)
	velocity = dir.normalized() * 8.4
	global_position += dir.normalized() * 0.5
	recover_time = 0.95
	stamina = max(0.0, stamina - 3.5)

func reset_for_serve() -> void:
	velocity = Vector3.ZERO
	move_input = Vector2.ZERO
	has_target = false
	is_jumping = false
	jump_offset = 0.0
	recover_time = 0.0
	action_name = ""
	action_duration = 0.0
	_celebrate = 0.0
	pose = "idle"
	stamina = min(stamina_max, stamina + 8.0)

func set_player(p: Dictionary) -> void:
	# Used by substitutions: rebuild the visual with new data/colors.
	for c in get_children():
		remove_child(c)
		c.queue_free()
	data = p.duplicate(true)
	role = str(data.get("role", "WS"))
	is_libero = role == "L"
	stamina_max = 80.0 + float(data["stats"]["stamina"]) * 0.2
	stamina = stamina_max
	speed = 3.9 + float(data["stats"]["speed"]) * 0.018
	jump_offset = 0.0
	recover_time = 0.0
	is_jumping = false
	velocity = Vector3.ZERO
	_build()
	set_name_plate()
	set_active(controlled)
