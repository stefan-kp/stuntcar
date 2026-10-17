extends Node3D

const TrackFactory = preload("res://scripts/track/track_factory.gd")
const DriveFactory = preload("res://scripts/vehicle/drive_model_factory.gd")
const SpatialBuilder = preload("res://scripts/track/visuals/spatial_builder.gd")
const Verification = preload("res://scripts/track/spatial/verification.gd")
const StuntAssist = preload("res://scripts/vehicle/spatial/stunt_assist.gd")
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

var control_clock:Callable
func control_now_ms()->int:
	return int(control_clock.call()) if control_clock.is_valid() else Time.get_ticks_msec()

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
var hint_tone_count:=0
var previous_state := "MENU"
var voice
var voice_context := ""
var voice_diagnostics
var voice_applied_count := 0
var voice_action_text := tr("I18N_VOICE_NO_ACTION")

func _ready() -> void:
	track = TrackData.new()
	model = DriveFactory.create(track)
	model.reset(5.0)
	session = CommandRouter.new(model)
	session.control_clock=control_now_ms
	session.action_requested.connect(on_action)
	load_settings()
	build_selected_track()
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
	session.set_control_bindings([key_left,key_right,key_faster,key_slower])
	if not event.pressed:
		session.capture_key(code,false)
		held.erase(code)
		return
	if event.echo or held.has(code):
		return
	held[code] = true
	session.capture_key(code,true,binding_stage==0)
	if binding_stage > 0:
		capture_binding(code)
		get_viewport().set_input_as_handled()
		return
	if code == KEY_ESCAPE:
		pending.clear()
		if session.state == "CALL_PRACTICE": session.close_call_practice()
		elif session.state == "PRACTICE": session.close_practice()
		else: session.pause()
	elif keyboard_action(code) == "left":
		if session.state!="RUNNING":pending.append(-1)
	elif keyboard_action(code) == "right":
		if session.state!="RUNNING":pending.append(1)
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
	session.ensure_controls()
	model.refresh_assist()
	var voice_waiting:Array[Dictionary]=[]
	sync_voice_context()
	if voice != null:
		voice.poll()
		model.refresh_assist()
		var call_context := current_call_context()
		voice.configure_call(call_context.profile, call_context.opportunity_id, session.state == "CALL_PRACTICE")
		if voice_diagnostics != null: voice_diagnostics.observe_state(self)
		var events: Array[Dictionary] = voice.take_commands()
		for level_event in voice.take_level_events():
			if level_event.epoch != voice.epoch: continue
			if session.state == "CALL_PRACTICE":
				if not voice.is_ready or session.call_practice.device != voice.device_name:
					session.call_practice.reset()
				else:
					var seconds = level_event.get("sample_seconds", 0.0)
					if TrackData.number(seconds) and seconds > 0.0 and seconds <= 0.2:
						session.call_practice.receive(level_event, seconds)
						if session.call_practice.phase == "done" and session.call_profile != session.call_practice.profile_data():
							session.call_profile = session.call_practice.profile_data()
							save_settings()
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
			var intent:Dictionary={}
			if packet.get("type", "") == "feedback":
				intent=session.queue_call(packet,voice.device_name)
				packet=packet.duplicate();packet["assisted"]=true
			elif packet.command in ["left","right","faster","slower"]:
				var normalized=packet.duplicate();normalized.strength=strength
				intent=session.queue_voice(normalized)
			else:
				var accepted:bool=session.submit_voice(packet.command,strength)
				confirm_voice(packet,strength,accepted)
				sync_voice_context()
			if not intent.is_empty():voice_waiting.append({"packet":packet,"strength":strength,"event_id":intent.event_id})
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
	var results:Array[Dictionary]=session.advance_controls(delta)
	for waiting in voice_waiting:
		var accepted=false
		for result in results:
			if result.get("event_id")==waiting.event_id and result.get("result")=="applied":accepted=true
		confirm_voice(waiting.packet,waiting.strength,accepted)
	var was_running: bool = session.state == "RUNNING"
	session.step(delta,false)
	if was_running:
		car.drive(model, delta)
	elif session.state == "FALLING":
		if model.has_method("feedback_state"): car.drive(model, delta)
		else: car.fall(delta)
	if model.has_method("take_motion_events") and (was_running or session.state == "FALLING"):
		var motion_events: Array[Dictionary] = model.take_motion_events()
		car.apply_motion_feedback(model.feedback_state(), motion_events, delta)
		race_audio.apply_motion_events(motion_events, session)
	race_audio.update(model, session, delta)
	model.take_assist_events()
	emit_control_hint_tones()
	previous_state = session.state
	sync_voice_context()
	if voice_diagnostics != null: voice_diagnostics.observe_state(self)

func emit_control_hint_tones()->void:
	if session.state!="RUNNING" or not session.sound_enabled:return
	for hint in session.control_hints:
		var id:String=hint.get("hint_id","")
		if id.is_empty() or hint.get("phase")=="closed" or hinted_ids.has(id):continue
		hinted_ids[id]=true;hint_tone_count+=1;race_audio.play_hint()

func confirm_voice(packet:Dictionary,strength:float,accepted:bool)->void:
	if voice_diagnostics!=null:voice_diagnostics.observe_command(packet,strength,accepted,self)
	var word=str(packet.get("command", ""))
	if accepted:
		if packet.get("assisted",false):word="left" if model.last_command<0 else "right"
		voice_applied_count+=1
		voice_action_text=(tr("I18N_VOICE_ASSIST_ACTION") if packet.get("assisted",false) else tr("I18N_VOICE_ACTION"))%[word,voice_applied_count]
		if word in ["faster","slower"]:voice_action_text+="\n"+model.speed_feedback
		if session.state=="RUNNING":ui.voice_compass.confirm(word,strength)
	else:voice_action_text=tr("I18N_VOICE_NO_EFFECT")%word

func current_call_context() -> Dictionary:
	var context := {"profile":{},"opportunity_id":-1}
	if session.state != "RUNNING" or binding_stage > 0: return context
	if not session.CallProfile.validate(session.call_profile, voice.device_name).is_empty(): return context
	# Keep the acoustic profile across curve windows and in Easy. Only the
	# opportunity grants unknown-call steering; words use the same noise floor.
	context.profile = session.call_profile
	if model.assist_id == "very_easy" and model.assist_state().phase != "closed":
		context.opportunity_id = model.assist_state().opportunity_id
	return context

func sync_voice_context() -> void:
	if voice == null: return
	var context := "%s:%d:%d" % [session.state, binding_stage, session.practice.generation if session.state == "PRACTICE" else 0]
	if context != voice_context:
		voice_context = context
		session.lose_control_source("voice")
		if session.state!="RUNNING":session.suspend_controls("context")
		clear_speed_keys()
		pending.clear()
		voice.invalidate()
		ui.voice_compass.clear()
		ui.practice_panel.compass.clear()

func on_voice_unavailable(_message: String) -> void:
	session.lose_control_source("voice")
	session.call_practice.reset()
	session.voice_enabled = false
	if session.state == "PRACTICE": session.practice.prepare(session.voice_mode)
	session.pause()
	pending.clear()

func _process(delta: float) -> void:
	if session == null:
		return
	if is_instance_valid(builder.landscape): builder.landscape.follow(car.global_position)
	if model.has_method("feedback_state"):
		if session.state in ["RUNNING","FALLING"]:
			car.drive_spatial(car.spatial_previous,car.spatial_current,Engine.get_physics_interpolation_fraction())
		camera.follow_spatial({"basis":car.global_basis},car.global_position,model.speed_mps,delta)
	else:
		camera.follow(car, model.heading, delta, session.state in ["MENU", "CONTROL", "TRACKS", "PRACTICE"], model.pitch, model.speed_mps, 1.0 if model.boost_remaining > 0.0 else 0.0)
	if session.state != "RUNNING":
		if model.has_method("feedback_state") and session.state == "PAUSED": car.effects.freeze_spatial()
		else: car.effects.suspend()
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
	if session.state == "RUNNING" and session.voice_enabled: ui.voice_text += " · " + voice_action_text
	ui.voice_ready = voice.is_ready
	ui.voice_visible = session.voice_enabled
	var personal_level: float = session.practice.calibration.strength_for(voice.input_rms, voice.input_level, voice.device_name)
	ui.voice_compass.set_input(voice.input_direction, personal_level)
	ui.practice_panel.compass.set_input(voice.input_direction, personal_level)
	ui.call_practice_panel.input_rms = voice.input_rms
	ui.render(session, message)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and session != null:
		if session.state == "PRACTICE":
			session.practice.prepare(session.voice_mode)
			sync_voice_context()
		session.lose_control_source("keyboard")
		session.call_practice.reset()
		session.pause()
		held.clear()
		pending.clear()

func on_action(action: String) -> void:
	if action.begins_with("track:"):
		select_track(action.trim_prefix("track:"))
		return
	match action:
		"call_start":
			if voice.is_ready:
				voice.invalidate()
				session.call_practice.begin(voice.device_name)
			elif not voice.enabled: voice.start(session.voice_mode)
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
			session.lose_control_source("keyboard")
			held.clear()
			pending.clear()
			candidate_keys.clear()
			binding_stage = 1
			bind_timeout = 30.0

func build_selected_track() -> void:
	builder = SpatialBuilder.new() if track.get("format_version") == 2 else TrackBuilder.new()
	add_child(builder)
	if track.get("format_version") == 2: builder.build(track, track.definition.styles)
	else: builder.build(track)
	if session != null:
		session.ensure_controls()
		session.visual_warnings.clear()
		if track.get("format_version") == 2:
			for warning in builder.warnings: session.visual_warnings.append(tr("I18N_STUNT_MODEL_FALLBACK") + " " + warning)

func select_track(path: String) -> void:
	var loaded: Dictionary = TrackFactory.load_track(path)
	if not loaded.errors.is_empty():
		session.open_tracks()
		session.catalog_errors.append(path.get_file() + ": " + str(loaded.errors))
		return
	var replacement = loaded.track
	if loaded.format_version == 2 and not Verification.playable(replacement, StuntAssist.profile(session.selected_assist_id)):
		session.open_tracks()
		session.catalog_errors.append(tr("I18N_STUNT_UNVERIFIED"))
		return
	track = replacement
	var hint: float = model.hint_seconds
	model = DriveFactory.create(track)
	model.hint_seconds = hint
	session.model = model
	model.reset(5.0)
	if is_instance_valid(builder):
		remove_child(builder)
		builder.free()
	build_selected_track()
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
			var loaded: Dictionary = TrackFactory.load_track(selected)
			if loaded.errors.is_empty() and (loaded.format_version == 1 or Verification.playable(loaded.track, StuntAssist.profile(session.selected_assist_id))):
				track = loaded.track
				model = DriveFactory.create(track)
				session.model = model
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
