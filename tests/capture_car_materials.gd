extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1440, 900)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-car-view-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.select_track("res://tracks/05_canyon_study.json")
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.voice_enabled = false
	scene.ui.visible = false
	scene.model.reset(185)
	scene.car.place(scene.model)
	var frame: Dictionary = scene.track.sample(185)
	var right: Vector3 = frame.right
	var forward: Vector3 = scene.track.forward(frame.heading)
	var target: Vector3 = scene.car.global_position + Vector3.UP * 0.7
	# Only the camera moves. Materials, light and environment are the live game scene.
	for view in ["front", "rear"]:
		scene.camera.fov = 40
		scene.camera.global_position = target + right * 4.6 + forward * (6.0 if view == "front" else -6.0) + Vector3.UP * 2.4
		scene.camera.look_at(target)
		for index in range(90):
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://docs/car-materials-%s.png" % view
		if "--baseline" in OS.get_cmdline_user_args():
			path = "/tmp/car-materials-before-%s.png" % view
		root.get_texture().get_image().save_png(path)
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit()
