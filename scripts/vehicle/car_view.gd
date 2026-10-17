extends CharacterBody3D

const QualityAssets = preload("res://scripts/quality_assets.gd")
const StuntEffects = preload("res://scripts/vehicle/stunt_effects.gd")
var effects: Node3D
var wheels: Array[Node3D] = []
var body: Node3D
var fall_velocity := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.6
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 0.65, 2.7)
	collision.shape = shape
	collision.position.y = 0.325
	add_child(collision)
	body = QualityAssets.create_car()
	add_child(body)
	for wheel_name in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		wheels.append(body.get_node(wheel_name))
	effects = StuntEffects.new()
	body.add_child(effects)

func place(model) -> void:
	global_position = model.position + Vector3.UP * 0.03
	rotation = Vector3(model.pitch, -model.heading, model.bank)
	body.rotation = Vector3.ZERO
	body.position = Vector3.ZERO
	velocity = Vector3.ZERO
	fall_velocity = 0.0
	if effects != null: effects.reset()
	for wheel in wheels: wheel.rotation.y = 0.0

func drive(model, delta: float) -> void:
	# The assisted model owns the road and flight path. Falling remains physical.
	var before := global_position
	global_position = model.position + Vector3.UP * 0.03
	velocity = (global_position - before) / maxf(delta, 0.001)
	rotation.y = -model.heading
	rotation.z = model.bank
	rotation.x = lerp_angle(rotation.x, model.pitch, 1.0 - exp(-10.0 * delta))
	body.position.y = -sin(model.landing_pulse * PI) * 0.16
	var response := 1.0 - exp(-9.0 * delta)
	var pitch_effect := 0.045 if model.boost_remaining > 0.0 else (-0.075 if (model.emergency_braking or model.assist_speed_active) and model.speed_mps > 0.1 else 0.0)
	body.rotation.x = lerp_angle(body.rotation.x,pitch_effect,response)
	body.rotation.y = lerp_angle(body.rotation.y,model.drift_angle,response)
	body.rotation.z = lerp_angle(body.rotation.z,-model.lateral * 0.055 - model.steering_input * 0.025 - model.drift_angle * 0.12,response)
	effects.update(model)
	for index in range(wheels.size()):
		var wheel := wheels[index]
		wheel.rotation.x -= model.speed_mps * delta / 0.384
		wheel.rotation.y = (-model.steering_input * 0.24 - model.drift_angle * 0.65) if index < 2 else 0.0

func fall(delta: float) -> void:
	effects.suspend()
	velocity.y -= 22.0 * delta
	move_and_slide()
	rotation.z += 0.3 * delta
