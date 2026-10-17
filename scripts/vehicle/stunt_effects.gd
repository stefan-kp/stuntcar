extends Node3D
# Small local effects use the same motion state as the car.
var flames: Node3D
var smoke: Array[CPUParticles3D] = []

func _ready() -> void:
	flames = Node3D.new()
	flames.name = "TurboFlames"
	add_child(flames)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("58bfff")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color("158dff")
	material.emission_energy_multiplier = 4.0
	for side in [-1.0,1.0]:
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.005
		cone.bottom_radius = 0.1
		cone.height = 0.85
		cone.radial_segments = 12
		flame.mesh = cone
		flame.material_override = material
		flame.rotation.x = PI / 2.0
		flame.position = Vector3(side * 0.52,0.36,2.25)
		flames.add_child(flame)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,1,1,0.65),Color(1,1,1,0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1.0,0.5)
	var mist := StandardMaterial3D.new()
	mist.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mist.vertex_color_use_as_albedo = true
	mist.albedo_texture = texture
	mist.albedo_color = Color(0.72,0.78,0.8,0.35)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.9,0.9)
	quad.material = mist
	for side in [-1.0,1.0]:
		var particles := CPUParticles3D.new()
		particles.name = "TireSmokeLeft" if side < 0 else "TireSmokeRight"
		particles.emitting = false
		particles.amount = 24
		particles.lifetime = 0.75
		particles.local_coords = false
		particles.mesh = quad
		particles.position = Vector3(side * 0.86,0.12,1.35)
		particles.direction = Vector3(0,0.4,1)
		particles.spread = 24.0
		particles.initial_velocity_min = 1.0
		particles.initial_velocity_max = 3.0
		particles.gravity = Vector3(0,0.5,0)
		particles.scale_amount_min = 0.4
		particles.scale_amount_max = 1.0
		var fade := Gradient.new()
		fade.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
		particles.color_ramp = fade
		add_child(particles)
		smoke.append(particles)
	reset()

func update(model) -> void:
	visible = true
	flames.visible = model.boost_remaining > 0.0
	flames.scale.z = 0.88 + 0.12 * sin(model.elapsed_s * 71.0)
	var sliding: bool = not model.airborne and model.speed_mps > 8.0 and (absf(model.drift_angle) > deg_to_rad(3.0) or (model.emergency_braking or model.assist_speed_active))
	for particles in smoke: particles.emitting = sliding

func suspend() -> void:
	visible = false
	for particles in smoke: particles.emitting = false

func reset() -> void:
	flames.visible = false
	for particles in smoke:
		particles.emitting = false
		particles.restart()
	suspend()

func update_spatial(state: Dictionary, events: Array[Dictionary]) -> void:
	visible = true
	flames.visible = state.boosting
	var contact: bool = state.grounded
	var impact := false
	for event in events:
		if event.type == "landing" and event.magnitude > 2: impact = true
	for particles in smoke:
		particles.speed_scale = 0 if state.get("paused", false) else 1
		particles.emitting = contact and (state.braking or state.slip_mps > 0.8 or impact)

func freeze_spatial() -> void:
	for particles in smoke: particles.speed_scale = 0
