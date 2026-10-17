extends RefCounted

const AssistProfile = preload("res://scripts/vehicle/assist_profile.gd")
const CurveAssist = preload("res://scripts/vehicle/curve_assist.gd")

const VoiceStrength = preload("res://scripts/input/voice_strength.gd")

const CRUISE_SPEED := 22.0
const MIN_SPEED := 14.0
const MAX_SPEED := 46.0
const SPEED_STEP := 5.0
const BOOST_SECONDS := 1.2
const BOOST_COOLDOWN := 2.8
const BOOST_BONUS := 12.0
const BOOST_ACCEL := 32.0
const FULL_BRAKE_DECEL := 42.0
var boost_remaining := 0.0
var boost_cooldown := 0.0
var emergency_braking := false
var drift_angle := 0.0
var steering_input := 0.0
var target_speed_mps := CRUISE_SPEED
var speed_strength := 1.0
var turn_strength := 1.0
var track
var position := Vector3.ZERO
var heading := 0.0
var speed_mps := 0.0
var distance_m := 0.0
var elapsed_s := 0.0
var active_curve_id := -1
var completed_curves := 0
var off_road := false
var finished := false
var lateral := 0.0
var hint_seconds := 5.0
var manual_remaining := 0.0
var manual_direction := 0
var last_command := 0
var completed_ids: Dictionary = {}
var correction_remaining := 0.0
var guide_offset := 0.0
var airborne := false
var pitch := 0.0
var bank := 0.0
var speed_feedback := ""
var speed_feedback_seconds := 0.0
var jump_assist_until := -1.0
var landing_pulse := 0.0
var assist_id := "very_easy"
var assist_profile := AssistProfile.for_id(assist_id)
var curve_assist = CurveAssist.new()
var attempt_id := 0
var input_serial := 0
var assist_events: Array[Dictionary] = []
var assist_target_mps := 0.0
var assist_speed_active := false
var assist_reason := ""
var recovery_remaining := 0.0
var motion := "normal"
var sway_remaining := 0.0
var sway_used := false

func _init(track_data) -> void:
	track = track_data
	reset()

func reset(checkpoint_m: float = 0.0) -> void:
	attempt_id += 1
	input_serial = 0
	curve_assist.reset(attempt_id)
	assist_events.clear()
	assist_speed_active = false
	assist_reason = ""
	recovery_remaining = 0.0
	motion = "normal"
	sway_remaining = 0.0
	sway_used = false
	var frame: Dictionary = track.sample(checkpoint_m)
	position = frame.position
	heading = frame.heading
	speed_mps = CRUISE_SPEED
	target_speed_mps = CRUISE_SPEED
	speed_strength = 1.0
	turn_strength = 1.0
	distance_m = checkpoint_m
	elapsed_s = 0.0
	active_curve_id = -1
	completed_curves = 0
	completed_ids.clear()
	off_road = false
	finished = false
	lateral = 0.0
	manual_remaining = 0.0
	manual_direction = 0
	last_command = 0
	correction_remaining = 0.0
	guide_offset = 0.0
	airborne = false
	pitch = track.pitch_at(distance_m)
	bank = track.bank_at(distance_m)
	speed_feedback = ""
	speed_feedback_seconds = 0.0
	jump_assist_until = -1.0
	landing_pulse = 0.0
	boost_remaining = 0.0
	boost_cooldown = 0.0
	emergency_braking = false
	drift_angle = 0.0
	steering_input = 0.0

func set_assist_level(id: String) -> void:
	assist_profile = AssistProfile.for_id(id)
	assist_id = assist_profile.id

func _emit_assist(kind: String, reason: String) -> void:
	var state: Dictionary = curve_assist.snapshot()
	if assist_events.size() >= 64: assist_events.pop_front()
	assist_events.append({"type":kind,"reason":reason,"curve_id":state.curve_id,
		"opportunity_id":state.opportunity_id,"elapsed_s":elapsed_s,
		"player_target_mps":target_speed_mps,"assist_target_mps":assist_target_mps,"speed_mps":speed_mps})

func _refresh_assist() -> void:
	if active_curve_id >= 0 and distance_m >= track.curves[active_curve_id].end_m:
		completed_ids[active_curve_id] = true
		completed_curves += 1
		active_curve_id = -1
		last_command = 0
		guide_offset = 0.0
		sway_used = false
	var projection: Dictionary = track.project(position, distance_m)
	var before: Dictionary = curve_assist.snapshot()
	curve_assist.update(track.next_curve(distance_m), {"distance_m":distance_m,"speed_mps":speed_mps,
		"target_speed_mps":target_speed_mps,"elapsed_s":elapsed_s,"hint_seconds":hint_seconds,
		"lateral":lateral,"gap":projection.gap,"heading_error_rad":angle_difference(projection.heading,heading),
		"off_road":off_road,"finished":finished}, assist_profile)
	var after: Dictionary = curve_assist.snapshot()
	if after.opened_at_s >= 0 and (before.opportunity_id != after.opportunity_id or before.opened_at_s < 0):
		_emit_assist("opened", "curve")
	if after.phase == "closed" and before.phase != "closed": _emit_assist("closed", after.closed_reason)

func assist_state() -> Dictionary:
	var state: Dictionary = curve_assist.snapshot()
	state.merge({"assist_id":assist_id,"player_target_mps":target_speed_mps,"assist_target_mps":assist_target_mps,
		"assist_speed_active":assist_speed_active,"motion":motion,"assist_reason":assist_reason})
	return state

func take_assist_events() -> Array[Dictionary]:
	var result := assist_events.duplicate()
	assist_events.clear()
	return result

func request_assisted_turn(direction: int, unknown_call: bool, event_id: String) -> bool:
	_refresh_assist()
	var was_authorized: bool = curve_assist.snapshot().authorized
	if not curve_assist.request(direction, unknown_call, event_id): return false
	var state: Dictionary = curve_assist.snapshot()
	active_curve_id = state.curve_id
	last_command = state.turn_sign
	turn_strength = 1.0
	steering_input = float(state.turn_sign)
	manual_remaining = 0.0
	if not was_authorized:
		if state.accepted_phase in ["late", "rescue"]:
			recovery_remaining = assist_profile.recovery_seconds * (2.0 if state.accepted_phase == "rescue" else 1.0)
			motion = "rescue_turn" if state.accepted_phase == "rescue" else "late_turn"
		_emit_assist("accepted", state.accepted_phase)
	return true

func request_turn(direction: int, _strength: float = VoiceStrength.NORMAL) -> void:
	if off_road or finished or direction not in [-1,1]: return
	input_serial += 1
	request_assisted_turn(direction, false, "key:%d:%d" % [attempt_id,input_serial])
	var jump: Dictionary = track.jump_for_correction(distance_m)
	if not jump.is_empty() and (absf(lateral) < 0.15 or signf(lateral) == -direction):
		jump_assist_until = maxf(jump.end_m + 24.0, distance_m + 24.0)
		turn_strength = 1.0

func input_window_m() -> float:
	return maxf(speed_mps, target_speed_mps) * hint_seconds

func change_speed(direction: int, strength: float = VoiceStrength.NORMAL) -> void:
	if direction not in [-1, 1] or off_road or finished: return
	var strong := VoiceStrength.bars(strength) == 3
	if direction < 0:
		boost_remaining = 0.0
		if strong or emergency_braking:
			emergency_braking = true
			target_speed_mps = 0.0
			speed_feedback = tr("I18N_FULL_BRAKE")
			speed_feedback_seconds = 2.0
			return
	else:
		emergency_braking = false
	var before := target_speed_mps
	speed_strength = VoiceStrength.multiplier(strength)
	var minimum := 0.0 if direction < 0 and target_speed_mps < MIN_SPEED else MIN_SPEED
	target_speed_mps = clampf(target_speed_mps + direction * SPEED_STEP * speed_strength, minimum, MAX_SPEED)
	speed_feedback_seconds = 2.0
	if direction > 0 and strong and boost_cooldown <= 0.0:
		boost_remaining = BOOST_SECONDS
		boost_cooldown = BOOST_COOLDOWN
		speed_feedback = tr("I18N_TURBO_BOOST")
		return
	if is_equal_approx(before, target_speed_mps):
		speed_feedback = tr("I18N_SPEED_MAX") if direction > 0 else tr("I18N_SPEED_MIN")
	else:
		speed_feedback = (tr("I18N_SPEED_FASTER") if direction > 0 else tr("I18N_SPEED_SLOWER")) % roundi(target_speed_mps * 3.6)

func keyboard_speed(direction: int, delta: float) -> void:
	if direction not in [-1, 1] or delta <= 0.0 or off_road or finished: return
	speed_strength = 1.0
	if direction > 0:
		emergency_braking = false
		target_speed_mps = minf(MAX_SPEED, maxf(target_speed_mps, speed_mps) + 10.0 * delta)
	else:
		boost_remaining = 0.0
		if emergency_braking: return
		# Brake now, even when the previous voice target was much higher.
		target_speed_mps = maxf(0.0, minf(target_speed_mps, speed_mps) - 18.0 * delta)
	speed_feedback_seconds = 0.0

func effective_target_speed() -> float:
	return minf(MAX_SPEED + BOOST_BONUS, target_speed_mps + BOOST_BONUS) if boost_remaining > 0.0 else target_speed_mps

func step(delta: float) -> void:
	if off_road or finished:
		return
	_refresh_assist()
	elapsed_s += delta
	speed_feedback_seconds = maxf(0.0, speed_feedback_seconds - delta)
	boost_remaining = maxf(0.0, boost_remaining - delta)
	boost_cooldown = maxf(0.0, boost_cooldown - delta)
	var desired_speed := effective_target_speed()
	var was_assisting := assist_speed_active
	assist_speed_active = recovery_remaining > 0.0 and active_curve_id >= 0
	assist_reason = "late_turn" if assist_speed_active else ""
	assist_target_mps = minf(desired_speed, CRUISE_SPEED * 0.45) if assist_speed_active else desired_speed
	if assist_speed_active: desired_speed = assist_target_mps
	if assist_speed_active != was_assisting: _emit_assist("speed_help" if assist_speed_active else "speed_help_end", assist_reason)
	recovery_remaining = maxf(0.0,recovery_remaining-delta)
	if not assist_speed_active: motion = "normal"
	var rate := BOOST_ACCEL if boost_remaining > 0.0 else (18.0 if desired_speed < speed_mps else 10.0) * speed_strength
	if emergency_braking: rate = FULL_BRAKE_DECEL
	if assist_speed_active: rate = assist_profile.max_assist_brake_mps2
	# Brakes act on the road. Preserve forward motion until the landing.
	if desired_speed >= speed_mps or track.jump_at(distance_m).is_empty():
		speed_mps = move_toward(speed_mps, desired_speed, rate * delta)
	steering_input = move_toward(steering_input, 0.0, delta * 2.2)
	var rolling_steer := clampf(speed_mps / MIN_SPEED, 0.0, 1.0)
	correction_remaining = maxf(0.0, correction_remaining - delta)
	landing_pulse = maxf(0.0, landing_pulse - delta * 3.0)
	if jump_assist_until > distance_m:
		var target: Dictionary = track.sample(distance_m + 10.0)
		var offset: Vector3 = target.position - position
		var desired := atan2(offset.x, -offset.z)
		var exit_blend := clampf((distance_m - jump_assist_until + 8.0) / 8.0, 0.0, 1.0)
		desired = lerp_angle(desired, target.heading, exit_blend)
		# Scale the lateral correction around the road direction.
		desired = lerp_angle(target.heading, desired, turn_strength)
		heading = rotate_toward(heading, desired, deg_to_rad(65.0) * turn_strength * rolling_steer * delta)
	elif active_curve_id >= 0:
		var curve: Dictionary = track.curves[active_curve_id]
		if distance_m >= curve.start_m:
			var target_s: float = minf(distance_m + 4.0, curve.end_m)
			var target: Dictionary = track.sample(target_s)
			var entry := smoothstep(curve.start_m, curve.start_m + 14.0, target_s)
			var exit := 1.0 - smoothstep(curve.end_m - 20.0, curve.end_m, target_s)
			var edge := 0.35 + clampf((speed_mps - 28.0) / 30.0,0.0,1.0) * 0.55
			var requested_offset: float = -float(curve.turn_sign) * edge * entry * exit
			guide_offset = move_toward(guide_offset, requested_offset, 3.5 * delta)
			var offset: Vector3 = target.position + track.right(target.heading) * guide_offset - position
			var desired := atan2(offset.x,-offset.z)
			var exit_blend := clampf((distance_m - float(curve.end_m) + 8.0) / 6.0,0.0,1.0)
			desired = lerp_angle(desired,track.sample(curve.end_m).heading,exit_blend)
			heading = rotate_toward(heading,desired,assist_profile.max_turn_rate_rad_s * rolling_steer * delta)
	position += track.forward(heading) * speed_mps * delta
	var projection: Dictionary = track.project(position, distance_m)
	distance_m = projection.distance_m
	lateral = projection.lateral
	var was_airborne := airborne
	airborne = not track.jump_at(distance_m).is_empty()
	bank = track.bank_at(distance_m)
	position.y = track.flight_height(distance_m) + lateral * tan(bank)
	# Follow the surface in the actual direction of travel, including banking.
	var ahead: Dictionary = track.project(position + track.forward(heading) * 0.4, distance_m)
	var ahead_height: float = track.flight_height(ahead.distance_m) + ahead.lateral * tan(ahead.bank)
	pitch = atan2(ahead_height - position.y, 0.4)
	if was_airborne and not airborne: landing_pulse = 1.0
	var drift_target := 0.0
	if active_curve_id >= 0 and not airborne and speed_mps > 26.0:
		var curve: Dictionary = track.curves[active_curve_id]
		var blend := smoothstep(curve.start_m, curve.start_m + 10.0, distance_m) * (1.0 - smoothstep(curve.end_m - 12.0, curve.end_m, distance_m))
		drift_target = -float(curve.turn_sign) * deg_to_rad(20.0) * clampf((speed_mps - 26.0) / 20.0, 0.0, 1.0) * blend
	drift_angle = lerpf(drift_angle, drift_target, 1.0 - exp(-6.0 * delta))
	# No horizontal snap or lane clamp: a missed turn really leaves the deck.
	if absf(lateral) > 3.2 or projection.gap > 3.2:
		off_road = true
	if distance_m >= track.length_m - 0.5 and absf(lateral) <= 2.2:
		finished = true
