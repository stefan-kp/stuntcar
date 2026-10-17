extends "res://tests/control/test_base.gd"
const Router=preload("res://scripts/input/command_router.gd")
const Drive=preload("res://scripts/vehicle/drive_model.gd")
const Track=preload("res://scripts/track/track_data.gd")
var now=0
func _initialize()->void:
 var m=Drive.new(Track.new());var s=Router.new(m)
 if not s.has_method("capture_key"):check(false,"Session lacks the common input path");done();return
 s.control_clock=func():return now
 s.capture_key(KEY_D,true);s.press(1)
 s.step(1.0/60.0)
 check(s.state=="RUNNING" and m.last_command==0,"Menu start never steers")
 s.capture_key(KEY_D,false);s.capture_key(KEY_D,true);s.step(1.0/60.0)
 check(m.last_command==1,"Fresh key uses common action")
 s.capture_key(KEY_W,true);now+=10;s.step(0.1)
 check(is_equal_approx(m.target_speed_mps,23),"Keyboard pedal runs once per step")
 s.pause();var target=m.target_speed_mps;s.activate(0);now+=60;s.step(0.1)
 check(m.target_speed_mps==target,"Pause requires a fresh press")
 s.capture_key(KEY_W,false);s.capture_key(KEY_W,true);now+=10;s.step(0.1)
 check(m.target_speed_mps>target,"Release and fresh press reactivate pedal")
 s.lose_control_source("keyboard");target=m.target_speed_mps;now+=60;s.step(0.1)
 check(m.target_speed_mps==target,"Source loss releases held actions")
 var old=s.control_session;m.reset(90);s.ensure_controls()
 check(s.control_session!=old,"Checkpoint reset creates a new session")
 old=s.control_session;s.model=Drive.new(Track.new());s.ensure_controls()
 check(s.control_session!=old and s.control_port.model==s.model,"Model swap replaces port and session")
 s.restart();s.submit_voice("left");check(s.model.last_command==-1 and s.model.active_curve_id==-1,"Explicit voice direction uses the same action")
 s.submit_voice("faster");target=s.model.target_speed_mps
 s.lose_control_source("voice");s.step(0.1)
 check(s.model.target_speed_mps==target,"Voice loss preserves stored target")
 done()
