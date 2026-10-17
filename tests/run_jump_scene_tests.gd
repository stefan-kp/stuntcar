extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-jump-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.session.sound_enabled = false
	for route in preload("res://tests/helpers/legacy_routes.gd").catalog():
		scene.select_track(route.path)
		for speed in [14.0, 22.0, 28.0, 46.0]:
			scene.session.restart()
			scene.model.speed_mps = speed
			scene.model.target_speed_mps = speed
			var sent := {}
			var last_correction := -10.0
			var jumps := 0
			var in_air := false
			var pause_checked := false
			for i in range(8500):
				for curve in scene.track.curves:
					if scene.model.distance_m > curve.start_m - 28 and not sent.has(curve.id):
						scene.session.press(curve.turn_sign)
						sent[curve.id] = true
				if speed > 28.0 and scene.model.active_curve_id >= 0 and absf(scene.model.lateral) > 1.6 and scene.model.elapsed_s - last_correction > 0.8:
					scene.session.press(scene.track.curves[scene.model.active_curve_id].turn_sign)
					last_correction = scene.model.elapsed_s
				scene._physics_process(1.0/60.0)
				if scene.model.airborne and not in_air: jumps += 1
				in_air = scene.model.airborne
				if in_air and not pause_checked:
					scene.session.pause()
					var position: Vector3 = scene.car.global_position
					scene._physics_process(1.0)
					check(scene.car.global_position == position, "Pause hält auch den Sprung an")
					scene.session.activate(0)
					pause_checked = true
				if scene.session.state != "RUNNING": break
			check(scene.session.state == "FINISHED", "%s: sichtbares Auto erreicht Ziel bei %d m/s" % [route.name, speed])
			check(jumps == scene.track.jumps.size(), "Alle Lücken werden überflogen")
			check(absf(scene.car.global_position.y - scene.model.position.y) < 0.1, "Die sichtbare Landung stimmt mit dem Fahrmodell überein")
			print("FAHRT: %s, %d m/s, %.1f s, %d Sprünge" % [route.name, speed, scene.model.elapsed_s, jumps])
	DirAccess.remove_absolute(scene.settings_path)
	scene.queue_free()
	await process_frame
	print("SPRÜNGE IM SPIEL: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
