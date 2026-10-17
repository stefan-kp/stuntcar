extends "res://tests/control/test_base.gd"
const F=preload("res://tests/control/fixtures.gd")
const Drive=preload("res://scripts/vehicle/drive_model.gd")
const Track=preload("res://scripts/track/track_data.gd")
const Port=preload("res://scripts/control/stuntcar_port.gd")
const Verification=preload("res://scripts/track/spatial/verification.gd")
func _initialize()->void:
 var Hints=need("res://scripts/control/stuntcar_hints.gd");var Rules=need("res://scripts/control/stuntcar_rules.gd")
 if Hints==null or Rules==null:done();return
 var m=Drive.new(Track.new());m.refresh_assist();var p=Port.new(m);p.reset("s1");m.refresh_assist()
 var before=JSON.stringify([m.position,m.heading,m.target_speed_mps,m.assist_state()])
 var hints=Hints.read(m,0)
 check(not hints.is_empty() and hints[0].recommended_actions[0]=="turn_right","Direction matches track sign")
 for i in range(20):p.assess({"now_ms":0,"intent":null})
 check(before==JSON.stringify([m.position,m.heading,m.target_speed_mps,m.assist_state()]),"Hint reads never move or authorize")
 check(hints[0].min_speed_mps==null and hints[0].max_speed_mps==null,"Unknown bounds remain null")
 check(hints[0].get("speed_evidence")!="safe_envelope","Assistance target is not a safe maximum")
 var sample={"condition":"exact","element_id":"e","speed_mps":22,"lateral_m":0,"mode":"grounded","min_mps":null,"max_mps":null,"target_mps":22}
 var report={"digest":"hash","status":"tested_samples","samples":[sample]}
 check(Verification.speed_hint(report,"other","e",{"condition":"exact"}).is_empty(),"Old checksum provides no evidence")
 check(Verification.speed_hint(report,"hash","e",{"condition":"other"}).is_empty(),"Sample requires exact condition")
 var state={"condition":"exact","speed_mps":22,"lateral_m":0,"mode":"grounded"}
 check(Verification.speed_hint(report,"hash","e",state).max_mps==null,"Separate samples do not create a range")
 var answer=p.assess({"now_ms":0,"intent":F.intent({"required_actions":[F.action("turn_left")]})})
 var wrong=answer.proposals.filter(func(v):return v.actions==[F.action("turn_left")])
 check(not wrong.is_empty() and wrong[0].available and wrong[0].utility==-0.8,"Requested bad action remains available")
 var synthetic=[{"recommended_actions":["turn_left"],"required_speed_action":"speed_down"}]
 check(Rules.rate([F.action("turn_left")],synthetic).utility==-0.4,"Known missing speed requirement lowers score")
 check(Rules.rate([F.action("turn_left"),F.action("speed_down")],synthetic).utility==0.8,"Pair receives its own score")
 check(Rules.rate([F.action("turn_left"),F.action("speed_up")],synthetic).utility==-0.4,"Wrong pair is not a sum")
 check(Rules.rate([F.action("speed_up")],hints).utility==null,"Unfounded rating remains unknown")
 var d={"session_id":"s1","intent":F.intent({"required_actions":[F.action("turn_right")]}),"actions":[F.action("turn_right")],"assessment_reference":answer}
 m.lateral=1
 check(p.apply(d,1).result=="stale" and m.requested_direction==0,"Apply rechecks actual conditions")
 check(m.requested_direction==0,"Hints never execute without input")
 done()
