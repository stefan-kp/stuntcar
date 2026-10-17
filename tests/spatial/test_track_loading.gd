extends "res://tests/spatial/test_base.gd"
const Factory=preload("res://scripts/track/track_factory.gd")
const Legacy=preload("res://scripts/track/track_data.gd")
func _initialize()->void:
	call_deferred("run")
func run()->void:
	var old:Dictionary=Factory.load_track("res://tracks/01_erste_fahrt.json")
	check(old.errors.is_empty() and old.track!=null and old.format_version==1,"legacy load unchanged")
	var new:Dictionary=Factory.load_track("res://tests/fixtures/spatial/straight.json")
	check(new.errors.is_empty() and new.track!=null and new.format_version==2,"spatial track loads")
	if new.track!=null:check(absf(new.track.length_m-24)<0.001,"spatial length")
	check(not Factory.load_track("res://missing.json").errors.is_empty(),"missing file reported")
	var path:="user://spatial-invalid.json"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string('{"format_version":88}');file.close()
	check(not Factory.load_track(path).errors.is_empty(),"unsupported version rejected")
	DirAccess.remove_absolute(path)
	var folder:="user://spatial-catalog"
	DirAccess.make_dir_recursive_absolute(folder)
	for entry in [["old.json","res://tracks/01_erste_fahrt.json"],["new.json","res://tests/fixtures/spatial/straight.json"]]:
		var out:=FileAccess.open(folder+"/"+entry[0],FileAccess.WRITE);var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(entry[1]));data.erase("preview");out.store_string(JSON.stringify(data));out.close()
	var catalog:Dictionary=Legacy.scan_catalog(folder)
	check(catalog.routes.size()==2 and catalog.errors.is_empty(),"mixed catalog loads both formats")
	for filename in ["old.json","new.json"]:DirAccess.remove_absolute(folder+"/"+filename)
	DirAccess.remove_absolute(folder)
	var builder=load("res://scripts/track/visuals/spatial_builder.gd").new();root.add_child(builder)
	builder.build(new.track,{"road":"neutral","scenery":"neutral"})
	check(builder.warnings.is_empty(),"matching model builds without warnings")
	check(builder.find_children("*","StaticBody3D",true,false).size()==1,"only canonical road collides")
	builder.queue_free();await process_frame
	done()
