class_name MatchHUD
extends CanvasLayer

## Broadcast-style match overlay: scoreboard, player card, prompts, flow,
## tactics readout, commentary, reticle, and charge bar.

const ReticleScript := preload("res://scripts/ui/Reticle.gd")
const PowerBarScript := preload("res://scripts/ui/PowerBar.gd")

var root: Control
var home_color := Color("#ff7a1a")
var away_color := Color("#d81f35")
var home_short := "KARASUNO"
var away_short := "NEKOMA"

var score_home: Label
var score_away: Label
var sets_home: Label
var sets_away: Label
var set_label: Label
var serve_home: Label
var serve_away: Label
var phase_label: Label
var prompt_label: Label
var commentary_label: Label
var player_name: Label
var player_meta: Label
var player_trait: Label
var stamina: ProgressBar
var flow: ProgressBar
var flow_value: Label
var flow_ready: Label
var play_chip: Label
var serve_chip: Label
var block_chip: Label
var recv_chip: Label
var camera_label: Label
var rally_label: Label
var banner_title: Label
var banner_sub: Label
var banner_box: VBoxContainer
var power: Control
var reticle: Control
var hint: Label
var _banner_tween: Tween
var _comment_tween: Tween
var _flash: ColorRect

func setup(home: Dictionary, away: Dictionary) -> void:
	home_color = Color.html(str(home["primary"]))
	away_color = Color.html(str(away["primary"]))
	home_short = str(home["short"])
	away_short = str(away["short"])
	_build()

func _build() -> void:
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)

	_build_scoreboard()
	_build_player_card()
	_build_flow_panel()
	_build_prompt()
	_build_banner()
	_build_commentary()
	_build_top_corners()

	reticle = ReticleScript.new()
	root.add_child(reticle)
	reticle.visible = false

	power = PowerBarScript.new()
	power.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	power.offset_left = -280
	power.offset_right = 280
	power.offset_top = -98
	power.offset_bottom = -60
	root.add_child(power)

func _ignore(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _panel_style(p: PanelContainer, border: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.035, 0.05, 0.09, 0.88)
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = border
	s.content_margin_left = 16
	s.content_margin_top = 9
	s.content_margin_right = 16
	s.content_margin_bottom = 9
	p.add_theme_stylebox_override("panel", s)

func _build_scoreboard() -> void:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	p.offset_left = -320
	p.offset_right = 320
	p.offset_top = 14
	p.offset_bottom = 96
	_ignore(p)
	_panel_style(p, Color(1, 1, 1, 0.14))
	root.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var home_v := VBoxContainer.new()
	home_v.custom_minimum_size = Vector2(220, 0)
	home_v.add_theme_constant_override("separation", -2)
	h.add_child(home_v)
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 8)
	home_v.add_child(hh)
	var hstripe := ColorRect.new()
	hstripe.color = home_color
	hstripe.custom_minimum_size = Vector2(4, 30)
	hh.add_child(hstripe)
	var hn := UI.bold(home_short, 17, home_color)
	hn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(hn)
	score_home = UI.bold("0", 44, UI.TEXT)
	score_home.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	home_v.add_child(score_home)
	sets_home = UI.label("○ ○ ○", 13, home_color)
	home_v.add_child(sets_home)

	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(160, 0)
	mid.add_theme_constant_override("separation", 0)
	h.add_child(mid)
	set_label = UI.bold("SET 1", 13, UI.GOLD)
	set_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(set_label)
	var vs := UI.bold("VS", 22, UI.MUTED)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(vs)
	rally_label = UI.label("RALLY 0", 10, Color(1, 1, 1, 0.35))
	rally_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(rally_label)
	var serve_row := HBoxContainer.new()
	serve_row.add_theme_constant_override("separation", 4)
	serve_row.alignment = BoxContainer.ALIGNMENT_CENTER
	serve_home = UI.bold("●", 12, home_color)
	serve_away = UI.bold("●", 12, away_color)
	serve_home.modulate.a = 0.0
	serve_away.modulate.a = 0.0
	serve_row.add_child(serve_home)
	var sl := UI.label("SERVE", 9, UI.MUTED)
	serve_row.add_child(sl)
	serve_row.add_child(serve_away)
	mid.add_child(serve_row)

	var away_v := VBoxContainer.new()
	away_v.custom_minimum_size = Vector2(220, 0)
	away_v.add_theme_constant_override("separation", -2)
	h.add_child(away_v)
	var ah := HBoxContainer.new()
	ah.add_theme_constant_override("separation", 8)
	away_v.add_child(ah)
	score_away = UI.bold("0", 44, UI.TEXT)
	score_away.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ah.add_child(score_away)
	var an := UI.bold(away_short, 17, away_color)
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	an.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ah.add_child(an)
	var astripe := ColorRect.new()
	astripe.color = away_color
	astripe.custom_minimum_size = Vector2(4, 30)
	ah.add_child(astripe)
	sets_away = UI.label("○ ○ ○", 13, away_color)
	sets_away.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	away_v.add_child(sets_away)

func _build_player_card() -> void:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	p.offset_left = 20
	p.offset_right = 330
	p.offset_top = -156
	p.offset_bottom = -22
	_ignore(p)
	_panel_style(p, Color(1, 1, 1, 0.12))
	root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	player_name = UI.bold("—", 22, UI.TEXT)
	player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(player_name)
	player_trait = UI.bold("TRAIT", 10, UI.CYAN)
	top.add_child(player_trait)
	player_meta = UI.label("", 12, UI.MUTED)
	v.add_child(player_meta)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 8)
	v.add_child(sh)
	sh.add_child(UI.label("STAMINA", 10, UI.MUTED))
	stamina = UI.bar(100, Color("#52d68a"), 190, 8)
	stamina.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.add_child(stamina)

func _build_flow_panel() -> void:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	p.offset_left = -350
	p.offset_right = -20
	p.offset_top = -166
	p.offset_bottom = -22
	_ignore(p)
	_panel_style(p, Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.28))
	root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	top.add_child(UI.bold("TEAM FLOW", 14, UI.GOLD))
	top.add_child(UI.hspacer())
	flow_value = UI.bold("0", 14, UI.MUTED)
	top.add_child(flow_value)
	flow = UI.bar(0, UI.GOLD, 300, 10)
	v.add_child(flow)
	flow_ready = UI.bold("E  •  SIGNATURE ABILITY READY", 12, UI.GOLD)
	flow_ready.visible = false
	v.add_child(flow_ready)
	v.add_child(UI.hline())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 2)
	v.add_child(grid)
	play_chip = _chip_row(grid, "PLAY", "WING")
	serve_chip = _chip_row(grid, "SERVE", "OVERHAND")
	block_chip = _chip_row(grid, "BLOCK", "READ")
	recv_chip = _chip_row(grid, "RECEIVE", "BALANCED")
	camera_label = UI.label("CAM  DYNAMIC", 10, Color(1, 1, 1, 0.35))
	camera_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(camera_label)

func _chip_row(grid: Control, key: String, value: String) -> Label:
	grid.add_child(UI.label(key, 10, UI.MUTED))
	var l := UI.bold(value, 11, UI.TEXT)
	grid.add_child(l)
	return l

func _build_prompt() -> void:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	p.offset_left = -300
	p.offset_right = 300
	p.offset_top = -196
	p.offset_bottom = -110
	_ignore(p)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.025, 0.035, 0.065, 0.80)
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.content_margin_left = 18
	s.content_margin_top = 7
	s.content_margin_right = 18
	s.content_margin_bottom = 7
	p.add_theme_stylebox_override("panel", s)
	root.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	phase_label = UI.bold("SERVE", 13, UI.ORANGE)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(phase_label)
	prompt_label = UI.bold("HOLD SPACE TO SERVE", 20, UI.TEXT)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(prompt_label)
	hint = UI.label("AUTO POSITIONING  •  SPACE RECEIVE / JUMP  •  CTRL DIVE  •  TAB TACTICS", 10, Color(1, 1, 1, 0.42))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)

func _build_banner() -> void:
	banner_box = VBoxContainer.new()
	banner_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner_box.offset_left = -560
	banner_box.offset_right = 560
	banner_box.offset_top = 208
	banner_box.offset_bottom = 350
	banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_box)
	banner_title = UI.bold("", 58, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	banner_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	banner_title.add_theme_constant_override("outline_size", 8)
	banner_box.add_child(banner_title)
	banner_sub = UI.bold("", 20, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	banner_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	banner_sub.add_theme_constant_override("outline_size", 5)
	banner_box.add_child(banner_sub)
	banner_box.modulate.a = 0.0

func _build_commentary() -> void:
	commentary_label = UI.bold("", 15, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	commentary_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	commentary_label.offset_left = -500
	commentary_label.offset_right = 500
	commentary_label.offset_top = 106
	commentary_label.offset_bottom = 138
	commentary_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	commentary_label.add_theme_constant_override("outline_size", 6)
	commentary_label.modulate.a = 0.0
	root.add_child(commentary_label)

func _build_top_corners() -> void:
	var tl := VBoxContainer.new()
	tl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tl.offset_left = 22
	tl.offset_right = 330
	tl.offset_top = 18
	tl.offset_bottom = 80
	tl.add_theme_constant_override("separation", 0)
	root.add_child(tl)
	tl.add_child(UI.label("HAIKYUU!! SPRING TOURNAMENT 2013", 11, UI.ORANGE))
	tl.add_child(UI.label("CENTER COURT  •  TOKYO", 10, Color(1, 1, 1, 0.38)))
	var tr := VBoxContainer.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tr.offset_left = -340
	tr.offset_right = -22
	tr.offset_top = 18
	tr.offset_bottom = 80
	tr.add_theme_constant_override("separation", 0)
	root.add_child(tr)
	var t1 := UI.label("MATCH FEED  •  LIVE", 11, UI.RED)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(t1)
	var t2 := UI.label("DIFFICULTY  NORMAL", 10, Color(1, 1, 1, 0.38))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tr.add_child(t2)

# ---------------------------------------------------------------------------
# Public updates
# ---------------------------------------------------------------------------

func update_score(h_sets: int, a_sets: int, h_score: int, a_score: int, serving: int, set_num: int, sets_to_win: int) -> void:
	if not score_home:
		return
	score_home.text = str(h_score)
	score_away.text = str(a_score)
	set_label.text = "SET " + str(set_num)
	sets_home.text = _dots(h_sets, sets_to_win)
	sets_away.text = _dots(a_sets, sets_to_win)
	serve_home.modulate.a = 1.0 if serving == 0 else 0.0
	serve_away.modulate.a = 1.0 if serving == 1 else 0.0

func _dots(won: int, total: int) -> String:
	var out: Array[String] = []
	for i in range(total):
		out.append("●" if i < won else "○")
	return "  ".join(out)

func set_phase(text: String, color: Color = UI.ORANGE) -> void:
	if phase_label:
		phase_label.text = text
		phase_label.add_theme_color_override("font_color", color)

func set_prompt(text: String, sub: String = "") -> void:
	if prompt_label:
		prompt_label.text = text
	if hint and sub != "":
		hint.text = sub

func set_player_info(p: Dictionary, current_stamina: float, role_override: String = "") -> void:
	if not player_name:
		return
	var names := str(p.get("name", "—")).split(" ")
	player_name.text = "#%d  %s" % [int(p.get("number", 0)), names[names.size() - 1].to_upper()]
	var role := role_override if role_override != "" else str(p.get("role", ""))
	player_meta.text = "%s  •  %s  •  HEIGHT %dcm  •  ATK %d  BLK %d  REC %d" % [
		role, str(p.get("trait", "")).replace("_", " ").to_upper(), int(p.get("height", 180)),
		int(p["stats"]["attack"]), int(p["stats"]["block"]), int(p["stats"]["receive"])
	]
	player_trait.text = str(p.get("trait", "")).replace("_", " ").to_upper()
	if stamina:
		stamina.value = current_stamina

func update_stamina(v: float) -> void:
	if stamina:
		stamina.value = v

func set_flow(v: float, ready: bool) -> void:
	if flow:
		flow.value = v
	if flow_value:
		flow_value.text = "%d / 100" % int(v)
	if flow_ready:
		flow_ready.visible = ready

func set_tactics(play: String, serve: String, block: String, receive: String) -> void:
	if play_chip:
		play_chip.text = play
	if serve_chip:
		serve_chip.text = serve
	if block_chip:
		block_chip.text = block
	if recv_chip:
		recv_chip.text = receive

func set_power(v: float, lo: float, hi: float, caption: String, color: Color, show_it: bool = true) -> void:
	if power:
		power.setup(v, lo, hi, caption, color, show_it)

func clear_power() -> void:
	if power:
		power.clear()

func set_reticle(pos: Vector2, valid: bool, color: Color) -> void:
	if reticle:
		reticle.set_state(pos, valid, color)

func hide_reticle() -> void:
	if reticle:
		reticle.visible = false

func set_reticle_idle(pos: Vector2) -> void:
	if reticle:
		reticle.set_idle(pos)

func set_camera(text: String) -> void:
	if camera_label:
		camera_label.text = "CAM  " + text

func set_rally(n: int) -> void:
	if rally_label:
		rally_label.text = "RALLY " + str(n)

func show_banner(title: String, subtitle: String, color: Color = UI.GOLD, hold: float = 1.5) -> void:
	if not banner_title:
		return
	banner_title.text = title
	banner_title.add_theme_color_override("font_color", color)
	banner_sub.text = subtitle
	banner_box.modulate.a = 0.0
	banner_box.scale = Vector2(0.92, 0.92)
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(banner_box, "modulate:a", 1.0, 0.18)
	_banner_tween.tween_property(banner_box, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.set_parallel(false)
	_banner_tween.tween_interval(hold)
	_banner_tween.tween_property(banner_box, "modulate:a", 0.0, 0.35)

func flash(color: Color = Color(1, 1, 1, 0.25)) -> void:
	if _flash:
		_flash.color = color
		var tw := create_tween()
		tw.tween_property(_flash, "color:a", 0.0, 0.30)

func commentary(text: String, color: Color = UI.TEXT, hold: float = 3.4) -> void:
	if not commentary_label:
		return
	commentary_label.text = text
	commentary_label.add_theme_color_override("font_color", color)
	commentary_label.modulate.a = 0.0
	if _comment_tween and _comment_tween.is_valid():
		_comment_tween.kill()
	_comment_tween = create_tween()
	_comment_tween.tween_property(commentary_label, "modulate:a", 1.0, 0.18)
	_comment_tween.tween_interval(hold)
	_comment_tween.tween_property(commentary_label, "modulate:a", 0.0, 0.5)

func set_difficulty(text: String) -> void:
	var labels := root.find_children("*", "Label", true, false)
	for l in labels:
		if str(l.text).begins_with("DIFFICULTY"):
			l.text = "DIFFICULTY  " + text
			break
