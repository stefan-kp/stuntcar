extends RefCounted
# Nachrichten bleiben reine Daten. Aktionsbedeutungen gehören zum Spiel.
const VERSION = 1
const KINDS = ["explicit", "activate", "unresolved", "cancel"]
const PHASES = ["begin", "update", "end"]
static func number(value) -> bool:
 return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))
static func integer(value, minimum: int = 0) -> bool:
 return number(value) and value >= minimum and floorf(float(value)) == float(value)
static func validate_catalog(catalog: Dictionary) -> Array[String]:
 var errors: Array[String] = []
 if catalog.get("schema_version") != VERSION: errors.append("schema_version")
 if not integer(catalog.get("catalog_version"),1): errors.append("catalog_version")
 if not catalog.get("actions") is Array: return ["actions"]
 var seen = {}
 for a in catalog.actions:
  if not a is Dictionary: errors.append("action");continue
  var id = a.get("action_id", "")
  if not id is String or id.is_empty() or seen.has(id): errors.append("action_id")
  seen[id] = true
  if not a.get("parameters") is Dictionary: errors.append("parameters")
  if a.get("execution_mode") not in ["pulse","bounded"]: errors.append("execution_mode")
  for key in ["default_duration_ms","max_duration_ms","max_update_gap_ms"]:
   if not integer(a.get(key)): errors.append(key)
  if integer(a.get("default_duration_ms")) and integer(a.get("max_duration_ms")):
   if a.execution_mode=="pulse" and (a.default_duration_ms!=0 or a.max_duration_ms!=0): errors.append("pulse_duration")
   if a.execution_mode=="bounded" and (a.default_duration_ms<=0 or a.default_duration_ms>a.max_duration_ms): errors.append("bounded_duration")
  for key in ["exclusive_group","reference_frame","effect"]:
   if not a.get(key) is String: errors.append(key)
 return errors
static func action_definition(catalog: Dictionary, id: String) -> Dictionary:
 for action in catalog.get("actions",[]):
  if action is Dictionary and action.get("action_id")==id: return action
 return {}
static func validate_actions(actions, catalog: Dictionary) -> Array[String]:
 if not actions is Array: return ["actions"]
 var errors: Array[String] = []
 var groups = {}
 var ids = {}
 for a in actions:
  if not a is Dictionary or not a.get("action_id") is String: errors.append("action_id");continue
  var definition = action_definition(catalog,a.action_id)
  if definition.is_empty(): errors.append("unknown_action");continue
  if ids.has(a.action_id): errors.append("duplicate_action")
  ids[a.action_id] = true
  var group = definition.get("exclusive_group","")
  if not group.is_empty():
   if groups.has(group): errors.append("exclusive_group")
   groups[group] = true
  var duration = a.get("duration_ms")
  if not integer(duration): errors.append("duration_ms")
  elif definition.execution_mode=="pulse" and duration!=0: errors.append("pulse_duration")
  elif definition.execution_mode=="bounded" and (duration<=0 or duration>definition.max_duration_ms): errors.append("bounded_duration")
  var parameters = a.get("parameters")
  if not parameters is Dictionary: errors.append("parameters");continue
  for key in parameters:
   if not definition.parameters.has(key): errors.append("unknown_parameter");continue
   var rule = definition.parameters[key]
   var value = parameters[key]
   if rule.get("type")=="number":
    if not number(value) or value<rule.get("min",-INF) or value>rule.get("max",INF): errors.append("parameter_range")
   elif rule.get("type")=="integer":
    if not integer(value,int(rule.get("min",0))) or value>rule.get("max",INF): errors.append("parameter_range")
   elif rule.get("type")=="string" and not value is String: errors.append("parameter_type")
  for key in definition.parameters:
   if not parameters.has(key) and not definition.parameters[key].has("default"): errors.append("missing_parameter")
 return errors
static func validate_intent(intent: Dictionary, catalog: Dictionary) -> Array[String]:
 var errors: Array[String] = []
 if intent.get("schema_version")!=VERSION: errors.append("schema_version")
 for key in ["session_id","event_id","source_id","control_id"]:
  if not intent.get(key) is String or intent.get(key,"").is_empty(): errors.append(key)
 if not integer(intent.get("control_revision"),1): errors.append("control_revision")
 if intent.get("kind") not in KINDS: errors.append("kind")
 if intent.get("phase") not in PHASES: errors.append("phase")
 for key in ["captured_at_ms","expires_at_ms"]:
  if not integer(intent.get(key)): errors.append(key)
 if integer(intent.get("captured_at_ms")) and integer(intent.get("expires_at_ms")) and intent.captured_at_ms>intent.expires_at_ms: errors.append("expiry")
 errors.append_array(validate_actions(intent.get("required_actions"),catalog))
 if intent.get("phase")=="update" and intent.get("required_actions") is Array:
  for action in intent.required_actions:
   if action is Dictionary and action.get("action_id") is String and action_definition(catalog,action.action_id).get("execution_mode")=="pulse":errors.append("pulse_update")
 if intent.get("kind")=="explicit" and intent.get("phase")=="begin" and intent.get("required_actions",[]).is_empty(): errors.append("explicit_actions")
 if not intent.get("forbidden_actions") is Array: errors.append("forbidden_actions")
 else:
  for id in intent.forbidden_actions:
   if not id is String or action_definition(catalog,id).is_empty(): errors.append("forbidden_action")
   for a in intent.get("required_actions",[]):
    if a is Dictionary and a.get("action_id")==id: errors.append("required_forbidden")
 return errors
static func validate_assessment(answer: Dictionary, catalog: Dictionary) -> Array[String]:
 var errors: Array[String] = []
 if answer.get("schema_version")!=VERSION or answer.get("catalog_version")!=catalog.get("catalog_version"): errors.append("version")
 for key in ["session_id","model_version","assist_profile_id","objective_id"]:
  if not answer.get(key) is String or answer.get(key,"").is_empty(): errors.append(key)
 for key in ["decision_revision","state_step","valid_until_ms","horizon_ms","scoring_version"]:
  if not integer(answer.get(key)): errors.append(key)
 if answer.get("assessment_method") not in ["rules_only","lookahead"]: errors.append("assessment_method")
 if not answer.get("hints") is Array: errors.append("hints")
 if not answer.get("proposals") is Array: return ["proposals"]
 var ids = {}
 for p in answer.proposals:
  if not p is Dictionary: errors.append("proposal");continue
  var id = p.get("proposal_id","")
  if not id is String or id.is_empty() or ids.has(id): errors.append("proposal_id")
  ids[id] = true
  errors.append_array(validate_actions(p.get("actions"),catalog))
  if not p.get("available") is bool: errors.append("available")
  if p.get("rating_status") not in ["rated","unknown"]: errors.append("rating_status")
  if p.get("rating_status")=="unknown" and p.get("utility")!=null: errors.append("unknown_utility")
  if p.get("rating_status")=="rated" and (not number(p.get("utility")) or absf(float(p.utility))>1): errors.append("utility")
  if p.get("available")==false and p.get("rating_status")!="unknown": errors.append("unavailable_rating")
  if p.get("evidence") not in ["rule","simulated","tested_samples","unknown"]: errors.append("evidence")
  if p.get("outcome_status") not in [null,"goal_reached","finished","open","crashed","unknown"]: errors.append("outcome_status")
 return errors
