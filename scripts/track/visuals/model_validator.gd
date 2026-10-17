extends RefCounted
const Forms=preload("res://scripts/track/spatial/form_library.gd")
const Track=preload("res://scripts/track/spatial/spatial_track.gd")
static func relative(node:Node3D,root:Node3D)->Transform3D:
	var t:=node.transform;var parent=node.get_parent()
	while parent!=null and parent!=root:
		if parent is Node3D:t=parent.transform*t
		parent=parent.get_parent()
	return t
static func triangle_distance(p:Vector3,a:Vector3,b:Vector3,c:Vector3)->float:
	var normal:Vector3=(b-a).cross(c-a)
	if normal.length_squared()<1e-16:return INF
	normal=normal.normalized()
	var projected:Vector3=p-normal*(p-a).dot(normal)
	if (b-a).cross(projected-a).dot(normal)>=-0.0000001 and (c-b).cross(projected-b).dot(normal)>=-0.0000001 and (a-c).cross(projected-c).dot(normal)>=-0.0000001:
		return absf((p-a).dot(normal))
	return minf(p.distance_to(Geometry3D.get_closest_point_to_segment(p,a,b)),minf(p.distance_to(Geometry3D.get_closest_point_to_segment(p,b,c)),p.distance_to(Geometry3D.get_closest_point_to_segment(p,c,a))))
static func check_scene(root:Node3D,form:Dictionary)->Dictionary:
	var errors:Array[String]=[];var samples:=0
	if not root.transform.is_equal_approx(Transform3D.IDENTITY):errors.append("root_transform")
	for key in ["Entry","Exit"]:
		var marker=root.get_node_or_null(NodePath(key))
		if not marker is Node3D:errors.append("marker_missing:"+key);continue
		var actual:=relative(marker,root);var expected:=Forms.pose(form[key.to_lower()])
		if actual.origin.distance_to(expected.origin)>0.001:errors.append("marker_position:"+key)
		if not actual.basis.get_scale().is_equal_approx(Vector3.ONE) or actual.basis.determinant()<0:errors.append("marker_scale:"+key)
		elif actual.basis.get_rotation_quaternion().angle_to(expected.basis.get_rotation_quaternion())>deg_to_rad(0.1):errors.append("marker_rotation:"+key)
	var faces:PackedVector3Array=[]
	for path in root.get_meta("surface_meshes",["Road"]):
		var mesh=root.get_node_or_null(NodePath(path))
		if not mesh is MeshInstance3D or mesh.mesh==null:errors.append("surface_missing");continue
		var transform:=relative(mesh,root)
		if transform.basis.determinant()<0 or not transform.basis.get_scale().is_equal_approx(Vector3.ONE):errors.append("surface_scale")
		for vertex in mesh.mesh.get_faces():faces.append(transform*vertex)
	if faces.is_empty():errors.append("surface_empty")
	if not errors.is_empty():return {"errors":errors,"samples":0,"spacing_m":0.25,"tolerance_m":0.02}
	var definition:={"name":"Validation","description":"","scenario":"forest","elements":[{"id":"form","form_id":"form","entry_transform":form.entry,"input":{"kind":"none"}}],"landings":[]}
	var track=Track.new(definition,{"form":form})
	var distances:Array=[]
	for s in track.elements[0].distances:distances.append(s)
	for i in range(int(ceil(track.length_m/0.25))+1):distances.append(minf(i*0.25,track.length_m))
	for s in distances:
		var frame:Dictionary=track.sample(s)
		for side in [-2.999,0.0,2.999]:
			var point:Vector3=track.surface_point("form",s,side)
			var found:=false
			for i in range(0,faces.size(),3):
				if Geometry3D.segment_intersects_triangle(point+frame.basis.y*0.020001,point-frame.basis.y*0.020001,faces[i],faces[i+1],faces[i+2])!=null:found=true;break
			if not found:
				for i in range(0,faces.size(),3):
					if triangle_distance(point,faces[i],faces[i+1],faces[i+2])<=0.020001:found=true;break
			samples+=1
			if not found:
				errors.append("surface_deviation")
				return {"errors":errors,"samples":samples,"spacing_m":0.25,"tolerance_m":0.02,"failed_s":s,"side":side,"point":point}
	return {"errors":errors,"samples":samples,"spacing_m":0.25,"tolerance_m":0.02}
