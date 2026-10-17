extends SceneTree
const Fixtures=preload("res://tests/spatial/fixtures.gd")
const Forms=preload("res://scripts/track/spatial/form_library.gd")
func _initialize()->void:
	var ids:=["straight_24","straight_24","straight_24","hill_32","straight_24","straight_24","straight_24","bank_left_90","straight_24","straight_24","straight_24","jump_launch","jump_landing","straight_24","straight_24","straight_24","loop_12","straight_24","straight_24","straight_24","curve_right_45","straight_24","straight_24"]
	var track=Fixtures.make(ids);var data:Dictionary=track.definition
	var launch:Dictionary=track.by_id.e11
	var exit:Transform3D=launch.transform*Forms.pose(track.forms.jump_launch.exit)
	var heading:Basis=launch.transform.basis
	var pose:=Transform3D(heading*Forms.pose(track.forms.jump_landing.entry).basis,exit.origin-heading.z*24)
	for i in range(12,data.elements.size()):
		var e:Dictionary=data.elements[i];var form:Dictionary=track.forms[e.form_id]
		var q:=pose.basis.get_rotation_quaternion()
		e.entry_transform={"position":[pose.origin.x,pose.origin.y,pose.origin.z],"rotation":[q.x,q.y,q.z,q.w]}
		pose=pose*Forms.pose(form.entry).affine_inverse()*Forms.pose(form.exit)
	data.elements[11].assist={"min_mps":20.5,"max_mps":21.5,"target_mps":21.0,"approach_m":60.0}
	data.name="Stuntlabor";data.description="Kuppe, Steilkurve, Sprung und Looping."
	data.report="reports/06_stuntlabor.json"
	data.landings=[{"launch_id":"e11","target_ids":["e12"],"max_angle_degrees":20.0,"max_impact_mps":12.0}]
	var file:=FileAccess.open("res://tracks/06_stuntlabor.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t",true,true)+"\n");file.close();quit()
