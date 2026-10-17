extends Control

const VoiceStrength = preload("res://scripts/input/voice_strength.gd")

const DIRECTIONS := {"left": -PI / 2.0, "right": PI / 2.0, "faster": 0.0, "slower": PI}
const OPPOSITE := {"left": "right", "right": "left", "faster": "slower", "slower": "faster"}
const MINT := Color("a9e2c8")
const PAPER := Color("f4f5e9")
const ORANGE := Color("ed8651")
var steering_bars := true
var input_direction := ""
var input_level := 0.0
var pulses: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_input(direction: String, level: float) -> void:
	input_direction = direction if DIRECTIONS.has(direction) else ""
	input_level = clampf(level, 0.0, 1.0) if is_finite(level) else 0.0
	queue_redraw()

func confirm(direction: String, strength: float) -> void:
	if not DIRECTIONS.has(direction): return
	pulses.erase(OPPOSITE[direction])
	pulses[direction] = {"strength": maxf(VoiceStrength.MIN_SIGNAL, VoiceStrength.normalize(strength)), "remaining": 0.6}
	queue_redraw()

func clear() -> void:
	input_direction = ""
	input_level = 0.0
	pulses.clear()
	queue_redraw()

func advance(delta: float) -> void:
	for direction in pulses.keys():
		pulses[direction].remaining -= maxf(delta, 0.0)
		if pulses[direction].remaining <= 0.0: pulses.erase(direction)
	queue_redraw()

func _process(delta: float) -> void:
	advance(delta)

func lit_bars(direction: String) -> int:
	var strength := input_level if input_direction == direction else 0.0
	if pulses.has(direction): strength = pulses[direction].strength
	return VoiceStrength.bars(strength)

func tip_lit(direction: String) -> bool:
	return pulses.has(direction)

func _draw() -> void:
	var origin := size / 2.0
	var factor := minf(size.x, size.y) / 220.0
	draw_set_transform(origin, 0.0, Vector2.ONE * factor)
	draw_circle(Vector2(0, 3), 107, Color("071b2466"))
	draw_circle(Vector2.ZERO, 105, Color("142f3ef2"))
	draw_arc(Vector2.ZERO, 104, 0, TAU, 100, Color("698d9480"), 1.0, true)
	for direction in DIRECTIONS:
		draw_set_transform(origin, DIRECTIONS[direction], Vector2.ONE * factor)
		var count := lit_bars(direction)
		var remaining: float = pulses[direction].remaining if pulses.has(direction) else 0.0
		var fade := clampf(remaining / 0.22, 0.0, 1.0)
		for index in range(3 if steering_bars or direction not in ["left", "right"] else 0):
			var rect := Rect2(-14, -31 - index * 17, 28, 11)
			var color := MINT if index < 2 else ORANGE
			var active := index < count
			var opacity := 1.0 if input_direction == direction and input_level >= 0.06 else fade
			draw_rect(rect, Color("385460").lerp(color, opacity) if active else Color("385460"))
			draw_rect(rect, Color("a3beb9"), false, 1.0)
		var points := PackedVector2Array([Vector2(-21, -77), Vector2(0, -98), Vector2(21, -77)])
		var tip_color := ORANGE if count == 3 else MINT
		draw_colored_polygon(points, Color("385460").lerp(tip_color, fade) if tip_lit(direction) else Color("385460"))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), PAPER if tip_lit(direction) else Color("a3beb9"), 1.0, true)
	draw_set_transform(origin, 0.0, Vector2.ONE * factor)
	draw_arc(Vector2.ZERO, 11, 0, TAU, 28, Color("a3beb9"), 1.5, true)
	draw_circle(Vector2.ZERO, 3.0 + input_level * 2.0, MINT)
