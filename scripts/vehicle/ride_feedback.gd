extends RefCounted
var compression:=0.0
var compression_velocity:=0.0
var pitch:=0.0
var roll:=0.0
var seen:Dictionary={}
func reset()->void:
	compression=0;compression_velocity=0;pitch=0;roll=0;seen.clear()
func advance(state:Dictionary,events:Array[Dictionary],dt:float)->Dictionary:
	if state.get("paused",false):return {"compression_m":compression,"pitch_rad":pitch,"roll_rad":roll}
	for event in events:
		if seen.has(event.id):continue
		seen[event.id]=true
		if seen.size()>128:seen.erase(seen.keys()[0])
		if event.type=="landing":compression=minf(0.16,compression+float(event.magnitude)*0.016)
	var remaining:=maxf(0,dt)
	while remaining>0:
		var h:=minf(remaining,1.0/120.0)
		compression_velocity+=(-144.0*compression-24.0*compression_velocity)*h
		compression=clampf(compression+compression_velocity*h,0,0.16);remaining-=h
	var acceleration:Vector3=state.get("accel_local",Vector3.ZERO)
	var tilt:=Vector2(acceleration.z*0.004,-acceleration.x*0.003).limit_length(deg_to_rad(5))
	var response:=1-exp(-8*maxf(dt,0))
	pitch=lerpf(pitch,tilt.x,response);roll=lerpf(roll,tilt.y,response)
	return {"compression_m":compression,"pitch_rad":pitch,"roll_rad":roll}
