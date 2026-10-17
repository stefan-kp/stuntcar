extends "res://tests/spatial/test_base.gd"
const Factory=preload("res://scripts/track/track_factory.gd")
const Cases=preload("res://tests/spatial/full_drive_cases.gd")
const Runner=preload("res://scripts/vehicle/spatial/drive_runner.gd")
const Verification=preload("res://scripts/track/spatial/verification.gd")
const Catalog=preload("res://scripts/track/visuals/model_catalog.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var track=Factory.load_track("res://tracks/06_stuntlabor.json").track
	var car=load("res://scripts/vehicle/car_view.gd").new();root.add_child(car)
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spatial/input_cases.json"))
	for level in ["very_easy","easy"]:
		var profile:Dictionary=load("res://scripts/vehicle/spatial/stunt_assist.gd").profile(level)
		for speed in config.start_speeds_mps:
			track.definition.styles={"road":"neutral","scenery":"neutral"}
			var inputs:Array[Dictionary]=Cases.record(track,level,speed).inputs
			var first:Dictionary=Runner.run(track,profile,inputs,12000,{"speed_mps":speed})
			var digest:=Verification.digest(track,profile)
			track.definition.styles={"road":"contrast","scenery":"contrast"}
			var model=load("res://scripts/vehicle/spatial_drive_model.gd").new(track);model.set_assist_level(level)
			model.state.velocity=-model.state.basis.z*speed;model.sync_fields();car.place(model)
			var controls:Dictionary=Runner.create_controls(model)
			var events:Array[Dictionary]=[];var trace:Array[Dictionary]=[];var cursor:=0
			for tick in range(12000):
				while cursor<inputs.size() and inputs[cursor].tick==tick:
					if inputs[cursor].kind!="held_speed":Runner.apply_input(model,inputs[cursor],controls)
					cursor+=1
				Runner.step_controls(controls,tick);model.step(1.0/60)
				var motion:Array[Dictionary]=model.take_motion_events();events.append_array(motion)
				car.drive(model,1.0/60);car.apply_motion_feedback(model.feedback_state(),motion,1.0/60)
				trace.append(model.state.snapshot())
				if tick%120==0:await process_frame
				if model.finished or model.off_road:break
			check(first.finished and model.finished and first.trace==trace and first.events==events,"two styles and effects preserve full drive %s %.1f"%[level,speed])
			check(Verification.digest(track,profile)==digest,"visual style retains report")
		var digest:=Verification.digest(track,profile)
		track.forms=track.forms.duplicate(true);track.forms.loop_12.points[1][0]+=0.01
		check(Verification.digest(track,profile)!=digest and not Verification.playable(track,profile),"form change invalidates report")
		track.forms.loop_12.points[1][0]-=0.01
	car.queue_free();await process_frame
	check(Catalog.resolve("missing","straight_24",1).fallback,"missing import falls back")
	check(Catalog.resolve("neutral","straight_24",99).fallback,"wrong form version falls back")
	for style in ["neutral","contrast"]:
		var result:Dictionary=Catalog.instantiate_model(Catalog.resolve(style,"straight_24",1),track.forms.straight_24)
		check(result.node!=null and result.report.errors.is_empty(),"new display report "+style)
		if result.node!=null:
			var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();body.add_child(shape);result.node.add_child(body)
			Catalog.remove_collisions(result.node)
			check(result.node.find_children("*","CollisionObject3D",true,false).is_empty(),"foreign collision removed")
			result.node.free()
		var scenery:Dictionary=Catalog.instantiate_scenery(style)
		check(scenery.node!=null,"scenery style loads "+style)
		if scenery.node!=null:scenery.node.free()
	done()
