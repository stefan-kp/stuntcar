extends RefCounted
# Builds the drive form of one parametric track piece.
# A form uses the layout of tracks/forms/stunt_v1.json: centre points, up vectors,
# and entry and exit poses. Every piece starts at the origin and drives along -Z.
const STEP_M := 0.3
const WIDTH_M := 6.0
const LIMITS := {
	"straight": {"length_m": [8.0, 200.0], "max_slope_deg": 15.0},
	"hill": {"length_m": [20.0, 80.0], "height_m": [-10.0, 10.0], "max_slope_deg": 30.0},
	"curve": {"angle_deg": [15.0, 180.0], "radius_m": [20.0, 80.0], "bank_deg": [0.0, 45.0]},
}

static func number(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))

static func in_range(piece: Dictionary, key: String, bounds: Array, fallback = null) -> bool:
	var v = piece.get(key, fallback)
	return number(v) and float(v) >= bounds[0] and float(v) <= bounds[1]

# Returns {"form": Dictionary, "errors": Array[String]}.
static func generate(piece: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var type = piece.get("type", "")
	if not LIMITS.has(type):
		errors.append("unknown_type")
		return {"form": {}, "errors": errors}
	var limits: Dictionary = LIMITS[type]
	for key in limits:
		if key.begins_with("max_"): continue
		if not in_range(piece, key, limits[key], 0.0 if key == "bank_deg" else null): errors.append(key)
	if type == "straight":
		var rise = piece.get("rise_m", 0.0)
		if not number(rise): errors.append("rise_m")
		elif errors.is_empty() and rad_to_deg(atan(PI * absf(rise) / (2.0 * piece.length_m))) > limits.max_slope_deg: errors.append("slope")
	if type == "hill" and errors.is_empty():
		if absf(piece.height_m) < 0.2: errors.append("height_m")
		elif rad_to_deg(atan(PI * absf(piece.height_m) / piece.length_m)) > limits.max_slope_deg: errors.append("slope")
	if type == "curve" and piece.get("direction") not in ["left", "right"]: errors.append("direction")
	if not errors.is_empty(): return {"form": {}, "errors": errors}
	match type:
		"straight": return {"form": profile_form("straight", piece.length_m, piece.get("rise_m", 0.0), false), "errors": errors}
		"hill": return {"form": profile_form("hill", piece.length_m, piece.height_m, true), "errors": errors}
	return {"form": curve_form(-1 if piece.direction == "left" else 1, deg_to_rad(piece.angle_deg), piece.radius_m, deg_to_rad(piece.get("bank_deg", 0.0))), "errors": errors}

static func samples(length_m: float) -> int:
	return maxi(8, ceili(length_m / STEP_M))

# Straight line along -Z with a vertical profile.
# A straight rises smoothly by `height` (half cosine); a hill goes up by `height` and back (full cosine).
static func profile_form(kind: String, length_m: float, height: float, returns: bool) -> Dictionary:
	var points: Array = []
	var ups: Array = []
	var n := samples(length_m)
	var w := TAU if returns else PI
	for i in range(n + 1):
		var t := float(i) / n
		var y := height * (1.0 - cos(w * t)) * 0.5
		var dy := height * w * sin(w * t) * 0.5
		points.append([0.0, y, -length_m * t])
		ups.append(vec(Vector3(0, length_m, dy).normalized()))
	var exit_y := 0.0 if returns else height
	return make_form(kind, points, ups, Transform3D(Basis.IDENTITY, Vector3(0, exit_y, -length_m)))

# Flat circular arc. Direction -1 turns left, 1 turns right.
# The bank rises and falls as sin² over the arc, so both ends stay level.
static func curve_form(direction: int, angle: float, radius: float, bank: float) -> Dictionary:
	var points: Array = []
	var ups: Array = []
	var n := samples(radius * angle)
	for i in range(n + 1):
		var t := float(i) / n
		var a := angle * t
		var b := bank * pow(sin(PI * t), 2)
		var inside := Vector3(direction * cos(a), 0, sin(a))
		points.append([direction * radius * (1.0 - cos(a)), 0.0, -radius * sin(a)])
		ups.append(vec((Vector3.UP * cos(b) + inside * sin(b)).normalized()))
	var exit := Transform3D(Basis(Vector3.UP, -direction * angle), Vector3(direction * radius * (1.0 - cos(angle)), 0, -radius * sin(angle)))
	return make_form("curve", points, ups, exit)

static func make_form(kind: String, points: Array, ups: Array, exit: Transform3D) -> Dictionary:
	points[-1] = vec(exit.origin)
	return {"version": 1, "kind": kind, "width_m": WIDTH_M, "points": points, "ups": ups, "entry": pose(Transform3D.IDENTITY), "exit": pose(exit)}

static func vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

static func pose(t: Transform3D) -> Dictionary:
	var q := t.basis.get_rotation_quaternion()
	return {"position": vec(t.origin), "rotation": [q.x, q.y, q.z, q.w]}
