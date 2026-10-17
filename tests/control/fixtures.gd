extends RefCounted
static func action(id: String, duration: int = 0, parameters: Dictionary = {}) -> Dictionary:
 return {"action_id":id,"duration_ms":duration,"parameters":parameters}
static func catalog() -> Dictionary:
 var actions = []
 for id in ["turn_left","turn_right","brake"]:
  actions.append({"action_id":id,"parameters":{},"execution_mode":"bounded" if id=="brake" else "pulse","default_duration_ms":100 if id=="brake" else 0,"max_duration_ms":1000 if id=="brake" else 0,"max_update_gap_ms":150 if id=="brake" else 0,"exclusive_group":"speed" if id=="brake" else "steering","reference_frame":"actor","effect":"test movement"})
 return {"schema_version":1,"catalog_version":1,"actions":actions}
static func intent(overrides: Dictionary = {}) -> Dictionary:
 var value = {"schema_version":1,"session_id":"s1","event_id":"key:1","source_id":"key","control_id":"key:1","control_revision":1,"kind":"explicit","required_actions":[action("turn_left")],"forbidden_actions":[],"phase":"begin","captured_at_ms":0,"expires_at_ms":250,"opportunity_id":1}
 value.merge(overrides,true)
 return value
static func proposal(id: String, actions: Array, utility = 0.6, status: String = "rated", outcome = null) -> Dictionary:
 return {"proposal_id":id,"actions":actions,"available":true,"rating_status":status,"utility":utility,"reason_code":"test","evidence":"rule" if outcome==null else "simulated","outcome_status":outcome}
static func assessment(proposal_overrides: Dictionary = {}, frame_overrides: Dictionary = {}) -> Dictionary:
 var p = proposal("left",[action("turn_left")]);p.merge(proposal_overrides,true)
 var value = {"schema_version":1,"session_id":"s1","decision_revision":1,"state_step":0,"opportunity_id":1,"valid_until_ms":250,"catalog_version":1,"model_version":"test:1","assist_profile_id":"very_easy:1","objective_id":"advance","horizon_ms":0,"scoring_version":1,"assessment_method":"rules_only","hints":[],"proposals":[p]}
 value.merge(frame_overrides,true)
 return value
static func profile(id: String = "very_easy") -> Dictionary:
 return {"profile_id":id+":1","allow_additions":id!="direct","allow_activate":id=="very_easy"}
