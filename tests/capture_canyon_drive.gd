extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/canyon-drive-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.select_track("res://tracks/05_canyon_study.json")
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	scene.session.voice_enabled = false
	scene.model.reset(0)
	scene.car.place(scene.model)
	scene.camera.initialized = false
	var sent := {}
	var times: Array[float] = []
	var peak_primitives := 0
	var peak_draws := 0
	for frame in range(600):
		var start := Time.get_ticks_usec()
		scene.session.state = "RUNNING"
		if frame >= 60:
			for curve in scene.track.curves:
				if scene.model.distance_m > curve.start_m-28 and not sent.has(curve.id):
					scene.model.request_turn(curve.turn_sign)
					sent[curve.id] = true
			scene.model.step(1.0/30.0)
			scene.car.drive(scene.model,1.0/30.0)
		scene._process(1.0/30.0)
		scene.ui.visible = false
		await process_frame
		if frame >= 60:
			times.append(float(Time.get_ticks_usec()-start)/1000.0)
			peak_primitives = maxi(peak_primitives,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
			peak_draws = maxi(peak_draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		if scene.model.finished or scene.model.off_road: break
	var total := 0.0
	for t in times: total += t
	times.sort()
	var report := {"resolution":"1280x800","adapter":RenderingServer.get_video_adapter_name(),
		"finished":scene.model.finished,"off_road":scene.model.off_road,"frames":times.size(),
		"mean_ms":total/times.size(),"p95_ms":times[int(times.size()*.95)],
		"peak_primitives":peak_primitives,"peak_draws":peak_draws,
		"note":"Automatische Fahrt mit 30 Simulationsschritten pro Sekunde. 60 Bilder Vorlauf. Bildausgabe mit aktiver vertikaler Synchronisation. Bei Filmaufnahme enthält die Messung auch die Aufnahmezeit."}
	print(JSON.stringify(report))
	FileAccess.open("/tmp/canyon-drive-metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	var passed: bool = scene.model.finished and not scene.model.off_road
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit(0 if passed else 1)
