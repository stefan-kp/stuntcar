extends "res://tests/spatial/test_base.gd"
const Factory=preload("res://scripts/track/track_factory.gd")
const Cases=preload("res://tests/spatial/full_drive_cases.gd")
const Runner=preload("res://scripts/vehicle/spatial/drive_runner.gd")
const Verification=preload("res://scripts/track/spatial/verification.gd")
const Catalog=preload("res://scripts/track/visuals/model_catalog.gd")
func _initialize()->void:
	var track=Factory.load_track("res://tracks/06_stuntlabor.json").track
	for level in ["very_easy","easy"]:
		var profile:Dictionary=load("res://scripts/vehicle/spatial/stunt_assist.gd").profile(level)
		var inputs:Array[Dictionary]=Cases.record(track,level).inputs
		var first:Dictionary=Runner.run(track,profile,inputs,12000)
		var digest:=Verification.digest(track,profile)
		track.definition.styles={"road":"contrast","scenery":"contrast"}
		var second:Dictionary=Runner.run(track,profile,inputs,12000)
		check(first.finished and first.trace==second.trace and first.events==second.events,"visual style cannot change movement "+level)
		check(Verification.digest(track,profile)==digest,"visual style retains report")
		track.forms=track.forms.duplicate(true);track.forms.loop_12.points[1][0]+=0.01
		check(Verification.digest(track,profile)!=digest and not Verification.playable(track,profile),"form change invalidates report")
		track.forms.loop_12.points[1][0]-=0.01
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
