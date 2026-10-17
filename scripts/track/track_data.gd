extends RefCounted

const Scenarios = preload("res://scripts/track/scenarios.gd")
const ROAD_WIDTH := 6.0
const BASE_HEIGHT := 12.0
const DEFAULT_PATH := "res://tracks/01_erste_fahrt.json"
var source_path := DEFAULT_PATH
var track_name := String(TranslationServer.translate("I18N_TRACK_FOREST_NAME"))
var description := ""
var scenario := "forest"
var preview_path := ""
var length_m := 600.0
var points := PackedVector3Array()
var headings := PackedFloat32Array()
var curves: Array[Dictionary] = []
var heights: Array[Dictionary] = []
var jumps: Array[Dictionary] = []
var valid := true
var validation_error := ""

static func read_definition(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error": String(TranslationServer.translate("I18N_FILE_MISSING")), "data": null}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"error": String(TranslationServer.translate("I18N_FILE_UNREADABLE")), "data": null}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"error": String(TranslationServer.translate("I18N_TRACK_JSON_ERROR")) % [parser.get_error_line(), parser.get_error_message()], "data": null}
	return {"error": validate_definition(parser.data), "data": parser.data}

static func scan_catalog(folder: String = "res://tracks") -> Dictionary:
	var result: Array[Dictionary] = []
	var errors: Array[String] = []
	var files := DirAccess.get_files_at(folder)
	files.sort()
	for file in files:
		if not file.ends_with(".json"): continue
		var path := folder.path_join(file)
		var report := read_definition(path)
		if not report.error.is_empty():
			errors.append(file + ": " + report.error)
			continue
		var d: Dictionary = report.data
		var landscape: String = d.get("scenario", "forest")
		var preview := Scenarios.preview(landscape)
		var custom: String = d.get("preview", "")
		if not custom.is_empty():
			preview = folder.path_join(custom)
			if not ResourceLoader.exists(preview) and not FileAccess.file_exists(preview):
				errors.append(String(TranslationServer.translate("I18N_TRACK_PREVIEW_MISSING")) % [file, custom])
				preview = Scenarios.preview(landscape)
		result.append({"path": path, "name": String(TranslationServer.translate(d.name)), "description": String(TranslationServer.translate(d.description)),
			"scenario": landscape, "preview": preview, "landscape_preview": preview == Scenarios.preview(landscape),
			"length_m": d.length_m, "curves": d.curves.size(), "jumps": d.jumps.size()})
	return {"routes": result, "errors": errors}

static func catalog() -> Array[Dictionary]:
	return scan_catalog().routes

static func validate_definition(d) -> String:
	if not d is Dictionary: return String(TranslationServer.translate("I18N_TRACK_OBJECT_ERROR"))
	for key in ["name", "description"]:
		if not d.get(key) is String or d[key].strip_edges().is_empty(): return String(TranslationServer.translate("I18N_TRACK_NAME_ERROR"))
	if not d.get("scenario", "forest") is String or not Scenarios.NAMES.has(d.get("scenario", "forest")):
		return String(TranslationServer.translate("I18N_TRACK_SCENARIO_ERROR"))
	if not d.get("preview", "") is String: return String(TranslationServer.translate("I18N_TRACK_PREVIEW_NAME_ERROR"))
	var preview: String = d.get("preview", "")
	if not preview.is_empty() and (preview.is_absolute_path() or ".." in preview.split("/") or preview.get_extension().to_lower() not in ["png", "jpg", "jpeg", "webp"]):
		return String(TranslationServer.translate("I18N_TRACK_PREVIEW_PATH_ERROR"))
	if not number(d.get("format_version", 1)) or d.get("format_version", 1) != 1: return String(TranslationServer.translate("I18N_TRACK_VERSION_ERROR"))
	for key in d:
		if key not in ["format_version", "name", "description", "scenario", "preview", "length_m", "curves", "heights", "jumps"]:
			return String(TranslationServer.translate("I18N_TRACK_FIELD_ERROR")) % str(key)
	if not number(d.get("length_m")) or d.length_m < 200 or d.length_m > 10000 or d.length_m != floor(d.length_m): return String(TranslationServer.translate("I18N_TRACK_LENGTH_ERROR"))
	for key in ["curves", "heights", "jumps"]:
		if not d.get(key) is Array: return String(TranslationServer.translate("I18N_TRACK_PARTS_ERROR"))
	var previous := 0.0
	for c in d.curves:
		if not c is Dictionary: return String(TranslationServer.translate("I18N_TRACK_CURVE_ERROR"))
		for key in ["start_m", "end_m", "turn_sign", "radius", "checkpoint_m"]:
			if not number(c.get(key)): return String(TranslationServer.translate("I18N_TRACK_CURVE_NUMBER_ERROR"))
		if c.start_m < previous + 40 or c.end_m <= c.start_m + 24 or c.end_m > d.length_m - 20 or absf(c.turn_sign) != 1.0 or c.radius < 20 or c.checkpoint_m < previous or c.checkpoint_m > c.start_m - 25: return String(TranslationServer.translate("I18N_TRACK_CURVE_SPACE_ERROR"))
		if not number(c.get("bank_degrees", 0)) or c.get("bank_degrees", 0) < 0 or c.get("bank_degrees", 0) > 45: return String(TranslationServer.translate("I18N_TRACK_BANK_ERROR"))
		if not valid_speed_hint(c.get("speed_hint")): return String(TranslationServer.translate("I18N_TRACK_SPEED_HINT_ERROR"))
		previous = c.end_m
	if d.heights.size() < 2: return String(TranslationServer.translate("I18N_TRACK_HEIGHT_COUNT_ERROR"))
	previous = -1.0
	for h in d.heights:
		if not h is Dictionary or not number(h.get("at_m")) or not number(h.get("height_m")): return String(TranslationServer.translate("I18N_TRACK_HEIGHT_ERROR"))
		if h.at_m <= previous or h.at_m > d.length_m or h.height_m < 5 or h.height_m > 100: return String(TranslationServer.translate("I18N_TRACK_HEIGHT_RANGE_ERROR"))
		previous = h.at_m
	if d.heights[0].at_m != 0 or d.heights[-1].at_m != d.length_m: return String(TranslationServer.translate("I18N_TRACK_HEIGHT_END_ERROR"))
	previous = 0.0
	for j in d.jumps:
		if not j is Dictionary: return String(TranslationServer.translate("I18N_TRACK_JUMP_ERROR"))
		for key in ["start_m", "end_m", "height_m"]:
			if not number(j.get(key)): return String(TranslationServer.translate("I18N_TRACK_JUMP_NUMBER_ERROR"))
		if j.start_m < previous + 60 or j.end_m - j.start_m < 15 or j.end_m - j.start_m > 50 or j.end_m > d.length_m - 60 or j.height_m < 2 or j.height_m > 12: return String(TranslationServer.translate("I18N_TRACK_JUMP_SPACE_ERROR"))
		for c in d.curves:
			if j.start_m - 60 < c.end_m and j.end_m + 90 > c.start_m: return String(TranslationServer.translate("I18N_TRACK_JUMP_TURN_ERROR"))
		if not valid_speed_hint(j.get("speed_hint")): return String(TranslationServer.translate("I18N_TRACK_SPEED_HINT_ERROR"))
		previous = j.end_m
	return ""

static func valid_speed_hint(hint) -> bool:
	if hint == null: return true
	if not hint is Dictionary or hint.get("version") != 1: return false
	if hint.get("status") not in ["unverified", "assisted_tested", "verified"]: return false
	if not hint.get("model") is String or hint.model.is_empty(): return false
	for key in hint:
		if key not in ["version", "min_mps", "max_mps", "target_mps", "status", "model"]: return false
	for key in ["min_mps", "max_mps", "target_mps"]:
		if not hint.has(key): return false
		if hint[key] != null and (not number(hint[key]) or hint[key] < 0 or hint[key] > 200): return false
	if hint.min_mps != null and hint.max_mps != null and hint.min_mps > hint.max_mps: return false
	if hint.target_mps != null:
		if hint.min_mps != null and hint.target_mps < hint.min_mps: return false
		if hint.max_mps != null and hint.target_mps > hint.max_mps: return false
	if hint.model == "position_based_v1" and (hint.status != "unverified" or hint.min_mps != null or hint.max_mps != null): return false
	return true

func speed_hint_at(s: float, approach: float = 0.0) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for c in curves:
		if s >= c.start_m - approach and s < c.end_m:
			candidates.append({"kind":"curve", "element":c})
	for j in jumps:
		if s >= j.start_m - approach and s < j.end_m:
			candidates.append({"kind":"ramp", "element":j})
	candidates.sort_custom(func(a,b): return a.element.start_m < b.element.start_m)
	if candidates.is_empty(): return {}
	var candidate: Dictionary = candidates[0]
	var hint: Dictionary = candidate.element.get("speed_hint", {"version":1,"min_mps":null,"max_mps":null,"target_mps":null,"status":"unverified","model":"unknown"}).duplicate(true)
	hint.merge({"kind":candidate.kind,"start_m":candidate.element.start_m,"end_m":candidate.element.end_m})
	return hint

static func number(value) -> bool:
	return typeof(value) in [TYPE_FLOAT, TYPE_INT] and is_finite(float(value))

func _init(path: String = DEFAULT_PATH) -> void:
	source_path = path
	var report := read_definition(path)
	validation_error = report.error
	valid = validation_error.is_empty()
	var definition = report.data
	if not valid:
		# A removed default route must not prevent the selection screen from opening.
		definition = {"name": String(TranslationServer.translate("I18N_TRACK_NONE_SELECTED")), "description": String(TranslationServer.translate("I18N_TRACK_SELECT_VALID")),
			"length_m": 200, "curves": [], "jumps": [], "heights": [{"at_m": 0, "height_m": 12}, {"at_m": 200, "height_m": 12}]}
		source_path = ""
	scenario = definition.get("scenario", "forest")
	preview_path = Scenarios.preview(scenario)
	track_name = tr(definition.name)
	description = tr(definition.description)
	length_m = definition.length_m
	for c in definition.curves:
		c["id"] = curves.size()
		curves.append(c)
	for h in definition.heights: heights.append(h)
	for j in definition.jumps: jumps.append(j)
	var p := Vector3(0, height_at(0), 0)
	var heading := 0.0
	points.append(p)
	headings.append(heading)
	for i in range(int(length_m)):
		var curvature := 0.0
		var s := float(i) + 0.5
		for curve in curves:
			if s >= curve.start_m and s < curve.end_m:
				var blend: float = minf(1.0, minf((s - curve.start_m) / 8.0, (curve.end_m - s) / 8.0))
				curvature = float(curve.turn_sign) / float(curve.radius) * blend
		p += forward(heading + curvature * 0.5)
		heading += curvature
		p.y = height_at(float(i + 1))
		points.append(p)
		headings.append(heading)

static func forward(heading: float) -> Vector3:
	return Vector3(sin(heading), 0, -cos(heading))

static func right(heading: float) -> Vector3:
	return Vector3(cos(heading), 0, sin(heading))

func bank_at(s: float) -> float:
	for curve in curves:
		if s >= curve.start_m and s <= curve.end_m:
			var blend := smoothstep(curve.start_m, curve.start_m + 18.0, s) * (1.0 - smoothstep(curve.end_m - 18.0, curve.end_m, s))
			return -float(curve.turn_sign) * deg_to_rad(float(curve.get("bank_degrees", 0))) * blend
	return 0.0

func height_at(s: float) -> float:
	for i in range(heights.size() - 1):
		var a: Dictionary = heights[i]
		var b: Dictionary = heights[i + 1]
		if s <= b.at_m:
			return lerpf(a.height_m, b.height_m, smoothstep(a.at_m, b.at_m, s))
	return heights[-1].height_m

func jump_at(s: float, approach: float = 0.0) -> Dictionary:
	for jump in jumps:
		if s >= jump.start_m - approach and s < jump.end_m:
			return jump
	return {}

func jump_for_correction(s: float) -> Dictionary:
	for jump in jumps:
		if s >= jump.start_m - 55.0 and s < jump.end_m + 20.0:
			return jump
	return {}

func flight_height(s: float) -> float:
	var jump := jump_at(s)
	if jump.is_empty(): return height_at(s)
	var t: float = (s - jump.start_m) / (jump.end_m - jump.start_m)
	return lerpf(height_at(jump.start_m), height_at(jump.end_m), t) + 4.0 * jump.height_m * t * (1.0 - t)

func pitch_at(s: float) -> float:
	return atan2(flight_height(minf(length_m, s + 0.3)) - flight_height(maxf(0, s - 0.3)), 0.6)

func sample(s: float) -> Dictionary:
	var distance := clampf(s, 0.0, length_m)
	var index := mini(int(distance), points.size() - 2)
	var weight := distance - float(index)
	var heading := lerp_angle(headings[index], headings[index + 1], weight)
	var bank := bank_at(distance)
	return {"position": points[index].lerp(points[index + 1], weight), "heading": heading, "bank": bank, "right": right(heading) + Vector3.UP * tan(bank)}

func section_at(s: float) -> Dictionary:
	for curve in curves:
		if s >= curve.start_m and s < curve.end_m:
			return curve
	return {"id": -1, "turn_sign": 0, "start_m": 0.0, "end_m": length_m, "checkpoint_m": 0.0}

func next_curve(s: float) -> Dictionary:
	for curve in curves:
		if s < curve.end_m:
			return curve
	return {}

func project(p: Vector3, hint: float = -1.0) -> Dictionary:
	var begin := 0 if hint < 0.0 else maxi(0, int(hint) - 15)
	var end := points.size() - 1 if hint < 0.0 else mini(points.size() - 1, int(hint) + 25)
	var best_sq := INF
	var best_s := 0.0
	for i in range(begin, end):
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[i + 1].x, points[i + 1].z)
		var pos := Vector2(p.x, p.z)
		var t := clampf((pos - a).dot(b - a) / (b - a).length_squared(), 0, 1)
		var sq := pos.distance_squared_to(a.lerp(b, t))
		if sq < best_sq:
			best_sq = sq
			best_s = float(i) + t
	var frame := sample(best_s)
	frame["distance_m"] = best_s
	frame["lateral"] = (p - frame.position).dot(right(frame.heading))
	frame["gap"] = sqrt(best_sq)
	return frame
