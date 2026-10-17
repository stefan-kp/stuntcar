extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Router = preload("res://scripts/input/command_router.gd")
const DT := 1.0 / 60.0
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func steps(model, count: int) -> void:
	for i in range(count): model.step(DT)
func _initialize() -> void:
	var track = Track.new()
	var model = Drive.new(track)
	check(model.get("boost_remaining") != null and model.get("emergency_braking") != null and model.get("drift_angle") != null, "Das Fahrmodell braucht Turbo, Vollbremsung und Drift.")
	if failures:
		quit(1)
		return
	model.change_speed(1, 0.5)
	steps(model, 15)
	var normal_speed: float = model.speed_mps
	model.reset()
	model.change_speed(1, 0.9)
	check(model.boost_remaining > 0.0, "Drei Balken starten den Turbo.")
	steps(model, 15)
	check(model.speed_mps > normal_speed + 4.0, "Der Turbo beschleunigt deutlich stärker als ein normaler Befehl.")
	var remaining: float = model.boost_remaining
	model.change_speed(1, 0.9)
	check(is_equal_approx(model.boost_remaining, remaining), "Ein weiterer Befehl verlängert den laufenden Turbo nicht.")
	steps(model, 70)
	check(model.boost_remaining == 0.0 and model.speed_mps <= 58.0, "Der Turbo endet und bleibt begrenzt.")
	model.reset()
	model.change_speed(1, 0.9)
	model.change_speed(-1, 0.9)
	check(model.emergency_braking and model.target_speed_mps == 0.0 and model.boost_remaining == 0.0, "Die Vollbremsung beendet den Turbo und verlangt Stillstand.")
	steps(model, 90)
	check(model.speed_mps == 0.0 and not model.off_road, "Die Vollbremsung hält das Auto auf der Geraden an.")
	var stopped: Vector3 = model.position
	steps(model, 30)
	check(model.position.is_equal_approx(stopped), "Das Auto bleibt nach der Vollbremsung stehen.")
	var stopped_heading: float = model.heading
	model.request_turn(1, 0.9)
	steps(model, 20)
	check(is_equal_approx(model.heading, stopped_heading), "Ein Lenkbefehl dreht das stehende Auto nicht auf der Stelle.")
	model.change_speed(-1, 0.2)
	check(model.target_speed_mps == 0.0, "Ein weiterer Bremsbefehl löst die Bremse nicht.")
	model.change_speed(1, 0.2)
	steps(model, 15)
	check(not model.emergency_braking and model.speed_mps > 0.0, "Ein leises faster fährt wieder an.")
	model.reset()
	var jump: Dictionary = track.jumps[0]
	model.reset(jump.start_m + 1.0)
	model.airborne = true
	model.change_speed(-1, 0.9)
	model.step(DT)
	check(model.speed_mps >= 22.0 and model.distance_m > jump.start_m + 1.0, "Eine Vollbremsung friert das Auto nicht in der Luft ein.")
	model.reset()
	var curve: Dictionary = track.curves[0]
	model.reset(curve.start_m - 10.0)
	model.speed_mps = 40.0
	model.target_speed_mps = 40.0
	model.request_turn(curve.turn_sign)
	steps(model, 90)
	check(absf(model.drift_angle) > deg_to_rad(5.0) and not model.off_road, "Eine schnelle unterstützte Kurve erzeugt sichtbaren Drift.")
	check(signf(model.drift_angle) == -curve.turn_sign, "Der Drift zeigt zur Innenseite der Kurve.")
	model.reset(curve.start_m - 10.0)
	model.speed_mps = 20.0
	model.target_speed_mps = 20.0
	model.request_turn(curve.turn_sign)
	steps(model, 90)
	check(absf(model.drift_angle) < deg_to_rad(1.0), "Langsame Kurven erzeugen keinen starken Drift.")
	model.reset()
	var router = Router.new(model)
	router.restart()
	router.submit_voice("faster", 0.9)
	router.pause()
	remaining = model.boost_remaining
	router.step(0.5)
	check(model.boost_remaining == remaining, "Eine Pause hält auch den Turbo an.")
	router.restart()
	check(model.boost_remaining == 0.0 and not model.emergency_braking and model.drift_angle == 0.0, "Ein Neustart löscht alle Fahreffekte.")
	print("STUNTGEFÜHL: %d Prüfungen, %d Fehler" % [checks,failures])
	quit(0 if failures == 0 else 1)
