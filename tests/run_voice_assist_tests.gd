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

func reset_scene(scene, distance: float = 80.0) -> void:
	scene.session.restart()
	scene.model.reset(distance)
	scene.car.place(scene.model)
	scene.sync_voice_context()
	scene.voice.enabled = true
	scene.voice.authenticated = true
	scene.voice.is_ready = true
	scene.voice.device_name = "Testmikrofon"
	scene.voice.last_message_ms = Time.get_ticks_msec()
	scene.session.practice.calibration.levels.assign([1000.0, 3000.0, 6000.0])
	scene.session.practice.calibration.device = "Testmikrofon"
	scene.session.voice_enabled = true
	scene.session.call_profile = {"version":1,"device":"Testmikrofon","on_rms":25.0,"off_rms":15.0,"min_call_s":0.15,"max_call_s":3.0,"release_s":0.3}
	scene.model.refresh_assist()
	scene.binding_stage = 0

func feedback(scene, peak: Variant = 45.0, duration: Variant = 0.4, state: String = "unknown", heard: String = "") -> Dictionary:
	sequence += 1
	var packet := {"type":"feedback", "seq":sequence, "epoch":scene.voice.epoch,
		"state":state, "heard":heard, "rms":0.0, "peak_rms":peak,
		"level":0.0, "speech_seconds":duration,"call_id":sequence,"opportunity_id":scene.model.assist_state().opportunity_id,"has_command":false}
	scene.voice.accept_packet(packet)
	scene._physics_process(DT)
	return packet

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-assist-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	for heard in ["", "updi dupdi"]:
		reset_scene(scene)
		var before: int = scene.voice_applied_count
		var packet := feedback(scene, 45.0, 0.4, "unknown", heard)
		check(scene.model.active_curve_id == 0 and scene.model.last_command == 1, "Ein leiser unbekannter Ruf lenkt in die rechte Kurve, auch ohne Text.")
		check(scene.voice_applied_count == before + 1, "Ein Ruf zählt genau einmal.")
		check(scene.ui.voice_compass.tip_lit("right"), "Die Anzeige bestätigt die Hilfe nach rechts.")
		check("Voice help" in scene.voice_action_text, "Die Anzeige unterscheidet die Hilfe vom erkannten Wort.")
		scene.voice.accept_packet(packet)
		scene._physics_process(DT)
		feedback(scene, 0.0, 0.0, "listening")
		check(scene.voice_applied_count == before + 1, "Ein doppeltes Paket und die folgende Stille lenken nicht erneut.")
		feedback(scene)
		check(scene.voice_applied_count == before + 2, "Ein neuer Ruf kann erneut helfen.")
	var left_curve: Dictionary = {}
	for curve in scene.track.curves:
		if curve.turn_sign < 0:
			left_curve = curve
			break
	reset_scene(scene, left_curve.start_m - 10.0)
	feedback(scene)
	check(scene.model.active_curve_id == left_curve.id and scene.model.last_command == -1, "Die Hilfe folgt auch einer linken Kurve.")
	# Second curve: 410–490 m. At 22 m/s, five seconds start at 300 m.
	for item in [[299.0, 0], [300.0, 1], [450.0, 1], [490.0, 0]]:
		reset_scene(scene, item[0])
		var before: int = scene.voice_applied_count
		feedback(scene)
		check(scene.voice_applied_count == before + item[1], "Das bisherige Zeitfenster begrenzt die Hilfe bei %s Metern." % item[0])
	for distance in [scene.track.length_m + 1.0]:
		reset_scene(scene, maxf(0.0, distance))
		# No movement: the first curve is outside the current time window.
		scene.model.speed_mps = 0.0
		scene.model.target_speed_mps = 0.0
		var before: int = scene.voice_applied_count
		feedback(scene)
		check(scene.voice_applied_count == before, "Ohne Kurve im Zeitfenster wirkt der Ruf nicht.")
	for values in [[20.0, 0.4], [6000.0, 0.05], [-1.0, 0.4], [NAN, 0.4], [INF, 0.4], ["invalid", 0.4], [6000.0, NAN], [6000.0, "invalid"], [6000.0, -1.0]]:
		reset_scene(scene)
		var before: int = scene.voice_applied_count
		feedback(scene, values[0], values[1])
		check(scene.voice_applied_count == before, "Leise, kurze oder ungültige Signale lösen keine Hilfe aus.")
	for state in ["checking", "recognized", "listening"]:
		reset_scene(scene)
		var before: int = scene.voice_applied_count
		feedback(scene, 6000.0, 0.4, state)
		check(scene.voice_applied_count == before, "Nur ein beendeter Ruf ohne Befehl löst die Hilfe aus.")
	for state in ["MENU", "PAUSED", "PRACTICE", "FALLING", "FINISHED"]:
		reset_scene(scene)
		scene.session.state = state
		scene.sync_voice_context()
		var before: int = scene.voice_applied_count
		feedback(scene)
		check(scene.voice_applied_count == before, "Die Hilfe bleibt außerhalb der Fahrt aus: " + state)
	for condition in ["missing_profile", "other_device", "disabled", "binding", "old_epoch"]:
		reset_scene(scene)
		var before: int = scene.voice_applied_count
		match condition:
			"missing_profile": scene.session.call_profile.clear()
			"other_device": scene.voice.device_name = "Anderes Mikrofon"
			"disabled": scene.session.voice_enabled = false
			"binding": scene.binding_stage = 1
			"old_epoch":
				sequence += 1
				scene.voice.accept_packet({"type":"feedback", "seq":sequence, "epoch":scene.voice.epoch - 1,
					"state":"unknown", "peak_rms":6000.0, "speech_seconds":0.4})
		if condition != "old_epoch": feedback(scene)
		else: scene._physics_process(DT)
		check(scene.voice_applied_count == before, "Die Hilfe benötigt eine gültige Sprachsteuerung: " + condition)
	reset_scene(scene)
	var before: int = scene.voice_applied_count
	sequence += 1
	scene.voice.accept_packet({"type":"command", "seq":sequence, "epoch":scene.voice.epoch,
		"command":"left", "peak_rms":6000.0})
	feedback(scene, 6000.0, 0.4, "recognized", "left")
	check(scene.voice_applied_count == before + 1 and scene.model.last_command == 1, "Sehr leicht gleicht eine erkannte falsche Richtung aus.")
	scene.free()
	print("RUFHILFE: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
