extends RefCounted
# Opt-in report. Store signal values and commands, never audio or free speech.
const VoiceCalibration = preload("res://scripts/input/voice_calibration.gd")
const VoiceStrength = preload("res://scripts/input/voice_strength.gd")
const MAX_RECORDS := 20000
const PACKET_FIELDS := ["type", "seq", "epoch", "device", "mode", "command", "strength", "rms", "peak_rms", "level", "clipped", "state", "direction", "speech_seconds"]
var file: FileAccess
var origin_ms := 0
var last_flush_ms := 0
var records := 0
var last_state := ""

func start(path: String) -> bool:
	close()
	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	origin_ms = Time.get_ticks_msec()
	last_flush_ms = origin_ms
	records = 0
	last_state = ""
	record("start", {"schema":1, "time":Time.get_datetime_string_from_system(true), "godot":Engine.get_version_info().string})
	file.flush()
	return true

func record(event: String, data: Dictionary) -> void:
	if file == null: return
	var row := data.duplicate(true)
	row["event"] = event
	row["elapsed_ms"] = Time.get_ticks_msec() - origin_ms
	file.store_line(JSON.stringify(row))
	records += 1
	if records >= MAX_RECORDS:
		file.store_line(JSON.stringify({"event":"limit", "elapsed_ms":Time.get_ticks_msec() - origin_ms}))
		file.close()
		file = null
	elif Time.get_ticks_msec() - last_flush_ms >= 1000:
		file.flush()
		last_flush_ms = Time.get_ticks_msec()

func observe_packet(packet: Dictionary) -> void:
	if file == null: return
	var data := {}
	for key in PACKET_FIELDS:
		if packet.has(key): data[key] = packet[key]
	record("packet", data)

func observe_state(scene) -> void:
	if file == null: return
	var calibration = scene.session.practice.calibration
	var state := {"epoch":scene.voice.epoch, "game_state":scene.session.state,
		"practice_phase":scene.session.practice.phase, "expected":scene.session.practice.expected_word(),
		"calibration_phase":calibration.phase, "calibration_stage":calibration.stage,
		"calibration_error":calibration.error, "calibration_values":calibration.values.duplicate(),
		"profile":calibration.profile_data(), "device":scene.voice.device_name,
		"ready":scene.voice.is_ready, "enabled":scene.voice.enabled, "mode":scene.voice.recognition_mode,
		"voice_status":scene.voice.status_text}
	var signature := JSON.stringify(state)
	if signature != last_state:
		last_state = signature
		record("state", state)

func observe_command(packet: Dictionary, strength: float, accepted: bool, scene) -> void:
	if file == null: return
	var calibration = scene.session.practice.calibration
	var reason := "calibrated"
	if not VoiceCalibration.valid_levels(calibration.levels): reason = "missing_profile"
	elif not VoiceCalibration.valid_signal(packet.get("peak_rms")): reason = "invalid_signal"
	elif calibration.device != scene.voice.device_name: reason = "device_mismatch"
	record("command_result", {"seq":packet.get("seq"), "epoch":packet.get("epoch"),
		"command":packet.get("command"), "peak_rms":packet.get("peak_rms"), "assisted":packet.get("assisted", false),
		"fallback_strength":packet.get("strength"), "strength":strength,
		"bars":VoiceStrength.bars(strength), "profile_reason":reason,
		"accepted":accepted, "game_state":scene.session.state})

func close() -> void:
	if file == null: return
	record("end", {})
	if file != null:
		file.close()
		file = null
