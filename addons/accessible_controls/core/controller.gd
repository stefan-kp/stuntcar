extends RefCounted
const Contract=preload("res://addons/accessible_controls/core/contract.gd")
const Ledger=preload("res://addons/accessible_controls/core/input_ledger.gd")
const Selector=preload("res://addons/accessible_controls/core/selector.gd")
var port
var profile:Dictionary
var catalog:Dictionary
var ledger=Ledger.new()
var session=""
var suspended=false
var queue:Array=[]
var executions:Dictionary={}
func _init(game_port, active_profile:Dictionary)->void:
 port=game_port;profile=active_profile.duplicate(true);catalog=port.describe_actions()
func begin_session(session_id:String)->void:
 queue.clear();executions.clear();suspended=false
 if session!=session_id:ledger.reset(session_id)
 session=session_id
func submit(intent:Dictionary)->void:queue.append(intent.duplicate(true))
func _request(intent, now_ms:int, query:bool=false)->Dictionary:
 return {"session_id":session,"now_ms":now_ms,"profile":profile.duplicate(true),"intent":intent,"query_only":query}
func _answer(intent,now_ms:int,query:bool=false)->Dictionary:
 var answer:Dictionary=port.assess(_request(intent,now_ms,query))
 if not Contract.validate_assessment(answer,catalog).is_empty():return {}
 if answer.session_id!=session or answer.assist_profile_id!=profile.profile_id or answer.valid_until_ms<now_ms:return {}
 if answer.has("active_members"):
  for record in executions.values():
   for id in record.get("ends",{}):record.ends[id]=now_ms
  for member in answer.active_members:
   if executions.has(member.execution_id):executions[member.execution_id].ends[member.action_id]=member.ends_at_ms
 return answer
func read_hints(now_ms:int)->Array:
 var answer=_answer(null,now_ms,true)
 return answer.get("hints",[]).duplicate(true)
func _fresh_update(intent:Dictionary,now_ms:int)->bool:
 if intent.phase!="update":return true
 for a in intent.required_actions:
  var definition=Contract.action_definition(catalog,a.action_id)
  var gap=int(definition.get("max_update_gap_ms",0))
  if gap<=0 or now_ms-intent.captured_at_ms>gap:return false
 return true
func step(now_ms:int)->Array[Dictionary]:
 var results:Array[Dictionary]=[]
 var pending:Array=[]
 var batch=queue;queue=[]
 if suspended:return [{"result":"rejected","reason_code":"suspended"}]
 if not Contract.validate_catalog(catalog).is_empty():return [{"result":"rejected","reason_code":"catalog"}]
 for input in batch:
  if not Contract.validate_intent(input,catalog).is_empty() or not _fresh_update(input,now_ms):
   results.append({"result":"rejected","reason_code":"input"});continue
  var accepted=ledger.accept(input,now_ms)
  if accepted.status!="accepted":results.append({"result":accepted.status,"reason_code":accepted.reason_code});continue
  pending.append(accepted.intent)
 var conflicts={}
 var group_actions={}
 for intent in pending:
  if intent.phase=="end" or intent.kind!="explicit":continue
  for a in intent.required_actions:
   var group=Contract.action_definition(catalog,a.action_id).get("exclusive_group","")
   if group.is_empty():continue
   if group_actions.has(group) and group_actions[group]!=a.action_id:conflicts[group]=true
   group_actions[group]=a.action_id
 for intent in pending:
  if intent.kind=="cancel":
   lose_source(intent.source_id,now_ms);results.append({"result":"applied","actions":[]});continue
  if intent.phase=="end":
   for id in executions.keys():
    if executions[id].control_id==intent.control_id and executions[id].source_id==intent.source_id:
     port.cancel({"session_id":session,"scope":"execution","execution_id":id,"reason":"input_end"},now_ms);executions.erase(id)
   results.append({"result":"applied","actions":[],"event_id":intent.event_id});continue
  if intent.kind=="unresolved":results.append({"result":"rejected","reason_code":"unresolved"});continue
  var blocked=false
  for a in intent.required_actions:
   if conflicts.has(Contract.action_definition(catalog,a.action_id).get("exclusive_group","")):blocked=true
  if blocked:
   ledger.retire(intent.control_id,intent.source_id);results.append({"result":"rejected","reason_code":"conflicting_inputs"});continue
  var result=_execute(intent,now_ms,pending)
  result.event_id=intent.event_id
  if result.get("result")=="applied":_remember(intent,result,now_ms)
  results.append(result)
 return results
func constrained_intent(intent:Dictionary,now_ms:int,pending:Array)->Dictionary:
 var selection=intent.duplicate(true)
 var requested_groups={}
 if intent.kind=="explicit":
  for a in intent.required_actions:requested_groups[Contract.action_definition(catalog,a.action_id).get("exclusive_group","")]=true
 var protected=[]
 for record in executions.values():
  for a in record.get("explicit_actions",[]):
   if record.get("ends",{}).get(a.action_id,now_ms)>now_ms:protected.append(a)
 for other in pending:
  if other.kind=="explicit" and other.phase!="end":protected.append_array(other.required_actions)
 for active in protected:
  var group=Contract.action_definition(catalog,active.action_id).get("exclusive_group","")
  if group.is_empty() or requested_groups.has(group):continue
  for action in catalog.actions:
   if action.exclusive_group==group and action.action_id!=active.action_id and action.action_id not in selection.forbidden_actions:selection.forbidden_actions.append(action.action_id)
 return selection
func _execute(intent:Dictionary,now_ms:int,pending:Array)->Dictionary:
 for attempt in range(3):
  var answer={} if attempt==2 else _answer(intent,now_ms)
  var choice=Selector.choose(constrained_intent(intent,now_ms,pending),answer,profile) if not answer.is_empty() else {"status":"explicit_only" if intent.kind=="explicit" else "no_action","actions":intent.required_actions if intent.kind=="explicit" else []}
  if choice.status=="no_action":return {"result":"rejected","reason_code":"no_rated_action","actions":[]}
  var decision={"session_id":session,"intent":intent.duplicate(true),"actions":choice.actions.duplicate(true),"assessment_reference":answer if choice.status=="selected" else {},"profile":profile.duplicate(true)}
  var result:Dictionary=port.apply(decision,now_ms)
  if result.get("result")!="stale":return result
 return {"result":"rejected","reason_code":"no_current_state","actions":[]}
func _remember(intent:Dictionary,result:Dictionary,now_ms:int)->void:
 var new_groups={}
 for a in result.get("actions",[]):
  new_groups[Contract.action_definition(catalog,a.action_id).get("exclusive_group","")]=a.action_id
 for id in executions.keys():
  var old=executions[id]
  if old.control_id==intent.control_id and old.source_id==intent.source_id:continue
  var retire=[]
  for a in old.actions:
   var group=Contract.action_definition(catalog,a.action_id).get("exclusive_group","")
   if new_groups.has(group) and new_groups[group]!=a.action_id:retire.append(a.action_id)
  if not retire.is_empty():
   ledger.retire_members(old.control_id,retire,old.source_id)
   port.cancel({"session_id":session,"scope":"execution","execution_id":id,"action_ids":retire,"reason":"replaced"},now_ms)
   old.actions=old.actions.filter(func(a):return a.action_id not in retire)
   if old.actions.is_empty():executions.erase(id)
 if result.has("execution_id"):
  var ends={}
  for a in result.get("actions",[]):ends[a.action_id]=now_ms+int(a.duration_ms)
  for member in result.get("member_ends",[]):ends[member.action_id]=member.ends_at_ms
  executions[result.execution_id]={"control_id":intent.control_id,"source_id":intent.source_id,"actions":result.get("actions",[]).duplicate(true),"explicit_actions":intent.required_actions.duplicate(true) if intent.kind=="explicit" else [],"ends":ends}
func suspend(reason:String,now_ms:int)->void:
 suspended=true
 queue.clear()
 port.cancel({"session_id":session,"scope":"session","reason":reason},now_ms)
 for record in executions.values():ledger.retire(record.control_id,record.source_id)
 executions.clear()
func lose_source(source_id:String,now_ms:int)->void:
 queue=queue.filter(func(i):return i.source_id!=source_id)
 ledger.retire_source(source_id)
 port.cancel({"session_id":session,"scope":"source","source_id":source_id,"reason":"source_lost"},now_ms)
 for id in executions.keys():
  if executions[id].source_id==source_id:executions.erase(id)
