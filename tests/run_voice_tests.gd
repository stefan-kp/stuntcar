extends SceneTree

const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Router = preload("res://scripts/input/command_router.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	var track = Track.new()
	var model = Drive.new(track)
	var router = Router.new(model)
	if not router.has_method("submit_voice"):
		check(false, "Die Sprachbefehle fehlen")
		finish()
		return
	router.submit_voice("start")
	check(router.state == "RUNNING", "Sprache startet die Fahrt")
	model.reset(80.0)
	router.submit_voice("right")
	check(model.active_curve_id == 0, "Rechts aktiviert dieselbe Lenkhilfe wie die Taste")
	router.submit_voice("right")
	check(router.state == "RUNNING" and model.assist_state().authorized and model.recovery_remaining == 0, "Erneutes Rechts erhaelt die Freigabe ohne neue Strafe")
	var old_speed: float = model.speed_mps
	router.submit_voice("slower")
	model.step(0.1)
	check(model.speed_mps < old_speed and model.speed_mps > 0, "Bremsen wirkt weich und hält das Auto nicht an")
	for i in range(30): router.submit_voice("slower")
	for i in range(120): model.step(1.0 / 60.0)
	check(model.speed_mps >= 14.0 and model.speed_mps <= 15.0, "Wiederholtes Bremsen bleibt bei fahrbarem Tempo")
	for i in range(30): router.submit_voice("faster")
	for i in range(120): model.step(1.0 / 60.0)
	check(model.speed_mps <= Drive.MAX_SPEED and model.speed_mps > 22.0, "Gas erhöht das Tempo bis zur Grenze")
	router.submit_voice("pause")
	var target: float = model.target_speed_mps
	router.submit_voice("slower")
	router.submit_voice("right")
	check(router.state == "PAUSED" and model.target_speed_mps == target, "Fahrbefehle verändern keine Pause")
	router.submit_voice("resume")
	check(router.state == "RUNNING", "Weiter setzt bewusst fort")
	for speed in [14.0, 28.0]:
		var drive = Drive.new(track)
		drive.target_speed_mps = speed
		drive.speed_mps = speed
		var sent := {}
		for i in range(6000):
			for curve in track.curves:
				if drive.distance_m > curve.start_m - 28.0 and not sent.has(curve.id):
					drive.request_turn(curve.turn_sign)
					sent[curve.id] = true
			drive.step(1.0 / 60.0)
			if drive.off_road or drive.finished: break
		check(drive.finished, "Die ganze Strecke bleibt bei %d m/s fahrbar" % speed)
	finish()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish() -> void:
	print("SPRACHSTEUERUNG: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
