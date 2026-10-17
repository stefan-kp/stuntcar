extends SceneTree
var Track = load("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Router = preload("res://scripts/input/command_router.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var track = Track.new()
	var model = Drive.new(track)
	var router = Router.new(model)
	router.restart()
	for i in range(4):
		var previous: float = model.target_speed_mps
		router.submit_voice("faster")
		check(model.target_speed_mps > previous, "Vier aufeinanderfolgende Gasbefehle erhöhen jeweils das Zieltempo")
	check(model.target_speed_mps >= 40, "Deutlich mehr Tempo ist möglich")
	for i in range(4): router.submit_voice("slower")
	check(is_equal_approx(model.target_speed_mps, 22), "Vier Bremsbefehle nehmen vier Gasbefehle zurück")
	check(track.has_method("bank_at"), "Steilkurven fehlen")
	if not track.has_method("bank_at"):
		quit(1)
		return
	var invalid = JSON.parse_string(FileAccess.get_file_as_string(Track.DEFAULT_PATH))
	invalid.curves[0].bank_degrees = 70
	check(not track.validate_definition(invalid).is_empty(), "Eine zu große Neigung wird abgewiesen")
	var normal_peak := 0.0
	var fast_peak := 0.0
	for speed in [22.0, 46.0]:
		var drive = Drive.new(track)
		drive.reset(80)
		drive.speed_mps = speed
		drive.target_speed_mps = speed
		drive.request_turn(1)
		for i in range(1000):
			drive.step(1.0/60.0)
			if speed == 22.0: normal_peak = maxf(normal_peak, absf(drive.lateral))
			else: fast_peak = maxf(fast_peak, absf(drive.lateral))
			if drive.off_road or drive.distance_m > 175: break
	check(fast_peak > normal_peak + 0.5, "Höheres Tempo erhöht die Randnähe tatsächlich")
	for route in preload("res://tests/helpers/legacy_routes.gd").catalog():
		track = Track.new(route.path)
		var peak_bank := 0.0
		for curve in track.curves:
			var middle: float = (curve.start_m + curve.end_m) * 0.5
			var bank: float = track.bank_at(middle)
			peak_bank = maxf(peak_bank, absf(bank))
			check(bank * curve.turn_sign <= 0, "Die Außenseite der Kurve liegt höher")
			check(absf(track.bank_at(curve.start_m)) < 0.001 and absf(track.bank_at(curve.end_m)) < 0.001, "Die Neigung läuft weich aus")
			var frame: Dictionary = track.sample(middle)
			check(is_equal_approx(frame.right.y, tan(bank)), "Fahrbahn und Fahrzeug nutzen dieselbe Neigung")
		var outer = Drive.new(track)
		var transition: float = track.curves[0].start_m + 9.0
		outer.reset(transition)
		outer.position += track.right(outer.heading) * -float(track.curves[0].turn_sign) * 2.0
		outer.step(1.0/60.0)
		var current: Dictionary = track.sample(outer.distance_m)
		var future: Dictionary = track.project(outer.position + track.forward(outer.heading) * 0.2, outer.distance_m)
		var future_height: float = track.flight_height(future.distance_m) + future.lateral * tan(future.bank)
		var actual_slope: float = atan2(future_height - outer.position.y, 0.2)
		check(absf(outer.pitch - actual_slope) < deg_to_rad(1), "Das Auto folgt auch seitlich der Höhe am Anfang einer Steilkurve")
		if not track.jumps.is_empty(): check(peak_bank >= deg_to_rad(25), "Neue Strecken enthalten sichtbare Steilkurven")
		for jump in track.jumps:
			check(track.bank_at(jump.start_m) == 0 and track.bank_at(jump.end_m) == 0, "Absprung und Landung bleiben gerade")
		var fast = Drive.new(track)
		fast.speed_mps = 46
		fast.target_speed_mps = 46
		var sent := {}
		var corrections := 0
		var last_correction := -10.0
		for i in range(6000):
			for curve in track.curves:
				if fast.distance_m >= curve.start_m - 45 and not sent.has(curve.id):
					fast.request_turn(curve.turn_sign)
					sent[curve.id] = true
			if fast.active_curve_id >= 0 and absf(fast.lateral) > 1.6 and fast.elapsed_s - last_correction > 0.8:
				fast.request_turn(track.curves[fast.active_curve_id].turn_sign)
				last_correction = fast.elapsed_s
				corrections += 1
			fast.step(1.0/60.0)
			if fast.off_road or fast.finished: break
		check(fast.finished, "Höchsttempo bleibt mit kurzen Korrekturen fahrbar: " + route.name + " bei " + str(fast.distance_m))
		check(corrections <= track.curves.size() * 3, "Höchsttempo verlangt keine ständigen schnellen Eingaben")
		print("SCHNELL: %s, %.1f s, %d Korrekturen" % [route.name, fast.elapsed_s, corrections])
	print("TEMPO UND STEILKURVEN: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
