extends SceneTree
const TestVoice = preload("res://tests/helpers/practice_voice_bridge.gd")
var failures := 0
var checks := 0
var sequence := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func sample(scene, rms: float) -> void:
	sequence += 1
	scene.voice.accept_packet({"type":"feedback","seq":sequence,"epoch":scene.voice.epoch,"state":"listening","rms":rms,"peak_rms":rms,"level":0.0,"sample_seconds":0.1})
	scene._physics_process(0.1)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/call-practice-%d.cfg" % OS.get_process_id()
	root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
	scene.voice.free();scene.voice = TestVoice.new();scene.add_child(scene.voice)
	scene.session.open_settings();scene.session.activate(7)
	check(scene.session.state == "CALL_PRACTICE", "Die Rufuebung hat einen eigenen Ablauf.")
	if scene.session.state != "CALL_PRACTICE": scene.free();quit(1);return
	scene.voice.device_name = "Quiet test"
	scene.session.activate(0);scene.sync_voice_context()
	for i in range(20): sample(scene, 10.0)
	for call in range(3):
		for i in range(4): sample(scene, 45.0)
		for i in range(4): sample(scene, 10.0)
	scene._process(0.01)
	check(scene.session.call_practice.phase == "done", "Drei leise Rufe reichen aus.")
	check(not scene.session.call_profile.is_empty(), "Die Probe speichert das Rufprofil.")
	check(scene.session.practice.calibration.levels.is_empty(), "Eine laute Probe ist nicht erforderlich.")
	check(scene.model.active_curve_id == -1, "Die Probe lenkt nicht.")
	check(scene.ui.call_practice_panel.visible, "Die Rufuebung ist sichtbar.")
	var saved: Dictionary = scene.session.call_profile.duplicate()
	scene.session.activate(0);sample(scene,10.0)
	scene.voice.device_name = "Other device";sample(scene,10.0)
	check(scene.session.call_practice.phase == "ready", "Ein anderes Geraet bricht die Probe ab.")
	scene.session.close_call_practice()
	check(scene.session.call_profile == saved and scene.session.state == "SETTINGS", "Ein Abbruch erhaelt das Profil.")
	scene.ui.render(scene.session)
	for i in range(3): await process_frame
	check(scene.ui.buttons[-1].get_global_rect().end.y < scene.ui.root.size.y - 124, "Alle Einstellungen passen oberhalb der Bedienhinweise.")
	var config := ConfigFile.new();config.load(scene.settings_path)
	check(config.get_value("input","call_profile",{}) == saved, "Das Profil bleibt gespeichert.")
	DirAccess.remove_absolute(scene.settings_path);scene.free()
	print("RUFUEBUNG: %d Bedingungen, %d Fehler" % [checks,failures]);quit(0 if failures == 0 else 1)
