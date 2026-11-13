extends SceneTree
# Prints a design report for one spatial track: its elements, where the road comes
# close to itself, the speed windows and three test laps per assist level.
# It fails when the road comes close to itself, a stunt has no passing speed, or a lap
# at the normal speed does not finish.
#
# godot --headless --path . --script tools/spatial/inspect_track.gd -- --track res://tracks/<file>.json
const Factory = preload("res://scripts/track/track_factory.gd")
const Drive = preload("res://scripts/vehicle/spatial_drive_model.gd")
const Runner = preload("res://scripts/vehicle/spatial/drive_runner.gd")
const Assist = preload("res://scripts/vehicle/spatial/stunt_assist.gd")
const Windows = preload("res://tools/spatial/speed_windows.gd")
# A voice player needs about this long from the hint to the recognized word.
const SLOW_CALL_S := 1.5
const NEAR_M := 9.0
const NEAR_HEIGHT_M := 7.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var path := ""
	for i in range(args.size() - 1):
		if args[i] == "--track": path = args[i + 1]
	var loaded: Dictionary = Factory.load_track(path)
	if not loaded.errors.is_empty():
		printerr(loaded.errors)
		quit(1)
		return
	var track = loaded.track
	print("%s: %.0f m, %d elements, %d curves" % [path.get_file(), track.length_m, track.elements.size(), track.curves.size()])
	for e in track.elements:
		var end: Vector3 = e.points[e.points.size() - 1]
		print("  %-12s %-8s %7.1f m  from %6.1f  ends (%.0f, %.1f, %.0f)" % [e.id, e.kind, e.length_m, e.start_m, end.x, end.y, end.z])
	var passed := true
	for issue in near_misses(track):
		print("  CLOSE: %s" % issue)
		passed = false
	for level in ["very_easy", "easy"]:
		var windows: Dictionary = Windows.compute(track, Assist.profile(level))
		for id in windows:
			var w: Dictionary = windows[id]
			if track.by_id[id].kind == "curve" and w.passes: continue
			print("  %s %s %s: %s, target %.1f m/s" % [level, id, track.by_id[id].kind, "%.1f-%.1f m/s" % [w.min_mps, w.max_mps] if w.passes else "NO PASSING SPEED", w.target_mps])
			passed = passed and w.passes
		for case in [["instant calls", 0.0, 22.0], ["slow calls", SLOW_CALL_S, 22.0], ["slow calls, fast", SLOW_CALL_S, 30.0]]:
			var lap := drive(track, level, case[1], case[2])
			print("  %s, %s: %s at %s after %.1f s, %d late calls, %d flights" % [level, case[0], lap.mode, lap.element, lap.seconds, lap.late, lap.flights])
			# The fast lap only shows how the track punishes too much speed.
			if case[2] <= 22.0: passed = passed and lap.mode == "finished"
	quit(0 if passed else 1)

# One lap with every curve called `delay_s` after its hint opens.
static func drive(track, level: String, delay_s: float, target_mps: float) -> Dictionary:
	var model = Drive.new(track)
	model.set_assist_level(level)
	model.target_speed_mps = target_mps
	var controls: Dictionary = Runner.create_controls(model)
	var opened := {}
	var called := {}
	var late := 0
	var flights := 0
	for tick in range(36000):
		model.refresh_assist()
		var hint: Dictionary = model.assist_state()
		if hint.phase != "closed" and not opened.has(hint.opportunity_id): opened[hint.opportunity_id] = tick
		if opened.has(hint.opportunity_id) and not called.has(hint.opportunity_id) and tick - opened[hint.opportunity_id] >= int(delay_s * 60.0) and hint.phase in ["early", "clean", "late", "rescue"]:
			called[hint.opportunity_id] = true
			if hint.phase in ["late", "rescue"]: late += 1
			Runner.apply_input(model, {"tick": tick, "kind": "turn", "value": hint.turn_sign, "event_id": "turn:%d" % hint.opportunity_id}, controls)
		Runner.step_controls(controls, tick)
		model.step(1.0 / 60.0)
		for event in model.take_motion_events():
			if event.type == "contact_lost": flights += 1
		if model.finished or model.off_road: break
	return {"mode": model.state.mode, "element": model.state.element_id, "seconds": model.elapsed_s, "late": late, "flights": flights}

# Places where two parts of the road that are far apart along the lap come close in space.
static func near_misses(track) -> Array[String]:
	var samples: Array[Dictionary] = []
	var d := 0.0
	while d < track.length_m:
		samples.append(track.sample(d))
		d += 4.0
	var result: Array[String] = []
	var reported := {}
	for i in range(samples.size()):
		for j in range(i + 1, samples.size()):
			var along: float = samples[j].distance_m - samples[i].distance_m
			if minf(along, track.length_m - along) < 60.0: continue
			var a: Vector3 = samples[i].position
			var b: Vector3 = samples[j].position
			if absf(a.y - b.y) > NEAR_HEIGHT_M or Vector2(a.x - b.x, a.z - b.z).length() > NEAR_M: continue
			var key := "%s/%s" % [samples[i].element_id, samples[j].element_id]
			if samples[i].element_id == samples[j].element_id or reported.has(key): continue
			reported[key] = true
			result.append("%s at %.0f m and %s at %.0f m" % [samples[i].element_id, samples[i].distance_m, samples[j].element_id, samples[j].distance_m])
	return result
