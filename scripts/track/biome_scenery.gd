extends RefCounted

const Assets = preload("res://scripts/landscape_assets.gd")
var landscape
var terrain
var rng := RandomNumberGenerator.new()
var snowy := false

func build(parent, ground) -> void:
	landscape = parent
	terrain = ground
	snowy = terrain.snowy
	rng.seed = 23671 if snowy else 89352
	var data = landscape.data
	for distance in range(0, int(data.length_m), 15):
		var frame: Dictionary = data.sample(distance)
		for side in [-1.0, 1.0]:
			var across: Vector3 = data.right(frame.heading) * side
			var pos: Vector3 = frame.position + across*rng.randf_range(18,36)
			pos += data.forward(frame.heading)*rng.randf_range(-6,6)
			var rock := "rock_07" if snowy else ("namaqualand_boulder_02" if distance%30 == 0 else "namaqualand_boulder_03")
			place(Assets.create_prop(rock, distance, snowy), pos, rng.randf_range(1.5,4.5), true)
			if snowy:
				for row in range(2):
					pos = frame.position + across*rng.randf_range(18+row*20,32+row*27)
					pos += data.forward(frame.heading)*rng.randf_range(-7,7)
					place(Assets.create_snow_tree(distance+row), pos, rng.randf_range(0.8,1.5))
			else:
				if distance%60 == 0:
					pos = frame.position + across*rng.randf_range(22,48)
					place(Assets.create_prop("quiver_tree_01",0),pos,rng.randf_range(2.3,3.6))
				for patch in range(3):
					pos = frame.position + across*rng.randf_range(13,44)
					pos += data.forward(frame.heading)*rng.randf_range(-9,9)
					place(Assets.create_prop("shrub_02",distance+patch),pos,rng.randf_range(0.8,1.8))
	# Larger outcrops belong to the hills, away from all road segments.
	for distance in range(0,int(data.length_m),65):
		var frame: Dictionary = data.sample(distance)
		for side in [-1.0,1.0]:
			var pos: Vector3 = frame.position + data.right(frame.heading)*side*rng.randf_range(65,125)
			var rock := "rock_07" if snowy else "namaqualand_boulder_03"
			place(Assets.create_prop(rock,distance,snowy),pos,rng.randf_range(9,19),true)

func place(node: Node3D, pos: Vector3, size: float, rock: bool = false) -> void:
	# The alpine scan measures only 32 cm across. Match the other boulders.
	if node.get_meta("biome_asset") == "rock_07": size *= 7.0
	var radius: float = node.get_meta("source_radius")*size
	if not landscape.clear_of_road(pos,radius):
		node.free()
		return
	pos.y = terrain.height_at(pos.x,pos.z) - (radius*0.23 if rock else 0.15)
	node.position = pos
	node.scale = Vector3.ONE*size
	node.rotation.y = rng.randf_range(0,TAU)
	node.set_meta("clearance_radius",radius)
	landscape.scenery.add_child(node)
