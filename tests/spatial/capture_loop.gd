extends SceneTree
const Fixtures=preload("res://tests/spatial/fixtures.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(1280,800)
	var track=Fixtures.make(["loop_12","straight_24"])
	var builder=load("res://scripts/track/visuals/spatial_builder.gd").new();root.add_child(builder);builder.build(track,{"road":"contrast","scenery":"neutral"})
	var car=load("res://scripts/vehicle/car_view.gd").new();root.add_child(car)
	var camera=load("res://scripts/camera/follow_camera.gd").new();root.add_child(camera);camera.current=true;camera.far=1800
	for s in [0.0,19.0,38.0,57.0,76.0,85.0]:
		var frame:Dictionary=track.sample(s);car.place_spatial(frame);camera.initialized=false;camera.follow_spatial(frame,frame.position,25,1.0/60)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/stuntcar-loop-%03d.png"%int(s))
	print("Saved six loop images to /private/tmp/stuntcar-loop-*.png")
	builder.queue_free();car.queue_free();camera.queue_free();await process_frame;quit()
