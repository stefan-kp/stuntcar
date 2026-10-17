extends "res://tests/control/test_base.gd"
const F=preload("res://tests/control/fixtures.gd")
const Drive=preload("res://scripts/vehicle/drive_model.gd")
const Track=preload("res://scripts/track/track_data.gd")
const Spatial=preload("res://scripts/vehicle/spatial_drive_model.gd")
const Fixtures=preload("res://tests/spatial/fixtures.gd")
const Contract=preload("res://addons/accessible_controls/core/contract.gd")
func decision(actions:Array,event:String="e1",control:String="c1",phase:String="begin")->Dictionary:
 return {"session_id":"s1","intent":F.intent({"event_id":event,"control_id":control,"source_id":"key","required_actions":actions,"phase":phase}),"actions":actions,"assessment_reference":{}}
func _initialize()->void:
 var Port=need("res://scripts/control/stuntcar_port.gd")
 if Port==null:done();return
 var m=Drive.new(Track.new());var p=Port.new(m);p.reset("s1")
 check(Contract.validate_catalog(p.describe_actions()).is_empty(),"Valid six action catalog")
 check(p.describe_actions().actions.size()==6 and Contract.action_definition(p.describe_actions(),"jump").is_empty(),"No fake jump action")
 var substituted=decision([F.action("turn_left")],"substitute","substitute")
 substituted.actions=[F.action("turn_right")]
 check(p.apply(substituted,0).result=="rejected" and m.requested_direction==0,"Port rejects replacement of explicit direction")
 var target=m.target_speed_mps
 check(p.apply(decision([F.action("speed_up"),F.action("missing")]),0).result=="rejected" and m.target_speed_mps==target,"Combination has no partial start")
 var d=decision([F.action("speed_up")]);check(p.apply(d,0).result=="applied","Pulse applies")
 var changed=m.target_speed_mps;p.apply(d,1);check(m.target_speed_mps==changed,"Pulse applies once")
 d=decision([F.action("speed_down")],"stale");d.assessment_reference=p.context(1);m.distance_m+=1
 check(p.apply(d,2).result=="stale" and m.target_speed_mps==changed,"Stale decision changes nothing")
 d.assessment_reference={};check(p.apply(d,2).result=="applied","Stale retry remains possible")
 p.reset("s2");p.reset("s1")
 d=decision([F.action("pedal_down",150)]);p.apply(d,0);p.advance(0.05,50)
 check(m.active_pedal==-1 and m.target_speed_mps<changed,"Held brake executes")
 target=m.target_speed_mps;p.advance(0.05,151)
 check(m.active_pedal==0 and m.target_speed_mps==target,"Timeout stops changes and preserves target")
 p.apply(decision([F.action("pedal_down",150)],"b1","b"),200)
 p.apply(decision([F.action("pedal_up",150)],"g1","g"),210)
 p.cancel({"session_id":"s1","scope":"execution","execution_id":"s1:key:b"},211)
 p.advance(0.01,212);check(m.active_pedal==1,"Cancel old execution preserves new pedal")
 p.apply(decision([F.action("pedal_down",150)],"b2","b","update"),220);p.advance(0.01,221)
 check(m.active_pedal==1,"Retired pedal cannot return")
 p.cancel({"session_id":"s1","scope":"source","source_id":"key"},222);p.advance(0.01,223)
 check(m.active_pedal==0,"Source cancellation ends active pedals")
 p.reset("s1")
 p.apply(decision([F.action("turn_right"),F.action("pedal_down",150)],"pair","pair"),300)
 p.cancel({"session_id":"s1","scope":"execution","execution_id":"s1:key:pair","action_ids":["pedal_down"]},310)
 p.advance(0.01,311)
 check(m.active_pedal==0 and m.requested_direction==1,"Combination members have separate ends")
 p.cancel({"session_id":"s1","scope":"session"},312)
 check(m.requested_direction==0,"Session cancellation clears pending steering")
 p.reset("s1")
 var older=decision([F.action("turn_left")],"old-same","old-same");older.intent.source_id="voice"
 p.apply(older,400);p.apply(decision([F.action("turn_left")],"new-same","new-same"),401)
 p.cancel({"session_id":"s1","scope":"source","source_id":"voice"},402)
 check(m.requested_direction==-1,"Cancellation of an older same direction preserves the new owner")
 for spatial in [false,true]:
  var model=Spatial.new(Fixtures.make(["straight_24","jump_launch"])) if spatial else Drive.new(Track.new())
  model.target_speed_mps=0;model.set_active_pedal(-1)
  if spatial:
   model.reset(20);model.target_speed_mps=0;model.set_active_pedal(-1)
  model.step(1.0/60.0)
  check(not model.assist_speed_active or model.assist_target_mps<=model.speed_mps,"Explicit brake blocks launch acceleration "+str(spatial))
  model.set_active_pedal(1);model.target_speed_mps=46
  if not spatial:model.request_turn(1);model.recovery_remaining=1
  model.step(1.0/60.0)
  check(not model.assist_speed_active or model.assist_target_mps>=model.speed_mps,"Explicit gas blocks extra brake "+str(spatial))
 done()
