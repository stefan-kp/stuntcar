extends RefCounted
# Endliche Spielparameter, keine physikalischen Sprunggrenzen.
const VERSION := 2
static func for_id(id: String) -> Dictionary:
	return {"id":id if id in ["very_easy", "easy"] else "very_easy", "version":VERSION,
		"late_lateral_m":0.75,"accept_lateral_m":2.4,"accept_heading_rad":deg_to_rad(20.0),
		"manual_turn_rate_rad_s":deg_to_rad(65.0),"exit_distance_m":16.0,"sway_limit_m":1.8,"max_turn_rate_rad_s":deg_to_rad(360.0),
		"max_assist_accel_mps2":32.0,"max_assist_brake_mps2":120.0,"recovery_seconds":1.5}
static func validate(profile: Dictionary) -> String:
	if profile.get("id", "") not in ["very_easy", "easy"]: return "invalid_id"
	for key in for_id("very_easy"):
		if key == "id": continue
		var value = profile.get(key)
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or value <= 0: return "invalid_" + key
	if profile.late_lateral_m >= profile.accept_lateral_m or profile.sway_limit_m >= profile.accept_lateral_m: return "invalid_bounds"
	return ""
