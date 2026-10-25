extends Node3D

## The match engine. Procedural court, six-on-six volleyball, tactical team
## control, scripted ball arcs, AI, rally scoring, and broadcast presentation.

signal match_finished(result: Dictionary)

const CourtScript := preload("res://scripts/Court.gd")
const BallScript := preload("res://scripts/Ball.gd")
const RigScript := preload("res://scripts/PlayerRig.gd")
const HUDScript := preload("res://scripts/ui/MatchHUD.gd")
const TacticsScript := preload("res://scripts/ui/TacticsOverlay.gd")
const PauseScript := preload("res://scripts/ui/PauseOverlay.gd")

const HOME := 0
const AWAY := 1
const HALF_W := 4.5
const HALF_L := 9.0
const ATTACK_LINE := 3.0
const NET_H := 2.43

# Court slots, 0 = back right, 1 = front right, 2 = front center,
# 3 = front left, 4 = back left, 5 = back center.
const SLOT_X := [3.2, 3.2, 0.0, -3.2, -3.2, 0.0]
const SLOT_Z := [6.4, 2.35, 2.35, 2.35, 6.4, 6.4]
const FRONT := [1, 2, 3]
const BACK := [0, 4, 5]

const PLAY_NAMES := ["QUICK", "BACK QUICK", "WING", "PIPE", "DUMP"]
const PLAY_KEYS := ["quick", "back_quick", "wing", "pipe", "dump"]
const SERVE_NAMES := ["OVERHAND", "UNDERARM", "JUMP"]
const BLOCK_NAMES := ["READ", "COMMIT", "SPREAD", "TRIPLE"]
const RECV_NAMES := ["BALANCED", "PERIMETER", "STACK"]

# Public, set by Main before add_child().
var home_team_id := "karasuno"
var away_team_id := "nekoma"
var match_options: Dictionary = {}

var court: VolleyCourt
var ball: VolleyBall
var camera: Camera3D
var hud: MatchHUD
var tactics_overlay
var pause_overlay

var teams: Array = []
var phase := "intro"
var phase_timer := 0.0
var paused := false
var overlay_open := false

var rally: Dictionary = {}
var set_number := 1
var set_scores: Array = []
var serving_side := HOME
var starting_server := HOME
var player_side := HOME
var autoplay := false
var difficulty := 2
var time_scale := 1.0
var camera_mode := 0

var active_rig: PlayerRig = null
var active_side := HOME
var active_slot := -1
var swap_cooldown := 0.0
var dive_clock := 0.0

var camera_pos := Vector3(0, 9.0, -18.0)
var camera_look := Vector3(0, 1.2, 0.8)
var mouse_pos := Vector2.ZERO
var aim_point := Vector3(0, 0, 5.0)
var aim_valid := true
var aim_active := false

var serve_charge := 0.0
var serving_hold := false
var ai_serve_delay := 0.0
var _prev_ball_pos := Vector3.ZERO
var _result_sent := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	autoplay = bool(match_options.get("autoplay", false))
	difficulty = clampi(int(match_options.get("difficulty", GameData.options.get("difficulty", 2))), 0, 4)
	time_scale = float(match_options.get("time_scale", 1.0))
	if time_scale != 1.0:
		Engine.time_scale = time_scale
	camera_mode = clampi(int(GameData.options.get("camera", 0)), 0, 3)
	_build_world()
	_build_teams()
	_build_ui()
	_reset_match()
	set_process(true)

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build_world() -> void:
	court = VolleyCourt.new()
	court.home_id = home_team_id
	court.away_id = away_team_id
	add_child(court)

	ball = VolleyBall.new()
	add_child(ball)
	ball.arrived.connect(_on_ball_arrived)

	camera = Camera3D.new()
	camera.fov = 50.0
	camera.near = 0.1
	camera.far = 140.0
	add_child(camera)
	camera.current = true
	camera_pos = Vector3(0, 9.2, -18.2)
	camera_look = Vector3(0, 1.2, 0.8)
	camera.look_at_from_position(camera_pos, camera_look, Vector3.UP)

func _build_teams() -> void:
	teams.clear()
	teams.append(_make_team(home_team_id, HOME))
	teams.append(_make_team(away_team_id, AWAY))

func _make_team(id: String, side: int) -> Dictionary:
	var td: Dictionary = GameData.team(id)
	var colors := {
		"primary": Color.html(str(td["primary"])),
		"secondary": Color.html(str(td["secondary"])),
		"accent": Color.html(str(td["accent"]))
	}
	var lineup: Array = []
	for p in GameData.starters(id):
		lineup.append(p.duplicate(true))
	var bench: Array = []
	for p in GameData.bench(id):
		bench.append(p.duplicate(true))
	var pb: Dictionary = td["playbook"]
	var team := {
		"id": id,
		"data": td,
		"side": side,
		"sign": _signi(side),
		"colors": colors,
		"lineup": lineup,
		"bench": bench,
		"slots": [],
		"rigs": [],
		"score": 0,
		"sets": 0,
		"rotation": 0,
		"flow": 0.0,
		"ability_ready": false,
		"ability_kind": "",
		"ability_timer": 0,
		"timeouts": 2,
		"subs": 6,
		"play_index": 2,
		"serve_index": _serve_index_for(str(pb.get("serve", "float"))),
		"block_index": _block_index_for(str(pb.get("block", "read"))),
		"recv_index": _recv_index_for(str(pb.get("receive", "balanced"))),
		"stats": {
			"kills": 0, "blocks": 0, "aces": 0, "digs": 0, "errors": 0,
			"attacks": 0, "serves": 0, "receptions": 0
		}
	}
	for s in range(6):
		team.slots.append(lineup[(s + int(team.rotation)) % 6])
		var rig := PlayerRig.new()
		rig.setup(team.slots[s], colors, _signi(side))
		var zmin := -10.9 if side == HOME else 0.22
		var zmax := -0.22 if side == HOME else 10.9
		rig.set_bounds(-6.2, 6.2, zmin, zmax)
		add_child(rig)
		rig.global_position = _base_pos(side, s)
		rig.set_active(false)
		team.rigs.append(rig)
	return team

func _build_ui() -> void:
	hud = MatchHUD.new()
	add_child(hud)
	hud.setup(GameData.team(home_team_id), GameData.team(away_team_id))
	hud.set_difficulty(GameData.difficulty_name())
	hud.set_camera(GameData.CAMERA_NAMES[camera_mode])

	tactics_overlay = TacticsScript.new()
	add_child(tactics_overlay)
	tactics_overlay.changed.connect(_on_tactics_changed)
	tactics_overlay.closed.connect(_on_tactics_closed)

	pause_overlay = PauseScript.new()
	add_child(pause_overlay)
	pause_overlay.resume.connect(_resume_from_pause)
	pause_overlay.tactics.connect(_pause_to_tactics)
	pause_overlay.substitute.connect(_pause_substitute)
	pause_overlay.substitute_custom.connect(_pause_substitute_custom)
	pause_overlay.timeout_taken.connect(_pause_timeout)
	pause_overlay.forfeit.connect(_forfeit_match)

# ---------------------------------------------------------------------------
# Teams, rotations, positions
# ---------------------------------------------------------------------------

func _signi(side: int) -> int:
	return -1 if side == HOME else 1

func _signf(side: int) -> float:
	return -1.0 if side == HOME else 1.0

func _team(side: int) -> Dictionary:
	return teams[side]

func _opp(side: int) -> Dictionary:
	return teams[1 - side]

func _serve_index_for(s: String) -> int:
	match s:
		"underarm": return 1
		"jump": return 2
		_: return 0

func _block_index_for(s: String) -> int:
	match s:
		"commit": return 1
		"spread": return 2
		"triple": return 3
		_: return 0

func _recv_index_for(s: String) -> int:
	match s:
		"perimeter": return 1
		"stack": return 2
		_: return 0

func _base_pos(side: int, slot: int) -> Vector3:
	return Vector3(SLOT_X[slot] * _signf(side), 0.0, _signf(side) * SLOT_Z[slot])

func _serve_pos(side: int, slot: int) -> Vector3:
	return Vector3(clampf(SLOT_X[slot], -3.7, 3.7) * _signf(side), 0.0, _signf(side) * 9.55)

func _setter_slot(team: Dictionary) -> int:
	for s in [1, 2, 3, 0, 4, 5]:
		if str(team.slots[s].get("role", "")) == "S":
			return s
	var best := 2
	var best_val := -100.0
	for s in range(6):
		var p: Dictionary = team.slots[s]
		if str(p.get("role", "")) == "L":
			continue
		var v := float(p["stats"]["set"]) + float(p["stats"]["iq"]) * 0.25
		if v > best_val:
			best_val = v
			best = s
	return best

func _setter_nest(team: Dictionary) -> Vector3:
	var side: int = int(team["side"])
	var rig: PlayerRig = team.rigs[_setter_slot(team)]
	var x := clampf(rig.global_position.x, -2.4, 2.4)
	return Vector3(x, 0.0, _signf(side) * 1.75)

func _apply_rotation(team: Dictionary) -> void:
	var stamina_map := {}
	for s in range(6):
		var old_rig: PlayerRig = team.rigs[s]
		stamina_map[str(old_rig.data.get("name", ""))] = old_rig.stamina
	for s in range(6):
		var p: Dictionary = team.lineup[(s + int(team.rotation)) % 6]
		team.slots[s] = p
		var rig: PlayerRig = team.rigs[s]
		if str(rig.data.get("name", "")) != str(p.get("name", "")):
			rig.set_player(p)
			if stamina_map.has(str(p.get("name", ""))):
				rig.stamina = float(stamina_map[str(p.get("name", ""))])
			else:
				rig.stamina = rig.stamina_max
		rig.global_position = _base_pos(int(team["side"]), s)
		rig.set_active(false)
		rig.clear_target()
		rig.set_move_input(Vector2.ZERO)

func _rotate(team: Dictionary) -> void:
	team.rotation = (int(team.rotation) + 1) % 6
	_apply_rotation(team)

func _reset_team(team: Dictionary) -> void:
	team.score = 0
	team.sets = 0
	team.rotation = 0
	team.flow = 0.0
	team.ability_ready = false
	team.ability_kind = ""
	team.ability_timer = 0
	team.timeouts = 2
	team.subs = 6
	for k in team.stats.keys():
		team.stats[k] = 0
	for p in team.lineup:
		_reset_player_counters(p)
	for p in team.bench:
		_reset_player_counters(p)
	_apply_rotation(team)
	for rig in team.rigs:
		rig.global_position = _base_pos(int(team["side"]), team.rigs.find(rig))
		rig.reset_for_serve()

func _reset_player_counters(p: Dictionary) -> void:
	for k in ["points", "attacks", "kills", "errors", "blocks", "digs", "aces", "serves", "receptions", "sets"]:
		p[k] = 0

func _team_stat(team: Dictionary, key: String, n: int = 1) -> void:
	team.stats[key] = int(team.stats.get(key, 0)) + n

func _player_stat(p: Dictionary, key: String, n: int = 1) -> void:
	if p.is_empty():
		return
	p[key] = int(p.get(key, 0)) + n

func _nearest_to(team: Dictionary, pos: Vector3, slots: Array, exclude: int = -1) -> Dictionary:
	var best := {"slot": -1, "rig": null, "dist": 9999.0}
	for s in slots:
		if s == exclude:
			continue
		var rig: PlayerRig = team.rigs[s]
		var d := Vector2(rig.global_position.x - pos.x, rig.global_position.z - pos.z).length()
		if d < best.dist:
			best = {"slot": s, "rig": rig, "dist": d}
	return best

func _receiver_for(team: Dictionary, landing: Vector3) -> Dictionary:
	var setter := _setter_slot(team)
	var candidates: Array = []
	for s in BACK:
		if s != setter:
			candidates.append(s)
	if candidates.is_empty():
		candidates = BACK.duplicate()
	var nearest := _nearest_to(team, landing, candidates)
	if landing.z * _signf(int(team["side"])) < 3.2:
		var front := _nearest_to(team, landing, FRONT, setter)
		if front.dist < nearest.dist - 0.6:
			return front
	return nearest

func _receive_radius_for(player: Dictionary, pressure: float = 0.0) -> float:
	var def := clampf(float(player["stats"]["receive"]) / 100.0, 0.0, 1.0)
	var spd := clampf(float(player["stats"]["speed"]) / 100.0, 0.0, 1.0)
	# Serves get a generous, readable circle; a hard-driven spike shrinks it.
	var radius := 0.62 + pow(def, 1.5) * 0.96 + spd * 0.07
	radius *= 1.0 - clampf(pressure, 0.0, 0.50)
	return clampf(radius, 0.60, 1.76)

func _receive_window_for(player: Dictionary) -> float:
	var def := clampf(float(player["stats"]["receive"]) / 100.0, 0.0, 1.0)
	return 0.10 + pow(def, 1.25) * 0.19

func _receive_timing_score(time_left: float, player: Dictionary) -> float:
	var window := _receive_window_for(player)
	var ideal := 0.10
	return clampf(1.0 - absf(time_left - ideal) / maxf(0.08, window), 0.0, 1.0)

func _contact_quality(team: Dictionary, player: Dictionary, dist: float, radius: float, timing: float, pressed: bool) -> float:
	if dist > radius * 1.18:
		return -1.0
	var pos_score := 0.10
	if dist <= radius:
		pos_score = 1.0 - (dist / maxf(0.25, radius)) * 0.32
	var base := pos_score * 0.68 + clampf(timing, 0.0, 1.0) * 0.32
	var stat := clampf(float(player["stats"]["receive"]) / 100.0, 0.0, 1.0)
	var q := base * (0.74 + stat * 0.36)
	q += _flow_bonus(int(team["side"]), "receive") * 0.22
	if not pressed:
		q = minf(q, 0.52)
	return clampf(q, 0.05, 1.0)

## A defender who is beaten can still throw out a hand. This only applies to the
## AI: the human's circle is an honest promise, and the dive is their lunge.
func _emergency_touch(player: Dictionary, dist: float, radius: float) -> float:
	var over := dist - radius * 1.18
	if over <= 0.0:
		return -1.0
	var def := clampf(float(player["stats"]["receive"]) / 100.0, 0.0, 1.0)
	var spd := clampf(float(player["stats"]["speed"]) / 100.0, 0.0, 1.0)
	if over > radius * 0.45:
		return -1.0
	var chance := clampf(0.38 - over * 0.14 + def * 0.16 + spd * 0.08, 0.03, 0.62)
	if _rng.randf() > chance:
		return -1.0
	return clampf(0.48 - over * 0.11, 0.10, 0.48)

func _ai_receive_timing(player: Dictionary) -> float:
	var def := clampf(float(player["stats"]["receive"]) / 100.0, 0.0, 1.0)
	var t := 0.40 + def * 0.30 + float(difficulty) * 0.022
	t += _rng.randf_range(-0.16, 0.16)
	return clampf(t, 0.16, 0.97)

func _set_receive_target(side: int, slot: int, pressure: float, show_circle: bool) -> void:
	var team: Dictionary = teams[side]
	if slot < 0 or slot >= 6:
		return
	var player: Dictionary = team.slots[slot]
	var radius := _receive_radius_for(player, pressure)
	rally.recv_radius = radius
	rally.recv_window = _receive_window_for(player)
	rally.receive_pressed = false
	rally.receive_timing = 0.0
	rally.receive_time_left = -1.0
	rally.receive_quality = 0.0
	if show_circle:
		var col := UI.CYAN
		court.set_receive_marker(ball.end, radius, col)
	else:
		court.hide_receive_marker()

func _front_near_net(team: Dictionary, x: float) -> Array:
	var out: Array = []
	for s in FRONT:
		var rig: PlayerRig = team.rigs[s]
		if absf(rig.global_position.x - x) < 2.7:
			out.append(s)
	out.sort_custom(func(a, b):
		return absf(team.rigs[a].global_position.x - x) < absf(team.rigs[b].global_position.x - x)
	)
	return out

func _is_setter(team: Dictionary, slot: int) -> bool:
	return slot == _setter_slot(team)

func _attack_candidates(team: Dictionary) -> Array:
	var out: Array = []
	for s in range(6):
		var p: Dictionary = team.slots[s]
		if str(p.get("role", "")) == "L":
			continue
		if s == _setter_slot(team):
			continue
		out.append(s)
	if out.is_empty():
		out = [1, 3, 5]
	return out

func _best_attacker(team: Dictionary, front_only: bool = false, back_only: bool = false) -> int:
	var best := -1
	var best_val := -100.0
	for s in _attack_candidates(team):
		if front_only and not FRONT.has(s):
			continue
		if back_only and not BACK.has(s):
			continue
		var p: Dictionary = team.slots[s]
		var v := float(p["stats"]["attack"]) + float(p["stats"]["jump"]) * 0.15
		if v > best_val:
			best_val = v
			best = s
	return best if best >= 0 else 2

# ---------------------------------------------------------------------------
# Match / set flow
# ---------------------------------------------------------------------------

func _sets_count() -> int:
	return clampi(int(match_options.get("sets", GameData.options.get("sets", 5))), 1, 5)

func _sets_to_win() -> int:
	return int(ceil(float(_sets_count()) / 2.0))

func _target_score() -> int:
	if _sets_count() > 1 and set_number >= _sets_count():
		return 15
	return 25

func _reset_match() -> void:
	_result_sent = false
	set_number = 1
	set_scores = []
	starting_server = _rng.randi() % 2
	serving_side = starting_server
	for team in teams:
		_reset_team(team)
	phase = "intro"
	phase_timer = 1.0 if autoplay else 2.2
	hud.update_score(teams[HOME].sets, teams[AWAY].sets, 0, 0, serving_side, set_number, _sets_to_win())
	hud.show_banner(
		"SPRING TOURNAMENT 2013",
		"%s   vs   %s" % [str(GameData.team(home_team_id)["short"]), str(GameData.team(away_team_id)["short"])],
		UI.GOLD, 1.4
	)
	hud.commentary("Tokyo Metropolitan Gymnasium. Center court. First serve coming up.", UI.MUTED, 3.0)

func _start_set() -> void:
	for team in teams:
		team.score = 0
	serving_side = (starting_server + set_number - 1) % 2
	phase = "set_intro"
	phase_timer = 0.9 if autoplay else 1.7
	hud.update_score(teams[HOME].sets, teams[AWAY].sets, 0, 0, serving_side, set_number, _sets_to_win())
	hud.show_banner(
		"SET %d" % set_number,
		"FIRST TO %d  •  WIN BY 2  •  %s TO SERVE" % [_target_score(), str(teams[serving_side].data["short"])],
		UI.ORANGE, 1.0
	)
	hud.commentary(
		"%s takes the court. %s will serve first." % [str(teams[serving_side].data["name"]), str(teams[serving_side].data["short"])],
		UI.TEXT, 2.6
	)

func _begin_serve() -> void:
	rally = {
		"attacking": serving_side,
		"defending": 1 - serving_side,
		"phase": "serve",
		"pass_quality": 0.9,
		"set_quality": 0.7,
		"attack_quality": 0.7,
		"attack_type": "spike",
		"serve_quality": 0.8,
		"setter_slot": -1,
		"hitter_slot": -1,
		"set_target": Vector3.ZERO,
		"attack_target": Vector3.ZERO,
		"attack_hint_x": 0.0,
		"landing": Vector3.ZERO,
		"chaser_side": -1,
		"chaser_slot": -1,
		"net_checked": false,
		"jump_pressed": false,
		"jump_quality": 0.0,
		"timing_value": 0.0,
		"recv_radius": 1.2,
		"recv_window": 0.22,
		"receive_pressed": false,
		"receive_timing": 0.0,
		"receive_time_left": -1.0,
		"receive_quality": 0.0,
		"block_winner": -1,
		"blocker_slot": -1,
		"def_react": 0.0,
		"player_block_bonus": 0.0,
		"dead_winner": -1,
		"dead_reason": "",
		"dead_player": null,
		"point_override": -1,
		"point_reason": "",
		"point_player": null,
		"point_winner": -1
	}
	phase = "serve"
	serve_charge = 0.0
	serving_hold = false
	dive_clock = 0.0
	ball.hide_ball()
	for side in [HOME, AWAY]:
		var team: Dictionary = teams[side]
		for s in range(6):
			var rig: PlayerRig = team.rigs[s]
			rig.reset_for_serve()
			rig.set_move_input(Vector2.ZERO)
			rig.clear_target()
			rig.set_active(false)
			rig.global_position = _base_pos(side, s)
	var srv: Dictionary = teams[serving_side]
	var server: PlayerRig = srv.rigs[0]
	server.global_position = _serve_pos(serving_side, 0)
	ball.hold_at(server.global_position + Vector3(0, 1.55, 0))
	_apply_receive_shape(teams[1 - serving_side])
	_set_active(serving_side, 0)
	ai_serve_delay = 0.85 + _rng.randf() * 0.35
	_maybe_ai_ability(serving_side)
	_maybe_ai_ability(1 - serving_side)
	hud.update_score(teams[HOME].sets, teams[AWAY].sets, teams[HOME].score, teams[AWAY].score, serving_side, set_number, _sets_to_win())
	hud.set_rally(0)
	rally_hits = 0
	hud.clear_power()
	hud.hide_reticle()
	court.set_zone_grid_visible(false)
	court.hide_target_cell()
	court.hide_receive_marker()
	var human_serving := serving_side == player_side and not autoplay
	if human_serving:
		hud.set_phase("SERVE", UI.ORANGE)
		hud.set_prompt("HOLD SPACE — RELEASE IN THE SWEET SPOT", "AIM WITH MOUSE  •  1-3 SERVE TYPE  •  TAB TACTICS")
	else:
		hud.set_phase("SERVE", UI.MUTED)
		hud.set_prompt("%s TO SERVE" % str(srv.data["short"]), "THE RECEIVING TEAM IS SETTING ITS SHAPE")
	_pressure_banner()

func _apply_receive_shape(team: Dictionary) -> void:
	var side: int = int(team["side"])
	var sign := _signf(side)
	var shape: int = int(team.recv_index)
	var back_positions := {}
	if shape == 1:
		back_positions = {0: Vector3(4.0 * sign, 0, sign * 6.5), 5: Vector3(0, 0, sign * 8.3), 4: Vector3(-4.0 * sign, 0, sign * 6.5)}
	elif shape == 2:
		back_positions = {0: Vector3(2.3 * sign, 0, sign * 6.0), 5: Vector3(0, 0, sign * 7.1), 4: Vector3(-2.3 * sign, 0, sign * 6.0)}
	else:
		back_positions = {0: _base_pos(side, 0), 5: _base_pos(side, 5), 4: _base_pos(side, 4)}
	for s in range(6):
		var rig: PlayerRig = team.rigs[s]
		if back_positions.has(s):
			rig.global_position = back_positions[s]
		else:
			rig.global_position = _base_pos(side, s)

func _serve_release(quality: float, override_target = null) -> void:
	if phase != "serve":
		return
	var srv: Dictionary = teams[serving_side]
	var server: PlayerRig = srv.rigs[0]
	var player: Dictionary = srv.slots[0]
	var idx: int = int(srv.serve_index)
	var target: Vector3 = aim_point if override_target == null else override_target
	if override_target == null and not aim_valid:
		# No usable mouse aim (keyboard-only or gamepad): serve into a real
		# zone instead of the stale default point.
		target = Vector3(
			_rng.randf_range(-3.6, 3.6),
			0.12,
			_signf(1 - serving_side) * _rng.randf_range(4.2, 8.2)
		)
	var serve_stat := float(player["stats"]["serve"]) / 100.0
	var power := clampf(quality + serve_stat * 0.12 + _flow_bonus(serving_side, "serve") * 0.25, 0.0, 1.15)
	var out_chance := 0.055
	match idx:
		0: out_chance = 0.05
		2: out_chance = 0.085
		_: out_chance = 0.008
	out_chance += maxf(0.0, 0.55 - quality) * 0.55
	out_chance -= serve_stat * 0.04
	if serving_side != player_side or autoplay:
		out_chance += (2 - difficulty) * 0.015
	var target_inside := _inside_court(target, 1 - serving_side, 0.0)
	var error := false
	if not target_inside and override_target == null:
		error = true
	elif _rng.randf() < maxf(0.0, out_chance):
		error = true
	if error:
		var miss := target
		if _inside_court(miss, 1 - serving_side, 0.0):
			var dirx := 1.0 if miss.x >= 0.0 else -1.0
			miss.x += dirx * _rng.randf_range(0.8, 1.8)
			miss.z += _signf(1 - serving_side) * _rng.randf_range(-0.8, 1.8)
		rally.point_override = 1 - serving_side
		rally.point_reason = "error"
		rally.point_player = player
		var start := server.global_position + Vector3(0, 2.1 if idx == 2 else 1.8, 0)
		ball.launch(start, Vector3(miss.x, 0.12, miss.z), 1.0, 1.6, "serve", server, serving_side, false)
		phase = "serve_flight"
		server.play_action("serve", 0.55)
		if idx == 2:
			server.jump(0.45, 0.82)
		Sfx.play("serve", -8.0, 0.95)
		if serving_side == player_side:
			hud.commentary("That serve is going long...", UI.RED, 2.0)
		return
	target.x = clampf(target.x, -HALF_W + 0.35, HALF_W - 0.35)
	var recv_sign := _signf(1 - serving_side)
	target.z = recv_sign * clampf(absf(target.z), 0.55, HALF_L - 0.35)
	if target.z * _signf(1 - serving_side) < 0.0:
		target.z = _signf(1 - serving_side) * 1.0
	rally.serve_quality = clampf(power / 1.15, 0.0, 1.0)
	rally.attacking = serving_side
	rally.defending = 1 - serving_side
	rally.landing = target
	var recv: Dictionary = teams[1 - serving_side]
	var chaser := _receiver_for(recv, target)
	rally.chaser_side = 1 - serving_side
	rally.chaser_slot = int(chaser.slot)
	var start_h := 2.75
	var dur := 1.32
	var arc := 1.9
	if idx == 2:
		start_h = 2.95
		dur = 1.05
		arc = 2.5
	elif idx == 1:
		start_h = 1.35
		dur = 1.55
		arc = 3.1
	dur += clampf((target - server.global_position).length() * 0.012, 0.0, 0.22)
	var start := server.global_position + Vector3(0, start_h, 0)
	ball.launch(start, Vector3(target.x, 1.12, target.z), dur, arc, "serve", server, serving_side, true)
	phase = "serve_flight"
	server.play_action("serve", 0.55)
	if idx == 2:
		server.jump(0.45, 0.82)
	var pressure := maxf(0.0, float(rally.serve_quality) - 0.55) * 0.38
	_set_receive_target(1 - serving_side, int(chaser.slot), pressure, 1 - serving_side == player_side and not autoplay)
	_player_stat(player, "serves", 1)
	_team_stat(srv, "serves", 1)
	if chaser.rig != null and (1 - serving_side == player_side or autoplay):
		_set_active(1 - serving_side, int(chaser.slot))
	if serving_side == player_side and not autoplay:
		hud.commentary("Serve away. Move into position!", UI.MUTED, 1.6)
	Sfx.play("serve", -7.0, 1.0 if idx != 2 else 0.82)
	serve_charge = 0.0
	serving_hold = false
	hud.clear_power()
	hud.hide_reticle()
	court.hide_target_cell()
	court.set_zone_grid_visible(false)

func _pressure_banner() -> void:
	var h: Dictionary = teams[HOME]
	var a: Dictionary = teams[AWAY]
	var target := _target_score()
	for side in [HOME, AWAY]:
		var t: Dictionary = teams[side]
		var o: Dictionary = teams[1 - side]
		if t.score + 1 >= target and t.score + 1 - o.score >= 2:
			if t.sets + 1 >= _sets_to_win():
				hud.show_banner("MATCH POINT", str(t.data["short"]), UI.GOLD, 1.2)
				hud.commentary(GameData.random_commentary("match_point", "", str(t.data["short"])), UI.GOLD, 2.5)
			else:
				hud.show_banner("SET POINT", str(t.data["short"]), UI.ORANGE, 1.0)
				hud.commentary(GameData.random_commentary("set_point", "", str(t.data["short"])), UI.ORANGE, 2.2)
			return

func _set_is_over() -> bool:
	var target := _target_score()
	for side in [HOME, AWAY]:
		if teams[side].score >= target and teams[side].score - teams[1 - side].score >= 2:
			return true
	return false

func _set_winner() -> int:
	return HOME if teams[HOME].score > teams[AWAY].score else AWAY

func _match_is_over() -> bool:
	return int(teams[HOME].sets) >= _sets_to_win() or int(teams[AWAY].sets) >= _sets_to_win()

# ---------------------------------------------------------------------------
# Phase clock and scoring transitions
# ---------------------------------------------------------------------------

func _update_phase_timers(delta: float) -> void:
	phase_timer -= delta
	match phase:
		"intro":
			if phase_timer <= 0.0:
				_start_set()
		"set_intro":
			if phase_timer <= 0.0:
				_begin_serve()
		"serve":
			if serving_side != player_side or autoplay:
				ai_serve_delay -= delta
				if ai_serve_delay <= 0.0:
					_ai_serve()
		"point":
			if phase_timer <= 0.0:
				if _set_is_over():
					_end_set()
				else:
					_after_point()
		"set_end":
			if phase_timer <= 0.0:
				_next_set()
		"match_end":
			if phase_timer <= 0.0 and not _result_sent:
				_finish_match()

func _ai_serve() -> void:
	if phase != "serve":
		return
	var srv: Dictionary = teams[serving_side]
	var player: Dictionary = srv.slots[0]
	var target := _ai_serve_target(srv)
	var q := 0.66 + _rng.randf() * 0.2 + float(player["stats"]["serve"]) * 0.0008
	q = clampf(q + (_rng.randf_range(-0.07, 0.07) if difficulty <= 2 else 0.0), 0.35, 0.95)
	aim_point = target
	_serve_release(q, target)

func _ai_serve_target(team: Dictionary) -> Vector3:
	var side: int = int(team["side"])
	var opp: Dictionary = teams[1 - side]
	var spots: Array = [
		Vector3(-3.8, 0, _signf(1 - side) * 7.8),
		Vector3(0, 0, _signf(1 - side) * 8.2),
		Vector3(3.8, 0, _signf(1 - side) * 7.8),
		Vector3(-3.4, 0, _signf(1 - side) * 4.4),
		Vector3(3.4, 0, _signf(1 - side) * 4.4),
		Vector3(0, 0, _signf(1 - side) * 5.2)
	]
	var best: Vector3 = spots[0]
	var best_score := -999.0
	for sp in spots:
		var near := _nearest_to(opp, sp, [0, 3, 4, 5])
		var score: float = near.dist + _rng.randf_range(0.0, 2.2)
		if sp.z * _signf(1 - side) > 7.0:
			score += 1.0
		if score > best_score:
			best_score = score
			best = sp
	var spread := 0.8 + (3 - difficulty) * 0.35
	best.x += _rng.randf_range(-spread, spread)
	best.z += _rng.randf_range(-spread * 0.5, spread * 0.5)
	return best

func _after_point() -> void:
	var winner := int(rally.get("point_winner", serving_side))
	if winner != serving_side:
		_rotate(teams[winner])
	serving_side = winner
	for team in teams:
		if int(team.ability_timer) > 0:
			team.ability_timer = int(team.ability_timer) - 1
			if int(team.ability_timer) <= 0:
				team.ability_kind = ""
	if not autoplay:
		_maybe_ai_substitute(1 - player_side)
	_begin_serve()

func _end_set() -> void:
	var winner := _set_winner()
	teams[winner].sets = int(teams[winner].sets) + 1
	set_scores.append([int(teams[HOME].score), int(teams[AWAY].score)])
	hud.update_score(teams[HOME].sets, teams[AWAY].sets, teams[HOME].score, teams[AWAY].score, serving_side, set_number, _sets_to_win())
	var t: Dictionary = teams[winner]
	if _match_is_over():
		phase = "match_end"
		phase_timer = 1.8 if autoplay else 3.0
		hud.show_banner("MATCH WON", str(t.data["short"]), UI.GOLD, 1.6)
		hud.commentary("%s takes the match!" % str(t.data["name"]), UI.GOLD, 3.2)
		Sfx.play("point", -5.0, 0.9)
		for rig in t.rigs:
			rig.celebrate()
	else:
		phase = "set_end"
		phase_timer = 1.4 if autoplay else 2.6
		hud.show_banner("SET %d" % set_number, "%s  %d — %d" % [str(t.data["short"]), int(teams[HOME].score), int(teams[AWAY].score)], UI.ORANGE, 1.4)
		hud.commentary("Set %d goes to %s. %d — %d." % [set_number, str(t.data["short"]), int(teams[HOME].score), int(teams[AWAY].score)], UI.ORANGE, 3.0)
		Sfx.play("point", -6.0, 1.0)
		for rig in t.rigs:
			rig.celebrate()

func _next_set() -> void:
	set_number = int(set_number) + 1
	for team in teams:
		team.score = 0
		team.flow = clampf(float(team.flow) * 0.35, 0.0, 100.0)
		team.ability_ready = false
		team.ability_kind = ""
		team.ability_timer = 0
		team.timeouts = 2
		team.subs = 6
		for rig in team.rigs:
			rig.reset_for_serve()
			rig.stamina = minf(rig.stamina_max, rig.stamina + 22.0)
	_start_set()

func _finish_match() -> void:
	if _result_sent:
		return
	_result_sent = true
	var result := _build_result()
	print("[match] result ", result.get("home_id"), " ", result.get("home_sets"), "-", result.get("away_sets"), " ", result.get("away_id"))
	match_finished.emit(result)

func _build_result() -> Dictionary:
	var h: Dictionary = teams[HOME]
	var a: Dictionary = teams[AWAY]
	var home_won := int(h.sets) > int(a.sets)
	return {
		"home_id": home_team_id,
		"away_id": away_team_id,
		"home_won": home_won,
		"home_sets": int(h.sets),
		"away_sets": int(a.sets),
		"sets": set_scores.duplicate(true),
		"home_stats": h.stats.duplicate(true),
		"away_stats": a.stats.duplicate(true),
		"mvp": _pick_mvp(home_won),
		"top_players": _top_players(5),
		"forfeit": false
	}

func _player_impact(p: Dictionary) -> float:
	return float(p.get("points", 0)) * 1.0 + float(p.get("blocks", 0)) * 1.25 + float(p.get("digs", 0)) * 0.55 \
		+ float(p.get("aces", 0)) * 1.55 + float(p.get("kills", 0)) * 0.35 + float(p.get("receptions", 0)) * 0.12 \
		- float(p.get("errors", 0)) * 0.22

func _pick_mvp(home_won: bool) -> Dictionary:
	var winning: Dictionary = teams[HOME] if home_won else teams[AWAY]
	var best: Dictionary = {}
	var best_score := -999.0
	for p in winning.lineup:
		var sc := _player_impact(p)
		if sc > best_score:
			best_score = sc
			best = p
	if best.is_empty():
		for team in teams:
			for p in team.lineup:
				var sc2 := _player_impact(p)
				if sc2 > best_score:
					best_score = sc2
					best = p
	var tid := str(best.get("team_id", home_team_id))
	return {
		"name": str(best.get("name", "—")),
		"team": str(GameData.team(tid)["short"]),
		"number": int(best.get("number", 0)),
		"line": _player_line(best)
	}

func _top_players(count: int) -> Array:
	var arr: Array = []
	for team in teams:
		for p in team.lineup:
			arr.append({
				"name": str(p.get("name", "")),
				"team_id": str(p.get("team_id", home_team_id)),
				"line": _player_line(p),
				"score": _player_impact(p)
			})
	arr.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	return arr.slice(0, mini(count, arr.size()))

func _player_line(p: Dictionary) -> String:
	if str(p.get("role", "")) == "S":
		return "%d AST  •  %d DIG  •  %d PTS" % [int(p.get("sets", 0)), int(p.get("digs", 0)), int(p.get("points", 0))]
	return "%d PTS  •  %d BLK  •  %d DIG" % [int(p.get("points", 0)), int(p.get("blocks", 0)), int(p.get("digs", 0))]

func _forfeit_match() -> void:
	if _result_sent:
		return
	if pause_overlay and pause_overlay.visible:
		pause_overlay.close_overlay()
	overlay_open = false
	paused = false
	var opponent := 1 - player_side
	teams[opponent].sets = _sets_to_win()
	if teams[HOME].sets == teams[AWAY].sets:
		teams[player_side].sets = maxi(0, _sets_to_win() - 1)
	phase = "match_end"
	_result_sent = true
	var result := _build_result()
	result["forfeit"] = true
	match_finished.emit(result)

# ---------------------------------------------------------------------------
# FLOW / signature abilities
# ---------------------------------------------------------------------------

func _add_flow(side: int, amount: float) -> void:
	var team: Dictionary = teams[side]
	if int(team.ability_timer) > 0:
		return
	team.flow = clampf(float(team.flow) + amount, 0.0, 100.0)
	if float(team.flow) >= 100.0 and not bool(team.ability_ready):
		team.ability_ready = true
		var col := Color.html(str(team.data["primary"]))
		hud.show_banner("FLOW MAX", str(team.data["short"]), col, 1.2)
		hud.commentary("%s is in the zone! Signature ability ready." % str(team.data["short"]), UI.GOLD, 2.6)
		Sfx.play("point", -7.0, 1.25)

func _maybe_ai_ability(side: int) -> void:
	if side == player_side and not autoplay:
		return
	var team: Dictionary = teams[side]
	if bool(team.ability_ready) and _rng.randf() < 0.7:
		_activate_ability(side)

func _activate_ability(side: int) -> void:
	var team: Dictionary = teams[side]
	if not bool(team.ability_ready):
		return
	team.ability_ready = false
	team.flow = 0.0
	team.ability_kind = str(team.data["ability_id"])
	team.ability_timer = 3
	var col := Color.html(str(team.data["primary"]))
	hud.show_banner(str(team.data["ability_name"]), str(team.data["short"]), col, 1.3)
	hud.commentary(str(team.data["ability_desc"]), UI.GOLD, 3.0)
	Sfx.play("point", -7.0, 1.12)
	if side == player_side:
		hud.flash(Color(col.r, col.g, col.b, 0.16))

func _flow_bonus(side: int, kind: String) -> float:
	var team: Dictionary = teams[side]
	if int(team.ability_timer) <= 0:
		return 0.0
	var k := str(team.ability_kind)
	match k:
		"freak_quick":
			if kind == "quick": return 0.18
		"floor_fortress":
			if kind == "receive" or kind == "dig": return 0.18
		"service_ace":
			if kind == "serve": return 0.18
		"left_cannon":
			if kind == "attack": return 0.16
		"mood_swing":
			if kind == "attack": return 0.16
		"iron_wall":
			if kind == "block": return 0.18
		"twin_decoy":
			if kind == "attack": return 0.12
		"total_defense":
			if kind == "receive" or kind == "dig" or kind == "block": return 0.14
		"free_spirit":
			if kind == "attack": return 0.14
		"ace_will":
			if kind == "attack": return 0.12
	return 0.0

# ---------------------------------------------------------------------------
# Ball arrivals and rally contacts
# ---------------------------------------------------------------------------

func _on_ball_arrived(pos: Vector3, info: Dictionary) -> void:
	rally_hits += 1
	var kind := str(info.get("kind", "free"))
	match kind:
		"serve": _resolve_serve_arrival(pos)
		"pass": _resolve_pass_arrival(pos)
		"set": _resolve_set_arrival(pos)
		"attack": _resolve_attack_arrival(pos)
		"block": _award_point(int(rally.get("block_winner", -1)), "block", _player_in_slot(int(rally.get("block_winner", -1)), int(rally.get("blocker_slot", -1))))
		"free": _resolve_free_arrival(pos)
		"dead": _award_point(int(rally.get("dead_winner", -1)), str(rally.get("dead_reason", "error")), rally.get("dead_player", null))

func _inside_court(pos: Vector3, side: int, margin: float = 0.0) -> bool:
	var s := _signf(side)
	var z := pos.z * s
	return absf(pos.x) <= HALF_W - margin and z >= margin and z <= HALF_L - margin

func _player_in_slot(side: int, slot: int) -> Dictionary:
	if side < 0 or side > 1 or slot < 0 or slot > 5:
		return {}
	return teams[side].slots[slot]

func _resolve_serve_arrival(pos: Vector3) -> void:
	if phase != "serve_flight":
		return
	if int(rally.get("point_override", -1)) >= 0:
		_award_point(int(rally.point_override), str(rally.point_reason), rally.get("point_player", null))
		return
	court.hide_receive_marker()
	var recv_side: int = int(rally.defending)
	var team: Dictionary = teams[recv_side]
	var chaser_slot: int = int(rally.get("chaser_slot", -1))
	if chaser_slot < 0:
		chaser_slot = int(_receiver_for(team, pos).slot)
	var rig: PlayerRig = team.rigs[chaser_slot]
	var player: Dictionary = team.slots[chaser_slot]
	var dist := Vector2(rig.global_position.x - pos.x, rig.global_position.z - pos.z).length()
	var radius := float(rally.get("recv_radius", _receive_radius_for(player)))
	if recv_side == player_side and active_rig == rig and dive_clock > 0.0:
		radius += 0.62
	var pressed := bool(rally.get("receive_pressed", false))
	var human_recv: bool = recv_side == player_side and not autoplay and active_rig == rig
	if not human_recv:
		rally.receive_timing = _ai_receive_timing(player)
		pressed = true
	var quality := _contact_quality(team, player, dist, radius, float(rally.get("receive_timing", 0.0)), pressed)
	if quality < 0.0 and not human_recv:
		quality = _emergency_touch(player, dist, radius)
	if quality >= 0.0:
		rally.receive_quality = quality
		_player_stat(player, "receptions", 1)
		_team_stat(team, "receptions", 1)
		if quality < 0.38:
			hud.commentary("A shaky reception. The setter has to chase it.", UI.ORANGE, 2.0)
		elif quality > 0.88 and recv_side == player_side:
			hud.commentary("PERFECT RECEPTION. The setter has all the time in the world.", UI.GREEN, 2.0)
		_begin_pass(pos, recv_side, quality, "serve")
	else:
		var srv: Dictionary = teams[int(rally.attacking)]
		var server: Dictionary = srv.slots[0]
		hud.commentary(GameData.random_commentary("ace", str(server.get("name", "")), str(srv.data["short"])), UI.GOLD, 2.6)
		Sfx.play("error", -7.0, 0.9)
		_launch_dead(pos, int(rally.attacking), "ace", server)

func _begin_pass(from: Vector3, side: int, quality: float, _origin: String) -> void:
	var team: Dictionary = teams[side]
	var setter := _setter_slot(team)
	var nest := _setter_nest(team)
	var q := clampf(quality, 0.0, 1.0)
	# Reception quality now shapes the ball: clean passes hang in the air and
	# give the setter/hitter time; shanked passes are low and arrive fast.
	var off := pow(1.0 - q, 1.35) * 1.85
	var target := Vector3(
		nest.x + _rng.randf_range(-off, off),
		lerpf(1.25, 2.18, q),
		nest.z + _signf(side) * _rng.randf_range(0.0, off * 0.55)
	)
	rally.attacking = side
	rally.defending = 1 - side
	rally.setter_slot = setter
	rally.pass_quality = q
	rally.phase = "pass"
	var dist := (target - from).length()
	var arc := lerpf(0.50, 2.85, q)
	var dur := lerpf(0.46, 1.08, q) + dist * lerpf(0.018, 0.050, q)
	dur = clampf(dur, 0.48, 1.65)
	ball.launch(from, target, dur, arc, "pass", team.rigs[setter], side, true)
	phase = "pass_flight"
	team.rigs[setter].set_target(nest)
	if side == player_side:
		_set_active(side, setter)
	hud.set_phase("PASS", UI.CYAN)
	if side == player_side and not autoplay:
		if q > 0.8:
			hud.set_prompt("CLEAN PASS — THE SETTER HAS TIME", "TAB TACTICS  •  1-5 PLAY CALL")
		else:
			hud.set_prompt("SCRAMBLE PASS — THE SETTER IS ON THE MOVE", "MOVE THE SETTER UNDER THE BALL")
	else:
		hud.set_prompt("PASS TO THE SETTER", "THE ATTACK IS FORMING")

func _resolve_pass_arrival(pos: Vector3) -> void:
	if phase != "pass_flight":
		return
	var side: int = int(rally.attacking)
	var team: Dictionary = teams[side]
	var setter := _setter_slot(team)
	var setter_rig: PlayerRig = team.rigs[setter]
	var setter_player: Dictionary = team.slots[setter]
	var dist := Vector2(setter_rig.global_position.x - pos.x, setter_rig.global_position.z - pos.z).length()
	var quality := clampf(
		float(rally.pass_quality) * 0.62 + float(setter_player["stats"]["set"]) / 100.0 * 0.38
		- maxf(0.0, dist - 0.7) * 0.13 + _flow_bonus(side, "set") * 0.3,
		0.1, 1.0
	)
	rally.set_quality = quality
	var play_index: int
	if side == player_side and not autoplay:
		play_index = int(team.play_index)
	else:
		play_index = _ai_choose_play(team, quality)
	team.play_index = play_index
	var key: String = PLAY_KEYS[play_index]
	var info := _choose_set_target(team, key, setter, quality)
	rally.hitter_slot = int(info.slot)
	rally.set_target = info.target
	rally.attack_hint_x = float(info.target.x)
	rally.attack_type = "tip" if key == "dump" else "spike"
	rally.jump_pressed = false
	rally.jump_quality = 0.0
	rally.timing_value = 0.0
	var hitter: PlayerRig = team.rigs[int(info.slot)]
	hitter.set_target(Vector3(info.target.x, 0.0, info.target.z))
	if side == player_side or autoplay:
		_set_active(side, int(info.slot))
	ball.launch(pos, info.target, float(info.duration), float(info.arc), "set", setter_rig, side, true)
	phase = "set_flight"
	setter_rig.play_action("set", 0.45)
	_player_stat(setter_player, "sets", 1)
	_team_stat(team, "sets", 1)
	Sfx.play("set", -9.0, 1.08)
	hud.set_phase("ATTACK", UI.ORANGE)
	if side == player_side and not autoplay:
		hud.set_prompt("SPACE TO JUMP — TIME IT AT THE TOP", "AIM WITH MOUSE  •  E = TIP  •  1-5 PLAY CALL")
	else:
		hud.set_prompt("%s IS ATTACKING" % str(team.data["short"]), "WATCH THE HITTER  •  1-4 DEFENSE")
	if side != player_side and not autoplay:
		hud.commentary("%s runs %s." % [str(team.data["short"]), PLAY_NAMES[play_index]], UI.MUTED, 1.6)

func _choose_set_target(team: Dictionary, key: String, setter_slot: int, quality: float) -> Dictionary:
	var side: int = int(team["side"])
	var sign := _signf(side)
	var slot := _best_attacker(team, true, false)
	var x := 0.0
	var z := sign * 1.45
	var height := 3.02
	var dur := 0.55
	var arc := 0.65
	match key:
		"quick":
			slot = _best_attacker(team, true, false)
			x = clampf(team.rigs[setter_slot].global_position.x, -1.2, 1.2)
			z = sign * 1.45
			height = 3.0
			dur = 0.40
			arc = 0.48
			if str(team.ability_kind) == "freak_quick" and int(team.ability_timer) > 0:
				dur *= 0.78
				arc *= 0.8
		"back_quick":
			slot = _best_attacker(team, false, true)
			x = 0.0
			z = sign * 3.3
			height = 2.9
			dur = 0.54
			arc = 0.68
		"wing":
			var choice := _choose_wing(team)
			slot = int(choice.slot)
			x = float(choice.x)
			z = sign * (2.2 if FRONT.has(slot) else 3.5)
			height = 3.05
			dur = 0.72
			arc = 0.78
		"pipe":
			slot = _best_attacker(team, false, true)
			x = 0.0
			z = sign * 4.25
			height = 3.0
			dur = 0.78
			arc = 0.85
		"dump":
			slot = setter_slot
			x = 0.0
			z = sign * 1.1
			height = 2.4
			dur = 0.36
			arc = 0.28
		_:
			slot = _best_attacker(team, true, false)
			x = 3.5 * sign
			z = sign * 2.2
			height = 3.0
			dur = 0.7
			arc = 0.75
	var q := clampf(quality, 0.0, 1.0)
	# A clean pass lets the setter put more air under the ball and gives the
	# hitter time to read the block. A poor pass forces a rushed, flat set.
	dur *= lerpf(0.80, 1.08, q)
	arc *= lerpf(0.70, 1.14, q)
	return {"slot": slot, "target": Vector3(x, height, z), "duration": dur, "arc": arc}

func _choose_wing(team: Dictionary) -> Dictionary:
	var sign := _signf(int(team["side"]))
	var left_best := -100.0
	var left_slot := 3
	var right_best := -100.0
	var right_slot := 1
	var setter := _setter_slot(team)
	for s in [3, 4]:
		if s == setter:
			continue
		var p: Dictionary = team.slots[s]
		if str(p.get("role", "")) == "L":
			continue
		var v := float(p["stats"]["attack"]) + float(p["stats"]["jump"]) * 0.12
		if v > left_best:
			left_best = v
			left_slot = s
	for s in [1, 0]:
		if s == setter:
			continue
		var p2: Dictionary = team.slots[s]
		if str(p2.get("role", "")) == "L":
			continue
		var v2 := float(p2["stats"]["attack"]) + float(p2["stats"]["jump"]) * 0.12
		if v2 > right_best:
			right_best = v2
			right_slot = s
	if right_best > left_best:
		return {"slot": right_slot, "x": 3.5 * sign}
	return {"slot": left_slot, "x": -3.5 * sign}

func _ai_choose_play(team: Dictionary, quality: float) -> int:
	var pb: Dictionary = team.data["playbook"]
	var allowed: Array = pb.get("attack", ["wing"])
	var weights := {
		"quick": 0.34 if quality > 0.58 else 0.12,
		"back_quick": 0.16,
		"wing": 0.36,
		"pipe": 0.14,
		"dump": 0.03
	}
	if str(team.ability_kind) == "freak_quick" and int(team.ability_timer) > 0:
		weights["quick"] = 0.58
	var total := 0.0
	var pool: Array = []
	for key in allowed:
		if not weights.has(key):
			continue
		var w: float = float(weights[key])
		if difficulty <= 1:
			w = 1.0
		total += w
		pool.append({"key": key, "w": w})
	if pool.is_empty() or total <= 0.0:
		return 2
	var roll := _rng.randf() * total
	var acc := 0.0
	for item in pool:
		acc += float(item.w)
		if roll <= acc:
			return maxi(0, PLAY_KEYS.find(str(item.key)))
	return maxi(0, PLAY_KEYS.find(str(pool[pool.size() - 1].key)))

# ---------------------------------------------------------------------------
# Attack, block, defense, and scoring
# ---------------------------------------------------------------------------

func _resolve_set_arrival(pos: Vector3) -> void:
	if phase != "set_flight":
		return
	var side: int = int(rally.attacking)
	var team: Dictionary = teams[side]
	var slot: int = int(rally.hitter_slot)
	if slot < 0:
		slot = _best_attacker(team, true, false)
	var rig: PlayerRig = team.rigs[slot]
	var player: Dictionary = team.slots[slot]
	var jq := 0.55
	if bool(rally.get("jump_pressed", false)):
		jq = float(rally.get("jump_quality", 0.6))
	elif side != player_side or autoplay:
		jq = 0.72 + float(difficulty) * 0.018
	var atk := float(player["stats"]["attack"]) / 100.0
	var quality := clampf(
		float(rally.set_quality) * 0.42 + atk * 0.38 + jq * 0.25
		+ _flow_bonus(side, "attack") + _play_attack_bonus(team),
		0.1, 1.0
	)
	if not rig.is_jumping:
		rig.jump(0.62, 0.90)
	rig.play_action("spike", 0.62)
	var tip := str(rally.attack_type) == "tip"
	var target: Vector3
	if side == player_side and not autoplay and aim_valid:
		target = aim_point
	else:
		target = _ai_attack_target(team, quality, tip)
	target.y = 0.12
	var dur := 0.48
	var arc := 0.3
	if tip:
		quality *= 0.82
		dur = 0.8
		arc = 0.72
	else:
		var dist := (pos - target).length()
		dur = clampf(0.40 + dist * 0.010, 0.40, 0.60)
		arc = 0.34
	rally.attack_quality = quality
	rally.attack_target = target
	rally.net_checked = false
	rally.block_winner = -1
	rally.blocker_slot = -1
	ball.launch(pos, target, dur, arc, "attack", rig, side, false)
	phase = "attack_flight"
	_player_stat(player, "attacks", 1)
	_team_stat(team, "attacks", 1)
	Sfx.play("hit", -6.0, 1.0 if not tip else 1.3)
	hud.clear_power()
	hud.hide_reticle()
	court.hide_target_cell()
	court.set_zone_grid_visible(false)
	_trigger_block_jump(1 - side, target.x)
	var def_team: Dictionary = teams[1 - side]
	var chaser := _receiver_for(def_team, target)
	rally.chaser_side = 1 - side
	rally.chaser_slot = int(chaser.slot)
	rally.def_react = clampf(0.30 - float(def_team.slots[int(chaser.slot)]["stats"]["receive"]) * 0.0018 - float(difficulty) * 0.014, 0.10, 0.28)
	var pressure := 0.06 + maxf(0.0, quality - 0.35) * 0.42
	_set_receive_target(1 - side, int(chaser.slot), pressure, 1 - side == player_side and not autoplay)
	if 1 - side == player_side and not autoplay:
		_set_active(1 - side, int(chaser.slot))
		hud.set_phase("DEFENSE", UI.RED)
		hud.set_prompt("MOVE INTO THE CIRCLE", "SPACE TO RECEIVE  •  CTRL = DIVE  •  1-4 SCHEME")

func _play_attack_bonus(team: Dictionary) -> float:
	if str(team.ability_kind) == "freak_quick" and int(team.ability_timer) > 0:
		var idx := int(team.play_index)
		if idx >= 0 and idx < PLAY_KEYS.size() and PLAY_KEYS[idx] == "quick":
			return 0.1
	return 0.0

func _trigger_block_jump(side: int, x: float) -> void:
	var team: Dictionary = teams[side]
	var scheme := int(team.block_index)
	var limit := 2
	if scheme == 1:
		limit = 1
	elif scheme == 3:
		limit = 3
	var candidates := _front_near_net(team, x)
	var chosen := candidates.slice(0, mini(limit, candidates.size()))
	for i in range(chosen.size()):
		var s: int = chosen[i]
		var rig: PlayerRig = team.rigs[s]
		var p: Dictionary = team.slots[s]
		var h := 0.48 + float(p["stats"]["block"]) * 0.0014
		rig.jump(h, 0.90)
		rig.play_action("block", 0.84)
		var off := (float(i) - float(chosen.size() - 1) * 0.5) * 0.75
		rig.set_target(Vector3(clampf(x + off, -HALF_W, HALF_W), 0.0, _signf(side) * 0.55))

func _try_block() -> void:
	if phase != "attack_flight" or bool(rally.get("net_checked", false)):
		return
	var cross := ball.crossing(0.0)
	if cross.is_empty():
		return
	var pos: Vector3 = cross["pos"]
	rally.net_checked = true
	if absf(pos.x) > HALF_W + 0.25:
		return
	if pos.y < 1.0 or pos.y > NET_H + 0.75:
		return
	var def_side := 1 - int(rally.attacking)
	var team: Dictionary = teams[def_side]
	var candidates := _front_near_net(team, pos.x)
	if candidates.is_empty():
		return
	var scheme := int(team.block_index)
	var limit := 2
	var mult := 1.0
	match scheme:
		0: limit = 2; mult = 1.0
		1: limit = 1; mult = 1.1
		2: limit = 2; mult = 0.97
		3: limit = 3; mult = 1.06
	var chosen := candidates.slice(0, mini(limit, candidates.size()))
	var block_sum := 0.0
	for s in chosen:
		block_sum += float(team.slots[s]["stats"]["block"])
	var block_score := (block_sum / maxf(1.0, float(chosen.size()))) / 100.0 * mult
	block_score *= 1.0 + float(chosen.size() - 1) * 0.045
	block_score += _flow_bonus(def_side, "block")
	if str(team.ability_kind) == "twin_decoy" and int(team.ability_timer) > 0:
		block_score -= 0.1
	var attack_score := float(rally.attack_quality)
	var chance := clampf(0.08 + (block_score - attack_score) * 0.62 + float(chosen.size()) * 0.04 + float(rally.get("player_block_bonus", 0.0)), 0.01, 0.62)
	if str(rally.attack_type) == "tip":
		chance *= 0.28
	if _rng.randf() < chance:
		var best_slot: int = chosen[0]
		var blocker: PlayerRig = team.rigs[best_slot]
		rally.block_winner = def_side
		rally.blocker_slot = best_slot
		var target := Vector3(
			clampf(pos.x + _rng.randf_range(-1.2, 1.2), -HALF_W + 0.3, HALF_W - 0.3),
			0.12,
			_signf(int(rally.attacking)) * _rng.randf_range(3.2, 7.6)
		)
		ball.launch(pos, target, 0.42, 0.12, "block", blocker, def_side, false)
		phase = "block_flight"
		court.hide_receive_marker()
		blocker.play_action("block", 0.5)
		Sfx.play("block", -5.0, 0.95)
		hud.flash(Color(1, 0.85, 0.35, 0.18))
		hud.set_phase("BLOCK", UI.GOLD)
		hud.set_prompt("ROOFED!", "THE WALL HOLDS")

func _resolve_attack_arrival(pos: Vector3) -> void:
	if phase != "attack_flight":
		return
	court.hide_receive_marker()
	var attacking := int(rally.attacking)
	var defender := 1 - attacking
	var atk_team: Dictionary = teams[attacking]
	var hitter_slot: int = int(rally.get("hitter_slot", -1))
	var hitter: Dictionary = _player_in_slot(attacking, hitter_slot)
	if not _inside_court(pos, defender, 0.02):
		var why := "out"
		if absf(pos.z) < 0.2:
			why = "net"
		hud.commentary(GameData.random_commentary("error", "", str(teams[defender].data["short"])), UI.RED, 2.4)
		_award_point(defender, why, hitter)
		return
	var def_team: Dictionary = teams[defender]
	var chaser_slot: int = int(rally.get("chaser_slot", -1))
	if chaser_slot < 0:
		chaser_slot = int(_receiver_for(def_team, pos).slot)
	var rig: PlayerRig = def_team.rigs[chaser_slot]
	var player: Dictionary = def_team.slots[chaser_slot]
	var dist := Vector2(rig.global_position.x - pos.x, rig.global_position.z - pos.z).length()
	var radius := float(rally.get("recv_radius", _receive_radius_for(player)))
	if defender == player_side and active_rig == rig and dive_clock > 0.0:
		radius += 0.62
	var pressed := bool(rally.get("receive_pressed", false))
	var human_recv: bool = defender == player_side and not autoplay and active_rig == rig
	if not human_recv:
		rally.receive_timing = _ai_receive_timing(player)
		pressed = true
	var quality := _contact_quality(def_team, player, dist, radius, float(rally.get("receive_timing", 0.0)), pressed)
	if quality < 0.0 and not human_recv:
		quality = _emergency_touch(player, dist, radius)
	if quality >= 0.0:
		rally.receive_quality = quality
		_player_stat(player, "digs", 1)
		_team_stat(def_team, "digs", 1)
		if quality < 0.35:
			hud.commentary("%s scrambles it up. The set is in trouble." % str(player.get("name", "")), UI.ORANGE, 2.2)
		else:
			hud.commentary(GameData.random_commentary("dig", str(player.get("name", "")), str(def_team.data["short"])), UI.CYAN, 2.2)
		Sfx.play("receive", -7.0, 1.0)
		_begin_pass(pos, defender, quality, "dig")
	else:
		hud.commentary(GameData.random_commentary("kill", str(hitter.get("name", "")), str(atk_team.data["short"])), UI.GOLD, 2.4)
		Sfx.play("hit", -6.0, 0.95)
		_award_point(attacking, "kill", hitter)

func _resolve_free_arrival(pos: Vector3) -> void:
	if phase != "free_flight":
		return
	var recv_side: int = int(rally.defending)
	var team: Dictionary = teams[recv_side]
	var chaser := _receiver_for(team, pos)
	var rig: PlayerRig = chaser.rig
	var player: Dictionary = team.slots[int(chaser.slot)]
	var dist := Vector2(rig.global_position.x - pos.x, rig.global_position.z - pos.z).length()
	var reach := 1.45 + float(player["stats"]["speed"]) * 0.005 + float(player["stats"]["receive"]) * 0.002
	if dist <= reach:
		var quality := clampf(0.85 - dist * 0.2 + float(player["stats"]["receive"]) * 0.002, 0.2, 0.95)
		_begin_pass(pos, recv_side, quality, "free")
	else:
		_award_point(int(rally.attacking), "free", null)

func _launch_dead(from: Vector3, winner: int, reason: String, player) -> void:
	if winner < 0 or winner > 1:
		return
	court.hide_receive_marker()
	rally.dead_winner = winner
	rally.dead_reason = reason
	rally.dead_player = player
	phase = "dead"
	var target := Vector3(from.x, 0.11, from.z)
	if absf(from.z) > HALF_L + 0.4 or absf(from.x) > HALF_W + 0.4:
		target = from
		target.y = 0.11
	ball.launch(from, target, 0.2, 0.04, "dead", null, -1, false)

func _award_point(winner: int, reason: String, player) -> void:
	if winner < 0 or winner > 1:
		return
	if phase == "point" or phase == "set_end" or phase == "match_end":
		return
	court.hide_receive_marker()
	var loser := 1 - winner
	var wteam: Dictionary = teams[winner]
	var lteam: Dictionary = teams[loser]
	wteam.score = int(wteam.score) + 1
	if player == null:
		player = {}
	match reason:
		"kill":
			_team_stat(wteam, "kills", 1)
			_player_stat(player, "kills", 1)
			_player_stat(player, "points", 1)
		"ace":
			_team_stat(wteam, "aces", 1)
			_player_stat(player, "aces", 1)
			_player_stat(player, "points", 1)
		"block":
			_team_stat(wteam, "blocks", 1)
			_player_stat(player, "blocks", 1)
			_player_stat(player, "points", 1)
		"out", "net", "error":
			_team_stat(lteam, "errors", 1)
			_player_stat(player, "errors", 1)
		"free":
			_team_stat(wteam, "kills", 1)
			_player_stat(player, "kills", 1)
			_player_stat(player, "points", 1)
	if autoplay:
		print("[rally] ", int(teams[HOME].score), "-", int(teams[AWAY].score), "  ", reason)
	_add_flow(winner, 13.0)
	_add_flow(loser, -5.0)
	var col := Color.html(str(wteam.data["primary"]))
	var pname := str(player.get("name", "")) if player != null else ""
	var reason_text := reason.to_upper()
	if reason == "kill":
		reason_text = "KILL  •  " + pname
	elif reason == "ace":
		reason_text = "ACE  •  " + pname
	elif reason == "block":
		reason_text = "BLOCK  •  " + pname
	elif reason == "out" or reason == "net":
		reason_text = "OUT"
	elif reason == "error":
		reason_text = "SERVE ERROR"
	hud.update_score(teams[HOME].sets, teams[AWAY].sets, teams[HOME].score, teams[AWAY].score, serving_side, set_number, _sets_to_win())
	hud.show_banner("POINT", "%s  •  %s" % [str(wteam.data["short"]), reason_text], col, 1.0)
	hud.flash(Color(col.r, col.g, col.b, 0.15))
	hud.set_phase("POINT", col)
	hud.set_prompt("%s TAKES THE RALLY" % str(wteam.data["short"]), "NEXT SERVE COMING UP")
	var ckind := "point"
	if reason == "kill": ckind = "kill"
	elif reason == "ace": ckind = "ace"
	elif reason == "block": ckind = "block"
	elif reason == "out" or reason == "net" or reason == "error": ckind = "error"
	hud.commentary(GameData.random_commentary(ckind, pname, str(wteam.data["short"])), col if ckind != "error" else UI.RED, 2.6)
	Sfx.play("point" if ckind != "error" else "error", -7.0, 1.0)
	rally.point_winner = winner
	phase = "point"
	phase_timer = 1.0 if autoplay else 1.65

func _ai_attack_target(team: Dictionary, quality: float, tip: bool) -> Vector3:
	var side: int = int(team["side"])
	var defender := 1 - side
	var def_team: Dictionary = teams[defender]
	var sgn := _signf(defender)
	var spots: Array = []
	if tip:
		spots = [
			Vector3(-3.7, 0, sgn * 2.5), Vector3(0, 0, sgn * 2.2), Vector3(3.7, 0, sgn * 2.5),
			Vector3(-2.4, 0, sgn * 3.2), Vector3(2.4, 0, sgn * 3.2)
		]
	else:
		# Deep corners, the deep middle seam, and the short corners. Anything
		# closer to the middle is food for the libero.
		spots = [
			Vector3(-4.05, 0, sgn * 8.55), Vector3(4.05, 0, sgn * 8.55), Vector3(0, 0, sgn * 8.60),
			Vector3(-3.95, 0, sgn * 5.40), Vector3(3.95, 0, sgn * 5.40),
			Vector3(-1.9, 0, sgn * 7.30), Vector3(1.9, 0, sgn * 7.30)
		]
	var best: Vector3 = spots[0]
	var best_score := -999.0
	for sp in spots:
		var near := _nearest_to(def_team, sp, [0, 4, 5])
		var score: float = near.dist
		if str(def_team.slots[int(near.slot)]["role"]) == "L":
			score += 0.8
		if absf(sp.x) > 3.0:
			score += 0.5
		score += _rng.randf_range(-1.4, 1.4) * (1.2 - quality)
		if score > best_score:
			best_score = score
			best = sp
	var spread := 0.55 + (1.0 - quality) * 1.8
	if difficulty >= 3:
		spread *= 0.65
	best.x += _rng.randf_range(-spread, spread)
	best.z += _rng.randf_range(-spread * 0.6, spread * 0.6)
	best.x = clampf(best.x, -HALF_W + 0.3, HALF_W - 0.3)
	best.z = sgn * clampf(absf(best.z), 0.9, HALF_L - 0.3)
	best.y = 0.12
	return best

# ---------------------------------------------------------------------------
# Game loop and human input
# ---------------------------------------------------------------------------

var _hud_accum := 0.0
var _pause_note := ""
var _pause_title := "PAUSED"
var rally_hits := 0

func _process(delta: float) -> void:
	if overlay_open:
		_update_camera(delta)
		return
	if paused:
		return
	if _result_sent and phase == "match_end":
		_update_rigs(delta)
		return
	_update_input(delta)
	_update_phase_timers(delta)
	_update_ai(delta)
	_update_rigs(delta)
	_update_ball(delta)
	_update_camera(delta)
	_update_hud(delta)

func _update_input(delta: float) -> void:
	if swap_cooldown > 0.0:
		swap_cooldown = maxf(0.0, swap_cooldown - delta)
	if dive_clock > 0.0:
		dive_clock = maxf(0.0, dive_clock - delta)
	mouse_pos = get_viewport().get_mouse_position()
	if Input.is_action_just_pressed("pause") and not get_viewport().is_input_handled():
		_open_pause()
		return
	if Input.is_action_just_pressed("tactics") and not get_viewport().is_input_handled():
		_open_tactics()
		return
	if Input.is_action_just_pressed("camera"):
		camera_mode = (int(camera_mode) + 1) % 4
		GameData.options["camera"] = camera_mode
		GameData.save_settings()
		hud.set_camera(GameData.CAMERA_NAMES[camera_mode])
		Sfx.play("ui", -12.0, 1.0)
	_update_aim()
	_update_number_keys()
	var frozen: bool = phase in ["point", "set_end", "match_end", "intro", "set_intro", "dead"]
	if frozen:
		if active_rig:
			active_rig.set_move_input(Vector2.ZERO)
		return
	var human := active_side == player_side and not autoplay and active_rig != null
	if human and active_rig:
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if phase != "serve":
			var fwd := -camera.global_transform.basis.z
			fwd.y = 0.0
			if fwd.length() < 0.01:
				fwd = Vector3(0, 0, 1)
			fwd = fwd.normalized()
			var right := camera.global_transform.basis.x
			right.y = 0.0
			if right.length() < 0.01:
				right = Vector3(1, 0, 0)
			right = right.normalized()
			var world := right * v.x + fwd * (-v.y)
			active_rig.set_move_input(Vector2(world.x, world.z))
		else:
			active_rig.set_move_input(Vector2.ZERO)
	elif active_rig:
		active_rig.set_move_input(Vector2.ZERO)

	if Input.is_action_just_pressed("switch_player") and swap_cooldown <= 0.0 and phase != "serve" and not autoplay:
		_switch_player()
	if Input.is_action_just_pressed("special") and not autoplay:
		if phase == "set_flight" and int(rally.get("attacking", -1)) == player_side:
			if str(rally.get("attack_type", "spike")) == "tip":
				rally.attack_type = "spike"
				hud.set_prompt("FULL SWING", "PRESS SPACE TO JUMP  •  E TO TIP")
			else:
				rally.attack_type = "tip"
				hud.set_prompt("TIP SELECTED — AIM SHORT", "PRESS SPACE TO JUMP  •  E FOR FULL SWING")
			Sfx.play("ui", -12.0, 1.15)
		elif human and bool(teams[player_side].ability_ready):
			_activate_ability(player_side)
	if Input.is_action_just_pressed("dive") and human and active_rig:
		var dd := Vector3.ZERO
		if active_rig.move_input.length() > 0.1:
			dd = Vector3(active_rig.move_input.x, 0.0, active_rig.move_input.y)
		elif ball.active:
			dd = ball.global_position - active_rig.global_position
			dd.y = 0.0
		if dd.length() < 0.01:
			dd = Vector3(0, 0, _signf(player_side))
		active_rig.start_dive(dd)
		dive_clock = 0.78
		Sfx.play("receive", -11.0, 0.85)
	if phase == "attack_flight" and int(rally.get("defending", -1)) == player_side and human:
		var chaser_slot := int(rally.get("chaser_slot", -1))
		if active_slot == chaser_slot:
			if Input.is_action_just_pressed("action") and not bool(rally.get("receive_pressed", false)):
				_register_receive_press()
		elif Input.is_action_just_pressed("action") and FRONT.has(active_slot) and not active_rig.is_jumping:
			rally.player_block_bonus = minf(0.18, float(rally.get("player_block_bonus", 0.0)) + 0.09)
			active_rig.jump(0.55, 0.88)
			active_rig.play_action("block", 0.78)
			Sfx.play("ui", -12.0, 0.9)
	if phase == "serve_flight" and int(rally.get("defending", -1)) == player_side and human:
		var chaser_slot2 := int(rally.get("chaser_slot", -1))
		if active_slot == chaser_slot2 and Input.is_action_just_pressed("action") and not bool(rally.get("receive_pressed", false)):
			_register_receive_press()
	if phase == "serve" and serving_side == player_side and not autoplay:
		if Input.is_action_just_pressed("action") and active_rig:
			serving_hold = true
			serve_charge = 0.0
			active_rig.play_action("serve_toss", 0.55)
		if serving_hold:
			serve_charge = minf(1.0, serve_charge + delta / 1.35)
			if Input.is_action_just_released("action") or serve_charge >= 1.0:
				var q := serve_charge
				serving_hold = false
				_serve_release(q)
		return
	if phase == "set_flight" and int(rally.get("attacking", -1)) == player_side and not autoplay:
		if Input.is_action_just_pressed("action") and not bool(rally.get("jump_pressed", false)):
			var u := 0.55
			if ball.active:
				u = clampf(ball.t / maxf(0.05, ball.duration), 0.0, 1.0)
			var q2 := clampf(1.0 - absf(u - 0.55) * 2.35, 0.12, 1.0)
			rally.jump_pressed = true
			rally.jump_quality = q2
			rally.timing_value = u
			if active_rig:
				active_rig.jump(0.62, 0.90)
				active_rig.play_action("spike", 0.62)
			Sfx.play("ui", -12.0, 1.0 + q2 * 0.25)

func _update_number_keys() -> void:
	if autoplay:
		return
	var team: Dictionary = teams[player_side]
	# 1–3 serve, 1–4 defense, 1–5 attack. Context decides which row the
	# number keys talk to, so the player never has to open the board mid-rally.
	var defending: bool = phase in ["serve_flight", "pass_flight", "set_flight", "attack_flight", "block_flight", "free_flight"] \
		and int(rally.get("attacking", -1)) != player_side
	for i in range(5):
		if not Input.is_action_just_pressed("num%d" % (i + 1)):
			continue
		if phase == "serve" and serving_side == player_side and i < 3:
			team.serve_index = i
			hud.commentary("SERVE: " + SERVE_NAMES[i], UI.CYAN, 1.2)
		elif defending and i < 4:
			team.block_index = i
			hud.commentary("DEFENSE: " + BLOCK_NAMES[i], UI.CYAN, 1.2)
		elif not defending:
			team.play_index = i
			hud.commentary("PLAY: " + PLAY_NAMES[i], UI.CYAN, 1.2)
		else:
			continue
		hud.set_tactics(PLAY_NAMES[int(team.play_index)], SERVE_NAMES[int(team.serve_index)], BLOCK_NAMES[int(team.block_index)], RECV_NAMES[int(team.recv_index)])
		Sfx.play("ui", -12.0, 1.06)
		return

func _update_aim() -> void:
	aim_active = false
	if autoplay:
		aim_valid = false
		return
	if phase == "serve" and serving_side == player_side:
		aim_active = true
	elif phase == "set_flight" and int(rally.get("attacking", -1)) == player_side:
		aim_active = true
	if not aim_active or camera == null:
		aim_valid = false
		return
	var origin := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	if absf(dir.y) < 0.0005:
		return
	var t := -origin.y / dir.y
	if t < 0.0:
		return
	var p := origin + dir * t
	p.y = 0.0
	aim_point = p
	aim_valid = _inside_court(p, 1 - player_side, 0.0)

func _switch_player() -> void:
	if phase == "serve":
		return
	var team: Dictionary = teams[player_side]
	var focus := ball.global_position if ball.active else Vector3(0, 0, 0)
	var arr: Array = []
	for s in range(6):
		var rig: PlayerRig = team.rigs[s]
		arr.append({"slot": s, "d": Vector2(rig.global_position.x - focus.x, rig.global_position.z - focus.z).length()})
	arr.sort_custom(func(a, b): return float(a["d"]) < float(b["d"]))
	var idx := 0
	for i in range(arr.size()):
		if int(arr[i].slot) == active_slot:
			idx = i
			break
	var pick: int = int(arr[(idx + 1) % arr.size()].slot)
	_set_active(player_side, pick)
	swap_cooldown = 0.22
	Sfx.play("ui", -13.0, 1.1)

func _register_receive_press() -> void:
	if not (phase in ["serve_flight", "attack_flight"]):
		return
	var slot := int(rally.get("chaser_slot", -1))
	if slot < 0 or slot != active_slot:
		return
	var team: Dictionary = teams[player_side]
	var player: Dictionary = team.slots[slot]
	var time_left := ball.time_left()
	var score := _receive_timing_score(time_left, player)
	rally.receive_pressed = true
	rally.receive_timing = score
	rally.receive_time_left = time_left
	if score >= 0.82:
		hud.set_prompt("PERFECT TIMING", "HOLD YOUR GROUND — THE BALL IS COMING")
		hud.flash(Color(0.35, 1.0, 0.65, 0.14))
		Sfx.play("ui", -9.0, 1.35)
	elif score >= 0.45:
		hud.set_prompt("GOOD TIMING", "STAY IN THE CIRCLE")
		Sfx.play("ui", -11.0, 1.12)
	else:
		hud.set_prompt("EARLY — STAY WITH IT", "THE CONTACT WILL BE SHAKY")
		Sfx.play("ui", -12.0, 0.9)

# ---------------------------------------------------------------------------
# Active player, AI movement, simulation ticks
# ---------------------------------------------------------------------------

func _set_active(side: int, slot: int) -> void:
	if active_rig and is_instance_valid(active_rig):
		active_rig.set_active(false)
	if side < 0 or side > 1:
		active_rig = null
		return
	var team: Dictionary = teams[side]
	if slot < 0 or slot >= team.rigs.size():
		active_rig = null
		return
	active_side = side
	active_slot = slot
	var rig: PlayerRig = team.rigs[slot]
	active_rig = rig
	rig.set_active(side == player_side and not autoplay)

func _update_ai(_delta: float) -> void:
	for side in [HOME, AWAY]:
		var team: Dictionary = teams[side]
		var ai_controlled: bool = side != player_side or autoplay
		for s in range(6):
			var rig: PlayerRig = team.rigs[s]
			if not ai_controlled and rig == active_rig:
				continue
			var spot := _ai_target_for(side, s, rig)
			var d := Vector2(spot.x - rig.global_position.x, spot.z - rig.global_position.z).length()
			if d > 0.16:
				rig.set_target(spot)
			else:
				rig.clear_target()
		if ai_controlled and phase == "set_flight" and int(rally.get("attacking", -1)) == side:
			var hs := int(rally.get("hitter_slot", -1))
			if hs >= 0 and hs <= 5:
				var hr: PlayerRig = team.rigs[hs]
				if not hr.is_jumping and ball.active and ball.t >= ball.duration * 0.46:
					hr.jump(0.62, 0.90)
					hr.play_action("spike", 0.62)
	if not autoplay and active_side == player_side and active_rig and bool(GameData.options.get("assist_move", true)):
		if phase in ["serve_flight", "attack_flight", "free_flight"]:
			var land := ball.end
			var dd := Vector2(land.x - active_rig.global_position.x, land.z - active_rig.global_position.z).length()
			if dd > 0.35 and dd < 3.2:
				active_rig.set_target(Vector3(land.x, 0.0, land.z))

func _ai_target_for(side: int, slot: int, rig: PlayerRig) -> Vector3:
	var team: Dictionary = teams[side]
	var attacking: int = int(rally.get("attacking", -1))
	var defending: int = int(rally.get("defending", -1))
	var chaser: int = int(rally.get("chaser_slot", -1))
	var live: bool = phase in ["serve_flight", "pass_flight", "set_flight", "attack_flight", "block_flight", "free_flight"]
	if not live:
		return _base_pos(side, slot)
	if side == defending and phase == "attack_flight" and ball.active and ball.t < float(rally.get("def_react", 0.0)):
		# Nobody teleports to the spike. The defense reads the hit first.
		return rig.global_position if slot == chaser else _base_pos(side, slot)
	if side == defending and slot == chaser and phase in ["serve_flight", "attack_flight", "free_flight"]:
		return Vector3(ball.end.x, 0.0, ball.end.z)
	if phase == "serve_flight":
		return rig.global_position
	if side == attacking:
		if slot == int(rally.get("setter_slot", -1)) and phase in ["pass_flight", "set_flight"]:
			return _setter_nest(team)
		if slot == int(rally.get("hitter_slot", -1)) and phase in ["set_flight", "attack_flight"]:
			var hp := rig.global_position
			hp.y = 0.0
			return hp
		return _attack_spot(team, slot)
	if side == defending:
		return _defense_spot(team, slot, ball.end)
	return _base_pos(side, slot)

func _attack_spot(team: Dictionary, slot: int) -> Vector3:
	var sign := _signf(int(team["side"]))
	match slot:
		3: return Vector3(-3.55 * sign, 0.0, sign * 1.9)
		1: return Vector3(3.55 * sign, 0.0, sign * 1.9)
		2: return Vector3(0.0, 0.0, sign * 2.15)
		4: return Vector3(-2.9 * sign, 0.0, sign * 4.4)
		0: return Vector3(2.9 * sign, 0.0, sign * 4.4)
		_: return Vector3(0.0, 0.0, sign * 3.6)

func _defense_spot(team: Dictionary, slot: int, landing: Vector3) -> Vector3:
	var side := int(team["side"])
	var sign := _signf(side)
	var base := _base_pos(side, slot)
	if FRONT.has(slot):
		var scheme := int(team.block_index)
		var step := 0.95
		if scheme == 1:
			step = 0.35
		elif scheme == 3:
			step = 1.2
		var x := clampf(landing.x, -HALF_W + 0.45, HALF_W - 0.45)
		var shift := float(2 - slot) * 0.5 * step * sign
		return Vector3(clampf(x + shift, -HALF_W + 0.2, HALF_W - 0.2), 0.0, sign * 1.02)
	var z := base.z
	if sign * landing.z > 0.0:
		z = lerpf(base.z, sign * clampf(absf(landing.z), 3.2, 8.6), 0.20)
	return Vector3(clampf(base.x + (landing.x - base.x) * 0.22, -HALF_W + 0.25, HALF_W - 0.25), 0.0, z)

func _update_rigs(delta: float) -> void:
	for team in teams:
		for rig in team.rigs:
			rig.tick(delta, true)

func _update_ball(delta: float) -> void:
	if ball.active:
		ball.tick(delta)
	if phase == "attack_flight":
		_try_block()

# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var focus := ball.global_position if ball.active else Vector3(0.0, 1.2, 0.0)
	var target_pos := Vector3(0, 9.2, _signf(player_side) * 17.8)
	var target_look := Vector3(0, 1.2, 0.0)
	var fov := 50.0
	match int(camera_mode):
		1:
			target_pos = Vector3(-0.4, 13.2, _signf(player_side) * 21.0)
			target_look = Vector3(0.0, 0.9, 0.4)
			fov = 46.0
		2:
			if active_rig:
				var p := active_rig.global_position
				target_pos = p + Vector3(0.0, 3.5, _signf(player_side) * 6.8)
				target_look = Vector3(focus.x * 0.6, maxf(1.0, focus.y * 0.6 + 0.6), focus.z * 0.4)
			else:
				target_pos = Vector3(0.0, 8.0, _signf(player_side) * 14.0)
				target_look = Vector3(0.0, 1.1, 0.0)
			fov = 62.0
		3:
			target_pos = Vector3(0.0, 23.5, _signf(player_side) * 7.5)
			target_look = Vector3(0.0, 0.0, 0.4)
			fov = 56.0
		_:
			target_pos = Vector3(clampf(focus.x * 0.32, -2.2, 2.2), 9.5, _signf(player_side) * 17.6)
			target_look = Vector3(clampf(focus.x * 0.5, -2.6, 2.6), maxf(0.8, focus.y * 0.4 + 0.7), clampf(focus.z * 0.35, -2.4, 2.4))
			fov = 52.0
	camera_pos = camera_pos.lerp(target_pos, clampf(delta * 3.4, 0.0, 1.0))
	camera_look = camera_look.lerp(target_look, clampf(delta * 4.4, 0.0, 1.0))
	if camera_pos.distance_to(camera_look) > 0.4:
		camera.look_at_from_position(camera_pos, camera_look, Vector3.UP)
	camera.fov = lerpf(camera.fov, fov, clampf(delta * 3.0, 0.0, 1.0))

# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------

func _update_hud(_delta: float) -> void:
	var card_side := active_side
	var card_slot := active_slot
	if not autoplay and card_side != player_side:
		card_side = player_side
		card_slot = _setter_slot(teams[player_side])
	var card := {}
	var stamina := 100.0
	if card_side >= 0 and card_side <= 1 and card_slot >= 0 and card_slot <= 5:
		card = teams[card_side].slots[card_slot]
		var rig: PlayerRig = teams[card_side].rigs[card_slot]
		stamina = rig.stamina
	if not card.is_empty():
		hud.set_player_info(card, stamina)
	var team: Dictionary = teams[player_side]
	hud.set_flow(float(team.flow), bool(team.ability_ready) and int(team.ability_timer) <= 0)
	hud.set_tactics(PLAY_NAMES[int(team.play_index)], SERVE_NAMES[int(team.serve_index)], BLOCK_NAMES[int(team.block_index)], RECV_NAMES[int(team.recv_index)])
	hud.set_rally(rally_hits)

	if autoplay:
		hud.clear_power()
		hud.hide_reticle()
		court.set_zone_grid_visible(false)
		court.hide_target_cell()
		court.hide_receive_marker()
		return

	var receiving := phase in ["serve_flight", "attack_flight"] \
		and int(rally.get("chaser_side", -1)) == player_side \
		and int(rally.get("chaser_slot", -1)) >= 0
	if receiving:
		var rslot := int(rally.get("chaser_slot", -1))
		var rplayer: Dictionary = teams[player_side].slots[rslot]
		var rrig: PlayerRig = teams[player_side].rigs[rslot]
		var radius := float(rally.get("recv_radius", _receive_radius_for(rplayer)))
		if active_rig == rrig and dive_clock > 0.0:
			radius += 0.62
		var dist := Vector2(rrig.global_position.x - ball.end.x, rrig.global_position.z - ball.end.z).length()
		var left := ball.time_left()
		var window := float(rally.get("recv_window", _receive_window_for(rplayer)))
		var timing_open := left <= 0.10 + window * 0.6
		var col := UI.CYAN
		if bool(rally.get("receive_pressed", false)):
			col = UI.GREEN
		elif dist > radius:
			col = UI.ORANGE
		elif timing_open:
			col = UI.GREEN
		court.set_receive_marker(ball.end, radius, col)
		court.set_receive_progress(ball.t / maxf(0.05, ball.duration))
		court.set_zone_grid_visible(false)
		court.hide_target_cell()
		hud.set_reticle_idle(mouse_pos)
		var dur := maxf(0.05, ball.duration)
		var progress := clampf(ball.t / dur, 0.0, 1.0)
		var lo := clampf(1.0 - (0.10 + window * 0.6) / dur, 0.0, 0.95)
		var hi := clampf(1.0 - maxf(0.0, 0.10 - window * 0.6) / dur, lo + 0.04, 1.0)
		hud.set_power(progress, lo, hi, "RECEIVE TIMING  —  SPACE AT THE BALL", UI.CYAN, true)
		if active_slot != rslot:
			hud.set_prompt("Q — RETURN TO THE RECEIVER", "THE BALL IS COMING DOWN")
		elif bool(rally.get("receive_pressed", false)):
			hud.set_prompt("CONTACT LOCKED — STAY IN THE CIRCLE", "GOOD POSITION WINS THE RALLY")
		elif dist > radius:
			hud.set_prompt("MOVE INTO THE CIRCLE", "SPACE TO RECEIVE  •  CTRL = DIVE  •  1-4 DEFENSE")
		elif timing_open:
			hud.set_prompt("PRESS SPACE NOW", "TIMING + POSITION  •  BETTER DEFENDERS = BIGGER WINDOW")
		else:
			hud.set_prompt("GET SET — WAIT FOR THE BALL", "THE CIRCLE IS YOUR RECEIVING ZONE")
		return

	if phase == "serve" and serving_side == player_side:
		hud.set_power(serve_charge if serving_hold else 0.0, 0.72, 0.92, "SERVE POWER  —  HOLD SPACE, RELEASE IN THE GREEN", UI.ORANGE, true)
	elif phase == "set_flight" and int(rally.get("attacking", -1)) == player_side and ball.active:
		var u := clampf(ball.t / maxf(0.05, ball.duration), 0.0, 1.0)
		hud.set_power(u, 0.42, 0.7, "JUMP TIMING  —  SPACE AT THE TOP OF THE SET", UI.CYAN, true)
	else:
		hud.clear_power()

	if aim_active:
		var tint := UI.GOLD if aim_valid else UI.RED
		hud.set_reticle(mouse_pos, aim_valid, tint)
		court.set_zone_grid_visible(true)
		court.set_target_cell(aim_point.x, aim_point.z, aim_valid, tint)
	else:
		hud.set_reticle_idle(mouse_pos)
		court.set_zone_grid_visible(false)
		court.hide_target_cell()

# ---------------------------------------------------------------------------
# Overlays, pause data, substitutions
# ---------------------------------------------------------------------------

func _open_pause() -> void:
	if overlay_open:
		return
	paused = true
	overlay_open = true
	_pause_note = "Use the tactics board to adjust the play call, serve type, block scheme, and reception shape."
	_pause_title = "PAUSED"
	pause_overlay.open_overlay(_pause_data())

func _resume_from_pause() -> void:
	if pause_overlay:
		pause_overlay.close_overlay()
	paused = false
	overlay_open = false

func _open_tactics() -> void:
	if overlay_open:
		return
	paused = true
	overlay_open = true
	var team: Dictionary = teams[player_side]
	tactics_overlay.setup(int(team.play_index), int(team.serve_index), int(team.block_index), int(team.recv_index))
	tactics_overlay.open_overlay()

func _on_tactics_changed(key: String, index: int) -> void:
	var team: Dictionary = teams[player_side]
	match key:
		"play":
			team.play_index = clampi(index, 0, PLAY_NAMES.size() - 1)
		"serve":
			team.serve_index = clampi(index, 0, SERVE_NAMES.size() - 1)
		"block":
			team.block_index = clampi(index, 0, BLOCK_NAMES.size() - 1)
		"receive":
			team.recv_index = clampi(index, 0, RECV_NAMES.size() - 1)
			if phase in ["serve", "serve_flight"]:
				_apply_receive_shape(teams[1 - serving_side])
	hud.set_tactics(PLAY_NAMES[int(team.play_index)], SERVE_NAMES[int(team.serve_index)], BLOCK_NAMES[int(team.block_index)], RECV_NAMES[int(team.recv_index)])

func _on_tactics_closed() -> void:
	paused = false
	overlay_open = false

func _pause_to_tactics() -> void:
	if pause_overlay:
		pause_overlay.close_overlay()
	paused = false
	overlay_open = false
	_open_tactics()

func _pause_substitute() -> void:
	if _auto_substitute():
		_pause_note = "Automatic substitution complete. The freshest matching player is in."
		Sfx.play("ui", -10.0, 1.1)
	else:
		_pause_note = "No substitution available. Check the bench and remaining subs."
	pause_overlay.open_overlay(_pause_data())

func _pause_substitute_custom(slot: int, bench_index: int) -> void:
	var team: Dictionary = teams[player_side]
	var name_out := str(team.slots[slot].get("name", "")) if slot >= 0 and slot < 6 else ""
	var incoming := ""
	if bench_index >= 0 and bench_index < team.bench.size():
		incoming = str(team.bench[bench_index].get("name", ""))
	if _swap_player(team, slot, bench_index):
		_pause_note = "SUB: %s in for %s. %d substitutions left this set." % [incoming, name_out, int(team.subs)]
		_set_active(player_side, slot)
		Sfx.play("ui", -9.0, 1.15)
	else:
		_pause_note = "That substitution is not available. Liberos cannot be used yet; check the bench and remaining subs."
	pause_overlay.open_overlay(_pause_data())

func _pause_data() -> Dictionary:
	var h: Dictionary = teams[HOME]
	var a: Dictionary = teams[AWAY]
	var lineup: Array = []
	for s in range(6):
		var p: Dictionary = h.slots[s].duplicate(true)
		var rig: PlayerRig = h.rigs[s]
		p["stamina"] = rig.stamina
		p["stamina_max"] = rig.stamina_max
		p["slot"] = s
		lineup.append(p)
	return {
		"home_short": str(h.data["short"]),
		"away_short": str(a.data["short"]),
		"home_color": Color.html(str(h.data["primary"])),
		"away_color": Color.html(str(a.data["primary"])),
		"home_sets": int(h.sets),
		"away_sets": int(a.sets),
		"home_score": int(h.score),
		"away_score": int(a.score),
		"set_number": set_number,
		"home_stats": h.stats.duplicate(true),
		"away_stats": a.stats.duplicate(true),
		"lineup": lineup,
		"bench": h.bench,
		"subs": int(h.subs),
		"timeouts": int(h.timeouts),
		"title": _pause_title,
		"note": _pause_note
	}

func _pause_timeout() -> void:
	_pause_title = "TIMEOUT"
	var team: Dictionary = teams[player_side]
	if int(team.timeouts) <= 0:
		_pause_note = "No timeouts left this set."
		pause_overlay.open_overlay(_pause_data())
		return
	if phase == "point" or phase == "set_end" or phase == "match_end":
		_pause_note = "You can only call a timeout during a live rally or before a serve."
		pause_overlay.open_overlay(_pause_data())
		return
	team.timeouts = int(team.timeouts) - 1
	var recovered := 0
	for rig in team.rigs:
		if rig.stamina < rig.stamina_max:
			rig.stamina = minf(rig.stamina_max, rig.stamina + 16.0)
			recovered += 1
	team.flow = minf(100.0, float(team.flow) + 9.0)
	_pause_note = "Timeout called. %d players catch their breath and the gym lifts the team." % recovered
	Sfx.play("ui", -10.0, 0.94)
	pause_overlay.open_overlay(_pause_data())

func _auto_substitute() -> bool:
	var team: Dictionary = teams[player_side]
	if int(team.subs) <= 0:
		return false
	if team.bench.is_empty():
		return false
	var slot := _most_tired_slot(team)
	if slot < 0:
		return false
	if not _swap_player(team, slot):
		return false
	_set_active(player_side, slot)
	return true

func _most_tired_slot(team: Dictionary) -> int:
	var best := -1
	var worst := 9999.0
	for s in range(6):
		var p: Dictionary = team.slots[s]
		if str(p.get("role", "")) == "L":
			continue
		var rig: PlayerRig = team.rigs[s]
		if rig.stamina < worst:
			worst = rig.stamina
			best = s
	return best

func _swap_player(team: Dictionary, slot: int, bench_index: int = -1) -> bool:
	if int(team.subs) <= 0 or team.bench.is_empty():
		return false
	if slot < 0 or slot > 5:
		return false
	var starter: Dictionary = team.slots[slot]
	if str(starter.get("role", "")) == "L":
		return false
	var li := -1
	for i in range(team.lineup.size()):
		var lp: Dictionary = team.lineup[i]
		if str(lp.get("name", "")) == str(starter.get("name", "")) and int(lp.get("number", 0)) == int(starter.get("number", 0)):
			li = i
			break
	if li < 0:
		return false
	var pick := 0
	if bench_index >= 0 and bench_index < team.bench.size():
		pick = bench_index
	else:
		var best := -999.0
		for i in range(team.bench.size()):
			var bp: Dictionary = team.bench[i]
			var score := float(bp["stats"]["stamina"])
			if str(bp.get("role", "")) == str(starter.get("role", "")):
				score += 35.0
			if score > best:
				best = score
				pick = i
	var incoming: Dictionary = team.bench[pick]
	if str(incoming.get("role", "")) == "L":
		return false
	team.bench.remove_at(pick)
	team.lineup[li] = incoming
	team.bench.append(starter)
	team.subs = int(team.subs) - 1
	_apply_rotation(team)
	return true

func _maybe_ai_substitute(side: int) -> void:
	var team: Dictionary = teams[side]
	if int(team.subs) <= 0 or team.bench.is_empty():
		return
	var slot := _most_tired_slot(team)
	if slot < 0:
		return
	var rig: PlayerRig = team.rigs[slot]
	if rig.stamina > 38.0:
		return
	if _swap_player(team, slot):
		var col := Color.html(str(team.data["primary"]))
		hud.commentary("%s turns to the bench." % str(team.data["short"]), col, 2.2)

# === END OF MATCH ===
