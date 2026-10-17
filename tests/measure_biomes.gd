extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,800)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.settings_path = "/tmp/stuntcar-biome-performance-%d.cfg" % OS.get_process_id()
	root.add_child(scene)
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.session.sound_enabled = false
	var results := []
	for route in scene.track.catalog():
		if route.scenario not in ["canyon","alpine"]: continue
		var begin := Time.get_ticks_msec()
		scene.select_track(route.path)
		var build_ms := Time.get_ticks_msec()-begin
		var times: Array[float] = []
		var peak_draws := 0
		var peak_triangles := 0
		for position in range(12):
			scene.model.reset((position+0.5)*scene.track.length_m/12.0)
			scene.car.place(scene.model)
			scene.camera.initialized = false
			for frame in range(90):
				var before := Time.get_ticks_usec()
				scene.session.state = "RUNNING"
				scene._process(1.0/60.0)
				await process_frame
				if frame < 30: continue
				times.append(float(Time.get_ticks_usec()-before)/1000.0)
				peak_draws = maxi(peak_draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
				peak_triangles = maxi(peak_triangles,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		times.sort()
		var total := 0.0
		for t in times: total += t
		var result := {"scenario":route.scenario,"resolution":"1280x800","adapter":RenderingServer.get_video_adapter_name(),
			"renderer":RenderingServer.get_current_rendering_method(),"frames":times.size(),"build_ms":build_ms,
			"mean_ms":total/times.size(),"p95_ms":times[int(times.size()*0.95)],"fps":1000.0/(total/times.size()),
			"peak_draw_calls":peak_draws,"peak_primitives":peak_triangles,
			"note":"Zwölf Positionen je Strecke. Je 30 Bilder Vorlauf und 60 Messbilder. Keine Bildaufnahme während der Messung. Vertikale Synchronisation aktiv."}
		results.append(result)
		print(JSON.stringify(result))
	FileAccess.open("res://docs/landschaften-bildzeiten.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t")+"\n")
	DirAccess.remove_absolute(scene.settings_path)
	scene.free()
	quit()
