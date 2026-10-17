extends PanelContainer
signal selected(index: int)
const Meter = preload("res://scripts/ui/voice_level_meter.gd")
var prompt: Label
var status: Label
var meter: Control
var buttons: Array[Button] = []
var input_rms := 0.0
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 48; offset_right = -48; offset_top = 48; offset_bottom = -48
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142f3e");style.set_content_margin_all(32)
	add_theme_stylebox_override("panel",style)
	var content := VBoxContainer.new();content.add_theme_constant_override("separation",24);add_child(content)
	var title := Label.new();title.text = tr("I18N_CALL_TITLE");title.add_theme_font_size_override("font_size",32);content.add_child(title)
	prompt = Label.new();prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;prompt.add_theme_font_size_override("font_size",26);prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL;content.add_child(prompt)
	meter = Meter.new();meter.custom_minimum_size = Vector2(0,160);content.add_child(meter)
	status = Label.new();status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;content.add_child(status)
	for i in range(2):
		var button := Button.new();button.custom_minimum_size.y = 48;button.pressed.connect(func(): selected.emit(i));content.add_child(button);buttons.append(button)
func render(session, voice_ready: bool, voice_status: String) -> void:
	var practice = session.call_practice
	match practice.phase:
		"noise": prompt.text = tr("I18N_CALL_NOISE")
		"call": prompt.text = tr("I18N_CALL_SOUND") % (practice.calls.size() + 1)
		"pause": prompt.text = tr("I18N_CALL_PAUSE")
		"done": prompt.text = tr("I18N_CALL_DONE")
		"retry": prompt.text = tr("I18N_CALL_RETRY")
		_: prompt.text = tr("I18N_CALL_READY")
	if not voice_ready: prompt.text = tr("I18N_CALL_WAIT")
	status.text = voice_status
	var scale: float = maxf(1.0, float(session.call_profile.get("on_rms", practice.threshold)) * 2.0)
	meter.set_signal(input_rms / scale, practice.phase == "done", float(practice.calls.size()) / 3.0)
	for i in range(buttons.size()):
		buttons[i].text = ("> " if session.menu_index == i else "") + session.entries()[i]
