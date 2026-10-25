extends CanvasLayer

## Mid-rally tactics board. Pauses the match while it is open.

signal closed
signal changed(key: String, index: int)

const PLAYS := ["QUICK", "BACK QUICK", "WING", "PIPE", "DUMP"]
const SERVES := ["FLOAT", "JUMP", "UNDERARM"]
const BLOCKS := ["READ", "COMMIT", "SPREAD", "TRIPLE"]
const RECEIVES := ["BALANCED", "PERIMETER", "STACK"]

const PLAY_DESC := [
	"A fast set to the middle. Beats a slow block, but needs a clean pass.",
	"A quick attack from the back row. Hard to read, slightly slower to develop.",
	"The classic antenna attack. Reliable power from either pin.",
	"A back-row attack through the middle. Great against a committed block.",
	"The setter tips it over on the second touch. Punishes blockers who jump early."
]
const BLOCK_DESC := [
	"Read the setter and react. Balanced, two blockers.",
	"Commit to the middle and close hard. Risky against wings.",
	"Spread the wall wide to smother pin attacks.",
	"Send three blockers. A true roof, but a tip can beat it."
]
const RECV_DESC := [
	"Standard cup. Safe and balanced.",
	"Three receivers around the edge, middle back stays deep.",
	"Stack the seams to hide the libero and overload one side."
]

var play_index := 2
var serve_index := 0
var block_index := 0
var recv_index := 0

var _play_buttons: Array = []
var _serve_buttons: Array = []
var _block_buttons: Array = []
var _recv_buttons: Array = []
var _play_desc: Label
var _block_desc: Label
var _recv_desc: Label
var _built := false

func setup(p: int, s: int, b: int, r: int) -> void:
	play_index = clampi(p, 0, PLAYS.size() - 1)
	serve_index = clampi(s, 0, SERVES.size() - 1)
	block_index = clampi(b, 0, BLOCKS.size() - 1)
	recv_index = clampi(r, 0, RECEIVES.size() - 1)
	if _built:
		_refresh()

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	_built = true
	_refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.035, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UI.panel(Color(0.035, 0.05, 0.09, 0.98), Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.55), 18)
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	v.add_child(head)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	hv.add_child(UI.label("BENCH ORDERS", 12, UI.ORANGE))
	hv.add_child(UI.bold("TEAM TACTICS", 34, UI.TEXT))
	head.add_child(UI.hspacer())
	var close := UI.small_button("TAB  •  RETURN", UI.GOLD)
	close.custom_minimum_size = Vector2(170, 40)
	close.pressed.connect(close_overlay)
	head.add_child(close)
	v.add_child(UI.hline())

	_section(v, "PLAY CALL  •  1 — 5", PLAYS, "play")
	_play_desc = UI.label(PLAY_DESC[play_index], 13, UI.MUTED)
	_play_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_play_desc)
	v.add_child(UI.hline())

	var two := HBoxContainer.new()
	two.add_theme_constant_override("separation", 18)
	v.add_child(two)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	two.add_child(left)
	_section(left, "SERVE TYPE", SERVES, "serve")
	left.add_child(UI.label("Float: safe and moving. Jump: power and risk. Underarm: guaranteed in.", 12, UI.MUTED))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	two.add_child(right)
	_section(right, "BLOCK SCHEME", BLOCKS, "block")
	_block_desc = UI.label(BLOCK_DESC[block_index], 12, UI.MUTED)
	_block_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_block_desc)

	v.add_child(UI.hline())
	_section(v, "RECEPTION FORMATION", RECEIVES, "receive")
	_recv_desc = UI.label(RECV_DESC[recv_index], 12, UI.MUTED)
	_recv_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_recv_desc)

	v.add_child(UI.hline())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	v.add_child(foot)
	var hint := UI.label("Changes apply immediately. The match is paused while this board is open.", 13, UI.MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(hint)
	var ok := UI.button("BACK TO MATCH", UI.ORANGE, 18, 46)
	ok.custom_minimum_size = Vector2(230, 46)
	ok.pressed.connect(close_overlay)
	foot.add_child(ok)

func _section(parent: VBoxContainer, title: String, items: Array, key: String) -> void:
	parent.add_child(UI.bold(title, 12, UI.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var arr: Array = []
	for i in range(items.size()):
		var b := UI.button(items[i], UI.CYAN, 15, 42)
		b.custom_minimum_size = Vector2(150, 42)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_pick.bind(key, i))
		row.add_child(b)
		arr.append(b)
	match key:
		"play": _play_buttons = arr
		"serve": _serve_buttons = arr
		"block": _block_buttons = arr
		"receive": _recv_buttons = arr

func _pick(key: String, index: int) -> void:
	match key:
		"play": play_index = index
		"serve": serve_index = index
		"block": block_index = index
		"receive": recv_index = index
	Sfx.play("ui", -12.0, 1.08)
	_refresh()
	changed.emit(key, index)

func _mark(buttons: Array, selected: int, words: Array) -> void:
	for i in range(buttons.size()):
		var b: Button = buttons[i]
		var on := i == selected
		b.text = ("▶  " if on else "") + str(words[i])
		b.add_theme_color_override("font_color", UI.GOLD if on else UI.MUTED)
		b.modulate = Color.WHITE if on else Color(0.82, 0.86, 0.95)

func _refresh() -> void:
	if not _built:
		return
	_mark(_play_buttons, play_index, PLAYS)
	_mark(_serve_buttons, serve_index, SERVES)
	_mark(_block_buttons, block_index, BLOCKS)
	_mark(_recv_buttons, recv_index, RECEIVES)
	if _play_desc:
		_play_desc.text = PLAY_DESC[play_index]
	if _block_desc:
		_block_desc.text = BLOCK_DESC[block_index]
	if _recv_desc:
		_recv_desc.text = RECV_DESC[recv_index]

func open_overlay() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Sfx.play("ui", -10.0, 0.95)

func close_overlay() -> void:
	if not visible:
		return
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("tactics") or event.is_action_pressed("pause") or event.is_action_pressed("back"):
		close_overlay()
		get_viewport().set_input_as_handled()
