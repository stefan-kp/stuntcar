extends Node3D

const TrackData = preload("res://scripts/track/track_data.gd")
const TrackBuilder = preload("res://scripts/track/track_builder.gd")
const DriveModel = preload("res://scripts/vehicle/drive_model.gd")
const KeyboardControls = preload("res://scripts/input/keyboard_controls.gd")
const CommandRouter = preload("res://scripts/input/command_router.gd")
const CarView = preload("res://scripts/vehicle/car_view.gd")
const FollowCamera = preload("res://scripts/camera/follow_camera.gd")
const GameUI = preload("res://scripts/ui/game_ui.gd")
const RaceAudio = preload("res://scripts/audio/race_audio.gd")
const VoiceBridge = preload("res://scripts/input/voice_bridge.gd")
const VoiceStrength = preload("res://scripts/input/voice_strength.gd")
const VoiceDiagnostics = preload("res://scripts/input/voice_diagnostics.gd")

var track
var builder: Node3D
var control_mode := ""
var settings_path := "user://settings.cfg"
var model
var session
var car: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var sound: AudioStreamPlayer
var race_audio
var key_left := KEY_A
var key_right := KEY_D
var key_faster := KEY_W
var key_slower := KEY_S
var pending: Array[int] = []
var held: Dictionary = {}
var binding_stage := 0
var candidate_keys: Array[int] = []
var bind_timeout := 0.0
var hinted_ids: Dictionary = {}
var previous_state := "MENU"
var voice
var voice_context := ""
var voice_diagnostics
var voice_applied_count := 0
var voice_action_text := tr("I18N_VOICE_NO_ACTION")

func _ready() -> void:
	track = TrackData.new()
	model = DriveModel.new(track)
	model.reset(5.0)
	session = CommandRouter.new(model)
	session.action_requested.connect(on_action)
	load_settings()
	builder = TrackBuilder.new()
	add_child(builder)
	builder.build(track)
	car = CarView.new()
	add_child(car)
	car.place(model)
	camera = FollowCamera.new()
	camera.far = 1800
	add_child(camera)
	camera.current = true
	ui = GameUI.new()
	add_child(ui)
	ui.menu_selected.connect(func(index): session.activate(index))
	update_key_names()
	race_audio = RaceAudio.new()
	add_child(race_audio)
	sound = race_audio.hint
	voice = VoiceBridge.new()
	add_child(voice)
	voice.unavailable.connect(on_voice_unavailable)
	sync_voice_context()
	session.control_mode = control_mode
	session.open_tracks()
	if control_mode == "voice":
		session.voice_enabled = true
		voice.start(session.voice_mode)
	sync_voice_context()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--voice-diagnostics="):
			if start_voice_diagnostics(argument.trim_prefix("--voice-diagnostics=")):
				session.open_settings()
				session.activate(5)
				sync_voice_context()

func start_voice_diagnostics(path: String) -> bool:
	var report = VoiceDiagnostics.new()
	if not report.start(path):
		push_warning("Cannot open the voice report: " + path)
		return false
	if voice_diagnostics != null:
		voice.packet_observed.disconnect(voice_diagnostics.observe_packet)
		voice_diagnostics.close()
	voice_diagnostics = report
	voice.packet_observed.connect(report.observe_packet)
	report.observe_state(self)
	return true

func _exit_tree() -> void:
	if voice_diagnostics != null: voice_diagnostics.close()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not event.pressed:
		held.erase(code)
		return
	if event.echo or held.has(code):
		return
	held[code] = true
	if binding_stage > 0:
		capture_binding(code)
		get_viewport().set_input_as_handled()
		return
	if code == KEY_ESCAPE:
		pending.clear()
		if session.state == "PRACTICE": session.close_practice()
		else: session.pause()
	elif keyboard_action(code) == "left":
		pending.append(-1)
	elif keyboard_action(code) == "right":
		pending.append(1)
	elif keyboard_action(code) in ["faster", "slower"]:
		pass
	else:
		return
	get_viewport().set_input_as_handled()

func keyboard_action(code: int) -> String:
	return KeyboardControls.action_for(code, [key_left, key_right, key_faster, key_slower])

func action_held(action: String) -> bool:
	for code in held:
		if keyboard_action(code) == action: return true
	return false

func clear_speed_keys() -> void:
	for code in held.keys():
		if keyboard_action(code) in ["faster", "slower"]: held.erase(code)

func _physics_process(delta: float) -> void:
	if session == null:
		return
	sync_voice_context()
	if voice != null:
		voice.poll()
		model.refresh_assist()
		var call_opportunity := -1
		if session.state == "RUNNING" and binding_stage == 0 and model.assist_id == "very_easy":
			if session.CallProfile.validate(session.call_profile, voice.device_name).is_empty():
				call_opportunity = model.assist_state().opportunity_id if model.assist_state().phase not in ["closed", "inactive"] else -1
		voice.configure_call(session.call_profile if call_opportunity >= 0 else {}, call_opportunity)
		if voice_diagnostics != null: voice_diagnostics.observe_state(self)
		var events: Array[Dictionary] = voice.take_commands()
		for level_event in voice.take_level_events():
			if level_event.epoch != voice.epoch: continue
			session.practice.capture_level(level_event.rms, level_event.peak_rms, level_event.clipped, level_event.speech_end)
			if voice_diagnostics != null: voice_diagnostics.observe_state(self)
			sync_voice_context()
		var feedback_events: Array[Dictionary] = voice.take_feedback_events()
		if session.state in ["PRACTICE", "RUNNING"]:
			events.append_array(feedback_events)
			events.sort_custom(func(a, b): return a.seq < b.seq)
		for packet in events:
			if packet.epoch != voice.epoch or binding_stage > 0: continue
			var word := str(packet.get("text", packet.get("command", ""))).left(40)
			var strength := VoiceStrength.normalize(packet.get("strength", VoiceStrength.NORMAL))
			strength = session.practice.calibration.strength_for(packet.get("peak_rms"), strength, voice.device_name)
			if session.state == "PRACTICE":
				if packet.get("type", "") == "feedback":
					if not str(packet.heard).is_empty(): session.practice.unrecognized(str(packet.heard))
					sync_voice_context()
				else:
					var accepted: bool = session.practice.receive(packet.command)
					if voice_diagnostics != null: voice_diagnostics.observe_command(packet, strength, accepted, self)
					if accepted:
						sync_voice_context()
						ui.practice_panel.compass.confirm(packet.command, strength)
				continue
			var accepted := false
			if packet.get("type", "") == "feedback":
				accepted = session.submit_call(packet, voice.device_name)
				if not accepted: continue
				packet = packet.duplicate()
				packet["command"] = "left" if model.last_command < 0 else "right"
				packet["assisted"] = true
				word = packet.command
			else:
				accepted = session.submit_voice(packet.command, strength, "word:%d:%s" % [packet.epoch, str(packet.get("event_id", packet.seq))])
			if voice_diagnostics != null: voice_diagnostics.observe_command(packet, strength, accepted, self)
			if accepted:
				voice_applied_count += 1
				voice_action_text = (tr("I18N_VOICE_ASSIST_ACTION") if packet.get("assisted", false) else tr("I18N_VOICE_ACTION")) % [word, voice_applied_count]
				if packet.command in ["faster", "slower"]:
					voice_action_text += "\n" + model.speed_feedback
				if session.state == "RUNNING":
					ui.voice_compass.confirm(packet.command, strength)
				sync_voice_context()
			else:
				voice_action_text = tr("I18N_VOICE_NO_EFFECT") % word
	if session.state == "PRACTICE":
		if session.practice.phase == "waiting" and voice.is_ready:
			session.practice.begin_calibration(session.voice_mode)
			sync_voice_context()
		session.practice.step(delta, voice.is_ready)
		if session.practice.phase == "calibrated":
			if session.practice.calibration.accept_profile(voice.device_name): save_settings()
			session.practice.start(session.voice_mode)
	var both := (action_held("left") and action_held("right")) or (pending.has(-1) and pending.has(1))
	if not both and not pending.is_empty():
		session.press(pending[0])
	pending.clear()
	if binding_stage > 0:
		bind_timeout -= delta
		if bind_timeout <= 0:
			binding_stage = 0
			candidate_keys.clear()
	if session.state == "RUNNING" and binding_stage == 0:
		model.keyboard_speed(int(action_held("faster")) - int(action_held("slower")), delta)
	var was_running: bool = session.state == "RUNNING"
	session.step(delta)
	if was_running:
		car.drive(model, delta)
	elif session.state == "FALLING":
		car.fall(delta)
	race_audio.update(model, session, delta)
	if session.state == "RUNNING":
		var curve: Dictionary = track.next_curve(model.distance_m)
		if not curve.is_empty() and model.distance_m >= curve.start_m - model.input_window_m() and not hinted_ids.has(curve.id):
			hinted_ids[curve.id] = true
			if session.sound_enabled:
				race_audio.play_hint()
	previous_state = session.state
	sync_voice_context()
	if voice_diagnostics != null: voice_diagnostics.observe_state(self)

func sync_voice_context() -> void:
	if voice == null: return
	var context := "%s:%d:%d" % [session.state, binding_stage, session.practice.generation if session.state == "PRACTICE" else 0]
	if context != voice_context:
		voice_context = context
		clear_speed_keys()
		pending.clear()
		voice.invalidate()
		ui.voice_compass.clear()
		ui.practice_panel.compass.clear()

func on_voice_unavailable(_message: String) -> void:
	session.voice_enabled = false
	if session.state == "PRACTICE": session.practice.prepare(session.voice_mode)
	session.pause()
	pending.clear()

func _process(delta: float) -> void:
	if session == null:
		return
	if is_instance_valid(builder.landscape): builder.landscape.follow(car.global_position)
	camera.follow(car, model.heading, delta, session.state in ["MENU", "CONTROL", "TRACKS", "PRACTICE"], model.pitch, model.speed_mps, 1.0 if model.boost_remaining > 0.0 else 0.0)
	if session.state != "RUNNING": car.effects.suspend()
	var message := ""
	if binding_stage == 1:
		message = tr("I18N_KEY_BIND_LEFT")
	elif binding_stage == 2:
		message = tr("I18N_KEY_BIND_RIGHT")
	elif binding_stage == 3:
		message = tr("I18N_KEY_BIND_FASTER")
	elif binding_stage == 4:
		message = tr("I18N_KEY_BIND_SLOWER")
	if binding_stage > 0:
		message += tr("I18N_KEY_BIND_TIMEOUT") % ceili(bind_timeout)
	ui.voice_text = voice.status_text if voice != null else tr("I18N_VOICE_OFF")
	ui.voice_ready = voice.is_ready
	ui.voice_visible = session.voice_enabled
	var personal_level: float = session.practice.calibration.strength_for(voice.input_rms, voice.input_level, voice.device_name)
	ui.voice_compass.set_input(voice.input_direction, personal_level)
	ui.practice_panel.compass.set_input(voice.input_direction, personal_level)
	ui.render(session, message)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and session != null:
		if session.state == "PRACTICE":
			session.practice.prepare(session.voice_mode)
			sync_voice_context()
		session.pause()
		held.clear()
		pending.clear()

func on_action(action: String) -> void:
	if action.begins_with("track:"):
		select_track(action.trim_prefix("track:"))
		return
	match action:
		"practice_open":
			session.voice_enabled = true
			if not voice.enabled or voice.recognition_mode != session.voice_mode:
				voice.start(session.voice_mode)
		"practice_start":
			session.voice_enabled = true
			if voice.is_ready:
				session.practice.begin_calibration(session.voice_mode)
			else:
				session.practice.wait_for_microphone(session.voice_mode)
				if not voice.enabled: voice.start(session.voice_mode)
		"practice_mode":
			session.voice_mode = "checked" if session.voice_mode == "direct" else "direct"
			session.practice.prepare(session.voice_mode)
			session.voice_enabled = true
			voice.start(session.voice_mode)
			save_settings()
		"practice_closed":
			session.voice_enabled = control_mode == "voice"
			if not session.voice_enabled: voice.stop()
		"control_keys", "control_voice":
			control_mode = "voice" if action == "control_voice" else "keys"
			session.control_mode = control_mode
			session.voice_enabled = control_mode == "voice"
			pending.clear()
			voice_applied_count = 0
			voice_action_text = tr("I18N_VOICE_NO_ACTION")
			if session.voice_enabled: voice.start(session.voice_mode)
			else: voice.stop()
			save_settings()
		"quit": get_tree().quit()
		"reset_car":
			clear_speed_keys()
			if race_audio != null: race_audio.reset()
			if voice != null: voice.invalidate()
			if is_instance_valid(car):
				car.place(model)
			if is_instance_valid(camera):
				camera.initialized = false
			hinted_ids.clear()
			pending.clear()
		"save_settings": save_settings()
		"rebind":
			held.clear()
			pending.clear()
			candidate_keys.clear()
			binding_stage = 1
			bind_timeout = 30.0

func select_track(path: String) -> void:
	var replacement = TrackData.new(path)
	if not replacement.valid:
		session.open_tracks()
		session.catalog_errors.append(path.get_file() + ": " + replacement.validation_error)
		return
	track = replacement
	model.track = track
	model.reset(5.0)
	if is_instance_valid(builder):
		remove_child(builder)
		builder.free()
	builder = TrackBuilder.new()
	add_child(builder)
	builder.build(track)
	session.go_to_menu()
	held.clear()
	pending.clear()
	save_settings()


func capture_binding(code: int) -> void:
	if code == KEY_ESCAPE:
		binding_stage = 0
		candidate_keys.clear()
		return
	if code in candidate_keys: return
	candidate_keys.append(code)
	if candidate_keys.size() < 4:
		binding_stage = candidate_keys.size() + 1
		bind_timeout = 30.0
		return
	key_left = candidate_keys[0]
	key_right = candidate_keys[1]
	key_faster = candidate_keys[2]
	key_slower = candidate_keys[3]
	binding_stage = 0
	candidate_keys.clear()
	held.clear()
	save_settings()
	update_key_names()

func update_key_names() -> void:
	ui.left_name = OS.get_keycode_string(key_left)
	ui.right_name = OS.get_keycode_string(key_right)
	ui.faster_name = OS.get_keycode_string(key_faster)
	ui.slower_name = OS.get_keycode_string(key_slower)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "mode", control_mode)
	config.set_value("input", "voice_mode", session.voice_mode)
	config.set_value("input", "voice_calibration", session.practice.calibration.profile_data())
	config.set_value("game", "track", track.source_path)
	config.set_value("game", "assist_level", session.selected_assist_id)
	config.set_value("input", "call_profile", session.call_profile)
	config.set_value("input", "left", key_left)
	config.set_value("input", "right", key_right)
	config.set_value("input", "faster", key_faster)
	config.set_value("input", "slower", key_slower)
	config.set_value("game", "hint_seconds", model.hint_seconds)
	config.set_value("game", "sound", session.sound_enabled)
	for key in ["engine_volume", "environment_volume", "hint_volume"]:
		config.set_value("audio", key, session.get(key))
	var error := config.save(settings_path)
	if error != OK:
		push_warning(tr("I18N_SETTINGS_SAVE_FAILED"))

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var assist = config.get_value("game", "assist_level", "very_easy")
	if assist in ["very_easy", "easy"]: session.selected_assist_id = assist
	var saved_call = config.get_value("input", "call_profile", {})
	if saved_call is Dictionary: session.call_profile = saved_call
	session.practice.calibration.load_profile(config.get_value("input", "voice_calibration", {}))
	var voice_mode = config.get_value("input", "voice_mode", "direct")
	if voice_mode in ["direct", "checked"]: session.voice_mode = voice_mode
	var mode = config.get_value("input", "mode", "")
	if mode in ["keys", "voice"]:
		control_mode = mode
		session.control_mode = mode
	var selected = config.get_value("game", "track", TrackData.DEFAULT_PATH)
	for route in TrackData.catalog():
		if route.path == selected:
			track = TrackData.new(selected)
			model.track = track
			model.reset(5.0)
			break
	var bindings := KeyboardControls.restored(config)
	key_left = bindings[0]
	key_right = bindings[1]
	key_faster = bindings[2]
	key_slower = bindings[3]
	var seconds = config.get_value("game", "hint_seconds", 5.0)
	if seconds in [3.0, 5.0, 8.0]:
		model.hint_seconds = seconds
	var enabled = config.get_value("game", "sound", true)
	if typeof(enabled) == TYPE_BOOL:
		session.sound_enabled = enabled

	for key in ["engine_volume", "environment_volume", "hint_volume"]:
		var volume = config.get_value("audio", key, session.get(key))
		if (typeof(volume) == TYPE_FLOAT or typeof(volume) == TYPE_INT) and is_finite(float(volume)):
			session.set(key, clampf(float(volume), 0.0, 1.0))
