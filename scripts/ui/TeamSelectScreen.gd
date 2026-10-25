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
var _lineup_layer: Control
var _lineup_body: VBoxContainer
var _lineup_hint: Label
var _lineup_team := ""
var _lineup_sel_kind := ""
var _lineup_sel_id := ""

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
	_detail.add_theme_constant_override("separation", 6)
	detail_scroll.add_child(_detail)

	# Footer ---------------------------------------------------------------
	root.add_child(UI.hline())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 16)
	root.add_child(foot)
	_hint = UI.label("", 14, UI.MUTED)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_hint)
	var lineup_btn := UI.button("EDIT LINEUP", UI.CYAN, 16, 50)
	lineup_btn.custom_minimum_size = Vector2(190, 50)
	lineup_btn.pressed.connect(func(): _open_lineup_editor(viewed))
	foot.add_child(lineup_btn)
	_play_btn = UI.button("PLAY MATCH  →", UI.ORANGE, 20, 50)
	_play_btn.custom_minimum_size = Vector2(260, 50)
	_play_btn.pressed.connect(_commit)
	foot.add_child(_play_btn)

	_build_lineup_layer()

func _build_lineup_layer() -> void:
	_lineup_layer = Control.new()
	_lineup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lineup_layer.visible = false
	add_child(_lineup_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.008, 0.02, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_lineup_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lineup_layer.add_child(center)
	var panel := UI.panel(Color(0.03, 0.05, 0.095, 0.99), Color(UI.CYAN.r, UI.CYAN.g, UI.CYAN.b, 0.35), 16)
	panel.custom_minimum_size = Vector2(1040, 620)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	outer.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	hv.add_child(UI.label("STARTING LINEUP", 12, UI.CYAN))
	hv.add_child(UI.bold("CHOOSE YOUR SIX", 28, UI.TEXT))
	head.add_child(UI.hspacer())
	var close_btn := UI.small_button("CLOSE  ✕", UI.MUTED)
	close_btn.pressed.connect(_close_lineup_editor)
	head.add_child(close_btn)

	outer.add_child(UI.hline())
	_lineup_body = VBoxContainer.new()
	_lineup_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lineup_body.add_theme_constant_override("separation", 10)
	outer.add_child(_lineup_body)
	outer.add_child(UI.hline())

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	outer.add_child(foot)
	_lineup_hint = UI.label("Pick a starter, then pick the player who should replace them. Pick two starters to change their rotation order.", 13, UI.MUTED)
	_lineup_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lineup_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_child(_lineup_hint)
	var reset_btn := UI.small_button("RESET TO DEFAULT", UI.GOLD)
	reset_btn.pressed.connect(_reset_lineup_editor)
	foot.add_child(reset_btn)
	var done_btn := UI.button("DONE", UI.GREEN, 17, 42)
	done_btn.custom_minimum_size = Vector2(150, 42)
	done_btn.pressed.connect(_close_lineup_editor)
	foot.add_child(done_btn)

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
	av.add_theme_constant_override("separation", 4)
	ab.add_child(av)
	av.add_child(UI.chip("FLOW ABILITY", UI.GOLD, 11))
	av.add_child(UI.bold(t["ability_name"], 22, UI.GOLD))
	var desc := UI.label(t["ability_desc"], 14, UI.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	av.add_child(desc)

	var stats := UI.panel(Color(0, 0, 0, 0.22), UI.LINE, 12)
	_detail.add_child(stats)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 3)
	stats.add_child(sv)
	sv.add_child(UI.bold("STARTER AVERAGES", 13, UI.MUTED))
	var avg := _averages(viewed)
	for key in ["attack", "block", "serve", "receive", "set", "speed"]:
		sv.add_child(UI.stat_row(key.to_upper(), int(avg[key]), accent, 170))

	var roster := UI.panel(Color(0, 0, 0, 0.18), UI.LINE, 12)
	_detail.add_child(roster)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 2)
	roster.add_child(rv)
	rv.add_child(UI.bold("STARTING SIX", 13, UI.MUTED))
	var starters := GameData.starters(viewed)
	for i in range(starters.size()):
		rv.add_child(_player_row(starters[i], i + 1, accent))

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
	h.add_theme_constant_override("separation", 6)
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

func _open_lineup_editor(team_id: String) -> void:
	_lineup_team = team_id
	_lineup_sel_kind = ""
	_lineup_sel_id = ""
	_lineup_layer.visible = true
	_refresh_lineup_editor()
	Sfx.play("ui", -12.0, 1.05)

func _close_lineup_editor() -> void:
	_lineup_layer.visible = false
	_build_detail()
	Sfx.play("ui", -12.0, 0.95)

func _refresh_lineup_editor() -> void:
	if not _lineup_body or _lineup_team == "":
		return
	UI.clear(_lineup_body)
	var t := GameData.team(_lineup_team)
	var accent := Color.html(str(t["primary"]))
	var ids := GameData.lineup_ids(_lineup_team)
	var by_id := {}
	for p in t["players"]:
		by_id[str(p.get("id", ""))] = p

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	_lineup_body.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(500, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 5)
	columns.add_child(left)
	left.add_child(UI.bold("ON COURT  •  P1 → P6", 13, UI.MUTED))
	for i in range(ids.size()):
		var p: Dictionary = by_id.get(ids[i], {})
		var b := _lineup_button(_lineup_row_text(i + 1, p, true), accent, i)
		if _lineup_sel_kind == "starter" and _lineup_sel_id == ids[i]:
			b.add_theme_color_override("font_color", UI.GOLD)
			b.modulate = Color(1.0, 1.0, 1.0, 1.0)
		b.pressed.connect(_on_lineup_starter.bind(i))
		left.add_child(b)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(460, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 5)
	columns.add_child(right)
	right.add_child(UI.bold("BENCH  •  AVAILABLE", 13, UI.MUTED))
	var available := 0
	for p in t["players"]:
		var pid := str(p.get("id", ""))
		if ids.has(pid):
			continue
		var is_libero := str(p.get("role", "")) == "L"
		var b2 := _lineup_button(_lineup_row_text(0, p, false), UI.MUTED if is_libero else accent, -1)
		if is_libero:
			b2.disabled = true
			b2.text = "LIBERO  •  #%d %s  •  BENCH (UNAVAILABLE)" % [int(p.get("number", 0)), str(p.get("name", ""))]
		else:
			available += 1
			if _lineup_sel_kind == "bench" and _lineup_sel_id == pid:
				b2.add_theme_color_override("font_color", UI.GOLD)
			b2.pressed.connect(_on_lineup_bench.bind(pid))
		right.add_child(b2)
	if available == 0:
		right.add_child(UI.label("No eligible bench players.", 13, UI.MUTED))

func _lineup_button(text: String, color: Color, _idx: int) -> Button:
	var b := UI.button(text, color, 14, 42)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 42)
	return b

func _lineup_row_text(pos: int, p: Dictionary, starter: bool) -> String:
	if p.is_empty():
		return "EMPTY"
	var prefix := "P%d" % pos if starter else "BENCH"
	var key := "ATK"
	var val := int(p.get("stats", {}).get("attack", 0))
	match str(p.get("role", "")):
		"S":
			key = "SET"
			val = int(p["stats"]["set"])
		"MB":
			key = "BLK"
			val = int(p["stats"]["block"])
		"L":
			key = "REC"
			val = int(p["stats"]["receive"])
	return "%-5s  #%d  %-15s  %-3s  %s %d" % [prefix, int(p.get("number", 0)), str(p.get("name", "")), str(p.get("role", "")), key, val]

func _on_lineup_starter(index: int) -> void:
	var ids := GameData.lineup_ids(_lineup_team)
	if index < 0 or index >= ids.size():
		return
	var clicked := ids[index]
	if _lineup_sel_kind == "":
		_lineup_sel_kind = "starter"
		_lineup_sel_id = clicked
		_lineup_hint.text = "Starter selected. Pick the replacement on the bench, or pick another starter to swap their rotation spots."
	elif _lineup_sel_kind == "bench":
		var incoming := _lineup_sel_id
		if incoming == "":
			return
		ids[index] = incoming
		if GameData.set_lineup(_lineup_team, ids):
			_lineup_hint.text = "Lineup updated. The new player is now P%d." % (index + 1)
		else:
			_lineup_hint.text = "That swap is not valid."
		_lineup_sel_kind = ""
		_lineup_sel_id = ""
	elif _lineup_sel_id == clicked:
		_lineup_sel_kind = ""
		_lineup_sel_id = ""
		_lineup_hint.text = "Selection cleared."
	else:
		var other := ids.find(_lineup_sel_id)
		if other >= 0:
			ids[other] = clicked
			ids[index] = _lineup_sel_id
			if GameData.set_lineup(_lineup_team, ids):
				_lineup_hint.text = "Rotation order updated: P%d and P%d swapped." % [other + 1, index + 1]
		_lineup_sel_kind = ""
		_lineup_sel_id = ""
	_refresh_lineup_editor()
	_build_detail()

func _on_lineup_bench(pid: String) -> void:
	if _lineup_sel_kind == "starter":
		var ids := GameData.lineup_ids(_lineup_team)
		var idx := ids.find(_lineup_sel_id)
		if idx >= 0:
			ids[idx] = pid
			if GameData.set_lineup(_lineup_team, ids):
				_lineup_hint.text = "Lineup updated: the bench player steps into P%d." % (idx + 1)
			else:
				_lineup_hint.text = "That swap is not valid."
			_lineup_sel_kind = ""
			_lineup_sel_id = ""
	else:
		_lineup_sel_kind = "bench"
		_lineup_sel_id = pid
		_lineup_hint.text = "Bench player selected. Now pick the starter they should replace, or pick another bench player."
	_refresh_lineup_editor()
	_build_detail()

func _reset_lineup_editor() -> void:
	GameData.reset_lineup(_lineup_team)
	_lineup_sel_kind = ""
	_lineup_sel_id = ""
	_lineup_hint.text = "Default lineup restored. Liberos remain on the bench."
	_refresh_lineup_editor()
	_build_detail()

func _input(event: InputEvent) -> void:
	if _lineup_layer and _lineup_layer.visible and event.is_action_pressed("back"):
		_close_lineup_editor()
		get_viewport().set_input_as_handled()

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
