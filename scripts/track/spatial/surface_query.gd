extends RefCounted
# First road face the segment a-b meets. A face met from below or behind sets "underside".
# Faces of `skip_id` between `skip_from_m` and `skip_to_m` are ignored: the road the car just left.
static func sweep(track,a:Vector3,b:Vector3,ids:Array[String],skip_id:String="",skip_from_m:float=0.0,skip_to_m:float=-1.0)->Dictionary:
	var result:Dictionary={};var nearest:=INF
	var direction:=b-a
	if direction.length_squared()<0.0000000001:return result
	var path:=AABB(a,Vector3.ZERO).expand(b)
	for id in ids:
		if not track.by_id.has(id) or not track.bounds(id).intersects(path):continue
		for face in track.triangles(id):
			if id==skip_id and face.local_m>=skip_from_m and face.local_m<skip_to_m:continue
			var hit=Geometry3D.segment_intersects_triangle(a,b,face.a,face.b,face.c)
			if hit==null:continue
			var t:float=(hit-a).dot(direction)/direction.length_squared()
			if t<nearest:
				nearest=t
				var projection:Dictionary=track.project_near(hit,id,face.local_m)
				result={"fraction":t,"position":hit,"normal":face.normal,"element_id":id,"local_m":projection.local_m,"underside":direction.dot(face.normal)>=-0.000001}
	return result
