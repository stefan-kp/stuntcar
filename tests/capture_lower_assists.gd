extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-lower-capture-unused.cfg"
	root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
	scene.session.sound_enabled=false
	for state in ["SETTINGS","CALL_PRACTICE","RUNNING"]:
		if state == "RUNNING":
			scene.session.restart();scene.model.reset(70);scene.model.request_turn(-1);scene.model.target_speed_mps=46
			for i in range(160):
				scene._physics_process(1.0/60.0)
				if scene.model.motion == "safe_sway" and scene.model.sway_remaining < 0.6:break
		scene.session.state=state;scene.session.menu_index=0
		scene._process(0.016)
		for i in range(6): await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/private/tmp/lower-assist-"+state.to_lower()+".png")
	print("Bilder der echten Spielszene erstellt.");scene.free();quit()
