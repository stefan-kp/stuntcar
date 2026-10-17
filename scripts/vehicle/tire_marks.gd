extends Node3D
var marks:Array[Dictionary]=[]
var new_mark_count:=0
var previous:Array=[]
var material:StandardMaterial3D
func _ready()->void:
	top_level=true;global_transform=Transform3D.IDENTITY
	material=StandardMaterial3D.new();material.albedo_color=Color(0.04,0.05,0.06,0.5)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED
func reset()->void:
	for entry in marks:entry.node.queue_free()
	marks.clear();previous.clear();new_mark_count=0
func advance(state:Dictionary,dt:float)->void:
	new_mark_count=0
	if state.get("paused",false):return
	for entry in marks:entry.age+=dt;entry.node.visible=entry.age<12.0
	var points:Array=state.get("wheel_contacts",[])
	if not state.get("grounded",false) or not (state.get("braking",false) or state.get("slip_mps",0)>0.8):previous=points.duplicate();return
	var normal:Vector3=state.get("normal",Vector3.UP)
	if previous.size()==points.size():
		for i in range(points.size()):
			var a:Vector3=previous[i];var b:Vector3=points[i]
			if a.distance_to(b)<0.07 or a.distance_to(b)>5:continue
			var side:Vector3=(b-a).normalized().cross(normal)*0.1
			a+=normal*0.012;b+=normal*0.012
			var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
			for v in [a-side,b+side,a+side,a-side,b-side,b+side]:mesh.add_vertex(v)
			var entry:Dictionary
			if marks.size()<256:
				var node:=MeshInstance3D.new();node.material_override=material;add_child(node)
				entry={"node":node,"age":0.0};marks.append(entry)
			else:
				entry=marks.pop_front();entry.age=0.0;marks.append(entry)
			entry.node.mesh=mesh.commit();entry.node.visible=true;new_mark_count+=1
	previous=points.duplicate()
