extends Node

## Top-level flow: main menu, team select, tournament bracket, match, results.

const MainMenuScreen := preload("res://scripts/ui/MainMenuScreen.gd")
const TeamSelectScreen := preload("res://scripts/ui/TeamSelectScreen.gd")
const TournamentScreen := preload("res://scripts/ui/TournamentScreen.gd")
const OptionsScreen := preload("res://scripts/ui/OptionsScreen.gd")
const InfoScreen := preload("res://scripts/ui/InfoScreen.gd")
const ResultsScreen := preload("res://scripts/ui/ResultsScreen.gd")
const MatchScene := preload("res://scripts/Match.gd")

var backdrop: Control
var current_screen: Control
var active_match
var pending_result: Dictionary = {}

func _ready() -> void:
	randomize()
	_setup_input()
	DisplayServer.window_set_title("HAIKYUU!!  Spring Tournament 2013")
	if _has_arg("--autotest"):
		_start_autotest()
		return
	if _has_arg("--matchtest"):
		_start_matchtest()
		return
	if _has_arg("--uitest"):
		_start_uitest()
		return
	show_main_menu()

func _has_arg(arg: String) -> bool:
	for a in OS.get_cmdline_args():
		if a == arg:
			return true
	for a in OS.get_cmdline_user_args():
		if a == arg:
			return true
	return false

# ---------------------------------------------------------------------------
# Input map (built in code so the project needs no fragile serialized events)
# ---------------------------------------------------------------------------

func _setup_input() -> void:
	_key("move_forward", [KEY_W, KEY_UP])
	_key("move_back", [KEY_S, KEY_DOWN])
	_key("move_left", [KEY_A, KEY_LEFT])
	_key("move_right", [KEY_D, KEY_RIGHT])
	_key("sprint", [KEY_SHIFT])
	_key("action", [KEY_SPACE])
	_key("dive", [KEY_CTRL, KEY_C])
	_key("switch_player", [KEY_Q])
	_key("special", [KEY_E])
	_key("tactics", [KEY_TAB])
	_key("pause", [KEY_ESCAPE, KEY_P])
	_key("camera", [KEY_V])
	_key("confirm", [KEY_ENTER, KEY_KP_ENTER])
	_key("back", [KEY_ESCAPE])
	_key("num1", [KEY_1, KEY_KP_1])
	_key("num2", [KEY_2, KEY_KP_2])
	_key("num3", [KEY_3, KEY_KP_3])
	_key("num4", [KEY_4, KEY_KP_4])
	_key("num5", [KEY_5, KEY_KP_5])
	_joy_button("action", JOY_BUTTON_A)
	_joy_button("dive", JOY_BUTTON_B)
	_joy_button("special", JOY_BUTTON_Y)
	_joy_button("switch_player", JOY_BUTTON_X)
	_joy_button("tactics", JOY_BUTTON_BACK)
	_joy_button("pause", JOY_BUTTON_START)
	_joy_button("camera", JOY_BUTTON_RIGHT_SHOULDER)
	_joy_button("sprint", JOY_BUTTON_LEFT_SHOULDER)
	_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)

func _key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _joy_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func _joy_axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)

# ---------------------------------------------------------------------------
# Screen management
# ---------------------------------------------------------------------------

func _clear_screen() -> void:
	if current_screen and is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null
	if backdrop and is_instance_valid(backdrop):
		backdrop.queue_free()
		backdrop = null
	if active_match and is_instance_valid(active_match):
		active_match.queue_free()
		active_match = null

func _add_screen(screen: Control, with_backdrop: bool = true) -> void:
	_clear_screen()
	if with_backdrop:
		backdrop = load("res://scripts/ui/MenuBackdrop.gd").new()
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(backdrop)
	current_screen = screen
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	screen.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(screen, "modulate", Color.WHITE, 0.22)

func show_main_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var menu = MainMenuScreen.new()
	menu.navigate.connect(_on_navigate)
	_add_screen(menu, true)

func _on_navigate(screen_name: String, arg: Variant = null) -> void:
	match screen_name:
		"quick":
			show_team_select("exhibition")
		"tournament":
			if not GameData.tournament.is_empty() and GameData.tournament.get("champion", "") == "":
				show_tournament()
			else:
				show_team_select("tournament")
		"teams":
			show_team_select("browse")
		"options":
			show_options()
		"howto":
			show_info("howto")
		"credits":
			show_info("credits")
		"quit":
			get_tree().quit()
		"menu":
			show_main_menu()
		"tournament_screen":
			show_tournament()
		_:
			show_main_menu()

func show_team_select(mode: String) -> void:
	var ts = TeamSelectScreen.new()
	ts.mode = mode
	ts.start_match.connect(_start_match)
	ts.start_tournament.connect(_start_tournament)
	ts.navigate.connect(_on_navigate)
	_add_screen(ts, true)

func show_tournament() -> void:
	if GameData.tournament.is_empty():
		show_team_select("tournament")
		return
	var ts = TournamentScreen.new()
	ts.play_match.connect(_play_tournament_match)
	ts.navigate.connect(_on_navigate)
	ts.new_tournament.connect(func(): show_team_select("tournament"))
	_add_screen(ts, true)

func show_options() -> void:
	var opts = OptionsScreen.new()
	opts.back.connect(func(): show_main_menu())
	_add_screen(opts, true)

func show_info(kind: String) -> void:
	var info = InfoScreen.new()
	info.kind = kind
	info.back.connect(func(): show_main_menu())
	_add_screen(info, true)

func _start_tournament(team_id: String) -> void:
	GameData.new_tournament(team_id)
	show_tournament()

func _play_tournament_match(opponent_id: String) -> void:
	var player_id: String = GameData.tournament["team_id"]
	pending_result = {"mode": "tournament"}
	_start_match(player_id, opponent_id, {"sets": GameData.options["sets"]})

# ---------------------------------------------------------------------------
# Match
# ---------------------------------------------------------------------------

func _start_match(home_id: String, away_id: String, opts: Dictionary = {}) -> void:
	_clear_screen()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	active_match = MatchScene.new()
	active_match.home_team_id = home_id
	active_match.away_team_id = away_id
	active_match.match_options = opts.duplicate(true)
	active_match.match_finished.connect(_on_match_finished)
	add_child(active_match)

func _on_match_finished(result: Dictionary) -> void:
	GameData.last_match_result = result
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if pending_result.get("mode", "") == "tournament":
		var player_id: String = GameData.tournament.get("team_id", "")
		var player_won: bool = bool(result.get("home_won", false))
		var ps: int = int(result.get("home_sets", 0))
		var os: int = int(result.get("away_sets", 0))
		if result.get("home_id", "") != player_id:
			player_won = not player_won
			var tmp := ps
			ps = os
			os = tmp
		GameData.record_match(player_won, ps, os)
		pending_result = {}
		show_tournament()
		return
	var rs = ResultsScreen.new()
	rs.result = result
	rs.rematch.connect(func(): _start_match(str(result.get("home_id", "karasuno")), str(result.get("away_id", "nekoma")), {"sets": GameData.options["sets"]}))
	rs.navigate.connect(_on_navigate)
	_add_screen(rs, true)

func home_id_or(result: Dictionary, key: String) -> String:
	return str(result.get(key, "karasuno"))

# ---------------------------------------------------------------------------
# Headless self-test: both teams AI-controlled, fast simulation.
# ---------------------------------------------------------------------------

func _start_autotest() -> void:
	print("[autotest] starting headless AI match")
	var m = MatchScene.new()
	m.home_team_id = "karasuno"
	m.away_team_id = "nekoma"
	m.match_options = {"sets": 1, "autoplay": true, "time_scale": 12.0}
	m.match_finished.connect(func(r):
		print("[autotest] finished ", r)
		get_tree().quit()
	)
	add_child(m)
	await get_tree().create_timer(1800.0).timeout
	print("[autotest] timeout — forcing quit")
	get_tree().quit()

# ---------------------------------------------------------------------------
# Headless self-test for the human-controlled path: simulate input events.
# ---------------------------------------------------------------------------

func _send_action(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)

func _tap(action: String, seconds: float = 0.08) -> void:
	_send_action(action, true)
	await get_tree().create_timer(seconds).timeout
	_send_action(action, false)

## Hold the movement keys that walk the active player toward a court position.
func _steer_to(m, target: Vector3) -> void:
	if m.active_rig == null:
		return
	var d: Vector3 = Vector3(target.x - m.active_rig.global_position.x, 0.0, target.z - m.active_rig.global_position.z)
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		_send_action(a, false)
	if d.length() < 0.18:
		return
	var fwd: Vector3 = -m.camera.global_transform.basis.z
	fwd.y = 0.0
	var right: Vector3 = m.camera.global_transform.basis.x
	right.y = 0.0
	if fwd.length() < 0.01 or right.length() < 0.01:
		return
	fwd = fwd.normalized()
	right = right.normalized()
	var vx := d.dot(right)
	var vy := d.dot(fwd)
	if vx > 0.18:
		_send_action("move_right", true)
	elif vx < -0.18:
		_send_action("move_left", true)
	if vy > 0.18:
		_send_action("move_forward", true)
	elif vy < -0.18:
		_send_action("move_back", true)

func _start_matchtest() -> void:
	print("[matchtest] starting simulated-input match")
	var m = MatchScene.new()
	m.home_team_id = "karasuno"
	m.away_team_id = "nekoma"
	m.match_options = {"sets": 1, "time_scale": 3.0}
	m.match_finished.connect(func(r):
		print("[matchtest] finished ", r)
		get_tree().quit()
	)
	add_child(m)
	await get_tree().create_timer(1.0).timeout
	await _tap("camera")
	var t: float = 0.0
	var holding: bool = false
	var hold_left: float = 0.0
	var tactics_done: bool = false
	var pause_done: bool = false
	var attacks: int = 0
	var receives: int = 0
	while t < 30.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
		var ph := str(m.phase)
		if ph == "serve" and int(m.serving_side) == int(m.player_side):
			if not holding:
				_send_action("action", true)
				holding = true
				hold_left = 0.5 + randf() * 0.7
			else:
				hold_left -= 0.1
				if hold_left <= 0.0:
					_send_action("action", false)
					holding = false
			continue
		if holding:
			_send_action("action", false)
			holding = false
		# New receive system: get under the ball, then press Space inside the
		# timing window. Poll at frame-ish resolution so we never miss it.
		var receiving: bool = (ph == "serve_flight" or ph == "attack_flight") \
			and int(m.rally.get("chaser_side", -1)) == int(m.player_side) \
			and int(m.rally.get("chaser_slot", -1)) == int(m.active_slot)
		if receiving:
			_send_action("sprint", true)
			var guard := 0
			while guard < 400 and str(m.phase) == ph and float(m.ball.time_left()) > 0.12 and not bool(m.rally.get("receive_pressed", false)):
				_steer_to(m, m.ball.end)
				await get_tree().create_timer(0.01).timeout
				guard += 1
				t += 0.01
			_send_action("sprint", false)
			for a in ["move_left", "move_right", "move_forward", "move_back"]:
				_send_action(a, false)
			if not bool(m.rally.get("receive_pressed", false)):
				await _tap("action", 0.04)
				receives += 1
			continue
		if not tactics_done and t > 4.0:
			tactics_done = true
			await _tap("tactics")
			await _tap("num2")
			await get_tree().create_timer(0.5).timeout
			await _tap("tactics")
			continue
		if not pause_done and t > 8.0:
			pause_done = true
			await _tap("pause")
			await get_tree().create_timer(0.3).timeout
			m._pause_timeout()
			await get_tree().create_timer(0.2).timeout
			var bench_i := -1
			for i in range(m.teams[0].bench.size()):
				if str(m.teams[0].bench[i].get("role", "")) != "L":
					bench_i = i
					break
			if bench_i >= 0:
				m._pause_substitute_custom(0, bench_i)
			else:
				m._pause_substitute()
			print("[matchtest] sub: ", str(m._pause_note), "  subs_left=", int(m.teams[0].subs))
			await get_tree().create_timer(0.2).timeout
			await _tap("pause")
			continue
		if ph == "set_flight" and int(m.rally.get("attacking", -1)) == int(m.player_side) and not holding:
			hold_left = 0.5
			_send_action("action", true)
			holding = true
			attacks += 1
		elif holding:
			hold_left -= 0.1
			if hold_left <= 0.0:
				_send_action("action", false)
				holding = false
		if randf() < 0.05:
			await _tap("switch_player")
		if randf() < 0.04:
			await _tap("dive")
		if randf() < 0.04:
			await _tap("special")
		if randf() < 0.02:
			await _tap("camera")
	print("[matchtest] summary phase=", str(m.phase), " score=", int(m.teams[0].score), "-", int(m.teams[1].score), " rallies=", int(m.rally_hits), " attacks=", attacks, " receives=", receives, " tactics=", tactics_done, " pause=", pause_done)
	if int(m.teams[0].score) + int(m.teams[1].score) <= 0:
		print("[matchtest] FAIL — no points scored on the human path")
	print("[matchtest] timeout — forcing quit")
	get_tree().quit()

# ---------------------------------------------------------------------------
# Headless self-test for the screens: menus, tournament, results.
# ---------------------------------------------------------------------------

func _ui_frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout

func _fake_result(home_id: String, away_id: String) -> Dictionary:
	var h := GameData.team(home_id)
	var a := GameData.team(away_id)
	var hp: Dictionary = h["players"][0]
	var ap: Dictionary = a["players"][1]
	return {
		"home_id": home_id,
		"away_id": away_id,
		"home_won": true,
		"home_sets": 3,
		"away_sets": 1,
		"sets": [[25, 18], [22, 25], [25, 21], [25, 19]],
		"home_stats": {"kills": 55, "blocks": 8, "aces": 4, "digs": 60, "errors": 9, "attacks": 120, "serves": 92, "receptions": 80, "sets": 118},
		"away_stats": {"kills": 48, "blocks": 6, "aces": 2, "digs": 52, "errors": 11, "attacks": 112, "serves": 88, "receptions": 74, "sets": 110},
		"mvp": {"name": str(hp["name"]), "team": str(h["short"]), "number": int(hp["number"]), "line": "20 PTS  •  3 BLK  •  8 DIG"},
		"top_players": [
			{"name": str(hp["name"]), "team_id": home_id, "line": "20 PTS  •  3 BLK  •  8 DIG", "score": 30.0},
			{"name": str(ap["name"]), "team_id": away_id, "line": "16 PTS  •  2 BLK  •  5 DIG", "score": 22.0}
		],
		"forfeit": false
	}

func _start_uitest() -> void:
	print("[uitest] walking every screen")
	show_main_menu()
	await _ui_frame()
	show_team_select("exhibition")
	await _ui_frame()
	# Exercise the starting-lineup editor end to end, then restore the saved
	# lineups so a test run never edits the player's real rotation.
	var saved_lineups: Dictionary = GameData.starting_lineups.duplicate(true)
	var ts = current_screen
	var bench_pick := ""
	for b in GameData.bench("karasuno"):
		if str(b.get("role", "")) != "L":
			bench_pick = str(b.get("id", ""))
			break
	if ts != null and is_instance_valid(ts) and ts.has_method("_open_lineup_editor") and bench_pick != "":
		ts.call("_open_lineup_editor", "karasuno")
		await _ui_frame()
		ts.call("_on_lineup_starter", 0)
		await _ui_frame()
		ts.call("_on_lineup_bench", bench_pick)
		await _ui_frame()
		var ids: Array = GameData.lineup_ids("karasuno")
		print("[uitest] lineup editor ok, bench in six=", ids.has(bench_pick))
		ts.call("_close_lineup_editor")
		await _ui_frame()
	GameData.starting_lineups = saved_lineups
	GameData.save_lineups()
	show_team_select("browse")
	await _ui_frame()
	show_team_select("tournament")
	await _ui_frame()
	show_options()
	await _ui_frame()
	show_info("howto")
	await _ui_frame()
	show_info("credits")
	await _ui_frame()
	_start_tournament("karasuno")
	await _ui_frame()
	var opponent := GameData.current_opponent()
	print("[uitest] round 1 vs ", opponent)
	pending_result = {"mode": "tournament"}
	_on_match_finished(_fake_result("karasuno", opponent))
	await _ui_frame()
	print("[uitest] tournament round now ", int(GameData.tournament.get("round", 0)), " champion=", str(GameData.tournament.get("champion", "")))
	var rs = ResultsScreen.new()
	rs.result = _fake_result("karasuno", "nekoma")
	_add_screen(rs, true)
	await _ui_frame()
	print("[uitest] ok")
	get_tree().quit()
