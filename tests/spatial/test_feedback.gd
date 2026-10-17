extends "res://tests/spatial/test_base.gd"
const Feedback=preload("res://scripts/vehicle/ride_feedback.gd")
const Marks=preload("res://scripts/vehicle/tire_marks.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var sample:={"grounded":true,"accel_local":Vector3.ZERO,"slip_mps":0.0,"braking":false,"boosting":false,"surface_kind":"asphalt","wheel_contacts":[Vector3.ZERO,Vector3.RIGHT],"paused":false}
	var a=Feedback.new();var b=Feedback.new()
	var soft:Array[Dictionary]=[{"id":"1:1:1","type":"landing","magnitude":2.0}]
	var hard:Array[Dictionary]=[{"id":"1:1:1","type":"landing","magnitude":10.0}]
	var gentle:Dictionary=a.advance(sample,soft,1.0/60.0);var strong:Dictionary=b.advance(sample,hard,1.0/60.0)
	check(strong.compression_m>gentle.compression_m and strong.compression_m<=0.16,"harder impact has bounded stronger compression")
	sample.paused=true
	check(b.advance(sample,hard,1).compression_m==strong.compression_m,"pause freezes feedback")
	sample.paused=false;sample.accel_local=Vector3(20,0,20)
	var leaned:Dictionary=b.advance(sample,[],0.2)
	check(absf(leaned.pitch_rad)>0 and absf(leaned.roll_rad)>0,"actual acceleration controls pitch and roll")
	var marks=Marks.new();root.add_child(marks)
	sample.braking=true
	for i in range(400):
		sample.wheel_contacts=[Vector3(0,0,-i*0.1),Vector3(1,0,-i*0.1)]
		marks.advance(sample,1.0/60)
	check(marks.marks.size()>0 and marks.marks.size()<=256,"marks bounded during long slide")
	sample.grounded=false;marks.advance(sample,1.0/60)
	check(marks.new_mark_count==0,"airborne car leaves no marks")
	marks.reset();check(marks.marks.is_empty(),"reset removes old marks")
	var audio=load("res://scripts/audio/race_audio.gd").new();root.add_child(audio)
	var model=load("res://scripts/vehicle/spatial_drive_model.gd").new(load("res://tests/spatial/fixtures.gd").make(["straight_24"]))
	var session=load("res://scripts/input/command_router.gd").new(model);session.state="RUNNING"
	var played:Array=[];audio.effect_played.connect(func(kind):played.append(kind))
	check(audio.has_method("apply_motion_events"),"audio consumes shared movement events")
	if audio.has_method("apply_motion_events"):
		session.sound_enabled=false;audio.apply_motion_events(hard,session)
		session.sound_enabled=true;audio.apply_motion_events(hard,session)
		check(played.is_empty(),"mute consumes event without delayed replay")
		var next:Array[Dictionary]=[{"id":"1:2:1","type":"landing","magnitude":4.0}]
		session.state="PAUSED";audio.apply_motion_events(next,session);check(played.is_empty(),"pause does not play landing")
		session.state="RUNNING";audio.apply_motion_events(next,session);audio.apply_motion_events(next,session)
		check(played.size()==1,"resumed landing plays once")
	await create_timer(0.2).timeout
	audio.reset();await create_timer(0.2).timeout
	marks.queue_free();audio.queue_free();session=null;model=null;await process_frame;done()
