extends RefCounted
const GRAVITY:=Vector3(0,-9.81,0)
static func step(track,state,controls:Dictionary,assistance:Dictionary,dt:float)->Dictionary:
	var result:={"remaining_s":0.0,"hold_used":0.0,"normal_accel":0.0}
	if dt<=0 or state.mode!="grounded":return result
	var e:Dictionary=track.by_id[state.element_id]
	var frame:Dictionary=track.sample_element(state.element_id,state.local_m)
	var forward:Vector3=-frame.basis.z
	var speed:=maxf(0,state.velocity.dot(forward))
	var before:Dictionary=track.sample_element(e.id,maxf(0,state.local_m-0.2))
	var after:Dictionary=track.sample_element(e.id,minf(e.length_m,state.local_m+0.2))
	var span:float=maxf(after.local_m-before.local_m,0.00001)
	var curvature:Vector3=(-after.basis.z+before.basis.z)/span
	var normal:float=speed*speed*curvature.dot(frame.basis.y)-GRAVITY.dot(frame.basis.y)
	result.normal_accel=normal
	if absf(state.lateral_m)>3.0:
		state.mode="crashed";return result
	if normal < -float(assistance.get("hold_mps2",0)):
		state.mode="airborne";result.remaining_s=dt;return result
	result.hold_used=maxf(0,-normal)
	var target:float=assistance.get("target_speed_mps",controls.get("target_speed_mps",speed))
	var cap:float=assistance.get("accel_cap_mps2",10) if target>=speed else assistance.get("brake_cap_mps2",18)
	var drive:float=clampf((target-speed)/dt,-cap,cap)
	var acceleration:float=drive+GRAVITY.dot(forward)
	var end_speed:=clampf(speed+acceleration*dt,0,58)
	var movement:float=(speed+end_speed)*0.5*dt
	var used:=dt
	if movement>e.length_m-state.local_m and movement>0.000001:
		used=dt*(e.length_m-state.local_m)/movement
		end_speed=clampf(speed+acceleration*used,0,58)
		movement=e.length_m-state.local_m
		result.remaining_s=dt-used
	var side_acceleration:float=GRAVITY.dot(frame.basis.x)-speed*speed*curvature.dot(frame.basis.x)
	if controls.get("turn_authorized",false) or e.input.kind=="none":
		side_acceleration=clampf(-state.lateral_m*12.0-state.lateral_speed*6.0,-80,80)
	state.lateral_speed+=side_acceleration*used
	state.lateral_m+=state.lateral_speed*used
	state.local_m+=movement;state.distance_m=e.start_m+state.local_m
	var next:Dictionary=track.sample_element(e.id,state.local_m)
	state.position=track.surface_point(e.id,state.local_m,state.lateral_m)
	state.basis=next.basis
	state.velocity=-next.basis.z*end_speed+next.basis.x*state.lateral_speed
	if absf(state.lateral_m)>3.0:state.mode="crashed";return result
	if state.local_m>=e.length_m-0.000001:
		if not track.landing_candidates(e.id).is_empty():state.mode="airborne"
		elif e.index+1>=track.elements.size():state.mode="finished"
		else:
			var neighbor:Dictionary=track.elements[e.index+1]
			state.element_id=neighbor.id;state.local_m=0;state.distance_m=neighbor.start_m
	return result
