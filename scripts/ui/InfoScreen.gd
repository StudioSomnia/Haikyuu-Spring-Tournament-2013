extends Control

signal back

var kind := "howto"

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
	tv.add_child(UI.bold("HOW TO PLAY" if kind == "howto" else "CREDITS", 38, UI.TEXT))
	tv.add_child(UI.label("A modern volleyball sim with Haikyuu's cast." if kind == "howto" else "Made with respect for the source material.", 14, UI.MUTED))
	root.add_child(UI.hline())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	if kind == "howto":
		_howto(body)
	else:
		_credits(body)

func _section(parent: Control, title: String, text: String, accent: Color = UI.ORANGE) -> void:
	var p := UI.panel(Color(0, 0, 0, 0.20), Color(accent.r, accent.g, accent.b, 0.28), 12)
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(UI.bold(title, 18, accent))
	var l := UI.label(text, 14, UI.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(0, 0)
	v.add_child(l)

func _howto(parent: Control) -> void:
	_section(parent, "THE SHAPE OF A RALLY", "Every rally moves through five phases: SERVE → RECEIVE → SET → ATTACK → BLOCK. The whole team moves into position automatically. You make the timing decisions: SPACE at the ball, CTRL to dive, the number keys to call the play. Q / X still switches which player you are watching.\n\nThe timing bar at the bottom is red → yellow → green → yellow → red. The green is the perfect window; it grows with the relevant stat — serve skill for serves, the setter's set skill for spikes, and the receiver's read for contacts.")
	_section(parent, "SERVE", "Aim with the mouse, hold SPACE, and release inside the green. 1 / 2 / 3 selects OVERHAND, UNDERARM, or JUMP. UNDERARM is the safe, low-power serve with a tiny stat barrier; OVERHAND adds more of the attack stat and is more sensitive to serve skill; JUMP has the highest power ceiling but a poor server will hit the net or sail long. Serve skill controls accuracy and the green window; attack skill controls how much sting the serve carries into the reception.")
	_section(parent, "RECEIVE & DEFENSE", "The game picks the nearest receiver and runs them to the landing marker, so you only time the contact: press SPACE as the ball drops. The white inner ring closes on the centre as a cue. CTRL / C dives at the drop point: a longer lunge and a bigger contact circle. A high RECEIVE stat gives a bigger circle, a wider timing window, and a faster recovery from the dive.\n\nWhile the opponent has the ball, 1-4 calls READ, COMMIT, SPREAD, or TRIPLE. The front row forms a single wall and jumps together, and the rest of the team shifts its floor coverage around that wall.")
	_section(parent, "SET & PLAY CALLS", "The setter is selected automatically. As soon as your receive is controlled, 1-5 opens the attack calls:\n1 QUICK — middle tempo, ideal for Hinata-style first-tempo plays.\n2 BACK QUICK — the other middle attacks behind the setter.\n3 WING — high ball to the pin for your ace.\n4 PIPE — back-row attack through the middle.\n5 DUMP — the setter attacks on the second touch.\n\nSET skill controls set accuracy, the size of the spike's green timing window, and how reliably the AI setter runs quick combinations under pressure.")
	_section(parent, "ATTACK", "The intended attacker runs to the set. In set_flight, watch the bar and press SPACE in the green. The reticle chooses the target; E / Y toggles a full swing and a tip. ATTACK and JUMP stats set the spike's power: harder hitters fly faster, are harder to dig, and win more dice contests against the block. A fully smothered shot can still be stopped by a strong, well-positioned wall. A badly timed press is a weak swing; if you never press in the window, the ball drops for the opponent.")
	_section(parent, "BLOCK", "The front row moves to the net as one unit and jumps together. 1-4 changes the scheme: READ keeps a balanced two-man wall, COMMIT sends one blocker after the middle, SPREAD widens the wall, and TRIPLE commits all three. The back row and any non-blocking front player fan out to cover the floor the wall leaves open.\n\nBLOCK skill widens each blocker's span and increases the wall's durability. At the net, the attack stat and the block stat are rolled as d6 contests: attack rating + d6 + spike power + jump timing against block rating + d6 + how smothered the shot is + durability + scheme. The better side wins, so upsets are possible. The enemy AI uses the same wall and picks its own scheme from your called play.")
	_section(parent, "STATS MATTER", "SERVE — accuracy, serve timing window, and serve power.\nATTACK — spike speed, block contest, and how much a dig is rattled.\nBLOCK — wall spacing, individual reach, durability, and the block dice.\nSET — set accuracy, spike timing window, and AI play selection.\nRECEIVE — receive circle, timing window, emergency reach, and dive recovery.\nSPEED — raw movement and how quickly players close on a ball.\nJUMP — spike power and timing quality.")
	_section(parent, "TACTICS & TEAM FLOW", "TAB opens the tactics board. It pauses the rally and lets you change serve type, reception shape, attack play, and block scheme. Changes apply to the next contact. The number keys mirror the board but are context-locked: 1-3 serve, 1-4 block, 1-5 attack.\n\nEvery good action fills your FLOW meter: aces, kills, blocks, digs, perfect receives. At 100, press E / Y to unleash your school's signature ability — Freak Quick, Floor Fortress, Iron Wall, Left Cannon, and more. FLOW is the anime heartbeat of the match.")
	_section(parent, "RULES", "Standard rally scoring. Sets are played to 25 (15 for a deciding fifth set) and must be won by two. Win three sets to take the match. The serving team rotates clockwise after winning a rally, so your lineup and matchups change constantly. Edit the starting six from the team-select screen, and make manual substitutions from the pause menu. Liberos sit on the bench in this build because their front-row replacement and serve rules are not implemented yet.")
	_section(parent, "TIPS", "• Watch the opponent's setter: the set direction tells you where the block should go.\n• A safe serve to a weak passer is often better than a maximum-power ace attempt.\n• On defense, let the auto positioning do the running, then time SPACE. Diving early trades recovery for reach; high-RECEIVE players get up faster.\n• Use your FLOW ability on a big point, not on the first rally.\n• The reticle never leaves the screen: bright while aiming, dimmed with a dark outline means it is your cursor.\n• Camera V cycles Dynamic, Broadcast, Behind Player, and High Tactical views.", UI.CYAN)
	_section(parent, "A NOTE ON DIFFICULTY", "Very Easy and Easy widen timing windows and reduce AI accuracy. Normal is the intended experience. Hard and Very Hard give the AI faster reads, better serves, and smarter attack placement. You can change difficulty at any time from Options.", UI.GREEN)

func _credits(parent: Control) -> void:
	_section(parent, "A FAN-MADE TRIBUTE", "Haikyuu!! and its characters belong to Haruichi Furudate, Shueisha, Production I.G, and the official rights holders. This is a non-commercial fan project. No copyrighted art, audio, models, or other assets from the anime or from International Volleyball 2009 are included. Every visual, sound, and line of code here is generated by the project.", UI.ORANGE)
	_section(parent, "WHAT WAS REBUILT", "International Volleyball 2009 (Idoru S.R.L.) was studied for its phase structure: serve, reception/defense, set, spike, and block; its 3×5 target grid; its power timing; its rotation and libero rules; its scout/statistics layer; and its five-phase tactical rhythm. This project keeps that skeleton and modernizes the controls, presentation, AI, and team-play systems.", UI.CYAN)
	_section(parent, "TECHNICAL", "Godot 4.7 • GDScript • fully procedural 3D court, players, animation, UI, and audio. No external plugins. The game is data-driven: schools and players live in scripts/data/TeamDatabase.gd, and the match engine reads their roles, stats, traits, and playbooks.", UI.GREEN)
	_section(parent, "SPECIAL THANKS", "To every player who ever shanked a receive and kept running anyway. The ball never drops.", UI.GOLD)
