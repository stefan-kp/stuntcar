extends SceneTree
const Track=preload("res://scripts/track/track_data.gd")
const Drive=preload("res://scripts/vehicle/drive_model.gd")
const Router=preload("res://scripts/input/command_router.gd")
var failures:=0
var checks:=0
func check(ok:bool,msg:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(msg)
func _initialize()->void:
	var model=Drive.new(Track.new())
	var r=Router.new(model)
	if not r.has_method("set_selected_assist"):
		check(false,"Die Stufenwahl fehlt.");quit(1);return
	check(r.selected_assist_id=="very_easy","Die Voreinstellung ist Sehr leicht.")
	r.restart();r.pause()
	r.set_selected_assist("easy")
	check(model.assist_id=="very_easy","Die Pause aendert nicht die aktive Stufe.")
	r.restart()
	check(model.assist_id=="easy","Der Neustart uebernimmt die Stufe.")
	check(not r.set_selected_assist("hard"),"Es gibt keine unfertigen Stufen.")
	model.reset(70)
	r.submit_voice("left")
	check(model.active_curve_id==-1,"Leicht braucht die richtige Richtung.")
	r.submit_voice("right")
	check(model.active_curve_id==0,"Die richtige Richtung gibt die Kurve frei.")
	r.set_selected_assist("very_easy");r.restart();model.reset(70)
	r.submit_voice("left")
	check(model.active_curve_id==0,"Sehr leicht gleicht die falsche Richtung aus.")
	r.restart();model.reset(70)
	r.submit_voice("faster")
	check(model.active_curve_id==-1 and model.target_speed_mps>22,"Ein Tempobefehl lenkt nicht.")
	r.voice_enabled=true
	r.call_profile={"version":1,"device":"quiet","on_rms":25.,"off_rms":15.,"min_call_s":0.15,"max_call_s":3.,"release_s":0.3}
	model.refresh_assist()
	var packet={"call_id":1,"epoch":1,"opportunity_id":model.assist_state().opportunity_id,"peak_rms":45.,"speech_seconds":0.4,"has_command":false}
	check(r.submit_call(packet,"quiet"),"Ein leiser Ruf gibt die Kurve frei.")
	check(not r.submit_call(packet,"quiet"),"Ein Ruf wirkt nur einmal.")
	check(not r.submit_call(packet,"other"),"Das Mikrofonprofil muss passen.")
	print("STUFENWAHL: %d Bedingungen, %d Fehler"%[checks,failures]);quit(0 if failures==0 else 1)
