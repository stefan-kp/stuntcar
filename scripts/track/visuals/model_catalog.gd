extends RefCounted
const Validator=preload("res://scripts/track/visuals/model_validator.gd")
static func resolve(style:String,id:String,version:int,form_id:String="")->Dictionary:
	if form_id.is_empty():form_id=id
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/stuntcar_styles/catalog.json"))
	var key:=style+"/"+id
	if data is Dictionary and data.get("models") is Dictionary and data.models.has(key):
		var entry:Dictionary=data.models[key]
		if entry.form_version==version and entry.form_id==form_id and ResourceLoader.exists(entry.scene_path):
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

static func instantiate_scenery(style:String)->Dictionary:
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/stuntcar_styles/catalog.json"))
	var entry:Dictionary=data.get("scenery",{}).get(style,{})
	if entry.is_empty() or not ResourceLoader.exists(entry.get("scene_path","")):return {"node":null,"errors":["scenery_unavailable"]}
	var node=load(entry.scene_path).instantiate()
	if not node is Node3D or not node.transform.is_equal_approx(Transform3D.IDENTITY):
		node.free();return {"node":null,"errors":["scenery_transform"]}
	remove_collisions(node)
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh==null:continue
		var transform:=Transform3D.IDENTITY;var part:Node3D=mesh
		while part!=node:transform=part.transform*transform;part=part.get_parent()
		var bounds:AABB=mesh.mesh.get_aabb()
		for index in range(8):
			var p:Vector3=transform*bounds.get_endpoint(index)
			if absf(p.x)>entry.radius_m or absf(p.z)>entry.radius_m or p.y<0 or p.y>entry.height_m:
				node.free();return {"node":null,"errors":["scenery_bounds"]}
	return {"node":node,"errors":[]}
