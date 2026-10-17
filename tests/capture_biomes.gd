extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-biome-capture-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	for route in scene.track.catalog():
		if route.scenario not in ["canyon","alpine"]: continue
		scene.select_track(route.path)
		for distance in [65, 220, 390, 880]:
			scene.model.reset(distance)
			scene.car.place(scene.model)
			scene.camera.initialized = false
			for frame in range(45):
				scene.session.state = "RUNNING"
				scene._process(1.0/60.0)
				await process_frame
			scene.ui.visible = false
			await RenderingServer.frame_post_draw
			var picture := root.get_texture().get_image()
			picture.save_png("res://docs/%s-%03d.png" % [route.scenario,distance])
			if distance == 65:
				picture.save_png("res://tracks/previews/"+route.scenario+".png")
				scene.ui.visible = true
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/fahrt-"+route.scenario+".png")
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit()
