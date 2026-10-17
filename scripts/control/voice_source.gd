extends RefCounted
const Source=preload("res://addons/accessible_controls/core/input_source.gd")
const Contract=preload("res://addons/accessible_controls/core/contract.gd")
const Strength=preload("res://scripts/input/voice_strength.gd")
const Profile=preload("res://scripts/input/call_profile.gd")
const Calibration=preload("res://scripts/input/voice_calibration.gd")
var source=Source.new("voice")
var session=""
var packets:Dictionary={}
func configure(session_id:String,_catalog:Dictionary)->void:
 session=session_id;source.reset();packets.clear()
func command(packet:Dictionary,now_ms:int)->Dictionary:
 var key=JSON.stringify([packet.get("epoch",-1),packet.get("event_id",packet.get("seq",-1)),"word"])
 if packets.has(key):return packets[key].duplicate(true)
 var mapping={"left":"turn_left","right":"turn_right","faster":"speed_up","slower":"speed_down"}
 var word=packet.get("command","")
 var actions=[]
 if mapping.has(word):actions.append({"action_id":mapping[word],"parameters":{"strength":Strength.normalize(packet.get("strength",Strength.NORMAL))},"duration_ms":0})
 var result=source.begin(session,"explicit" if not actions.is_empty() else "unresolved",actions,now_ms,250)
 packets[key]=result
 return result.duplicate(true)
func activate_call(packet:Dictionary,context:Dictionary,now_ms:int)->Dictionary:
 if context.get("state")!="RUNNING" or not context.get("voice_enabled",false) or context.get("assist_id")!="very_easy":return {}
 var profile:Dictionary=context.get("profile",{})
 if not Profile.validate(profile,context.get("microphone","")).is_empty():return {}
 if packet.get("has_command",true)!=false:return {}
 for key in ["call_id","epoch","opportunity_id"]:
  if not Contract.integer(packet.get(key)):return {}
 if packet.opportunity_id!=context.get("opportunity_id",-1) or packet.epoch!=context.get("epoch",packet.epoch):return {}
 var duration=packet.get("speech_seconds")
 if not Contract.number(duration) or duration<profile.min_call_s or duration>profile.max_call_s:return {}
 if not Calibration.valid_signal(packet.get("peak_rms")) or packet.peak_rms<profile.on_rms:return {}
 var key=JSON.stringify([packet.epoch,packet.call_id,"call"])
 if packets.has(key):return packets[key].duplicate(true)
 var result=source.begin(session,"activate",[],now_ms,250,packet.opportunity_id)
 packets[key]=result
 return result.duplicate(true)
