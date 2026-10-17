extends "res://addons/accessible_controls/core/game_port.gd"
const F = preload("res://tests/control/fixtures.gd")
var answer = F.assessment()
var applied: Array = []
var cancelled: Array = []
var position = 0
var stale_count = 0
var applied_ids = {}
var extra_actions=[]
var queries=[]
func describe_actions() -> Dictionary:
 var catalog=F.catalog();catalog.actions.append_array(extra_actions);return catalog
func assess(request: Dictionary) -> Dictionary:
 queries.append(request.duplicate(true))
 var result = answer.duplicate(true)
 result.session_id = request.session_id
 result.assist_profile_id = request.profile.profile_id
 return result
func apply(decision: Dictionary, _now_ms: int) -> Dictionary:
 var intent = decision.intent
 if applied_ids.has(intent.event_id): return {"result":"duplicate","actions":[]}
 if stale_count>0:
  stale_count-=1
  return {"result":"stale","actions":[]}
 for a in decision.actions:
  if a.action_id=="turn_left": position-=1
  if a.action_id=="turn_right": position+=1
 applied_ids[intent.event_id]=true
 applied.append(decision.duplicate(true))
 return {"result":"applied","execution_id":intent.event_id,"actions":decision.actions.duplicate(true)}
func cancel(request: Dictionary, _now_ms: int) -> Dictionary:
 cancelled.append(request.duplicate(true))
 return {"result":"applied","actions":[]}
