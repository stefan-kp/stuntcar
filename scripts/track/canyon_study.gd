extends Node3D

const ROUTE := "res://tracks/05_canyon_study.json"
const ROOT := "res://assets/landscapes/canyon/"
var rock_material: ShaderMaterial
var wind_dust: CPUParticles3D

func build(track, terrain) -> void:
	name = "CanyonStudy"
	rock_material = ShaderMaterial.new()
	rock_material.shader = load(ROOT + "rock.gdshader")
	rock_material.set_shader_parameter("color_map", load(ROOT + "textures/Diffuse.jpg"))
	rock_material.set_shader_parameter("rough_map", load(ROOT + "textures/Rough.jpg"))
	rock_material.set_shader_parameter("normal_map", load(ROOT + "textures/nor_gl.jpg"))
	get_parent().get_node("BiomeTerrain").material_override = ground_material()
	configure_light()
	make_shoulders(track, terrain)
	make_scree(track, terrain)
	make_scanned_faces(track, terrain)
	make_dust()
	# Local X follows the road for walls; it crosses the road for the arch.
	for entry in [[25, -25, "wall_1"], [63, -26, "wall_2"], [105, -28, "wall_3"], [15, 28, "wall_3"], [56, 30, "wall_1"], [100, 33, "wall_2"], [182, -29, "wall_1"]]:
		var frame: Dictionary = track.sample(entry[0])
		var pos: Vector3 = frame.position + track.right(frame.heading)*entry[1]
		pos.y = terrain.height_at(pos.x,pos.z)-2.0
		place(entry[2], pos, PI/2.0-frame.heading, "Wall_%d_%d" % [entry[0],entry[1]])
	var mesa_frame: Dictionary = track.sample(160)
	var mesa_pos: Vector3 = mesa_frame.position + track.right(mesa_frame.heading)*103 + track.forward(mesa_frame.heading)*125
	mesa_pos.y = terrain.height_at(mesa_pos.x,mesa_pos.z)-8
	place("mesa",mesa_pos,0.35,"Mesa")
	var arch_frame: Dictionary = track.sample(148)
	var arch_pos: Vector3 = arch_frame.position - Vector3.UP*14
	place("arch",arch_pos,-arch_frame.heading,"Arch")

static func road_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(ROOT + "road.gdshader")
	mat.set_shader_parameter("color_map", load("res://assets/quality/road/color.jpg"))
	mat.set_shader_parameter("normal_map", load("res://assets/quality/road/normal.jpg"))
	mat.set_shader_parameter("arm_map", load("res://assets/quality/road/arm.jpg"))
	mat.set_shader_parameter("gravel_map", load(ROOT + "gravel/Diffuse.jpg"))
	return mat

static func ground_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(ROOT + "ground.gdshader")
	mat.set_shader_parameter("color_map", load(ROOT + "gravel/Diffuse.jpg"))
	mat.set_shader_parameter("normal_map", load(ROOT + "gravel/nor_gl.jpg"))
	mat.set_shader_parameter("rough_map", load(ROOT + "gravel/Rough.jpg"))
	mat.set_shader_parameter("cliff_map", load(ROOT + "textures/Diffuse.jpg"))
	return mat

func configure_light() -> void:
	var env: Environment = get_parent().get_node("Environment").environment
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load(ROOT + "sky/environment.hdr")
	env.sky.sky_material = panorama
	env.sky_rotation.y = 0.6
	env.background_energy_multiplier = 0.6
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b6c6db")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.ssao_radius = 2.5
	env.ssao_intensity = 1.7
	env.ssao_detail = 0.8
	env.ssil_enabled = true
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.65
	env.glow_intensity = 0.12
	env.fog_enabled = true
	env.fog_light_color = Color("b6b5b0")
	env.fog_light_energy = 0.6
	env.fog_density = 0.0015
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.002
	env.volumetric_fog_length = 220.0
	env.volumetric_fog_albedo = Color("b9ada0")
	env.volumetric_fog_ambient_inject = 0.15
	for node in get_parent().get_children():
		if node is DirectionalLight3D:
			node.rotation_degrees = Vector3(-24,-48,0)
			node.light_color = Color("ffead2")
			node.light_energy = 1.8
			node.light_angular_distance = 0.65
			node.directional_shadow_max_distance = 280.0
			node.shadow_blur = 1.4
			node.light_volumetric_fog_energy = 0.7
	var reflection := ReflectionProbe.new()
	reflection.name = "CanyonReflection"
	reflection.size = Vector3(320,100,340)
	reflection.position = Vector3(25,25,-95)
	reflection.origin_offset = Vector3(0,-8,0)
	reflection.box_projection = true
	reflection.max_distance = 400
	add_child(reflection)

func make_shoulders(track, terrain) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for distance in range(int(track.length_m)):
		var a: Dictionary = track.sample(distance)
		var b: Dictionary = track.sample(distance+1)
		for side in [-1.0,1.0]:
			var offsets := [2.99,3.5,4.5,6.5,9.0]
			for strip in range(offsets.size()-1):
				var vertices: Array[Vector3] = []
				for pair in [[a,offsets[strip]],[a,offsets[strip+1]],[b,offsets[strip+1]],[b,offsets[strip]]]:
					var frame: Dictionary = pair[0]
					var offset: float = pair[1]
					var p: Vector3 = frame.position + frame.right * side * offset
					var blend := smoothstep(3.0,9.0,offset)
					p.y = lerpf(p.y-0.035,terrain.height_at(p.x,p.z)+0.06,blend)
					vertices.append(p)
				for index in ([0,2,1,0,3,2] if side > 0 else [0,1,2,0,2,3]):
					surface.add_vertex(vertices[index])
	surface.generate_normals()
	var shoulders := MeshInstance3D.new()
	shoulders.name = "GravelShoulders"
	shoulders.mesh = surface.commit()
	shoulders.material_override = ground_material()
	add_child(shoulders)
	shoulders.create_trimesh_collision()

func make_scree(track, terrain) -> void:
	var assets = load("res://scripts/landscape_assets.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 47107
	# Instanced scan fragments add scale without a separate draw call per stone.
	for variant in range(2):
		var source_mesh: Mesh = assets.variants("namaqualand_boulder_02" if variant == 0 else "namaqualand_boulder_03")[0]
		var source = load(ROOT + "scree_%d.glb" % variant).instantiate()
		var mesh: Mesh = source.find_children("*","MeshInstance3D",true,false)[0].mesh.duplicate()
		source.free()
		var bounds := mesh.get_aabb()
		var center := Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
		for surface in range(mesh.get_surface_count()):
			var mat: StandardMaterial3D = source_mesh.surface_get_material(surface).duplicate()
			mat.albedo_color = Color("bc9a7b")
			mat.roughness = 0.94
			mesh.surface_set_material(surface,mat)
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = 170
		for index in range(multimesh.instance_count):
			var frame: Dictionary = track.sample(rng.randf_range(0,200))
			var side := -1.0 if index%2 == 0 else 1.0
			var offset := rng.randf_range(5.6,19.0)
			var p: Vector3 = frame.position + track.right(frame.heading)*side*offset
			var size := rng.randf_range(.12,.6) if offset < 10 else rng.randf_range(.5,2.0)
			var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(size,size*rng.randf_range(.5,1.0),size))
			p.y = terrain.height_at(p.x,p.z) - .05
			# Place small shoulder stones on the interpolated shoulder surface.
			if offset < 9:
				var road_y: float = frame.position.y + frame.right.y*side*offset - .035
				p.y = lerpf(road_y,p.y+.11,smoothstep(3.0,9.0,offset))-.04
			multimesh.set_instance_transform(index,Transform3D(basis,p-basis*center))
		var field := MultiMeshInstance3D.new()
		field.name = "Scree%d" % variant
		field.multimesh = multimesh
		field.visibility_range_end = 200.0
		add_child(field)

func make_scanned_faces(track, terrain) -> void:
	var packed := load(ROOT + "rock_face_02.glb")
	var rng := RandomNumberGenerator.new()
	rng.seed = 86713
	for distance in [8,29,51,73,94,116]:
		var frame: Dictionary = track.sample(distance)
		for side in [-1.0,1.0]:
			var face: Node3D = packed.instantiate()
			face.name = "ScannedCliff%d_%d" % [distance,side]
			# The scan has open sides. Embed its back and rim in the solid cliff.
			var offset: float = (17.0+distance*.02) if side < 0 else (20.0+distance*.035)
			var pos: Vector3 = frame.position + track.right(frame.heading)*side*offset
			pos.y = terrain.height_at(pos.x,pos.z)-.6
			face.position = pos
			face.rotation.y = -frame.heading - side*PI/2.0 + rng.randf_range(-.12,.12)
			face.scale = Vector3.ONE*rng.randf_range(2.4,3.0)
			add_child(face)
			for mesh in face.find_children("*","MeshInstance3D",true,false):
				for surface in range(mesh.mesh.get_surface_count()):
					var mat: StandardMaterial3D = mesh.mesh.surface_get_material(surface).duplicate()
					mat.albedo_color = Color("c3a68c")
					mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					mesh.set_surface_override_material(surface,mat)
				mesh.create_trimesh_collision()
				for body in mesh.get_children():
					if body is StaticBody3D: body.collision_layer = 5

func make_dust() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 831
	noise.frequency = .075
	var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var radial := maxf(0.0,1.0-Vector2(x-31.5,y-31.5).length()/31.5)
			var alpha := pow(radial,1.8)*clampf(noise.get_noise_2d(x,y)*1.4+.45,0.0,1.0)
			image.set_pixel(x,y,Color(1,1,1,alpha))
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.albedo_color = Color(.63,.52,.40,.24)
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var quad := QuadMesh.new()
	quad.material = mat
	wind_dust = CPUParticles3D.new()
	wind_dust.name = "WindDust"
	wind_dust.mesh = quad
	wind_dust.amount = 44
	wind_dust.lifetime = 7.0
	wind_dust.preprocess = 3.0
	wind_dust.local_coords = false
	wind_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	wind_dust.emission_box_extents = Vector3(22,1.2,35)
	wind_dust.direction = Vector3(1,.06,.2)
	wind_dust.spread = 12.0
	wind_dust.gravity = Vector3.ZERO
	wind_dust.initial_velocity_min = 1.2
	wind_dust.initial_velocity_max = 2.8
	wind_dust.scale_amount_min = 5.0
	wind_dust.scale_amount_max = 13.0
	wind_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0,.2,.65,1.0])
	fade.colors = PackedColorArray([Color(1,1,1,0),Color.WHITE,Color(1,1,1,.7),Color(1,1,1,0)])
	wind_dust.color_ramp = fade
	add_child(wind_dust)

func follow(pos: Vector3) -> void:
	if wind_dust != null: wind_dust.global_position = pos + Vector3(0,.3,-20)

func place(asset: String, pos: Vector3, angle: float, label: String) -> void:
	var object = load(ROOT + asset + ".glb").instantiate()
	object.name = label
	add_child(object)
	object.position = pos
	object.rotation.y = angle
	for mesh in object.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = rock_material
		mesh.create_trimesh_collision()
		for body in mesh.get_children():
			if body is StaticBody3D:
				# Layer 1 stops the car; layer 3 permits separate clearance checks.
				body.collision_layer = 5
				body.collision_mask = 0
