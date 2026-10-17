extends SceneTree

const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Router = preload("res://scripts/input/command_router.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	var track = Track.new()
	for curve in track.curves:
		var baseline = Drive.new(track)
		var corrected = Drive.new(track)
		baseline.reset(curve.start_m - 20.0)
		corrected.reset(curve.start_m - 20.0)
		baseline.request_turn(curve.turn_sign)
		corrected.request_turn(curve.turn_sign)
		var peak := 0.0
		var command_sent := false
		var corrected_peak := 0.0
		for i in range(900):
			baseline.step(1.0 / 60.0)
			corrected.step(1.0 / 60.0)
			peak = maxf(peak, absf(baseline.lateral))
			if not command_sent and corrected.distance_m > curve.start_m + 5.0:
				corrected.request_turn(curve.turn_sign)
				command_sent = true
			corrected_peak = maxf(corrected_peak, absf(corrected.lateral))
			if baseline.off_road or corrected.off_road or baseline.distance_m > curve.end_m + 25.0: break
		check(peak >= 0.1 and peak <= baseline.assist_profile.sway_limit_m, "Die sichtbare Bewegung bleibt innerhalb der Hilfe.")
		check(not baseline.off_road and baseline.distance_m > curve.end_m, "Eine Eingabe reicht für die Kurve.")
		print("curve ",curve.id," peak ",peak," corrected ",corrected_peak," sent ",command_sent)
		check(command_sent and corrected_peak <= corrected.assist_profile.sway_limit_m and not corrected.off_road, "Eine weitere Eingabe hält die Fahrt innerhalb der Hilfe.")
		check(baseline.speed_mps >= 18.0, "Die Kurvenfahrt hält das Tempo.")
	var model = Drive.new(track)
	var router = Router.new(model)
	router.restart()
	model.reset(80.0)
	router.press(1)
	for i in range(90):
		if i % 10 == 0:
			router.press(1)
		router.step(1.0 / 60.0)
	check(router.state == "RUNNING" and model.distance_m > 100.0, "Wiederholte Korrekturen halten die Fahrt nicht an")
	print("SPANNUNGSPRÜFUNGEN: %d, FEHLER: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
