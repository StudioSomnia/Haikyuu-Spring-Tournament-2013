extends Control

signal play_match(opponent_id: String)
signal navigate(screen: String, arg: Variant)
signal new_tournament

func _ready() -> void:
	_build()

func _build() -> void:
	var tour := GameData.tournament
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	root.add_child(head)
	var back := UI.small_button("←  MENU", UI.MUTED)
	back.custom_minimum_size = Vector2(120, 40)
	back.pressed.connect(func(): navigate.emit("menu"))
	head.add_child(back)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	head.add_child(tv)
	tv.add_child(UI.bold("SPRING TOURNAMENT 2013", 36, UI.TEXT))
	tv.add_child(UI.label("TOKYO METROPOLITAN GYMNASIUM  •  SINGLE ELIMINATION", 13, UI.ORANGE))
	head.add_child(UI.hspacer())
	if tour.is_empty():
		root.add_child(UI.label("No tournament in progress.", 18, UI.MUTED))
		return
	var team := GameData.team(str(tour["team_id"]))
	var badge := UI.panel(Color(team["primary"]).darkened(0.72), Color.html(team["primary"]), 10)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 0)
	badge.add_child(bv)
	bv.add_child(UI.label("YOUR SCHOOL", 10, UI.MUTED))
	bv.add_child(UI.bold(team["short"], 19, Color.html(team["primary"])))
	head.add_child(badge)

	root.add_child(UI.hline())

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 22)
	root.add_child(content)

	var bracket := UI.panel(Color(0, 0, 0, 0.16), UI.LINE, 14)
	bracket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bracket.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bracket)
	var bracket_margin := MarginContainer.new()
	bracket_margin.add_theme_constant_override("margin_left", 16)
	bracket_margin.add_theme_constant_override("margin_right", 16)
	bracket_margin.add_theme_constant_override("margin_top", 12)
	bracket_margin.add_theme_constant_override("margin_bottom", 12)
	bracket.add_child(bracket_margin)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	bracket_margin.add_child(cols)
	for r in range(3):
		cols.add_child(_round_column(r))

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(360, 0)
	side.add_theme_constant_override("separation", 14)
	content.add_child(side)
	_side_panel(side)

	root.add_child(UI.hline())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	root.add_child(foot)
	var status := "ROUND: " + GameData.round_name(int(tour.get("round", 0)))
	if str(tour.get("champion", "")) != "":
		status = "COMPLETE  •  CHAMPION: " + GameData.team(str(tour["champion"]))["short"]
	foot.add_child(UI.label(status, 13, UI.MUTED))
	foot.add_child(UI.hspacer())
	var newb := UI.small_button("NEW TOURNAMENT", UI.RED)
	newb.pressed.connect(func():
		GameData.clear_tournament()
		new_tournament.emit()
	)
	foot.add_child(newb)

func _round_column(r: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var label := UI.bold(GameData.round_name(r), 13, UI.MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(label)
	col.add_child(UI.hline())
	var tour := GameData.tournament
	var matches: Array = []
	if r < tour.get("history", []).size():
		matches = tour["history"][r]
	elif r == int(tour.get("round", 0)):
		matches = tour.get("matches", [])
	var expected: int = [4, 2, 1][r]
	var top_space: int = [0, 64, 128][r]
	col.add_child(UI.spacer(top_space))
	for i in range(expected):
		if i < matches.size():
			col.add_child(_match_card(matches[i], r))
		else:
			col.add_child(_tbd_card())
		col.add_child(UI.spacer([12, 54, 0][r]))
	col.add_child(UI.hspacer())
	return col

func _match_card(m: Dictionary, round_index: int) -> PanelContainer:
	var a := GameData.team(str(m["a"]))
	var b := GameData.team(str(m["b"]))
	var pid: String = GameData.tournament.get("team_id", "")
	var live: bool = not bool(m["played"]) and round_index == int(GameData.tournament.get("round", 0)) and (m["a"] == pid or m["b"] == pid)
	var accent := Color(1, 1, 1, 0.10)
	if live:
		accent = UI.ORANGE
	elif bool(m["played"]):
		accent = Color(0.4, 0.8, 0.6, 0.35)
	var p := UI.panel(Color(0.02, 0.03, 0.06, 0.55), accent, 9)
	p.custom_minimum_size = Vector2(0, 72)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	v.add_child(_team_line(a, int(m.get("score_a", 0)), m.get("winner", "") == m["a"], m.get("played", false)))
	v.add_child(_team_line(b, int(m.get("score_b", 0)), m.get("winner", "") == m["b"], m.get("played", false)))
	if live:
		var tag := UI.bold("YOUR MATCH", 9, UI.ORANGE)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_child(tag)
	return p

func _team_line(t: Dictionary, score: int, won: bool, played: bool) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var stripe := ColorRect.new()
	stripe.color = Color.html(t["primary"])
	stripe.custom_minimum_size = Vector2(4, 20)
	h.add_child(stripe)
	var n := UI.bold(t["short"], 13, UI.GOLD if won else (UI.TEXT if played else UI.MUTED))
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	h.add_child(n)
	h.add_child(UI.bold(str(score) if played else "–", 15, UI.GOLD if won else UI.MUTED))
	return h

func _tbd_card() -> PanelContainer:
	var p := UI.panel(Color(0, 0, 0, 0.18), Color(1, 1, 1, 0.05), 8)
	p.custom_minimum_size = Vector2(0, 72)
	var l := UI.label("TBD", 13, Color(1, 1, 1, 0.2), HORIZONTAL_ALIGNMENT_CENTER)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func _side_panel(parent: Control) -> void:
	var tour := GameData.tournament
	var champion: String = str(tour.get("champion", ""))
	var eliminated: bool = bool(tour.get("eliminated", false))
	if champion != "":
		var t := GameData.team(champion)
		var card := UI.panel(Color(0.12, 0.09, 0.02, 0.92), UI.GOLD, 16)
		parent.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		card.add_child(v)
		v.add_child(UI.bold("CHAMPIONS", 13, UI.GOLD))
		v.add_child(UI.bold(t["short"], 40, Color.html(t["primary"])))
		v.add_child(UI.label(t["name"], 16, UI.TEXT))
		v.add_child(UI.label("Spring Tournament 2013 Champions", 13, UI.MUTED))
		if champion == str(tour["team_id"]):
			v.add_child(UI.spacer(10))
			v.add_child(UI.bold("YOU DID IT. FLY HIGH.", 20, UI.GOLD))
		var menu := UI.button("MAIN MENU", UI.GOLD, 18, 46)
		menu.pressed.connect(func(): navigate.emit("menu"))
		parent.add_child(menu)
		return

	var opp_id := GameData.current_opponent()
	if opp_id == "":
		parent.add_child(UI.label("The bracket is being prepared.", 16, UI.MUTED))
		return
	var opp := GameData.team(opp_id)
	var card := UI.panel(Color(opp["primary"]).darkened(0.78), Color.html(opp["primary"]), 16)
	parent.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UI.chip("NEXT OPPONENT", UI.ORANGE, 12))
	v.add_child(UI.bold(opp["short"], 36, Color.html(opp["primary"])))
	v.add_child(UI.label(opp["name"] + "  •  OVR " + str(opp["overall"]), 14, UI.MUTED))
	v.add_child(UI.hline())
	v.add_child(UI.label("SIGNATURE", 10, UI.MUTED))
	v.add_child(UI.bold(opp["ability_name"], 17, UI.GOLD))
	var d := UI.label(opp["ability_desc"], 12, UI.MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	v.add_child(UI.hline())
	v.add_child(UI.label("KEY PLAYER", 10, UI.MUTED))
	var key := _key_player(opp_id)
	v.add_child(UI.bold("%s  #%d  %s" % [key["name"], key["number"], key["role"]], 15, UI.TEXT))

	var play := UI.button("PLAY MATCH  →", UI.ORANGE, 21, 54)
	play.pressed.connect(func():
		Sfx.play("whistle", -8.0, 1.0)
		play_match.emit(opp_id)
	)
	parent.add_child(play)
	var note := UI.label("Win to advance. Lose and the tournament ends for your school.", 12, UI.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(note)

func _key_player(team_id: String) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1.0
	for p in GameData.starters(team_id):
		var s: Dictionary = p["stats"]
		var score := float(s["attack"] + s["block"] + s["serve"] + s["receive"] + s["set"]) / 5.0
		if score > best_score:
			best_score = score
			best = p
	return best
