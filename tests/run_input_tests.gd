extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func key(scene, code: int, pressed := true, echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	scene._input(event)

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-test-unused.cfg"
	root.add_child(scene)
	scene.session.state = "MENU"
	scene.sync_voice_context()
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.session.sound_enabled = false
	scene.key_left = KEY_A
	scene.key_right = KEY_D
	key(scene, KEY_D)
	scene._physics_process(1.0 / 60.0)
	check(scene.session.state == "RUNNING" and scene.model.last_command == 0, "Start sendet keinen Lenkbefehl")
	key(scene, KEY_D, true, true)
	key(scene, KEY_D)
	scene._physics_process(1.0 / 60.0)
	check(scene.model.last_command == 0, "Halten und Tastenwiederholung senden keinen neuen Befehl")
	key(scene, KEY_D, false)
	key(scene, KEY_D)
	key(scene, KEY_ESCAPE)
	scene._physics_process(1.0 / 60.0)
	check(scene.session.state == "PAUSED", "Ein alter Tastendruck darf die Pause nicht beenden")
	key(scene,KEY_A,false)
	key(scene,KEY_D,false)
	scene.held.clear()
	scene.pending.clear()
	scene.session.restart()
	key(scene, KEY_A)
	key(scene, KEY_D)
	scene._physics_process(1.0 / 60.0)
	check(scene.model.last_command == 0, "Gleichzeitige Tasten senden keinen Lenkbefehl")
	key(scene, KEY_A, false)
	key(scene, KEY_D, false)
	scene.model.reset(80.0)
	scene.car.place(scene.model)
	key(scene, KEY_D)
	scene._physics_process(1.0 / 60.0)
	check(scene.model.active_curve_id == 0, "Ein echter Tastendruck wählt die erste Kurve")
	key(scene, KEY_D, false)
	key(scene, KEY_D)
	scene._physics_process(1.0 / 60.0)
	check(scene.session.state == "RUNNING", "Erneuter Tastendruck lenkt und unterbricht die Fahrt nicht")
	key(scene, KEY_ESCAPE)
	scene._physics_process(1.0 / 60.0)
	var position: Vector3 = scene.car.global_position
	var elapsed: float = scene.model.elapsed_s
	scene._physics_process(2.0)
	check(scene.car.global_position == position and scene.model.elapsed_s == elapsed, "Pause hält auch das sichtbare Auto an")
	key(scene, KEY_D, false)
	key(scene, KEY_D)
	scene._physics_process(1.0 / 60.0)
	check(scene.session.state == "RUNNING" and scene.session.last_key == 0, "Weiter setzt keinen neuen Lenkbefehl")
	key(scene, KEY_D, false)
	key(scene, KEY_A)
	scene._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	scene._physics_process(1.0 / 60.0)
	check(scene.session.state == "PAUSED" and scene.pending.is_empty(), "Fensterwechsel pausiert und löscht alte Eingaben")
	scene.binding_stage = 1
	scene.bind_timeout = 0.01
	scene._physics_process(0.02)
	check(scene.binding_stage == 0 and scene.key_left == KEY_A and scene.key_right == KEY_D, "Die Frist beendet die Tastenzuweisung ohne Änderung")
	scene.on_action("rebind")
	scene.capture_binding(KEY_J)
	scene.capture_binding(KEY_J)
	check(scene.binding_stage == 2 and scene.key_left == KEY_A and scene.key_right == KEY_D, "Doppelte Zuordnungen ändern die Tasten nicht")
	scene.capture_binding(KEY_ESCAPE)
	check(scene.binding_stage == 0 and scene.key_left == KEY_A and scene.key_right == KEY_D, "Abbruch verwirft eine unvollständige Zuordnung")
	print("EINGABEPRÜFUNGEN: %d, FEHLER: %d" % [checks, failures])
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
