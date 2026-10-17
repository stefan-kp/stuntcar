extends RefCounted
const Actions=preload("res://scripts/control/stuntcar_actions.gd")
const Contract=preload("res://addons/accessible_controls/core/contract.gd")
static func rate(actions:Array,hints:Array)->Dictionary:
 var known="";var speed=""
 for hint in hints:
  for id in hint.get("recommended_actions",[]):
   if id in ["turn_left","turn_right"]:known=id
  speed=hint.get("required_speed_action",speed)
 var turn="";var tempo=""
 for a in actions:
  if a.action_id in ["turn_left","turn_right"]:turn=a.action_id
  else:tempo=a.action_id
 var utility=null
 if not known.is_empty() and not turn.is_empty():
  if turn!=known:utility=-0.8
  elif not speed.is_empty():utility=0.8 if tempo==speed else -0.4
  elif tempo.is_empty():utility=0.6
 return {"rating_status":"unknown" if utility==null else "rated","utility":utility,"reason_code":"no_basis" if utility==null else "track_requirement"}
static func assess(model,request:Dictionary,hints:Array[Dictionary],now_ms:int)->Dictionary:
 var proposals=[];var choices=[]
 for id in ["turn_left","turn_right"]:choices.append([{"action_id":id,"parameters":{},"duration_ms":0}])
 var intent=request.get("intent")
 if intent is Dictionary and not intent.get("required_actions",[]).is_empty():choices.append(intent.required_actions)
 var seen={}
 for actions in choices:
  if not Contract.validate_actions(actions,Actions.catalog()).is_empty():continue
  var key=JSON.stringify(actions)
  if seen.has(key):continue
  seen[key]=true
  var rating=rate(actions,hints)
  var available=not model.off_road and not model.finished
  if model.airborne:
   for a in actions:
    if a.action_id.begins_with("turn_"):available=false
  if not available:rating={"rating_status":"unknown","utility":null,"reason_code":"unavailable"}
  var p={"proposal_id":"rule:%d"%proposals.size(),"actions":actions.duplicate(true),"available":available,"evidence":"rule" if rating.utility!=null else "unknown","outcome_status":null}
  p.merge(rating);proposals.append(p)
 return {"schema_version":1,"session_id":request.get("session_id",""),"decision_revision":0,"state_step":roundi(model.elapsed_s*60),"opportunity_id":model.assist_state().opportunity_id,"valid_until_ms":now_ms+100,"catalog_version":1,"model_version":"stuntcar:2","assist_profile_id":Actions.control_profile(model).profile_id,"objective_id":"stuntcar_rules_v1","horizon_ms":0,"scoring_version":1,"assessment_method":"rules_only","hints":hints.duplicate(true),"proposals":proposals}
