extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func run() -> void:
	# Check the imported shape after the source node rotations.
	var source = load("res://assets/landscapes/shrub_02/shrub_02.gltf").instantiate()
	var models: Array = load("res://scripts/landscape_assets.gd").variants("shrub_02")
	var variant := 0
	for item in source.find_children("*", "MeshInstance3D", true, false):
		var transform: Transform3D = item.transform
		var parent = item.get_parent()
		while parent != source:
			transform = parent.transform * transform
			parent = parent.get_parent()
		var bounds := AABB()
		var first := true
		for surface in range(item.mesh.get_surface_count()):
			for vertex in item.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var pos: Vector3 = transform * vertex
				if first:
					bounds = AABB(pos,Vector3.ZERO)
					first = false
				else: bounds = bounds.expand(pos)
		check(bounds.size.distance_to(models[variant].get_aabb().size) < 0.02, "Die Sträucher behalten ihre Form und ihre Ausrichtung.")
		variant += 1
	source.free()
	var track = load("res://scripts/track/track_data.gd").new()
	for route in track.catalog():
		if route.scenario not in ["canyon", "alpine"]: continue
		track = load("res://scripts/track/track_data.gd").new(route.path)
		var landscape = load("res://scripts/track/landscape.gd").new()
		root.add_child(landscape)
		landscape.build(track)
		var terrain = landscape.get_node_or_null("BiomeTerrain")
		check(terrain != null, "Die Landschaft braucht Gelände: " + route.scenario)
		if terrain != null:
			check(terrain.get_aabb().size.y > 35, "Das Gelände braucht große Höhenunterschiede.")
			await physics_frame
			await physics_frame
			var space = root.world_3d.direct_space_state
			var missing := false
			var blocked := false
			for distance in range(0, int(track.length_m), 12):
				var frame: Dictionary = track.sample(distance)
				for side in [-4.0, 0.0, 4.0]:
					var pos: Vector3 = frame.position + frame.right * side
					# Inspect the floor below the car, not an arch above it.
					var query := PhysicsRayQueryParameters3D.create(pos, pos + Vector3.DOWN * 300)
					var hit := space.intersect_ray(query)
					if hit.is_empty(): missing = true
					# The canyon shoulder meets the banked road within centimetres.
					elif hit.position.y > pos.y - (0.02 if route.path == "res://tracks/05_canyon_study.json" else 3.0): blocked = true
			check(not missing, "Das Gelände fängt einen Fall entlang der ganzen Strecke auf.")
			check(not blocked, "Das Gelände hält Abstand unter den Steilkurven und Sprüngen.")
			var imported := 0
			var blocks_road := false
			for item in landscape.scenery.get_children():
				if item.has_meta("biome_asset"): imported += 1
				var radius: float = item.get_meta("clearance_radius", 0.0)
				for point in track.points:
					if Vector2(point.x-item.position.x, point.z-item.position.z).length() < radius+6.0:
						blocks_road = true
			check(imported > 30, "Die Landschaft nutzt die CC0-Modelle.")
			check(not blocks_road, "Die Modelle lassen alle Straßenabschnitte frei.")
		landscape.free()
	print("WÜSTE UND SCHNEE: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
