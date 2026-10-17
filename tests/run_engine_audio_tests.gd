extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func tick(motor, speed: float, target: float, seconds: float, flying := false, slope := 0.0) -> void:
	for i in range(roundi(seconds * 60)):
		motor.step(speed, target, slope, flying, 1.0 / 60.0)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(ResourceLoader.exists("res://scripts/audio/engine_state.gd"), "Die berechnete Motordrehzahl fehlt.")
	if failures:
		quit(1)
		return
	var State = load("res://scripts/audio/engine_state.gd")
	var motor = State.new()
	tick(motor, 22, 22, 2)
	var cruise_rpm: float = motor.rpm
	var cruise_throttle: float = motor.throttle
	tick(motor, 22, 32, 0.4)
	check(motor.throttle > cruise_throttle + 0.3, "Gasgeben erhöht die Motorlast schon vor der Tempoänderung.")
	check(motor.rpm > cruise_rpm + 150, "Gasgeben hebt die Drehzahl schon vor der Tempoänderung an.")
	tick(motor, 22, 14, 0.4)
	check(motor.throttle < 0.1 and motor.rpm < cruise_rpm, "Gaswegnehmen senkt Last und Drehzahl.")
	motor.reset()
	tick(motor, 14, 14, 1)
	var shifts := 0
	var audible_drops := 0
	var last_rpm: float = motor.rpm
	var last_gear: int = motor.gear
	var pre_shift_rpm := 0.0
	var rpm_in_range := true
	for i in range(600):
		var speed := minf(46.0, 14.0 + i / 60.0 * 4.0)
		motor.step(speed, 46, 0, false, 1.0 / 60.0)
		if motor.gear > last_gear:
			shifts += 1
			pre_shift_rpm = last_rpm
		if pre_shift_rpm > 0 and motor.rpm < pre_shift_rpm - 200:
			audible_drops += 1
			pre_shift_rpm = 0
		rpm_in_range = rpm_in_range and is_finite(motor.rpm) and motor.rpm >= 800 and motor.rpm <= 7000
		last_rpm = motor.rpm
		last_gear = motor.gear
	check(rpm_in_range, "Die Drehzahl bleibt in allen 600 Schritten im gültigen Bereich.")
	check(shifts >= 2 and audible_drops >= 2, "Die Beschleunigung erzeugt mehrere Gangwechsel mit Drehzahlabfall.")
	var high_gear: int = motor.gear
	tick(motor, 46, 46, 5)
	check(motor.gear == high_gear, "Gleichmäßige Fahrt erzeugt keine wiederholten Gangwechsel.")
	for i in range(480):
		motor.step(maxf(14, 46 - i / 60.0 * 4), 14, 0, false, 1.0 / 60.0)
	check(motor.gear < high_gear, "Langsamere Fahrt schaltet zurück.")
	motor.reset()
	tick(motor, 22, 22, 2)
	cruise_rpm = motor.rpm
	var ground_gear: int = motor.gear
	tick(motor, 22, 22, 1, true)
	var flying_rpm: float = motor.rpm
	check(flying_rpm > cruise_rpm + 700 and motor.gear == ground_gear, "Im Flug dreht der Motor höher, ohne einen Gangwechsel.")
	tick(motor, 22, 22, 0.15)
	check(motor.rpm < flying_rpm - 700, "Die Landung senkt die Drehzahl kurz ab.")
	tick(motor, 22, 22, 2)
	check(absf(motor.rpm - cruise_rpm) < 100, "Nach der Landung kehrt die Drehzahl zum Fahrzustand zurück.")
	tick(motor, 22, 22, 0.5, false, deg_to_rad(25))
	check(motor.throttle > cruise_throttle + 0.2, "Die Rampe erhöht die Motorlast auch bei gleichem Tempo.")
	motor.reset()
	check(motor.gear == 1 and motor.rpm <= 1200 and motor.shift_remaining == 0, "Ein Neustart entfernt alte Gangwechsel und Drehzahländerungen.")
	var audio = load("res://scripts/audio/race_audio.gd").new()
	root.add_child(audio)
	check(audio.get("combustion") != null, "Der erzeugte Motoranteil fehlt.")
	if audio.get("combustion") != null:
		var stream: AudioStreamWAV = audio.combustion.stream
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.data.size() > 100, "Der erzeugte Ton muss sich wiederholen können.")
		var peak := 0
		var mean := 0.0
		for i in range(stream.data.size() / 2):
			var sample := stream.data.decode_s16(i * 2)
			peak = maxi(peak, absi(sample))
			mean += sample
		mean /= stream.data.size() / 2
		check(peak > 5000 and peak < 30000 and absf(mean) < 50, "Der erzeugte Ton hat einen begrenzten Pegel und keinen Gleichanteil.")
		check(absi(stream.data.decode_s16(0) - stream.data.decode_s16(stream.data.size()-2)) < 1500, "Die Wiederholung vermeidet einen großen Pegelsprung.")
	audio.free()
	print("MOTORTON: %d Prüfungen, %d Fehler" % [checks, failures])
	quit(0 if failures == 0 else 1)
