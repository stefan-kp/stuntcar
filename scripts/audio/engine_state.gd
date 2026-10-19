extends RefCounted

# An audio model only. It does not change the car's movement or controls.
# Gears step by about 10%, so each shift dips the revs by a few hundred RPM.
# Gear 1 sits near 2600 RPM at 14 m/s and gear 4 near 6400 RPM at 46 m/s.
const RATIOS := [1.481, 1.346, 1.223, 1.113]
const WHEEL_RPM_PER_MPS := 125.0
# Wheel RPM at which each gear shifts up, and at which the next gear down is
# selected. The down thresholds sit below the post-shift RPM to avoid hunting.
const UP_RPM := [3500.0, 4300.0, 5250.0]
const DOWN_RPM := [2800.0, 3440.0, 4200.0]
const IDLE_RPM := 950.0
const MAX_RPM := 6800.0
const SHIFT_SECONDS := 0.24

var rpm := IDLE_RPM
var throttle := 0.0
var load := 0.0
var gear := 1
var shift_remaining := 0.0
var shift_cooldown := 0.0
var landing_recovery := 0.0
var last_speed := 0.0
var was_airborne := false
var initialized := false

func reset() -> void:
	rpm = IDLE_RPM
	throttle = 0.0
	load = 0.0
	gear = 1
	shift_remaining = 0.0
	shift_cooldown = 0.0
	landing_recovery = 0.0
	last_speed = 0.0
	was_airborne = false
	initialized = false

func step(speed: float, target_speed: float, slope: float, airborne: bool, delta: float) -> void:
	if delta <= 0: return
	speed = maxf(0, speed)
	if not initialized:
		while gear < RATIOS.size() and wheel_rpm(speed) > UP_RPM[gear - 1]:
			gear += 1
		rpm = maxf(IDLE_RPM, wheel_rpm(speed))
		last_speed = speed
		was_airborne = airborne
		initialized = true
	var acceleration := clampf((speed - last_speed) / delta, -18, 10)
	var demand := (target_speed - speed) * 0.2 + acceleration * 0.04
	var grade := sin(slope) * 0.9 if not airborne else 0.0
	var requested := clampf(0.3 + demand + grade, 0, 1) if speed > 0.5 or target_speed > 0.5 else 0.0
	throttle = lerpf(throttle, requested, 1.0 - exp(-delta * 14.0))
	shift_remaining = maxf(0, shift_remaining - delta)
	shift_cooldown = maxf(0, shift_cooldown - delta)
	landing_recovery = maxf(0, landing_recovery - delta * 3.0)
	if was_airborne and not airborne:
		landing_recovery = 1.0
	if not airborne and shift_cooldown <= 0:
		if gear < RATIOS.size() and wheel_rpm(speed) > UP_RPM[gear - 1] and throttle > 0.1:
			gear += 1
			begin_shift()
		elif gear > 1 and wheel_rpm(speed) < DOWN_RPM[gear - 2]:
			gear -= 1
			begin_shift()
	var desired := wheel_rpm(speed) - 500 + throttle * 1100
	if airborne:
		desired = wheel_rpm(speed) + 1200 + throttle * 900
	else:
		desired -= landing_recovery * 900
	desired = clampf(desired, IDLE_RPM, MAX_RPM)
	# RPM falls quickly at a shift or landing and rises smoothly under power.
	rpm = move_toward(rpm, desired, (10000.0 if desired < rpm else 6500.0) * delta)
	var shift_cut := 0.15 if shift_remaining > 0 else 1.0
	load = throttle * shift_cut * (0.45 if airborne else 1.0)
	last_speed = speed
	was_airborne = airborne

func wheel_rpm(speed: float) -> float:
	return speed * WHEEL_RPM_PER_MPS * RATIOS[gear - 1]

func begin_shift() -> void:
	shift_remaining = SHIFT_SECONDS
	shift_cooldown = 0.85
