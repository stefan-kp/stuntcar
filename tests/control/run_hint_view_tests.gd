extends "res://tests/control/test_base.gd"
func _initialize()->void:call_deferred("run")
func run()->void:
 var P=need("res://scripts/ui/hint_presenter.gd")
 if P==null:done();return
 var hints:Array[Dictionary]=[{"hint_id":"curve:1","kind":"direction","phase":"early","recommended_actions":["turn_right"],"target_speed_mps":22.0,"min_speed_mps":null,"max_speed_mps":null,"speed_evidence":"assist_target","detail_code":"saved"}]
 var confirmation={"result":"applied","actions":[{"action_id":"turn_left"}]}
 var text=P.present(hints,confirmation,"RUNNING")
 check("Left" in text.title and "Right" not in text.title,"Confirmation shows actual requested direction")
 check("Recommended" in text.detail and "79" in text.detail,"Target carries recommended label")
 check("0–" not in text.detail and "maximum" not in text.detail,"Unknown bounds never display a fake zero")
 var before=JSON.stringify([hints,confirmation]);P.present(hints,confirmation,"RUNNING")
 check(before==JSON.stringify([hints,confirmation]),"Presenter has no execution effect")
 check(P.present(hints,confirmation,"PAUSED").hint_id=="","Pause clears visible hint")
 check(P.present([],{},"RUNNING").hint_id=="","Model swap has no old hint")
 var scene=load("res://scenes/main.tscn").instantiate()
 scene.settings_path="/private/tmp/control-hint-test-%d.cfg"%OS.get_process_id()
 root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
 scene.session.restart();scene.session.refresh_control_hints()
 scene.session.sound_enabled=true
 scene.emit_control_hint_tones();var count=scene.hint_tone_count
 for tick in range(10):scene.emit_control_hint_tones();scene.ui.render(scene.session)
 check(scene.hint_tone_count==count and count==1,"One tone per hint window")
 scene.session.pause();scene.emit_control_hint_tones()
 check(scene.session.control_hints.is_empty() and scene.hint_tone_count==count,"Pause clears hints and stops tones")
 scene.free()
 done()
