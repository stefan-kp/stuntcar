extends RefCounted

const STEP := 6.0
const MARGIN := 420.0
var track
var snowy := false
var canyon_study := false
var peaks: Array[Vector4] = []
var samples: PackedVector3Array
var noise := FastNoiseLite.new()
var detail := FastNoiseLite.new()

func _init(route) -> void:
	track = route
	snowy = route.scenario == "alpine"
	canyon_study = route.source_path == "res://tracks/05_canyon_study.json"
	noise.seed = 2107 if snowy else 5462
	noise.frequency = 0.006 if snowy else 0.009
	noise.fractal_octaves = 3
	detail.seed = 981
	detail.frequency = 0.018
	detail.fractal_octaves = 2
	for i in range(0, route.points.size(), 6): samples.append(route.points[i])
	samples.append(route.points[-1])
	if snowy:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77341
		for distance in range(0, int(route.length_m)+1, 160):
			var frame: Dictionary = route.sample(distance)
			for side in [-1.0, 1.0]:
				var pos: Vector3 = frame.position + route.right(frame.heading)*side*rng.randf_range(210,330)
				peaks.append(Vector4(pos.x,pos.z,rng.randf_range(125,230),rng.randf_range(170,280)))

func road_distance(pos: Vector3) -> Vector2:
	var best := INF
	var height := 12.0
	for p in samples:
		var sq := Vector2(pos.x-p.x, pos.z-p.z).length_squared()
		if sq < best:
			best = sq
			height = p.y
	return Vector2(sqrt(best), height)

func height_at(x: float, z: float) -> float:
	var nearest := road_distance(Vector3(x, 0, z))
	var n := noise.get_noise_2d(x, z)
	var small := detail.get_noise_2d(x, z)
	var foothills := smoothstep(15.0, 85.0, nearest.x)
	var horizon := smoothstep(65.0, 280.0, nearest.x)
	var floor_height := minf(nearest.y, 12.0) - 9.0
	if canyon_study:
		# A shallow road cutting, with a shoulder instead of the prototype bridge.
		var valley := nearest.y - 0.8 - smoothstep(7.0, 30.0, nearest.x) * 4.0
		return valley + foothills * (8.0 + small * 7.0) + horizon * (27.0 + n * 31.0)
	if snowy:
		var mountains := 0.0
		for peak in peaks:
			var distance := Vector2(x-peak.x,z-peak.y).length()
			mountains = maxf(mountains,pow(maxf(0.0,1.0-distance/peak.w),1.25)*peak.z)
		return floor_height + foothills*(12.0+small*4.0) + horizon*(mountains*(1.0+n*0.3)+small*5.0)
	var dunes := 10.0 + n * 16.0 + sin(x * 0.022 + z * 0.009 + n * 4.0) * 5.0
	return floor_height + foothills * dunes + horizon * (32.0 + n * 42.0 + small * 3.0)

func create_mesh() -> MeshInstance3D:
	var bounds := AABB(track.points[0], Vector3.ZERO)
	for point in track.points: bounds = bounds.expand(point)
	var origin := Vector2(floor((bounds.position.x-MARGIN)/STEP)*STEP, floor((bounds.position.z-MARGIN)/STEP)*STEP)
	var columns := ceili((bounds.size.x+MARGIN*2)/STEP)+1
	var rows := ceili((bounds.size.z+MARGIN*2)/STEP)+1
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for z in range(rows):
		for x in range(columns):
			var px := origin.x + x*STEP
			var pz := origin.y + z*STEP
			vertices.append(Vector3(px,height_at(px,pz),pz))
			uvs.append(Vector2(px,pz)/5.0)
	for z in range(rows-1):
		for x in range(columns-1):
			var a := z*columns+x
			indices.append_array(PackedInt32Array([a,a+1,a+columns,a+1,a+columns+1,a+columns]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var surface := SurfaceTool.new()
	surface.create_from_arrays(arrays)
	surface.generate_normals()
	surface.generate_tangents()
	var node := MeshInstance3D.new()
	node.name = "BiomeTerrain"
	node.mesh = surface.commit()
	node.create_trimesh_collision()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/landscapes/terrain.gdshader")
	var folder := "snow" if snowy else "sand"
	mat.set_shader_parameter("ground_color", load("res://assets/landscapes/"+folder+"/color.jpg"))
	mat.set_shader_parameter("ground_normal", load("res://assets/landscapes/"+folder+"/normal.jpg"))
	var rock := "rock_07" if snowy else "namaqualand_boulder_02"
	mat.set_shader_parameter("rock_color", load("res://assets/landscapes/"+rock+"/textures/"+rock+"_diff_1k.jpg"))
	mat.set_shader_parameter("snowy", snowy)
	node.material_override = mat
	return node
