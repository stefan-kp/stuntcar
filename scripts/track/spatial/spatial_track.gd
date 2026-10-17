extends RefCounted
const Forms=preload("res://scripts/track/spatial/form_library.gd")
var definition:Dictionary
var forms:Dictionary
var elements:Array[Dictionary]=[]
var by_id:Dictionary={}
var triangle_cache:Dictionary={}
var length_m:=0.0
var format_version:=2
var source_path:=""
var valid:=true
var validation_error:=""
var scenario:="forest"
var track_name:=""
var description:=""
var preview_path:=""
var curves:Array[Dictionary]=[]
var jumps:Array[Dictionary]=[]

func _init(data:Dictionary,library:Dictionary)->void:
	definition=data.duplicate(true);forms=library
	track_name=tr(data.name);description=tr(data.description);scenario=data.scenario
	for source in data.elements:
		var form:Dictionary=forms[source.form_id]
		var transform:Transform3D=Forms.pose(source.entry_transform)*Forms.pose(form.entry).affine_inverse()
		var points:PackedVector3Array=[];var bases:Array[Basis]=[];var distances:PackedFloat64Array=[0.0]
		for i in range(form.points.size()):
			var p:=Forms.vector(form.points[i]);var up:=Forms.vector(form.ups[i])
			var forward:=Forms.vector(form.points[mini(i+1,form.points.size()-1)])-Forms.vector(form.points[maxi(i-1,0)])
			forward=(forward-up*forward.dot(up)).normalized()
			var basis:=Basis(forward.cross(up).normalized(),up,-forward).orthonormalized()
			if i==0:basis=Forms.pose(form.entry).basis
			if i==form.points.size()-1:basis=Forms.pose(form.exit).basis
			points.append(transform*p);bases.append(transform.basis*basis)
			if i>0:distances.append(distances[-1]+points[i].distance_to(points[i-1]))
		var e:Dictionary=source.duplicate(true)
		e.merge({"points":points,"bases":bases,"distances":distances,"start_m":length_m,"end_m":length_m+distances[-1],"length_m":distances[-1],"transform":transform,"index":elements.size(),"width_m":form.width_m})
		by_id[e.id]=e;elements.append(e);length_m=e.end_m
		if source.input.kind=="turn":
			curves.append({"id":curves.size(),"element_id":e.id,"start_m":e.start_m,"end_m":e.end_m,"turn_sign":source.input.direction,"radius":28.0,"checkpoint_m":maxf(0,e.start_m-36.0)})
	for landing in data.landings:
		if by_id.has(landing.launch_id) and not landing.target_ids.is_empty() and by_id.has(landing.target_ids[0]):
			var launch:Dictionary=by_id[landing.launch_id];var target:Dictionary=by_id[landing.target_ids[0]]
			jumps.append({"start_m":launch.end_m,"end_m":target.end_m,"launch_id":launch.id,"target_id":target.id,"height_m":3.0})

func sample(distance:float)->Dictionary:
	var s:=clampf(distance,0,length_m)
	var e:Dictionary=elements[-1]
	for part in elements:
		if s<part.end_m:e=part;break
	return sample_element(e.id,s-e.start_m)

func sample_element(id:String,local:float)->Dictionary:
	var e:Dictionary=by_id[id]
	var s:=clampf(local,0,e.length_m)
	var ds:PackedFloat64Array=e.distances
	var i:=clampi(ds.bsearch(s)-1,0,ds.size()-2)
	var t:float=(s-ds[i])/(ds[i+1]-ds[i])
	var qa:Quaternion=e.bases[i].get_rotation_quaternion();var qb:Quaternion=e.bases[i+1].get_rotation_quaternion()
	if qa.dot(qb)<0:qb=-qb
	var basis:=Basis(qa.slerp(qb,t)).orthonormalized()
	return {"position":e.points[i].lerp(e.points[i+1],t),"basis":basis,"distance_m":e.start_m+s,"element_id":id,"local_m":s,"heading":atan2(-basis.z.x,basis.z.z),"bank":basis.get_euler().z,"right":basis.x}

func project_near(p:Vector3,id:String,local:float)->Dictionary:
	if not by_id.has(id):return {"valid":false}
	var e:Dictionary=by_id[id];var candidates:Array[Dictionary]=[e]
	if local>e.length_m-3.0 and e.index+1<elements.size() and landing_candidates(id).is_empty():candidates.append(elements[e.index+1])
	var best:=INF;var result:Dictionary={"valid":false}
	for part in candidates:
		for i in range(part.points.size()-1):
			if part.id==id and (part.distances[i+1]<local-8 or part.distances[i]>local+8):continue
			if part.id!=id and part.distances[i]>8:break
			var a:Vector3=part.points[i];var b:Vector3=part.points[i+1]
			var t:=clampf((p-a).dot(b-a)/a.distance_squared_to(b),0,1)
			var sq:=p.distance_squared_to(a.lerp(b,t))
			if sq<best:
				best=sq;result=sample_element(part.id,lerpf(part.distances[i],part.distances[i+1],t))
	if result.has("basis"):
		var offset:Vector3=p-result.position
		result.merge({"valid":true,"lateral_m":offset.dot(result.basis.x),"normal_m":offset.dot(result.basis.y)})
	return result

func landing_candidates(id:String)->Array[String]:
	var result:Array[String]=[]
	for l in definition.landings:
		if l.launch_id==id:result.assign(l.target_ids)
	return result

func triangles(id:String)->Array[Dictionary]:
	if triangle_cache.has(id):return triangle_cache[id]
	var e:Dictionary=by_id[id];var result:Array[Dictionary]=[]
	for i in range(e.points.size()-1):
		var a:Vector3=e.points[i]-e.bases[i].x*3;var b:Vector3=e.points[i]+e.bases[i].x*3
		var c:Vector3=e.points[i+1]+e.bases[i+1].x*3;var d:Vector3=e.points[i+1]-e.bases[i+1].x*3
		var normal:Vector3=(e.bases[i].y+e.bases[i+1].y).normalized()
		result.append({"a":a,"b":c,"c":b,"normal":normal,"local_m":e.distances[i]})
		result.append({"a":a,"b":d,"c":c,"normal":normal,"local_m":e.distances[i]})
	triangle_cache[id]=result
	return result

func surface_point(id:String,local:float,lateral:float)->Vector3:
	var e:Dictionary=by_id[id];var ds:PackedFloat64Array=e.distances
	var s:=clampf(local,0,e.length_m);var i:=clampi(ds.bsearch(s)-1,0,ds.size()-2)
	var t:float=(s-ds[i])/(ds[i+1]-ds[i]);var r:=clampf((lateral+3.0)/6.0,0,1)
	var a:Vector3=e.points[i]-e.bases[i].x*3;var b:Vector3=e.points[i]+e.bases[i].x*3
	var c:Vector3=e.points[i+1]+e.bases[i+1].x*3;var d:Vector3=e.points[i+1]-e.bases[i+1].x*3
	return a*(1-r)+b*(r-t)+c*t if r>=t else a*(1-t)+d*(t-r)+c*r

static func number(value)->bool:return Forms.number(value)
static func scan_catalog(folder:String="res://tracks")->Dictionary:
	return load("res://scripts/track/track_data.gd").scan_catalog(folder)
static func catalog()->Array[Dictionary]:return scan_catalog().routes
func next_curve(s:float)->Dictionary:
	for c in curves:
		if s<c.end_m:return c
	return {}
func section_at(s:float)->Dictionary:
	for c in curves:
		if s>=c.start_m and s<c.end_m:return c
	return {"id":-1,"turn_sign":0,"start_m":0.0,"end_m":length_m,"checkpoint_m":0.0}
func jump_at(s:float,approach:float=0)->Dictionary:
	for j in jumps:
		if s>=j.start_m-approach and s<j.end_m:return j
	return {}
func jump_for_correction(s:float)->Dictionary:return jump_at(s,55.0)
func speed_hint_at(_s:float,_approach:float=0)->Dictionary:return {}
