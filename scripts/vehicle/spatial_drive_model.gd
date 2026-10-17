extends "res://scripts/vehicle/drive_model.gd"
const State=preload("res://scripts/vehicle/spatial/drive_state.gd")
const Surface=preload("res://scripts/vehicle/spatial/surface_motion.gd")
const Flight=preload("res://scripts/vehicle/spatial/flight_motion.gd")
const StuntAssist=preload("res://scripts/vehicle/spatial/stunt_assist.gd")
var hint_report:Dictionary={}
var hint_digest:=""
var state
var motion_events:Array[Dictionary]=[]
var spatial_profile:Dictionary={}
var last_acceleration:=Vector3.ZERO
var actual_boost:=false
var holding:=false
var event_serial:=0
func _init(track_data)->void:
	super(track_data)
	reset()
func reset(checkpoint_m:float=0)->void:
	state=State.new();attempt_id+=1;state.attempt_id=attempt_id
	var f:Dictionary=track.sample(checkpoint_m)
	state.position=f.position;state.basis=f.basis;state.velocity=-f.basis.z*22;state.element_id=f.element_id;state.local_m=f.local_m;state.distance_m=f.distance_m
	active_curve_id=-1;completed_curves=0;completed_ids.clear();last_command=0;input_serial=0
	target_speed_mps=22;boost_remaining=0;boost_cooldown=0;emergency_braking=false;recovery_remaining=0
	curve_assist.reset(attempt_id);assist_events.clear();motion_events.clear();event_serial=0
	actual_boost=false;holding=false;last_acceleration=Vector3.ZERO;rejection_until_s=-1
	set_assist_level(assist_id);sync_fields()
func set_assist_level(id:String)->void:
	super.set_assist_level(id)
	spatial_profile=StuntAssist.profile(assist_id)
	var verification=load("res://scripts/track/spatial/verification.gd")
	hint_digest=verification.digest(track,spatial_profile)
	hint_report=verification.read_report(track).get("profiles",{}).get(assist_id,{})
func sync_fields()->void:
	position=state.position;speed_mps=state.speed_mps;distance_m=state.distance_m;elapsed_s=state.tick/60.0
	lateral=state.lateral_m;airborne=state.mode=="airborne";off_road=state.mode=="crashed";finished=state.mode=="finished"
	var forward:Vector3=-state.basis.z
	heading=atan2(forward.x,-forward.z);pitch=asin(clampf(forward.y,-1,1));bank=state.basis.get_euler().z
	drift_angle=atan2(state.lateral_speed,maxf(speed_mps,0.1))
func refresh_assist()->void:
	if state==null:return
	sync_fields()
	if active_curve_id>=0 and distance_m>=track.curves[active_curve_id].end_m+assist_profile.exit_distance_m:
		completed_ids[active_curve_id]=true;completed_curves+=1;active_curve_id=-1;last_command=0
	var curve:Dictionary={}
	if active_curve_id>=0:curve=track.curves[active_curve_id]
	else:
		for c in track.curves:
			if distance_m<c.end_m:curve=c;break
	var before:Dictionary=curve_assist.snapshot()
	curve_assist.update(curve,{"distance_m":distance_m,"speed_mps":speed_mps,"target_speed_mps":target_speed_mps,"elapsed_s":elapsed_s,"hint_seconds":hint_seconds,"lateral":lateral,"gap":absf(lateral),"heading_error_rad":atan2(state.lateral_speed,maxf(speed_mps,0.1)),"off_road":off_road,"finished":finished},assist_profile)
	var after:Dictionary=curve_assist.snapshot()
	if after.opened_at_s>=0 and (before.opportunity_id!=after.opportunity_id or before.opened_at_s<0):_emit_assist("opened","curve")
	if after.phase=="closed" and before.phase!="closed":_emit_assist("closed",after.closed_reason)
func request_turn(direction:int,_strength:float=VoiceStrength.NORMAL,event_id:String="")->bool:
	if off_road or finished or direction not in [-1,1]:return false
	input_serial+=1
	return request_assisted_turn(direction,false,event_id if not event_id.is_empty() else "key:%d:%d"%[attempt_id,input_serial])
func emit_motion(type:String,magnitude:float=0)->void:
	if motion_events.size()>=128:motion_events.pop_front()
	event_serial+=1
	motion_events.append({"id":"%d:%d:%d"%[attempt_id,state.tick,event_serial],"attempt_id":attempt_id,"tick":state.tick,"element_id":state.element_id,"type":type,"position":state.position,"normal":state.basis.y,"magnitude":magnitude})
func take_motion_events()->Array[Dictionary]:
	var result:=motion_events.duplicate(true);motion_events.clear();return result
func step(delta:float)->void:
	if delta<=0 or state.mode=="finished":return
	if state.mode=="crashed":
		state.velocity+=Surface.GRAVITY*delta;state.position+=state.velocity*delta;state.tick+=1;sync_fields();return
	refresh_assist();state.tick+=1
	boost_remaining=maxf(0,boost_remaining-delta);boost_cooldown=maxf(0,boost_cooldown-delta)
	speed_feedback_seconds=maxf(0,speed_feedback_seconds-delta);landing_pulse=maxf(0,landing_pulse-delta*3)
	var aid:Dictionary=StuntAssist.evaluate(track,state,spatial_profile,effective_target_speed())
	if aid.get("invalid",false):state.mode="crashed";emit_motion("crash");sync_fields();return
	assist_speed_active=aid.active;assist_target_mps=aid.target_speed_mps;assist_reason="stunt_speed" if aid.active else ""
	if recovery_remaining>0:
		aid.target_speed_mps=minf(aid.target_speed_mps,10);aid.brake_cap_mps2=spatial_profile.assist_brake_mps2
		recovery_remaining=maxf(0,recovery_remaining-delta);assist_speed_active=true
	var before_velocity:Vector3=state.velocity
	var remaining:=delta;var iterations:=0;var hold_used:=false;var boosted:=false
	while remaining>0.000001 and iterations<8 and state.mode not in ["crashed","finished"]:
		iterations+=1
		aid=StuntAssist.evaluate(track,state,spatial_profile,effective_target_speed())
		var slice:=remaining
		if aid.remaining_s>0:slice=minf(slice,aid.remaining_s)
		if recovery_remaining>0:
			aid.target_speed_mps=minf(aid.target_speed_mps,10);aid.brake_cap_mps2=spatial_profile.assist_brake_mps2
		var was_mode:String=state.mode
		var outcome:Dictionary
		var slice_boost:=false
		if state.mode=="grounded":
			var current:Dictionary=track.by_id[state.element_id]
			var authorized:bool=current.input.kind=="none" or (active_curve_id>=0 and track.curves[active_curve_id].element_id==current.id)
			outcome=Surface.step(track,state,{"target_speed_mps":effective_target_speed(),"turn_authorized":authorized},aid,slice)
			hold_used=hold_used or outcome.hold_used>0
		else:
			if boost_remaining>0 and state.thrust_used<spatial_profile.thrust_seconds-0.000001:
				slice=minf(slice,spatial_profile.thrust_seconds-state.thrust_used)
				aid.thrust_world_mps2=-state.basis.z*spatial_profile.thrust_mps2
				slice_boost=true;boosted=true
			outcome=Flight.step(track,state,aid,slice)
			if outcome.landed:landing_pulse=1;emit_motion("landing",outcome.impact_mps)
		var used:float=slice-outcome.remaining_s
		if aid.active or outcome.get("hold_used",0)>0:
			state.help_used[aid.element_id]=minf(spatial_profile.help_seconds,float(state.help_used.get(aid.element_id,0))+used)
		if slice_boost:state.thrust_used+=used
		if was_mode=="grounded" and state.mode=="airborne":emit_motion("contact_lost")
		remaining-=used
	if iterations>=8 and remaining>0.000001:state.mode="crashed"
	if state.mode=="crashed":emit_motion("crash")
	if hold_used!=holding:emit_motion("hold_start" if hold_used else "hold_end")
	if boosted!=actual_boost:emit_motion("boost_start" if boosted else "boost_end")
	holding=hold_used;actual_boost=boosted;last_acceleration=(state.velocity-before_velocity)/delta
	sync_fields();refresh_assist()
func feedback_state()->Dictionary:
	var contacts:Array[Vector3]=[]
	if state.mode=="grounded":
		for z in [-1.0,1.0]:
			for x in [-0.85,0.85]:contacts.append(state.position+state.basis*Vector3(x,0,z))
	return {"normal":state.basis.y,"grounded":state.mode=="grounded","accel_local":state.basis.inverse()*last_acceleration,"slip_mps":absf(state.lateral_speed),"braking":last_acceleration.dot(-state.basis.z)<-2,"boosting":actual_boost,"surface_kind":"asphalt","wheel_contacts":contacts,"paused":false}

func verified_speed_hint()->Dictionary:
	var verification=load("res://scripts/track/spatial/verification.gd")
	return verification.speed_hint(hint_report,hint_digest,state.element_id,{"condition":verification.condition(self),"speed_mps":speed_mps,"lateral_m":lateral,"mode":state.mode})
