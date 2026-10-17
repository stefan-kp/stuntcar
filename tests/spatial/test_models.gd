extends "res://tests/spatial/test_base.gd"
const Forms=preload("res://scripts/track/spatial/form_library.gd")
const Validator=preload("res://scripts/track/visuals/model_validator.gd")
const Catalog=preload("res://scripts/track/visuals/model_catalog.gd")
func _initialize()->void:
	var f:Dictionary=Forms.load_file("res://tracks/forms/stunt_v1.json").forms.straight_24
	var node=load("res://assets/stuntcar_kit/track/straight_24.tscn").instantiate()
	check(Validator.check_scene(node,f).errors.is_empty(),"matching road accepted")
	node.get_node("Exit").position.x=0.0011
	check(not Validator.check_scene(node,f).errors.is_empty(),"connector offset rejected")
	node.get_node("Exit").position.x=0.0009
	check(Validator.check_scene(node,f).errors.is_empty(),"connector tolerance accepted")
	node.get_node("Road").position.y=0.021
	check(not Validator.check_scene(node,f).errors.is_empty(),"same ends wrong surface rejected")
	node.get_node("Road").position.y=0.019
	check(Validator.check_scene(node,f).errors.is_empty(),"surface tolerance accepted")
	node.scale.x=-1
	check(not Validator.check_scene(node,f).errors.is_empty(),"mirrored model rejected")
	check(Catalog.resolve("missing","straight_24",1).fallback,"missing style uses fallback")
	check(Catalog.resolve("neutral","straight_24",99).fallback,"wrong version uses fallback")
	node.free()
	var forms:Dictionary=Forms.load_file("res://tracks/forms/stunt_v1.json").forms
	for style in ["neutral","contrast"]:
		for id in forms:
			var model:Dictionary=Catalog.instantiate_model(Catalog.resolve(style,id,1),forms[id])
			check(model.errors.is_empty(),"import "+style+"/"+id+": "+str(model.get("report",model.errors)))
			if model.node!=null:
				check(model.node.find_children("*","CollisionObject3D",true,false).is_empty(),"visual collisions removed")
				model.node.free()
	done()
