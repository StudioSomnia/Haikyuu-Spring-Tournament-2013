extends Control

signal back

var _list: VBoxContainer

func _ready() -> void:
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	root.add_child(head)
	var b := UI.small_button("←  BACK", UI.MUTED)
	b.custom_minimum_size = Vector2(120, 40)
	b.pressed.connect(func(): back.emit())
	head.add_child(b)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	head.add_child(tv)
	tv.add_child(UI.bold("OPTIONS", 38, UI.TEXT))
	tv.add_child(UI.label("Tune the simulation to your taste.", 14, UI.MUTED))
	root.add_child(UI.hline())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	_section("MATCH")
	_option("Difficulty", "AI reaction speed, accuracy, and error rate.", "difficulty", GameData.DIFFICULTY_NAMES, GameData.difficulty_name())
	_option("Sets per match", "Best-of format. A fifth set is played to 15.", "sets", [1, 3, 5], str(GameData.options["sets"]))
	_option("Camera angle", "You can also cycle cameras in-match with V.", "camera", GameData.CAMERA_NAMES, GameData.CAMERA_NAMES[int(GameData.options["camera"])])
	_toggle("Sound effects", "Procedural impacts, whistles, and crowd reactions.", "sfx", bool(GameData.options["sfx"]))

	_section("ASSISTS")
	_toggle("Auto receive", "The nearest receiver plays the ball automatically.", "auto_receive", bool(GameData.options["auto_receive"]))
	_toggle("Auto set", "If you do not set in time, the setter plays a safe ball.", "auto_set", bool(GameData.options["auto_set"]))
	_toggle("Auto attack", "The selected attacker swings even without input.", "auto_attack", bool(GameData.options["auto_attack"]))
	_toggle("Tactics slow-motion", "Opening the tactics board briefly slows the rally.", "tactics_slowmo", bool(GameData.options["tactics_slowmo"]))

	_section("CONTROLS")
	var help := UI.panel(Color(0, 0, 0, 0.22), UI.LINE, 12)
	_root_add(help)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	help.add_child(hv)
	var rows := [
		["AUTO", "Players move into position and play their assignments"],
		["MOUSE / RIGHT STICK", "Aim at a court zone"],
		["SPACE / A", "Receive, jump, spike, block, or charge a serve"],
		["CTRL or C / B", "Dive toward the drop point"],
		["1–3", "Serve type while serving"],
		["1–4", "Block scheme while defending"],
		["1–5", "Attack play after the receive"],
		["Q / X", "Switch active player"],
		["E / Y", "Activate team FLOW ability when charged"],
		["TAB / BACK", "Open tactics board"],
		["V / RB", "Cycle camera"],
		["ESC / START", "Pause"]
	]
	for r in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		var k := UI.bold(r[0], 13, UI.GOLD)
		k.custom_minimum_size = Vector2(220, 0)
		h.add_child(k)
		h.add_child(UI.label(r[1], 13, UI.MUTED))
		hv.add_child(h)

	root.add_child(UI.hline())
	var foot := HBoxContainer.new()
	foot.add_child(UI.label("Settings save automatically to user://settings.cfg", 12, UI.MUTED))
	foot.add_child(UI.hspacer())
	var reset := UI.small_button("RESET DEFAULTS", UI.RED)
	reset.pressed.connect(_reset)
	foot.add_child(reset)
	root.add_child(foot)

func _root_add(n: Node) -> void:
	_list.add_child(n)

func _section(text: String) -> void:
	_list.add_child(UI.spacer(12))
	_list.add_child(UI.bold(text, 13, UI.ORANGE))
	_list.add_child(UI.hline())

func _option(title: String, desc: String, key: String, values: Array, current: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.bold(title, 16, UI.TEXT))
	v.add_child(UI.label(desc, 12, UI.MUTED))
	var prev := UI.small_button("◀", UI.CYAN)
	prev.custom_minimum_size = Vector2(44, 36)
	prev.pressed.connect(func(): _cycle(key, values, -1))
	h.add_child(prev)
	var lab := UI.bold(current, 14, UI.CYAN)
	lab.custom_minimum_size = Vector2(150, 0)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(lab)
	var next := UI.small_button("▶", UI.CYAN)
	next.custom_minimum_size = Vector2(44, 36)
	next.pressed.connect(func(): _cycle(key, values, 1))
	h.add_child(next)
	_list.add_child(h)

func _cycle(key: String, values: Array, dir: int) -> void:
	var cur = GameData.options[key]
	var idx := 0
	if key == "difficulty":
		idx = int(cur)
	elif key == "sets":
		idx = values.find(int(cur))
	elif key == "camera":
		idx = int(cur)
	idx = wrapi(idx + dir, 0, values.size())
	if key == "difficulty":
		GameData.options[key] = idx
	elif key == "sets":
		GameData.options[key] = int(values[idx])
	elif key == "camera":
		GameData.options[key] = idx
	GameData.save_settings()
	Sfx.play("ui", -12.0, 1.0)
	_rebuild()

func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()

func _toggle(title: String, desc: String, key: String, value: bool) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.bold(title, 16, UI.TEXT))
	v.add_child(UI.label(desc, 12, UI.MUTED))
	var b := UI.button("ON" if value else "OFF", UI.GREEN if value else UI.RED, 14, 36)
	b.custom_minimum_size = Vector2(90, 36)
	b.pressed.connect(func():
		GameData.options[key] = not bool(GameData.options[key])
		GameData.save_settings()
		Sfx.play("ui", -12.0, 1.0)
		_rebuild()
	)
	h.add_child(b)
	_list.add_child(h)

func _reset() -> void:
	GameData.options = {
		"difficulty": 2,
		"sets": 5,
		"camera": 0,
		"sfx": true,
		"auto_receive": false,
		"auto_set": true,
		"auto_attack": false,
		"tactics_slowmo": true
	}
	GameData.save_settings()
	_rebuild()
