extends SceneTree
const TestVoice = preload("res://tests/helpers/practice_voice_bridge.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func command(scene, word: String, strength: float) -> void:
	scene.voice.accept_packet({"type":"command","seq":scene.voice.last_seq+1,"epoch":scene.voice.epoch,"command":word,"strength":strength})
	scene._physics_process(1.0/60.0)
	scene._process(1.0/60.0)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stunt-scene-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.voice.free()
	scene.voice = TestVoice.new()
	scene.add_child(scene.voice)
	scene.voice.start()
	scene.session.restart()
	scene.sync_voice_context()
	check(scene.car.get("effects") != null, "Das echte Auto braucht sichtbare Fahreffekte.")
	if scene.car.get("effects") != null:
		command(scene,"faster",0.9)
		check(scene.model.boost_remaining > 0.0 and scene.car.effects.flames.visible, "Ein lauter Befehl startet das Modell und die Flammen zusammen.")
		check(scene.car.body.rotation.x > 0.0 and "Turbo" in scene.ui.status_label.text, "Der Turbo hebt die Karosserie und zeigt eine klare Meldung.")
		scene.camera.fov = 90.0
		scene.camera.follow(scene.car,scene.model.heading,0.2,false,0.0,22.0,0.0)
		var normal_fov: float = scene.camera.fov
		scene.camera.fov = 90.0
		scene.camera.follow(scene.car,scene.model.heading,0.2,false,0.0,22.0,1.0)
		check(scene.camera.fov > normal_fov + 1.0, "Der Turbo erweitert sichtbar den Blickwinkel.")
		scene.session.pause()
		scene._process(0.016)
		check(not scene.car.effects.visible and not scene.car.effects.smoke[0].emitting, "Eine Pause unterbricht die sichtbaren Effekte.")
		scene.session.restart()
		check(not scene.car.effects.flames.visible and scene.car.body.rotation.is_equal_approx(Vector3.ZERO), "Der Neustart entfernt die alte Flamme und die alte Karosseriebewegung.")
		scene.sync_voice_context()
		command(scene,"slower",0.9)
		check(scene.car.body.rotation.x < 0.0 and scene.car.effects.smoke[0].emitting, "Die Vollbremsung senkt die Nase und erzeugt Reifenrauch.")
		check("Full brake" in scene.ui.status_label.text and scene.model.target_speed_mps == 0.0, "Die Anzeige nennt die Vollbremsung und das Modell hält an.")
		var angles: Array[float] = []
		for strength in [0.2,0.9]:
			scene.session.restart()
			scene.sync_voice_context()
			command(scene,"left",strength)
			angles.append(absf(scene.car.wheels[0].rotation.y))
		check(is_equal_approx(angles[1], angles[0]), "Die Lautstaerke aendert die Lenkhilfe nicht.")
		var curve: Dictionary = scene.track.curves[0]
		scene.session.restart()
		scene.model.reset(curve.start_m - 10.0)
		scene.model.speed_mps = 40.0
		scene.model.target_speed_mps = 40.0
		scene.session.ensure_controls()
		scene.session.press(curve.turn_sign)
		for i in range(90): scene._physics_process(1.0/60.0)
		check(absf(scene.car.body.rotation.y) > deg_to_rad(3.0) and scene.car.effects.smoke[0].emitting, "Die echte Karosserie driftet mit Reifenrauch durch die schnelle Kurve.")
		scene.model.airborne = true
		scene.car.drive(scene.model,0.016)
		check(not scene.car.effects.smoke[0].emitting, "In der Luft entsteht kein Reifenrauch.")
	scene.queue_free()
	for i in range(3): await process_frame
	print("STUNTS IM SPIEL: %d Prüfungen, %d Fehler" % [checks,failures])
	quit(0 if failures == 0 else 1)
