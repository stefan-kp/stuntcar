extends "res://tests/spatial/test_base.gd"
const Fixtures=preload("res://tests/spatial/fixtures.gd")
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
func _initialize()->void:
	var track=Fixtures.make(["straight_24","straight_24","straight_24","curve_right_45","straight_24","curve_left_45","straight_24"])
	var easy=Drive.new(track);easy.set_assist_level("easy")
	check(not easy.request_assisted_turn(-1,false,"wrong"),"easy rejects wrong direction")
	check(not easy.request_assisted_turn(0,true,"call"),"easy rejects unknown call")
	check(easy.request_assisted_turn(1,false,"right"),"easy accepts correct direction")
	check(not easy.request_assisted_turn(1,false,"right"),"duplicate event rejected")
	var very=Drive.new(track)
	check(very.request_assisted_turn(0,true,"quiet"),"very easy accepts quiet call")
	very.change_speed(1)
	check(very.active_curve_id==0,"speed command does not authorize another curve")
	var silent=Drive.new(track)
	for i in range(600):silent.step(1.0/60.0)
	check(silent.state.mode=="crashed","missing curve input fails")
	var driven=Drive.new(track);driven.request_assisted_turn(1,false,"first")
	for i in range(600):driven.step(1.0/60.0)
	check(driven.state.mode=="crashed","one input cannot authorize second curve")
	driven.reset();check(driven.take_motion_events().is_empty(),"reset clears motion events")
	check(driven.state.attempt_id>1,"reset changes attempt id")
	for level in ["very_easy","easy"]:
		var good=Drive.new(track);good.set_assist_level(level)
		for i in range(900):
			good.refresh_assist()
			var opportunity:Dictionary=good.assist_state()
			if opportunity.phase in ["early","clean"]:good.request_assisted_turn(opportunity.turn_sign,false,"turn:%d"%opportunity.opportunity_id)
			good.step(1.0/60.0)
			if good.state.mode in ["finished","crashed"]:break
		check(good.finished,"complete authorized drive "+level)
	var assisted_track=Fixtures.make(["straight_24","loop_12"])
	var bounded=Drive.new(assisted_track)
	bounded.target_speed_mps=0
	bounded.state.help_used["e1"]=bounded.spatial_profile.help_seconds-0.001
	bounded.step(1.0/60.0)
	check(bounded.state.help_used.e1<=bounded.spatial_profile.help_seconds+0.000001,"help stops exactly at budget boundary")
	var assist=load("res://scripts/vehicle/spatial/stunt_assist.gd")
	bounded.state.help_used.e1=bounded.spatial_profile.help_seconds
	check(not assist.evaluate(assisted_track,bounded.state,bounded.spatial_profile,0).active,"expired help remains off")
	done()
