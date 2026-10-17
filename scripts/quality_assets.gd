extends RefCounted

const ROOT := "res://assets/quality/"
const CarLivery = preload("res://scripts/vehicle/car_livery.gd")
static var car_scene: PackedScene
static var pine_meshes: Array[Mesh] = []
static var asphalt: StandardMaterial3D
static var forest_floor: StandardMaterial3D

static func create_car() -> Node3D:
	if car_scene == null:
		car_scene = load(ROOT + "car/CarConcept.gltf")
	var body := Node3D.new()
	body.name = "DetailedCoupe"
	body.set_meta("quality_source", "Car Concept / Eric Chadwick / CC BY 4.0")
	var model: Node3D = car_scene.instantiate()
	model.rotation.y = PI
	body.add_child(model)
	var materials := {}
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for i in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.mesh.surface_get_material(i)
			if not original is StandardMaterial3D:
				continue
			if CarLivery.applies_to(mesh, original):
				mesh.set_surface_override_material(i, CarLivery.material_for(mesh, model))
				continue
			if not materials.has(original):
				materials[original] = car_material(original)
			mesh.set_surface_override_material(i, materials[original])
	# Preserve the imported wheel geometry. Use straight local X axes for spin.
	# This also works before the model enters the scene tree.
	var index := 0
	for source_name in ["WheelFrontL", "WheelFrontR", "WheelRearL", "WheelRearR"]:
		var wheel: Node3D = model.find_child(source_name, true, false)
		var relative := wheel.transform
		var parent := wheel.get_parent()
		while parent != body:
			relative = parent.transform * relative
			parent = parent.get_parent()
		wheel.owner = null
		for descendant in wheel.find_children("*", "", true, false):
			descendant.owner = null
		wheel.get_parent().remove_child(wheel)
		var pivot := Node3D.new()
		pivot.name = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"][index]
		pivot.position = relative.origin
		body.add_child(pivot)
		pivot.add_child(wheel)
		wheel.transform = Transform3D(relative.basis, Vector3.ZERO)
		if index < 2:
			wheel.basis = Basis(Vector3.UP, deg_to_rad(30.0)) * wheel.basis
		index += 1
	return body

static func car_material(original: StandardMaterial3D) -> StandardMaterial3D:
	var mat: StandardMaterial3D = original.duplicate()
	var key := original.resource_name
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Godot imports these glTF materials without their per-texture transforms.
	# Restore the supported detail maps below with the source scale explicitly.
	mat.normal_enabled = false
	mat.ao_enabled = false
	if key.begins_with("Paint 1"):
		mat.albedo_color = Color("ef7c25")
		mat.metallic = 0.8
		mat.roughness = 0.22
		mat.normal_enabled = true
		mat.normal_texture = load(ROOT + "car/Powdercoat_N.png")
		mat.normal_scale = 0.09
		mat.uv1_scale = Vector3(30, 30, 1)
		mat.clearcoat_enabled = true
		mat.clearcoat = 1.0
		mat.clearcoat_roughness = 0.1
	elif key.begins_with("Paint 2"):
		mat.albedo_color = Color("303b42")
		mat.metallic = 0.75
		mat.roughness = 0.3
		mat.normal_enabled = true
		mat.normal_texture = load(ROOT + "car/Powdercoat_N.png")
		mat.normal_scale = 0.06
		mat.uv1_scale = Vector3(30, 30, 1)
		mat.clearcoat_enabled = true
		mat.clearcoat = 0.8
		mat.clearcoat_roughness = 0.14
	elif key == "Glass":
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.18, 0.25, 0.28, 0.42)
		mat.metallic = 0.35
		mat.roughness = 0.08
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.refraction_enabled = false
	elif key in ["Tireside", "Tiretread"]:
		mat.albedo_color = Color("292b2e")
		mat.albedo_texture = null
		mat.metallic = 0.0
		mat.roughness = 0.72
		mat.normal_enabled = true
		mat.normal_scale = 0.65
		if key == "Tiretread":
			mat.uv1_scale = Vector3(1, 4, 1)
			mat.uv1_offset = Vector3(0, 1.5, 0)
	elif key in ["Rim1", "Rim2"]:
		mat.emission_enabled = false
		mat.albedo_color = Color("7e8a94") if key == "Rim1" else Color("e0e5ea")
		mat.albedo_texture = load(ROOT + "car/metal/color.jpg")
		mat.normal_enabled = true
		mat.normal_texture = load(ROOT + "car/metal/normal.jpg")
		mat.normal_scale = 0.12
		mat.roughness_texture = load(ROOT + "car/metal/roughness.jpg")
		mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		mat.metallic = 1.0
		mat.roughness = 0.7
		# Project in local metres so all four wheels keep the same fine grain.
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3.ONE * 4.0
	elif key == "License":
		mat.albedo_texture = null
		mat.albedo_color = Color("111b20")
	elif key == "Headlight":
		mat.emission_energy_multiplier = 2.2
	return mat

static func surface(folder: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(ROOT + folder + "/color.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load(ROOT + folder + "/normal.jpg")
	mat.normal_scale = 0.65
	mat.roughness_texture = load(ROOT + folder + "/arm.jpg")
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.ao_enabled = true
	mat.ao_texture = mat.roughness_texture
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

static func road_material() -> StandardMaterial3D:
	if asphalt == null:
		asphalt = surface("road")
		asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
	return asphalt

static func ground_material() -> StandardMaterial3D:
	if forest_floor == null:
		forest_floor = surface("ground")
		forest_floor.albedo_color = Color(0.36, 0.43, 0.30)
		forest_floor.roughness_texture = null
		forest_floor.roughness = 0.98
		forest_floor.normal_scale = 0.4
		forest_floor.uv1_triplanar = true
		forest_floor.uv1_world_triplanar = true
		forest_floor.uv1_scale = Vector3.ONE / 3.5
	return forest_floor

static func create_pine(variant: int) -> MeshInstance3D:
	if pine_meshes.is_empty():
		var source: Node3D = load(ROOT + "tree/tree.gltf").instantiate()
		for mesh in source.find_children("*", "MeshInstance3D", true, false):
			pine_meshes.append(mesh.mesh)
		source.free()
	var tree := MeshInstance3D.new()
	tree.name = "DetailedPine"
	tree.mesh = pine_meshes[posmod(variant, pine_meshes.size())]
	tree.visibility_range_end = 260.0
	tree.visibility_range_end_margin = 35.0
	tree.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	tree.lod_bias = 0.6
	return tree
