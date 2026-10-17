extends SceneTree
const Factory=preload("res://scripts/track/track_factory.gd")
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
var frames:Array[float]=[]
var index:=0
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,800);Engine.max_fps=0
	DirAccess.make_dir_recursive_absolute("/private/tmp/stuntcar-film")
	var track=Factory.load_track("res://tracks/06_stuntlabor.json").track
	var builder=load("res://scripts/track/visuals/spatial_builder.gd").new();root.add_child(builder);builder.build(track,{"road":"contrast","scenery":"neutral"})
	var car=load("res://scripts/vehicle/car_view.gd").new();root.add_child(car)
	var camera=load("res://scripts/camera/follow_camera.gd").new();root.add_child(camera);camera.current=true;camera.far=1800
	for case in ["clean","late","hard"]:
		var model=Drive.new(track)
		if case=="late":model.reset(track.by_id.e7.start_m-24)
		if case=="hard":
			model.reset(track.by_id.e12.start_m+1);model.state.position+=model.state.basis.y*0.5;model.state.velocity=-model.state.basis.z*30-model.state.basis.y*8;model.state.mode="airborne";model.state.element_id="e11"
		car.place(model);camera.initialized=false
		for tick in range(2400):
			model.refresh_assist();var hint:Dictionary=model.assist_state()
			if hint.phase in (["late"] if case=="late" else ["early","clean"]):model.request_turn(hint.turn_sign,0.5,"turn:%d"%hint.opportunity_id)
			model.step(1.0/60);var events:Array[Dictionary]=model.take_motion_events()
			car.drive(model,1.0/60);car.apply_motion_feedback(model.feedback_state(),events,1.0/60)
			camera.follow_spatial({"basis":car.global_basis},car.global_position,model.speed_mps,1.0/60)
			if tick%4==0:
				var start:=Time.get_ticks_usec()
				await process_frame;await RenderingServer.frame_post_draw
				frames.append((Time.get_ticks_usec()-start)/1000.0)
				root.get_texture().get_image().save_png("/private/tmp/stuntcar-film/%05d.png"%index);index+=1
			if not events.is_empty():
				for event in events:
					if event.type=="landing":print(case," landing magnitude ",event.magnitude)
			if model.finished or model.off_road or case=="late" and tick>220 or case=="hard" and tick>100:break
	frames.sort()
	var file:=FileAccess.open("/private/tmp/stuntcar-film/metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"resolution":[1280,800],"frames":frames.size(),"median_render_wait_ms":frames[frames.size()/2],"p95_render_wait_ms":frames[int(frames.size()*0.95)],"method":"wall wait for drawn frame; includes scheduling, excludes PNG write; not FPS benchmark"},"\t"));file.close()
	builder.queue_free();car.queue_free();camera.queue_free();await process_frame;quit()
