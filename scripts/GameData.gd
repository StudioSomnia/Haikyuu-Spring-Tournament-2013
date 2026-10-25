extends Node

## Global data, settings, and the Spring Tournament bracket.

var teams: Dictionary = {}
var team_order: Array[String] = []
var options: Dictionary = {
	"difficulty": 2,
	"sets": 5,
	"camera": 0,
	"sfx": true,
	"auto_receive": false,
	"auto_set": true,
	"auto_attack": false,
	"assist_move": true,
	"tactics_slowmo": true
}
var tournament: Dictionary = {}
var last_match_result: Dictionary = {}

const DIFFICULTY_NAMES := ["VERY EASY", "EASY", "NORMAL", "HARD", "VERY HARD"]
const DIFFICULTY_MULT := [0.80, 0.90, 1.0, 1.09, 1.18]
const CAMERA_NAMES := ["DYNAMIC", "BROADCAST", "BEHIND PLAYER", "HIGH TACTICAL"]
const SET_OPTIONS := [1, 3, 5]

const COMMENTARY := {
	"serve": ["{player} steps up to the service line.", "{team} puts the ball in play.", "The gym goes quiet for the serve."],
	"ace": ["ACE! {player}'s serve hits the floor untouched!", "What a serve from {player}! Nobody moved!", "{player} paints the line for an ace!"],
	"kill": ["{player} hammers it through the block!", "That's a monster hit from {player}!", "{player} finds the open floor! Point {team}!"],
	"block": ["ROOFED! {player} shuts the door at the net!", "{player} wins the battle at the net!", "The wall holds! {team} takes the point!"],
	"dig": ["{player} keeps the rally alive!", "Incredible floor defense from {player}!", "{player} digs it out of nowhere!"],
	"set": ["{player} threads the pass perfectly.", "{player} sets it up with precision."],
	"error": ["That one sails out. Point {team}.", "A costly miss, and {team} takes it.", "The ball lands wide. {team} scores."],
	"perfect": ["PERFECT! The timing was flawless.", "Textbook technique from {player}!", "That is as clean as it gets!"],
	"point": ["Point, {team}!", "{team} takes the rally!", "The crowd erupts for {team}!"],
	"set_point": ["SET POINT for {team}!", "{team} is one point away from the set!"],
	"match_point": ["MATCH POINT for {team}!", "One point separates {team} from victory!"],
	"flow": ["{team} is in the zone! FLOW is ready!", "The momentum is electric. {team} can unleash its signature play!"]
}

func _ready() -> void:
	teams = TeamDatabase.build()
	team_order.clear()
	for k in teams.keys():
		team_order.append(str(k))
	_load_settings()
	_load_tournament()

func team(id: String) -> Dictionary:
	return teams.get(id, teams["karasuno"])

func team_ids() -> Array[String]:
	return team_order.duplicate()

func team_color(id: String) -> Color:
	return Color.html(team(id)["primary"])

func team_secondary(id: String) -> Color:
	return Color.html(team(id)["secondary"])

func team_accent(id: String) -> Color:
	return Color.html(team(id)["accent"])

func difficulty_name() -> String:
	return DIFFICULTY_NAMES[clampi(int(options["difficulty"]), 0, 4)]

func difficulty_mult() -> float:
	return DIFFICULTY_MULT[clampi(int(options["difficulty"]), 0, 4)]

func player_name_of(team_id: String, player_id: String) -> String:
	for p in team(team_id)["players"]:
		if p["id"] == player_id:
			return p["name"]
	return "Player"

func starters(team_id: String) -> Array:
	var out: Array = []
	for p in team(team_id)["players"]:
		if p["starter"]:
			out.append(p)
	while out.size() < 6:
		out.append(team(team_id)["players"][out.size()])
	return out.slice(0, 6)

func bench(team_id: String) -> Array:
	var out: Array = []
	for p in team(team_id)["players"]:
		if not p["starter"]:
			out.append(p)
	return out

func random_commentary(kind: String, player: String = "", team_name: String = "") -> String:
	var pool: Array = COMMENTARY.get(kind, ["..."])
	var line: String = pool[randi() % pool.size()]
	return line.replace("{player}", player).replace("{team}", team_name)

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in options:
		cfg.set_value("game", k, options[k])
	cfg.save("user://settings.cfg")

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		for k in options.keys():
			if cfg.has_section_key("game", k):
				options[k] = cfg.get_value("game", k)

# ---------------------------------------------------------------------------
# Spring Tournament 2013
# ---------------------------------------------------------------------------

func new_tournament(player_team_id: String) -> void:
	var others: Array[String] = []
	for id in team_order:
		if id != player_team_id:
			others.append(id)
	others.shuffle()
	var alive: Array[String] = [player_team_id]
	for i in range(7):
		alive.append(others[i])
	alive.shuffle()
	tournament = {
		"team_id": player_team_id,
		"alive": alive,
		"round": 0,
		"matches": [],
		"history": [],
		"champion": "",
		"eliminated": false,
		"created": Time.get_datetime_string_from_system()
	}
	_build_matches()
	save_tournament()

func _build_matches() -> void:
	var alive: Array = tournament.get("alive", [])
	var matches: Array = []
	var i := 0
	while i + 1 < alive.size():
		matches.append({
			"a": alive[i],
			"b": alive[i + 1],
			"played": false,
			"winner": "",
			"score_a": 0,
			"score_b": 0
		})
		i += 2
	tournament["matches"] = matches

func current_player_match_index() -> int:
	if tournament.is_empty():
		return -1
	var id: String = tournament.get("team_id", "")
	var matches: Array = tournament.get("matches", [])
	for i in range(matches.size()):
		if matches[i]["a"] == id or matches[i]["b"] == id:
			return i
	return -1

func current_opponent() -> String:
	var idx := current_player_match_index()
	if idx < 0:
		return ""
	var m: Dictionary = tournament["matches"][idx]
	var id: String = tournament["team_id"]
	return m["b"] if m["a"] == id else m["a"]

func record_match(player_won: bool, player_sets: int, opp_sets: int) -> void:
	if tournament.is_empty():
		return
	var idx := current_player_match_index()
	if idx < 0:
		return
	var matches: Array = tournament["matches"]
	var pid: String = tournament["team_id"]
	var m: Dictionary = matches[idx]
	var opponent: String = m["b"] if m["a"] == pid else m["a"]
	m["played"] = true
	m["winner"] = pid if player_won else opponent
	m["score_a"] = player_sets if m["a"] == pid else opp_sets
	m["score_b"] = opp_sets if m["a"] == pid else player_sets

	for i in range(matches.size()):
		if i == idx:
			continue
		if not matches[i]["played"]:
			var sim := simulate_match(matches[i]["a"], matches[i]["b"])
			matches[i]["played"] = true
			matches[i]["winner"] = sim["winner"]
			matches[i]["score_a"] = sim["score_a"]
			matches[i]["score_b"] = sim["score_b"]
	tournament["history"].append(matches.duplicate(true))

	var winners: Array = []
	for mm in matches:
		winners.append(mm["winner"])

	if not player_won:
		tournament["eliminated"] = true
		tournament["champion"] = _simulate_rest(winners)
		save_tournament()
		return

	tournament["round"] = int(tournament["round"]) + 1
	tournament["alive"] = winners
	if tournament["round"] >= 3:
		tournament["champion"] = pid
	else:
		_build_matches()
	save_tournament()

func _simulate_rest(alive: Array) -> String:
	var current: Array = alive.duplicate()
	while current.size() > 1:
		var next: Array = []
		var i := 0
		while i + 1 < current.size():
			var sim := simulate_match(current[i], current[i + 1])
			next.append(sim["winner"])
			i += 2
		current = next
	return current[0] if current.size() > 0 else ""

func simulate_match(a: String, b: String) -> Dictionary:
	var ra: float = float(team(a)["overall"]) + randf_range(-7.0, 7.0)
	var rb: float = float(team(b)["overall"]) + randf_range(-7.0, 7.0)
	var winner: String = a if ra >= rb else b
	var loser_is_a := winner == b
	var winner_sets := 3
	var loser_sets := randi() % 3
	return {
		"winner": winner,
		"score_a": loser_sets if loser_is_a else winner_sets,
		"score_b": winner_sets if loser_is_a else loser_sets
	}

func save_tournament() -> void:
	var f := FileAccess.open("user://tournament.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(tournament, "\t"))

func _load_tournament() -> void:
	if not FileAccess.file_exists("user://tournament.json"):
		return
	var f := FileAccess.open("user://tournament.json", FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and parsed.has("team_id"):
		tournament = parsed

func clear_tournament() -> void:
	tournament = {}
	if FileAccess.file_exists("user://tournament.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://tournament.json"))

func round_name(round_index: int) -> String:
	match round_index:
		0: return "QUARTERFINALS"
		1: return "SEMIFINALS"
		2: return "FINAL"
		_: return "COMPLETE"
