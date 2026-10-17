extends "res://tests/control/test_base.gd"
const Legacy=preload("res://scripts/vehicle/drive_model.gd")
const Spatial=preload("res://scripts/vehicle/spatial_drive_model.gd")
const Track=preload("res://scripts/track/track_data.gd")
const Fixtures=preload("res://tests/spatial/fixtures.gd")
func make_model(spatial:bool):
 return Spatial.new(Fixtures.make(["straight_24","straight_24","straight_24","curve_right_45","straight_24"])) if spatial else Legacy.new(Track.new())
func _initialize()->void:
 for spatial in [false,true]:
  for level in ["very_easy","easy"]:
   for direction in [-1,1]:
    var m=make_model(spatial);m.set_assist_level(level)
    if not m.has_method("set_steering_request"):
     check(false,"Directed steering contract is missing");continue
    check(m.set_steering_request(direction,0.5),"Manual request accepted")
    for tick in range(30):m.step(1.0/60.0)
    check(m.lateral*direction>0.1,"Physical manual direction "+str([spatial,level,direction]))
   var m=make_model(spatial);m.set_assist_level(level)
   if not m.has_method("set_steering_request"):continue
   m.refresh_assist();var curve:Dictionary=m.track.curves[0]
   check(m.request_turn(-curve.turn_sign),"Wrong direction remains executable")
   check(m.active_curve_id==-1 and not m.assist_state().authorized,"Wrong direction never authorizes opposite guidance")
   for tick in range(15):m.step(1.0/60.0)
   check(m.lateral*(-curve.turn_sign)>0.02,"Wrong request has physical effect")
   m=make_model(spatial);m.set_assist_level(level);m.request_turn(curve.turn_sign)
   for tick in range(500):
    m.step(1.0/60.0)
    if m.distance_m>curve.end_m+16 or m.off_road:break
   check(not m.off_road and m.distance_m>curve.end_m,"Correct direction preserves guidance "+str([spatial,level,m.distance_m,m.lateral,m.elapsed_s,m.off_road]))
   m=make_model(spatial);m.set_steering_request(1,0.5);m.set_steering_request(-1,0.5)
   for tick in range(20):m.step(1.0/60.0)
   check(m.lateral<0,"Opposite request replaces the old direction")
   m=make_model(spatial);m.hint_seconds=0.01
   check(m.request_turn(-1),"Outside window remains manual")
   for tick in range(15):m.step(1.0/60.0)
   check(m.lateral<0,"Outside window changes physical direction")
 done()
