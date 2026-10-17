extends SceneTree
func vec(v:Vector3)->Array:return [v.x,v.y,v.z]
func pose(t:Transform3D)->Dictionary:
	var q:=t.basis.get_rotation_quaternion()
	return {"position":vec(t.origin),"rotation":[q.x,q.y,q.z,q.w]}
func _initialize()->void:
	var forms:={}
	for id in ["straight_24","curve_left_45","curve_right_45","bank_left_90","bank_right_90","jump_launch","jump_landing","hill_32","loop_12"]:
		var node=load("res://assets/stuntcar_kit/track/"+id+".tscn").instantiate()
		var points:Array=[];var ups:Array=[]
		for p in node.get_meta("centerline"):points.append(vec(p))
		for u in node.get_meta("up_vectors"):ups.append(vec(u))
		forms[id]={"version":1,"kind":node.get_meta("kind"),"width_m":6.0,"points":points,"ups":ups,"entry":pose(node.get_node("Entry").transform),"exit":pose(node.get_node("Exit").transform)}
		node.free()
	var file:=FileAccess.open("res://tracks/forms/stunt_v1.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"forms":forms},"\t")+"\n")
	print("Extracted %d forms without modifying source assets"%forms.size());quit()
