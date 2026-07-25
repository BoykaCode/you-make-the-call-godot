extends Node
## Autoload — UI strings, ranks, 20 scenarios in EN + AR.

const ROUND_LEN := 10
const TIME_PER_Q := 15.0

const UI := {
	"en": {
		"tagline": "READ THE PLAY. MAKE THE CALL. BEAT THE CLOCK.",
		"play": "KICK OFF", "best": "Best:", "question": "Call", "score": "Pts",
		"incident": "MATCH INCIDENT", "fulltime": "FULL TIME", "accuracy": "Accuracy:",
		"again": "PLAY AGAIN", "menu": "MAIN MENU",
		"correct": "CORRECT CALL", "partial": "CLOSE — PARTLY RIGHT",
		"wrong": "WRONG CALL", "timeout": "TIME'S UP", "newbest": "NEW BEST SCORE!"
	},
	"ar": {
		"tagline": "شاهد اللقطة، اتخذ القرار، واسبق عقارب الساعة.",
		"play": "ابدأ المباراة", "best": "الأفضل:", "question": "القرار", "score": "نقاط",
		"incident": "حالة تحكيمية", "fulltime": "نهاية المباراة", "accuracy": "الدقة:",
		"again": "العب مرة أخرى", "menu": "القائمة الرئيسية",
		"correct": "قرار صحيح", "partial": "قريب — صحيح جزئيًا",
		"wrong": "قرار خاطئ", "timeout": "انتهى الوقت", "newbest": "رقم قياسي جديد!"
	}
}

const RANKS := [
	{"min": 100, "en": ["WORLD CUP FINAL REF", "Elite. FIFA wants your number."],
		"ar": ["حكم نهائي كأس العالم", "مستوى النخبة. الفيفا يريد رقم هاتفك."]},
	{"min": 70, "en": ["CHAMPIONS LEAGUE REF", "Big nights, big calls."],
		"ar": ["حكم دوري الأبطال", "ليالٍ كبيرة وقرارات كبيرة."]},
	{"min": 40, "en": ["PRO LEAGUE REF", "Solid, with room to grow."],
		"ar": ["حكم الدوري المحترف", "أداء جيد ومجال للتطور."]},
	{"min": 0, "en": ["SUNDAY LEAGUE REF", "Keep the whistle warm and study the Laws."],
		"ar": ["حكم الأحياء", "أبقِ الصافرة دافئة وراجع قوانين اللعبة."]}
]

# Scenarios — same 20 as the HTML source of truth.
# c = correct index (0-3), p = partial credit index (optional), card = 'yellow' | 'red' (optional)
# anim = key into PixelScene.ANIMS
const SCENARIOS := [
	{"anim": "slide", "c": 2, "p": 1, "card": "yellow",
		"en": {"d": "A defender slides in from behind inside the box, clipping the attacker's ankle after the ball is gone.",
			"a": ["Play on", "Penalty only", "Penalty + yellow card", "Penalty + red card"],
			"x": "A reckless challenge in the penalty area: penalty kick and a caution for the defender."},
		"ar": {"d": "مدافع يتدخل من الخلف داخل منطقة الجزاء ويعرقل كاحل المهاجم بعد أن غادرت الكرة.",
			"a": ["استمرار اللعب", "ركلة جزاء فقط", "ركلة جزاء + بطاقة صفراء", "ركلة جزاء + بطاقة حمراء"],
			"x": "تدخل متهور داخل منطقة الجزاء: ركلة جزاء مع إنذار المدافع بالبطاقة الصفراء."}},
	{"anim": "passback", "c": 1,
		"en": {"d": "An attacker standing in an offside position receives the ball directly from a defender's deliberate back-pass.",
			"a": ["Offside — indirect free kick", "Play on", "Drop ball", "Yellow card for the attacker"],
			"x": "No offence: a deliberate play by an opponent resets offside, so the attacker is onside."},
		"ar": {"d": "مهاجم في موقع تسلل يستلم الكرة مباشرة من تمريرة متعمدة خاطئة من المدافع.",
			"a": ["تسلل — ركلة حرة غير مباشرة", "استمرار اللعب", "كرة حكم", "بطاقة صفراء للمهاجم"],
			"x": "لا مخالفة: اللعب المتعمد من الخصم يلغي التسلل، فالمهاجم في وضع سليم."}},
	{"anim": "keeperOut", "c": 1, "p": 0, "card": "yellow",
		"en": {"d": "The goalkeeper rushes out and handles the ball just outside the penalty area, stopping a promising attack.",
			"a": ["Direct free kick only", "Direct free kick + yellow card", "Direct free kick + red card", "Indirect free kick"],
			"x": "Handling outside the area that stops a promising attack: direct free kick and a caution."},
		"ar": {"d": "الحارس يندفع ويلمس الكرة بيده خارج منطقة الجزاء بقليل، موقفًا هجمة واعدة.",
			"a": ["ركلة حرة مباشرة فقط", "ركلة حرة مباشرة + بطاقة صفراء", "ركلة حرة مباشرة + بطاقة حمراء", "ركلة حرة غير مباشرة"],
			"x": "لمس الكرة باليد خارج المنطقة لإيقاف هجمة واعدة: ركلة حرة مباشرة مع إنذار."}},
	{"anim": "lineHand", "c": 2, "p": 1, "card": "red",
		"en": {"d": "A defender on the goal line deliberately punches a goal-bound shot away with his hand.",
			"a": ["Penalty only", "Penalty + yellow card", "Penalty + red card", "Indirect free kick"],
			"x": "Denying an obvious goal by deliberate handball: penalty kick and a red card."},
		"ar": {"d": "مدافع يقف على خط المرمى يبعد كرة متجهة للشباك بيده عمدًا.",
			"a": ["ركلة جزاء فقط", "ركلة جزاء + بطاقة صفراء", "ركلة جزاء + بطاقة حمراء", "ركلة حرة غير مباشرة"],
			"x": "حرمان من فرصة هدف محقق بلمسة يد متعمدة: ركلة جزاء وبطاقة حمراء."}},
	{"anim": "armGoal", "c": 1,
		"en": {"d": "The ball accidentally brushes an attacker's arm, and he immediately scores from the rebound.",
			"a": ["Goal stands", "No goal — free kick to the defence", "Penalty retake", "Yellow card + goal stands"],
			"x": "A goal scored immediately after an accidental handball by the scorer is disallowed."},
		"ar": {"d": "الكرة تلمس ذراع المهاجم بشكل عرضي، ثم يسجل مباشرة من الارتداد.",
			"a": ["الهدف صحيح", "لا هدف — ركلة حرة للدفاع", "إعادة ركلة الجزاء", "بطاقة صفراء والهدف صحيح"],
			"x": "الهدف المسجل مباشرة بعد لمسة يد عرضية من المسجل نفسه يُلغى."}},
	{"anim": "twoFoot", "c": 2, "p": 1, "card": "red",
		"en": {"d": "A midfielder lunges in with both feet and excessive force near halfway — but wins the ball cleanly.",
			"a": ["Play on — he got the ball", "Foul + yellow card", "Foul + red card", "Drop ball"],
			"x": "Winning the ball never excuses excessive force: serious foul play means a red card."},
		"ar": {"d": "لاعب وسط يتدخل بقدمين وبقوة مفرطة قرب منتصف الملعب — لكنه يصل إلى الكرة أولًا.",
			"a": ["استمرار اللعب — وصل للكرة", "خطأ + بطاقة صفراء", "خطأ + بطاقة حمراء", "كرة حكم"],
			"x": "الوصول إلى الكرة لا يبرر القوة المفرطة أبدًا: اللعب العنيف الجسيم يعني بطاقة حمراء."}},
	{"anim": "shirtOff", "c": 1, "card": "yellow",
		"en": {"d": "A striker scores, then removes his shirt while celebrating with the fans.",
			"a": ["No action — emotion is part of the game", "Goal stands + yellow card", "Disallow the goal", "Red card"],
			"x": "The goal counts, but removing the shirt is a mandatory caution."},
		"ar": {"d": "مهاجم يسجل هدفًا ثم يخلع قميصه أثناء الاحتفال مع الجماهير.",
			"a": ["لا إجراء — الحماس جزء من اللعبة", "الهدف صحيح + بطاقة صفراء", "إلغاء الهدف", "بطاقة حمراء"],
			"x": "الهدف صحيح، لكن خلع القميص إنذار إلزامي بالبطاقة الصفراء."}},
	{"anim": "keeperHold", "c": 1,
		"en": {"d": "The goalkeeper controls the ball with his hands and holds it for 12 seconds, slowing the game down.",
			"a": ["Indirect free kick", "Corner kick to the opponents", "Play on", "Yellow card only"],
			"x": "Under the updated Laws, holding the ball longer than 8 seconds gives a corner kick to the opponents."},
		"ar": {"d": "الحارس يمسك الكرة بيديه ويحتفظ بها ١٢ ثانية لتضييع الوقت.",
			"a": ["ركلة حرة غير مباشرة", "ركلة ركنية للخصم", "استمرار اللعب", "بطاقة صفراء فقط"],
			"x": "وفق التعديل الجديد لقوانين اللعبة، الاحتفاظ بالكرة أكثر من ٨ ثوانٍ يمنح ركلة ركنية للخصم."}},
	{"anim": "subBlock", "c": 2, "card": "red",
		"en": {"d": "A substitute warming up runs onto the pitch and blocks a shot that was heading into the net.",
			"a": ["Drop ball and a warning", "Indirect free kick", "Penalty/free kick where he interfered + red card", "Goal awarded"],
			"x": "An extra person denying a goal: restart where he interfered (penalty if in the box) and a red card."},
		"ar": {"d": "لاعب بديل أثناء الإحماء يدخل الملعب ويعترض كرة كانت متجهة إلى الشباك.",
			"a": ["كرة حكم مع تحذير", "ركلة حرة غير مباشرة", "ركلة جزاء/حرة من مكان التدخل + بطاقة حمراء", "احتساب الهدف"],
			"x": "شخص إضافي يمنع هدفًا: يُستأنف اللعب من مكان التدخل (ركلة جزاء داخل المنطقة) مع بطاقة حمراء."}},
	{"anim": "clap", "c": 1, "card": "yellow",
		"en": {"d": "After a free kick is given against him, a defender sarcastically applauds the referee.",
			"a": ["Ignore it", "Yellow card for dissent", "Red card", "Stop play — drop ball"],
			"x": "Sarcastic applause is dissent by action: a caution."},
		"ar": {"d": "بعد احتساب خطأ ضده، يصفق مدافع للحكم بسخرية.",
			"a": ["تجاهل الأمر", "بطاقة صفراء للاعتراض", "بطاقة حمراء", "إيقاف اللعب — كرة حكم"],
			"x": "التصفيق الساخر اعتراض بالفعل على القرار: يستوجب الإنذار بالبطاقة الصفراء."}},
	{"anim": "blockSight", "c": 0,
		"en": {"d": "A shot flies in, but a teammate in an offside position stands directly in the keeper's line of sight without touching the ball.",
			"a": ["Offside — disallow the goal", "Goal stands — he didn't touch it", "Corner kick", "Retake the shot"],
			"x": "Blocking the keeper's line of vision is interfering with an opponent: offside, no goal."},
		"ar": {"d": "تسديدة تدخل المرمى، لكن زميلًا في موقع تسلل يقف مباشرة في مجال رؤية الحارس دون لمس الكرة.",
			"a": ["تسلل — إلغاء الهدف", "الهدف صحيح — لم يلمس الكرة", "ركلة ركنية", "إعادة التسديدة"],
			"x": "حجب الرؤية عن الحارس تدخّل في الخصم: تسلل والهدف مُلغى."}},
	{"anim": "throwIn", "c": 1,
		"en": {"d": "A player takes a throw-in but lifts his back foot completely off the ground as he releases the ball.",
			"a": ["Play on", "Foul throw — throw-in to the opponents", "Indirect free kick", "Retake the same throw"],
			"x": "Both feet must stay on the ground: the throw-in passes to the opponents."},
		"ar": {"d": "لاعب ينفذ رمية تماس ويرفع قدمه الخلفية بالكامل عن الأرض لحظة إطلاق الكرة.",
			"a": ["استمرار اللعب", "رمية خاطئة — تماس للخصم", "ركلة حرة غير مباشرة", "إعادة الرمية لنفس اللاعب"],
			"x": "يجب أن تبقى القدمان على الأرض: رمية التماس تنتقل إلى الفريق الخصم."}},
	{"anim": "backpassPick", "c": 2,
		"en": {"d": "A defender passes the ball back to his keeper with his foot, and the keeper picks it up with his hands.",
			"a": ["Play on", "Direct free kick", "Indirect free kick", "Penalty"],
			"x": "Handling a deliberate kicked back-pass: indirect free kick where the keeper handled it."},
		"ar": {"d": "مدافع يعيد الكرة بقدمه إلى حارسه، فيلتقطها الحارس بيديه.",
			"a": ["استمرار اللعب", "ركلة حرة مباشرة", "ركلة حرة غير مباشرة", "ركلة جزاء"],
			"x": "إمساك التمريرة المتعمدة بالقدم من الزميل: ركلة حرة غير مباشرة من مكان اللمس."}},
	{"anim": "doubleTouch", "c": 1,
		"en": {"d": "The corner taker's kick hits the post and comes straight back — he plays it again before anyone else touches it.",
			"a": ["Play on", "Indirect free kick — double touch", "Retake the corner", "Goal kick"],
			"x": "Touching the ball twice before another player: indirect free kick to the opponents."},
		"ar": {"d": "منفذ الركنية يسدد فترتد الكرة من القائم إليه مباشرة — فيلعبها مرة أخرى قبل أن يلمسها أحد.",
			"a": ["استمرار اللعب", "ركلة حرة غير مباشرة — لمستان", "إعادة الركنية", "ركلة مرمى"],
			"x": "لمس الكرة مرتين قبل أن يلمسها لاعب آخر: ركلة حرة غير مباشرة للخصم."}},
	{"anim": "penFeint", "c": 2, "card": "yellow",
		"en": {"d": "At a penalty, the kicker finishes his run-up, stops completely to fool the keeper, then scores.",
			"a": ["Goal stands", "Retake the penalty", "No goal — indirect free kick + yellow card", "No goal — corner kick"],
			"x": "Feinting to kick after completing the run-up is illegal: indirect free kick and a caution."},
		"ar": {"d": "في ركلة جزاء، ينهي المنفذ جريته ثم يتوقف تمامًا لخداع الحارس قبل أن يسدد ويسجل.",
			"a": ["الهدف صحيح", "إعادة ركلة الجزاء", "لا هدف — حرة غير مباشرة + بطاقة صفراء", "لا هدف — ركلة ركنية"],
			"x": "التوقف للخداع بعد إتمام الجرية مخالف: ركلة حرة غير مباشرة مع إنذار."}},
	{"anim": "spit", "c": 0, "card": "red",
		"en": {"d": "During a heated argument, a player spits at his opponent. The ball was in play in midfield.",
			"a": ["Red card + direct free kick", "Yellow card for both players", "Indirect free kick", "Talking-to only"],
			"x": "Spitting at an opponent is always a red card, with a direct free kick."},
		"ar": {"d": "أثناء مشادة، يبصق لاعب على منافسه بينما الكرة في اللعب وسط الملعب.",
			"a": ["بطاقة حمراء + ركلة حرة مباشرة", "بطاقة صفراء للاعبين", "ركلة حرة غير مباشرة", "اكتفاء بالتنبيه"],
			"x": "البصق على المنافس بطاقة حمراء دائمًا مع ركلة حرة مباشرة."}},
	{"anim": "refDeflect", "c": 2,
		"en": {"d": "A pass deflects off the referee and rolls into the goal.",
			"a": ["Goal stands", "Corner kick", "No goal — drop ball", "Indirect free kick"],
			"x": "If the ball touches the referee and enters the goal, play restarts with a drop ball."},
		"ar": {"d": "تمريرة ترتد من الحكم وتتدحرج إلى داخل المرمى.",
			"a": ["الهدف صحيح", "ركلة ركنية", "لا هدف — كرة حكم", "ركلة حرة غير مباشرة"],
			"x": "إذا لمست الكرة الحكم ودخلت المرمى، يُستأنف اللعب بكرة حكم."}},
	{"anim": "advantage", "c": 0,
		"en": {"d": "An attacker is fouled, but the ball runs to his teammate who is through on goal with only the keeper to beat.",
			"a": ["Advantage — play on", "Stop play — free kick", "Stop play — penalty", "Drop ball"],
			"x": "With a clear goalscoring chance developing, apply advantage; deal with any card at the next stoppage."},
		"ar": {"d": "مهاجم يتعرض لخطأ، لكن الكرة تصل إلى زميله المنفرد أمام الحارس مباشرة.",
			"a": ["احتساب الأفضلية — استمرار اللعب", "إيقاف اللعب — ركلة حرة", "إيقاف اللعب — ركلة جزاء", "كرة حكم"],
			"x": "مع فرصة تهديف واضحة، تُحتسب الأفضلية، وتُشهر أي بطاقة عند أول توقف للعب."}},
	{"anim": "keeperLine", "c": 0,
		"en": {"d": "The keeper dives early off his line at a penalty and saves it — replays show his movement clearly affected the kicker.",
			"a": ["Retake the penalty", "Save stands — play on", "Goal awarded", "Indirect free kick"],
			"x": "A keeper offence that affects the kick when no goal is scored: the penalty is retaken."},
		"ar": {"d": "الحارس يتقدم مبكرًا عن خطه في ركلة جزاء ويتصدى لها — والإعادة تُظهر أن حركته أثرت على المسدد.",
			"a": ["إعادة ركلة الجزاء", "التصدي صحيح — استمرار اللعب", "احتساب الهدف", "ركلة حرة غير مباشرة"],
			"x": "مخالفة الحارس التي تؤثر على الركلة دون تسجيل هدف: تُعاد ركلة الجزاء."}},
	{"anim": "shirtPull", "c": 1, "p": 0, "card": "yellow",
		"en": {"d": "On the counter-attack, a defender grabs and holds the winger's shirt, stopping a promising move near the touchline.",
			"a": ["Direct free kick only", "Direct free kick + yellow card", "Direct free kick + red card", "Play on"],
			"x": "Holding that stops a promising attack: direct free kick and a caution."},
		"ar": {"d": "في هجمة مرتدة، يمسك مدافع قميص الجناح ويوقفه قرب خط التماس موقفًا هجمة واعدة.",
			"a": ["ركلة حرة مباشرة فقط", "ركلة حرة مباشرة + بطاقة صفراء", "ركلة حرة مباشرة + بطاقة حمراء", "استمرار اللعب"],
			"x": "الإمساك الذي يوقف هجمة واعدة: ركلة حرة مباشرة مع إنذار."}}
]

# --- state used across scenes ---
var lang: String = "en"
var high_score: int = 0

func _ready() -> void:
	_load_prefs()

func _load_prefs() -> void:
	var f = FileAccess.open("user://prefs.cfg", FileAccess.READ)
	if not f: return
	var parts = f.get_line().split("|")
	if parts.size() >= 1 and parts[0] != "":
		lang = parts[0]
	if parts.size() >= 2:
		high_score = int(parts[1])
	f.close()

func save_prefs() -> void:
	var f = FileAccess.open("user://prefs.cfg", FileAccess.WRITE)
	if f:
		f.store_line("%s|%d" % [lang, high_score])
		f.close()

func t(key: String) -> String:
	return UI.get(lang, UI["en"]).get(key, key)

func is_rtl() -> bool:
	return lang == "ar"

func rank_for(score: int) -> Dictionary:
	for r in RANKS:
		if score >= r.min:
			return r
	return RANKS[RANKS.size() - 1]
