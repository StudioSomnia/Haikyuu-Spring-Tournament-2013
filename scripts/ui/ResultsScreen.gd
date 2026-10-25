extends Control

signal rematch
signal navigate(screen: String, arg: Variant)

var result: Dictionary = {}

func _ready() -> void:
	_build()

func _build() -> void:
	var home_id: String = str(result.get("home_id", "karasuno"))
	var away_id: String = str(result.get("away_id", "nekoma"))
	var home := GameData.team(home_id)
	var away := GameData.team(away_id)
	var home_won := bool(result.get("home_won", true))
	var winner := home if home_won else away
	var winner_id := home_id if home_won else away_id
	var accent := Color.html(winner["primary"])

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	root.add_child(top)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	top.add_child(tv)
	tv.add_child(UI.label("MATCH COMPLETE  •  SPRING TOURNAMENT 2013", 13, UI.ORANGE))
	tv.add_child(UI.bold("FINAL RESULT", 38, UI.TEXT))
	top.add_child(UI.hspacer())
	var badge := UI.panel(Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.95), accent, 12)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 0)
	badge.add_child(bv)
	bv.add_child(UI.label("WINNER", 10, UI.MUTED))
	bv.add_child(UI.bold(winner["short"], 22, accent))
	top.add_child(badge)

	root.add_child(UI.hline())

	var hero := UI.panel(Color(accent.r * 0.13, accent.g * 0.13, accent.b * 0.13, 0.9), Color(accent.r, accent.g, accent.b, 0.42), 18)
	root.add_child(hero)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 8)
	hero.add_child(hv)
	hv.add_child(UI.bold("VICTORY" if home_won else "DEFEAT", 44, accent if home_won else UI.RED))
	hv.add_child(UI.label("%s  %d  —  %d  %s" % [home["short"], int(result.get("home_sets", 0)), int(result.get("away_sets", 0)), away["short"]], 28, UI.TEXT))
	var set_line: Array[String] = []
	for s in result.get("sets", []):
		set_line.append("%d-%d" % [int(s[0]), int(s[1])])
	hv.add_child(UI.label("SETS:  " + "   ".join(set_line), 15, UI.MUTED))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	root.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	row.add_child(left)

	var stat_panel := UI.panel(Color(0, 0, 0, 0.20), UI.LINE, 14)
	left.add_child(stat_panel)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 7)
	stat_panel.add_child(sv)
	sv.add_child(UI.bold("TEAM STATISTICS", 14, UI.MUTED))
	var hs: Dictionary = result.get("home_stats", {})
	var as_: Dictionary = result.get("away_stats", {})
	for key in [["kills", "KILLS"], ["blocks", "BLOCKS"], ["aces", "ACES"], ["digs", "DIGS"], ["errors", "ERRORS"]]:
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 12)
		var hn := UI.bold(str(int(hs.get(key[0], 0))), 18, Color.html(home["primary"]))
		hn.custom_minimum_size = Vector2(46, 0)
		hh.add_child(hn)
		var lab := UI.label(key[1], 12, UI.MUTED)
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hh.add_child(lab)
		var an := UI.bold(str(int(as_.get(key[0], 0))), 18, Color.html(away["primary"]))
		an.custom_minimum_size = Vector2(46, 0)
		an.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hh.add_child(an)
		sv.add_child(hh)
	sv.add_child(UI.hline())
	sv.add_child(UI.label("MVP", 10, UI.MUTED))
	var mvp: Dictionary = result.get("mvp", {})
	sv.add_child(UI.bold(str(mvp.get("name", "—")), 24, UI.GOLD))
	sv.add_child(UI.label("%s  •  #%d  •  %s" % [str(mvp.get("team", "")), int(mvp.get("number", 0)), str(mvp.get("line", ""))], 13, UI.MUTED))

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(440, 0)
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	var score_panel := UI.panel(Color(0, 0, 0, 0.20), UI.LINE, 14)
	right.add_child(score_panel)
	var scv := VBoxContainer.new()
	scv.add_theme_constant_override("separation", 4)
	score_panel.add_child(scv)
	scv.add_child(UI.bold("TOP PERFORMERS", 14, UI.MUTED))
	for p in result.get("top_players", []):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var team := GameData.team(str(p.get("team_id", home_id)))
		var stripe := ColorRect.new()
		stripe.color = Color.html(team["primary"])
		stripe.custom_minimum_size = Vector2(4, 24)
		h.add_child(stripe)
		var n := UI.label(str(p.get("name", "")), 14, UI.TEXT)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(UI.label(str(p.get("line", "")), 12, UI.MUTED))
		scv.add_child(h)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	root.add_child(buttons)
	var menu := UI.button("MAIN MENU", UI.MUTED, 18, 48)
	menu.custom_minimum_size = Vector2(220, 48)
	menu.pressed.connect(func(): navigate.emit("menu"))
	buttons.add_child(menu)
	buttons.add_child(UI.hspacer())
	var again := UI.button("REMATCH  ↻", UI.ORANGE, 19, 48)
	again.custom_minimum_size = Vector2(220, 48)
	again.pressed.connect(func(): rematch.emit())
	buttons.add_child(again)
