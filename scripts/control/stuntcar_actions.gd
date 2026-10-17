extends RefCounted
static func catalog()->Dictionary:
 var actions=[]
 for id in ["turn_left","turn_right","speed_up","speed_down","pedal_up","pedal_down"]:
  var pedal=id.begins_with("pedal_")
  actions.append({"action_id":id,"parameters":{} if pedal else {"strength":{"type":"number","min":0.0,"max":1.0,"default":0.5}},"execution_mode":"bounded" if pedal else "pulse","default_duration_ms":150 if pedal else 0,"max_duration_ms":150 if pedal else 0,"max_update_gap_ms":150 if pedal else 0,"exclusive_group":"steering" if id.begins_with("turn_") else "speed","reference_frame":"vehicle","effect":"requested_direction" if id.begins_with("turn_") else "stored_target_speed"})
 return {"schema_version":1,"catalog_version":1,"actions":actions}
static func control_profile(model)->Dictionary:
 return {"profile_id":"%s:%d"%[model.assist_id,model.assist_profile.version],"allow_additions":true,"allow_activate":model.assist_id=="very_easy"}
