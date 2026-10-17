extends RefCounted
const Forms=preload("res://scripts/track/spatial/form_library.gd")
const Track=preload("res://scripts/track/spatial/spatial_track.gd")
static func make(ids:Array):
	var library:Dictionary=Forms.load_file("res://tracks/forms/stunt_v1.json").forms
	var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spatial/straight.json"));d.elements=[]
	var pose:=Transform3D(Basis.IDENTITY,Vector3(0,12,0))
	for i in range(ids.size()):
		var f:Dictionary=library[ids[i]];var q:=pose.basis.get_rotation_quaternion()
		d.elements.append({"id":"e%d"%i,"kind":f.kind,"form_id":ids[i],"form_version":1,"entry_transform":{"position":[pose.origin.x,pose.origin.y,pose.origin.z],"rotation":[q.x,q.y,q.z,q.w]},"input":{"kind":"turn","direction":-1 if "left" in ids[i] else 1} if f.kind in ["curve","bank"] else {"kind":"none"},"assist":{},"visual_id":ids[i]})
		pose=pose*Forms.pose(f.entry).affine_inverse()*Forms.pose(f.exit)
	return Track.new(d,library)
