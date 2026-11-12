extends RefCounted
# Turns a format 3 track (start + list of parametric pieces) into the element list
# that SpatialTrack drives on. Pieces are chained end to start, and the last piece
# must arrive back at the start: every format 3 track is a circuit.
const Pieces = preload("res://scripts/track/pieces/piece_generator.gd")
const Forms = preload("res://scripts/track/spatial/form_library.gd")
const Spatial = preload("res://scripts/track/spatial/spatial_track.gd")
const CLOSE_M := 0.01
const CLOSE_DEG := 0.1
# A landing on the landing ramp of a jump.
const JUMP_LANDING := {"max_angle_degrees": 20.0, "max_impact_mps": 12.0}
# Speed windows that tests confirmed for the 12 m loop; other loops scale with the square root of the radius.
const LOOP_12_MPS := {"min_mps": 24.0, "max_mps": 32.0, "target_mps": 26.0}

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
	var pieces: Array = fit(data.pieces, errors)
	if not errors.is_empty(): return result
	var pose := origin
	var elements: Array = []
	var landings: Array = []
	var ids := {}
	for i in range(pieces.size()):
		var piece = pieces[i]
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
		elements.append(element(id, form, pose, piece, default_assist(piece, generated)))
		if generated.has("landing_form"):
			# The landing ramp starts beyond the gap; the car flies from the take-off ramp onto it.
			var landing_id := id + "_landing"
			var landing: Dictionary = generated.landing_form
			var placed := pose * Transform3D(Basis.IDENTITY, generated.landing_origin)
			result.forms[landing_id] = landing
			elements.append(element(landing_id, landing, placed * Forms.pose(landing.entry), {}, {}))
			landings.append({"launch_id": id, "target_ids": [landing_id]}.merged(JUMP_LANDING))
		pose = advance(pose, generated)
	if not errors.is_empty(): return result
	var gap := pose.origin.distance_to(origin.origin)
	var turn := rad_to_deg(pose.basis.get_rotation_quaternion().angle_to(origin.basis.get_rotation_quaternion()))
	if gap > CLOSE_M or turn > CLOSE_DEG:
		var end := pose.origin - origin.origin
		errors.append("circuit_open: end is %.2f m from the start (x %.2f, y %.2f, z %.2f) and %.1f° off" % [gap, end.x, end.y, end.z, turn])
		return result
	result.definition = {"format_version": 3, "name": data.name, "description": data.description, "scenario": data.scenario,
		"styles": data.get("styles", {"road": "neutral", "scenery": "neutral"}), "report": data.get("report", ""),
		"elements": elements, "landings": landings}
	return result

# The pose after a piece that starts at `pose`.
static func advance(pose: Transform3D, generated: Dictionary) -> Transform3D:
	if generated.has("landing_form"):
		return pose * Transform3D(Basis.IDENTITY, generated.landing_origin) * Forms.pose(generated.landing_form.exit)
	return pose * Forms.pose(generated.form.exit)

# Where the chain of pieces ends when it starts at the origin; pieces with errors are skipped.
static func chain_end(pieces: Array) -> Transform3D:
	var pose := Transform3D.IDENTITY
	for piece in pieces:
		if not piece is Dictionary: continue
		var generated: Dictionary = Pieces.generate(piece)
		if generated.errors.is_empty(): pose = advance(pose, generated)
	return pose

# Resolves "fit" values so the circuit closes: exactly two straights may have
# "length_m": "fit", and one straight may have "rise_m": "fit".
# Returns the pieces with numbers in place of "fit".
static func fit(source: Array, errors: Array[String]) -> Array:
	var pieces: Array = source.duplicate(true)
	var lengths: Array[int] = []
	var rise := -1
	for i in range(pieces.size()):
		var piece = pieces[i]
		if not piece is Dictionary: continue
		for key in piece:
			if not piece[key] is String or piece[key] != "fit": continue
			if piece.get("type") != "straight" or key not in ["length_m", "rise_m"]: errors.append("piece %d (%s): %s" % [i, piece.get("type", "?"), key])
			elif key == "length_m": lengths.append(i)
			elif rise >= 0: errors.append("piece %d (straight): only one rise_m can be fit" % i)
			else: rise = i
	if lengths.size() not in [0, 2]: errors.append("fit: exactly two straights need \"length_m\": \"fit\", found %d" % lengths.size())
	if not errors.is_empty(): return pieces
	if rise >= 0: pieces[rise].rise_m = 0.0
	if lengths.size() == 2:
		var trial := 50.0
		pieces[lengths[0]].length_m = trial
		pieces[lengths[1]].length_m = trial
		var base := chain_end(pieces).origin
		pieces[lengths[0]].length_m = trial + 1.0
		var a := chain_end(pieces).origin - base
		pieces[lengths[0]].length_m = trial
		pieces[lengths[1]].length_m = trial + 1.0
		var b := chain_end(pieces).origin - base
		var det := a.x * b.z - a.z * b.x
		if absf(det) < 0.001:
			errors.append("fit: the two fitted straights are parallel")
			return pieces
		var first := trial + (-base.x * b.z + base.z * b.x) / det
		var second := trial + (-a.x * base.z + a.z * base.x) / det
		for pair in [[lengths[0], first], [lengths[1], second]]:
			var bounds: Array = Pieces.LIMITS.straight.length_m
			if pair[1] < bounds[0] or pair[1] > bounds[1]: errors.append("fit: piece %d would need a length of %.1f m" % pair)
			pieces[pair[0]].length_m = pair[1]
	if rise >= 0: pieces[rise].rise_m = -chain_end(pieces).origin.y
	return pieces

static func element(id: String, form: Dictionary, entry: Transform3D, piece: Dictionary, assist: Dictionary) -> Dictionary:
	var q := entry.basis.get_rotation_quaternion()
	var turns: bool = form.kind in ["curve", "bank"]
	return {"id": id, "kind": form.kind, "form_id": id, "form_version": form.version,
		"entry_transform": {"position": Pieces.vec(entry.origin), "rotation": [q.x, q.y, q.z, q.w]},
		"input": {"kind": "turn", "direction": -1 if piece.direction == "left" else 1} if turns else {"kind": "none"},
		"assist": assist, "visual_id": "procedural"}

# A piece's own "assist" wins. A jump holds its design speed; a loop scales the 12 m loop window.
static func default_assist(piece: Dictionary, generated: Dictionary) -> Dictionary:
	if piece.has("assist"): return piece.assist
	if generated.has("design_mps"):
		var v: float = snappedf(generated.design_mps, 0.1)
		return {"min_mps": v - 0.5, "max_mps": v + 0.5, "target_mps": v, "approach_m": 60.0}
	if piece.type == "loop":
		var scale := sqrt(piece.radius_m / 12.0)
		return {"min_mps": snappedf(LOOP_12_MPS.min_mps * scale, 0.1), "max_mps": snappedf(LOOP_12_MPS.max_mps * scale, 0.1),
			"target_mps": snappedf(LOOP_12_MPS.target_mps * scale, 0.1), "approach_m": 60.0}
	return {}

static func load_track(data: Dictionary, source_path: String = "") -> Dictionary:
	var built := build(data)
	if not built.errors.is_empty(): return {"track": null, "errors": built.errors}
	var track = Spatial.new(built.definition, built.forms)
	track.source_path = source_path
	return {"track": track, "errors": built.errors}
