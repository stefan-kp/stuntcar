extends SceneTree

var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for file in ["res://scripts/track/track_data.gd", "res://scripts/vehicle/drive_model.gd"]:
		check(ResourceLoader.exists(file), "Fehlender Baustein: " + file)
	if not failures.is_empty():
		finish()
		return
	var track_script = load("res://scripts/track/track_data.gd")
	var drive_script = load("res://scripts/vehicle/drive_model.gd")
	var track = track_script.new()
	check(absf(track.length_m - 940.0) < 1.0, "Die Stuntstrecke umfasst 940 Meter")
	var start: Dictionary = track.sample(20.0)
	check(absf(start.position.x) < 0.01 and absf(start.position.z + 20.0) < 0.01, "Startgerade zeigt geradeaus")
	for curve in track.curves:
		var before: Dictionary = track.sample(curve.start_m - 0.01)
		var after: Dictionary = track.sample(curve.start_m + 0.01)
		check(before.position.distance_to(after.position) < 0.05, "Kurvenanfang hat keine Lücke")
	var no_input = drive_script.new(track)
	for i in range(1100):
		no_input.step(1.0 / 60.0)
		if no_input.off_road:
			break
	check(no_input.off_road, "Ohne Eingabe verlässt das Auto die erste Kurve")
	check(no_input.position.x < 0.05, "Ohne Eingabe dreht das Auto nicht selbst")
	var wrong = drive_script.new(track)
	wrong.set_assist_level("easy")
	wrong.reset(80.0)
	wrong.request_turn(-1)
	for i in range(400):
		wrong.step(1.0 / 60.0)
		if wrong.off_road:
			break
	check(wrong.off_road, "Leicht lehnt eine falsche Richtung ab")
	var early = drive_script.new(track)
	early.hint_seconds = 3.0
	early.request_turn(1)
	for i in range(1200):
		early.step(1.0 / 60.0)
		if early.off_road:
			break
	check(early.off_road and early.distance_m < 170.0, "Ein zu früher Befehl fährt nicht automatisch die spätere Kurve")
	var guided = drive_script.new(track)
	var sent: Dictionary = {}
	for i in range(5000):
		for curve in track.curves:
			if guided.distance_m > curve.start_m - 28.0 and not sent.has(curve.id):
				guided.request_turn(curve.turn_sign)
				sent[curve.id] = true
		guided.step(1.0 / 60.0)
		if guided.off_road or guided.finished:
			break
	print("Geführte Fahrt: s=", guided.distance_m, " seitlich=", guided.lateral, " Richtung=", guided.heading, " Kurven=", guided.completed_curves)
	check(guided.finished and not guided.off_road, "Drei grobe Eingaben ermöglichen die ganze Strecke")
	check(guided.completed_curves == 3, "Jede Kurve zählt nur einmal")
	var single = drive_script.new(track)
	single.reset(80.0)
	single.request_turn(1)
	for i in range(2200):
		single.step(1.0 / 60.0)
		if single.off_road:
			break
	check(single.off_road and single.distance_m < track.curves[1].end_m, "Eine Eingabe gilt nicht für die nächste Kurve")
	for curve in track.curves:
		var late = drive_script.new(track)
		late.reset(curve.start_m - 20.0)
		var elapsed := 0.0
		while late.distance_m < curve.start_m and not late.off_road:
			late.step(1.0 / 60.0)
		while elapsed < 0.25:
			late.step(1.0 / 60.0)
			elapsed += 1.0 / 60.0
		late.request_turn(curve.turn_sign)
		for i in range(600):
			late.step(1.0 / 60.0)
			if late.off_road or late.distance_m > curve.end_m + 3.0:
				break
		check(not late.off_road and late.distance_m > curve.end_m, "Späte passende Eingabe rettet Kurve " + str(curve.id))
	check(ResourceLoader.exists("res://scripts/input/command_router.gd"), "Die Zustandsverwaltung fehlt")
	if ResourceLoader.exists("res://scripts/input/command_router.gd"):
		test_router(track, drive_script)
	finish()

func test_router(track, drive_script) -> void:
	var router_script = load("res://scripts/input/command_router.gd")
	var model = drive_script.new(track)
	var router = router_script.new(model)
	router.press(1)
	check(router.state == "RUNNING", "Start mit der rechten Taste")
	router.step(1.0)
	router.press(-1)
	check(model.last_command == 1, "Sehr leicht gleicht die linke Taste fuer die rechte Kurve aus")
	router.press(-1)
	check(router.state == "RUNNING", "Erneuter Tastendruck lenkt ohne Pause")
	router.pause()
	var saved_position: Vector3 = model.position
	var saved_time: float = model.elapsed_s
	router.step(10.0)
	check(model.position == saved_position and model.elapsed_s == saved_time, "Pause friert Fahrt und Zeit ein")
	router.press(1)
	check(router.state == "RUNNING" and model.last_command == 1, "Weiter erhaelt die bestehende Kurvenfreigabe")
	router.pause()
	router.press(-1)
	router.press(1)
	check(router.state == "RUNNING" and model.active_curve_id == -1 and model.elapsed_s == 0.0, "Neustart verwirft die alte Lenkabsicht")
	router.step(0.1)
	model.off_road = true
	router.step(0.1)
	check(router.state == "FALLING", "Verlassen der Strecke führt zum Fall")
	router.step(2.0)
	check(router.state == "RUNNING", "Nach dem Fall geht die Fahrt ohne Menü weiter")
	check(not model.off_road and model.speed_mps >= 18.0 and model.last_command == 0, "Der erneute Versuch rollt sofort und verwirft die alte Richtung")

func finish() -> void:
	print("PRÜFUNGEN: %d, FEHLER: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
