extends "res://tests/spatial/test_base.gd"
const Track=preload("res://scripts/track/spatial/spatial_track.gd")
const Forms=preload("res://scripts/track/spatial/form_library.gd")
const Query=preload("res://scripts/track/spatial/surface_query.gd")
func _initialize()->void:
	var forms:Dictionary=Forms.load_file("res://tracks/forms/stunt_v1.json").forms
	var definition:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spatial/straight.json"))
	var track=Track.new(definition,forms)
	check(track.sample(12).position.distance_to(Vector3(0,12,-12))<0.001,"straight distance in meters")
	var hit:Dictionary=Query.sweep(track,Vector3(0,15,-12),Vector3(0,9,-12),["start"])
	check(not hit.is_empty(),"swept landing between ticks")
	if not hit.is_empty():check(absf(hit.fraction-0.5)<0.001,"middle contact time")
	check(Query.sweep(track,Vector3(4,15,-12),Vector3(4,9,-12),["start"]).is_empty(),"contact outside road rejected")
	definition.elements[0].form_id="loop_12";definition.elements[0].kind="loop"
	track=Track.new(definition,forms)
	check(track.length_m>75.0,"loop uses spatial arc length")
	var top:Dictionary=track.sample(38)
	check(top.basis.y.dot(Vector3.UP)<-0.99,"loop top points down")
	check(absf(top.basis.determinant()-1)<0.00001,"orthonormal frame")
	var projected:Dictionary=track.project_near(Vector3(0,12,0),"start",70)
	check(projected.get("local_m",0)>50,"nearby entry must not reset loop progress")
	done()
