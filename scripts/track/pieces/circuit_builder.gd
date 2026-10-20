extends RefCounted
# Turns a format 3 track (start + list of parametric pieces) into the element list
# that SpatialTrack drives on. Pieces are chained end to start, and the last piece
# must arrive back at the start: every format 3 track is a circuit.
const Pieces = preload("res://scripts/track/pieces/piece_generator.gd")
const Forms = preload("res://scripts/track/spatial/form_library.gd")
const Spatial = preload("res://scripts/track/spatial/spatial_track.gd")
const CLOSE_M := 0.01
const CLOSE_DEG := 0.1

# Returns {"definition", "forms", "errors"}. The definition and forms feed SpatialTrack.new().
static func build(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var result := {"definition": {}, "forms": {}, "errors": errors}
	if data.get("format_version") != 3: errors.append("format_version")
	for key in ["name", "description", "scenario"]:
		if not data.get(key) is String or data[key].is_empty(): errors.append(key)
	var start = data.get("start")
	if not start is Dictionary or not Pieces.number(start.get("height_m")) or start.height_m < 5 or start.height_m > 100: errors.append("start")
	if not data.get("pieces") is Array or data.pieces.is_empty(): errors.append("pieces")
	if not errors.is_empty(): return result
	var origin := Transform3D(Basis.IDENTITY, Vector3(0, start.height_m, 0))
	var pose := origin
	var elements: Array = []
	var ids := {}
	for i in range(data.pieces.size()):
		var piece = data.pieces[i]
		if not piece is Dictionary:
			errors.append("piece %d: fields" % i)
			continue
		var id: String = str(piece.get("id", "e%d" % i))
		if ids.has(id): errors.append("piece %d: duplicate_id" % i)
		ids[id] = true
		var generated: Dictionary = Pieces.generate(piece)
		for error in generated.errors: errors.append("piece %d (%s): %s" % [i, piece.get("type", "?"), error])
		if not generated.errors.is_empty(): continue
		var form: Dictionary = generated.form
		result.forms[id] = form
		var q := pose.basis.get_rotation_quaternion()
		elements.append({"id": id, "kind": form.kind, "form_id": id, "form_version": form.version,
			"entry_transform": {"position": Pieces.vec(pose.origin), "rotation": [q.x, q.y, q.z, q.w]},
			"input": {"kind": "turn", "direction": -1 if piece.direction == "left" else 1} if form.kind == "curve" else {"kind": "none"},
			"assist": piece.get("assist", {}), "visual_id": "procedural"})
		pose = pose * Forms.pose(form.exit)
	if not errors.is_empty(): return result
	var gap := pose.origin.distance_to(origin.origin)
	var turn := rad_to_deg(pose.basis.get_rotation_quaternion().angle_to(origin.basis.get_rotation_quaternion()))
	if gap > CLOSE_M or turn > CLOSE_DEG:
		var end := pose.origin - origin.origin
		errors.append("circuit_open: end is %.2f m from the start (x %.2f, y %.2f, z %.2f) and %.1f° off" % [gap, end.x, end.y, end.z, turn])
		return result
	result.definition = {"format_version": 3, "name": data.name, "description": data.description, "scenario": data.scenario,
		"styles": data.get("styles", {"road": "neutral", "scenery": "neutral"}), "report": data.get("report", ""),
		"elements": elements, "landings": []}
	return result

static func load_track(data: Dictionary, source_path: String = "") -> Dictionary:
	var built := build(data)
	if not built.errors.is_empty(): return {"track": null, "errors": built.errors}
	var track = Spatial.new(built.definition, built.forms)
	track.source_path = source_path
	return {"track": track, "errors": built.errors}
