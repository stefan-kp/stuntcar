extends "res://tests/spatial/test_base.gd"
const Pieces = preload("res://scripts/track/pieces/piece_generator.gd")
const Builder = preload("res://scripts/track/pieces/circuit_builder.gd")
const Forms = preload("res://scripts/track/spatial/form_library.gd")
const Cases = preload("res://tests/spatial/full_drive_cases.gd")
const Factory = preload("res://scripts/track/track_factory.gd")
const Catalog = preload("res://scripts/track/track_data.gd")
const Verification = preload("res://scripts/track/spatial/verification.gd")
const Assist = preload("res://scripts/vehicle/spatial/stunt_assist.gd")
const Road = preload("res://scripts/track/visuals/road_mesh.gd")
const MATCH_M := 0.02
const MATCH_DEG := 1.0

func _initialize() -> void:
	var library: Dictionary = Forms.load_file("res://tracks/forms/stunt_v1.json").forms
	# Parameters rebuild the fixed forms that came from Blender.
	match_form(library.straight_24, {"type": "straight", "length_m": 24}, "straight_24")
	match_form(library.curve_left_45, {"type": "curve", "direction": "left", "angle_deg": 45, "radius_m": 28}, "curve_left_45")
	match_form(library.curve_right_45, {"type": "curve", "direction": "right", "angle_deg": 45, "radius_m": 28}, "curve_right_45")
	match_form(library.hill_32, {"type": "hill", "length_m": 32, "height_m": 3}, "hill_32")
	match_form(library.bank_left_90, {"type": "curve", "direction": "left", "angle_deg": 90, "radius_m": 28, "bank_deg": 45}, "bank_left_90")
	match_form(library.bank_right_90, {"type": "curve", "direction": "right", "angle_deg": 90, "radius_m": 28, "bank_deg": 45}, "bank_right_90")
	check_generated_forms_are_valid()
	check_limits()
	check_circuit()
	check_stunt_circuit()
	done()

func match_form(reference: Dictionary, piece: Dictionary, name: String) -> void:
	var generated: Dictionary = Pieces.generate(piece)
	check(generated.errors.is_empty(), name + ": parameters accepted " + str(generated.errors))
	if not generated.errors.is_empty(): return
	var form: Dictionary = generated.form
	check(form.kind == reference.kind or name.begins_with("bank"), name + ": same kind")
	var exit_a := Forms.pose(form.exit)
	var exit_b := Forms.pose(reference.exit)
	check(exit_a.origin.distance_to(exit_b.origin) < 0.001, name + ": exit position within 1 mm")
	check(rad_to_deg(exit_a.basis.get_rotation_quaternion().angle_to(exit_b.basis.get_rotation_quaternion())) < 0.1, name + ": exit direction within 0.1°")
	var worst := 0.0
	var worst_up := 0.0
	for i in range(reference.points.size()):
		var near := nearest(form, Forms.vector(reference.points[i]))
		worst = maxf(worst, near.distance)
		worst_up = maxf(worst_up, rad_to_deg(near.up.angle_to(Forms.vector(reference.ups[i]))))
	for p in form.points:
		worst = maxf(worst, nearest(reference, Forms.vector(p)).distance)
	print("%s: %.4f m, %.3f°" % [name, worst, worst_up])
	check(worst <= MATCH_M, name + ": centre line within 2 cm (%.4f m)" % worst)
	check(worst_up <= MATCH_DEG, name + ": up vectors within 1° (%.3f°)" % worst_up)

func nearest(form: Dictionary, p: Vector3) -> Dictionary:
	var best := {"distance": INF, "up": Vector3.UP}
	for i in range(form.points.size() - 1):
		var a := Forms.vector(form.points[i])
		var b := Forms.vector(form.points[i + 1])
		var t := clampf((p - a).dot(b - a) / maxf(a.distance_squared_to(b), 0.0000001), 0, 1)
		var d := p.distance_to(a.lerp(b, t))
		if d < best.distance:
			best = {"distance": d, "up": Forms.vector(form.ups[i]).lerp(Forms.vector(form.ups[i + 1]), t).normalized()}
	return best

func check_generated_forms_are_valid() -> void:
	var forms := {}
	var pieces := [{"type": "straight", "length_m": 60, "rise_m": 5}, {"type": "hill", "length_m": 40, "height_m": -4},
		{"type": "curve", "direction": "right", "angle_deg": 180, "radius_m": 40, "bank_deg": 30}]
	for i in range(pieces.size()):
		forms["p%d" % i] = Pieces.generate(pieces[i]).form
	var path := "user://piece-forms-%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "forms": forms}))
	file.close()
	var loaded: Dictionary = Forms.load_file(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.errors.is_empty() and loaded.forms.size() == pieces.size(), "Generated forms pass the form library checks " + str(loaded.errors))
	var rise: Transform3D = Forms.pose(forms.p0.exit)
	check(is_equal_approx(rise.origin.y, 5.0) and rise.basis.is_equal_approx(Basis.IDENTITY), "A rising straight ends 5 m higher and level")
	var turn: Transform3D = Forms.pose(forms.p2.exit)
	check(turn.origin.distance_to(Vector3(80, 0, 0)) < 0.001, "A 180° right curve with 40 m radius ends 80 m to the right")
	var middle: Vector3 = Forms.vector(forms.p2.ups[forms.p2.ups.size() / 2])
	check(absf(rad_to_deg(middle.angle_to(Vector3.UP)) - 30.0) < 0.5 and middle.z > 0, "The bank peaks at 30° towards the centre of the curve")

func check_limits() -> void:
	var rejected := [
		[{"type": "loop", "radius_m": 12}, "unknown_type"],
		[{"type": "straight", "length_m": 4}, "length_m"],
		[{"type": "straight", "length_m": 20, "rise_m": 8}, "slope"],
		[{"type": "hill", "length_m": 20, "height_m": 8}, "slope"],
		[{"type": "hill", "length_m": 40, "height_m": 0}, "height_m"],
		[{"type": "curve", "direction": "up", "angle_deg": 90, "radius_m": 30}, "direction"],
		[{"type": "curve", "direction": "left", "angle_deg": 90, "radius_m": 10}, "radius_m"],
		[{"type": "curve", "direction": "left", "angle_deg": 90, "radius_m": 30, "bank_deg": 60}, "bank_deg"],
	]
	for case in rejected:
		var errors: Array = Pieces.generate(case[0]).errors
		check(case[1] in errors, "Rejects %s with %s (got %s)" % [str(case[0]), case[1], str(errors)])

func circuit(pieces: Array) -> Dictionary:
	return {"format_version": 3, "name": "Test circuit", "description": "Test", "scenario": "forest", "start": {"height_m": 12}, "pieces": pieces}

func check_circuit() -> void:
	var pieces := []
	var middles := [{"type": "straight", "length_m": 40}, {"type": "hill", "length_m": 40, "height_m": 3},
		{"type": "straight", "length_m": 40, "rise_m": 4}, {"type": "straight", "length_m": 40, "rise_m": -4}]
	for middle in middles:
		pieces.append({"type": "straight", "length_m": 60})
		pieces.append(middle)
		pieces.append({"type": "straight", "length_m": 60})
		pieces.append({"type": "curve", "direction": "right", "angle_deg": 90, "radius_m": 30, "bank_deg": 25})
	var loaded: Dictionary = Builder.load_track(circuit(pieces))
	check(loaded.errors.is_empty(), "A closed square circuit builds " + str(loaded.errors))
	if not loaded.errors.is_empty(): return
	var track = loaded.track
	check(track.curves.size() == 4, "The circuit has four curves with an input")
	check(track.curves.all(func(c): return c.turn_sign == 1), "All curves turn right")
	var end: Dictionary = track.sample(track.length_m)
	check(end.position.distance_to(track.sample(0).position) < 0.01, "The circuit ends where it starts")
	var open := pieces.duplicate(true)
	open[0].length_m = 50
	var failed: Dictionary = Builder.build(circuit(open))
	check(failed.errors.size() == 1 and failed.errors[0].begins_with("circuit_open: end is 10.00 m"), "An open circuit names the gap " + str(failed.errors))
	var bad := pieces.duplicate(true)
	bad[3].radius_m = 5
	failed = Builder.build(circuit(bad))
	check(failed.errors == ["piece 3 (curve): radius_m"], "A bad piece names its index and field " + str(failed.errors))
	for level in ["very_easy", "easy"]:
		var drive: Dictionary = Cases.record(track, level, 22)
		check(drive.finished, "%s: the car drives one lap with one input per curve (%s at %s)" % [level, drive.mode, drive.element])
	var wrong: Dictionary = Cases.record(track, "easy", 22, "wrong")
	check(not wrong.finished and wrong.mode == "crashed", "The wrong direction takes the car off the circuit")

func check_stunt_circuit() -> void:
	var path := "res://tracks/08_stunt_circuit.json"
	var loaded: Dictionary = Factory.load_track(path)
	check(loaded.errors.is_empty() and loaded.format_version == 3, "The Stunt Circuit loads as format 3 " + str(loaded.errors))
	if not loaded.errors.is_empty(): return
	var track = loaded.track
	check(Catalog.catalog().any(func(r): return r.path == path and r.curves == 4), "The track menu lists the Stunt Circuit with four curves")
	for level in ["very_easy", "easy"]:
		check(Verification.playable(track, Assist.profile(level)), "%s: the drive report matches the current track and code" % level)
	check(track.preview_path == "res://tracks/previews/stunt_circuit.png", "The Stunt Circuit uses its own preview")
	var road: Node3D = Road.build_element(track.elements[3], "neutral")
	check(road.get_child_count() == 4 and road.get_children().all(func(m): return m.mesh.get_surface_count() == 1), "A curve gets a surface, deck, edge lines and barriers")
	road.free()
	var pillars: Node3D = Road.build_pillars(track, "neutral")
	check(pillars.get_child_count() >= 60, "Pillars carry the road around the circuit (%d)" % pillars.get_child_count())
	var grounded := true
	for pillar in pillars.get_children():
		grounded = grounded and is_equal_approx(pillar.position.y - pillar.transform.basis.y.length() * 0.5, Road.GROUND_Y)
	check(grounded, "Every pillar stands on the ground")
	pillars.free()
