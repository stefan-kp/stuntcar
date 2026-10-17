extends RefCounted
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
const Controller=preload("res://addons/accessible_controls/core/controller.gd")
const Source=preload("res://addons/accessible_controls/core/input_source.gd")
const Port=preload("res://scripts/control/stuntcar_port.gd")
const Actions=preload("res://scripts/control/stuntcar_actions.gd")
static func create_controls(model)->Dictionary:
 var port=Port.new(model);port.reset("replay")
 var controller=Controller.new(port,Actions.control_profile(model));controller.begin_session("replay")
 return {"port":port,"controller":controller,"source":Source.new("replay"),"held":0,"pedal_control":"","refreshed_ms":-1,"recorded":[]}
static func submit(controls:Dictionary,intent:Dictionary,tick:int)->void:
 controls.controller.submit(intent)
 controls.recorded.append({"tick":tick,"kind":"intent","value":intent.duplicate(true),"event_id":intent.event_id})
static func apply_input(model,event:Dictionary,controls:Dictionary={})->void:
 if controls.is_empty():controls=create_controls(model)
 var tick:int=event.get("tick",model.state.tick)
 var now:int=roundi(tick*1000.0/60.0)
 if event.kind=="intent":submit(controls,event.value,tick);return
 if event.kind=="held_speed":
  if not controls.pedal_control.is_empty():submit(controls,controls.source.end(controls.pedal_control,now,250),tick)
  controls.held=int(event.value);controls.pedal_control=""
  if controls.held!=0:
   var intent=controls.source.begin("replay","explicit",[{"action_id":"pedal_up" if controls.held>0 else "pedal_down","parameters":{},"duration_ms":150}],now,250)
   controls.pedal_control=intent.control_id;controls.refreshed_ms=now;submit(controls,intent,tick)
  return
 var actions=[];var kind="explicit";var opportunity=null
 match event.kind:
  "turn":actions=[{"action_id":"turn_left" if int(event.value)<0 else "turn_right","parameters":{"strength":0.5},"duration_ms":0}]
  "call":kind="activate";opportunity=model.assist_state().opportunity_id
  "faster","slower":actions=[{"action_id":"speed_up" if event.kind=="faster" else "speed_down","parameters":{"strength":float(event.value)},"duration_ms":0}]
  _:return
 var intent=controls.source.begin("replay",kind,actions,now,250,opportunity)
 intent.event_id="recorded:"+str(event.event_id)
 submit(controls,intent,tick)
static func step_controls(controls:Dictionary,tick:int,delta:float=1.0/60.0)->void:
 var now=roundi(tick*1000.0/60.0)
 if controls.held!=0 and now-controls.refreshed_ms>=50:
  var intent=controls.source.update(controls.pedal_control,[{"action_id":"pedal_up" if controls.held>0 else "pedal_down","parameters":{},"duration_ms":150}],now,250)
  controls.refreshed_ms=now;submit(controls,intent,tick)
 controls.controller.port.model.refresh_assist()
 controls.controller.step(now);controls.port.advance(delta,now)
static func run(track,profile:Dictionary,inputs:Array[Dictionary],max_ticks:int,initial:Dictionary={})->Dictionary:
 var model=Drive.new(track);model.set_assist_level(profile.id);model.spatial_profile=profile.duplicate(true)
 if initial.has("distance_m"):model.reset(initial.distance_m)
 if initial.has("speed_mps"):
  model.state.velocity=-model.state.basis.z*float(initial.speed_mps);model.target_speed_mps=initial.get("target_speed_mps",22.0);model.sync_fields()
 var controls=create_controls(model)
 var start:Dictionary=model.state.snapshot();var events:Array[Dictionary]=[];var trace:Array[Dictionary]=[]
 var by_tick:Dictionary={}
 for event in inputs:
  if not event.has_all(["kind","tick","event_id","value"]) or event.tick<0:return {"error":"invalid_input"}
  if not by_tick.has(int(event.tick)):by_tick[int(event.tick)]=[]
  by_tick[int(event.tick)].append(event)
 for tick in range(max_ticks):
  for event in by_tick.get(tick,[]):apply_input(model,event,controls)
  step_controls(controls,tick);model.step(1.0/60.0)
  events.append_array(model.take_motion_events());trace.append(model.state.snapshot())
  if model.state.mode in ["finished","crashed"]:break
 return {"initial":start,"inputs":inputs,"trace":trace,"trace_digest":JSON.stringify(trace,"",true,true).sha256_text(),"events":events,"finished":model.finished,"crashed":model.off_road,"mode":model.state.mode,"seconds":model.elapsed_s,"final":model.state.snapshot(),"help_used":model.state.help_used.duplicate(),"error":""}
