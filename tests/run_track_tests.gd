extends SceneTree
var Track = load("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var probe = Track.new()
	check(probe.has_method("catalog"), "Die Streckenauswahl lädt mehrere Streckendateien")
	if not probe.has_method("catalog"):
		quit(1)
		return
	for file in DirAccess.get_files_at("res://tracks"):
		if file.ends_with(".json"):
			var definition = JSON.parse_string(FileAccess.get_file_as_string("res://tracks/" + file))
			check(probe.validate_definition(definition).is_empty(), "Alle angebotenen Streckendateien sind gültig: " + file)
	var template = JSON.parse_string(FileAccess.get_file_as_string("res://tracks/templates/strecke.json"))
	check(probe.validate_definition(template).is_empty(), "Die Vorlage ist direkt nutzbar")
	var invalid: Dictionary = template.duplicate(true)
	invalid.jumps[0].start_m = invalid.curves[0].start_m
	check(not probe.validate_definition(invalid).is_empty(), "Ein Sprung in einer Kurve wird abgewiesen")
	invalid = template.duplicate(true)
	invalid.heights[0].at_m = 10
	check(not probe.validate_definition(invalid).is_empty(), "Ein fehlender Höhenwert am Start wird abgewiesen")
	check(not probe.validate_definition({}).is_empty(), "Eine leere Datei wird abgewiesen")
	var routes: Array = preload("res://tests/helpers/legacy_routes.gd").catalog()
	check(routes.size() >= 3, "Drei Strecken stehen zur Auswahl")
	for route in routes:
		var track = Track.new(route.path)
		check(track.valid, "Streckendatei gültig: " + route.name)
		for speed in [14.0, 22.0, 28.0]:
			var drive = Drive.new(track)
			drive.speed_mps = speed
			drive.target_speed_mps = speed
			var sent := {}
			var flights := 0
			var was_airborne := false
			var peak := 0.0
			for i in range(8000):
				for curve in track.curves:
					if drive.distance_m > curve.start_m - 28.0 and not sent.has(curve.id):
						drive.request_turn(curve.turn_sign)
						sent[curve.id] = true
				drive.step(1.0 / 60.0)
				if drive.airborne and not was_airborne: flights += 1
				was_airborne = drive.airborne
				peak = maxf(peak, drive.position.y)
				if drive.off_road or drive.finished: break
			check(drive.finished and not drive.off_road, "%s bei %d m/s: wenige Eingaben reichen bis zum Ziel (%d m)" % [route.name, speed, drive.distance_m])
			check(flights == track.jumps.size(), "Jeder Sprung hebt tatsächlich ab")
			check(drive.speed_mps >= 14.0, "Keine automatische Pause oder Abbremsung")
			if not track.jumps.is_empty(): check(peak > 25, "Deutlich sichtbare Höhenunterschiede")
		for jump in track.jumps:
			var drive = Drive.new(track)
			drive.reset(jump.start_m - 25.0)
			drive.position += track.right(drive.heading) * 1.8
			drive.lateral = 1.8
			drive.request_turn(-1)
			for i in range(400):
				drive.step(1.0/60.0)
				if drive.distance_m > jump.end_m + 8 or drive.off_road: break
			check(not drive.off_road and absf(drive.lateral) < 0.6, "Ein kurzer Druck korrigiert die Landung")
		for jump in track.jumps:
			for input_offset in [-1.0, 8.0, 18.0]:
				for lateral in [-1.8, 1.8]:
					var drive = Drive.new(track)
					drive.reset(jump.end_m + input_offset)
					drive.position += track.right(drive.heading) * lateral
					drive.lateral = lateral
					drive.request_turn(-int(signf(lateral)))
					for i in range(500):
						drive.step(1.0/60.0)
						if drive.off_road or drive.distance_m > jump.end_m + 80: break
					check(not drive.off_road and absf(drive.lateral) < 0.6, "Späte Korrektur hält auch nach der Landung die Gerade (%d m)" % input_offset)
	print("STRECKEN: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
