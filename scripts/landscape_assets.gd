extends RefCounted

const ROOT := "res://assets/landscapes/"
const ForestAssets = preload("res://scripts/forest_assets.gd")
static var mesh_cache := {}
static var snow_materials := {}

static func variants(asset: String) -> Array:
	if not mesh_cache.has(asset):
		var path := ROOT + "prepared/" + asset + ".glb"
		var source = load(path).instantiate()
		var found := []
		for item in source.find_children("*", "MeshInstance3D", true, false):
			ForestAssets.prepare_materials(item.mesh)
			found.append(item.mesh)
		source.free()
		mesh_cache[asset] = found
	return mesh_cache[asset]

static func snow_material(original: StandardMaterial3D, foliage: bool) -> ShaderMaterial:
	var key := str(original.get_instance_id()) + str(foliage)
	if not snow_materials.has(key):
		var mat := ShaderMaterial.new()
		mat.shader = load(ROOT + "snow_cover.gdshader")
		mat.set_shader_parameter("base_color", original.albedo_texture)
		mat.set_shader_parameter("snow_color", load(ROOT + "snow/color.jpg"))
		mat.set_shader_parameter("foliage", foliage)
		snow_materials[key] = mat
	return snow_materials[key]

static func create_prop(asset: String, variant: int, snowy: bool = false) -> Node3D:
	var choices := variants(asset)
	var mesh: Mesh = choices[posmod(variant, choices.size())]
	var node := Node3D.new()
	node.name = "LandscapeProp"
	node.set_meta("biome_asset", asset)
	node.set_meta("source_radius", ForestAssets.radius(mesh))
	var item := ForestAssets.centered(mesh)
	item.visibility_range_end = 350.0 if asset != "shrub_02" else 110.0
	item.visibility_range_end_margin = 25.0
	if snowy:
		for surface in range(mesh.get_surface_count()):
			item.set_surface_override_material(surface, snow_material(mesh.surface_get_material(surface), false))
	if asset == "shrub_02":
		item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in range(mesh.get_surface_count()):
			var mat: StandardMaterial3D = mesh.surface_get_material(surface).duplicate()
			mat.albedo_color = Color(0.70, 0.53, 0.27)
			item.set_surface_override_material(surface, mat)
	node.add_child(item)
	return node

static func create_snow_tree(variant: int) -> Node3D:
	var node := ForestAssets.create_tree("fir_tree_01", variant)
	node.name = "SnowFir"
	node.set_meta("biome_asset", "fir_tree_01")
	for item in node.get_children():
		for surface in range(item.mesh.get_surface_count()):
			var mat: StandardMaterial3D = item.mesh.surface_get_material(surface)
			item.set_surface_override_material(surface, snow_material(mat, mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED))
	return node
