extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
const Profile = preload("res://scripts/vehicle/assist_profile.gd")
const DT := 1.0/60.0
var failures := 0
var results: Array[Dictionary] = []
func run_drive(track, level: String, hint: float, speed: float, timing: String, throttle: String = "fixed") -> void:
	var d = Drive.new(track);d.set_assist_level(level);d.hint_seconds=hint;d.speed_mps=speed;d.target_speed_mps=speed
	var sent := {};var events: Array[Dictionary] = [];var gap := 3.2;var stopped := false
	if speed == 0:
		var initial: Vector3 = d.position
		for i in range(30):d.step(DT)
		stopped = d.position.is_equal_approx(initial)
		d.change_speed(1)
	for frame in range(18000):
		d.refresh_assist()
		var curve: Dictionary = d.track.next_curve(d.distance_m)
		if d.active_curve_id < 0 and not curve.is_empty() and not sent.has(curve.id):
			var state: Dictionary = d.assist_state()
			var ready: bool = state.phase in ["early","clean"] if timing == "early" else (state.phase == timing if timing in ["late", "rescue"] else d.distance_m >= curve.start_m-20.0)
			if ready:
				var accepted: bool = d.request_assisted_turn(-curve.turn_sign if level == "very_easy" else curve.turn_sign,false,"input:%d"%curve.id)
				sent[curve.id]=true
				events.append({"curve":curve.id,"at_m":d.distance_m,"time_s":d.elapsed_s,"lateral":d.lateral,"heading":d.heading,"phase":state.phase,"accepted":accepted})
		if d.active_curve_id >= 0:
			if throttle == "gas": d.keyboard_speed(1,DT)
			elif throttle == "alternate": d.keyboard_speed(1 if frame%120 < 90 else -1,DT)
			elif throttle == "brake" and frame%180==0: d.change_speed(-1,0.9)
			elif throttle == "brake" and d.speed_mps == 0:d.change_speed(1,0.9)
		d.step(DT);gap=minf(gap,3.2-absf(d.lateral))
		if d.off_road or d.finished: break
	var passed: bool = d.finished and not d.off_road and (speed != 0 or stopped) and events.size()==track.curves.size()
	if not passed:
		failures+=1
		print("Fahrt fehlgeschlagen: %s %s %.0f %.0f %s %s bei%.2f lateral%.2f"%[track.source_path,level,hint,speed,timing,throttle,d.distance_m,d.lateral])
	results.append({"track":track.source_path,"level":level,"hint_s":hint,"initial_speed_mps":speed,"initial_position_m":0,"timing":timing,"throttle":throttle,"passed":passed,"minimum_edge_margin_m":gap,"end_m":d.distance_m,"seconds":d.elapsed_s,"extra_turn_inputs":0,"inputs":events})
func _initialize() -> void:
	for route in preload("res://tests/helpers/legacy_routes.gd").catalog():
		var track = Track.new(route.path)
		for level in ["very_easy","easy"]:
			for hint in [3.0,5.0,8.0]:
				for speed in [0.,5.,10.,14.,15.,20.,22.,25.,28.,30.,35.,40.,45.,46.,50.,55.,58.]:
					run_drive(track,level,hint,speed,"clean")
			for timing in ["early","late","rescue"]:
				for speed in [14.,22.,46.,58.]:run_drive(track,level,5.,speed,timing)
			for throttle in ["gas","brake","alternate"]: run_drive(track,level,5.,22.,"clean",throttle)
		print("Geprueft: "+route.path)
	var revision: Array = [];OS.execute("git",["rev-parse","HEAD"],revision)
	var report := {"source_base":str(revision[0]).strip_edges(),"source_state":"working_tree","profile":Profile.for_id("very_easy"),"step_s":DT,"runs":results.size(),"failures":failures,"limits":["Discrete samples, no proof for every possible input.","No human microphone trial.","Jumps use the existing position-based path.","Artificial boundary states have a separate test."],"results":results}
	var hashes := {}
	for path in ["res://scripts/vehicle/drive_model.gd","res://scripts/vehicle/curve_assist.gd","res://scripts/vehicle/assist_profile.gd","res://scripts/track/track_data.gd"]:
		hashes[path] = FileAccess.get_sha256(path)
	for route in preload("res://tests/helpers/legacy_routes.gd").catalog(): hashes[route.path] = FileAccess.get_sha256(route.path)
	report["source_sha256"] = hashes
	var output := "/private/tmp/stuntcar-legacy-matrix.json"
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()-1):
		if args[i]=="--output": output=args[i+1]
	var file := FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t")+"\n")
	print("STRECKENMATRIX: %d Fahrten, %d Fehler"%[results.size(),failures]);quit(0 if failures==0 else 1)
