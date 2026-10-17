extends Node

const VoiceRuntime = preload("res://scripts/input/voice_runtime.gd")
const VoiceCalibration = preload("res://scripts/input/voice_calibration.gd")
const VoiceStrength = preload("res://scripts/input/voice_strength.gd")

signal unavailable(message: String)
signal packet_observed(packet: Dictionary)
const COMMANDS := ["left", "right", "faster", "slower", "pause", "resume", "next", "select", "start"]
var server := TCPServer.new()
var peer: StreamPeerTCP
var child_pid := -1
var enabled := false
var is_ready := false
var recognition_mode := "direct"
var feedback_events: Array[Dictionary] = []
var authenticated := false
var token := ""
var epoch := 0
var last_seq := 0
var last_message_ms := 0
var started_ms := 0
var status_text := tr("I18N_VOICE_OFF")
var buffer := PackedByteArray()
var commands: Array[Dictionary] = []
var input_level := 0.0
var input_rms := -1.0
var input_peak_rms := -1.0
var level_events: Array[Dictionary] = []
var input_direction := ""
var level_ms := 0
var heard_text := ""
var feedback_state := "listening"
var device_name := ""
var feedback_ms := 0

func start(mode: String = "direct") -> void:
	stop()
	recognition_mode = mode if mode in ["direct", "checked"] else "direct"
	var launch := VoiceRuntime.command_for(OS.get_name(), OS.has_feature("editor"), OS.get_executable_path(), ProjectSettings.globalize_path("res://"))
	if not FileAccess.file_exists(launch.executable):
		fail(tr("I18N_VOICE_SETUP_MISSING"))
		return
	if server.listen(0, "127.0.0.1") != OK:
		fail(tr("I18N_VOICE_CONNECT_FAILED"))
		return
	token = Crypto.new().generate_random_bytes(24).hex_encode()
	enabled = true
	started_ms = Time.get_ticks_msec()
	last_message_ms = started_ms
	status_text = tr("I18N_VOICE_STARTING")
	var arguments: PackedStringArray = launch.arguments
	arguments.append_array(PackedStringArray(["--port", str(server.get_local_port()), "--token", token, "--mode", recognition_mode]))
	child_pid = OS.create_process(launch.executable, arguments, false)
	if child_pid < 0: fail(tr("I18N_VOICE_START_FAILED"))

func stop() -> void:
	if peer != null: peer.disconnect_from_host()
	peer = null
	server.stop()
	if child_pid > 0 and OS.is_process_running(child_pid): OS.kill(child_pid)
	child_pid = -1
	enabled = false
	is_ready = false
	authenticated = false
	last_seq = 0
	buffer.clear()
	commands.clear()
	epoch += 1
	status_text = tr("I18N_VOICE_OFF")
	input_level = 0.0
	input_rms = -1.0
	input_peak_rms = -1.0
	level_events.clear()
	input_direction = ""
	feedback_events.clear()
	heard_text = ""
	device_name = ""

func fail(message: String) -> void:
	stop()
	status_text = message
	unavailable.emit(message)

func invalidate() -> void:
	epoch += 1
	heard_text = ""
	feedback_state = "listening"
	feedback_events.clear()
	input_level = 0.0
	input_rms = -1.0
	input_peak_rms = -1.0
	level_events.clear()
	input_direction = ""
	commands.clear()
	if peer != null and authenticated:
		peer.put_data((JSON.stringify({"type":"context", "epoch":epoch}) + "\n").to_utf8_buffer())

func poll() -> void:
	if not enabled: return
	var now := Time.get_ticks_msec()
	if now - level_ms > 300:
		input_level = 0.0
		input_rms = 0.0
		input_peak_rms = 0.0
		input_direction = ""
	if is_ready and now - last_message_ms > 3000:
		fail(tr("I18N_VOICE_CONNECTION_LOST"))
		return
	if not is_ready and now - started_ms > 60000:
		fail(tr("I18N_VOICE_NOT_READY"))
		return
	if peer == null and server.is_connection_available(): peer = server.take_connection()
	if peer != null:
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			fail(tr("I18N_VOICE_CONNECTION_ENDED"))
			return
		var available := peer.get_available_bytes()
		if available > 0:
			var data := peer.get_partial_data(mini(available, 8192))
			if data[0] == OK: consume_bytes(data[1])
	if enabled and child_pid > 0 and not OS.is_process_running(child_pid):
		fail(tr("I18N_VOICE_PROCESS_ENDED"))

func consume_bytes(data: PackedByteArray) -> void:
	if not enabled: return
	buffer.append_array(data)
	while buffer.has(10):
		var end := buffer.find(10)
		if end > 1024:
			fail(tr("I18N_VOICE_BAD_PACKET"))
			return
		var line := buffer.slice(0, end).get_string_from_utf8()
		buffer = buffer.slice(end + 1)
		var packet = JSON.parse_string(line)
		if typeof(packet) != TYPE_DICTIONARY:
			fail(tr("I18N_VOICE_BAD_PACKET"))
			return
		accept_packet(packet)
		if not enabled: return
	if buffer.size() > 1024: fail(tr("I18N_VOICE_BAD_PACKET"))

func accept_packet(packet: Dictionary) -> void:
	var seq = packet.get("seq", 0)
	if typeof(seq) not in [TYPE_INT, TYPE_FLOAT] or float(seq) != floorf(float(seq)) or seq <= last_seq: return
	last_seq = int(seq)
	if not authenticated:
		if packet.get("type") != "hello" or packet.get("token") != token:
			fail(tr("I18N_VOICE_AUTH_FAILED"))
			return
		authenticated = true
		invalidate()
		return
	last_message_ms = Time.get_ticks_msec()
	match packet.get("type", ""):
		"ready":
			is_ready = true
			var mode := str(packet.get("mode", recognition_mode))
			if mode in ["direct", "checked"]: recognition_mode = mode
			device_name = str(packet.get("device", tr("I18N_VOICE_DEFAULT_DEVICE"))).left(60)
			status_text = tr("I18N_VOICE_READY")
			packet_observed.emit(packet)
		"feedback":
			if not is_ready or packet.get("epoch", -1) != epoch: return
			packet_observed.emit(packet)
			var level = packet.get("level", 0.0)
			var valid_level := typeof(level) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(level))
			input_level = clampf(float(level), 0.0, 1.0) if valid_level else 0.0
			input_rms = float(packet.rms) if VoiceCalibration.valid_signal(packet.get("rms")) else -1.0
			input_peak_rms = float(packet.peak_rms) if VoiceCalibration.valid_signal(packet.get("peak_rms")) else -1.0
			if input_rms >= 0.0 and input_peak_rms >= input_rms:
				if level_events.size() >= 64:
					fail(tr("I18N_VOICE_TOO_MANY"))
					return
				level_events.append({"epoch":epoch, "rms":input_rms, "peak_rms":input_peak_rms, "clipped":typeof(packet.get("clipped")) == TYPE_BOOL and packet.get("clipped", false), "speech_end":packet.get("state", "") in ["recognized", "unknown"]})
			level_ms = Time.get_ticks_msec()
			var direction := str(packet.get("direction", ""))
			input_direction = direction if valid_level and direction in ["left", "right", "faster", "slower"] else ""
			var heard := str(packet.get("heard", "")).left(70)
			var state := str(packet.get("state", "listening"))
			if state == "unknown":
				if feedback_events.size() >= 16:
					fail(tr("I18N_VOICE_TOO_MANY"))
					return
				feedback_events.append({"type":"feedback", "epoch":epoch, "seq":last_seq, "heard":heard,
					"peak_rms":input_peak_rms, "speech_seconds":packet.get("speech_seconds", 0.0)})
			if not heard.is_empty() or Time.get_ticks_msec() - feedback_ms > 2000:
				heard_text = heard
				feedback_state = state
			if not heard.is_empty(): feedback_ms = Time.get_ticks_msec()
		"error":
			var code := str(packet.get("message", ""))
			if code not in ["I18N_VOICE_MODEL_MISSING", "I18N_VOICE_AUDIO_LATE", "I18N_VOICE_DELAY", "I18N_VOICE_NO_AUDIO"]:
				code = "I18N_VOICE_UNAVAILABLE"
			fail(tr(code))
		"command":
			if not is_ready or packet.get("epoch", -1) != epoch or packet.get("command", "") not in COMMANDS: return
			if commands.size() >= 16:
				fail(tr("I18N_VOICE_TOO_MANY"))
				return
			var strength = packet.get("strength", VoiceStrength.NORMAL)
			packet["strength"] = VoiceStrength.normalize(strength)
			commands.append(packet)
			packet_observed.emit(packet)

func take_commands() -> Array[Dictionary]:
	var result := commands.duplicate()
	commands.clear()
	return result

func take_level_events() -> Array[Dictionary]:
	var result := level_events.duplicate()
	level_events.clear()
	return result

func take_feedback_events() -> Array[Dictionary]:
	var result := feedback_events.duplicate()
	feedback_events.clear()
	return result

func _exit_tree() -> void:
	stop()
