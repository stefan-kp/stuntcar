extends Node3D
const Catalog=preload("res://scripts/track/visuals/model_catalog.gd")
const Scenery=preload("res://scripts/track/visuals/stunt_scenery.gd")
const Road=preload("res://scripts/track/visuals/road_mesh.gd")
var landscape:Node3D
var warnings:Array[String]=[]
func build(track,styles:Dictionary)->void:
	for child in get_children():remove_child(child);child.queue_free()
	warnings.clear()
	for element in track.elements:
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for face in track.triangles(element.id):
			for v in [face.a,face.b,face.c]:surface.set_normal(face.normal);surface.add_vertex(v)
		var mesh:=surface.commit()
		var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0
		var shape:=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();body.add_child(shape);add_child(body)
		if element.visual_id=="procedural":
			add_child(Road.build_element(element,styles.road));continue
		var entry:Dictionary=Catalog.resolve(styles.road,element.visual_id,element.form_version,element.form_id)
		var model:Dictionary=Catalog.instantiate_model(entry,track.forms[element.form_id])
		if model.node!=null:
			add_child(model.node);model.node.transform=element.transform
		else:
			for error in model.errors:warnings.append(element.id+" ("+element.visual_id+"): "+str(error))
			var fallback:=MeshInstance3D.new();fallback.mesh=mesh
			var mat:=StandardMaterial3D.new();mat.albedo_color=Color("466576");mat.cull_mode=BaseMaterial3D.CULL_DISABLED
			fallback.material_override=mat;add_child(fallback)
	if track.elements.any(func(e):return e.visual_id=="procedural"):add_child(Road.build_pillars(track,styles.road))
	landscape=Scenery.new();add_child(landscape);landscape.build(track,styles.get("scenery","neutral"))
