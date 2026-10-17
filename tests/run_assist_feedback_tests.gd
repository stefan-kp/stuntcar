extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Router = preload("res://scripts/input/command_router.gd")
const UI = preload("res://scripts/ui/game_ui.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1;push_error(text)
func run() -> void:
	var model = Drive.new(Track.new());var session = Router.new(model)
	var ui = UI.new();root.add_child(ui);session.restart();model.reset(70.0)
	model.request_turn(-1);ui.render(session)
	check("saved" in ui.hint_detail.text, "Die vorgemerkte Eingabe ist sichtbar.")
	model.target_speed_mps = 46.0
	var sway := false;var max_lateral := 0.0
	for i in range(1000):
		model.keyboard_speed(1,1.0/60.0);model.step(1.0/60.0)
		sway = sway or model.motion == "safe_sway"
		max_lateral = maxf(max_lateral,absf(model.lateral))
		if model.distance_m > 190.0 or model.off_road: break
	check(sway, "Vollgas erzeugt nach der Freigabe ein Schlingern.")
	check(not model.off_road and max_lateral <= model.assist_profile.sway_limit_m, "Das Schlingern bleibt sicher.")
	check(not model.assist_state().authorized, "Die Folgekurve braucht eine neue Eingabe.")
	model.reset(95);model.request_turn(1);model.step(1.0/60.0);ui.render(session)
	check("help" in ui.hint_detail.text.to_lower(), "Die spaete Hilfe ist sichtbar.")
	model.reset(70);model.refresh_assist();model.curve_assist.close("expired");ui.render(session)
	check("missed" in ui.hint_label.text.to_lower(), "Ein geschlossenes Fenster bleibt sichtbar.")
	model.reset(70);model.set_assist_level("easy");model.request_turn(1);model.target_speed_mps=46
	var easy_sway := false
	for i in range(300):
		model.step(1.0/60.0);easy_sway = easy_sway or model.motion == "safe_sway"
	check(not easy_sway,"Leicht hat keinen zusaetzlichen Schlingerimpuls.")
	ui.free();print("HILFSANZEIGE: %d Bedingungen, %d Fehler"%[checks,failures]);quit(0 if failures==0 else 1)
