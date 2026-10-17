extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-canyon-view-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.select_track("res://tracks/05_canyon_study.json")
	if "--play" in OS.get_cmdline_user_args():
		scene.control_mode = "keys"
		scene.session.control_mode = "keys"
		scene.session.state = "MENU"
		return
	scene.session.sound_enabled = false
	scene.session.voice_enabled = false
	scene.set_process(false)
	scene.set_physics_process(false)
	for distance in [15,55,110,135,155,185]:
		scene.model.reset(distance)
		scene.car.place(scene.model)
		scene.camera.initialized = false
		for frame in range(35):
			scene.session.state = "RUNNING"
			scene._process(1.0/60.0)
			await process_frame
		scene.ui.visible = false
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/canyon-study-%03d.png" % distance)
		if distance == 110:
			root.get_texture().get_image().save_png("res://tracks/previews/canyon-study.png")
			scene.ui.visible = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/canyon-study-game.png")
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit()
