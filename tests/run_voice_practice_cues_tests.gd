extends SceneTree
const Practice = preload("res://scripts/input/voice_practice.gd")
const PracticePanel = preload("res://scripts/ui/voice_practice_panel.gd")
const Router = preload("res://scripts/input/command_router.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Track = preload("res://scripts/track/track_data.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var session = Router.new(Drive.new(Track.new()))
	var panel = PracticePanel.new()
	root.add_child(panel)
	panel.render(session, true, "")
	check(not panel.prompt.visible, "Vor dem Start erscheint keine verfrühte Sprechaufforderung.")
	session.practice.start("direct")
	session.practice.step(0.2, true)
	panel.render(session, true, "")
	check(panel.prompt.visible and panel.prompt.text.to_lower() == "left", "Der erste Versuch zeigt nur das gefragte Wort.")
	check(not panel.score.visible and not panel.counts.visible, "Die laufende Übung zeigt keine ausführliche Statistik.")
	session.practice.receive("left")
	check(session.practice.phase == "transition", "Jeder Treffer beginnt eine sichtbare Pause, auch das erste left.")
	check(not session.practice.receive("left") and session.practice.attempted == 1, "Ein weiterer Befehl in der Pause zählt nicht als neuer Versuch.")
	session.practice.step(0.3, true)
	panel.render(session, true, "")
	check(panel.prompt.modulate.a < 0.05, "Das Wort verschwindet vor dem nächsten Versuch vollständig.")
	session.practice.step(1.0, true)
	session.practice.step(0.2, true)
	panel.render(session, true, "")
	check(panel.prompt.visible and panel.prompt.modulate.a > 0.9, "Das wiederholte left erscheint als neue Aufforderung.")
	# Eine echte Containerberechnung prüft die räumliche Zuordnung der Aufforderungen.
	for word in ["left", "left", "right", "right", "right", "faster", "faster", "faster", "slower", "slower", "slower"]:
		session.practice.step(1.0, true)
		panel.render(session, true, "")
		await process_frame
		var target: Rect2 = panel.prompt.get_global_rect()
		var cross: Rect2 = panel.compass.get_global_rect()
		match word:
			"left": check(target.end.x <= cross.position.x, "Left steht am linken Pfeil.")
			"right": check(target.position.x >= cross.end.x, "Right steht am rechten Pfeil.")
			"faster": check(target.end.y <= cross.position.y and panel.prompt.text.to_lower() == "faster", "Faster steht am oberen Pfeil.")
			"slower": check(target.position.y >= cross.end.y and panel.prompt.text.to_lower() == "slower", "Slower steht am unteren Pfeil.")
		session.practice.receive(word)
	session.practice.step(0.3, true)
	panel.render(session, true, "")
	check(session.practice.phase == "transition" and panel.feedback.visible and panel.prompt.modulate.a < 0.05, "Auch der letzte Versuch zeigt die kurze Rückmeldung und blendet das Wort aus.")
	session.practice.step(1.0, true)
	panel.render(session, true, "")
	check(session.practice.correct == 12 and panel.score.visible and not panel.prompt.visible, "Die Trefferzahl erscheint am Ende ohne weitere Sprechaufforderung.")
	panel.free()
	print("KLARE SPRACHÜBUNG: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
