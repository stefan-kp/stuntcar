extends "res://tests/spatial/test_base.gd"
const Track=preload("res://scripts/track/spatial/spatial_track.gd")
const Forms=preload("res://scripts/track/spatial/form_library.gd")
const State=preload("res://scripts/vehicle/spatial/drive_state.gd")
const Flight=preload("res://scripts/vehicle/spatial/flight_motion.gd")
func state_at(p:Vector3,v:Vector3):
	var s=State.new();s.position=p;s.velocity=v;s.element_id="launch";s.mode="airborne";return s
func _initialize()->void:
	var definition:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spatial/straight.json"))
	definition.landings=[{"launch_id":"launch","target_ids":["start"],"max_angle_degrees":80,"max_impact_mps":12}]
	var track=Track.new(definition,Forms.load_file("res://tracks/forms/stunt_v1.json").forms)
	var slow=state_at(Vector3(0,30,0),Vector3(0,3,-10));var fast=state_at(Vector3(0,30,0),Vector3(0,3,-20))
	Flight.step(track,slow,{},0.5);Flight.step(track,fast,{},0.5)
	check(fast.position.z<slow.position.z,"faster takeoff flies farther")
	check(absf(slow.velocity.z+10)<0.0001,"no tire braking in air")
	check(slow.velocity.y<3,"gravity changes vertical speed")
	var landing=state_at(Vector3(0,13,-5),Vector3(0,-5,-10))
	var hit:Dictionary=Flight.step(track,landing,{},0.3)
	check(hit.landed and landing.mode=="grounded","swept landing before end of tick")
	if hit.landed:check(hit.impact_mps>5 and hit.remaining_s>0,"impact and remaining time recorded")
	var miss=state_at(Vector3(4,13,-5),Vector3(0,-5,-10))
	check(not Flight.step(track,miss,{},0.3).landed,"missed road not corrected")
	var hard=state_at(Vector3(0,13,-5),Vector3(0,-30,-10))
	check(Flight.step(track,hard,{},0.1).crashed,"excessive impact rejected")
	var wrong=state_at(Vector3(0,13,-5),Vector3(0,-5,10));wrong.basis=Basis(Vector3.UP,PI)
	check(Flight.step(track,wrong,{},0.3).crashed,"wrong landing direction rejected")
	for speed in [1.0,100.0]:
		var outside=state_at(Vector3(0,15,8),Vector3(0,0,-speed))
		var landed:=false
		for i in range(180):
			var outcome:Dictionary=Flight.step(track,outside,{},1.0/60.0)
			landed=landed or outcome.landed
			if outside.mode!="airborne":break
		check(not landed,"too short/long approach misses landing")
	done()
