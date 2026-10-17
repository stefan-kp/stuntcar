extends RefCounted
const Source=preload("res://addons/accessible_controls/core/input_source.gd")
const Keys=preload("res://scripts/input/keyboard_controls.gd")
const TTL_MS=250
const REFRESH_MS=50
const PEDAL_MS=150
var source=Source.new("keyboard")
var bindings:Array[int]=[]
var session=""
var held:Dictionary={}
var blocked:Dictionary={}
var active:Dictionary={}
func _init(key_bindings:Array)->void:bindings.assign(key_bindings)
func configure(session_id:String,_catalog:Dictionary)->void:
 reset();session=session_id
func _action(id:String)->Dictionary:
 return {"action_id":id,"parameters":{"strength":0.5} if id.begins_with("turn_") else {},"duration_ms":PEDAL_MS if id.begins_with("pedal_") else 0}
func capture(code:int,pressed:bool,now_ms:int)->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 if not pressed:
  held.erase(code);blocked.erase(code)
  if active.has(code):
   result.append(source.end(active[code].control_id,now_ms,TTL_MS));active.erase(code)
  return result
 if held.has(code) or blocked.has(code):return result
 held[code]=true
 var action=Keys.action_for(code,bindings)
 if action.is_empty() or session.is_empty():return result
 var id={"left":"turn_left","right":"turn_right","faster":"pedal_up","slower":"pedal_down"}[action]
 var event=source.begin(session,"explicit",[_action(id)],now_ms,TTL_MS)
 result.append(event)
 if id.begins_with("pedal_"):active[code]={"control_id":event.control_id,"action_id":id,"refreshed":now_ms}
 return result
func refresh(now_ms:int)->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for code in active:
  var entry=active[code]
  if held.has(code) and not blocked.has(code) and now_ms-entry.refreshed>=REFRESH_MS:
   result.append(source.update(entry.control_id,[_action(entry.action_id)],now_ms,TTL_MS));entry.refreshed=now_ms
 return result
func reset(require_release:bool=true)->void:
 if require_release:
  for code in held:blocked[code]=true
 else:blocked.clear()
 held.clear();active.clear();source.reset()
func rebind(key_bindings:Array,now_ms:int)->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for entry in active.values():result.append(source.end(entry.control_id,now_ms,TTL_MS))
 reset();bindings.assign(key_bindings)
 return result
