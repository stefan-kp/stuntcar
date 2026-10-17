extends RefCounted
const StuntAssist=preload("res://scripts/vehicle/spatial/stunt_assist.gd")
static func read(model,now_ms:int)->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 var state:Dictionary=model.assist_state()
 var direction:int=state.turn_sign
 if state.phase!="closed" and direction in [-1,1]:
  result.append({"hint_id":"%d:curve:%d"%[model.attempt_id,state.opportunity_id],"opportunity_id":state.opportunity_id,"kind":"direction","phase":state.phase,"recommended_actions":["turn_left" if direction==-1 else "turn_right"],"direction":direction,"min_speed_mps":null,"max_speed_mps":null,"target_speed_mps":null,"speed_evidence":"unknown","evidence":"rule","valid_until_ms":now_ms+100})
 if not result.is_empty():
  var curve:Dictionary=model.track.curves[state.curve_id]
  result[0].detail_code="saved" if state.authorized and model.distance_m<curve.start_m else ("rescue" if model.motion in ["late_turn","rescue_turn"] else ("sway" if model.motion=="safe_sway" else "active" if state.authorized else "prompt"))
 elif state.phase=="closed" and state.closed_reason in ["expired","outside_support","missed"]:
  result.append({"hint_id":"%d:missed:%d"%[model.attempt_id,state.opportunity_id],"opportunity_id":state.opportunity_id,"kind":"missed","phase":"closed","recommended_actions":[],"direction":0,"min_speed_mps":null,"max_speed_mps":null,"target_speed_mps":null,"speed_evidence":"unknown","evidence":"rule","valid_until_ms":now_ms+100})
 var speed:Dictionary={};var evidence="unknown";var element=""
 if model.has_method("verified_speed_hint"):
  speed=model.verified_speed_hint()
  if not speed.is_empty():evidence="tested_samples"
  else:
   for e in model.track.elements:
    if e.end_m<model.distance_m:continue
    var limits:Dictionary=StuntAssist.limits(e)
    if limits.is_empty():continue
    if e.start_m-model.distance_m>float(limits.approach_m):break
    speed={"target_mps":limits.target_mps};element=e.id;evidence="assist_target";break
 else:
  speed=model.track.speed_hint_at(model.distance_m,model.input_window_m())
  if speed.get("target_mps")!=null:evidence="assist_target" if speed.get("model")=="lower_assist_v1" else "unverified_target"
 if not speed.is_empty() and (speed.get("target_mps")!=null or speed.get("kind")=="ramp"):
  var hint:Dictionary=result[0] if not result.is_empty() else {"hint_id":"%d:speed:%s"%[model.attempt_id,element if not element.is_empty() else str(speed.get("start_m",0))],"opportunity_id":state.opportunity_id,"kind":"jump" if speed.get("kind")=="ramp" else "speed","phase":"early","recommended_actions":[],"direction":0,"evidence":"rule","valid_until_ms":now_ms+100}
  hint.target_speed_mps=speed.target_mps
  hint.min_speed_mps=speed.get("min_mps") if evidence=="tested_samples" else null
  hint.max_speed_mps=speed.get("max_mps") if evidence=="tested_samples" else null
  hint.speed_evidence=evidence
  if result.is_empty():result.append(hint)
 return result
