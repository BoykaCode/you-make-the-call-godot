extends Node
## 8-bit style audio via AudioStreamGeneratorPlayback (square waves + fake whistle).

const SAMPLE_RATE := 44100

var players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = SAMPLE_RATE
		gen.buffer_length = 0.5
		p.stream = gen
		p.volume_db = -6
		players.append(p)

func _free_player() -> AudioStreamPlayer:
	for p in players:
		if not p.playing:
			return p
	return players[0]

func beep(freq: float, dur: float, vol: float = 0.5) -> void:
	var p = _free_player()
	p.stop()
	p.play()
	var pb: AudioStreamGeneratorPlayback = p.get_stream_playback()
	if pb == null: return
	var frames = int(dur * SAMPLE_RATE)
	var buf = PackedVector2Array()
	buf.resize(frames)
	var phase = 0.0
	var phase_inc = freq / SAMPLE_RATE
	for i in range(frames):
		var sq = 1.0 if phase < 0.5 else -1.0
		# Envelope: quick attack, exponential decay
		var t = float(i) / frames
		var env = exp(-t * 5.0) * vol
		buf[i] = Vector2(sq * env, sq * env)
		phase += phase_inc
		if phase >= 1.0:
			phase -= 1.0
	pb.push_buffer(buf)

func whistle(long: bool = false) -> void:
	var p = _free_player()
	p.stop()
	p.play()
	var pb: AudioStreamGeneratorPlayback = p.get_stream_playback()
	if pb == null: return
	var dur = 0.55 if long else 0.22
	var frames = int(dur * SAMPLE_RATE)
	var buf = PackedVector2Array()
	buf.resize(frames)
	var phase = 0.0
	var base_freq = 2350.0
	var vibrato_freq = 38.0
	var vibrato_depth = 420.0
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var freq = base_freq + sin(t * vibrato_freq * TAU) * vibrato_depth
		var phase_inc = freq / SAMPLE_RATE
		var sq = 1.0 if phase < 0.5 else -1.0
		var norm_t = float(i) / frames
		var env: float
		if norm_t < 0.05:
			env = norm_t / 0.05 * 0.4
		else:
			env = exp(-(norm_t - 0.05) * 6.0) * 0.4
		buf[i] = Vector2(sq * env, sq * env)
		phase += phase_inc
		if phase >= 1.0:
			phase -= 1.0
	pb.push_buffer(buf)

func sfx_good() -> void:
	beep(523, 0.09, 0.4)
	await get_tree().create_timer(0.09).timeout
	beep(659, 0.09, 0.4)
	await get_tree().create_timer(0.09).timeout
	beep(880, 0.16, 0.4)

func sfx_bad() -> void:
	beep(196, 0.12, 0.4)
	await get_tree().create_timer(0.12).timeout
	beep(147, 0.22, 0.4)

func sfx_tick() -> void:
	beep(1046, 0.05, 0.25)

func sfx_partial() -> void:
	beep(440, 0.12, 0.4)
	await get_tree().create_timer(0.12).timeout
	beep(494, 0.12, 0.4)
