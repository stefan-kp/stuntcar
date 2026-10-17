extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-landscape-test-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	check(scene.car.body.has_meta("quality_source"), "Das Spiel nutzt das Auto aus der Qualitätsprobe.")
	check(scene.car.wheels.size() == 4, "Das neue Auto besitzt vier getrennte Räder.")
	for route in preload("res://tests/helpers/legacy_routes.gd").catalog():
		scene.select_track(route.path)
		check(scene.find_children("*", "WorldEnvironment", true, false).size() == 1, "Der Landschaftswechsel hinterlässt keine zweite Umgebung.")
		var landscape = scene.builder.landscape
		var road = scene.builder.get_node_or_null("AsphaltRoad")
		var road_texture = null
		if road != null:
			road_texture = road.material_override.get_shader_parameter("color_map") if road.material_override is ShaderMaterial else road.material_override.albedo_texture
		check(road_texture != null, "Die Straße verwendet eine Asphaltoberfläche.")
		if road != null:
			var arrays: Array = road.mesh.surface_get_arrays(0)
			check(arrays[Mesh.ARRAY_TEX_UV].size() == arrays[Mesh.ARRAY_VERTEX].size(), "Die Asphaltoberfläche folgt der ganzen Straße.")
		if route.scenario == "alpine":
			check(not landscape.scenery.find_children("SnowFir*", "Node3D", true, false).is_empty(), "Die Schneelandschaft nutzt die Tannen mit einer Schneeschicht.")
		check(landscape.scenery.get_child_count() > 10, "Die Landschaft enthält sichtbare Modelle: " + route.name)
		var blocks_road := false
		for item in landscape.scenery.get_children():
			var radius: float = item.get_meta("clearance_radius")
			for point in scene.track.points:
				if Vector2(point.x - item.position.x, point.z - item.position.z).length() < radius + 6:
					blocks_road = true
		check(not blocks_road, "Die Landschaft lässt die ganze Fahrbahn frei: " + route.name)
		scene.session.restart()
		scene.model.reset(50)
		scene.car.place(scene.model)
		var before: float = scene.car.wheels[0].rotation.x
		scene.model.step(0.02)
		scene.car.drive(scene.model, 0.02)
		check(absf(scene.car.wheels[0].rotation.x - before) > 0.1, "Die Räder drehen um ihre Achse.")
		landscape.follow(scene.car.global_position)
		if route.scenario in ["alpine", "coast"]:
			check(landscape.weather.global_position.distance_to(scene.car.global_position) < 15, "Das Wetter folgt dem Auto.")
		else: check(landscape.weather == null, "Der Landschaftswechsel entfernt das alte Wetter.")
		if route.scenario == "coast":
			check(not landscape.find_children("lighthouse", "Node3D", true, false).is_empty(), "Die Küste enthält den Leuchtturm.")
		scene.session.open_tracks()
		scene.ui.render(scene.session)
		check(scene.ui.track_selection.picture.texture != null, "Die Auswahl zeigt ein Vorschaubild.")
	DirAccess.remove_absolute(scene.settings_path)
	scene.queue_free()
	await process_frame
	print("LANDSCHAFTEN: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
