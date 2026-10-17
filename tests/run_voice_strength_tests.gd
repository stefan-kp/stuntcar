extends SceneTree

var checks := 0
var failures := 0
var sequence := 0
const DT := 1.0 / 60.0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func reset_scene(scene, distance: float = 0.0, speed: float = 22.0) -> void:
	scene.session.restart()
	scene.model.reset(distance)
	scene.model.speed_mps = speed
	scene.model.target_speed_mps = speed
	scene.car.place(scene.model)
	scene.sync_voice_context()
	scene.voice.enabled = true
	scene.voice.authenticated = true
	scene.voice.is_ready = true
	scene.voice.last_message_ms = Time.get_ticks_msec()

func command(scene, word: String, strength: float) -> void:
	sequence += 1
	scene.voice.accept_packet({"type":"command", "seq":sequence, "epoch":scene.voice.epoch, "command":word, "strength":strength})
	scene._physics_process(DT)
	scene._process(DT)

func steps(scene, count: int) -> void:
	for i in range(count): scene._physics_process(DT)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-strength-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.voice_enabled = true
	scene.session.sound_enabled = false
	var accelerations: Array[float] = []
	var braking: Array[float] = []
	var targets: Array[float] = []
	for item in [[0.2, 24.0, 20.0, 1], [0.5, 27.0, 17.0, 2], [0.9, 30.0, 0.0, 3]]:
		reset_scene(scene)
		command(scene, "faster", item[0])
		targets.append(scene.model.target_speed_mps)
		accelerations.append(scene.model.speed_mps - 22.0)
		check(is_equal_approx(scene.model.target_speed_mps, item[1]), "Die Lautstärke bestimmt die Größe der Tempoerhöhung.")
		check(scene.ui.voice_compass.lit_bars("faster") == item[3], "Die Balken zeigen dieselbe Stufe wie die Tempoerhöhung.")
		reset_scene(scene)
		command(scene, "slower", item[0])
		braking.append(22.0 - scene.model.speed_mps)
		check(is_equal_approx(scene.model.target_speed_mps, item[2]), "Die Lautstärke bestimmt die Größe der Temposenkung.")
	check(accelerations[0] < accelerations[1] and accelerations[1] < accelerations[2], "Ein lauterer Befehl beschleunigt das echte Auto stärker.")
	check(braking[0] < braking[1] and braking[1] < braking[2], "Ein lauterer Befehl bremst das echte Auto stärker.")
	print("ZIELTEMPO: ", targets, "; BESCHLEUNIGUNG: ", accelerations, "; BREMSE: ", braking)
	for direction in ["left", "right"]:
		var angles: Array[float] = []
		for strength in [0.2, 0.5, 0.9]:
			reset_scene(scene, 0.0, 14.0)
			command(scene, direction, strength)
			steps(scene, 17)
			angles.append(rad_to_deg(scene.model.heading))
			check(is_zero_approx(scene.model.heading), "Die vorgemerkte Kurve dreht die Gerade noch nicht.")
		check(is_equal_approx(angles[0],angles[1]) and is_equal_approx(angles[1],angles[2]), "Die Lautstaerke aendert die Richtung nicht: " + direction)
		check(is_zero_approx(angles[0]) and is_zero_approx(angles[2]), "Beide Lautstaerken erhalten die gerade Fahrtrichtung.")
		print("LENKWINKEL ", direction, ": ", angles)
	var curve_results: Array[float] = []
	var curve = scene.track.curves[0]
	for strength in [0.2, 0.5, 0.9]:
		reset_scene(scene, curve.start_m + 24.0)
		scene.model.position += scene.track.right(scene.model.heading) * -2.3
		scene.model.lateral = -2.3
		command(scene, "right", strength)
		steps(scene, 17)
		curve_results.append(absf(scene.model.lateral))
		check(scene.session.state == "RUNNING", "Die Kurvenkorrektur hält das Auto auf der Strecke.")
	check(curve_results[0] < 2.3 and is_equal_approx(curve_results[0],curve_results[2]), "Die Kurvenhilfe rettet bei allen Lautstaerken gleich.")
	print("ABSTAND ZUR MITTE IN DER KURVE: ", curve_results)
	var jump_results: Array[float] = []
	var jump = scene.track.jumps[0]
	for strength in [0.2, 0.5, 0.9]:
		reset_scene(scene, jump.start_m - 15.0)
		scene.model.position += scene.track.right(scene.model.heading) * 1.5
		scene.model.lateral = 1.5
		command(scene, "left", strength)
		steps(scene, 11)
		jump_results.append(absf(scene.model.lateral))
		check(scene.session.state == "RUNNING", "Die Sprungkorrektur hält das Auto auf der Strecke.")
	check(jump_results[0] < 1.5 and is_equal_approx(jump_results[0],jump_results[2]), "Die Sprungkorrektur wirkt bei allen Lautstaerken gleich.")
	print("ABSTAND ZUR MITTE VOR DEM SPRUNG: ", jump_results)
	reset_scene(scene)
	command(scene, "faster", 0.2)
	command(scene, "faster", 0.2)
	check(is_equal_approx(scene.model.target_speed_mps, 26.0), "Zwei leise Befehle wirken genau zweimal.")
	for item in [[0.339, 24.0, 1], [0.34, 27.0, 2], [0.669, 27.0, 2], [0.67, 30.0, 3]]:
		reset_scene(scene)
		command(scene, "faster", item[0])
		check(is_equal_approx(scene.model.target_speed_mps, item[1]) and scene.ui.voice_compass.lit_bars("faster") == item[2], "An den Stufengrenzen stimmen die Anzeige und die Wirkung überein.")
	for item in [[NAN, 27.0, 2], [INF, 27.0, 2], [-1.0, 24.0, 1], [10.0, 30.0, 3]]:
		reset_scene(scene)
		command(scene, "faster", item[0])
		check(is_equal_approx(scene.model.target_speed_mps, item[1]) and scene.ui.voice_compass.lit_bars("faster") == item[2], "Ungültige und übergroße Stärken bleiben begrenzt und stimmen mit der Anzeige überein.")
	reset_scene(scene)
	command(scene, "faster", 0.2)
	command(scene, "faster", 0.2)
	reset_scene(scene)
	command(scene, "faster", 0.2)
	sequence += 1
	scene.voice.accept_packet({"type":"feedback", "seq":sequence, "epoch":scene.voice.epoch, "direction":"faster", "level":0.95})
	scene._process(DT)
	check(scene.ui.voice_compass.lit_bars("faster") == 1 and scene.ui.voice_compass.tip_lit("faster") and scene.model.target_speed_mps == 24.0, "Ein neuer hoher Pegel ändert weder die bestätigten Balken noch die kleine Fahrwirkung.")
	command(scene, "faster", 0.95)
	check(scene.ui.voice_compass.lit_bars("faster") == 3 and scene.model.target_speed_mps == 32.0, "Ein neuer bestätigter lauter Befehl ändert die Balken und die Fahrwirkung zusammen.")
	reset_scene(scene)
	command(scene, "faster", 0.2)
	command(scene, "faster", 0.2)
	var count: int = scene.voice_applied_count
	scene.voice.accept_packet({"type":"command", "seq":sequence, "epoch":scene.voice.epoch, "command":"faster", "strength":0.9})
	scene._physics_process(DT)
	check(scene.voice_applied_count == count and is_equal_approx(scene.model.target_speed_mps, 26.0), "Ein doppeltes Paket löst keinen zusätzlichen starken Befehl aus.")
	reset_scene(scene, 0.0, 30.0)
	command(scene, "slower", 0.9)
	check(is_equal_approx(scene.model.target_speed_mps, 0.0), "Ein lauter Bremsbefehl verlangt Stillstand.")
	command(scene, "faster", 0.2)
	check(is_equal_approx(scene.model.target_speed_mps, 14.0), "Ein leiser Gegenbefehl löst die Vollbremsung und fährt wieder an.")
	reset_scene(scene, 0.0, 14.0)
	command(scene, "left", 0.9)
	reset_scene(scene, 0.0, 14.0)
	scene.session.press(-1)
	steps(scene, 18)
	check(is_zero_approx(scene.model.heading) and scene.model.turn_strength == 1.0, "Die Taste nutzt dieselbe Hilfskraft und wartet auf die Kurve.")
	reset_scene(scene)
	for i in range(8): command(scene, "faster", 0.9)
	check(scene.model.target_speed_mps == 46.0, "Laute Gasbefehle überschreiten das Höchsttempo nicht.")
	for i in range(8): command(scene, "slower", 0.9)
	check(scene.model.target_speed_mps == 0.0, "Laute Bremsbefehle halten das Auto an.")
	scene.session.pause()
	scene.sync_voice_context()
	var target: float = scene.model.target_speed_mps
	command(scene, "faster", 0.9)
	check(scene.session.state == "PAUSED" and scene.model.target_speed_mps == target, "Ein lauter Fahrbefehl verändert die Pause nicht.")
	scene.free()
	print("LAUTSTÄRKESTEUERUNG: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
