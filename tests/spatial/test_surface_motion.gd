extends "res://tests/spatial/test_base.gd"
const Forms=preload("res://scripts/track/spatial/form_library.gd")
const Track=preload("res://scripts/track/spatial/spatial_track.gd")
const State=preload("res://scripts/vehicle/spatial/drive_state.gd")
const Motion=preload("res://scripts/vehicle/spatial/surface_motion.gd")
func make_track(id:String):
	var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spatial/straight.json"));d.elements[0].form_id=id
	return Track.new(d,Forms.load_file("res://tracks/forms/stunt_v1.json").forms)
func state_at(track,local:float,speed:float):
	var s=State.new();var f:Dictionary=track.sample(local)
	s.position=f.position;s.basis=f.basis;s.velocity=-f.basis.z*speed;s.element_id=f.element_id;s.local_m=f.local_m;s.distance_m=f.distance_m
	return s
func _initialize()->void:
	var level=make_track("straight_24");var hill=make_track("hill_32")
	var a=state_at(level,3,10);var b=state_at(hill,3,10)
	Motion.step(level,a,{"target_speed_mps":10,"turn_authorized":true},{"accel_cap_mps2":0,"brake_cap_mps2":0},0.1)
	Motion.step(hill,b,{"target_speed_mps":10,"turn_authorized":true},{"accel_cap_mps2":0,"brake_cap_mps2":0},0.1)
	check(b.speed_mps<a.speed_mps,"uphill slows without drive")
	var stopped=state_at(level,0,0);Motion.step(level,stopped,{"target_speed_mps":0},{},0.1)
	check(stopped.position.distance_to(Vector3(0,12,0))<0.0001,"standstill stays fixed")
	Motion.step(level,stopped,{"target_speed_mps":22},{"accel_cap_mps2":10},0.1)
	check(stopped.speed_mps>0 and stopped.position.z<0,"drive accelerates")
	var loop=make_track("loop_12");var slow=state_at(loop,38,1);var before:Vector3=slow.velocity
	Motion.step(loop,slow,{"target_speed_mps":1},{"accel_cap_mps2":0,"brake_cap_mps2":0,"hold_mps2":0},1.0/60)
	check(slow.mode=="airborne","slow inverted car loses contact")
	check(slow.velocity.distance_to(before)<0.01,"contact loss preserves velocity")
	var held=state_at(loop,38,1)
	Motion.step(loop,held,{"target_speed_mps":1},{"hold_mps2":10},1.0/60)
	check(held.mode=="grounded","bounded holding force supports inversion")
	var outside=state_at(level,1,10);outside.lateral_m=3.1
	Motion.step(level,outside,{"target_speed_mps":10},{},1.0/60)
	check(outside.mode=="crashed","outside road not snapped back")
	done()
