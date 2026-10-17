extends "res://tests/spatial/test_base.gd"
const Factory=preload("res://scripts/track/track_factory.gd")
const State=preload("res://scripts/vehicle/spatial/drive_state.gd")
const Flight=preload("res://scripts/vehicle/spatial/flight_motion.gd")
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
func jump(track,speed:float,side:float=0)->bool:
	var launch:Dictionary=track.by_id.e11;var f:Dictionary=track.sample_element("e11",launch.length_m)
	var state=State.new();state.position=f.position+f.basis.x*side;state.basis=f.basis;state.velocity=-f.basis.z*speed;state.mode="airborne";state.element_id="e11";state.local_m=launch.length_m
	for tick in range(300):
		var result:Dictionary=Flight.step(track,state,{},1.0/60)
		if result.landed:return true
		if result.crashed:return false
	return false
func _initialize()->void:
	var track=Factory.load_track("res://tracks/06_stuntlabor.json").track
	var low:=18.0;var high:=21.0
	for i in range(14):
		var mid:=(low+high)*0.5
		if jump(track,mid):high=mid
		else:low=mid
	check(not jump(track,low-0.1) and jump(track,high+0.1),"measured lower jump threshold +/-0.1")
	var upper_low:=21.0;var upper_high:=40.0
	for i in range(14):
		var mid:=(upper_low+upper_high)*0.5
		if jump(track,mid):upper_low=mid
		else:upper_high=mid
	check(jump(track,upper_low-0.1) and not jump(track,upper_high+0.1),"measured upper jump threshold +/-0.1")
	print("Measured upper jump threshold: ",upper_low,"..",upper_high," m/s")
	print("Measured lower jump threshold: ",low,"..",high," m/s")
	check(jump(track,21,2.99) and not jump(track,21,3.01),"actual landing width +/-0.01 m")
	for level in ["very_easy","easy"]:
		var model=Drive.new(track);model.set_assist_level(level);model.reset(track.by_id.e16.start_m+30)
		model.target_speed_mps=0
		var budget:float=model.spatial_profile.help_seconds
		model.state.help_used.e16=budget-1.0/60
		model.step(1.0/60)
		check(float(model.state.help_used.e16)<=budget+0.000001,"help ends at exact tick budget")
		model.step(1.0/60)
		check(float(model.state.help_used.e16)<=budget+0.000001,"one later tick cannot renew help")
	var flat=load("res://tests/spatial/fixtures.gd").make(["straight_24"])
	flat.definition.landings=[{"launch_id":"launch","target_ids":["e0"],"max_angle_degrees":20.0,"max_impact_mps":12.0}]
	for impact in [11.9,12.1]:
		var state=State.new();state.position=Vector3(0,12.0001,-5);state.velocity=Vector3(0,-impact,-40);state.element_id="launch";state.mode="airborne"
		var result:Dictionary=Flight.step(flat,state,{},1.0/60)
		check(result.landed if impact<12 else result.crashed,"impact boundary +/-0.1 m/s")
	for angle in [19.9,20.1]:
		var state=State.new();state.position=Vector3(0,12.00001,-5);state.velocity=Vector3(sin(deg_to_rad(angle))*100,-0.001,-cos(deg_to_rad(angle))*100);state.element_id="launch";state.mode="airborne"
		var result:Dictionary=Flight.step(flat,state,{},1.0/60)
		check(result.landed if angle<20 else result.crashed,"landing angle boundary +/-0.1 degrees")
	done()
