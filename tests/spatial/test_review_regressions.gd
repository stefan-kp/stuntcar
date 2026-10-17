extends "res://tests/spatial/test_base.gd"
const Factory=preload("res://scripts/track/track_factory.gd")
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
const Verification=preload("res://scripts/track/spatial/verification.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var track=Factory.load_track("res://tracks/06_stuntlabor.json").track
	var model=Drive.new(track);model.reset(5);model.refresh_assist()
	var condition:=Verification.condition(model)
	model.reset(5);model.refresh_assist()
	check(Verification.condition(model)==condition,"restart preserves equivalent driving condition")
	for level in ["very_easy","easy"]:
		for attempt in range(2):
			model.set_assist_level(level);model.reset(5)
			var matches:=0
			for tick in range(6000):
				model.refresh_assist();var hint:Dictionary=model.assist_state()
				if hint.phase in ["early","clean"]:model.request_turn(hint.turn_sign,0.5,"turn:%d"%hint.opportunity_id)
				if not model.verified_speed_hint().is_empty():matches+=1
				model.step(1.0/60);model.take_motion_events()
				if model.finished or model.off_road:break
			check(model.finished and matches>0,"published hints reachable after actual restart "+level)
	model.reset(track.by_id.e7.start_m+0.1);model.refresh_assist()
	var hint:Dictionary=model.assist_state()
	check(model.request_turn(hint.turn_sign,0.5,"late"),"late input accepted")
	model.step(1.0/60)
	check(model.assist_target_mps<=10 and model.assist_speed_active,"display matches actual rescue target")
	for i in range(100):model.step(1.0/60)
	check(model.recovery_remaining==0 and model.motion=="normal","rescue display ends with rescue")
	model.reset(5)
	check(model.motion=="normal" and model.steering_input==0 and not model.assist_speed_active,"reset clears presentation fields")
	var car=load("res://scripts/vehicle/car_view.gd").new();root.add_child(car)
	var contact:={"grounded":true,"braking":true,"wheel_contacts":[Vector3.ZERO],"normal":Vector3.UP}
	car.tire_marks.advance(contact,1.0/60);contact.wheel_contacts=[Vector3(0,0,-0.2)];car.tire_marks.advance(contact,1.0/60)
	check(car.tire_marks.marks.size()>0,"mark exists before route change")
	var legacy=load("res://scripts/vehicle/drive_model.gd").new(Factory.load_track("res://tracks/01_erste_fahrt.json").track)
	car.place(legacy);check(car.tire_marks.marks.is_empty(),"legacy route change removes spatial marks")
	var scene=load("res://scenes/main.tscn").instantiate();scene.settings_path="/private/tmp/stuntcar-review-regression.cfg"
	root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
	scene.select_track("res://tracks/06_stuntlabor.json")
	scene.track.by_id.e0.visual_id="missing_variant"
	scene.builder.free();scene.build_selected_track()
	check(not scene.builder.warnings.is_empty(),"visual id selects actual model")
	check(scene.session.get("visual_warnings")!=null and not scene.session.get("visual_warnings").is_empty(),"model warning reaches player")
	var audio=scene.race_audio;var played:Array=[];audio.effect_played.connect(func(kind):played.append(kind))
	scene.session.state="RUNNING";scene.session.sound_enabled=true
	var boost:Array[Dictionary]=[{"id":"boost:1","type":"boost_start","magnitude":8.0}]
	audio.apply_motion_events(boost,scene.session);audio.apply_motion_events(boost,scene.session)
	check(played.count("boost")==1,"actual thrust produces one sound")
	check(audio.boost.playing and audio.boost.volume_db>-70,"thrust sound has audible stream")
	var muted:Array[Dictionary]=[{"id":"boost:2","type":"boost_start","magnitude":8.0}]
	scene.session.sound_enabled=false;audio.apply_motion_events(muted,scene.session)
	scene.session.sound_enabled=true;audio.apply_motion_events(muted,scene.session)
	check(played.count("boost")==1,"muted thrust cannot replay later")
	await create_timer(0.2).timeout
	audio.reset();await create_timer(0.2).timeout
	car.queue_free();scene.queue_free();model=null;legacy=null;await process_frame;done()
