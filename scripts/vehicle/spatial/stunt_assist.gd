extends RefCounted
static func profile(id:String)->Dictionary:
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://scripts/vehicle/spatial/profiles.json"))
	if not data is Dictionary or id not in ["very_easy","easy"] or not data.get(id) is Dictionary:return {}
	var p:Dictionary=data[id]
	for key in ["version","accel_mps2","brake_mps2","max_mps","assist_accel_mps2","assist_brake_mps2","hold_mps2","help_seconds","thrust_mps2","thrust_seconds"]:
		var v=p.get(key)
		if typeof(v) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(v)) or v<=0:return {}
	return p
static func limits(element:Dictionary)->Dictionary:
	var defaults:={"hill":[0.0,12.0,11.0],"curve":[0.0,30.0,22.0],"bank":[0.0,30.0,22.0],"launch":[19.0,21.0,20.0],"loop":[24.0,32.0,26.0]}
	if not defaults.has(element.kind):return {}
	var v:Array=defaults[element.kind]
	return element.assist if not element.assist.is_empty() else {"min_mps":v[0],"max_mps":v[1],"target_mps":v[2],"approach_m":60.0}
static func evaluate(track,state,profile:Dictionary,requested:float)->Dictionary:
	if profile.is_empty():return {"active":false,"remaining_s":0.0,"invalid":true}
	var result:={"active":false,"target_speed_mps":requested,"accel_cap_mps2":profile.accel_mps2,"brake_cap_mps2":profile.brake_mps2,"hold_mps2":0.0,"thrust_world_mps2":Vector3.ZERO,"remaining_s":0.0,"element_id":state.element_id}
	if state.mode in ["crashed","finished"]:return result
	for e in track.elements:
		if e.end_m<state.distance_m-0.00001:continue
		var range:Dictionary=limits(e)
		if range.is_empty():continue
		if e.start_m-state.distance_m>float(range.approach_m):return result
		var remaining:float=maxf(0,profile.help_seconds-float(state.help_used.get(e.id,0)))
		result.element_id=e.id;result.remaining_s=remaining
		if remaining<=0:return result
		var target:=requested
		if requested<range.min_mps or requested>range.max_mps:target=range.target_mps
		result.target_speed_mps=target
		result.active=not is_equal_approx(target,requested)
		if result.active:
			result.accel_cap_mps2=profile.assist_accel_mps2;result.brake_cap_mps2=profile.assist_brake_mps2
		if e.id==state.element_id:result.hold_mps2=profile.hold_mps2
		return result
	return result
