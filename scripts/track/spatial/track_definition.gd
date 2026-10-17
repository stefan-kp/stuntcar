extends RefCounted
const Forms=preload("res://scripts/track/spatial/form_library.gd")

static func validate(data: Dictionary, forms: Dictionary) -> Array[String]:
	var errors: Array[String]=[]
	if data.get("format_version")!=2:errors.append("format_version")
	for key in ["name","description","scenario"]:
		if not data.get(key) is String or data[key].is_empty():errors.append(key)
	if not data.get("styles") is Dictionary or not data.styles.get("road") is String or not data.styles.get("scenery") is String:errors.append("styles")
	var report=data.get("report","")
	if not report is String or report.is_empty() or report.is_absolute_path() or ".." in report.split("/") or report.get_extension()!="json":errors.append("report_path")
	if not data.get("elements") is Array or data.elements.is_empty():errors.append("elements");return errors
	if not data.get("landings") is Array:errors.append("landings");return errors
	var landing_ids: Array=[]
	var launch_ids: Array=[]
	for landing in data.landings:
		if not landing is Dictionary or not landing.get("launch_id") is String or not landing.get("target_ids") is Array or landing.target_ids.is_empty():errors.append("landing_fields");continue
		for key in ["max_angle_degrees","max_impact_mps"]:
			if not Forms.number(landing.get(key)) or landing[key]<=0:errors.append("landing_bounds")
		landing_ids.append_array(landing.target_ids);launch_ids.append(landing.launch_id)
	var ids: Dictionary={}
	var previous: Dictionary={}
	for e in data.elements:
		if not e is Dictionary or not e.get("id") is String or e.id.is_empty():errors.append("element_id");continue
		if ids.has(e.id):errors.append("duplicate_id")
		ids[e.id]=e
		if not forms.has(e.get("form_id","")):errors.append("unknown_form");continue
		var form: Dictionary=forms[e.form_id]
		if e.get("form_version")!=form.version:errors.append("form_version")
		if not Forms.valid_pose(e.get("entry_transform")):errors.append("transform");continue
		if not e.get("input") is Dictionary or e.input.get("kind") not in ["none","turn"]:errors.append("input")
		elif e.input.kind=="turn" and e.input.get("direction") not in [-1,1]:errors.append("direction")
		if not e.get("assist") is Dictionary or not e.get("visual_id") is String:errors.append("element_fields")
		if form.has("kind") and e.get("kind")!=form.kind:errors.append("element_kind")
		var entry: Transform3D=Forms.pose(e.entry_transform)
		if not previous.is_empty() and e.id not in landing_ids:
			var end: Transform3D=previous.exit
			if entry.origin.distance_to(end.origin)>0.001:errors.append("connection_position")
			if entry.basis.get_rotation_quaternion().angle_to(end.basis.get_rotation_quaternion())>deg_to_rad(0.1):errors.append("connection_rotation")
		if form.has("entry") and form.has("exit"):
			previous={"exit":entry*Forms.pose(form.entry).affine_inverse()*Forms.pose(form.exit)}
	for id in landing_ids+launch_ids:
		if not ids.has(id):errors.append("landing_reference")
	return errors
