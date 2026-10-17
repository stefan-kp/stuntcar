extends Node3D

const TrackData = preload("res://scripts/track/track_data.gd")
const Landscape = preload("res://scripts/track/landscape.gd")
const Post = preload("res://assets/stuntcar_kit/shared/road_post.tscn")
const Support = preload("res://assets/stuntcar_kit/shared/bridge_support_8.tscn")
const QualityAssets = preload("res://scripts/quality_assets.gd")
const CanyonStudy = preload("res://scripts/track/canyon_study.gd")
var landscape: Node3D
var data

static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

func build(track_data) -> void:
	data = track_data
	var study: bool = data.source_path == CanyonStudy.ROUTE
	var deck := SurfaceTool.new()
	deck.begin(Mesh.PRIMITIVE_TRIANGLES)
	var borders := SurfaceTool.new()
	borders.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(int(data.length_m)):
		if not data.jump_at(float(i)).is_empty(): continue
		var a: Dictionary = data.sample(float(i))
		var b: Dictionary = data.sample(float(i + 1))
		var ra: Vector3 = a.right
		var rb: Vector3 = b.right
		quad(deck, a.position - ra * 3, a.position + ra * 3, b.position + rb * 3, b.position - rb * 3, Color.WHITE,
			[Vector2(0, i * 0.5), Vector2(3, i * 0.5), Vector2(3, (i + 1) * 0.5), Vector2(0, (i + 1) * 0.5)])
		if study: continue
		for sign_value in [-1.0, 1.0]:
			var color := Color("edf4ed") if (i / 3) % 2 == 0 else Color("ef8055")
			quad(borders, a.position + ra * 2.72 * sign_value + Vector3.UP * 0.015, a.position + ra * 3.0 * sign_value + Vector3.UP * 0.015, b.position + rb * 3.0 * sign_value + Vector3.UP * 0.015, b.position + rb * 2.72 * sign_value + Vector3.UP * 0.015, color)
		if i % 8 < 3:
			quad(borders, a.position - ra * 0.045 + Vector3.UP * 0.02, a.position + ra * 0.045 + Vector3.UP * 0.02, b.position + rb * 0.045 + Vector3.UP * 0.02, b.position - rb * 0.045 + Vector3.UP * 0.02, Color("95b4b5"))
		# Dark visible fascia under the raised deck.
		for sign_value in [-1.0, 1.0]:
			quad(borders, a.position + ra * 3 * sign_value, b.position + rb * 3 * sign_value, b.position + rb * 3 * sign_value - Vector3.UP * 0.6, a.position + ra * 3 * sign_value - Vector3.UP * 0.6, Color("203d4c"))
	var road := finish_mesh(deck, true)
	road.name = "AsphaltRoad"
	road.material_override = QualityAssets.road_material()
	if study: road.material_override = CanyonStudy.road_material()
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var collision := CollisionShape3D.new()
	collision.shape = road.mesh.create_trimesh_shape()
	body.add_child(collision)
	add_child(body)
	if not study: finish_mesh(borders)
	for i in range(8, int(data.length_m) - 4, 8):
		if study: continue
		if not data.jump_at(float(i)).is_empty(): continue
		var frame: Dictionary = data.sample(float(i))
		for side in [-1.0, 1.0]:
			var post := Post.instantiate()
			add_child(post)
			post.position = frame.position + frame.right * 3.35 * side
			post.rotation = Vector3(0, -frame.heading, frame.bank)
	for i in range(12, int(data.length_m), 30):
		if study: continue
		if not data.jump_at(float(i)).is_empty(): continue
		var frame: Dictionary = data.sample(float(i))
		var pillar := Support.instantiate()
		pillar.position = frame.position
		pillar.scale.y = (frame.position.y + 3.0) / 8.0
		pillar.rotation.y = -frame.heading
		add_child(pillar)
	for curve in data.curves:
		make_gate(curve.start_m - 16.0, tr("I18N_SIGN_RIGHT") if curve.turn_sign > 0 else tr("I18N_SIGN_LEFT"), Color("ecf5eb"), Color("203d4c"))
	make_gate(1.0, data.track_name.to_upper(), Color("a3dbc6"), Color("163949"))
	make_gate(data.length_m - 3.0, tr("I18N_SIGN_FINISH"), Color("f4bc73"), Color("203d4c"))
	for jump in data.jumps:
		# On the tall forest ramps, place the sign before the climb so the
		# follow camera cannot pass through the panel above the car.
		var warning_distance: float = 65.0 if data.scenario == "forest" else 22.0
		make_gate(jump.start_m - warning_distance, tr("I18N_SIGN_JUMP"), Color("f4bc73"), Color("203d4c"))
		make_gate(jump.end_m + 15.0, tr("I18N_SIGN_LAND"), Color("a3dbc6"), Color("203d4c"))
	make_landscape()

func quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, uvs: Array = []) -> void:
	var vertices := [a, b, c, d]
	for index in [0, 2, 1, 0, 3, 2]:
		surface.set_color(color)
		if not uvs.is_empty(): surface.set_uv(uvs[index])
		surface.add_vertex(vertices[index])

func finish_mesh(surface: SurfaceTool, textured: bool = false) -> MeshInstance3D:
	surface.generate_normals()
	if textured: surface.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	var mat := material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat
	add_child(mesh)
	return mesh

func make_gate(s: float, text: String, panel_color: Color, text_color: Color) -> void:
	var frame: Dictionary = data.sample(s)
	var gate := Node3D.new()
	add_child(gate)
	gate.position = frame.position
	gate.rotation.y = -frame.heading
	if data.source_path == CanyonStudy.ROUTE:
		# Small roadside signs keep the same driving cues without an arcade gantry.
		box(gate, Vector3(0.08, 2.0, 0.08), Vector3(4.4, 0.9, 0), Color("777b78"))
		box(gate, Vector3(2.2, 0.55, 0.07), Vector3(4.4, 1.8, 0), Color("d8cab1"))
		var sign := Label3D.new()
		sign.text = text
		sign.font_size = 50
		sign.pixel_size = 0.0033
		sign.modulate = Color("242725")
		sign.outline_size = 0
		sign.position = Vector3(4.4, 1.8, 0.045)
		gate.add_child(sign)
		return
	for x in [-3.8, 3.8]:
		box(gate, Vector3(0.18, 4.5, 0.18), Vector3(x, 2.25, 0), Color("244b58"))
	box(gate, Vector3(7.9, 1.15, 0.18), Vector3(0, 4.1, 0), panel_color)
	var label := Label3D.new()
	label.text = text
	label.font_size = 80
	label.pixel_size = 0.008
	label.modulate = text_color
	label.outline_size = 0
	label.position = Vector3(0, 4.1, 0.11)
	label.no_depth_test = false
	gate.add_child(label)

func make_landscape() -> void:
	landscape = Landscape.new()
	add_child(landscape)
	landscape.build(data)
