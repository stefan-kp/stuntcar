extends Node3D
func build(track,style:String)->void:
	var env:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("9bcad8")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("c8ddeb");settings.ambient_light_energy=0.7
	env.environment=settings;add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);light.shadow_enabled=true;add_child(light)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(2400,2400);ground.mesh=plane
	var material:=StandardMaterial3D.new();material.albedo_color=Color("709880") if style=="neutral" else Color("bfa984")
	ground.material_override=material;ground.position.y=-2;add_child(ground)
	for element in track.elements:
		var frame:Dictionary=track.sample(element.start_m)
		for side in [-1,1]:
			var position:Vector3=frame.position+frame.basis.x*side*28;position.y=1
			var clear:=true
			for e in track.elements:
				for p in e.points:
					if Vector2(p.x,p.z).distance_to(Vector2(position.x,position.z))<18:clear=false
			if not clear:continue
			var stone:=MeshInstance3D.new();var shape:=CylinderMesh.new();shape.top_radius=1;shape.bottom_radius=4;shape.height=6
			stone.mesh=shape;stone.material_override=material;stone.position=position;add_child(stone)
func follow(_position:Vector3)->void:pass
