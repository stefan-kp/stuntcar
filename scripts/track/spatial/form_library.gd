extends RefCounted

static func number(v) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))

static func numbers(v, size: int) -> bool:
	if not v is Array or v.size() != size: return false
	for x in v:
		if not number(x): return false
	return true

static func vector(v: Array) -> Vector3:
	return Vector3(v[0],v[1],v[2])

static func pose(d: Dictionary) -> Transform3D:
	var q: Array = d.rotation
	return Transform3D(Basis(Quaternion(q[0],q[1],q[2],q[3]).normalized()),vector(d.position))

static func valid_pose(d) -> bool:
	if not d is Dictionary or not numbers(d.get("position"),3) or not numbers(d.get("rotation"),4): return false
	if d.keys().size()!=2: return false
	var q: Array=d.rotation
	return absf(Vector4(q[0],q[1],q[2],q[3]).length()-1.0)<0.00001

static func load_file(path: String) -> Dictionary:
	var result := {"forms":{},"errors":[],"digest":""}
	if not FileAccess.file_exists(path):
		result.errors.append("forms_missing"); return result
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version")!=1 or not data.get("forms") is Dictionary:
		result.errors.append("forms_format");return result
	for id in data.forms:
		var f=data.forms[id]
		if not f is Dictionary or f.get("version")!=1 or f.get("width_m")!=6.0 or not f.get("points") is Array or not f.get("ups") is Array:
			result.errors.append("form_fields:"+id);continue
		if f.points.size()<2 or f.points.size()!=f.ups.size() or not valid_pose(f.get("entry")) or not valid_pose(f.get("exit")):
			result.errors.append("form_shape:"+id);continue
		var valid := true
		for i in range(f.points.size()):
			if not numbers(f.points[i],3) or not numbers(f.ups[i],3):valid=false;break
			if absf(vector(f.ups[i]).length()-1.0)>0.0001:valid=false;break
			if i>0 and vector(f.points[i]).distance_to(vector(f.points[i-1]))<0.00001:valid=false;break
		if not valid:result.errors.append("form_samples:"+id);continue
		if vector(f.points[0]).distance_to(pose(f.entry).origin)>0.001 or vector(f.points[-1]).distance_to(pose(f.exit).origin)>0.001:
			result.errors.append("form_endpoints:"+id);continue
		result.forms[id]=f
	result.digest=FileAccess.get_sha256(path)
	return result
