extends RefCounted

const CallProfile = preload("res://scripts/input/call_profile.gd")
const CallPractice = preload("res://scripts/input/call_practice.gd")

const VoiceStrength = preload("res://scripts/input/voice_strength.gd")
const VoicePractice = preload("res://scripts/input/voice_practice.gd")
const VoiceCalibration = preload("res://scripts/input/voice_calibration.gd")

signal action_requested(action: String)
var model
var state := "MENU"
var menu_index := 0
var previous_state := "MENU"
var last_key := 0
var remembered_curve := -1
var fall_time := 0.0
var retry_count := 0
var checkpoint_m := 0.0
var total_time := 0.0
var sound_enabled := true
var engine_volume := 0.75
var environment_volume := 0.5
var hint_volume := 1.0
var voice_enabled := false
var voice_mode := "direct"
var practice = VoicePractice.new()
var paused_from := "RUNNING"
var control_return := "MENU"
var control_mode := "keys"
var routes: Array[Dictionary] = []
var catalog_errors: Array[String] = []

var selected_assist_id := "very_easy"
var call_profile: Dictionary = {}
var call_practice = CallPractice.new()

func set_selected_assist(id: String) -> bool:
	if id not in ["very_easy", "easy"]: return false
	selected_assist_id = id
	action_requested.emit("save_settings")
	return true

func assist_name(id: String) -> String:
	return tr("I18N_ASSIST_VERY_EASY") if id == "very_easy" else tr("I18N_ASSIST_EASY")

func submit_call(packet: Dictionary, microphone: String) -> bool:
	if state != "RUNNING" or not voice_enabled or model.assist_id != "very_easy": return false
	if not CallProfile.validate(call_profile, microphone).is_empty(): return false
	if packet.get("has_command", true) != false: return false
	for key in ["call_id", "epoch", "opportunity_id"]:
		var value = packet.get(key)
		if not model.track.number(value) or value < 0 or value != floor(value): return false
	var duration = packet.get("speech_seconds")
	if not model.track.number(duration) or duration < call_profile.min_call_s or duration > call_profile.max_call_s: return false
	if not VoiceCalibration.valid_signal(packet.get("peak_rms")) or packet.peak_rms < call_profile.on_rms: return false
	model.refresh_assist()
	if packet.opportunity_id != model.assist_state().opportunity_id: return false
	var accepted: bool = model.request_assisted_turn(0, true, "call:%d:%d" % [packet.epoch, packet.call_id])
	if accepted: remembered_curve = model.active_curve_id
	return accepted

func submit_voice(command: String, strength: float = VoiceStrength.NORMAL, event_id: String = "") -> bool:
	match command:
		"left", "right":
			if state != "RUNNING": return false
			var accepted: bool = model.request_turn(-1 if command == "left" else 1, strength, event_id)
			remembered_curve = model.active_curve_id
			return accepted
		"faster", "slower":
			if state != "RUNNING": return false
			model.change_speed(1 if command == "faster" else -1, strength)
		"pause":
			if state != "RUNNING": return false
			pause()
		"resume":
			if state != "PAUSED": return false
			activate(0)
		"start":
			if state not in ["MENU", "FINISHED"]: return false
			restart()
		"next", "select":
			if state not in ["MENU", "PAUSED", "FINISHED", "SETTINGS", "CONTROL", "TRACKS", "AUDIO"]: return false
			press(-1 if command == "next" else 1)
		_: return false
	return true

func _init(drive_model) -> void:
	model = drive_model

func entries() -> Array[String]:
	var voice_entry := tr("I18N_CONTROL_VOICE_ENTRY") if control_mode == "voice" else tr("I18N_CONTROL_KEYS_ENTRY")
	match state:
		"MENU": return [tr("I18N_MENU_START"), tr("I18N_MENU_TRACKS"), tr("I18N_MENU_SETTINGS"), tr("I18N_MENU_QUIT")]
		"PAUSED": return [tr("I18N_MENU_CONTINUE"), tr("I18N_MENU_RESTART"), tr("I18N_MENU_SETTINGS"), voice_entry, tr("I18N_MENU_QUIT")]
		"FINISHED": return [tr("I18N_MENU_AGAIN"), tr("I18N_MENU_MAIN"), tr("I18N_MENU_TRACKS"), tr("I18N_MENU_QUIT")]
		"SETTINGS": return [tr("I18N_HINT_SECONDS") % int(model.hint_seconds), tr("I18N_SOUND_ON") if sound_enabled else tr("I18N_SOUND_OFF"), tr("I18N_KEYS_CHANGE"), voice_entry, tr("I18N_MENU_VOLUME"), tr("I18N_MENU_VOICE_PRACTICE"), tr("I18N_ASSIST_SELECT") % assist_name(selected_assist_id), tr("I18N_MENU_BACK")]
		"PRACTICE": return [tr("I18N_PRACTICE_START"), tr("I18N_PRACTICE_MODE_ONE") if voice_mode == "direct" else tr("I18N_PRACTICE_MODE_TWO"), tr("I18N_PRACTICE_BACK")]
		"AUDIO": return [tr("I18N_VOLUME_ENGINE") % roundi(engine_volume * 100), tr("I18N_VOLUME_ENVIRONMENT") % roundi(environment_volume * 100), tr("I18N_VOLUME_HINTS") % roundi(hint_volume * 100), tr("I18N_MENU_BACK")]
		"CONTROL": return [tr("I18N_CONTROL_KEYS"), tr("I18N_CONTROL_VOICE")]
		"TRACKS":
			var result: Array[String] = []
			for route in routes: result.append(route.name)
			result.append(tr("I18N_MENU_SETTINGS"))
			result.append(tr("I18N_MENU_QUIT"))
			return result
	return []

func press(direction: int, strength: float = VoiceStrength.NORMAL) -> void:
	if state == "RUNNING":
		last_key = direction
		model.request_turn(direction, strength)
		remembered_curve = model.active_curve_id
		return
	var options := entries()
	if options.is_empty():
		return
	if direction == -1:
		menu_index = (menu_index + 1) % options.size()
	else:
		activate(menu_index)

func activate(index: int) -> void:
	if index < 0 or index >= entries().size():
		return
	match state:
		"MENU":
			if index == 0: restart()
			elif index == 1: open_tracks()
			elif index == 2: open_settings()
			else: action_requested.emit("quit")
		"PAUSED":
			if index == 0:
				state = paused_from
				last_key = 0
			elif index == 1: restart()
			elif index == 2: open_settings()
			elif index == 3: open_controls()
			else: action_requested.emit("quit")
		"FINISHED":
			if index == 0: restart()
			elif index == 1: go_to_menu()
			elif index == 2: open_tracks()
			else: action_requested.emit("quit")
		"SETTINGS":
			if index == 0:
				var values := [3.0, 5.0, 8.0]
				model.hint_seconds = values[(values.find(model.hint_seconds) + 1) % 3]
				action_requested.emit("save_settings")
			elif index == 1:
				sound_enabled = not sound_enabled
				action_requested.emit("save_settings")
			elif index == 2: action_requested.emit("rebind")
			elif index == 3: open_controls()
			elif index == 4:
				state = "AUDIO"
				menu_index = 0
			elif index == 5:
				state = "PRACTICE"
				menu_index = 0
				practice.prepare(voice_mode)
				action_requested.emit("practice_open")
			elif index == 6:
				set_selected_assist("easy" if selected_assist_id == "very_easy" else "very_easy")
			else:
				state = previous_state
				menu_index = 0

		"PRACTICE":
			if index == 0: action_requested.emit("practice_start")
			elif index == 1: action_requested.emit("practice_mode")
			else: close_practice()

		"AUDIO":
			if index < 3:
				var key: String = ["engine_volume", "environment_volume", "hint_volume"][index]
				set(key, fmod(float(get(key)) + 0.25, 1.25))
				action_requested.emit("save_settings")
			else:
				state = "SETTINGS"
				menu_index = 4

		"CONTROL":
			control_mode = "keys" if index == 0 else "voice"
			state = control_return
			menu_index = 0
			action_requested.emit("control_" + control_mode)
		"TRACKS":
			if index < routes.size():
				state = "MENU"
				menu_index = 0
				action_requested.emit("track:" + routes[index].path)
				if state == "TRACKS": return
				if control_mode.is_empty():
					control_return = "MENU"
					state = "CONTROL"
			elif index == routes.size(): open_settings()
			else: action_requested.emit("quit")

func close_practice() -> void:
	practice.prepare(voice_mode)
	state = "SETTINGS"
	menu_index = 5
	action_requested.emit("practice_closed")

func open_controls() -> void:
	control_return = state
	state = "CONTROL"
	menu_index = 0 if control_mode == "keys" else 1

func open_tracks() -> void:
	var report: Dictionary = model.track.scan_catalog()
	routes.assign(report.routes)
	catalog_errors.assign(report.errors)
	state = "TRACKS"
	menu_index = 0
	for i in range(routes.size()):
		if routes[i].path == model.track.source_path: menu_index = i


func restart() -> void:
	model.set_assist_level(selected_assist_id)
	model.reset(5.0)
	state = "RUNNING"
	menu_index = 0
	last_key = 0
	remembered_curve = -1
	retry_count = 0
	checkpoint_m = 5.0
	total_time = 0.0
	action_requested.emit("reset_car")

func go_to_menu() -> void:
	model.reset(5.0)
	state = "MENU"
	menu_index = 0
	last_key = 0
	action_requested.emit("reset_car")

func open_settings() -> void:
	previous_state = state
	state = "SETTINGS"
	menu_index = 0

func pause() -> void:
	if state in ["RUNNING", "FALLING"]:
		paused_from = state
		state = "PAUSED"
		menu_index = 0
		last_key = 0

func step(delta: float) -> void:
	if state == "RUNNING":
		model.step(delta)
		if remembered_curve >= 0 and model.active_curve_id == -1:
			last_key = 0
			remembered_curve = -1
		for curve in model.track.curves:
			if model.distance_m >= curve.checkpoint_m:
				checkpoint_m = curve.checkpoint_m
		if model.off_road:
			state = "FALLING"
			fall_time = 0.0
			retry_count += 1
		elif model.finished:
			state = "FINISHED"
			menu_index = 0
	elif state == "FALLING":
		fall_time += delta
		if fall_time >= 1.1:
			total_time += model.elapsed_s
			model.reset(checkpoint_m)
			state = "RUNNING"
			menu_index = 0
			last_key = 0
			remembered_curve = -1
			action_requested.emit("reset_car")
