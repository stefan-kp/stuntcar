extends Node3D

const Scenarios = preload("res://scripts/track/scenarios.gd")
const QualityAssets = preload("res://scripts/quality_assets.gd")
const ForestTerrain = preload("res://scripts/track/forest_terrain.gd")
const ForestScenery = preload("res://scripts/track/forest_scenery.gd")
const BiomeTerrain = preload("res://scripts/track/biome_terrain.gd")
const BiomeScenery = preload("res://scripts/track/biome_scenery.gd")
const CanyonStudy = preload("res://scripts/track/canyon_study.gd")
var data
var weather: Node3D
var scenery: Node3D
var scene_cache := {}
var canyon_study: Node3D

func build(track) -> void:
	data = track
	name = "Landscape"
	make_environment()
	scenery = Node3D.new()
	scenery.name = "Scenery"
	add_child(scenery)
	if data.scenario == "forest":
		var terrain = ForestTerrain.new(data)
		add_child(terrain.create_mesh())
		ForestScenery.new().build(self, terrain)
		return
	if data.scenario in ["canyon", "alpine"]:
		var terrain = BiomeTerrain.new(data)
		add_child(terrain.create_mesh())
		BiomeScenery.new().build(self, terrain)
		if data.source_path == CanyonStudy.ROUTE:
			var study := CanyonStudy.new()
			canyon_study = study
			add_child(study)
			study.build(data, terrain)
		make_weather()
		return
	var bounds := AABB(data.points[0], Vector3.ZERO)
	for point in data.points: bounds = bounds.expand(point)
	var ground: Node3D = load(Scenarios.ROOT + ("coast/water_48.tscn" if data.scenario == "coast" else data.scenario + "/ground_24.tscn")).instantiate()
	var tile_size := 48.0 if data.scenario == "coast" else 24.0
	ground.position = bounds.get_center()
	ground.position.y = -3.0
	ground.scale = Vector3((bounds.size.x + 1800) / tile_size, 1, (bounds.size.z + 1800) / tile_size)
	add_child(ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 121
	var stride := maxi(12, int(data.length_m / 120.0))
	for distance in range(0, int(data.length_m), stride):
		var frame: Dictionary = data.sample(distance)
		for side in [-1.0, 1.0]:
			var offset := rng.randf_range(13, 29)
			var pos: Vector3 = frame.position + data.right(frame.heading) * offset * side
			pos.y = -3
			var scale_factor := rng.randf_range(1.5, 2.5)
			place("coast/boulder_2", pos, scale_factor*1.7, 3.5, rng.randf_range(0,TAU))
			pos += data.right(frame.heading)*side*18
			place("coast/boulder_2",pos,scale_factor*2,3.5,rng.randf_range(0,TAU))
	# Larger silhouettes beyond the close scenery keep the route readable.
	for distance in range(0, int(data.length_m), maxi(90, int(data.length_m / 18.0))):
		var frame: Dictionary = data.sample(distance)
		for side in [-1.0, 1.0]:
			var pos: Vector3 = frame.position + data.right(frame.heading) * side * rng.randf_range(75, 115)
			pos.y = -3
			place("coast/cliff_18", pos, 3.0, 15, -frame.heading)
	if data.scenario == "coast":
		# One recognizable landmark near the opening stretch.
		var frame: Dictionary = data.sample(125)
		for side in [1.0, -1.0]:
			var pos: Vector3 = frame.position + data.right(frame.heading) * side * 45
			pos.y = -3
			if clear_of_road(pos, 18):
				place("coast/boulder_2", pos, 5, 3.5)
				pos.y = 9
				place("coast/lighthouse", pos, 1.7, 2.5)
				break
	make_weather()

func make_weather() -> void:
	if data.scenario in ["alpine", "coast"]:
		weather = load(Scenarios.ROOT + "weather/" + ("snow" if data.scenario == "alpine" else "rain") + ".tscn").instantiate()
		weather.name = "Weather"
		add_child(weather)
		for emitter in weather.find_children("*", "CPUParticles3D", true, false):
			emitter.local_coords = false
		follow(data.points[0])

func clear_of_road(pos: Vector3, radius: float) -> bool:
	# Check the whole route, including another stretch behind a nearby curve.
	for index in range(0, data.points.size(), 4):
		var point: Vector3 = data.points[index]
		if Vector2(point.x - pos.x, point.z - pos.z).length() < radius + 9.0: return false
	return true

func place(path: String, pos: Vector3, size: float, radius: float, angle: float = 0.0) -> Node3D:
	if not clear_of_road(pos, radius * size): return null
	if not scene_cache.has(path): scene_cache[path] = load(Scenarios.ROOT + path + ".tscn")
	var node: Node3D = scene_cache[path].instantiate()
	node.position = pos
	node.scale = Vector3.ONE * size
	node.rotation.y = angle
	node.set_meta("clearance_radius", radius * size)
	scenery.add_child(node)
	return node

func follow(pos: Vector3) -> void:
	if weather != null: weather.global_position = pos + Vector3(0, 9, -6)
	if canyon_study != null: canyon_study.follow(pos)

func make_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color({"alpine": "487f9c", "forest": "557c75", "canyon": "637e94", "coast": "304e63"}[data.scenario])
	sky_mat.sky_horizon_color = Color({"alpine": "d7e6e8", "forest": "b3c5ac", "canyon": "efc6a0", "coast": "a0b6bf"}[data.scenario])
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	sky_mat.ground_bottom_color = Color("344b59")
	if data.scenario in ["forest", "canyon", "alpine"]:
		var panorama := PanoramaSkyMaterial.new()
		panorama.panorama = load(QualityAssets.ROOT + "sky/environment.hdr" if data.scenario == "forest" else "res://assets/landscapes/sky/environment.hdr")
		sky.sky_material = panorama
	else:
		sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = sky_mat.sky_horizon_color
	env.ambient_light_energy = 0.5
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.background_energy_multiplier = 0.7
	if data.scenario in ["canyon", "alpine"]: env.background_energy_multiplier = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 1.8
	env.ssao_intensity = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.fog_enabled = true
	env.fog_sky_affect = 0.15
	env.fog_light_color = sky_mat.sky_horizon_color
	env.fog_density = {"forest": 0.0016, "canyon": 0.0011, "alpine": 0.0015, "coast": 0.00065}[data.scenario]
	var world := WorldEnvironment.new()
	world.name = "Environment"
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -32, 0)
	sun.light_color = Color({"canyon": "ffe1b6", "alpine": "f0f6ff", "forest": "fff4df", "coast": "fff4df"}[data.scenario])
	sun.light_energy = 1.25 if data.scenario != "coast" else 0.75
	sun.light_angular_distance = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180
	if data.scenario == "forest":
		sun.directional_shadow_max_distance = 75
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
