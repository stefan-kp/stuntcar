extends RefCounted
# Builds the drive form of one parametric track piece.
# A form uses the layout of tracks/forms/stunt_v1.json: centre points, up vectors,
# and entry and exit poses. Every piece starts at the origin and drives along -Z.
const STEP_M := 0.3
const WIDTH_M := 6.0
const GRAVITY := 9.81
# Both ramps of a jump are this long; the take-off and landing ramp are parabolas.
const RAMP_M := 18.0
# A jump is aimed this far into the landing ramp, so a slightly slow car still lands on it.
const AIM_M := 6.0
const LIMITS := {
	"straight": {"length_m": [8.0, 200.0], "max_slope_deg": 15.0},
	"hill": {"length_m": [20.0, 80.0], "height_m": [-10.0, 10.0], "max_slope_deg": 30.0},
	"curve": {"angle_deg": [15.0, 180.0], "radius_m": [20.0, 80.0], "bank_deg": [0.0, 45.0]},
	"bank": {"angle_deg": [60.0, 180.0], "radius_m": [15.0, 30.0], "bank_deg": [30.0, 90.0]},
	"bumps": {"length_m": [20.0, 120.0], "count": [2.0, 12.0], "height_m": [0.2, 1.5], "max_slope_deg": 20.0},
	"ramp": {"gap_m": [10.0, 50.0], "takeoff_deg": [5.0, 25.0], "height_m": [-8.0, 4.0], "max_landing_deg": 35.0},
	"loop": {"radius_m": [8.0, 16.0], "offset_m": [6.0, 10.0]},
}

static func number(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))

static func in_range(piece: Dictionary, key: String, bounds: Array, fallback = null) -> bool:
	var v = piece.get(key, fallback)
	return number(v) and float(v) >= bounds[0] and float(v) <= bounds[1]

# Returns {"form": Dictionary, "errors": Array[String]}.
# A ramp also returns "landing_form", the landing ramp, and "landing_origin",
# where the landing form starts in the frame of the take-off ramp, and "design_mps",
# the speed that carries the car from the take-off ramp to the aim point.
static func generate(piece: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var type = piece.get("type", "")
	if not LIMITS.has(type):
		errors.append("unknown_type")
		return {"form": {}, "errors": errors}
	var limits: Dictionary = LIMITS[type]
	for key in limits:
		if key.begins_with("max_"): continue
		if not in_range(piece, key, limits[key], 0.0 if key == "bank_deg" and type == "curve" else null): errors.append(key)
	if type == "straight":
		var rise = piece.get("rise_m", 0.0)
		if not number(rise): errors.append("rise_m")
		elif errors.is_empty() and rad_to_deg(atan(PI * absf(rise) / (2.0 * piece.length_m))) > limits.max_slope_deg: errors.append("slope")
	if type == "hill" and errors.is_empty():
		if absf(piece.height_m) < 0.2: errors.append("height_m")
		elif rad_to_deg(atan(PI * absf(piece.height_m) / piece.length_m)) > limits.max_slope_deg: errors.append("slope")
	if type == "bumps" and errors.is_empty():
		if piece.count != floorf(piece.count): errors.append("count")
		elif rad_to_deg(atan(PI * piece.height_m * piece.count / piece.length_m)) > limits.max_slope_deg: errors.append("slope")
	if type in ["curve", "bank"] and piece.get("direction") not in ["left", "right"]: errors.append("direction")
	if type == "loop" and piece.get("side", "right") not in ["left", "right"]: errors.append("side")
	if not errors.is_empty(): return {"form": {}, "errors": errors}
	match type:
		"straight": return {"form": profile_form("straight", piece.length_m, piece.get("rise_m", 0.0), 0.5), "errors": errors}
		"hill": return {"form": profile_form("hill", piece.length_m, piece.height_m, 1.0), "errors": errors}
		"bumps": return {"form": profile_form("bumps", piece.length_m, piece.height_m, piece.count), "errors": errors}
		"loop": return {"form": loop_form(piece.radius_m, piece.offset_m * (-1 if piece.get("side", "right") == "left" else 1)), "errors": errors}
		"ramp": return ramp(piece, errors)
	var form := curve_form(-1 if piece.direction == "left" else 1, deg_to_rad(piece.angle_deg), piece.radius_m, deg_to_rad(piece.get("bank_deg", 0.0)))
	form.kind = type
	return {"form": form, "errors": errors}

static func samples(length_m: float) -> int:
	return maxi(8, ceili(length_m / STEP_M))

# Straight line along -Z with a vertical cosine profile of `waves` full waves.
# Half a wave is a smooth rise by `height` (a straight), one wave is a hill,
# and several waves are a row of bumps. Every profile starts and ends level.
static func profile_form(kind: String, length_m: float, height: float, waves: float) -> Dictionary:
	var points: Array = []
	var ups: Array = []
	var n := samples(length_m)
	var w := TAU * waves
	for i in range(n + 1):
		var t := float(i) / n
		var y := height * (1.0 - cos(w * t)) * 0.5
		var dy := height * w * sin(w * t) * 0.5
		points.append([0.0, y, -length_m * t])
		ups.append(vec(Vector3(0, length_m, dy).normalized()))
	var exit_y := height if is_equal_approx(waves, 0.5) else 0.0
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

# A full vertical circle. The road moves sideways by `offset` (smoothstep) so the
# exit passes beside the entry, and it leaves in the entry direction.
static func loop_form(radius: float, offset: float) -> Dictionary:
	var points: Array = []
	var ups: Array = []
	var n := samples(TAU * radius)
	for i in range(n + 1):
		var t := float(i) / n
		var a := TAU * t
		points.append([offset * t * t * (3.0 - 2.0 * t), radius * (1.0 - cos(a)), -radius * sin(a)])
		ups.append([0.0, cos(a), sin(a)])
	return make_form("loop", points, ups, Transform3D(Basis.IDENTITY, Vector3(offset, 0, 0)))

# Take-off ramp: a parabola that leaves level ground and ends pitched up by `angle`.
# With a negative angle it is the landing ramp: it starts pitched down and ends level.
static func ramp_form(kind: String, angle: float) -> Dictionary:
	var points: Array = []
	var ups: Array = []
	var n := samples(RAMP_M)
	var slope := tan(absf(angle))
	var up_ramp := angle > 0
	for i in range(n + 1):
		var u := RAMP_M * float(i) / n
		var y := slope * u * u / (2.0 * RAMP_M) if up_ramp else -slope * u + slope * u * u / (2.0 * RAMP_M)
		var dy := slope * u / RAMP_M if up_ramp else -slope * (1.0 - u / RAMP_M)
		points.append([0.0, y, -u])
		ups.append(vec(Vector3(0, 1, dy).normalized()))
	var end_y: float = points[-1][1]
	var pitch := Basis(Vector3.RIGHT, absf(angle))
	var entry := Transform3D.IDENTITY if up_ramp else Transform3D(pitch.inverse(), Vector3.ZERO)
	var exit := Transform3D(pitch, Vector3(0, end_y, -RAMP_M)) if up_ramp else Transform3D(Basis.IDENTITY, Vector3(0, end_y, -RAMP_M))
	var form := make_form(kind, points, ups, exit)
	form.entry = pose(entry)
	return form

# A jump over a gap. The landing ramp starts at the angle of the flight path that
# just reaches it. The design speed carries the car AIM_M further, onto the ramp.
static func ramp(piece: Dictionary, errors: Array[String]) -> Dictionary:
	var takeoff := deg_to_rad(piece.takeoff_deg)
	var rise := RAMP_M * tan(takeoff) * 0.5
	var gap: float = piece.gap_m
	var landing := takeoff
	for i in range(200):
		var start_y: float = piece.height_m + RAMP_M * tan(landing) * 0.5
		var speed_sq := flight_speed_sq(rise, takeoff, gap, start_y)
		if speed_sq <= 0: break
		var descent := GRAVITY * gap / (speed_sq * pow(cos(takeoff), 2)) - tan(takeoff)
		landing = lerpf(landing, clampf(atan(descent), 0.0, deg_to_rad(60.0)), 0.5)
	var slope := tan(landing)
	var aim_y: float = piece.height_m + RAMP_M * slope * 0.5 - slope * AIM_M + slope * AIM_M * AIM_M / (2.0 * RAMP_M)
	var design_sq := flight_speed_sq(rise, takeoff, gap + AIM_M, aim_y)
	if design_sq <= 0:
		errors.append("height_m")
		return {"form": {}, "errors": errors}
	if rad_to_deg(landing) > LIMITS.ramp.max_landing_deg:
		errors.append("landing_angle")
		return {"form": {}, "errors": errors}
	return {"form": ramp_form("launch", takeoff), "landing_form": ramp_form("landing", -landing),
		"landing_origin": Vector3(0, piece.height_m + RAMP_M * slope * 0.5, -RAMP_M - gap), "design_mps": sqrt(design_sq), "errors": errors}

# Squared speed at which a car leaving the take-off ramp end (height `rise`, angle `takeoff`)
# passes `reach` metres further at height `y`; zero or less if no speed does.
static func flight_speed_sq(rise: float, takeoff: float, reach: float, y: float) -> float:
	var fall := rise + reach * tan(takeoff) - y
	if fall <= 0: return 0.0
	return GRAVITY * reach * reach / (2.0 * pow(cos(takeoff), 2) * fall)

static func make_form(kind: String, points: Array, ups: Array, exit: Transform3D) -> Dictionary:
	points[-1] = vec(exit.origin)
	return {"version": 1, "kind": kind, "width_m": WIDTH_M, "points": points, "ups": ups, "entry": pose(Transform3D.IDENTITY), "exit": pose(exit)}

static func vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

static func pose(t: Transform3D) -> Dictionary:
	var q := t.basis.get_rotation_quaternion()
	return {"position": vec(t.origin), "rotation": [q.x, q.y, q.z, q.w]}
