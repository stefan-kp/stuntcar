extends RefCounted
static func text(key:String)->String:return TranslationServer.translate(key)
static func present(hints:Array,confirmation:Dictionary,state:String)->Dictionary:
 var result={"title":"","detail":"","hint_id":""}
 if state=="FALLING":return {"title":text("I18N_FALL_TITLE"),"detail":text("I18N_FALL_HELP"),"hint_id":""}
 if state!="RUNNING":return result
 result.title=text("I18N_STRAIGHT_TITLE");result.detail=text("I18N_STRAIGHT_HELP")
 var hint:Dictionary={} if hints.is_empty() else hints[0]
 var chosen=""
 if confirmation.get("result")=="applied":
  for a in confirmation.get("actions",[]):
   if a.action_id in ["turn_left","turn_right"]:chosen=a.action_id
 if not chosen.is_empty():
  result.title=text("I18N_TURN_LEFT_SELECTED" if chosen=="turn_left" else "I18N_TURN_RIGHT_SELECTED")
  result.detail=text({"saved":"I18N_ASSIST_SAVED","rescue":"I18N_ASSIST_RESCUE","sway":"I18N_ASSIST_SWAY","active":"I18N_ASSIST_ACTIVE"}.get(hint.get("detail_code",""),"I18N_CONTROL_DIRECTION_EXECUTED"))
 elif hint.get("kind")=="direction":
  result.title=text("I18N_TURN_LEFT" if hint.direction==-1 else "I18N_TURN_RIGHT")
  result.detail=text("I18N_ASSIST_LAST_CHANCE" if hint.phase=="rescue" else "I18N_TURN_PROMPT")
 elif hint.get("kind")=="missed":result.title=text("I18N_ASSIST_MISSED");result.detail=text("I18N_ASSIST_MISSED_HELP")
 elif hint.get("kind")=="jump":result.title=text("I18N_JUMP_AHEAD");result.detail=text("I18N_RAMP_SPEED_UNVERIFIED")
 if not hint.is_empty():
  result.hint_id=hint.get("hint_id","") if hint.get("phase")!="closed" else ""
  if hint.get("target_speed_mps")!=null:result.detail+="\n"+text("I18N_CONTROL_RECOMMENDED_SPEED")%roundi(float(hint.target_speed_mps)*3.6)
  if hint.get("speed_evidence","unknown") not in ["tested_samples"]:result.detail+="\n"+text("I18N_CONTROL_SPEED_BOUNDS_UNKNOWN")
 return result
