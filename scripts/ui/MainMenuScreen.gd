extends Control

signal navigate(screen: String, arg: Variant)

var _root: VBoxContainer

func _ready() -> void:
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 54)
	margin.add_child(row)

	# ---- Left: title + navigation -----------------------------------------
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)

	left.add_child(UI.label("UNOFFICIAL FAN PROJECT  •  TOKYO 2013", 14, UI.ORANGE))
	left.add_child(UI.spacer(6))
	var title := UI.bold("HAIKYUU!!", 96, UI.TEXT)
	left.add_child(title)
	left.add_child(UI.bold("SPRING TOURNAMENT 2013", 30, UI.GOLD))
	left.add_child(UI.label("The ball never drops. Build the play. Fly higher.", 18, UI.MUTED))
	left.add_child(UI.spacer(26))

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	left.add_child(buttons)
	_button(buttons, "01   QUICK MATCH", "quick", UI.ORANGE)
	_button(buttons, "02   SPRING TOURNAMENT 2013", "tournament", UI.GOLD)
	_button(buttons, "03   TEAM & PLAYER DATA", "teams", UI.CYAN)
	_button(buttons, "04   OPTIONS", "options", UI.BLUE)
	_button(buttons, "05   HOW TO PLAY", "howto", UI.GREEN)
	_button(buttons, "06   CREDITS", "credits", UI.MUTED)
	_button(buttons, "07   QUIT", "quit", UI.RED)

	left.add_child(UI.spacer(14))
	var tour := GameData.tournament
	if not tour.is_empty() and str(tour.get("champion", "")) == "":
		var banner := UI.panel(Color(0.1, 0.14, 0.24, 0.9), Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.5), 10)
		var bh := HBoxContainer.new()
		bh.add_theme_constant_override("separation", 14)
		banner.add_child(bh)
		var team := GameData.team(str(tour.get("team_id", "karasuno")))
		bh.add_child(UI.bold("SPRING TOURNAMENT IN PROGRESS", 15, UI.GOLD))
		bh.add_child(UI.label("%s  •  %s" % [team["name"], GameData.round_name(int(tour.get("round", 0)))], 15, UI.TEXT))
		left.add_child(banner)

	# ---- Right: featured card + controls -----------------------------------
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 16)
	row.add_child(right)

	var feature := UI.panel(Color(0.055, 0.073, 0.13, 0.9), Color(1, 1, 1, 0.08), 18)
	right.add_child(feature)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 14)
	feature.add_child(fv)
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 10)
	fv.add_child(fh)
	fh.add_child(UI.chip("FEATURED MATCH", UI.ORANGE, 13))
	fh.add_child(UI.hspacer())
	fh.add_child(UI.label("TOKYO METROPOLITAN GYMNASIUM", 13, UI.MUTED))
	fv.add_child(UI.hline())
	feature_team(fv, "karasuno", "KARASUNO", "Fly High")
	var vs := HBoxContainer.new()
	vs.add_theme_constant_override("separation", 14)
	fv.add_child(vs)
	vs.add_child(UI.hline())
	vs.add_child(UI.bold("VS", 20, UI.MUTED))
	vs.add_child(UI.hline())
	feature_team(fv, "nekoma", "NEKOMA", "Connect")
	fv.add_child(UI.hline())
	var fdesc := UI.label("\"If you're going to hit it, hit it until it breaks.\"", 16, UI.MUTED)
	fdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fv.add_child(fdesc)

	right.add_child(UI.spacer(2))

	var tips := UI.panel(Color(0.055, 0.073, 0.13, 0.86), Color(1, 1, 1, 0.07), 16)
	right.add_child(tips)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 8)
	tips.add_child(tv)
	tv.add_child(UI.bold("MODERN CONTROLS", 15, UI.CYAN))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 6)
	tv.add_child(grid)
	_kv(grid, "WASD", "Move")
	_kv(grid, "MOUSE", "Aim target zone")
	_kv(grid, "HOLD SPACE", "Charge serve / spike")
	_kv(grid, "Q", "Switch player")
	_kv(grid, "TAB", "Tactics & play call")
	_kv(grid, "E", "Team FLOW ability")
	_kv(grid, "V", "Camera angle")
	_kv(grid, "ESC", "Pause")

	right.add_child(UI.hspacer())
	var footer := UI.label("v0.1  •  Godot 4  •  Inspired by International Volleyball 2009", 12, Color(1, 1, 1, 0.28))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(footer)

func _button(parent: Control, text: String, screen: String, accent: Color) -> void:
	var b := UI.button(text, accent, 20, 50)
	b.pressed.connect(func():
		if GameData.options.get("sfx", true):
			Sfx.play("ui", -12.0, 1.0)
		navigate.emit(screen)
	)
	parent.add_child(b)

func feature_team(parent: Control, id: String, short: String, motto: String) -> void:
	var team := GameData.team(id)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	parent.add_child(h)
	var stripe := ColorRect.new()
	stripe.color = Color.html(team["primary"])
	stripe.custom_minimum_size = Vector2(6, 56)
	h.add_child(stripe)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.bold(short, 26, Color.html(team["primary"])))
	v.add_child(UI.label(motto, 13, UI.MUTED))
	var stars := UI.bold(str(team["overall"]), 34, UI.TEXT)
	stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(stars)

func _kv(parent: Control, key: String, value: String) -> void:
	parent.add_child(UI.bold(key, 13, UI.GOLD))
	parent.add_child(UI.label(value, 13, UI.MUTED))
