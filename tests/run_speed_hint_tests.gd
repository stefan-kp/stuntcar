extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
var errors := 0
func check(ok: bool, msg: String) -> void:
	if not ok: errors += 1; push_error(msg)
func _initialize() -> void:
	var track = Track.new()
	check(track.has_method("speed_hint_at"), "Die Geschwindigkeitshinweise fehlen.")
	if not track.has_method("speed_hint_at"): quit(1);return
	for route in Track.catalog():
		var t = Track.new(route.path)
		for c in t.curves:
			var hint: Dictionary = t.speed_hint_at(c.start_m)
			if c.has("speed_hint"):
				check(hint.kind == "curve" and hint.max_mps == 58.0 and hint.status == "assisted_tested", "Die Kurve nennt die Grenze mit Hilfe.")
			else:
				check(hint.kind == "curve" and hint.max_mps == null and hint.status == "unverified", "Eine neue Strecke ohne Tempoprüfung erhält keine erfundene Grenze.")
		for j in t.jumps:
			var hint: Dictionary = t.speed_hint_at(j.start_m)
			check(hint.kind == "ramp" and hint.min_mps == null and hint.status == "unverified", "Die feste Sprungbahn hat keine erfundene Mindestgeschwindigkeit.")
	var definition: Dictionary = Track.read_definition(Track.DEFAULT_PATH).data.duplicate(true)
	definition.curves[0].speed_hint.max_mps = -1
	check(not Track.validate_definition(definition).is_empty(), "Eine negative Grenze ist ungueltig.")
	definition.curves[0].speed_hint.max_mps = 20
	definition.curves[0].speed_hint.min_mps = 25
	check(not Track.validate_definition(definition).is_empty(), "Die Mindestgeschwindigkeit darf die Hoechstgeschwindigkeit nicht uebersteigen.")
	definition.curves[0].erase("speed_hint")
	check(Track.validate_definition(definition).is_empty(), "Alte Strecken bleiben lesbar.")
	var drive = load("res://scripts/vehicle/drive_model.gd").new(Track.new())
	drive.track.curves[0].speed_hint.max_mps = 20.0
	drive.track.curves[0].speed_hint.target_mps = 15.0
	drive.reset(70);drive.speed_mps=46;drive.target_speed_mps=46
	drive.request_turn(1);drive.step(1.0/60.0)
	check(drive.assist_speed_active and drive.assist_target_mps == 20 and drive.target_speed_mps == 46, "Die Hilfe nutzt die Kurvengrenze und erhaelt das Spielerziel.")
	print("TEMPOHINWEISE: %d Fehler" % errors);quit(0 if errors == 0 else 1)
