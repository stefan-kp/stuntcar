extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func contains_text(node: Node, text: String) -> bool:
	if node is Label and text in node.text: return true
	for child in node.get_children():
		if contains_text(child, text): return true
	return false

func run() -> void:
	if not ResourceLoader.exists("res://scripts/ui/voice_compass.gd"):
		check(false, "Das Pfeilkreuz fehlt.")
		quit(1)
		return
	var compass = load("res://scripts/ui/voice_compass.gd").new()
	root.add_child(compass)
	compass.set_process(false)
	for item in [["left", 0.2, 1], ["right", 0.5, 2], ["faster", 0.9, 3], ["slower", 0.2, 1]]:
		compass.clear()
		compass.set_input(item[0], item[1])
		check(compass.lit_bars(item[0]) == item[2], "Der Mikrofonpegel füllt die richtige Zahl der Balken.")
		check(not compass.tip_lit(item[0]), "Die Vorschau bestätigt noch keinen ausgeführten Befehl.")
		compass.confirm(item[0], item[1])
		check(compass.tip_lit(item[0]), "Der ausgeführte Befehl beleuchtet die passende Spitze.")
	compass.clear()
	compass.confirm("left", 0.2)
	compass.set_input("left", 0.95)
	check(compass.lit_bars("left") == 1, "Ein neuer Livepegel überdeckt die bestätigte kleine Wirkung nicht.")
	compass.confirm("left", 0.95)
	check(compass.lit_bars("left") == 3, "Erst der bestätigte laute Befehl füllt alle Balken.")
	compass.set_input("right", 0.2)
	compass.confirm("right", 0.2)
	check(compass.lit_bars("left") == 0, "Der Gegenbefehl löscht die vorige Lenkrichtung.")
	check(compass.lit_bars("right") == 1, "Ein leiser Gegenbefehl bleibt klein.")
	compass.set_input("", 0.0)
	compass.advance(1.0)
	check(compass.lit_bars("right") == 0 and not compass.tip_lit("right"), "Die Anzeige klingt nach dem Befehl ab.")
	compass.set_input("unknown", 1.0)
	compass.confirm("pause", 1.0)
	check(compass.lit_bars("left") == 0 and compass.lit_bars("faster") == 0, "Geräusche und Menübefehle füllen keinen Fahrpfeil.")
	compass.confirm("left", 1.0)
	compass.clear()
	check(compass.lit_bars("left") == 0, "Ein Zustandswechsel löscht alle alten Pfeile.")
	compass.free()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/private/tmp/stuntcar-compass-unused.cfg"
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.voice_enabled = true
	scene.session.restart()
	scene.sync_voice_context()
	var voice = scene.voice
	voice.enabled = true
	voice.authenticated = true
	voice.is_ready = true
	voice.last_message_ms = Time.get_ticks_msec()
	voice.accept_packet({"type":"feedback", "seq":1, "epoch":voice.epoch, "heard":"left left left", "direction":"left", "level":0.9, "state":"checking"})
	scene._process(0.016)
	check(scene.ui.get("voice_compass") != null, "Die echte Spielszene enthält das Pfeilkreuz.")
	if scene.ui.get("voice_compass") != null:
		check(scene.ui.voice_compass.visible, "Die Sprachfahrt zeigt das Pfeilkreuz.")
		check(scene.ui.voice_compass.lit_bars("left") == 3, "Die Spielszene zeigt den hohen Mikrofonpegel am linken Pfeil.")
		voice.accept_packet({"type":"command", "seq":2, "epoch":voice.epoch, "command":"left", "text":"left left left", "strength":0.9})
		scene._physics_process(0.016)
		scene._process(0.016)
		check(scene.ui.voice_compass.tip_lit("left"), "Die echte Spielszene bestätigt den ausgeführten Befehl mit der Pfeilspitze.")
		check(contains_text(scene.ui, "left left left") and contains_text(scene.ui, "Curve help: right"), "Die Anzeige trennt das erkannte Wort von der angewendeten Richtung.")
		scene.session.pause()
		scene.sync_voice_context()
		scene._process(0.016)
		check(not scene.ui.voice_compass.visible and scene.ui.voice_compass.lit_bars("left") == 0, "Die Pause entfernt die alte Richtungsanzeige.")
	scene.free()
	print("PFEILKREUZ: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
