extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	if not FileAccess.file_exists("res://scripts/vehicle/curve_assist.gd"):
		check(false, "Die stufenabhaengige Kurvenfreigabe fehlt.")
		quit(1)
		return
	var C = load("res://scripts/vehicle/curve_assist.gd")
	var P = load("res://scripts/vehicle/assist_profile.gd")
	var curve := {"id":0,"start_m":100.0,"end_m":180.0,"turn_sign":1}
	var state := {"distance_m":50.0,"speed_mps":22.0,"target_speed_mps":22.0,"elapsed_s":0.0,"hint_seconds":5.0,"lateral":0.0,"gap":0.0,"heading_error_rad":0.0,"off_road":false,"finished":false}
	for level in ["very_easy", "easy"]:
		var c = C.new()
		c.reset(1)
		var profile: Dictionary = P.for_id(level)
		check(P.validate(profile).is_empty(), "Das Profil ist gueltig.")
		c.update(curve, state, profile)
		check(c.snapshot().phase == "early", "Der Hinweis oeffnet die fruehe Eingabe.")
		check(not c.request(-1, false, "first"), "Die Stufe bestimmt den Richtungsabgleich.")
		check(c.request(1, false, "second"), "Die richtige Richtung gibt die Kurve frei.")
		check(not c.request(1, false, "second"), "Ein Ereignis wirkt nur einmal.")
		var first: Dictionary = c.snapshot()
		state.distance_m = 180.0
		c.update(curve, state, profile)
		check(c.snapshot().authorized, "Die Hilfe sichert den Kurvenausgang.")
		state.distance_m = 180.0 + profile.exit_distance_m
		c.update(curve, state, profile)
		check(not c.snapshot().authorized, "Nach dem Kurvenausgang endet die Freigabe.")
		var next := {"id":1,"start_m":220.0,"end_m":280.0,"turn_sign":-1}
		c.update(next, state, profile)
		check(not c.snapshot().authorized and c.snapshot().opportunity_id != first.opportunity_id, "Die Folgekurve braucht eine neue Eingabe.")
		check(not c.request(-1, false, "second"), "Eine alte Kennung lenkt keine Folgekurve.")
		state.distance_m = 50.0
		c.reset(2)
		c.update(curve, state, profile)
		check(c.request(0, true, "call") == (level == "very_easy"), "Nur Sehr leicht nutzt einen unbekannten Ruf.")
		c.reset(3)
		state.elapsed_s = 0.0
		c.update(curve, state, profile)
		state.elapsed_s = 10.0
		c.update(curve, state, profile)
		check(not c.request(1, false, "expired"), "Der Ablauf bleibt endlich, auch bei Stillstand.")
		state.elapsed_s = 0.0
	for item in [[78.0,0.0,"clean"],[100.0,0.0,"late"],[105.0,0.75,"rescue"],[105.0,2.4,"closed"]]:
		var c = C.new()
		c.reset(4)
		state.distance_m = item[0]
		state.lateral = item[1]
		c.update(curve,state,P.for_id("very_easy"))
		check(c.snapshot().phase == item[2], "Die Abschnittsgrenze ist eindeutig: " + str(item))
	print("KURVENHILFE: %d Bedingungen, %d Fehler" % [checks,failures])
	quit(0 if failures == 0 else 1)
