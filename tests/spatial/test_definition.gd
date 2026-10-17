extends "res://tests/spatial/test_base.gd"
const Definition = preload("res://scripts/track/spatial/track_definition.gd")

func _initialize() -> void:
	var loaded: Dictionary = load("res://scripts/track/spatial/form_library.gd").load_file("res://tracks/forms/stunt_v1.json")
	check(loaded.errors.is_empty() and loaded.forms.size()==9,"nine extracted forms")
	var forms: Dictionary = loaded.forms
	var element := {"id":"start","kind":"straight","form_id":"straight_24","form_version":1,"entry_transform":{"position":[0,12,0],"rotation":[0,0,0,1]},"input":{"kind":"none"},"assist":{},"visual_id":"straight_24"}
	var valid := {"format_version":2,"name":"Test","description":"Route","scenario":"forest","styles":{"road":"neutral","scenery":"neutral"},"elements":[element],"landings":[],"report":"reports/test.json"}
	check(Definition.validate(valid,forms).is_empty(),"valid route")
	var duplicate: Dictionary = valid.duplicate(true)
	duplicate.elements.append(element.duplicate(true))
	check("duplicate_id" in Definition.validate(duplicate,forms),"duplicate ids rejected")
	var version: Dictionary = valid.duplicate(true)
	version.elements[0].form_version=99
	check("form_version" in Definition.validate(version,forms),"unknown form version rejected")
	var invalid: Dictionary = valid.duplicate(true)
	invalid.elements[0].entry_transform.position[0]=INF
	check("transform" in Definition.validate(invalid,forms),"infinite transform rejected")
	invalid=valid.duplicate(true); invalid.elements[0].entry_transform.rotation=[0,0,0,0]
	check("transform" in Definition.validate(invalid,forms),"zero quaternion rejected")
	invalid=valid.duplicate(true);invalid.report="../../private.json"
	check("report_path" in Definition.validate(invalid,forms),"report cannot escape track folder")
	invalid=valid.duplicate(true)
	var next:Dictionary=element.duplicate(true);next.id="next";next.entry_transform.position=[0,12,-24]
	invalid.elements.append(next)
	check(Definition.validate(invalid,forms).is_empty(),"aligned connectors")
	invalid.elements[1].entry_transform.position[0]=0.0011
	check("connection_position" in Definition.validate(invalid,forms),"connector gap rejected")
	invalid.elements[1].entry_transform.position[0]=0.0009
	check(Definition.validate(invalid,forms).is_empty(),"small connector tolerance")
	var loop:Dictionary=forms.loop_12
	check(loop.ups[80][1]<-0.99,"inverted loop top retained")
	done()
