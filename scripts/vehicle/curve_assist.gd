extends RefCounted
var data: Dictionary
var profile: Dictionary
var seen: Dictionary = {}
var serial := 0
var attempt := 0
var reference_speed := 22.0
func _init() -> void: reset(0)
func reset(attempt_id: int) -> void:
	attempt = attempt_id
	serial = 0
	seen.clear()
	data = {"curve_id":-1,"opportunity_id":-1,"phase":"closed","authorized":false,"turn_sign":0,
		"opened_at_s":-1.0,"expires_at_s":-1.0,"accepted_phase":"","closed_reason":"reset"}
func close(reason: String) -> void:
	data.authorized = false
	data.phase = "closed"
	data.closed_reason = reason
func update(curve: Dictionary, state: Dictionary, selected: Dictionary) -> void:
	profile = selected
	if state.off_road or state.finished:
		close("missed")
		return
	if curve.is_empty():
		close("completed")
		return
	if curve.id != data.curve_id:
		serial += 1
		data = {"curve_id":curve.id,"opportunity_id":attempt * 10000 + serial,"phase":"closed","authorized":false,
			"turn_sign":curve.turn_sign,"opened_at_s":-1.0,"expires_at_s":-1.0,"accepted_phase":"","closed_reason":"not_open"}
	if data.authorized:
		if state.distance_m >= curve.end_m + profile.exit_distance_m: close("completed")
		return
	if state.distance_m >= curve.end_m:
		close("completed")
		return
	if data.closed_reason not in ["not_open", ""]: return
	if data.opened_at_s < 0.0:
		reference_speed = maxf(22.0, maxf(state.speed_mps, state.target_speed_mps))
		if state.distance_m < curve.start_m - reference_speed * state.hint_seconds: return
		data.opened_at_s = state.elapsed_s
		data.expires_at_s = state.elapsed_s + maxf(10.0, 2.0 * state.hint_seconds * reference_speed / maxf(5.0, maxf(state.speed_mps, state.target_speed_mps)))
		data.closed_reason = ""
	if state.elapsed_s >= data.expires_at_s:
		close("expired")
		return
	if absf(state.lateral) >= profile.accept_lateral_m or state.gap >= profile.accept_lateral_m or absf(state.heading_error_rad) >= profile.accept_heading_rad:
		close("outside_support")
		return
	var phase := "early"
	if state.distance_m >= curve.start_m:
		phase = "rescue" if absf(state.lateral) >= profile.late_lateral_m else "late"
	elif state.distance_m >= curve.start_m - reference_speed: phase = "clean"
	var order := ["closed","early","clean","late","rescue"]
	if order.find(phase) > order.find(data.phase): data.phase = phase
func request(direction: int, unknown_call: bool, event_id: String) -> bool:
	if event_id.is_empty() or seen.has(event_id) or seen.size() >= 4096: return false
	seen[event_id] = true
	if data.phase == "closed": return false
	if unknown_call:
		if profile.id != "very_easy": return false
	elif direction not in [-1,1] or (profile.id == "easy" and direction != data.turn_sign): return false
	if not data.authorized:
		data.accepted_phase = data.phase
		data.authorized = true
		data.phase = "active"
	return true
func snapshot() -> Dictionary: return data.duplicate()
