extends RefCounted

const CallProfile = preload("res://scripts/input/call_profile.gd")
const CallPractice = preload("res://scripts/input/call_practice.gd")

const VoiceStrength = preload("res://scripts/input/voice_strength.gd")
const VoicePractice = preload("res://scripts/input/voice_practice.gd")
const VoiceCalibration = preload("res://scripts/input/voice_calibration.gd")

const DriveController=preload("res://addons/accessible_controls/core/controller.gd")
const ControlActions=preload("res://scripts/control/stuntcar_actions.gd")
const ControlPort=preload("res://scripts/control/stuntcar_port.gd")
const KeyboardSource=preload("res://scripts/control/keyboard_source.gd")
const VoiceSource=preload("res://scripts/control/voice_source.gd")
var control_clock:Callable=func():return Time.get_ticks_msec()
var controller
var control_port
var keyboard_source=KeyboardSource.new([KEY_A,KEY_D,KEY_W,KEY_S])
var voice_source=VoiceSource.new()
var control_session=""
var control_serial=0
var control_model
var control_attempt=-1
var control_profile=""
var control_hints:Array[Dictionary]=[]
var control_confirmation:Dictionary={}
var compatibility_serial=0
func control_now_ms()->int:return int(control_clock.call())
func ensure_controls()->void:
	var profile=ControlActions.control_profile(model)
	if control_model==model and control_attempt==model.attempt_id and control_profile==profile.profile_id:return
	if controller!=null:controller.suspend("session_replaced",control_now_ms())
	control_serial+=1;control_session="drive:%d"%control_serial
	control_model=model;control_attempt=model.attempt_id;control_profile=profile.profile_id
	control_port=ControlPort.new(model);control_port.reset(control_session)
	controller=DriveController.new(control_port,profile);controller.begin_session(control_session)
	keyboard_source.configure(control_session,controller.catalog);voice_source.configure(control_session,controller.catalog)
	control_hints.clear();control_confirmation.clear()
func suspend_controls(reason:String)->void:
	if controller!=null:controller.suspend(reason,control_now_ms())
	keyboard_source.reset()
func lose_control_source(source:String)->void:
	if controller!=null:controller.lose_source(source,control_now_ms())
	if source=="keyboard":keyboard_source.reset()
func set_control_bindings(bindings:Array)->void:
	if keyboard_source.bindings==bindings:return
	for event in keyboard_source.rebind(bindings,control_now_ms()):
		if state=="RUNNING":controller.submit(event)
func capture_key(code:int,pressed:bool,allow_driving:bool=true)->void:
	ensure_controls()
	var events=keyboard_source.capture(code,pressed,control_now_ms())
	if state=="RUNNING" and allow_driving:
		for event in events:controller.submit(event)
func queue_voice(packet:Dictionary)->Dictionary:
	if state!="RUNNING":return {}
	ensure_controls()
	var intent=voice_source.command(packet,control_now_ms())
	controller.submit(intent)
	return intent
func queue_call(packet:Dictionary,microphone:String)->Dictionary:
	if state!="RUNNING":return {}
	ensure_controls();model.refresh_assist()
	var intent=voice_source.activate_call(packet,{"state":state,"voice_enabled":voice_enabled,"assist_id":model.assist_id,"profile":call_profile,"microphone":microphone,"opportunity_id":model.assist_state().opportunity_id},control_now_ms())
	if not intent.is_empty():controller.submit(intent)
	return intent
func advance_controls(delta:float)->Array[Dictionary]:
	ensure_controls()
	if state!="RUNNING":return []
	if controller.suspended:controller.begin_session(control_session)
	model.refresh_assist()
	var now=control_now_ms()
	for event in keyboard_source.refresh(now):controller.submit(event)
	var results=controller.step(now)
	for result in results:
		if result.get("result")=="applied" and not result.get("actions",[]).is_empty():control_confirmation=result.duplicate(true)
	control_port.advance(delta,now)
	remembered_curve=model.active_curve_id
	return results
func flush_compatibility(intent:Dictionary)->bool:
	if intent.is_empty():return false
	var accepted=false
	for result in advance_controls(0):
		if result.get("event_id")==intent.event_id and result.get("result")=="applied":accepted=true
	return accepted

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
var visual_warnings: Array[String] = []

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
	return flush_compatibility(queue_call(packet,microphone))

func submit_voice(command: String, strength: float = VoiceStrength.NORMAL, event_id: String = "") -> bool:
	match command:
		"left", "right", "faster", "slower":
			compatibility_serial+=1
			return flush_compatibility(queue_voice({"command":command,"strength":strength,"epoch":0,"event_id":event_id if not event_id.is_empty() else "compat:%d"%compatibility_serial}))
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
			if state not in ["MENU", "PAUSED", "FINISHED", "SETTINGS", "CONTROL", "TRACKS", "AUDIO", "CALL_PRACTICE"]: return false
			press(-1 if command == "next" else 1)
		_: return false
	return true

func _init(drive_model) -> void:
	model = drive_model
	ensure_controls()

func entries() -> Array[String]:
	var voice_entry := tr("I18N_CONTROL_VOICE_ENTRY") if control_mode == "voice" else tr("I18N_CONTROL_KEYS_ENTRY")
	match state:
		"MENU": return [tr("I18N_MENU_START"), tr("I18N_MENU_TRACKS"), tr("I18N_MENU_SETTINGS"), tr("I18N_MENU_QUIT")]
		"PAUSED": return [tr("I18N_MENU_CONTINUE"), tr("I18N_MENU_RESTART"), tr("I18N_MENU_SETTINGS"), voice_entry, tr("I18N_MENU_QUIT")]
		"FINISHED": return [tr("I18N_MENU_AGAIN"), tr("I18N_MENU_MAIN"), tr("I18N_MENU_TRACKS"), tr("I18N_MENU_QUIT")]
		"SETTINGS": return [tr("I18N_HINT_SECONDS") % int(model.hint_seconds), tr("I18N_SOUND_ON") if sound_enabled else tr("I18N_SOUND_OFF"), tr("I18N_KEYS_CHANGE"), voice_entry, tr("I18N_MENU_VOLUME"), tr("I18N_MENU_VOICE_PRACTICE"), tr("I18N_ASSIST_SELECT") % assist_name(selected_assist_id), tr("I18N_CALL_TITLE"), tr("I18N_MENU_BACK")]
		"CALL_PRACTICE": return [tr("I18N_CALL_START"), tr("I18N_MENU_BACK")]
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
		compatibility_serial+=1
		var event=keyboard_source.source.begin(control_session,"explicit",[{"action_id":"turn_left" if direction==-1 else "turn_right","parameters":{"strength":strength},"duration_ms":0}],control_now_ms(),250)
		controller.submit(event)
		flush_compatibility(event)
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
				if controller!=null:controller.begin_session(control_session)
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
			elif index == 7:
				state = "CALL_PRACTICE"
				menu_index = 0
				call_practice.reset()
				action_requested.emit("practice_open")
			else:
				state = previous_state
				menu_index = 0

		"CALL_PRACTICE":
			if index == 0: action_requested.emit("call_start")
			else: close_call_practice()

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

func close_call_practice() -> void:
	call_practice.reset()
	state = "SETTINGS"
	menu_index = 7
	action_requested.emit("practice_closed")

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
	catalog_errors.append_array(visual_warnings)
	state = "TRACKS"
	menu_index = 0
	for i in range(routes.size()):
		if routes[i].path == model.track.source_path: menu_index = i


func restart() -> void:
	if model.track.get("format_version") == 2:
		var verification = load("res://scripts/track/spatial/verification.gd")
		var profile: Dictionary = load("res://scripts/vehicle/spatial/stunt_assist.gd").profile(selected_assist_id)
		if not verification.playable(model.track, profile):
			open_tracks()
			catalog_errors.append(tr("I18N_STUNT_UNVERIFIED"))
			return
	model.set_assist_level(selected_assist_id)
	model.reset(5.0)
	ensure_controls()
	state = "RUNNING"
	menu_index = 0
	last_key = 0
	remembered_curve = -1
	retry_count = 0
	checkpoint_m = 5.0
	total_time = 0.0
	action_requested.emit("reset_car")

func go_to_menu() -> void:
	suspend_controls("menu")
	model.reset(5.0)
	ensure_controls()
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
		suspend_controls("pause")
		paused_from = state
		state = "PAUSED"
		menu_index = 0
		last_key = 0

func step(delta: float, process_controls: bool = true) -> void:
	if state == "RUNNING":
		if process_controls:advance_controls(delta)
		model.step(delta)
		control_hints.assign(controller.read_hints(control_now_ms()))
		if remembered_curve >= 0 and model.active_curve_id == -1:
			last_key = 0
			remembered_curve = -1
		for curve in model.track.curves:
			if model.distance_m >= curve.checkpoint_m:
				checkpoint_m = curve.checkpoint_m
		if model.off_road:
			suspend_controls("falling")
			state = "FALLING"
			fall_time = 0.0
			retry_count += 1
		elif model.finished:
			suspend_controls("finished")
			state = "FINISHED"
			menu_index = 0
	elif state == "FALLING":
		if model.has_method("feedback_state"): model.step(delta)
		fall_time += delta
		if fall_time >= 1.1:
			total_time += model.elapsed_s
			model.reset(checkpoint_m)
			ensure_controls()
			state = "RUNNING"
			menu_index = 0
			last_key = 0
			remembered_curve = -1
			action_requested.emit("reset_car")
