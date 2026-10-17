extends RefCounted
const Query=preload("res://scripts/track/spatial/surface_query.gd")
const GRAVITY:=Vector3(0,-9.81,0)
static func step(track,state,assistance:Dictionary,dt:float)->Dictionary:
	var result:={"landed":false,"crashed":false,"impact_mps":0.0,"remaining_s":0.0}
	if dt<=0 or state.mode!="airborne":return result
	var candidates:Array[String]=track.landing_candidates(state.element_id)
	var rules:Dictionary={}
	for l in track.definition.landings:
		if l.launch_id==state.element_id:rules=l;break
	var acceleration:Vector3=GRAVITY+assistance.get("thrust_world_mps2",Vector3.ZERO)
	var remaining:=dt
	while remaining>0.0000001:
		var slice:=minf(remaining,1.0/120.0)
		var next:Vector3=state.position+state.velocity*slice+acceleration*slice*slice*0.5
		var hit:Dictionary=Query.sweep(track,state.position,next,candidates)
		var used:float=slice if hit.is_empty() else slice*hit.fraction
		state.velocity+=acceleration*used
		if state.velocity.length()>0.001:
			var forward:Vector3=state.velocity.normalized()
			var up:Vector3=state.basis.y-forward*state.basis.y.dot(forward)
			if up.length_squared()>0.000001:state.basis=Basis(forward.cross(up).normalized(),up.normalized(),-forward)
		remaining-=used
		if not hit.is_empty():
			state.position=hit.position
			var frame:Dictionary=track.sample_element(hit.element_id,hit.local_m)
			var impact:float=maxf(0,-state.velocity.dot(hit.normal))
			var angle:float=state.basis.get_rotation_quaternion().angle_to(frame.basis.get_rotation_quaternion())
			result.impact_mps=impact;result.remaining_s=remaining
			if impact>float(rules.get("max_impact_mps",0)) or rad_to_deg(angle)>float(rules.get("max_angle_degrees",0)) or state.velocity.dot(-frame.basis.z)<=0:
				state.mode="crashed";result.crashed=true;return result
			state.mode="grounded";state.element_id=hit.element_id;state.local_m=hit.local_m;state.distance_m=frame.distance_m
			state.lateral_m=(state.position-frame.position).dot(frame.basis.x);state.lateral_speed=state.velocity.dot(frame.basis.x)
			state.velocity-=hit.normal*state.velocity.dot(hit.normal);state.basis=frame.basis
			result.landed=true;return result
		state.position=next
		if state.position.y< -5:
			state.mode="crashed";result.crashed=true;return result
	return result
