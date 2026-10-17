extends RefCounted
const SOURCES:=["scripts/vehicle/spatial_drive_model.gd","scripts/vehicle/spatial/drive_state.gd","scripts/vehicle/spatial/surface_motion.gd","scripts/vehicle/spatial/flight_motion.gd","scripts/vehicle/spatial/stunt_assist.gd","scripts/vehicle/drive_model.gd","scripts/vehicle/curve_assist.gd","scripts/vehicle/assist_profile.gd","scripts/track/spatial/spatial_track.gd","scripts/track/spatial/surface_query.gd","scripts/track/spatial/track_definition.gd","scripts/track/spatial/form_library.gd"]
static func digest(track,profile:Dictionary)->String:
	var data:Dictionary=track.definition.duplicate(true)
	for key in ["name","description","preview","styles","report"]:data.erase(key)
	for e in data.elements:e.erase("visual_id")
	var forms:Dictionary={}
	for e in data.elements:forms[e.form_id]=track.forms[e.form_id]
	var hashes:Dictionary={}
	for path in SOURCES:hashes[path]=FileAccess.get_sha256("res://"+path)
	return JSON.stringify({"rule_version":2,"dt":1.0/60.0,"definition":data,"forms":forms,"profile":profile,"sources":hashes},"",true,true).sha256_text()
static func speed_hint(report:Dictionary,expected:String,id:String,state:Dictionary)->Dictionary:
	if report.get("digest","")!=expected or report.get("status")!="tested_samples":return {}
	for sample in report.get("samples",[]):
		if not state.has("condition") or sample.get("condition")!=state.condition:continue
		if sample.get("element_id")!=id or sample.get("mode")!=state.get("mode"):continue
		if absf(float(sample.speed_mps)-float(state.get("speed_mps",INF)))>0.0001 or absf(float(sample.lateral_m)-float(state.get("lateral_m",INF)))>0.0001:continue
		return {"version":2,"min_mps":sample.min_mps,"max_mps":sample.max_mps,"target_mps":sample.target_mps,"status":"tested_samples","model":"spatial_v1"}
	return {}
static func read_report(track)->Dictionary:
	var path:String=track.source_path.get_base_dir().path_join(track.definition.report)
	if not FileAccess.file_exists(path):return {}
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}
static func playable(track,profile:Dictionary)->bool:
	var report:=read_report(track)
	var level:Dictionary=report.get("profiles",{}).get(profile.get("id",""),{})
	return level.get("digest","")==digest(track,profile) and level.get("clean_completed",false)==true

static func condition(model)->String:
	var snapshot:Dictionary=model.state.snapshot()
	# Attempt identifiers do not affect movement; input windows and remaining budgets do.
	snapshot.erase("attempt_id")
	var input_state:Dictionary=model.assist_state()
	input_state.erase("opportunity_id")
	return JSON.stringify({"state":snapshot,"curve":model.active_curve_id,"target":model.target_speed_mps,"recovery":model.recovery_remaining,"boost":model.boost_remaining,"curve_assist":input_state},"",true,true).sha256_text()
