extends "res://tests/spatial/test_base.gd"
const Fixtures=preload("res://tests/spatial/fixtures.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var track=Fixtures.make(["loop_12","straight_24"])
	var camera=load("res://scripts/camera/follow_camera.gd").new();root.add_child(camera)
	var last:=Quaternion.IDENTITY
	for i in range(401):
		var f:Dictionary=track.sample(i*0.25)
		camera.follow_spatial(f,f.position,25,1.0/60.0)
		check(camera.global_position.is_finite() and absf(camera.basis.determinant()-1)<0.00001,"finite camera frame")
		if i>0:check(last.angle_to(camera.basis.get_rotation_quaternion())<0.2,"no sudden camera side switch")
		last=camera.basis.get_rotation_quaternion()
	camera.initialized=false
	var top:Dictionary=track.sample(38)
	camera.follow_spatial(top,top.position,0,1.0/60.0)
	check(camera.basis.y.dot(Vector3.UP)<-0.8,"camera follows inverted road at rest")
	var car=load("res://scripts/vehicle/car_view.gd").new();root.add_child(car)
	car.place_spatial(top)
	check(car.basis.y.dot(Vector3.UP)<-0.99,"car uses inverted surface basis")
	check(car.position.distance_to(top.position)<0.1,"car position agrees with physics")
	car.queue_free();camera.queue_free();await process_frame;done()
