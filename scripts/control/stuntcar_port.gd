extends "res://addons/accessible_controls/core/game_port.gd"
const Actions=preload("res://scripts/control/stuntcar_actions.gd")
const Hints=preload("res://scripts/control/stuntcar_hints.gd")
const Rules=preload("res://scripts/control/stuntcar_rules.gd")
const Contract=preload("res://addons/accessible_controls/core/contract.gd")
var model
var session=""
var revision=0
var last_condition=""
var applied:Dictionary={}
var executions:Dictionary={}
var retired:Dictionary={}
var steering_owner=""
func _init(drive_model)->void:model=drive_model
func describe_actions()->Dictionary:return Actions.catalog()
func reset(session_id:String)->void:
 model.clear_steering_request();model.set_active_pedal(0)
 steering_owner=""
 session=session_id;applied.clear();executions.clear();retired.clear();last_condition="";revision=0
func condition()->String:
 return JSON.stringify([model.attempt_id,model.elapsed_s,model.distance_m,model.speed_mps,model.target_speed_mps,model.lateral,model.off_road,model.finished,model.airborne,model.requested_direction,model.assist_state(),Actions.control_profile(model)])
func context(now_ms:int)->Dictionary:
 var current=condition()
 if current!=last_condition:revision+=1;last_condition=current
 return {"session_id":session,"decision_revision":revision,"state_step":roundi(model.elapsed_s*60),"opportunity_id":model.assist_state().opportunity_id,"valid_until_ms":now_ms+100,"catalog_version":1,"model_version":"stuntcar:2","assist_profile_id":Actions.control_profile(model).profile_id,"condition":current}
func assess(request:Dictionary)->Dictionary:
 var answer=Rules.assess(model,request,Hints.read(model,request.now_ms),request.now_ms)
 answer.merge(context(request.now_ms),true)
 answer.active_members=[]
 for key in executions:
  for id in executions[key].members:
   var member:Dictionary=executions[key].members[id]
   var end:int=member.expires_ms
   if id.begins_with("turn_") and key==steering_owner and model.requested_direction==(-1 if id=="turn_left" else 1):end=request.now_ms+roundi(maxf(0,model.steering_expires_at_s-model.elapsed_s)*1000)
   if end>request.now_ms:answer.active_members.append({"execution_id":key,"action_id":id,"ends_at_ms":end})
 return answer
func reject(reason:String)->Dictionary:return {"result":"rejected","reason_code":reason,"actions":[]}
func apply(decision:Dictionary,now_ms:int)->Dictionary:
 if decision.get("session_id")!=session:return reject("session")
 var intent:Dictionary=decision.get("intent",{})
 var event:String=intent.get("event_id","")
 var key:String="%s:%s:%s"%[session,intent.get("source_id",""),intent.get("control_id","")]
 var event_key=JSON.stringify([intent.get("source_id"),event])
 if applied.has(event_key):return applied[event_key].duplicate(true)
 var actions:Array=decision.get("actions",[])
 if event.is_empty() or actions.is_empty() or not Contract.validate_actions(actions,describe_actions()).is_empty():return reject("actions")
 if model.off_road or model.finished:return reject("vehicle_unavailable")
 var reference:Dictionary=decision.get("assessment_reference",{})
 if not reference.is_empty():
  var current=context(now_ms)
  if reference.get("condition")!=current.condition or reference.get("assist_profile_id")!=current.assist_profile_id or reference.get("session_id")!=session or reference.get("valid_until_ms",-1)<now_ms:return {"result":"stale","actions":[]}
 if intent.get("kind")=="explicit":
  for required in intent.get("required_actions",[]):
   if not actions.has(required):return reject("explicit_action_missing")
 if actions.size()>intent.get("required_actions",[]).size() or intent.get("kind")=="activate":
  if reference.is_empty() or decision.get("profile",{}).get("profile_id")!=Actions.control_profile(model).profile_id:return reject("assistance_context")
  if intent.get("kind")=="activate" and (model.assist_id!="very_easy" or intent.get("opportunity_id")!=model.assist_state().opportunity_id):return reject("activation_context")
 if retired.has(key):return reject("retired")
 for a in actions:
  if a.action_id.begins_with("turn_") and model.airborne:return reject("airborne_steering")
 # Complete preflight precedes every model change.
 var record:Dictionary=executions.get(key,{"source_id":intent.get("source_id",""),"members":{}})
 for a in actions:
  var id:String=a.action_id
  var group:String=Contract.action_definition(describe_actions(),id).exclusive_group
  for old_key in executions.keys():
   for old_id in executions[old_key].members.keys():
    if old_id!=id and Contract.action_definition(describe_actions(),old_id).exclusive_group==group:
     executions[old_key].members.erase(old_id)
     if executions[old_key].members.is_empty():retired[old_key]=true
  var strength:float=a.parameters.get("strength",0.5)
  if id.begins_with("turn_"):
   model.request_turn(-1 if id=="turn_left" else 1,strength,"control:"+event_key)
   steering_owner=key
  elif id in ["speed_up","speed_down"]:model.change_speed(1 if id=="speed_up" else -1,strength)
  record.members[id]={"action":a.duplicate(true),"expires_ms":now_ms+int(a.duration_ms) if a.duration_ms>0 else -1}
 executions[key]=record
 var ends=[]
 for a in actions:
  var end=now_ms+int(a.duration_ms)
  if a.action_id.begins_with("turn_"):end=now_ms+roundi(maxf(0,model.steering_expires_at_s-model.elapsed_s)*1000)
  ends.append({"action_id":a.action_id,"ends_at_ms":end})
 var result={"member_ends":ends,"result":"applied","execution_id":key,"actions":actions.duplicate(true),"reason_code":"executed"}
 applied[event_key]=result.duplicate(true)
 return result
func pedal_direction()->int:
 var up=false;var down=false
 for record in executions.values():
  up=up or record.members.has("pedal_up");down=down or record.members.has("pedal_down")
 return 0 if up==down else (1 if up else -1)
func advance(delta:float,now_ms:int)->void:
 for record in executions.values():
  for id in record.members.keys():
   var member:Dictionary=record.members[id]
   if member.expires_ms>=0 and now_ms>=member.expires_ms:record.members.erase(id);continue
 var direction=pedal_direction()
 model.set_active_pedal(direction)
 model.keyboard_speed(direction,delta)
func cancel(request:Dictionary,_now_ms:int)->Dictionary:
 if request.get("session_id")!=session:return reject("session")
 for key in executions.keys():
  var record:Dictionary=executions[key]
  var matches=request.get("scope")=="session" or (request.get("scope")=="source" and record.source_id==request.get("source_id")) or (request.get("scope")=="execution" and key==request.get("execution_id"))
  if not matches:continue
  for id in record.members.keys():
   if request.has("action_ids") and id not in request.action_ids:continue
   record.members.erase(id)
   if id.begins_with("turn_") and key==steering_owner:model.clear_steering_request();steering_owner=""
  if record.members.is_empty():executions.erase(key)
 if request.get("scope")=="session":model.clear_steering_request()
 model.set_active_pedal(pedal_direction())
 return {"result":"applied","actions":[]}
