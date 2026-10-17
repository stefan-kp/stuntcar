extends "res://addons/accessible_controls/core/game_port.gd"
const Contract=preload("res://addons/accessible_controls/core/contract.gd")
var x=0
var y=0.0
var velocity_y=0.0
var grounded=true
var jumps=0
var applied={}
func describe_actions()->Dictionary:
 var actions=[]
 for id in ["move_left","move_right","jump"]:
  actions.append({"action_id":id,"parameters":{},"execution_mode":"pulse","default_duration_ms":0,"max_duration_ms":0,"max_update_gap_ms":0,"exclusive_group":"horizontal" if id.begins_with("move_") else "vertical","reference_frame":"actor","effect":"horizontal_step" if id.begins_with("move_") else "upward_impulse"})
 return {"schema_version":1,"catalog_version":1,"actions":actions}
func action(id:String)->Dictionary:return {"action_id":id,"parameters":{},"duration_ms":0}
func assess(request:Dictionary)->Dictionary:
 var proposals=[]
 var choices=[[action("move_right")],[action("move_left")],[action("move_right"),action("jump")]]
 if request.intent is Dictionary and not request.intent.required_actions.is_empty():choices.append(request.intent.required_actions)
 for i in range(choices.size()):
  var actions:Array=choices[i]
  var possible=grounded or not actions.any(func(a):return a.action_id=="jump")
  proposals.append({"proposal_id":str(i),"actions":actions,"available":possible,"rating_status":"rated" if possible else "unknown","utility":(0.8 if actions.size()==2 else -0.8 if actions[0].action_id=="move_left" else 0.6) if possible else null,"evidence":"rule","outcome_status":null,"reason_code":"platform"})
 return {"schema_version":1,"session_id":request.session_id,"decision_revision":jumps,"state_step":0,"opportunity_id":1,"valid_until_ms":request.now_ms+100,"catalog_version":1,"model_version":"platform:1","assist_profile_id":request.profile.profile_id,"objective_id":"platform","horizon_ms":0,"scoring_version":1,"assessment_method":"rules_only","hints":[],"proposals":proposals}
func apply(decision:Dictionary,now_ms:int)->Dictionary:
 var key=JSON.stringify([decision.session_id,decision.intent.source_id,decision.intent.event_id])
 if applied.has(key):return {"result":"duplicate","actions":[]}
 var actions:Array=decision.actions
 if not Contract.validate_actions(actions,describe_actions()).is_empty() or (not grounded and actions.any(func(a):return a.action_id=="jump")):return {"result":"rejected","reason_code":"no_ground","actions":[]}
 for a in actions:
  match a.action_id:
   "move_left":x-=1
   "move_right":x+=1
   "jump":velocity_y=6.0;grounded=false;jumps+=1
 applied[key]=true
 var ends=[]
 for a in actions:ends.append({"action_id":a.action_id,"ends_at_ms":now_ms})
 return {"result":"applied","execution_id":key,"actions":actions.duplicate(true),"member_ends":ends}
func cancel(_request:Dictionary,_now_ms:int)->Dictionary:return {"result":"applied","actions":[]}
func step(delta:float)->void:
 y+=velocity_y*delta-4.9*delta*delta;velocity_y-=9.8*delta
 if y<=0:y=0;velocity_y=0;grounded=true
