extends Camera3D

var initialized := false

func follow(car: Node3D, heading: float, delta: float, overview: bool, pitch: float = 0.0, speed: float = 22.0, boost: float = 0.0) -> void:
	var forward := Vector3(sin(heading), 0, -cos(heading))
	var right := Vector3(cos(heading), 0, sin(heading))
	var destination: Vector3
	var target: Vector3
	if overview:
		destination = car.global_position - forward * 17.0 + right * 13.0 + Vector3.UP * 12.0
		target = car.global_position + forward * 15.0 - right * 6.0
		fov = 58
	else:
		destination = car.global_position - forward * (5.6 + boost * 0.65) + Vector3.UP * (2.35 + maxf(0.0, -sin(pitch)) * 6.0)
		target = car.global_position + forward * 13.0 + Vector3.UP * (0.9 + clampf(tan(pitch) * 10.0, -3.0, 4.0))
		fov = lerpf(fov, lerpf(80.0, 100.0, clampf((speed - 14.0) / 32.0, 0.0, 1.0)) + boost * 7.0, 1.0 - exp(-3.0 * delta))
	if not initialized:
		global_position = destination
		initialized = true
	else:
		global_position = global_position.lerp(destination, 1.0 - exp(-9.0 * delta))
	look_at(target, Vector3.UP)

func follow_spatial(frame:Dictionary,target:Vector3,speed_mps:float,delta:float)->void:
	var surface:Basis=frame.basis
	var forward:Vector3=-surface.z
	var destination:Vector3=target-forward*6.5+surface.y*2.9
	var look:Vector3=target+forward*8+surface.y*0.8
	var desired:Basis=Basis.looking_at((look-destination).normalized(),surface.y)
	var response:=1.0-exp(-12.0*maxf(delta,0))
	if not initialized:
		global_position=destination;global_basis=desired;initialized=true
	else:
		global_position=global_position.lerp(destination,response)
		var a:=global_basis.get_rotation_quaternion();var b:=desired.get_rotation_quaternion()
		if a.dot(b)<0:b=-b
		global_basis=Basis(a.slerp(b,response))
	fov=lerpf(76.0,90.0,clampf(speed_mps/58.0,0,1))
