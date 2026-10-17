extends RefCounted
static func _includes(actions: Array, required: Array) -> bool:
 for wanted in required:
  var found=false
  for a in actions:
   if a.action_id==wanted.action_id and a.parameters==wanted.parameters and a.duration_ms==wanted.duration_ms: found=true;break
  if not found:return false
 return true
static func choose(intent: Dictionary, answer: Dictionary, profile: Dictionary) -> Dictionary:
 var required=intent.required_actions
 var explicit=intent.kind=="explicit"
 if not explicit and (intent.kind!="activate" or not profile.get("allow_activate",false) or intent.get("opportunity_id")==null or intent.opportunity_id!=answer.get("opportunity_id")):
  return {"status":"no_action","actions":[]}
 var choices=[]
 for proposal in answer.get("proposals",[]):
  if not proposal.get("available",false) or proposal.get("rating_status")!="rated":continue
  var actions=proposal.actions
  if explicit and not _includes(actions,required):continue
  var additions=actions.size()-required.size()
  if explicit and additions>0 and not profile.get("allow_additions",false):continue
  if proposal.get("outcome_status")=="crashed" and (not explicit or additions>0):continue
  var forbidden=false
  for a in actions:
   if a.action_id in intent.forbidden_actions:forbidden=true
  if forbidden:continue
  var item=proposal.duplicate(true);item.additions=additions
  choices.append(item)
 choices.sort_custom(func(a,b):
  if a.utility!=b.utility:return a.utility>b.utility
  if a.additions!=b.additions:return a.additions<b.additions
  return a.proposal_id<b.proposal_id)
 if choices.is_empty():return {"status":"explicit_only" if explicit else "no_action","actions":required.duplicate(true) if explicit else []}
 var best=choices[0]
 return {"status":"selected" if not best.actions.is_empty() else "no_action","actions":best.actions.duplicate(true),"proposal_id":best.proposal_id}
