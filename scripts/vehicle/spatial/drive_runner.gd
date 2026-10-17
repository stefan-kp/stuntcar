extends RefCounted
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
static func apply_input(model,event:Dictionary)->void:
	match event.kind:
		"turn":model.request_turn(int(event.value),0.5,event.event_id)
		"call":model.request_assisted_turn(0,true,event.event_id)
		"faster":model.change_speed(1,float(event.value))
		"slower":model.change_speed(-1,float(event.value))
static func run(track,profile:Dictionary,inputs:Array[Dictionary],max_ticks:int,initial:Dictionary={})->Dictionary:
	var model=Drive.new(track);model.set_assist_level(profile.id);model.spatial_profile=profile.duplicate(true)
	if initial.has("distance_m"):model.reset(initial.distance_m)
	if initial.has("speed_mps"):
		model.state.velocity=-model.state.basis.z*float(initial.speed_mps);model.target_speed_mps=initial.speed_mps;model.sync_fields()
	var start:Dictionary=model.state.snapshot();var events:Array[Dictionary]=[];var trace:Array[Dictionary]=[]
	var held:=0;var by_tick:Dictionary={}
	for event in inputs:
		if not event.has_all(["kind","tick","event_id","value"]) or event.tick<0:return {"error":"invalid_input"}
		if not by_tick.has(int(event.tick)):by_tick[int(event.tick)]=[]
		by_tick[int(event.tick)].append(event)
	for tick in range(max_ticks):
		for event in by_tick.get(tick,[]):
			if event.kind=="held_speed":held=int(event.value)
			else:apply_input(model,event)
		model.keyboard_speed(held,1.0/60.0);model.step(1.0/60.0)
		events.append_array(model.take_motion_events());trace.append(model.state.snapshot())
		if model.state.mode in ["finished","crashed"]:break
	return {"initial":start,"inputs":inputs,"trace":trace,"trace_digest":JSON.stringify(trace,"",true,true).sha256_text(),"events":events,"finished":model.finished,"crashed":model.off_road,"mode":model.state.mode,"seconds":model.elapsed_s,"final":model.state.snapshot(),"help_used":model.state.help_used.duplicate(),"error":""}
