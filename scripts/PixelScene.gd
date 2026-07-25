extends Control
## Retro pixel canvas — draws a per-scenario mini-animation at ~12fps.
## Coordinates match the HTML source: 192×84 logical, scaled to fit.

const LOGICAL_W := 192.0
const LOGICAL_H := 84.0
const G := 76  # ground line y-coord

const RED := Color("#E43B44")
const BLU := Color("#2C6FD1")
const YEL := Color("#F5C518")
const BLK := Color("#181818")
const GRN := Color("#39D06A")
const SKIN := Color("#F0C48C")
const WHITE := Color.WHITE
const BLACK := Color.BLACK

const CROWD := [Color("#1B2440"), Color("#26325A"), Color("#31406F"), Color("#20294A"),
	Color("#3A4A80"), Color("#1B2440"), Color("#26325A"), Color("#101830"), Color("#26325A")]

var anim_name: String = ""
var anim_start_ms: int = 0
var last_frame_ms: int = 0
var scale_factor: float = 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(LOGICAL_W * 2, LOGICAL_H * 2)
	resized.connect(_recalc_scale)
	_recalc_scale()

func _recalc_scale() -> void:
	if size.x > 0 and size.y > 0:
		var sx = size.x / LOGICAL_W
		var sy = size.y / LOGICAL_H
		scale_factor = min(sx, sy)

func set_scene(name: String) -> void:
	anim_name = name
	anim_start_ms = Time.get_ticks_msec()
	queue_redraw()

func _process(_delta: float) -> void:
	if anim_name == "":
		return
	var now = Time.get_ticks_msec()
	if now - last_frame_ms >= 80:  # 12 fps
		last_frame_ms = now
		queue_redraw()

func _draw() -> void:
	# Black background border area
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#000"))
	if anim_name == "":
		return
	var t = float((Time.get_ticks_msec() - anim_start_ms) % 2600) / 2600.0
	_pitch()
	if has_method("_anim_" + anim_name):
		call("_anim_" + anim_name, t)

# ---------- helpers ----------
func _px(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(int(x) * scale_factor, int(y) * scale_factor, w * scale_factor, h * scale_factor), col, true)

func _ph(t: float, a: float, b: float) -> float:
	return clamp((t - a) / max(0.0001, b - a), 0.0, 1.0)

func _F(t: float) -> int:
	return int(t * 12) % 2

func _bang(x: float, y: float) -> void:
	_px(x, y, 3, 7, YEL)
	_px(x, y + 9, 3, 3, YEL)

func _ball_at(x: float, y: float, f: int) -> void:
	_px(x - 1, y - 3, 4, 4, WHITE)
	_px(x + (f % 2), y - 2, 1, 1, BLACK)

func _goal_r() -> void:
	_px(176, 44, 3, 34, WHITE)
	_px(176, 44, 16, 3, WHITE)
	var faded = Color(1, 1, 1, 0.28)
	for i in range(180, 192, 3):
		_px(i, 47, 1, 30, faded)
	for j in range(50, 77, 4):
		_px(180, j, 12, 1, faded)

func _pitch() -> void:
	# Crowd rows
	for y in range(0, 12, 2):
		for x in range(0, 192, 2):
			_px(x, y, 2, 2, CROWD[(x * 31 + y * 17) % 9])
	_px(0, 12, 192, 2, Color("#0B1226"))
	# Alternating grass stripes
	for x in range(0, 192, 24):
		var c = Color("#27893F") if (x / 24) % 2 else Color("#2E9C4C")
		_px(x, 14, 24, 70, c)
	_px(0, 77, 192, 1, Color(1, 1, 1, 0.55))
	_px(140, 71, 1, 6, WHITE)
	_px(150, 74, 2, 2, WHITE)
	_goal_r()

func _guy(x: float, y: float, shirt: Color, f: int, o: Dictionary = {}) -> void:
	x = int(x)
	y = int(y)
	if o.get("fall", false):
		_px(x, y - 4, 4, 4, SKIN)
		_px(x + 4, y - 4, 9, 4, shirt)
		_px(x + 13, y - 3, 4, 2, o.get("shorts", WHITE))
		return
	_px(x + 1, y - 15, 5, 2, o.get("hair", Color("#222")))
	_px(x + 1, y - 13, 5, 3, SKIN)
	_px(x, y - 10, 7, 5, shirt)
	if o.get("armsUp", false):
		_px(x - 2, y - 15, 2, 6, shirt)
		_px(x + 7, y - 15, 2, 6, shirt)
	else:
		_px(x - 1, y - 10, 1, 4, shirt)
		_px(x + 7, y - 10, 1, 4, shirt)
	_px(x, y - 5, 7, 2, o.get("shorts", WHITE))
	var l = f % 2
	_px(x + (0 if l else 1), y - 3, 2, 3, Color("#111"))
	_px(x + (5 if l else 4), y - 3, 2, 3, Color("#111"))

# ---------- animations (one per scenario) ----------
## Retro Goal-style top-down slide tackle. Whole pitch visible from above,
## players are ~5x8 blocks with shirt/shorts/head, real run + slide cycles.
func _anim_slide(t: float) -> void:
	_pitch_topdown()
	var f = _F(t)  # 2-frame walk cycle

	# Attacker (RED shirt) dribbles left→right along mid-lane, then falls
	# Defender (BLU shirt) sprints in from upper-left, slides at t≈0.55
	# Ball tracks attacker's front foot until tackle, then squirts forward
	var att_x: float
	var att_y: float = 46
	var def_x: float
	var def_y: float
	var ball_x: float
	var ball_y: float

	if t < 0.55:
		var p = _ph(t, 0, 0.55)
		att_x = 60 + 60 * p
		def_x = 20 + 80 * p
		def_y = 30 + 15 * p  # angles down toward attacker
		ball_x = att_x + 8
		ball_y = att_y - 1
		_topdown_player(att_x, att_y, RED, WHITE, f, 0)         # running east
		_topdown_player(def_x, def_y, BLU, WHITE, f, 30)        # angling in
		_ball_topdown(ball_x, ball_y, f)
	else:
		var q = _ph(t, 0.55, 1)
		# Defender extends into a slide — long horizontal shape
		var slide_x = 90 + 8 * q
		var slide_y = 46
		_topdown_player_sliding(slide_x, slide_y, BLU, WHITE, 90)
		# Attacker tumbles — smaller crumpled shape past contact point
		_topdown_player_fallen(100, 45, RED, WHITE, q)
		# Ball squirts forward past the tackle
		ball_x = 108 + 60 * q
		ball_y = 45 - 6 * sin(q * PI) * 0.5
		_ball_topdown(ball_x, ball_y, f)
		# Impact spark
		if q < 0.35:
			_impact_burst(96, 46, 1.0 - q / 0.35)

func _pitch_topdown() -> void:
	# Alternating grass stripes going TOP-DOWN (bands across the pitch length)
	var band_a = Color("#2E9C4C")
	var band_b = Color("#27893F")
	for x in range(0, int(LOGICAL_W), 24):
		var c = band_a if (x / 24) % 2 == 0 else band_b
		_px(x, 0, 24, LOGICAL_H, c)
	# Halfway line vertical
	_px(int(LOGICAL_W / 2) - 1, 0, 1, int(LOGICAL_H), Color(1, 1, 1, 0.75))
	# Center circle (small)
	_circle_ring(int(LOGICAL_W / 2), int(LOGICAL_H / 2), 8, Color(1, 1, 1, 0.75))
	# Sidelines
	_px(0, 0, LOGICAL_W, 1, Color(1, 1, 1, 0.6))
	_px(0, LOGICAL_H - 1, LOGICAL_W, 1, Color(1, 1, 1, 0.6))
	# Left penalty box
	_px(0, 22, 20, 1, WHITE)
	_px(20, 22, 1, 40, WHITE)
	_px(0, 62, 20, 1, WHITE)
	# Right penalty box
	_px(172, 22, 20, 1, WHITE)
	_px(172, 22, 1, 40, WHITE)
	_px(172, 62, 20, 1, WHITE)
	# Goals (very small ends)
	_px(0, 36, 2, 12, WHITE)
	_px(190, 36, 2, 12, WHITE)

func _circle_ring(cx: int, cy: int, r: int, col: Color) -> void:
	# Rough pixel ring — plot 16 arc points
	for i in range(16):
		var ang = i / 16.0 * TAU
		var x = cx + int(round(cos(ang) * r))
		var y = cy + int(round(sin(ang) * r))
		_px(x, y, 1, 1, col)

func _topdown_player(x: float, y: float, shirt: Color, shorts: Color, f: int, facing_deg: float) -> void:
	# Facing_deg unused for simple top-down; player facing "east" (+x)
	# Shadow
	_px(x - 2, y + 4, 6, 1, Color(0, 0, 0, 0.35))
	# Shorts (below shirt in top-down = "bottom" of sprite, dark)
	_px(x - 2, y + 2, 6, 2, Color("#111"))
	# Shirt (main body)
	_px(x - 2, y - 2, 6, 4, shirt)
	# Head (skin on top)
	_px(x - 1, y - 5, 4, 3, SKIN)
	# Hair dot
	_px(x - 1, y - 6, 4, 1, Color("#3B2818"))
	# Feet (2-frame alternating)
	if f == 0:
		_px(x - 2, y + 4, 2, 1, Color("#111"))
		_px(x + 2, y + 4, 2, 1, Color("#111"))
	else:
		_px(x - 1, y + 4, 2, 1, Color("#111"))
		_px(x + 1, y + 4, 2, 1, Color("#111"))

func _topdown_player_sliding(x: float, y: float, shirt: Color, shorts: Color, facing_deg: float) -> void:
	# Sliding = elongated horizontal shape, arms tucked
	# Shadow (long)
	_px(x - 8, y + 3, 16, 2, Color(0, 0, 0, 0.4))
	# Legs stretched forward
	_px(x + 2, y - 1, 6, 3, Color("#111"))
	_px(x + 8, y, 3, 1, Color("#111"))  # foot
	# Shirt (compressed under motion)
	_px(x - 4, y - 2, 6, 4, shirt)
	# Head trailing
	_px(x - 7, y - 1, 3, 2, SKIN)
	# Motion lines
	_px(x - 10, y - 1, 2, 1, Color(1, 1, 1, 0.7))
	_px(x - 10, y + 1, 2, 1, Color(1, 1, 1, 0.7))

func _topdown_player_fallen(x: float, y: float, shirt: Color, shorts: Color, q: float) -> void:
	# Crumpled: shirt is a lump, legs sprawled at odd angles
	var jitter = int(q * 3) % 2
	# Shadow
	_px(x - 4, y + 3, 10, 2, Color(0, 0, 0, 0.35))
	# Body scrunched
	_px(x - 3, y - 2, 6, 4, shirt)
	# Head off to side
	_px(x - 6, y, 3, 3, SKIN)
	# Sprawled leg 1 (up-right)
	_px(x + 3, y - 2 + jitter, 4, 2, Color("#111"))
	# Sprawled leg 2 (down)
	_px(x + 2, y + 2, 3, 2, Color("#111"))

func _ball_topdown(x: float, y: float, f: int) -> void:
	# Shadow below the ball
	_px(x - 1, y + 3, 3, 1, Color(0, 0, 0, 0.4))
	# Ball
	_px(x - 1, y - 1, 3, 3, WHITE)
	# Pentagon dot for classic look
	_px(x + (0 if f == 0 else 1) - 1, y, 1, 1, BLACK)

func _impact_burst(x: float, y: float, intensity: float) -> void:
	# Little cross of yellow pixels
	var alpha = intensity
	var spark = Color(1, 0.85, 0.1, alpha)
	_px(x, y - 3, 1, 2, spark)
	_px(x, y + 2, 1, 2, spark)
	_px(x - 3, y, 2, 1, spark)
	_px(x + 2, y, 2, 1, spark)
	_px(x - 1, y - 1, 3, 3, Color(1, 1, 0.4, alpha * 0.6))

func _anim_passback(t: float) -> void:
	var f = _F(t)
	_guy(96, G, BLU, 0)
	var rx = 154 + (18 * _ph(t, 0.55, 1) if t > 0.55 else 0)
	_guy(rx, G, RED, f if t > 0.55 else 0)
	if t < 0.55:
		_ball_at(103 + 52 * _ph(t, 0.1, 0.55), G, f)
	else:
		_ball_at(rx + 9, G, f)

func _anim_keeperOut(t: float) -> void:
	var f = _F(t)
	_guy(56, G, RED, f if t < 0.5 else 0)
	if t < 0.5:
		_guy(172 - 40 * _ph(t, 0, 0.5), G, YEL, f)
		_ball_at(62 + 70 * _ph(t, 0, 0.5), G - 4, f)
	else:
		_guy(132, G, YEL, 0, {"armsUp": true})
		_ball_at(135, G - 18 - 5 * sin(_ph(t, 0.5, 1) * TAU), 0)
		_bang(140, 44)

func _anim_lineHand(t: float) -> void:
	_guy(156, G, YEL, 0, {"fall": true})
	_guy(170, G, BLU, 0, {"armsUp": true})
	_guy(78, G, RED, 0)
	if t < 0.55:
		var p = _ph(t, 0, 0.55)
		_ball_at(84 + 86 * p, G - 8 - 16 * sin(p * PI), _F(t))
	else:
		var q = _ph(t, 0.55, 1)
		_ball_at(170 - 58 * q, G - 20 + 14 * q, _F(t))
		_bang(162, 42)

func _anim_armGoal(t: float) -> void:
	_guy(148, G, RED, 0)
	if t < 0.4:
		var p = _ph(t, 0, 0.4)
		_ball_at(88 + 58 * p, G - 6 - 14 * sin(p * PI), _F(t))
	elif t < 0.55:
		_ball_at(150, G - 9, 0)
		_bang(144, 46)
	else:
		_ball_at(152 + 32 * _ph(t, 0.55, 0.85), G - 3, _F(t))

func _anim_twoFoot(t: float) -> void:
	var f = _F(t)
	_ball_at(96, G, 0)
	if t < 0.45:
		_guy(40 + 42 * _ph(t, 0, 0.45), G, BLU, f)
		_guy(152 - 42 * _ph(t, 0, 0.45), G, RED, f)
	else:
		_guy(82, G - 3, BLU, 0, {"fall": true})
		_guy(112, G, RED, 0, {"fall": true})
		_bang(94, 42)

func _anim_shirtOff(t: float) -> void:
	_ball_at(185, G, 0)
	_guy(118, G, SKIN, int(t * 8) % 2, {"hair": Color("#222")})
	_px(115 + sin(t * 12.5) * 5, G - 24, 9, 5, RED)

func _anim_keeperHold(t: float) -> void:
	_guy(166, G, YEL, 0)
	_ball_at(164, G - 8, 0)
	_guy(124 + 8 * sin(t * TAU), G, RED, int(t * 10) % 2)
	var n = min(8, int(1 + t * 9))
	for i in range(n):
		_px(146 + i * 4, 42, 3, 3, WHITE if i < 5 else YEL)
	if t > 0.85:
		_bang(182, 38)

func _anim_subBlock(t: float) -> void:
	_guy(66, G, RED, 0)
	if t < 0.5:
		_ball_at(76 + 88 * _ph(t, 0, 0.5), G - 6 - 12 * sin(_ph(t, 0, 0.5) * PI), _F(t))
		_guy(6 + 142 * _ph(t, 0, 0.5), G, GRN, int(t * 14) % 2)
	else:
		_guy(148, G, GRN, 0, {"armsUp": true})
		var q = _ph(t, 0.5, 1)
		_ball_at(164 - 40 * q, G - 14 + 9 * q, _F(t))
		_bang(156, 40)

func _anim_clap(t: float) -> void:
	_guy(100, G, BLK, 0, {"shorts": BLK})
	_guy(130, G, BLU, 0)
	var o = 3 if int(t * 8) % 2 else 0
	_px(127 - o, G - 17, 3, 3, SKIN)
	_px(136 + o, G - 17, 3, 3, SKIN)
	if t > 0.5:
		_bang(138, 46)

func _anim_blockSight(t: float) -> void:
	_guy(168, G, YEL, 0)
	_guy(158, G, RED, 0)
	_guy(66, G, RED, 0)
	var p = _ph(t, 0.1, 0.7)
	_ball_at(74 + 108 * p, G - 8 - 16 * sin(p * PI), _F(t))
	if t > 0.7:
		_bang(148, 40)

func _anim_throwIn(t: float) -> void:
	var lift = 3 if t > 0.35 else 0
	_guy(88, G - lift, BLU, 0, {"armsUp": true})
	if t < 0.5:
		_ball_at(92, G - 22 - lift, 0)
	else:
		var q = _ph(t, 0.5, 1)
		_ball_at(92 + 54 * q, G - 22 - 8 * sin(q * PI), _F(t))
	if t > 0.35:
		_bang(80, 60)

func _anim_backpassPick(t: float) -> void:
	_guy(98, G, BLU, 0)
	_guy(166, G, YEL, 0)
	if t < 0.45:
		_ball_at(106 + 56 * _ph(t, 0.05, 0.45), G, _F(t))
	else:
		_ball_at(164, G - 8, 0)
		_bang(172, 40)

func _anim_doubleTouch(t: float) -> void:
	_guy(150, G, RED, 0)
	if t < 0.35:
		_ball_at(158 + 19 * _ph(t, 0, 0.35), G - 3, _F(t))
	elif t < 0.65:
		_ball_at(177 - 19 * _ph(t, 0.35, 0.65), G - 2, _F(t))
	else:
		_ball_at(158 + 12 * _ph(t, 0.65, 1), G - 1, _F(t))
		_bang(146, 44)

func _anim_penFeint(t: float) -> void:
	_guy(174, G, YEL, 0)
	if t < 0.35:
		_guy(114 + 32 * _ph(t, 0, 0.35), G, RED, int(t * 14) % 2)
		_ball_at(151, G, 0)
	elif t < 0.6:
		_guy(146, G, RED, 0)
		_ball_at(151, G, 0)
		_bang(142, 42)
	else:
		_guy(148, G, RED, 1)
		_ball_at(151 + 30 * _ph(t, 0.6, 0.9), G - 3, _F(t))

func _anim_spit(t: float) -> void:
	_guy(114, G, RED, 0)
	_guy(138, G, BLU, 0)
	var p = fmod(t * 2, 1.0)
	_px(121 + 15 * p, G - 13, 2, 2, Color("#BFE9C8"))
	if p > 0.75:
		_bang(140, 46)

func _anim_refDeflect(t: float) -> void:
	_guy(66, G, BLU, 0)
	_guy(128, G, BLK, 0, {"shorts": BLK})
	if t < 0.4:
		_ball_at(74 + 52 * _ph(t, 0, 0.4), G - 1, _F(t))
	elif t < 0.5:
		_ball_at(129, G - 6, 0)
		_bang(124, 46)
	else:
		_ball_at(131 + 52 * _ph(t, 0.5, 0.9), G - 7 + 6 * _ph(t, 0.5, 0.9), _F(t))

func _anim_advantage(t: float) -> void:
	var f = _F(t)
	_guy(28, G, BLK, 0, {"armsUp": true, "shorts": BLK})
	_guy(66, G, RED, 0, {"fall": t > 0.25})
	_guy(56, G, BLU, 0)
	if t <= 0.25:
		_ball_at(78, G, 0)
	else:
		var x = 84 + 70 * _ph(t, 0.25, 0.85)
		_guy(x - 9, G, RED, f)
		_ball_at(x, G, f)

func _anim_keeperLine(t: float) -> void:
	_guy(148, G, RED, int(t * 14) % 2 if t < 0.35 else 1)
	if t < 0.2:
		_guy(174, G, YEL, 0)
	elif t < 0.45:
		_guy(174 - 14 * _ph(t, 0.2, 0.45), G, YEL, 1)
		_bang(166, 40)
	else:
		_guy(156, G - 2, YEL, 0, {"fall": true})
	if t < 0.35:
		_ball_at(151, G, 0)
	else:
		var p = min(1.0, _ph(t, 0.35, 0.6))
		_ball_at(151 + 15 * p, G - 5 * sin(p * PI), 0)

func _anim_shirtPull(t: float) -> void:
	var f = _F(t)
	if t < 0.6:
		var p = _ph(t, 0, 0.6)
		_guy(68 + 48 * p, G, RED, f)
		_guy(54 + 50 * p, G, BLU, f)
		_ball_at(68 + 48 * p + 9, G, f)
	else:
		_guy(118, G, RED, 0, {"fall": true})
		_guy(106, G, BLU, 0)
		_px(113, G - 9, 6, 2, BLU)
		_bang(116, 42)
		_ball_at(133, G, 0)
