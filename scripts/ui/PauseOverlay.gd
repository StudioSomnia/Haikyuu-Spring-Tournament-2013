extends CanvasLayer

## Pause board: score, team stats, rotation stamina, and match actions.

signal resume
signal tactics
signal substitute
signal timeout_taken
signal forfeit

var _body: VBoxContainer
var _built := false
var _timeout_btn: Button

func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	_built = true

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.008, 0.012, 0.03, 0.80)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 38)
	add_child(margin)

	var panel := UI.panel(Color(0.03, 0.045, 0.085, 0.98), Color(1, 1, 1, 0.14), 18)
	margin.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	outer.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	hv.add_child(UI.label("MATCH PAUSED  •  SPRING TOURNAMENT 2013", 12, UI.ORANGE))
	hv.add_child(UI.bold("TIMEOUT", 38, UI.TEXT))
	head.add_child(UI.hspacer())
	var resume_btn := UI.button("RESUME  ▶", UI.GREEN, 18, 46)
	resume_btn.custom_minimum_size = Vector2(190, 46)
	resume_btn.pressed.connect(func(): resume.emit())
	head.add_child(resume_btn)

	outer.add_child(UI.hline())
	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	outer.add_child(_body)
	outer.add_child(UI.hline())

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	outer.add_child(foot)
	var tactics_btn := UI.button("TACTICS  TAB", UI.CYAN, 17, 46)
	tactics_btn.custom_minimum_size = Vector2(190, 46)
	tactics_btn.pressed.connect(func(): tactics.emit())
	foot.add_child(tactics_btn)
	var sub_btn := UI.button("SUBSTITUTE", UI.GOLD, 17, 46)
	sub_btn.custom_minimum_size = Vector2(190, 46)
	sub_btn.pressed.connect(func(): substitute.emit())
	foot.add_child(sub_btn)
	_timeout_btn = UI.button("TIMEOUT", UI.ORANGE, 17, 46)
	_timeout_btn.custom_minimum_size = Vector2(190, 46)
	_timeout_btn.pressed.connect(func(): timeout_taken.emit())
	foot.add_child(_timeout_btn)
	foot.add_child(UI.hspacer())
	var quit_btn := UI.button("FORFEIT MATCH", UI.RED, 17, 46)
	quit_btn.custom_minimum_size = Vector2(210, 46)
	quit_btn.pressed.connect(func(): forfeit.emit())
	foot.add_child(quit_btn)

func open_overlay(data: Dictionary) -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_render(data)
	Sfx.play("ui", -10.0, 0.95)

func close_overlay() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _render(data: Dictionary) -> void:
	if not _built:
		return
	UI.clear(_body)
	var hcolor := data.get("home_color", UI.ORANGE) as Color
	var acolor := data.get("away_color", UI.RED) as Color

	var score := HBoxContainer.new()
	score.add_theme_constant_override("separation", 18)
	_body.add_child(score)
	score.add_child(_score_card(str(data.get("home_short", "HOME")), hcolor, int(data.get("home_sets", 0)), int(data.get("home_score", 0)), false))
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(150, 0)
	score.add_child(mid)
	var sl := UI.label("SET " + str(data.get("set_number", 1)), 13, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(sl)
	var vs := UI.bold("VS", 26, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(vs)
	mid.add_child(UI.label("PAUSED", 11, Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER))
	score.add_child(_score_card(str(data.get("away_short", "AWAY")), acolor, int(data.get("away_sets", 0)), int(data.get("away_score", 0)), true))

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	_body.add_child(columns)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	left.add_child(UI.bold("TEAM STATISTICS", 13, UI.MUTED))
	var stats_box := UI.panel(Color(0, 0, 0, 0.22), UI.LINE, 12)
	left.add_child(stats_box)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 5)
	stats_box.add_child(sv)
	var hs: Dictionary = data.get("home_stats", {})
	var as_: Dictionary = data.get("away_stats", {})
	for key in [["kills", "KILLS"], ["blocks", "BLOCKS"], ["aces", "ACES"], ["digs", "DIGS"], ["errors", "ERRORS"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var hn := UI.bold(str(int(hs.get(key[0], 0))), 17, hcolor)
		hn.custom_minimum_size = Vector2(42, 0)
		row.add_child(hn)
		var l := UI.label(key[1], 12, UI.MUTED)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(l)
		var an := UI.bold(str(int(as_.get(key[0], 0))), 17, acolor)
		an.custom_minimum_size = Vector2(42, 0)
		an.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(an)
		sv.add_child(row)

	var tip := UI.panel(Color(UI.CYAN.r * 0.10, UI.CYAN.g * 0.10, UI.CYAN.b * 0.10, 0.85), Color(UI.CYAN.r, UI.CYAN.g, UI.CYAN.b, 0.35), 12)
	left.add_child(tip)
	var tv := VBoxContainer.new()
	tip.add_child(tv)
	tv.add_child(UI.bold("CAPTAIN'S NOTE", 11, UI.CYAN))
	tv.add_child(UI.label(str(data.get("note", "Use the tactics board to change the play call, serve type, block scheme, and reception shape.")), 13, UI.MUTED))

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(470, 0)
	right.add_theme_constant_override("separation", 8)
	columns.add_child(right)
	right.add_child(UI.bold("ROTATION  •  STAMINA", 13, UI.MUTED))
	var roster := UI.panel(Color(0, 0, 0, 0.22), UI.LINE, 12)
	right.add_child(roster)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	roster.add_child(rv)
	var lineup: Array = data.get("lineup", [])
	for i in range(lineup.size()):
		rv.add_child(_player_row(lineup[i], hcolor, i + 1))
	var bench: Array = data.get("bench", [])
	if not bench.is_empty():
		rv.add_child(UI.hline())
		rv.add_child(UI.bold("BENCH", 11, UI.MUTED))
		var names: Array = []
		for b in bench:
			names.append("#%d %s (%s)" % [int(b.get("number", 0)), str(b.get("name", "")), str(b.get("role", ""))])
		var bl := UI.label(UI.join_names(names), 12, UI.MUTED)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rv.add_child(bl)
	if _timeout_btn:
		var remaining := int(data.get("timeouts", 0))
		_timeout_btn.text = "TIMEOUT (%d)" % remaining
		_timeout_btn.disabled = remaining <= 0

func _score_card(short: String, col: Color, sets: int, score: int, right: bool) -> PanelContainer:
	var p := UI.panel(Color(col.r * 0.13, col.g * 0.13, col.b * 0.13, 0.92), Color(col.r, col.g, col.b, 0.45), 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var n := UI.bold(short, 20, col, HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT)
	v.add_child(n)
	var s := UI.bold(str(score), 46, UI.TEXT, HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT)
	v.add_child(s)
	var dots := ""
	for i in range(3):
		dots += "● " if i < sets else "○ "
	v.add_child(UI.label(dots, 12, col, HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT))
	return p

func _player_row(p: Dictionary, accent: Color, pos: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var n := UI.bold("%d." % pos, 12, UI.MUTED)
	n.custom_minimum_size = Vector2(20, 0)
	h.add_child(n)
	var role := UI.chip(str(p.get("role", "")), accent, 9)
	h.add_child(role)
	var name := UI.label(str(p.get("name", "")), 13, UI.TEXT)
	name.custom_minimum_size = Vector2(150, 0)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name)
	var sta := ProgressBar.new()
	sta.min_value = 0
	sta.max_value = maxf(1.0, float(p.get("stamina_max", 100.0)))
	sta.value = float(p.get("stamina", 100.0))
	sta.show_percentage = false
	sta.custom_minimum_size = Vector2(110, 8)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.4)
	var fill := StyleBoxFlat.new()
	var frac := sta.value / sta.max_value
	fill.bg_color = Color("#52d68a") if frac > 0.45 else (Color("#ffc857") if frac > 0.22 else Color("#ff5d6c"))
	sta.add_theme_stylebox_override("background", back)
	sta.add_theme_stylebox_override("fill", fill)
	h.add_child(sta)
	var val := UI.label("%d" % int(sta.value), 11, UI.MUTED)
	val.custom_minimum_size = Vector2(28, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(val)
	return h

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("back"):
		resume.emit()
		get_viewport().set_input_as_handled()
