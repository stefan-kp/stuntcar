extends RefCounted

const ROOT := "res://assets/quality/car/"

static func applies_to(mesh: MeshInstance3D, material: StandardMaterial3D) -> bool:
	return material.resource_name.begins_with("Paint 1") or mesh.name == "BodyRoofPanel"

static func material_for(mesh: MeshInstance3D, model: Node3D) -> ShaderMaterial:
	# Capture each panel's transform before the model is attached to the scene tree.
	# The mapping then follows the car through steering, banking and jumps.
	var relative := mesh.transform
	var parent := mesh.get_parent()
	while parent != model:
		relative = parent.transform * relative
		parent = parent.get_parent()
	var material := ShaderMaterial.new()
	material.shader = load(ROOT + "livery/paint.gdshader")
	material.set_shader_parameter("color_map", load(ROOT + "livery/orange-stripes.png"))
	material.set_shader_parameter("flake_map", load(ROOT + "Powdercoat_N.png"))
	material.set_shader_parameter("mesh_to_car", relative)
	return material
