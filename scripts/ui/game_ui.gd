extends CanvasLayer

signal menu_selected(index: int)
const TrackSelection = preload("res://scripts/ui/track_selection.gd")
const VoiceCompass = preload("res://scripts/ui/voice_compass.gd")
const PracticePanel = preload("res://scripts/ui/voice_practice_panel.gd")
var practice_panel: PanelContainer
var track_selection: PanelContainer
const INK := Color("142f3e")
const PAPER := Color("f4f5e9")
const MINT := Color("a9e2c8")
var root: Control
var hud: Control
var menu_panel: PanelContainer
var menu_title: Label
var menu_subtitle: Label
var menu_buttons: VBoxContainer
var menu_footer: Label
var route_label: Label
var time_label: Label
var hint_label: Label
var hint_detail: Label
var keys_label: Label
var status_label: Label
var voice_label: Label
var voice_text := tr("I18N_VOICE_OFF")
var voice_visible := false
var voice_ready := false
var voice_compass: Control
var progress: ProgressBar
var minimap: Control
var current_menu := ""
var current_entries: Array[String] = []
var buttons: Array[Button] = []
var left_name := "A"
var right_name := "D"
var faster_name := "W"
var slower_name := "S"

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 20
	root.theme = theme
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := panel(hud, Color("142f3ef5"))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 28
	top.offset_right = -28
	top.offset_top = 24
	top.offset_bottom = 88
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 30)
	top.add_child(top_row)
	var brand := label(tr("I18N_APP_BRAND"), 23, PAPER)
	top_row.add_child(brand)
	route_label = label(tr("I18N_HUD_INITIAL_ROUTE"), 19, MINT)
	route_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(route_label)
	time_label = label("00:00", 24, PAPER)
	top_row.add_child(time_label)
	progress = ProgressBar.new()
	progress.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	progress.offset_left = 30
	progress.offset_right = -30
	progress.offset_top = 91
	progress.offset_bottom = 95
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", style(Color("142f3e40"), 0, 0))
	progress.add_theme_stylebox_override("fill", style(Color("ed8651"), 0, 0))
	hud.add_child(progress)
	var hint_box := VBoxContainer.new()
	hint_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hint_box.offset_left = -300
	hint_box.offset_right = 300
	hint_box.offset_top = 128
	hint_box.add_theme_constant_override("separation", 5)
	hud.add_child(hint_box)
	hint_label = label("", 36, INK)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", PAPER)
	hint_label.add_theme_color_override("font_outline_color", INK)
	hint_label.add_theme_constant_override("outline_size", 8)
	hint_box.add_child(hint_label)
	hint_detail = label("", 20, INK)
	hint_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_detail.add_theme_color_override("font_color", PAPER)
	hint_detail.add_theme_color_override("font_outline_color", INK)
	hint_detail.add_theme_constant_override("outline_size", 6)
	hint_box.add_child(hint_detail)
	var bottom := panel(hud, Color("142f3ef5"))
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 28
	bottom.offset_right = -28
	bottom.offset_top = -124
	bottom.offset_bottom = -24
	var bottom_row := VBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 4)
	bottom.add_child(bottom_row)
	keys_label = label("", 22, PAPER)
	keys_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_row.add_child(keys_label)
	status_label = label("", 16, MINT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_row.add_child(status_label)
	voice_label = label(tr("I18N_VOICE_OFF"), 16, MINT)
	voice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_row.add_child(voice_label)
	voice_compass = VoiceCompass.new()
	voice_compass.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	voice_compass.offset_left = -264
	voice_compass.offset_right = -40
	voice_compass.offset_top = -32
	voice_compass.offset_bottom = 192
	voice_compass.visible = false
	hud.add_child(voice_compass)
	menu_panel = panel(root, Color("142f3ef5"))
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	menu_panel.offset_left = 48
	menu_panel.offset_top = -290
	menu_panel.offset_right = 492
	menu_panel.offset_bottom = 230
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	menu_panel.add_child(content)
	content.add_child(label(tr("I18N_APP_BRAND"), 16, MINT))
	menu_title = label(tr("I18N_MENU_TITLE"), 34, PAPER)
	content.add_child(menu_title)
	menu_subtitle = label("", 19, Color("d0dedb"))
	menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_subtitle.custom_minimum_size = Vector2(365, 64)
	content.add_child(menu_subtitle)
	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 8)
	content.add_child(menu_buttons)
	menu_footer = label("", 15, MINT)
	menu_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(menu_footer)
	practice_panel = PracticePanel.new()
	root.add_child(practice_panel)
	practice_panel.selected.connect(func(index): menu_selected.emit(index))
	track_selection = TrackSelection.new()
	root.add_child(track_selection)
	track_selection.selected.connect(func(index): menu_selected.emit(index))

func style(color: Color, radius: int = 8, padding: int = 20) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(radius)
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = 12
	result.content_margin_bottom = 12
	return result

func panel(parent: Control, color: Color) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", style(color))
	parent.add_child(result)
	return result

func label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

func render(session, rebind_message: String = "") -> void:
	practice_panel.visible = session.state == "PRACTICE"
	track_selection.visible = session.state == "TRACKS"
	hud.visible = session.state not in ["TRACKS", "PRACTICE"]
	if session.state == "PRACTICE":
		menu_panel.visible = false
		practice_panel.render(session, voice_ready, voice_text)
		return
	if session.state == "TRACKS":
		menu_panel.visible = false
		track_selection.render(session, left_name, right_name, voice_text)
		return
	voice_label.text = voice_text
	var model = session.model
	var state: String = session.state
	var driving := state in ["RUNNING", "FALLING"]
	voice_compass.visible = voice_visible and state == "RUNNING"
	menu_panel.visible = not driving
	hint_label.visible = driving
	hint_detail.visible = driving
	progress.value = model.distance_m / model.track.length_m * 100.0
	var speed_text := tr("I18N_HUD_SPEED") % (roundi(model.speed_mps * 3.6) if driving else 0)
	var target_speed: float = model.effective_target_speed()
	if driving and absf(target_speed - model.speed_mps) > 0.3:
		speed_text = tr("I18N_HUD_SPEED_TARGET") % [roundi(model.speed_mps * 3.6), roundi(target_speed * 3.6)]
	time_label.text = tr("I18N_HUD_TIME") % [speed_text, int(session.total_time + model.elapsed_s) / 60, int(session.total_time + model.elapsed_s) % 60]
	route_label.text = tr("I18N_HUD_ROUTE") % [model.track.track_name, int(model.distance_m), int(model.track.length_m)]
	var curve: Dictionary = model.track.next_curve(model.distance_m)
	var near_curve: bool = not curve.is_empty() and curve.start_m - model.distance_m <= model.input_window_m()
	keys_label.text = tr("I18N_DRIVE_KEYS") % [left_name, right_name, faster_name, slower_name]
	status_label.text = tr("I18N_DRIVE_HELP")
	if session.voice_enabled:
		status_label.text = tr("I18N_DRIVE_VOICE")
	if state == "FALLING":
		hint_label.text = tr("I18N_FALL_TITLE")
		hint_detail.text = tr("I18N_FALL_HELP")
	elif model.active_curve_id >= 0:
		hint_label.text = tr("I18N_TURN_LEFT_SELECTED") if model.track.curves[model.active_curve_id].turn_sign < 0 else tr("I18N_TURN_RIGHT_SELECTED")
		if model.correction_remaining > 0.0:
			hint_detail.text = tr("I18N_TURN_CORRECTION")
		elif absf(model.lateral) > 1.6:
			hint_detail.text = tr("I18N_TURN_EDGE")
		else:
			hint_detail.text = tr("I18N_TURN_SELECTED_HELP")
	elif near_curve:
		hint_label.text = tr("I18N_TURN_LEFT") if curve.turn_sign < 0 else tr("I18N_TURN_RIGHT")
		hint_detail.text = tr("I18N_TURN_PROMPT")
	else:
		hint_label.text = tr("I18N_STRAIGHT_TITLE")
		hint_detail.text = tr("I18N_STRAIGHT_HELP")
	var jump: Dictionary = model.track.jump_for_correction(model.distance_m)
	if state == "RUNNING" and not jump.is_empty():
		hint_label.text = tr("I18N_JUMP_AIR") if model.airborne else (tr("I18N_JUMP_LANDED") if model.distance_m >= jump.end_m else tr("I18N_JUMP_AHEAD"))
		if model.lateral > 0.7:
			hint_detail.text = tr("I18N_JUMP_LEFT")
		elif model.lateral < -0.7:
			hint_detail.text = tr("I18N_JUMP_RIGHT")
		else:
			hint_detail.text = tr("I18N_JUMP_READY")
	if driving and model.emergency_braking:
		status_label.text = tr("I18N_FULL_BRAKE")
	elif driving and model.boost_remaining > 0.0:
		status_label.text = tr("I18N_TURBO_BOOST")
	elif driving and model.speed_feedback_seconds > 0.0:
		status_label.text = model.speed_feedback
	elif driving and model.speed_mps > 30.0:
		status_label.text = tr("I18N_HIGH_SPEED")
	if driving:
		current_menu = ""
		return
	keys_label.text = tr("I18N_MENU_KEYS") % [left_name, right_name]
	status_label.text = tr("I18N_MENU_HELP")
	if session.voice_enabled:
		status_label.text = tr("I18N_MENU_VOICE")
	match state:
		"MENU":
			menu_title.text = tr("I18N_MENU_TITLE")
			menu_subtitle.text = model.track.track_name + "\n" + model.track.description
		"PAUSED":
			menu_title.text = tr("I18N_PAUSE_TITLE")
			menu_subtitle.text = tr("I18N_ASSIST_CURRENT_NEXT") % [session.assist_name(model.assist_id), session.assist_name(session.selected_assist_id)]
		"FINISHED":
			menu_title.text = tr("I18N_FINISH_TITLE")
			menu_subtitle.text = tr("I18N_FINISH_FACTS") % [int(model.track.length_m), model.track.curves.size(), session.retry_count]
		"CONTROL":
			menu_title.text = tr("I18N_CONTROL_TITLE")
			menu_subtitle.text = tr("I18N_CONTROL_HELP")
		"TRACKS":
			menu_title.text = tr("I18N_TRACK_TITLE")
			var routes: Array = session.routes
			menu_subtitle.text = routes[session.menu_index].description if session.menu_index < routes.size() else tr("I18N_TRACK_RETURN")
		"AUDIO":
			menu_title.text = tr("I18N_AUDIO_TITLE")
			menu_subtitle.text = tr("I18N_AUDIO_HELP")
		"SETTINGS":
			menu_title.text = tr("I18N_SETTINGS_TITLE")
			menu_subtitle.text = rebind_message if not rebind_message.is_empty() else tr("I18N_SETTINGS_HELP")
	menu_subtitle.custom_minimum_size.y = 40 if state == "SETTINGS" else 64
	menu_footer.visible = state != "SETTINGS"
	menu_footer.text = tr("I18N_MENU_FOOTER")
	if state == "AUDIO":
		menu_footer.text = tr("I18N_AUDIO_FOOTER")
	if state == "CONTROL":
		menu_footer.text = tr("I18N_CONTROL_FOOTER") % [left_name, right_name, faster_name, slower_name]
	var entries: Array[String] = session.entries()
	if current_menu != state or entries != current_entries:
		for button in buttons:
			button.queue_free()
		buttons.clear()
		for i in range(entries.size()):
			var button := Button.new()
			button.text = entries[i]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(0, 46)
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_font_size_override("font_size", 20)
			button.add_theme_stylebox_override("hover", style(Color("bfe8d8")))
			button.add_theme_color_override("font_hover_color", INK)
			button.pressed.connect(func(): menu_selected.emit(i))
			menu_buttons.add_child(button)
			buttons.append(button)
		current_menu = state
		current_entries = entries.duplicate()
	for i in range(buttons.size()):
		buttons[i].add_theme_stylebox_override("normal", style(MINT if i == session.menu_index else Color("294553")))
		buttons[i].add_theme_color_override("font_color", INK if i == session.menu_index else PAPER)
		buttons[i].disabled = not rebind_message.is_empty()
