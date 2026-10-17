extends "res://tests/spatial/test_base.gd"
func _initialize()->void:call_deferred("run")
func run()->void:
	var car=load("res://scripts/vehicle/car_view.gd").new();root.add_child(car)
	var state:={"normal":Vector3.UP,"grounded":true,"accel_local":Vector3(0,0,4),"slip_mps":1.0,"braking":true,"boosting":false,"surface_kind":"asphalt","wheel_contacts":[],"paused":false}
	var empty:Array[Dictionary]=[];var peak:=0
	for tick in range(36000):
		state.wheel_contacts=[Vector3(0,0,-tick*0.1),Vector3(1,0,-tick*0.1)]
		car.apply_motion_feedback(state,empty,1.0/60)
		peak=maxi(peak,car.tire_marks.marks.size())
		if tick%60==0:await process_frame
	check(peak<=256 and car.tire_marks.get_child_count()<=256,"ten simulated minutes keep at most 256 marks")
	var particles:=0
	for emitter in car.effects.smoke:particles+=emitter.amount
	check(particles<=128,"fixed particle allocation remains bounded")
	state.grounded=false;car.apply_motion_feedback(state,empty,1.0/60)
	check(car.tire_marks.new_mark_count==0,"no airborne marks after long run")
	for emitter in car.effects.smoke:check(not emitter.emitting,"no airborne tire smoke")
	print("Simulated seconds: 600, peak marks: ",peak,", particles: ",particles)
	car.queue_free();await process_frame;done()
