extends Control
## Root of Main.tscn — runs Menu → Game → Results loop.

const MENU := 0
const GAME := 1
const RESULTS := 2

# UI refs (built at runtime)
var pitch_bg: ColorRect
var scanlines: Control
var menu_panel: Control
var game_panel: Control
var results_panel: Control
var ref_overlay: Control
var audio: Node
var pixel_scene: Control

# Menu widgets
var menu_title_en: Label
var menu_title_ar: Label
var menu_tagline: Label
var play_btn: Button
var en_btn: Button
var ar_btn: Button
var hs_label: Label

# Game widgets
var qnum_label: Label
var streak_label: Label
var score_label: Label
var timer_bar: ProgressBar
var scenario_text: Label
var answers_container: VBoxContainer
var explain_panel: Control
var verdict_label: Label
var explain_text: Label
var points_pop: Label

# Results widgets
var final_score_label: Label
var acc_label: Label
var rank_title: Label
var rank_sub: Label
var newbest_label: Label

# State
var deck: Array = []
var qi: int = 0
var score: int = 0
var streak: int = 0
var correct_count: int = 0
var time_left: float = Data.TIME_PER_Q
var locked: bool = false
var timer_active: bool = false
var last_tick: int = 0

func _ready() -> void:
	_setup_root()
	_build_menu()
	_build_game()
	_build_results()
	audio = preload("res://scripts/Audio.gd").new()
	add_child(audio)
	ref_overlay = preload("res://scripts/RefereeOverlay.gd").new()
	add_child(ref_overlay)
	_show_screen(MENU)
	_apply_locale()

func _setup_root() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Pitch stripes background
	pitch_bg = ColorRect.new()
	pitch_bg.color = Color("#0B1226")
	pitch_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pitch_bg)

func _make_style(bg: Color, border_col: Color = Color.WHITE, border: int = 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border_col
	s.border_width_left = border
	s.border_width_top = border
	s.border_width_right = border
	s.border_width_bottom = border
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 5
	s.shadow_offset = Vector2(5, 5)
	return s

func _make_button(label: String, size: int, bg: Color, border: Color = Color.WHITE) -> Button:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _make_style(bg, border))
	var hov := _make_style(bg.lightened(0.1), border)
	b.add_theme_stylebox_override("hover", hov)
	var pressed := _make_style(bg.darkened(0.15), border)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_color_override("font_color", Color.WHITE if bg.get_luminance() < 0.55 else Color.BLACK)
	return b

# ---------- MENU ----------
func _build_menu() -> void:
	menu_panel = Control.new()
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_panel)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.custom_minimum_size = Vector2(360, 460)
	v.position = Vector2(-180, -230)
	v.add_theme_constant_override("separation", 16)
	menu_panel.add_child(v)

	menu_title_en = Label.new()
	menu_title_en.text = "YOU MAKE\nTHE CALL"
	menu_title_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title_en.add_theme_font_size_override("font_size", 40)
	menu_title_en.add_theme_color_override("font_color", Color("#F5F7F2"))
	menu_title_en.add_theme_constant_override("outline_size", 4)
	menu_title_en.add_theme_color_override("font_outline_color", Color("#0A0C14"))
	v.add_child(menu_title_en)

	menu_title_ar = Label.new()
	menu_title_ar.text = "أنت الحكم"
	menu_title_ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title_ar.add_theme_font_size_override("font_size", 36)
	menu_title_ar.add_theme_color_override("font_color", Color("#F5C518"))
	v.add_child(menu_title_ar)

	menu_tagline = Label.new()
	menu_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_tagline.add_theme_font_size_override("font_size", 16)
	menu_tagline.add_theme_color_override("font_color", Color("#F5F7F2AA"))
	menu_tagline.custom_minimum_size = Vector2(320, 60)
	v.add_child(menu_tagline)

	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.add_theme_constant_override("separation", 12)
	v.add_child(lang_row)
	en_btn = _make_button("English", 18, Color("#0A0C14"), Color("#F5F7F2AA"))
	en_btn.custom_minimum_size = Vector2(120, 46)
	en_btn.pressed.connect(func(): _set_lang("en"))
	lang_row.add_child(en_btn)
	ar_btn = _make_button("العربية", 20, Color("#0A0C14"), Color("#F5F7F2AA"))
	ar_btn.custom_minimum_size = Vector2(120, 46)
	ar_btn.pressed.connect(func(): _set_lang("ar"))
	lang_row.add_child(ar_btn)

	play_btn = _make_button("KICK OFF", 26, Color("#F5C518"), Color("#0A0C14"))
	play_btn.custom_minimum_size = Vector2(240, 60)
	play_btn.pressed.connect(_start_game)
	v.add_child(play_btn)

	hs_label = Label.new()
	hs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hs_label.add_theme_font_size_override("font_size", 16)
	hs_label.add_theme_color_override("font_color", Color("#F5F7F2AA"))
	v.add_child(hs_label)

# ---------- GAME ----------
func _build_game() -> void:
	game_panel = Control.new()
	game_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_panel)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_top = 18
	v.offset_right = -16
	v.offset_bottom = -18
	v.add_theme_constant_override("separation", 10)
	game_panel.add_child(v)

	# HUD
	var hud := HBoxContainer.new()
	v.add_child(hud)
	qnum_label = Label.new()
	qnum_label.text = "Call 1/10"
	qnum_label.add_theme_font_size_override("font_size", 16)
	qnum_label.size_flags_horizontal = SIZE_EXPAND_FILL
	hud.add_child(qnum_label)
	streak_label = Label.new()
	streak_label.text = "🔥0"
	streak_label.add_theme_font_size_override("font_size", 16)
	streak_label.add_theme_color_override("font_color", Color("#F5C518"))
	hud.add_child(streak_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(30, 0)
	hud.add_child(spacer)
	score_label = Label.new()
	score_label.text = "Pts 0"
	score_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(score_label)

	# Timer bar
	timer_bar = ProgressBar.new()
	timer_bar.min_value = 0
	timer_bar.max_value = Data.TIME_PER_Q
	timer_bar.value = Data.TIME_PER_Q
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(0, 14)
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color("#0A0C14")
	bar_style.border_color = Color("#F5F7F2")
	bar_style.border_width_left = 2
	bar_style.border_width_right = 2
	bar_style.border_width_top = 2
	bar_style.border_width_bottom = 2
	timer_bar.add_theme_stylebox_override("background", bar_style)
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color("#7DE8A0")
	timer_bar.add_theme_stylebox_override("fill", fg)
	v.add_child(timer_bar)

	# Pixel scene
	pixel_scene = preload("res://scripts/PixelScene.gd").new()
	pixel_scene.custom_minimum_size = Vector2(0, 200)
	pixel_scene.size_flags_horizontal = SIZE_EXPAND_FILL
	v.add_child(pixel_scene)

	# Scenario card
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.05, 0.08, 0.82)))
	v.add_child(card)
	var card_v := VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 6)
	card.add_child(card_v)
	var incident_label := Label.new()
	incident_label.text = "MATCH INCIDENT"
	incident_label.add_theme_font_size_override("font_size", 12)
	incident_label.add_theme_color_override("font_color", Color("#7DE8A0"))
	card_v.add_child(incident_label)
	scenario_text = Label.new()
	scenario_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scenario_text.add_theme_font_size_override("font_size", 16)
	card_v.add_child(scenario_text)

	# Answers
	answers_container = VBoxContainer.new()
	answers_container.size_flags_vertical = SIZE_EXPAND_FILL
	answers_container.add_theme_constant_override("separation", 8)
	v.add_child(answers_container)

	# Explain panel (overlay)
	explain_panel = PanelContainer.new()
	explain_panel.add_theme_stylebox_override("panel", _make_style(Color("#F5F7F2"), Color("#0A0C14")))
	explain_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	explain_panel.offset_left = 14
	explain_panel.offset_right = -14
	explain_panel.offset_bottom = -14
	explain_panel.offset_top = -180
	explain_panel.visible = false
	game_panel.add_child(explain_panel)
	var explain_v := VBoxContainer.new()
	explain_v.add_theme_constant_override("separation", 6)
	explain_panel.add_child(explain_v)
	verdict_label = Label.new()
	verdict_label.add_theme_font_size_override("font_size", 16)
	verdict_label.add_theme_color_override("font_color", Color("#0A0C14"))
	explain_v.add_child(verdict_label)
	explain_text = Label.new()
	explain_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain_text.add_theme_font_size_override("font_size", 15)
	explain_text.add_theme_color_override("font_color", Color("#0A0C14"))
	explain_v.add_child(explain_text)

	# Points pop
	points_pop = Label.new()
	points_pop.add_theme_font_size_override("font_size", 24)
	points_pop.add_theme_color_override("font_color", Color("#F5C518"))
	points_pop.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	points_pop.offset_left = -80
	points_pop.offset_top = 200
	points_pop.visible = false
	game_panel.add_child(points_pop)

# ---------- RESULTS ----------
func _build_results() -> void:
	results_panel = Control.new()
	results_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(results_panel)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	v.custom_minimum_size = Vector2(380, 500)
	v.position = Vector2(-190, -250)
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	results_panel.add_child(v)

	var ft := Label.new()
	ft.text = "FULL TIME"
	ft.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ft.add_theme_font_size_override("font_size", 22)
	ft.add_theme_color_override("font_color", Color("#7DE8A0"))
	v.add_child(ft)

	final_score_label = Label.new()
	final_score_label.text = "0"
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score_label.add_theme_font_size_override("font_size", 72)
	final_score_label.add_theme_color_override("font_color", Color("#F5C518"))
	final_score_label.add_theme_constant_override("outline_size", 4)
	final_score_label.add_theme_color_override("font_outline_color", Color("#0A0C14"))
	v.add_child(final_score_label)

	acc_label = Label.new()
	acc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	acc_label.add_theme_font_size_override("font_size", 16)
	acc_label.add_theme_color_override("font_color", Color("#F5F7F2AA"))
	v.add_child(acc_label)

	newbest_label = Label.new()
	newbest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	newbest_label.add_theme_font_size_override("font_size", 16)
	newbest_label.add_theme_color_override("font_color", Color("#7DE8A0"))
	newbest_label.visible = false
	v.add_child(newbest_label)

	var rank_panel := PanelContainer.new()
	rank_panel.add_theme_stylebox_override("panel", _make_style(Color(0.96, 0.77, 0.09, 0.08), Color("#F5C518")))
	rank_panel.custom_minimum_size = Vector2(340, 100)
	v.add_child(rank_panel)
	var rv := VBoxContainer.new()
	rank_panel.add_child(rv)
	rank_title = Label.new()
	rank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rank_title.add_theme_font_size_override("font_size", 20)
	rank_title.add_theme_color_override("font_color", Color("#F5C518"))
	rv.add_child(rank_title)
	rank_sub = Label.new()
	rank_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rank_sub.add_theme_font_size_override("font_size", 14)
	rank_sub.add_theme_color_override("font_color", Color("#F5F7F2AA"))
	rv.add_child(rank_sub)

	var play_again := _make_button("PLAY AGAIN", 22, Color("#F5C518"), Color("#0A0C14"))
	play_again.custom_minimum_size = Vector2(0, 54)
	play_again.pressed.connect(_start_game)
	v.add_child(play_again)

	var menu_back := _make_button("MAIN MENU", 18, Color("#0A0C14"), Color("#F5F7F2AA"))
	menu_back.custom_minimum_size = Vector2(0, 46)
	menu_back.pressed.connect(func(): _show_screen(MENU))
	v.add_child(menu_back)

# ---------- state transitions ----------
func _show_screen(which: int) -> void:
	menu_panel.visible = which == MENU
	game_panel.visible = which == GAME
	results_panel.visible = which == RESULTS

func _set_lang(l: String) -> void:
	Data.lang = l
	Data.save_prefs()
	_apply_locale()

func _apply_locale() -> void:
	# Update all labels for current lang
	menu_tagline.text = Data.t("tagline")
	play_btn.text = Data.t("play")
	hs_label.text = "%s %d" % [Data.t("best"), Data.high_score]
	en_btn.modulate = Color(1, 0.8, 0.05) if Data.lang == "en" else Color.WHITE
	ar_btn.modulate = Color(1, 0.8, 0.05) if Data.lang == "ar" else Color.WHITE

# ---------- game loop ----------
func _start_game() -> void:
	deck = Data.SCENARIOS.duplicate()
	deck.shuffle()
	deck = deck.slice(0, Data.ROUND_LEN)
	qi = 0
	score = 0
	streak = 0
	correct_count = 0
	_show_screen(GAME)
	audio.whistle(true)
	_load_question()

func _load_question() -> void:
	locked = false
	var s = deck[qi]
	var L = s[Data.lang]
	qnum_label.text = "%s %d/%d" % [Data.t("question"), qi + 1, Data.ROUND_LEN]
	streak_label.text = "🔥%d" % streak
	score_label.text = "%s %d" % [Data.t("score"), score]
	scenario_text.text = L.d
	pixel_scene.set_scene(s.anim)
	explain_panel.visible = false

	# Clear + rebuild answer buttons
	for c in answers_container.get_children():
		c.queue_free()
	for i in range(L.a.size()):
		var idx = i
		var b = _make_button(L.a[idx], 14, Color("#0A0C14"), Color("#F5F7F2AA"))
		b.custom_minimum_size = Vector2(0, 56)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func(): _on_answer(idx, b))
		answers_container.add_child(b)

	time_left = Data.TIME_PER_Q
	timer_active = true
	last_tick = int(time_left)
	_update_timer_bar()

func _update_timer_bar() -> void:
	timer_bar.value = time_left
	var pct = time_left / Data.TIME_PER_Q
	var fg := StyleBoxFlat.new()
	if pct > 0.5:
		fg.bg_color = Color("#7DE8A0")
	elif pct > 0.25:
		fg.bg_color = Color("#F5C518")
	else:
		fg.bg_color = Color("#E43B44")
	timer_bar.add_theme_stylebox_override("fill", fg)

func _process(delta: float) -> void:
	if not timer_active or locked:
		return
	time_left -= delta
	_update_timer_bar()
	var current_int = int(ceil(time_left))
	if current_int != last_tick and current_int <= 5 and current_int > 0:
		last_tick = current_int
		audio.sfx_tick()
	if time_left <= 0:
		timer_active = false
		_time_up()

func _on_answer(i: int, btn: Button) -> void:
	if locked: return
	locked = true
	timer_active = false
	var s = deck[qi]
	var correct_idx: int = s.c
	var partial_idx: int = s.get("p", -1)
	var buttons = answers_container.get_children()

	# Highlight correct
	if correct_idx >= 0 and correct_idx < buttons.size():
		var cb: Button = buttons[correct_idx]
		cb.add_theme_stylebox_override("normal", _make_style(Color("#10251A"), Color("#7DE8A0")))
		cb.add_theme_color_override("font_color", Color("#7DE8A0"))

	var gained := 0
	var verdict_key := ""
	var verdict_col := Color.BLACK
	if i == correct_idx:
		gained = 10
		correct_count += 1
		streak += 1
		verdict_key = "correct"
		verdict_col = Color("#1C7A3F")
		audio.sfx_good()
		ref_overlay.trigger(s.get("card", "good"))
	elif i == partial_idx:
		gained = 5
		streak = 0
		btn.add_theme_stylebox_override("normal", _make_style(Color("#2A2208"), Color("#F5C518")))
		btn.add_theme_color_override("font_color", Color("#F5C518"))
		verdict_key = "partial"
		verdict_col = Color("#8A6D00")
		audio.sfx_partial()
	else:
		streak = 0
		btn.add_theme_stylebox_override("normal", _make_style(Color("#2A0F12"), Color("#E43B44")))
		btn.add_theme_color_override("font_color", Color("#E43B44"))
		verdict_key = "wrong"
		verdict_col = Color("#B3242F")
		audio.sfx_bad()
		ref_overlay.trigger("bad")

	var bonus = 5 if streak > 0 and streak % 3 == 0 else 0
	score += gained + bonus
	streak_label.text = "🔥%d" % streak
	score_label.text = "%s %d" % [Data.t("score"), score]
	if gained + bonus > 0:
		points_pop.text = "+%d%s" % [gained + bonus, "!" if bonus > 0 else ""]
		points_pop.visible = true
		var tween = create_tween()
		tween.tween_property(points_pop, "position:y", 180.0, 0.9).from(220.0)
		tween.parallel().tween_property(points_pop, "modulate:a", 0.0, 0.9).from(1.0)
		tween.tween_callback(func(): points_pop.visible = false; points_pop.modulate.a = 1.0)

	_show_explain(verdict_key, verdict_col, deck[qi][Data.lang].x)

func _time_up() -> void:
	if locked: return
	locked = true
	streak = 0
	streak_label.text = "🔥0"
	var s = deck[qi]
	var buttons = answers_container.get_children()
	for b in buttons:
		b.disabled = true
	if s.c >= 0 and s.c < buttons.size():
		var cb: Button = buttons[s.c]
		cb.add_theme_stylebox_override("normal", _make_style(Color("#10251A"), Color("#7DE8A0")))
	audio.sfx_bad()
	ref_overlay.trigger("bad")
	_show_explain("timeout", Color("#B3242F"), s[Data.lang].x)

func _show_explain(vk: String, vc: Color, text: String) -> void:
	verdict_label.text = Data.t(vk)
	verdict_label.add_theme_color_override("font_color", vc)
	explain_text.text = text
	explain_panel.visible = true
	await get_tree().create_timer(3.4).timeout
	_next_question()

func _next_question() -> void:
	qi += 1
	if qi >= Data.ROUND_LEN:
		_end_game()
	else:
		_load_question()

func _end_game() -> void:
	audio.whistle(true)
	final_score_label.text = str(score)
	var acc = int(round(float(correct_count) / Data.ROUND_LEN * 100))
	acc_label.text = "%s %d%%" % [Data.t("accuracy"), acc]
	var r = Data.rank_for(score)
	rank_title.text = r[Data.lang][0]
	rank_sub.text = r[Data.lang][1]
	var is_best = score > Data.high_score
	if is_best:
		Data.high_score = score
		Data.save_prefs()
		newbest_label.text = "★ " + Data.t("newbest")
		newbest_label.visible = true
	else:
		newbest_label.visible = false
	_show_screen(RESULTS)
