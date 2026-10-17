extends SceneTree
const Factory=preload("res://scripts/track/track_factory.gd")
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
const Runner=preload("res://scripts/vehicle/spatial/drive_runner.gd")
const Assist=preload("res://scripts/vehicle/spatial/stunt_assist.gd")
const Verification=preload("res://scripts/track/spatial/verification.gd")
func _initialize()->void:
	var args:=OS.get_cmdline_user_args();var path:="res://tracks/06_stuntlabor.json";var output:="user://stunt-report.json"
	for i in range(args.size()-1):
		if args[i]=="--track":path=args[i+1]
		if args[i]=="--output":output=args[i+1]
	var loaded:Dictionary=Factory.load_track(path)
	if not loaded.errors.is_empty():printerr(loaded.errors);quit(1);return
	var track=loaded.track;var profiles:Dictionary={};var passed:=true
	for id in ["very_easy","easy"]:
		var profile:=Assist.profile(id);var model=Drive.new(track);model.set_assist_level(id);model.reset(5.0)
		var controls:Dictionary=Runner.create_controls(model)
		var inputs:Array[Dictionary]=[];var samples:Array[Dictionary]=[];var seen:Dictionary={}
		for tick in range(18000):
			model.refresh_assist();var hint:Dictionary=model.assist_state()
			if hint.phase in ["early","clean"]:
				var event:={"tick":tick,"kind":"turn","value":hint.turn_sign,"event_id":"turn:%d"%hint.opportunity_id}
				Runner.apply_input(model,event,controls)
			var e:Dictionary=track.by_id[model.state.element_id]
			var limits:Dictionary=Assist.limits(e)
			if not seen.has(e.id) and not limits.is_empty():
				seen[e.id]=true;samples.append({"condition":Verification.condition(model),"element_id":e.id,"speed_mps":model.speed_mps,"lateral_m":model.lateral,"mode":model.state.mode,"min_mps":null,"max_mps":null,"target_mps":limits.target_mps})
			Runner.step_controls(controls,tick)
			model.step(1.0/60.0);model.take_motion_events()
			if model.state.mode in ["finished","crashed"]:break
		inputs.assign(controls.recorded)
		var result:Dictionary=Runner.run(track,profile,inputs,18000,{"distance_m":5.0})
		result.erase("trace")
		profiles[id]={"digest":Verification.digest(track,profile),"status":"tested_samples","clean_completed":result.finished,"samples":samples,"clean_run":result}
		passed=passed and result.finished
		print("%s: %s at %.2f m, %.2f s"%[id,result.mode,result.final.distance_m,result.seconds])
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file==null:printerr("Cannot write report");quit(1);return
	file.store_string(JSON.stringify({"version":1,"profiles":profiles,"limits":["Discrete samples only; no continuous speed envelope proven.","No human microphone or comfort trial."]},"\t",true,true)+"\n")
	quit(0 if passed else 1)
