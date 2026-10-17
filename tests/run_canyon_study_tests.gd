extends SceneTree

const PATH := "res://tracks/05_canyon_study.json"
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(FileAccess.file_exists(PATH), "Die Schlucht fehlt in der Streckenauswahl.")
	if failures:
		quit(1)
		return
	var track = load("res://scripts/track/track_data.gd").new(PATH)
	check(track.valid and track.length_m == 200, "Die Teststrecke muss 200 Meter lang und gültig sein.")
	var builder = load("res://scripts/track/track_builder.gd").new()
	root.add_child(builder)
	builder.build(track)
	var study = builder.landscape.get_node_or_null("CanyonStudy")
	check(study != null, "Die Teststrecke muss die neuen Felsformen laden.")
	if study != null:
		check(study.get_node_or_null("Mesa") != null, "Der Tafelberg fehlt.")
		check(study.get_node_or_null("Arch") != null, "Der Felsbogen fehlt.")
		await physics_frame
		await physics_frame
		var space = root.world_3d.direct_space_state
		# The canyon road needs a solid shoulder, without the old eleven-metre drop.
		var shoulder_frame: Dictionary = track.sample(25)
		for side in [-1.0, 1.0]:
			var edge: Vector3 = shoulder_frame.position + shoulder_frame.right * side * 3.4
			var shoulder := space.intersect_ray(PhysicsRayQueryParameters3D.create(edge + Vector3.UP, edge - Vector3.UP * 2.0, 1))
			check(not shoulder.is_empty(), "Der Straßenrand braucht einen festen Übergang zum Gelände.")
		var blocked := false
		# Sweep the full road width and the ordinary camera corridor.
		for distance in range(0, 200, 2):
			var frame: Dictionary = track.sample(distance)
			for side in [-3.5, 0.0, 3.5]:
				for height in [0.5, 2.5, 5.0]:
					var from: Vector3 = frame.position + frame.right * side + Vector3.UP * height
					var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + track.forward(frame.heading)*2.0, 4))
					if not hit.is_empty(): blocked = true
		check(not blocked, "Felsen müssen die Fahrbahn und die Fahrkamera freihalten.")
		var arch_frame: Dictionary = track.sample(148)
		var below: Vector3 = arch_frame.position + Vector3.UP * 5
		var roof := space.intersect_ray(PhysicsRayQueryParameters3D.create(below, below+Vector3.UP*45, 4))
		check(not roof.is_empty(), "Der Felsbogen muss über der Fahrbahn liegen.")
		if not roof.is_empty(): check(roof.position.y > arch_frame.position.y+8, "Der Felsbogen braucht genügend Höhe.")
		var wall_frame: Dictionary = track.sample(25)
		var wall_from: Vector3 = wall_frame.position + Vector3.UP
		var wall_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(wall_from, wall_from-wall_frame.right*60, 1))
		check(not wall_hit.is_empty(), "Die Felswand muss für das Auto eine feste Grenze bilden.")
		var drive = load("res://scripts/vehicle/drive_model.gd").new(track)
		var sent := {}
		for step in range(3000):
			for curve in track.curves:
				if drive.distance_m > curve.start_m-28 and not sent.has(curve.id):
					drive.request_turn(curve.turn_sign)
					sent[curve.id] = true
			drive.step(1.0/60.0)
			if drive.finished or drive.off_road: break
		check(drive.finished and not drive.off_road, "Die Teststrecke muss mit einem passenden Fahrbefehl fahrbar sein.")
	builder.free()
	print("FELSSCHLUCHT: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
