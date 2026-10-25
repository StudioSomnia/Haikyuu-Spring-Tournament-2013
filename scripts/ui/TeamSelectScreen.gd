extends Control

signal start_match(home_id: String, away_id: String, opts: Dictionary)
signal start_tournament(team_id: String)
signal navigate(screen: String, arg: Variant)

var mode := "exhibition"
var step := "home"
var selected_home := "karasuno"
var selected_away := "nekoma"
var viewed := "karasuno"
var difficulty := 2
var set_count := 5

var _cards: Dictionary = {}
var _detail: VBoxContainer
var _header_step: Label
var _play_btn: Button
var _hint: Label
var _diff_label: Label
var _sets_label: Label

func _ready() -> void:
	difficulty = int(GameData.options["difficulty"])
	set_count = int(GameData.options["sets"])
	if not GameData.SET_OPTIONS.has(set_count):
		set_count = 5
	_build()
	_refresh()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# Header ---------------------------------------------------------------
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	root.add_child(head)
	var back := UI.small_button("←  BACK", UI.MUTED)
	back.custom_minimum_size = Vector2(120, 40)
	back.pressed.connect(func(): navigate.emit("menu"))
	head.add_child(back)
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 0)
	head.add_child(title_box)
	var title_text := "SPRING TOURNAMENT 2013"
	if mode == "exhibition":
		title_text = "QUICK MATCH"
	elif mode == "browse":
		title_text = "TEAM & PLAYER DATA"
	title_box.add_child(UI.bold(title_text, 36, UI.TEXT))
	_header_step = UI.label("", 14, UI.ORANGE)
	title_box.add_child(_header_step)
	head.add_child(UI.hspacer())
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	head.add_child(controls)
	var dbox := UI.panel(Color(0, 0, 0, 0.25), UI.LINE, 8)
	controls.add_child(dbox)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 0)
	dbox.add_child(dv)
	dv.add_child(UI.label("DIFFICULTY", 10, UI.MUTED))
	_diff_label = UI.bold(GameData.difficulty_name(), 15, UI.GOLD)
	dv.add_child(_diff_label)
	var dprev := UI.small_button("−", UI.GOLD)
	dprev.custom_minimum_size = Vector2(38, 34)
	dprev.pressed.connect(func(): _cycle_difficulty(-1))
	controls.add_child(dprev)
	var dnext := UI.small_button("+", UI.GOLD)
	dnext.custom_minimum_size = Vector2(38, 34)
	dnext.pressed.connect(func(): _cycle_difficulty(1))
	controls.add_child(dnext)
	if mode != "tournament":
		var sbox := UI.panel(Color(0, 0, 0, 0.25), UI.LINE, 8)
		controls.add_child(sbox)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 0)
		sbox.add_child(sv)
		sv.add_child(UI.label("SETS", 10, UI.MUTED))
		_sets_label = UI.bold(str(set_count), 15, UI.CYAN)
		sv.add_child(_sets_label)
		var sprev := UI.small_button("−", UI.CYAN)
		sprev.custom_minimum_size = Vector2(38, 34)
		sprev.pressed.connect(func(): _cycle_sets(-1))
		controls.add_child(sprev)
		var snext := UI.small_button("+", UI.CYAN)
		snext.custom_minimum_size = Vector2(38, 34)
		snext.pressed.connect(func(): _cycle_sets(1))
		controls.add_child(snext)

	root.add_child(UI.hline())

	# Content --------------------------------------------------------------
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 22)
	root.add_child(content)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for id in GameData.team_ids():
		var team := GameData.team(id)
		var accent := Color.html(team["primary"])
		var b := UI.button("", accent, 17, 82)
		b.custom_minimum_size = Vector2(245, 82)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _select(id))
		grid.add_child(b)
		_cards[id] = b
		var stripe := ColorRect.new()
		stripe.color = accent
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		stripe.offset_right = 5
		stripe.offset_left = 0
		b.add_child(stripe)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2(470, 0)
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(detail_scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(_detail)

	# Footer ---------------------------------------------------------------
	root.add_child(UI.hline())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 16)
	root.add_child(foot)
	_hint = UI.label("", 14, UI.MUTED)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_hint)
	_play_btn = UI.button("PLAY MATCH  →", UI.ORANGE, 20, 50)
	_play_btn.custom_minimum_size = Vector2(260, 50)
	_play_btn.pressed.connect(_commit)
	foot.add_child(_play_btn)

func _cycle_difficulty(d: int) -> void:
	difficulty = clampi(difficulty + d, 0, 4)
	GameData.options["difficulty"] = difficulty
	GameData.save_settings()
	_diff_label.text = GameData.difficulty_name()
	Sfx.play("ui", -12.0, 1.0)

func _cycle_sets(d: int) -> void:
	var idx := GameData.SET_OPTIONS.find(set_count)
	if idx < 0:
		idx = 2
	idx = clampi(idx + d, 0, GameData.SET_OPTIONS.size() - 1)
	set_count = GameData.SET_OPTIONS[idx]
	GameData.options["sets"] = set_count
	GameData.save_settings()
	if _sets_label:
		_sets_label.text = str(set_count)
	Sfx.play("ui", -12.0, 1.0)

func _select(id: String) -> void:
	Sfx.play("ui", -12.0, 1.1)
	viewed = id
	if mode == "browse":
		_refresh()
		return
	if mode == "tournament":
		selected_home = id
	elif step == "home":
		selected_home = id
		selected_away = ""
	else:
		if id == selected_home:
			return
		selected_away = id
	_refresh()

func _refresh() -> void:
	for id in _cards:
		var b: Button = _cards[id]
		var team := GameData.team(id)
		var selected: bool = (id == viewed)
		var marker := "▶  " if selected else "     "
		b.text = "%s%s\n%s\nOVR %d   •   %s" % [marker, team["short"], team["name"], team["overall"], _role_blurb(id)]
		b.add_theme_color_override("font_color", UI.TEXT if selected else UI.MUTED)
		b.modulate = Color.WHITE if (mode == "browse" or step == "home" or id != selected_home) else Color(0.35, 0.35, 0.4, 0.7)
		b.disabled = (mode == "exhibition" and step == "away" and id == selected_home)

	if mode == "browse":
		_header_step.text = "BROWSE THE ROSTERS  •  SELECT A SCHOOL"
	elif mode == "tournament":
		_header_step.text = "STEP 1/1  •  CHOOSE YOUR SCHOOL"
	else:
		_header_step.text = "STEP 1/2  •  CHOOSE YOUR TEAM" if step == "home" else "STEP 2/2  •  CHOOSE YOUR OPPONENT"

	if _play_btn:
		if mode == "browse":
			_play_btn.text = "QUICK MATCH  →"
		elif mode == "tournament":
			_play_btn.text = "ENTER TOURNAMENT  →"
		else:
			_play_btn.text = "PLAY MATCH  →" if step == "away" and selected_away != "" else "CHOOSE OPPONENT  →"

	if _hint:
		if mode == "browse":
			_hint.text = "Every school has its own playbook, signature ability, and player traits."
		elif mode == "tournament":
			_hint.text = "Eight schools. Single elimination. Win three matches to take the Spring Tournament."
		elif step == "home":
			_hint.text = "Pick the school you will control. Your team defends the near court."
		else:
			_hint.text = "%s selected. Now pick who stands across the net." % GameData.team(selected_home)["name"]

	_build_detail()

func _role_blurb(id: String) -> String:
	var t := GameData.team(id)
	var pb: Dictionary = t["playbook"]
	return "%s tempo" % ("FAST" if float(pb.get("tempo", 0.8)) >= 0.85 else "CONTROL")

func _build_detail() -> void:
	if not _detail:
		return
	UI.clear(_detail)
	var t := GameData.team(viewed)
	var accent := Color.html(t["primary"])
	var header := UI.panel(Color(accent.r * 0.14, accent.g * 0.14, accent.b * 0.14, 0.92), Color(accent.r, accent.g, accent.b, 0.55), 14)
	_detail.add_child(header)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	header.add_child(hv)
	hv.add_child(UI.bold(t["short"], 32, accent))
	hv.add_child(UI.label(t["name"] + "  •  " + t["motto"], 15, UI.MUTED))
	var ov := HBoxContainer.new()
	ov.add_theme_constant_override("separation", 12)
	hv.add_child(ov)
	ov.add_child(UI.label("TEAM OVERALL", 11, UI.MUTED))
	ov.add_child(UI.bold(str(t["overall"]), 28, UI.GOLD))
	if mode == "exhibition" and step == "away" and selected_home != "":
		ov.add_child(UI.hspacer())
		ov.add_child(UI.label("vs  " + GameData.team(selected_home)["short"], 16, UI.TEXT))

	var ab := UI.panel(Color(0, 0, 0, 0.28), Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.4), 12)
	_detail.add_child(ab)
	var av := VBoxContainer.new()
	av.add_theme_constant_override("separation", 5)
	ab.add_child(av)
	av.add_child(UI.chip("FLOW ABILITY", UI.GOLD, 11))
	av.add_child(UI.bold(t["ability_name"], 22, UI.GOLD))
	var desc := UI.label(t["ability_desc"], 14, UI.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	av.add_child(desc)

	var stats := UI.panel(Color(0, 0, 0, 0.22), UI.LINE, 12)
	_detail.add_child(stats)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 5)
	stats.add_child(sv)
	sv.add_child(UI.bold("STARTER AVERAGES", 13, UI.MUTED))
	var avg := _averages(viewed)
	for key in ["attack", "block", "serve", "receive", "set", "speed"]:
		sv.add_child(UI.stat_row(key.to_upper(), int(avg[key]), accent, 170))

	var roster := UI.panel(Color(0, 0, 0, 0.18), UI.LINE, 12)
	_detail.add_child(roster)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	roster.add_child(rv)
	rv.add_child(UI.bold("STARTING SIX", 13, UI.MUTED))
	var starters := GameData.starters(viewed)
	for i in range(starters.size()):
		rv.add_child(_player_row(starters[i], i + 1, accent))
	rv.add_child(UI.hline())
	rv.add_child(UI.bold("BENCH", 12, UI.MUTED))
	var bench := GameData.bench(viewed)
	var bench_names: Array = []
	for p in bench:
		bench_names.append("#%d %s" % [p["number"], p["name"]])
	rv.add_child(UI.label(UI.join_names(bench_names), 13, UI.MUTED))

func _averages(id: String) -> Dictionary:
	var out := {"attack": 0.0, "block": 0.0, "serve": 0.0, "receive": 0.0, "set": 0.0, "speed": 0.0}
	var starters := GameData.starters(id)
	for p in starters:
		for k in out:
			out[k] += float(p["stats"][k])
	for k in out:
		out[k] = int(round(out[k] / max(1, starters.size())))
	return out

func _player_row(p: Dictionary, pos: int, accent: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var posl := UI.bold(str(pos), 14, UI.MUTED)
	posl.custom_minimum_size = Vector2(16, 0)
	h.add_child(posl)
	var num := UI.bold("#%d" % p["number"], 14, accent)
	num.custom_minimum_size = Vector2(42, 0)
	h.add_child(num)
	var role := UI.chip(p["role"], accent, 10)
	h.add_child(role)
	var name := UI.label(p["name"], 14, UI.TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name)
	var key_stat: String = "attack"
	match p["role"]:
		"S": key_stat = "set"
		"MB": key_stat = "block"
		"L": key_stat = "receive"
		_: key_stat = "attack"
	h.add_child(UI.label("%s %d" % [key_stat.to_upper(), p["stats"][key_stat]], 12, UI.MUTED))
	return h

func _commit() -> void:
	Sfx.play("ui", -10.0, 0.95)
	GameData.options["difficulty"] = difficulty
	GameData.options["sets"] = set_count
	GameData.save_settings()
	if mode == "browse":
		mode = "exhibition"
		step = "away"
		selected_home = viewed
		selected_away = "nekoma" if viewed != "nekoma" else "karasuno"
		viewed = selected_away
		_refresh()
		return
	if mode == "tournament":
		start_tournament.emit(selected_home)
		return
	if step == "home":
		step = "away"
		selected_away = ""
		if selected_home == "karasuno":
			viewed = "nekoma"
		else:
			viewed = "karasuno"
		_refresh()
		return
	if selected_away == "":
		return
	start_match.emit(selected_home, selected_away, {"sets": set_count, "difficulty": difficulty})
