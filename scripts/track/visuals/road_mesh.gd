extends RefCounted
# Builds the visible road of parametric pieces from the drive form:
# a deck with edge lines and low barriers, and pillars down to the ground.
# The drive form alone decides contact; these meshes carry no collision.
const HALF_WIDTH := 3.0
const DECK_DEPTH := 0.6
const BARRIER := [Vector2(3.0, 0.0), Vector2(3.3, 0.0), Vector2(3.3, 0.55), Vector2(3.0, 0.55)]
const LINE := [Vector2(2.7, 0.012), Vector2(2.85, 0.012)]
const PILLAR_SPACING_M := 12.0
const GROUND_Y := -2.0
const COLORS := {
	"neutral": {"road": Color("3b4046"), "deck": Color("8d949b"), "barrier": Color("d94436"), "line": Color("eef0f2"), "pillar": Color("9aa1a8")},
	"contrast": {"road": Color("23262a"), "deck": Color("6e757c"), "barrier": Color("f2c230"), "line": Color("ffffff"), "pillar": Color("7b8288")},
}

static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

static func colors(style: String) -> Dictionary:
	return COLORS.get(style, COLORS.neutral)

# One element's deck, edge lines and barriers.
static func build_element(element: Dictionary, style: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Road_" + element.id
	var c := colors(style)
	var top := [Vector2(-HALF_WIDTH, 0), Vector2(HALF_WIDTH, 0)]
	var deck := [Vector2(HALF_WIDTH, 0), Vector2(HALF_WIDTH, -DECK_DEPTH), Vector2(-HALF_WIDTH, -DECK_DEPTH), Vector2(-HALF_WIDTH, 0)]
	root.add_child(extrude(element, [top], c.road, "Surface"))
	root.add_child(extrude(element, [deck], c.deck, "Deck"))
	root.add_child(extrude(element, [LINE, mirror(LINE)], c.line, "Lines"))
	root.add_child(extrude(element, [closed(BARRIER), closed(mirror(BARRIER))], c.barrier, "Barriers"))
	return root

static func mirror(profile: Array) -> Array:
	var result := []
	for i in range(profile.size() - 1, -1, -1): result.append(Vector2(-profile[i].x, profile[i].y))
	return result

static func closed(profile: Array) -> Array:
	return profile + [profile[0]]

# Sweeps open polylines in the cross-section plane (x right, y up) along the element.
static func extrude(element: Dictionary, profiles: Array, color: Color, name: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array = element.points
	var bases: Array = element.bases
	for profile in profiles:
		for i in range(points.size() - 1):
			for k in range(profile.size() - 1):
				var a := ring(points[i], bases[i], profile[k])
				var b := ring(points[i], bases[i], profile[k + 1])
				var c := ring(points[i + 1], bases[i + 1], profile[k + 1])
				var d := ring(points[i + 1], bases[i + 1], profile[k])
				for v in [a, c, b, a, d, c]: st.add_vertex(v)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.mesh = st.commit()
	mesh.material_override = material(color)
	return mesh

static func ring(p: Vector3, basis: Basis, offset: Vector2) -> Vector3:
	return p + basis.x * offset.x + basis.y * offset.y

# Pillars under the whole track, skipped where the road is steeply banked or near the ground.
static func build_pillars(track, style: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Pillars"
	var column := BoxMesh.new()
	column.size = Vector3(1.2, 1.0, 1.2)
	column.material = material(colors(style).pillar)
	var distance := PILLAR_SPACING_M * 0.5
	while distance < track.length_m:
		var frame: Dictionary = track.sample(distance)
		distance += PILLAR_SPACING_M
		if frame.basis.y.y < 0.8: continue
		var top: Vector3 = frame.position - frame.basis.y * DECK_DEPTH
		var height := top.y - GROUND_Y
		if height < 1.0: continue
		var pillar := MeshInstance3D.new()
		pillar.mesh = column
		pillar.transform = Transform3D(Basis.IDENTITY.scaled(Vector3(1, height, 1)), Vector3(top.x, GROUND_Y + height * 0.5, top.z))
		root.add_child(pillar)
	return root
