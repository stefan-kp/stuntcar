extends RefCounted
const Validator=preload("res://scripts/track/visuals/model_validator.gd")
static func resolve(style:String,id:String,version:int)->Dictionary:
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/stuntcar_styles/catalog.json"))
	var key:=style+"/"+id
	if data is Dictionary and data.get("models") is Dictionary and data.models.has(key):
		var entry:Dictionary=data.models[key]
		if entry.form_version==version and entry.form_id==id and ResourceLoader.exists(entry.scene_path):
			var result:=entry.duplicate(true);result.merge({"fallback":false,"errors":[]});return result
	return {"scene_path":"","fallback":true,"errors":["model_unavailable:"+key]}
static func remove_collisions(node:Node)->void:
	for child in node.get_children():
		if child is CollisionObject3D or child is CollisionShape3D:
			node.remove_child(child);child.free()
		else:remove_collisions(child)
static func instantiate_model(entry:Dictionary,form:Dictionary)->Dictionary:
	if entry.fallback:return {"node":null,"errors":entry.errors}
	var node=load(entry.scene_path).instantiate()
	node.set_meta("surface_meshes",entry.surface_meshes)
	var report:Dictionary=Validator.check_scene(node,form)
	if not report.errors.is_empty():node.free();return {"node":null,"errors":report.errors,"report":report}
	remove_collisions(node)
	return {"node":node,"errors":[],"report":report}
