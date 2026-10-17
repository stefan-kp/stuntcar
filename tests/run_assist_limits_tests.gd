extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1;push_error(message)
func _initialize() -> void:
	for level in ["very_easy","easy"]:
		var d = Drive.new(Track.new());d.set_assist_level(level);d.reset(95)
		d.speed_mps=0;d.target_speed_mps=22;d.request_turn(1)
		d.step(1.0/60.0)
		check(d.speed_mps <= d.assist_profile.max_assist_accel_mps2/60.0 + 0.00001, "Die Rettung ueberschreitet ihre Beschleunigungsgrenze nicht.")
		d.reset(95);d.speed_mps=58;d.target_speed_mps=58;d.request_turn(1)
		d.step(1.0/60.0)
		check(58-d.speed_mps <= d.assist_profile.max_assist_brake_mps2/60.0 + 0.00001, "Die Rettung ueberschreitet ihre Bremsgrenze nicht.")
	print("HILFSKRAEFTE: %d Fehler" % failures);quit(0 if failures==0 else 1)
