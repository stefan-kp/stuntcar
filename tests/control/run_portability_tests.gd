extends "res://tests/control/test_base.gd"
const Controller=preload("res://addons/accessible_controls/core/controller.gd")
const Source=preload("res://addons/accessible_controls/core/input_source.gd")
const Contract=preload("res://addons/accessible_controls/core/contract.gd")
func _initialize()->void:
 var P=need("res://tests/control/platform_port.gd")
 if P==null:done();return
 var port=P.new();var c=Controller.new(port,{"profile_id":"assist:1","allow_additions":true,"allow_activate":true});c.begin_session("s")
 check(Contract.validate_catalog(port.describe_actions()).is_empty(),"Second game uses the common catalog")
 var source=Source.new("switch")
 var jump={"action_id":"jump","parameters":{},"duration_ms":0}
 var left={"action_id":"move_left","parameters":{},"duration_ms":0}
 var intent=source.begin("s","explicit",[left],0,250)
 c.submit(intent);c.step(0)
 check(port.x==-1,"Explicit bad move remains left")
 intent=source.begin("s","explicit",[jump],1,250)
 c.submit(intent);c.submit(intent);c.step(1)
 check(port.jumps==1 and port.velocity_y>0 and not port.grounded,"Jump has one real impulse")
 var after_jump=port.x
 intent=source.begin("s","explicit",[left,jump],2,250)
 c.submit(intent);c.step(2)
 check(port.x==after_jump and port.jumps==1,"Impossible jump rejects the whole pair")
 port.step(2)
 intent=source.begin("s","activate",[],3,250,1);c.submit(intent);c.step(3)
 check(port.x==after_jump+1 and port.jumps==2,"Second game can select a useful combination")
 for path in ["contract","controller","game_port","input_ledger","input_source","selector"]:
  var text=FileAccess.get_file_as_string("res://addons/accessible_controls/core/"+path+".gd")
  check(not "res://scripts/" in text and not "turn_left" in text and not "Stuntcar" in text,"Core has no vehicle dependency: "+path)
 done()
