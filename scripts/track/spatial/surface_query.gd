extends RefCounted
static func sweep(track,a:Vector3,b:Vector3,ids:Array[String])->Dictionary:
	var result:Dictionary={};var nearest:=INF
	var direction:=b-a
	if direction.length_squared()<0.0000000001:return result
	for id in ids:
		if not track.by_id.has(id):continue
		for face in track.triangles(id):
			if direction.dot(face.normal)>=-0.000001:continue
			var hit=Geometry3D.segment_intersects_triangle(a,b,face.a,face.b,face.c)
			if hit==null:continue
			var t:float=(hit-a).dot(direction)/direction.length_squared()
			if t<nearest:
				nearest=t
				var projection:Dictionary=track.project_near(hit,id,face.local_m)
				result={"fraction":t,"position":hit,"normal":face.normal,"element_id":id,"local_m":projection.local_m}
	return result
