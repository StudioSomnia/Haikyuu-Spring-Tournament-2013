class_name TeamDatabase
extends RefCounted

## All playable schools. Stats are 1-99. The first six players are the
## starting rotation (P1 back-right, P2 front-right, P3 front-center,
## P4 front-left, P5 back-left, P6 back-center). Everyone after that
## starts on the bench and can be used in the substitution screen.

const STAT_KEYS := ["serve", "receive", "set", "attack", "block", "speed", "jump", "stamina", "iq", "mentality"]

static func build() -> Dictionary:
	var t := {}

	t["karasuno"] = _team(
		"karasuno", "Karasuno High", "KARASUNO", "Fly High", "#ff7a1a", "#141821", "#f5f7ff",
		"freak_quick", "FREAK QUICK",
		"Kageyama and Hinata erase the gap between set and spike. The next quick attack is almost impossible to read.",
		{"serve": "float", "receive": "balanced", "block": "read", "attack": ["quick", "wing", "pipe", "back_quick"], "tempo": 0.9},
		[
			_p("Tobio Kageyama", 9, "S", 181, [88, 72, 97, 78, 70, 76, 82, 88, 94, 78], "setter_ace", "#1b1b22"),
			_p("Daichi Sawamura", 1, "WS", 176, [70, 92, 66, 70, 72, 78, 76, 94, 86, 96], "captain", "#241c18"),
			_p("Shoyo Hinata", 10, "MB", 162, [58, 60, 55, 88, 64, 96, 99, 90, 62, 94], "freak_quick", "#f26b1d"),
			_p("Asahi Azumane", 3, "WS", 184, [78, 66, 60, 94, 74, 70, 82, 84, 76, 70], "ace", "#2d211c"),
			_p("Yu Nishinoya", 4, "L", 159, [60, 98, 70, 40, 40, 95, 94, 92, 82, 98], "floor_general", "#c58a2a"),
			_p("Kei Tsukishima", 11, "MB", 188, [62, 68, 64, 74, 92, 64, 78, 78, 92, 72], "guess_block", "#c9b458"),
			_p("Ryunosuke Tanaka", 5, "WS", 177, [82, 72, 55, 86, 66, 80, 86, 90, 70, 92], "ace", "#3b2a22"),
			_p("Koshi Sugawara", 2, "S", 174, [68, 74, 86, 62, 66, 68, 70, 82, 88, 84], "veteran", "#b7b9c6"),
			_p("Tadashi Yamaguchi", 12, "MB", 179, [74, 62, 58, 66, 70, 66, 72, 74, 74, 62], "serve_specialist", "#35506e"),
			_p("Chikara Ennoshita", 6, "WS", 177, [64, 76, 64, 68, 64, 72, 72, 80, 78, 76], "veteran", "#2b252b")
		]
	)

	t["nekoma"] = _team(
		"nekoma", "Nekoma High", "NEKOMA", "Connect", "#d81f35", "#17151a", "#f5f7ff",
		"floor_fortress", "FLOOR FORTRESS",
		"The cats refuse to let the ball drop. For the next three attacks, the team's floor defense is dramatically boosted.",
		{"serve": "float", "receive": "perimeter", "block": "read", "attack": ["wing", "pipe", "back_quick"], "tempo": 0.7},
		[
			_p("Kenma Kozume", 5, "S", 169, [62, 66, 95, 56, 58, 60, 62, 58, 99, 84], "commander", "#c9a76b"),
			_p("Taketora Yamamoto", 2, "WS", 178, [82, 74, 54, 88, 66, 80, 86, 92, 64, 96], "ace", "#f2c94c"),
			_p("Tetsuro Kuroo", 1, "MB", 187, [78, 82, 78, 82, 94, 78, 84, 86, 94, 90], "guess_block", "#17151a"),
			_p("Shohei Fukunaga", 7, "WS", 180, [70, 76, 62, 78, 64, 74, 78, 82, 72, 78], "veteran", "#5c3a2a"),
			_p("Morisuke Yaku", 3, "L", 166, [58, 96, 74, 42, 42, 94, 88, 90, 86, 94], "floor_general", "#7a5238"),
			_p("Lev Haiba", 11, "MB", 194, [66, 58, 50, 82, 80, 78, 88, 74, 58, 72], "rookie", "#d6d8df"),
			_p("So Inuoka", 4, "MB", 185, [64, 70, 58, 74, 78, 90, 92, 86, 70, 82], "speedster", "#2a2320"),
			_p("Nobuyuki Kai", 6, "WS", 178, [66, 84, 68, 70, 70, 74, 74, 84, 82, 86], "veteran", "#232326"),
			_p("Yuki Shibayama", 8, "WS", 172, [62, 80, 66, 64, 58, 78, 72, 80, 76, 80], "scrapper", "#3a3028"),
			_p("Haruki Komi", 9, "L", 170, [54, 84, 62, 40, 40, 86, 78, 82, 74, 82], "scrapper", "#4b3529")
		]
	)

	t["seijoh"] = _team(
		"seijoh", "Aoba Johsai", "SEIJOH", "Rule the Court", "#12b5c9", "#0e2230", "#f5f7ff",
		"service_ace", "SERVICE ACE",
		"Oikawa's serve bends the court itself. The next serve gains power and accuracy and puts the receivers on the back foot.",
		{"serve": "jump", "receive": "balanced", "block": "read", "attack": ["wing", "back_quick", "pipe", "quick"], "tempo": 0.8},
		[
			_p("Toru Oikawa", 1, "S", 184, [96, 76, 96, 80, 70, 74, 84, 82, 98, 92], "serve_ace", "#7b4b2a"),
			_p("Hajime Iwaizumi", 4, "WS", 179, [86, 78, 62, 91, 74, 82, 88, 92, 84, 94], "ace", "#28211c"),
			_p("Yutaro Kindaichi", 12, "MB", 189, [70, 68, 58, 78, 86, 70, 82, 80, 68, 76], "tall", "#2a2a2e"),
			_p("Issei Matsukawa", 2, "MB", 188, [70, 72, 62, 76, 90, 68, 80, 82, 80, 82], "guess_block", "#3a2b23"),
			_p("Takahiro Hanamaki", 6, "WS", 184, [76, 74, 62, 82, 72, 76, 80, 84, 78, 80], "veteran", "#a55a36"),
			_p("Shinji Watari", 8, "L", 168, [56, 90, 68, 40, 40, 90, 84, 86, 80, 88], "floor_general", "#332b25"),
			_p("Kentaro Kyotani", 9, "WS", 182, [88, 58, 48, 94, 64, 84, 92, 78, 52, 70], "wild_card", "#d4b26a"),
			_p("Akira Kunimi", 13, "WS", 183, [68, 76, 60, 78, 64, 68, 74, 72, 82, 62], "lazy_genius", "#2f2a2a"),
			_p("Shigeru Yahaba", 7, "S", 179, [72, 68, 84, 64, 64, 70, 72, 76, 80, 74], "veteran", "#4b3426"),
			_p("Yudai Hyakuzawa", 14, "MB", 199, [60, 54, 44, 76, 78, 62, 82, 68, 48, 58], "rookie", "#2a2626")
		]
	)

	t["shiratorizawa"] = _team(
		"shiratorizawa", "Shiratorizawa Academy", "SHIRATORI", "Absolute Power", "#7b3fa0", "#23122e", "#f5f7ff",
		"left_cannon", "LEFT CANNON",
		"Ushijima's left-handed spike is a force of nature. The next attack becomes a devastating cross-court cannon.",
		{"serve": "jump", "receive": "stack", "block": "commit", "attack": ["wing", "pipe", "quick"], "tempo": 0.75},
		[
			_p("Kenjiro Shirabu", 6, "S", 178, [76, 68, 90, 66, 66, 70, 74, 80, 88, 80], "setter_ace", "#8a7a5a"),
			_p("Wakatoshi Ushijima", 1, "OPP", 189, [94, 70, 54, 99, 82, 78, 90, 94, 82, 98], "left_cannon", "#2a241f"),
			_p("Satori Tendo", 2, "MB", 187, [72, 72, 60, 80, 96, 72, 84, 84, 88, 86], "guess_block", "#b03a3a"),
			_p("Taichi Kawanishi", 5, "MB", 188, [70, 74, 60, 74, 88, 68, 80, 82, 78, 80], "tall", "#2a2a2e"),
			_p("Tsutomu Goshiki", 4, "WS", 181, [78, 70, 58, 88, 68, 80, 88, 84, 64, 78], "rookie", "#3a3028"),
			_p("Hayato Yamagata", 7, "L", 174, [58, 92, 68, 40, 40, 92, 84, 88, 82, 90], "floor_general", "#2b2520"),
			_p("Reon Ohira", 8, "WS", 185, [78, 80, 62, 84, 76, 74, 80, 86, 80, 84], "veteran", "#5b4432"),
			_p("Eita Semi", 3, "S", 180, [86, 70, 86, 72, 68, 74, 78, 80, 82, 78], "serve_ace", "#d1c48f"),
			_p("Jin Soekawa", 10, "WS", 179, [70, 78, 60, 74, 68, 72, 74, 80, 76, 78], "veteran", "#2f2a26"),
			_p("Yusho Kai", 11, "MB", 190, [64, 64, 52, 72, 80, 64, 78, 76, 66, 70], "tall", "#2a2622")
		]
	)

	t["fukurodani"] = _team(
		"fukurodani", "Fukurodani Academy", "FUKURODANI", "The Owl's Wing", "#d4a017", "#16130c", "#f5f7ff",
		"mood_swing", "MOOD SWING",
		"Bokuto is unstoppable when he is having fun. The next three attacks gain a huge power and accuracy boost.",
		{"serve": "jump", "receive": "balanced", "block": "read", "attack": ["wing", "quick", "pipe"], "tempo": 0.85},
		[
			_p("Keiji Akaashi", 5, "S", 182, [76, 72, 94, 70, 68, 72, 78, 80, 96, 86], "commander", "#2a2b30"),
			_p("Kotaro Bokuto", 4, "WS", 185, [88, 66, 52, 97, 78, 78, 92, 90, 56, 88], "mood_swing", "#d9d9df"),
			_p("Tatsuki Washio", 2, "MB", 188, [70, 74, 60, 76, 88, 68, 80, 82, 78, 82], "veteran", "#2a2520"),
			_p("Akinori Konoha", 7, "WS", 183, [74, 78, 66, 80, 72, 76, 80, 84, 82, 84], "all_round", "#5a3a26"),
			_p("Haruki Sarukui", 1, "WS", 184, [76, 72, 58, 82, 74, 74, 80, 84, 74, 78], "veteran", "#2e2721"),
			_p("Wataru Onaga", 3, "L", 172, [54, 88, 66, 40, 40, 88, 82, 84, 80, 86], "floor_general", "#3a2e26"),
			_p("Yamato Samejima", 6, "MB", 190, [66, 64, 54, 72, 82, 62, 78, 76, 68, 74], "tall", "#2a2622"),
			_p("Kazuma Komi", 8, "WS", 177, [68, 76, 62, 72, 66, 72, 74, 78, 76, 78], "scrapper", "#4b3529"),
			_p("Takeru Anahori", 9, "S", 175, [64, 66, 78, 60, 60, 66, 68, 72, 74, 70], "veteran", "#2a292e"),
			_p("Shohei Yonezawa", 10, "WS", 180, [66, 70, 56, 70, 64, 70, 74, 76, 70, 72], "rookie", "#3a3028")
		]
	)

	t["dateko"] = _team(
		"dateko", "Date Tech High", "DATE TECH", "Iron Wall", "#2c5f9e", "#0c1524", "#f5f7ff",
		"iron_wall", "IRON WALL",
		"Date Tech's read block closes like a gate. The next opponent attack faces a three-man wall with boosted timing.",
		{"serve": "float", "receive": "balanced", "block": "triple", "attack": ["wing", "back_quick", "quick"], "tempo": 0.65},
		[
			_p("Kanji Koganegawa", 2, "S", 193, [74, 62, 80, 70, 78, 68, 84, 78, 60, 66], "rookie", "#c9d4e0"),
			_p("Kenji Futakuchi", 6, "WS", 182, [78, 76, 60, 84, 74, 78, 84, 86, 80, 84], "captain", "#2a241f"),
			_p("Takanobu Aone", 1, "MB", 192, [66, 74, 54, 74, 98, 66, 86, 88, 84, 90], "iron_wall", "#d8d8de"),
			_p("Yasushi Kamasaki", 5, "MB", 187, [70, 72, 58, 76, 90, 66, 80, 82, 78, 80], "veteran", "#3a2c24"),
			_p("Yutaka Obara", 7, "WS", 180, [72, 78, 58, 78, 68, 78, 80, 82, 76, 78], "scrapper", "#4b3426"),
			_p("Kousuke Sakunami", 9, "L", 169, [54, 88, 64, 40, 42, 88, 82, 84, 78, 84], "floor_general", "#2b2622"),
			_p("Takehito Sasaya", 3, "WS", 183, [74, 74, 58, 78, 76, 72, 78, 82, 74, 78], "veteran", "#2a2520"),
			_p("Mitsuhiro Onagawa", 8, "WS", 178, [68, 72, 54, 72, 66, 72, 74, 78, 72, 74], "veteran", "#3a3028"),
			_p("Kazuki Kato", 10, "MB", 189, [62, 66, 50, 68, 78, 62, 76, 74, 66, 70], "tall", "#2a2622"),
			_p("Shinnosuke Ouchi", 11, "WS", 176, [64, 70, 54, 68, 62, 70, 72, 74, 70, 72], "rookie", "#4b3529")
		]
	)

	t["inarizaki"] = _team(
		"inarizaki", "Inarizaki High", "INARIZAKI", "We Don't Need Memories", "#7b1f3d", "#160b10", "#f5d78a",
		"twin_decoy", "TWIN DECOY",
		"Atsumu and Osamu blur the line between setter and spiker. The next attack creates a decoy that freezes the block.",
		{"serve": "jump", "receive": "balanced", "block": "spread", "attack": ["quick", "wing", "back_quick", "pipe"], "tempo": 0.95},
		[
			_p("Atsumu Miya", 4, "S", 184, [94, 74, 96, 84, 66, 76, 84, 86, 94, 88], "twin_quick", "#d4b46a"),
			_p("Aran Ojiro", 2, "WS", 185, [88, 76, 56, 94, 78, 76, 88, 90, 78, 90], "ace", "#2a2420"),
			_p("Rintaro Suna", 3, "MB", 187, [70, 72, 64, 84, 90, 72, 82, 82, 90, 82], "guess_block", "#6b5a42"),
			_p("Ren Omimi", 7, "MB", 191, [72, 68, 56, 76, 88, 66, 82, 80, 72, 78], "tall", "#2a2622"),
			_p("Osamu Miya", 5, "OPP", 184, [82, 74, 82, 86, 70, 74, 82, 84, 86, 82], "twin_quick", "#d4b46a"),
			_p("Michinari Akagi", 8, "L", 172, [56, 92, 70, 40, 40, 90, 84, 86, 82, 88], "floor_general", "#3a2e26"),
			_p("Shinsuke Kita", 1, "WS", 178, [78, 90, 76, 72, 76, 78, 78, 88, 90, 96], "captain", "#2a292e"),
			_p("Hitoshi Ginjima", 6, "WS", 181, [78, 74, 56, 82, 70, 78, 82, 82, 74, 78], "veteran", "#4b3426"),
			_p("Heisuke Riseki", 9, "WS", 179, [84, 62, 50, 80, 62, 76, 80, 76, 60, 68], "serve_specialist", "#2a2520"),
			_p("Yuto Kosaku", 10, "MB", 188, [64, 66, 52, 70, 78, 62, 76, 74, 68, 70], "rookie", "#3a3028")
		]
	)

	t["kamomedai"] = _team(
		"kamomedai", "Kamomedai High", "KAMOMEDAI", "The Little Giant", "#2e86c1", "#0c1a26", "#f5f7ff",
		"total_defense", "TOTAL DEFENSE",
		"Serve, block, and never flinch. The next rally gives Kamomedai boosted receive and block readings.",
		{"serve": "jump", "receive": "stack", "block": "commit", "attack": ["wing", "quick", "pipe", "back_quick"], "tempo": 0.85},
		[
			_p("Korai Hoshiumi", 1, "WS", 169, [88, 84, 70, 92, 84, 94, 99, 96, 94, 96], "all_round", "#e8e8ee"),
			_p("Sachiro Hirugami", 2, "MB", 188, [72, 78, 64, 78, 96, 70, 84, 86, 92, 90], "iron_wall", "#2a2b30"),
			_p("Gao Hakuba", 3, "MB", 198, [70, 62, 48, 82, 90, 62, 86, 78, 62, 70], "tall", "#d9d9df"),
			_p("Aoi Suwa", 4, "S", 181, [86, 72, 90, 72, 70, 74, 80, 82, 88, 82], "serve_ace", "#4b3529"),
			_p("Nozawa", 5, "WS", 180, [76, 78, 58, 80, 72, 78, 82, 84, 78, 82], "veteran", "#2a2520"),
			_p("Keiichiro Kanbayashi", 6, "L", 170, [56, 90, 64, 40, 42, 88, 82, 86, 80, 86], "floor_general", "#3a2e26"),
			_p("Bessho", 7, "MB", 190, [70, 70, 52, 76, 86, 66, 82, 80, 76, 78], "veteran", "#2a2622"),
			_p("Ezota", 8, "WS", 182, [72, 72, 56, 78, 70, 74, 78, 80, 74, 78], "veteran", "#4b3426"),
			_p("Hiroto Oda", 9, "S", 176, [68, 66, 80, 62, 60, 68, 70, 74, 76, 72], "veteran", "#2a292e"),
			_p("Junpei Kuroda", 10, "WS", 178, [68, 70, 54, 72, 64, 72, 74, 76, 70, 74], "rookie", "#3a3028")
		]
	)

	t["johzenji"] = _team(
		"johzenji", "Johzenji High", "JOHZENJI", "Play Free", "#f2c300", "#1b1a12", "#111111",
		"free_spirit", "FREE SPIRIT",
		"Anything goes. Johzenji improvises a wild, unpredictable attack that is hard for any block to read.",
		{"serve": "jump", "receive": "balanced", "block": "spread", "attack": ["wing", "quick", "pipe"], "tempo": 1.0},
		[
			_p("Yusuke Terushima", 1, "WS", 180, [86, 70, 62, 86, 64, 86, 92, 88, 70, 86], "wild_card", "#e8c46a"),
			_p("Kazuma Numajiri", 2, "S", 176, [74, 68, 82, 66, 62, 72, 74, 78, 78, 74], "veteran", "#2a2520"),
			_p("Rintaro Tsuchiya", 3, "MB", 184, [70, 68, 54, 74, 76, 70, 80, 80, 70, 76], "tall", "#2a2622"),
			_p("Kenta Sawamura", 4, "WS", 178, [74, 74, 58, 78, 66, 78, 80, 82, 74, 78], "scrapper", "#4b3426"),
			_p("Daichi Onodera", 5, "MB", 183, [66, 70, 52, 72, 74, 68, 78, 78, 72, 74], "veteran", "#3a3028"),
			_p("Shohei Nakamura", 6, "L", 168, [54, 84, 62, 40, 40, 86, 80, 82, 74, 82], "scrapper", "#2b2622"),
			_p("Kazuki Mashiko", 7, "WS", 177, [72, 72, 56, 76, 64, 76, 80, 80, 72, 76], "veteran", "#2a2520"),
			_p("Takeru Ono", 8, "S", 174, [66, 66, 76, 60, 58, 68, 70, 72, 72, 70], "rookie", "#4b3529"),
			_p("Yuto Kikuchi", 9, "WS", 180, [70, 68, 52, 72, 62, 74, 76, 76, 68, 72], "rookie", "#3a3028")
		]
	)

	t["wakutani"] = _team(
		"wakutani", "Wakutani Minami", "WAKUTANI", "The Ace's Promise", "#2e7d32", "#0d1a0f", "#f5f7ff",
		"ace_will", "ACE'S WILL",
		"The team rallies behind its ace. The next attack gains power, and every player recovers stamina.",
		{"serve": "jump", "receive": "balanced", "block": "read", "attack": ["wing", "quick", "pipe"], "tempo": 0.75},
		[
			_p("Takeru Nakashima", 1, "WS", 178, [84, 82, 60, 90, 68, 84, 90, 88, 84, 94], "ace", "#6b4a2f"),
			_p("Yuki Hyakuzawa", 2, "S", 175, [72, 72, 82, 64, 62, 72, 74, 78, 80, 76], "veteran", "#2a2520"),
			_p("Kenta Akiyama", 3, "MB", 186, [68, 72, 54, 74, 80, 68, 80, 80, 76, 78], "veteran", "#2a2622"),
			_p("Sora Takahashi", 4, "MB", 184, [66, 68, 52, 70, 76, 66, 78, 78, 72, 74], "tall", "#3a3028"),
			_p("Ryohei Kudo", 5, "WS", 180, [72, 78, 58, 76, 68, 78, 80, 82, 76, 80], "scrapper", "#4b3426"),
			_p("Daiki Nishimura", 6, "L", 170, [54, 86, 64, 40, 40, 86, 80, 82, 76, 84], "floor_general", "#2b2622"),
			_p("Kazuki Shibata", 7, "WS", 178, [70, 72, 54, 74, 62, 74, 76, 78, 72, 76], "veteran", "#2a2520"),
			_p("Haruto Miyata", 8, "S", 176, [66, 64, 76, 60, 58, 68, 70, 72, 72, 70], "rookie", "#4b3529"),
			_p("Kohei Watanabe", 9, "MB", 187, [62, 64, 48, 68, 76, 62, 76, 74, 66, 70], "rookie", "#3a3028")
		]
	)

	return t

static func _team(id: String, name: String, short: String, motto: String, primary: String, secondary: String, accent: String, ability_id: String, ability_name: String, ability_desc: String, playbook: Dictionary, players: Array) -> Dictionary:
	var roster: Array = []
	for i in range(players.size()):
		var p: Dictionary = players[i].duplicate(true)
		p["id"] = "%s_%d" % [id, i]
		p["team_id"] = id
		p["starter"] = i < 6
		p["bench"] = i >= 6
		roster.append(p)
	var overall := 0.0
	for p in roster.slice(0, 6):
		var s: Dictionary = p["stats"]
		overall += float(s["attack"] + s["block"] + s["serve"] + s["receive"] + s["set"]) / 5.0
	overall /= 6.0
	return {
		"id": id,
		"name": name,
		"short": short,
		"motto": motto,
		"primary": primary,
		"secondary": secondary,
		"accent": accent,
		"ability_id": ability_id,
		"ability_name": ability_name,
		"ability_desc": ability_desc,
		"playbook": playbook,
		"players": roster,
		"overall": int(round(overall))
	}

static func _p(name: String, number: int, role: String, height: int, stats: Array, player_trait: String, hair: String) -> Dictionary:
	var s := {}
	for i in range(STAT_KEYS.size()):
		s[STAT_KEYS[i]] = int(stats[i])
	return {
		"name": name,
		"number": number,
		"role": role,
		"height": height,
		"stats": s,
		"trait": player_trait,
		"hair": hair,
		"skin": _skin_for(name),
		"points": 0,
		"attacks": 0,
		"kills": 0,
		"errors": 0,
		"blocks": 0,
		"digs": 0,
		"aces": 0,
		"serves": 0,
		"receptions": 0,
		"sets": 0
	}

static func _skin_for(name: String) -> String:
	# Small deterministic palette so every character reads clearly at distance.
	var tones := ["#f0c8a8", "#e3b28e", "#d19a74", "#c58a62", "#a96e4c", "#8a5a3e"]
	var h := 0
	for i in range(name.length()):
		h = (h * 31 + name.unicode_at(i)) % 997
	return tones[h % tones.size()]
