extends Control
## Fullscreen referee reaction — raises card, nods, or shakes head.

var visible_tint: Color = Color(0, 0, 0, 0)
var arm_angle: float = 8.0  # degrees
var card_color: Color = Color("#F5C518")
var card_visible: bool = false
var head_offset: float = 0.0
var body_offset_y: float = 0.0
var reaction_start_ms: int = 0
var current_reaction: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func trigger(kind: String) -> void:
	current_reaction = kind
	reaction_start_ms = Time.get_ticks_msec()
	card_visible = kind == "yellow" or kind == "red"
	if kind == "yellow":
		card_color = Color("#F5C518")
		visible_tint = Color(0.96, 0.77, 0.09, 0.16)
	elif kind == "red":
		card_color = Color("#E43B44")
		visible_tint = Color(0.89, 0.23, 0.26, 0.20)
	elif kind == "good":
		visible_tint = Color(0.49, 0.91, 0.63, 0.12)
	else:
		visible_tint = Color(0, 0, 0, 0.36)
	queue_redraw()

func _process(_delta: float) -> void:
	if current_reaction == "":
		return
	var elapsed = (Time.get_ticks_msec() - reaction_start_ms) / 1000.0
	if elapsed > 1.3:
		current_reaction = ""
		visible_tint = Color(0, 0, 0, 0)
		queue_redraw()
		return

	# Animate based on reaction
	if current_reaction == "yellow" or current_reaction == "red":
		# Arm sweeps up (raise card)
		arm_angle = lerp(8.0, -143.0, min(1.0, elapsed / 0.6))
		head_offset = 0.0
		body_offset_y = 0.0
	elif current_reaction == "good":
		# Bounce head down/up (nod), arm sweeps across
		arm_angle = lerp(8.0, -62.0, min(1.0, elapsed / 0.6))
		var bounce = sin(elapsed * PI * 3.0) * 12.0 * (1.0 - min(1.0, elapsed / 0.6))
		body_offset_y = -bounce
		head_offset = 0.0
	else:
		# Bad — shake head + wag arm
		head_offset = sin(elapsed * 20.0) * 10.0
		arm_angle = -42.0 + sin(elapsed * 18.0) * 20.0
		body_offset_y = 0.0
	queue_redraw()

func _draw() -> void:
	# Tint layer
	if visible_tint.a > 0:
		draw_rect(Rect2(Vector2.ZERO, size), visible_tint, true)
	if current_reaction == "":
		return
	# Center the ref pixel art
	var svg_w = min(size.x * 0.52, 200.0)
	var svg_h = svg_w * (320.0 / 220.0)
	var origin = Vector2((size.x - svg_w) * 0.5, (size.y - svg_h) * 0.5 + body_offset_y)
	_draw_ref(origin, svg_w / 220.0)

func _draw_ref(origin: Vector2, scale: float) -> void:
	# Shadow
	_r(origin, scale, 60, 296, 100, 10, Color(0, 0, 0, 0.35))
	# Legs
	_r(origin, scale, 86, 214, 18, 62, Color("#0E0F12"))
	_r(origin, scale, 118, 214, 18, 62, Color("#0E0F12"))
	# Sock
	_r(origin, scale, 86, 252, 18, 26, Color("#26282E"))
	_r(origin, scale, 118, 252, 18, 26, Color("#26282E"))
	# Boots
	_r(origin, scale, 78, 272, 30, 14, Color("#000"))
	_r(origin, scale, 114, 272, 30, 14, Color("#000"))
	# Shorts
	_r(origin, scale, 80, 194, 62, 30, Color("#0E0F12"))
	# Body/shirt
	_r(origin, scale, 68, 128, 86, 74, Color("#15161A"))
	# Collar
	_r(origin, scale, 98, 128, 26, 12, Color("#F5F7F2"))
	# Badge
	_r(origin, scale, 82, 146, 12, 12, Color("#F5C518"))
	# Right (still) arm
	_r(origin, scale, 52, 140, 16, 52, Color("#15161A"))
	_r(origin, scale, 50, 192, 16, 14, Color("#F0C48C"))
	# Head (with shake offset)
	var head_origin = origin + Vector2(head_offset * scale, 0)
	_r(head_origin, scale, 85, 66, 52, 52, Color("#F0C48C"))
	_r(head_origin, scale, 85, 60, 52, 14, Color("#22232A"))  # cap
	_r(head_origin, scale, 81, 70, 8, 12, Color("#22232A"))   # cap bill
	_r(head_origin, scale, 97, 88, 6, 6, Color("#111"))       # left eye
	_r(head_origin, scale, 119, 88, 6, 6, Color("#111"))      # right eye
	_r(head_origin, scale, 102, 104, 16, 4, Color("#8A5A3B")) # mouth
	_r(head_origin, scale, 120, 106, 18, 10, Color("#C7CCD6")) # whistle

	# Left (moving) arm — rotated
	_draw_arm(origin, scale)

func _draw_arm(origin: Vector2, scale: float) -> void:
	# Pivot at top of arm (146, 138 in svg coords)
	var pivot = origin + Vector2(154 * scale, 148 * scale)
	var angle_rad = deg_to_rad(arm_angle)
	# Draw rotated arm rectangle using triangles
	var arm_rect = Rect2(Vector2(-8 * scale, 0), Vector2(16 * scale, 58 * scale))
	_draw_rotated_rect(pivot, arm_rect, angle_rad, Color("#15161A"))
	# Hand
	var hand_rect = Rect2(Vector2(-8 * scale, 58 * scale), Vector2(16 * scale, 14 * scale))
	_draw_rotated_rect(pivot, hand_rect, angle_rad, Color("#F0C48C"))
	# Card (only if raised)
	if card_visible:
		var card_rect = Rect2(Vector2(-13 * scale, 70 * scale), Vector2(26 * scale, 38 * scale))
		_draw_rotated_rect(pivot, card_rect, angle_rad, card_color)

func _r(origin: Vector2, scale: float, x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(origin + Vector2(x, y) * scale, Vector2(w, h) * scale), col, true)

func _draw_rotated_rect(pivot: Vector2, local_rect: Rect2, angle: float, col: Color) -> void:
	var pts = PackedVector2Array()
	var corners = [
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0),
		local_rect.position + local_rect.size,
		local_rect.position + Vector2(0, local_rect.size.y),
	]
	var cos_a = cos(angle)
	var sin_a = sin(angle)
	for c in corners:
		pts.append(pivot + Vector2(c.x * cos_a - c.y * sin_a, c.x * sin_a + c.y * cos_a))
	draw_colored_polygon(pts, col)
