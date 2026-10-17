extends RefCounted
var source_id: String
var serial = 0
var controls: Dictionary = {}
func _init(id: String) -> void: source_id = id
func _event(control: Dictionary, phase: String, actions: Array, now_ms: int, ttl_ms: int) -> Dictionary:
 serial += 1
 control.revision += 1
 return {"schema_version":1,"session_id":control.session,"event_id":"%s:%s:%d" % [control.session,source_id,serial],"source_id":source_id,"control_id":control.id,"control_revision":control.revision,"kind":control.kind,"required_actions":actions.duplicate(true),"forbidden_actions":[],"phase":phase,"captured_at_ms":now_ms,"expires_at_ms":now_ms+ttl_ms,"opportunity_id":control.opportunity}
func begin(session_id: String, kind: String, actions: Array, now_ms: int, ttl_ms: int, opportunity_id = null) -> Dictionary:
 var id = "%s:%s:control:%d" % [session_id,source_id,serial+1]
 var control = {"id":id,"session":session_id,"kind":kind,"revision":0,"opportunity":opportunity_id}
 controls[id] = control
 return _event(control,"begin",actions,now_ms,ttl_ms)
func update(control_id: String, actions: Array, now_ms: int, ttl_ms: int) -> Dictionary:
 if not controls.has(control_id): return {}
 return _event(controls[control_id],"update",actions,now_ms,ttl_ms)
func end(control_id: String, now_ms: int, ttl_ms: int) -> Dictionary:
 if not controls.has(control_id): return {}
 var result = _event(controls[control_id],"end",[],now_ms,ttl_ms)
 controls.erase(control_id)
 return result
func reset() -> void: controls.clear()
