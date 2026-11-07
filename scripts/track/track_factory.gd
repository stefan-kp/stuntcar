extends RefCounted
const Legacy=preload("res://scripts/track/track_data.gd")
const Forms=preload("res://scripts/track/spatial/form_library.gd")
const Definition=preload("res://scripts/track/spatial/track_definition.gd")
const Spatial=preload("res://scripts/track/spatial/spatial_track.gd")
const Circuit=preload("res://scripts/track/pieces/circuit_builder.gd")
static func load_track(path:String)->Dictionary:
	var report:Dictionary=Legacy.read_definition(path)
	if not report.error.is_empty():return {"track":null,"errors":[report.error],"format_version":0}
	var d:Dictionary=report.data
	if d.get("format_version",1)==1:return {"track":Legacy.new(path),"errors":[],"format_version":1}
	if d.get("format_version")==3:
		var built:Dictionary=Circuit.load_track(d,path)
		if built.track!=null:built.track.preview_path=path.get_base_dir().path_join(d.preview) if d.get("preview","")!="" else Legacy.Scenarios.preview(built.track.scenario)
		return {"track":built.track,"errors":built.errors,"format_version":3}
	var library:Dictionary=Forms.load_file("res://tracks/forms/stunt_v1.json")
	if not library.errors.is_empty():return {"track":null,"errors":library.errors,"format_version":2}
	var track=Spatial.new(d,library.forms);track.source_path=path
	track.preview_path=Legacy.Scenarios.preview(track.scenario)
	return {"track":track,"errors":[],"format_version":2}
