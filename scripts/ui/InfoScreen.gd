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
	_section(parent, "THE SHAPE OF A RALLY", "Every rally moves through five phases: SERVE → RECEIVE → SET → ATTACK → BLOCK. The HUD always tells you which phase you are in, and the whole team moves into position automatically. You make the timing decisions: SPACE at the ball, CTRL to dive, the number keys to call the play. Q / X still switches which player you are watching.\n\nHold SPACE to charge serves, and press SPACE near the top of a set to jump and swing. For receives, press SPACE as the ball arrives. The landing marker and the shrinking timing ring are your best friends.")
	_section(parent, "SERVE", "Aim with the mouse (or right stick), then hold SPACE and release near the sweet spot. While you are serving, 1 / 2 / 3 selects OVERHAND, UNDERARM, or JUMP; 4 and 5 do nothing in this phase. Jump serves are faster but less accurate; overhand serves are safer and move in the air. Aim at weak receivers, not just empty floor.")
	_section(parent, "RECEIVE & DEFENSE", "The game picks the nearest receiver and runs them to the landing marker, so you only have to time the contact: press SPACE as the ball drops. The white inner ring closes on the centre as a timing cue. Press CTRL / C to dive at the drop point: a longer lunge and a bigger contact circle, but you get up a step slower.\n\nWhile the opponent has the ball, 1-4 calls READ, COMMIT, SPREAD, or TRIPLE. The front row forms a single wall and jumps together, and the rest of the team shifts its floor coverage around that wall. A perfect receive raises set quality; a poor one forces a scramble.")
	_section(parent, "SET & PLAY CALLS", "The setter is selected automatically. As soon as your receive is controlled, 1-5 opens the attack calls:\n1 QUICK — middle tempo, ideal for Hinata-style first-tempo plays.\n2 BACK QUICK — the other middle attacks behind the setter.\n3 WING — high ball to the pin for your ace.\n4 PIPE — back-row attack through the middle.\n5 DUMP — the setter attacks on the second touch.\n\nAim with the mouse to place the set. Quick sets demand better timing and a better pass.")
	_section(parent, "ATTACK", "The intended attacker is selected and runs to the set. In set_flight, press SPACE once near the top of the set to jump and swing. The reticle chooses the target zone; press E / Y to toggle a full swing and a tip. Power beats blockers; placement beats floor defense. Deep corners and seams are the best targets.")
	_section(parent, "BLOCK", "When the opponent attacks, the front row moves to the net as one unit and jumps together. 1-4 changes the scheme: READ keeps a balanced two-man wall, COMMIT sends one blocker after the middle, SPREAD widens the wall, and TRIPLE commits all three. The back row and any non-blocking front player fan out to cover the floor the wall leaves open.")
	_section(parent, "TACTICS & TEAM FLOW", "TAB opens the tactics board. It pauses the rally and lets you change serve type, reception shape, attack play, and block scheme. Changes apply to the next contact. The number keys mirror the board but are context-locked: 1-3 serve, 1-4 block, 1-5 attack.\n\nEvery good action fills your FLOW meter: aces, kills, blocks, digs, perfect receives. At 100, press E / Y to unleash your school's signature ability — Freak Quick, Floor Fortress, Iron Wall, Left Cannon, and more. FLOW is the anime heartbeat of the match.")
	_section(parent, "RULES", "Standard rally scoring. Sets are played to 25 (15 for a deciding fifth set) and must be won by two. Win three sets to take the match. The serving team rotates clockwise after winning a rally, so your lineup and matchups change constantly. Edit the starting six from the team-select screen, and make manual substitutions from the pause menu. Liberos sit on the bench in this build because their front-row replacement and serve rules are not implemented yet.")
	_section(parent, "TIPS", "• Watch the opponent's setter: the set direction tells you where the block should go.\n• A safe serve to a weak passer is often better than a maximum-power ace attempt.\n• On defense, let the auto positioning do the running, then time SPACE. Diving early trades recovery for reach.\n• Use your FLOW ability on a big point, not on the first rally.\n• The reticle never leaves the screen: bright means you are aiming, dimmed with a dark outline means it is your cursor.\n• Camera V cycles Dynamic, Broadcast, Behind Player, and High Tactical views.", UI.CYAN)
	_section(parent, "A NOTE ON DIFFICULTY", "Very Easy and Easy widen timing windows and reduce AI accuracy. Normal is the intended experience. Hard and Very Hard give the AI faster reads, better serves, and smarter attack placement. You can change difficulty at any time from Options.", UI.GREEN)

func _credits(parent: Control) -> void:
	_section(parent, "A FAN-MADE TRIBUTE", "Haikyuu!! and its characters belong to Haruichi Furudate, Shueisha, Production I.G, and the official rights holders. This is a non-commercial fan project. No copyrighted art, audio, models, or other assets from the anime or from International Volleyball 2009 are included. Every visual, sound, and line of code here is generated by the project.", UI.ORANGE)
	_section(parent, "WHAT WAS REBUILT", "International Volleyball 2009 (Idoru S.R.L.) was studied for its phase structure: serve, reception/defense, set, spike, and block; its 3×5 target grid; its power timing; its rotation and libero rules; its scout/statistics layer; and its five-phase tactical rhythm. This project keeps that skeleton and modernizes the controls, presentation, AI, and team-play systems.", UI.CYAN)
	_section(parent, "TECHNICAL", "Godot 4.7 • GDScript • fully procedural 3D court, players, animation, UI, and audio. No external plugins. The game is data-driven: schools and players live in scripts/data/TeamDatabase.gd, and the match engine reads their roles, stats, traits, and playbooks.", UI.GREEN)
	_section(parent, "SPECIAL THANKS", "To every player who ever shanked a receive and kept running anyway. The ball never drops.", UI.GOLD)
