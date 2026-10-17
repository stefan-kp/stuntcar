extends RefCounted
var session = ""
var events: Dictionary = {}
var controls: Dictionary = {}
func reset(session_id: String) -> void:
 session=session_id;events.clear();controls.clear()
func _key(intent: Dictionary) -> String:
 return JSON.stringify([intent.session_id,intent.source_id,intent.control_id])
func accept(intent: Dictionary, now_ms: int) -> Dictionary:
 if intent.session_id!=session or intent.captured_at_ms>now_ms or intent.expires_at_ms<now_ms: return {"status":"stale","reason_code":"input_time_or_session"}
 var event_key=JSON.stringify([session,intent.source_id,intent.event_id])
 if events.has(event_key): return {"status":"duplicate","reason_code":"event_seen"}
 events[event_key]=true
 var key=_key(intent)
 if intent.phase=="begin":
  if controls.has(key): return {"status":"stale","reason_code":"control_seen"}
  controls[key]={"source":intent.source_id,"id":intent.control_id,"revision":intent.control_revision,"captured":intent.captured_at_ms,"ended":false,"retired":{}}
 else:
  if not controls.has(key): return {"status":"stale","reason_code":"no_begin"}
  var previous=controls[key]
  if previous.ended or intent.control_revision<=previous.revision or intent.captured_at_ms<previous.captured: return {"status":"stale","reason_code":"old_control"}
  previous.revision=intent.control_revision;previous.captured=intent.captured_at_ms
 var control=controls[key]
 var accepted=intent.duplicate(true)
 if intent.phase=="end": control.ended=true
 else:
  accepted.required_actions=accepted.required_actions.filter(func(a):return not control.retired.has(a.action_id))
  if intent.kind=="explicit" and accepted.required_actions.is_empty(): return {"status":"stale","reason_code":"retired_members"}
 return {"status":"accepted","intent":accepted}
func retire(control_id: String, source_id:String="") -> void:
 for record in controls.values():
  if record.id==control_id and (source_id.is_empty() or record.source==source_id): record.ended=true
func retire_members(control_id: String, action_ids: Array, source_id:String="") -> void:
 for record in controls.values():
  if record.id==control_id and (source_id.is_empty() or record.source==source_id):
   for id in action_ids: record.retired[id]=true
func retire_source(source_id: String) -> void:
 for record in controls.values():
  if record.source==source_id: record.ended=true
