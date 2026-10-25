class_name VolleyCourt
extends Node3D

## Procedural gym: court, net, bleachers, crowd, banners, lights.

const COURT_W := 9.0
const COURT_L := 18.0
const HALF_W := 4.5
const HALF_L := 9.0
const NET_H := 2.43
const ATTACK_LINE := 3.0

var home_id := "karasuno"
var away_id := "nekoma"
var home_primary := Color("#ff7a1a")
var away_primary := Color("#d81f35")

var zone_grid: Node3D
var target_cell: MeshInstance3D
var _target_mat: StandardMaterial3D

func _ready() -> void:
	home_id = "karasuno" if home_id == "" else home_id
	_build()

func setup(h_id: String, a_id: String) -> void:
	home_id = h_id
	away_id = a_id

func _mat(color: Color, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m

func _box(size: Vector3, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO, rough: float = 0.8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color, rough)
	mi.position = pos
	mi.rotation = rot
	add_child(mi)
	return mi

func _line(size: Vector3, pos: Vector3, color: Color = Color(0.96, 0.97, 1.0, 0.95)) -> void:
	var mi := _box(size, color, pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build() -> void:
	var home := GameData.team(home_id)
	var away := GameData.team(away_id)
	home_primary = Color.html(str(home["primary"]))
	away_primary = Color.html(str(away["primary"]))
	_build_environment()
	_build_floor()
	_build_lines()
	_build_net()
	_build_gym()
	_build_zone_grid()
	_build_banners(home, away)

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#070a14")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8ea2d8")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("#0b1020")
	env.fog_light_energy = 0.35
	env.fog_density = 0.004
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_color = Color("#fff2df")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 42.0
	add_child(sun)

	for z in [-7.0, 0.0, 7.0]:
		for x in [-5.5, 5.5]:
			var o := OmniLight3D.new()
			o.position = Vector3(x, 8.5, z)
			o.light_color = Color("#dfe9ff")
			o.light_energy = 1.4
			o.omni_range = 15.0
			o.shadow_enabled = false
			add_child(o)

func _build_floor() -> void:
	# Gym apron.
	_box(Vector3(30, 0.4, 34), Color("#1b2336"), Vector3(0, -0.22, 0), Vector3.ZERO, 0.92)
	# Free zone / run-off.
	_box(Vector3(17.0, 0.06, 26.0), Color("#b45309"), Vector3(0, 0.0, 0), Vector3.ZERO, 0.9)
	# Playing surface: two subtle halves.
	_box(Vector3(COURT_W, 0.08, HALF_L), Color("#155e75"), Vector3(0, 0.01, -HALF_L * 0.5), Vector3.ZERO, 0.82)
	_box(Vector3(COURT_W, 0.08, HALF_L), Color("#1e6f8a"), Vector3(0, 0.01, HALF_L * 0.5), Vector3.ZERO, 0.82)
	# Center strip.
	_box(Vector3(COURT_W, 0.082, 0.12), Color("#0e7490"), Vector3(0, 0.012, 0), Vector3.ZERO, 0.8)
	# Home / away tint blocks in the free zone.
	_box(Vector3(9.4, 0.03, 0.45), Color(home_primary.r, home_primary.g, home_primary.b, 0.9), Vector3(0, 0.035, -9.25), Vector3.ZERO, 0.7)
	_box(Vector3(9.4, 0.03, 0.45), Color(away_primary.r, away_primary.g, away_primary.b, 0.9), Vector3(0, 0.035, 9.25), Vector3.ZERO, 0.7)
	# Serve zone hash marks.
	for x in [-3.0, 0.0, 3.0]:
		_line(Vector3(0.045, 0.02, 0.55), Vector3(x, 0.045, -9.65))
		_line(Vector3(0.045, 0.02, 0.55), Vector3(x, 0.045, 9.65))

func _build_lines() -> void:
	var c := Color("#f8fbff")
	var h := 0.018
	# Sidelines.
	_line(Vector3(0.055, h, COURT_L), Vector3(-HALF_W, 0.045, 0), c)
	_line(Vector3(0.055, h, COURT_L), Vector3(HALF_W, 0.045, 0), c)
	# End lines.
	_line(Vector3(COURT_W, h, 0.055), Vector3(0, 0.045, -HALF_L), c)
	_line(Vector3(COURT_W, h, 0.055), Vector3(0, 0.045, HALF_L), c)
	# Center line.
	_line(Vector3(COURT_W, h, 0.065), Vector3(0, 0.045, 0), c)
	# Attack lines.
	_line(Vector3(COURT_W, h, 0.05), Vector3(0, 0.045, -ATTACK_LINE), c)
	_line(Vector3(COURT_W, h, 0.05), Vector3(0, 0.045, ATTACK_LINE), c)
	# Substitution zone marks (dashed at the sideline).
	for z in [-8.6, -8.1, 8.1, 8.6]:
		_line(Vector3(0.05, h, 0.42), Vector3(-HALF_W - 0.35, 0.045, z), Color(1, 1, 1, 0.45))

func _build_net() -> void:
	var post_mat := _mat(Color("#10141f"), 0.5, 0.4)
	for x in [-HALF_W - 0.28, HALF_W + 0.28]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.055
		pm.bottom_radius = 0.075
		pm.height = NET_H + 0.32
		post.mesh = pm
		post.material_override = post_mat
		post.position = Vector3(x, (NET_H + 0.32) * 0.5, 0)
		add_child(post)
		# Padding base.
		_box(Vector3(0.42, 0.10, 0.42), Color("#0b0f18"), Vector3(x, 0.05, 0))
	# Net top and bottom bands.
	_line(Vector3(9.0, 0.07, 0.035), Vector3(0, NET_H, 0), Color("#f4f6fb"))
	_line(Vector3(9.0, 0.035, 0.025), Vector3(0, NET_H - 1.0, 0), Color(0.9, 0.92, 0.97, 0.8))
	# Mesh: horizontal and vertical threads.
	for i in range(18):
		var y := NET_H - 0.06 - i * 0.052
		_line(Vector3(9.0, 0.008, 0.008), Vector3(0, y, 0), Color(1, 1, 1, 0.30))
	for i in range(25):
		var x := -4.32 + i * 0.36
		_line(Vector3(0.008, 0.94, 0.008), Vector3(x, NET_H - 0.52, 0), Color(1, 1, 1, 0.22))
	# Antennae.
	for x in [-HALF_W, HALF_W]:
		var antenna := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 0.025
		am.bottom_radius = 0.025
		am.height = 1.75
		antenna.mesh = am
		antenna.material_override = _mat(Color("#ff3b4d"), 0.5)
		antenna.position = Vector3(x, NET_H + 0.42, 0)
		add_child(antenna)
		for b in range(4):
			var band := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.top_radius = 0.027
			bm.bottom_radius = 0.027
			bm.height = 0.18
			band.mesh = bm
			band.material_override = _mat(Color.WHITE if b % 2 == 0 else Color("#ff3b4d"), 0.5)
			band.position = Vector3(x, NET_H + 0.06 + b * 0.36, 0)
			add_child(band)
	# Referee stand (simplified).
	_box(Vector3(0.7, 1.0, 0.7), Color("#0f1420"), Vector3(-5.9, 0.5, 0))
	_box(Vector3(0.65, 0.08, 0.65), Color("#2a3247"), Vector3(-5.9, 1.04, 0))
	_box(Vector3(0.08, 0.5, 0.08), Color("#0f1420"), Vector3(-5.9, 1.3, 0))

func _build_gym() -> void:
	# Side bleachers.
	for side: float in [-1.0, 1.0]:
		for row in range(7):
			var x := side * (10.5 + row * 0.95)
			var y := 0.38 + row * 0.42
			var col := Color("#131a2a").lightened(row * 0.018)
			_box(Vector3(0.92, 0.42, 25.0), col, Vector3(x, y, 0))
			# Seat fronts.
			_box(Vector3(0.06, 0.1, 25.0), Color("#26314b"), Vector3(x - side * 0.45, y + 0.16, 0))
	# Back wall + bleachers behind each baseline.
	for side: float in [-1.0, 1.0]:
		var z := side * 19.0
		_box(Vector3(34.0, 12.0, 0.5), Color("#090d18"), Vector3(0, 6.0, z + side * 2.0))
		for row in range(6):
			var y := 0.38 + row * 0.44
			var zz := side * (14.8 + row * 0.9)
			_box(Vector3(25.0, 0.44, 0.88), Color("#121a2b").lightened(row * 0.02), Vector3(0, y, zz))
	# Ceiling truss + lights.
	_box(Vector3(30.0, 0.25, 0.25), Color("#0e1422"), Vector3(0, 11.6, -7.0))
	_box(Vector3(30.0, 0.25, 0.25), Color("#0e1422"), Vector3(0, 11.6, 7.0))
	for x in [-10.0, -3.3, 3.3, 10.0]:
		for z in [-7.0, 7.0]:
			var lamp := _box(Vector3(2.2, 0.14, 0.7), Color("#fff3d6"), Vector3(x, 11.35, z), Vector3.ZERO, 0.35)
			lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_crowd()
	# Team benches.
	_box(Vector3(2.8, 0.10, 0.55), Color("#0f1522"), Vector3(-7.2, 0.55, -7.3))
	_box(Vector3(2.8, 0.10, 0.55), Color("#0f1522"), Vector3(7.2, 0.55, 7.3))
	_box(Vector3(0.5, 0.5, 0.5), Color("#0f1522"), Vector3(-7.2, 0.25, -7.3))
	_box(Vector3(0.5, 0.5, 0.5), Color("#0f1522"), Vector3(7.2, 0.25, 7.3))

func _build_crowd() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, 0.34, 0.22)
	mm.mesh = bm
	var count := 520
	mm.instance_count = count
	var palette := [
		Color("#2a3550"), Color("#3a4560"), Color("#1d2438"),
		Color("#7a2f38"), Color("#325a76"), Color("#5d4b7a"),
		Color("#9a6a2e"), Color("#314b3c")
	]
	var idx := 0
	for side: float in [-1.0, 1.0]:
		for row in range(7):
			for col in range(28):
				if idx >= count:
					break
				var x := side * (10.6 + row * 0.9) + randf_range(-0.12, 0.12)
				var z := -12.0 + col * 0.88 + randf_range(-0.15, 0.15)
				var y := 0.60 + row * 0.42 + randf_range(0.0, 0.08)
				var t := Transform3D(Basis().scaled(Vector3(1, randf_range(0.85, 1.2), 1)), Vector3(x, y, z))
				mm.set_instance_transform(idx, t)
				mm.set_instance_color(idx, palette[randi() % palette.size()].lightened(randf_range(-0.08, 0.12)))
				idx += 1
	# Fill the baseline bleachers with the rest.
	while idx < count:
		var side := -1.0 if idx % 2 == 0 else 1.0
		var row := (idx / 2) % 6
		var col := (idx / 12) % 22
		var x := -10.0 + col * 0.95 + randf_range(-0.2, 0.2)
		var y := 0.60 + row * 0.44
		var z := side * (14.9 + row * 0.9)
		var t := Transform3D(Basis().scaled(Vector3(1, randf_range(0.85, 1.15), 1)), Vector3(x, y, z))
		mm.set_instance_transform(idx, t)
		mm.set_instance_color(idx, palette[randi() % palette.size()].lightened(randf_range(-0.08, 0.1)))
		idx += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _build_banners(home: Dictionary, away: Dictionary) -> void:
	var title := Label3D.new()
	title.text = "SPRING TOURNAMENT 2013"
	title.font_size = 96
	title.pixel_size = 0.012
	title.modulate = Color("#ffc857")
	title.outline_size = 12
	title.outline_modulate = Color(0, 0, 0, 0.7)
	title.position = Vector3(0, 8.4, -21.4)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	title.rotation.y = 0
	add_child(title)
	var sub := Label3D.new()
	sub.text = "TOKYO METROPOLITAN GYMNASIUM  •  CENTER COURT"
	sub.font_size = 38
	sub.pixel_size = 0.012
	sub.modulate = Color(0.8, 0.86, 1.0, 0.7)
	sub.position = Vector3(0, 7.2, -21.35)
	add_child(sub)
	for side: float in [-1.0, 1.0]:
		var t := GameData.team(home_id if side < 0 else away_id)
		var col := Color.html(str(t["primary"]))
		var l := Label3D.new()
		l.text = str(t["short"])
		l.font_size = 150
		l.pixel_size = 0.014
		l.modulate = Color(col.r, col.g, col.b, 0.82)
		l.outline_size = 0
		l.position = Vector3(side * 16.5, 6.2, -21.2)
		l.rotation.y = 0
		add_child(l)
		var motto := Label3D.new()
		motto.text = str(t["motto"]).to_upper()
		motto.font_size = 44
		motto.pixel_size = 0.011
		motto.modulate = Color(1, 1, 1, 0.45)
		motto.position = Vector3(side * 16.5, 5.2, -21.2)
		add_child(motto)

func _build_zone_grid() -> void:
	zone_grid = Node3D.new()
	zone_grid.visible = false
	add_child(zone_grid)
	var c := Color(1, 1, 1, 0.18)
	for x in [-1.5, 1.5]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, 0.01, 18.0)
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = c
		mi.material_override = m
		mi.position = Vector3(x, 0.052, 0)
		zone_grid.add_child(mi)
	for z in [-7.2, -3.6, 3.6, 7.2]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(9.0, 0.01, 0.025)
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = c
		mi.material_override = m
		mi.position = Vector3(0, 0.052, z)
		zone_grid.add_child(mi)
	target_cell = MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(3.0, 3.6)
	target_cell.mesh = quad
	_target_mat = StandardMaterial3D.new()
	_target_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_target_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_target_mat.albedo_color = Color(1, 0.8, 0.3, 0.18)
	target_cell.material_override = _target_mat
	target_cell.position.y = 0.05
	zone_grid.add_child(target_cell)

func set_zone_grid_visible(v: bool) -> void:
	if zone_grid:
		zone_grid.visible = v

func set_target_cell(x: float, z: float, valid: bool, tint: Color = Color("#ffc857")) -> void:
	if not zone_grid:
		return
	var cx := clampf(floor((x + HALF_W) / 3.0), 0.0, 2.0) * 3.0 - HALF_W + 1.5
	var cz := clampf(floor((z + HALF_L) / 3.6), 0.0, 4.0) * 3.6 - HALF_L + 1.8
	target_cell.position = Vector3(cx, 0.052, cz)
	target_cell.visible = true
	_target_mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.20 if valid else 0.10)
	if not valid:
		_target_mat.albedo_color = Color(1.0, 0.25, 0.25, 0.14)

func hide_target_cell() -> void:
	if target_cell:
		target_cell.visible = false
