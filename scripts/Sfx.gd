extends Node

## Tiny procedural sound bank. No external audio files needed.

var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next := 0

func _ready() -> void:
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_streams["hit"] = _make_hit(0.11, 180.0, 0.55)
	_streams["serve"] = _make_whoosh(0.22)
	_streams["block"] = _make_hit(0.16, 90.0, 0.85)
	_streams["receive"] = _make_hit(0.07, 260.0, 0.34)
	_streams["set"] = _make_hit(0.05, 340.0, 0.22)
	_streams["whistle"] = _make_whistle(0.45)
	_streams["point"] = _make_chord(0.55)
	_streams["ui"] = _make_blip(0.045)
	_streams["crowd"] = _make_crowd(1.6)
	_streams["error"] = _make_fail(0.28)

func play(name: String, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	if not bool(GameData.options.get("sfx", true)):
		return
	if not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch, 0.55, 1.8)
	p.play()

func _wav(samples: PackedFloat32Array, rate: int = 22050) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w

func _make_hit(duration: float, base_hz: float, noise_mix: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / rate
		var u := t / duration
		var env := exp(-u * 9.0)
		var tone := sin(TAU * base_hz * t) * 0.6 + sin(TAU * base_hz * 1.9 * t) * 0.2
		var noise := randf_range(-1.0, 1.0) * noise_mix
		out[i] = (tone + noise) * env * 0.85
	return _wav(out, rate)

func _make_whoosh(duration: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in range(n):
		var u := float(i) / n
		var env := sin(u * PI)
		last = lerpf(last, randf_range(-1.0, 1.0), 0.18)
		out[i] = last * env * 0.6
	return _wav(out, rate)

func _make_whistle(duration: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / rate
		var u := t / duration
		var env: float = minf(1.0, u * 18.0) * minf(1.0, (1.0 - u) * 9.0)
		var f := 2100.0 + sin(TAU * 13.0 * t) * 80.0
		var a := sin(TAU * f * t) * 0.45 + sin(TAU * (f * 1.5) * t) * 0.18
		a += randf_range(-0.03, 0.03)
		out[i] = a * env
	return _wav(out, rate)

func _make_chord(duration: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / rate
		var u := t / duration
		var env := exp(-u * 3.2)
		var a := sin(TAU * 523.25 * t) * 0.22
		a += sin(TAU * 659.25 * t) * 0.18
		a += sin(TAU * 783.99 * t) * 0.14
		out[i] = a * env
	return _wav(out, rate)

func _make_blip(duration: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / rate
		var env := exp(-t / duration * 6.0)
		out[i] = sin(TAU * 880.0 * t) * env * 0.25
	return _wav(out, rate)

func _make_fail(duration: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t := float(i) / rate
		var u := t / duration
		var env := exp(-u * 4.0)
		out[i] = sin(TAU * (220.0 - u * 90.0) * t) * env * 0.35
	return _wav(out, rate)

func _make_crowd(duration: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(duration * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	for i in range(n):
		var u := float(i) / n
		var env: float = minf(1.0, u * 5.0) * minf(1.0, (1.0 - u) * 3.0)
		low = lerpf(low, randf_range(-1.0, 1.0), 0.03)
		var mid := randf_range(-1.0, 1.0) * 0.22
		out[i] = (low * 0.6 + mid) * env * 0.7
	return _wav(out, rate)
