extends SceneTree

# Saves a UI-free frame of one track with the car frozen at a chosen distance.
#
# godot --path . --script res://tests/capture_track_preview.gd -- <track.json> [distance_m] [output.png]
#
# Example
# godot --path . --script res://tests/capture_track_preview.gd -- res://tracks/07_schluchtjagd.json 520 res://tracks/previews/canyon_gauntlet.png

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Usage: -- <track.json> [distance_m] [output.png]")
		quit(1)
		return
	var track_path: String = args[0]
	var distance: float = float(args[1]) if args.size() > 1 else 65.0
	var output: String = args[2] if args.size() > 2 else "res://tracks/previews/capture.png"

	root.size = Vector2i(1280, 800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "user://preview-capture-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.set_process(false)

	scene.select_track(track_path)
	scene.model.reset(distance)
	scene.car.place(scene.model)
	scene.camera.initialized = false
	for i in range(45):
		scene.session.state = "RUNNING"
		scene._process(1.0 / 60.0)
		await process_frame

	scene.ui.visible = false
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output)
	print("Saved ", ProjectSettings.globalize_path(output))

	DirAccess.remove_absolute(scene.settings_path)
	scene.queue_free()
	await process_frame
	quit()
