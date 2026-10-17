extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(text)
func _initialize() -> void:
	var m = Drive.new(Track.new())
	if not m.has_method("set_assist_level"):
		check(false,"Die beiden Hilfestufen fehlen im Fahrmodell.")
		quit(1)
		return
	for level in ["very_easy","easy"]:
		for route in preload("res://tests/helpers/legacy_routes.gd").catalog():
			for speed in [14.0,22.0,28.0,46.0,58.0]:
				var d = Drive.new(Track.new(route.path))
				d.set_assist_level(level)
				d.speed_mps = speed
				d.target_speed_mps = speed
				var sent := {}
				for i in range(12000):
					var c: Dictionary = d.track.next_curve(d.distance_m)
					if not c.is_empty() and d.distance_m >= c.start_m - 20 and not sent.has(c.id):
						d.request_turn(-c.turn_sign if level == "very_easy" else c.turn_sign,0.1)
						sent[c.id] = true
					d.step(1.0/60.0)
					if d.off_road or d.finished: break
				check(d.finished,"Ein Befehl pro Kurve: %s %s %.0f bei %.1f" % [level,route.path,speed,d.distance_m])
	for late_offset in [0.0,0.25,0.5]:
		var d = Drive.new(Track.new())
		d.reset(90)
		for i in range(int(late_offset*60)):d.step(1.0/60)
		d.request_turn(1)
		for i in range(600):
			d.step(1.0/60)
			if d.distance_m > 171 or d.off_road:break
		check(not d.off_road and d.distance_m > 170,"Eine spaete Eingabe rettet die Kurve.")
	var silent = Drive.new(Track.new())
	for i in range(600):silent.step(1.0/60)
	check(silent.off_road and is_zero_approx(silent.heading),"Ohne Eingabe bleibt die Richtung gleich.")
	var single = Drive.new(Track.new())
	single.request_turn(1)
	for i in range(2000):single.step(1.0/60)
	check(single.off_road and single.completed_curves == 1,"Eine Eingabe erlaubt keine zweite Kurve.")
	print("UNTERE FAHRHILFE: %d Bedingungen, %d Fehler" % [checks,failures])
	quit(0 if failures==0 else 1)
