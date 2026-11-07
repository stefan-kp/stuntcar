extends RefCounted
# Finds, for every element with a stunt speed window, the held speeds at which the car
# gets across it. The car enters the element at a speed, the assist holds that speed,
# every curve is called correctly, and the run passes when the car is on the road
# PASS_AFTER_M past the element's end.
const State = preload("res://scripts/vehicle/spatial/drive_state.gd")
const Surface = preload("res://scripts/vehicle/spatial/surface_motion.gd")
const Flight = preload("res://scripts/vehicle/spatial/flight_motion.gd")
const Assist = preload("res://scripts/vehicle/spatial/stunt_assist.gd")
const WALK_MPS := 1.0
const STEP_MPS := 0.1
const MIN_MPS := 1.0
const MAX_MPS := 58.0
const PASS_AFTER_M := 30.0
const MAX_SECONDS := 20.0
const DT := 1.0 / 60.0

# Returns {element_id: {"min_mps", "max_mps", "target_mps", "passes"}} for one assist level.
# The search walks out from the target in WALK_MPS steps and then bisects each edge to
# STEP_MPS, so it reports the passing range that contains the target. Both bounds are
# null when the target itself fails.
static func compute(track, profile: Dictionary) -> Dictionary:
	var result := {}
	for e in track.elements:
		var limits: Dictionary = Assist.limits(e)
		if limits.is_empty(): continue
		var target := float(limits.target_mps)
		var passes := crosses(track, profile, e, target)
		result[e.id] = {"min_mps": edge(track, profile, e, target, -1.0) if passes else null,
			"max_mps": edge(track, profile, e, target, 1.0) if passes else null, "target_mps": target, "passes": passes}
	return result

# The last passing speed from `target` in `direction`, within STEP_MPS.
static func edge(track, profile: Dictionary, e: Dictionary, target: float, direction: float) -> float:
	var good := target
	var bad := INF
	while bad == INF:
		var next := clampf(good + direction * WALK_MPS, MIN_MPS, MAX_MPS)
		if is_equal_approx(next, good): return good
		if crosses(track, profile, e, next): good = next
		else: bad = next
	while absf(bad - good) > STEP_MPS:
		var middle := (good + bad) * 0.5
		if crosses(track, profile, e, middle): good = middle
		else: bad = middle
	return snappedf(good, 0.01)

static func crosses(track, profile: Dictionary, e: Dictionary, speed: float) -> bool:
	var state = State.new()
	var frame: Dictionary = track.sample_element(e.id, 0.0)
	state.position = frame.position
	state.basis = frame.basis
	state.velocity = -frame.basis.z * speed
	state.element_id = e.id
	state.distance_m = e.start_m
	var goal: float = minf(e.end_m + PASS_AFTER_M, track.length_m)
	var controls := {"target_speed_mps": speed, "turn_authorized": true, "steering_direction": 0}
	for tick in range(int(MAX_SECONDS / DT)):
		var remaining := DT
		var iterations := 0
		while remaining > 0.000001 and iterations < 8 and state.mode in ["grounded", "airborne"]:
			iterations += 1
			var aid := {"target_speed_mps": speed, "accel_cap_mps2": profile.assist_accel_mps2, "brake_cap_mps2": profile.assist_brake_mps2,
				"hold_mps2": profile.hold_mps2 if state.element_id == e.id else 0.0}
			var outcome: Dictionary = Surface.step(track, state, controls, aid, remaining) if state.mode == "grounded" else Flight.step(track, state, aid, remaining)
			remaining = outcome.remaining_s
		if state.mode == "finished": return true
		if state.mode != "grounded" and state.mode != "airborne": return false
		if iterations >= 8 and remaining > 0.000001: return false
		if state.mode == "grounded" and state.distance_m >= goal - 0.001: return true
	return false
