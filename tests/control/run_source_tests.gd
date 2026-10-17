extends "res://tests/control/test_base.gd"
const F=preload("res://tests/control/fixtures.gd")
func _initialize()->void:
 var K=need("res://scripts/control/keyboard_source.gd")
 var V=need("res://scripts/control/voice_source.gd")
 if K==null or V==null:done();return
 var keys=K.new([KEY_A,KEY_D,KEY_W,KEY_S]);keys.configure("s1",F.catalog())
 var first=keys.capture(KEY_W,true,0)
 check(first.size()==1 and first[0].required_actions[0].action_id=="pedal_up","pedal begin")
 check(keys.capture(KEY_W,true,1).is_empty(),"test_key_repeat_is_not_new_impulse")
 var alias=keys.capture(KEY_UP,true,2)
 check(alias.size()==1 and alias[0].control_id!=first[0].control_id,"test_arrow_alias_keeps_its_own_control")
 var end=keys.capture(KEY_W,false,3)
 check(end.size()==1 and end[0].control_id==first[0].control_id,"test_release_one_of_two_same_action_keys")
 check(keys.refresh(49).is_empty(),"no early refresh")
 check(keys.refresh(52).size()==1,"test_refresh_after_50_ms")
 keys.reset();check(keys.refresh(100).is_empty(),"test_source_loss_stops_refresh")
 check(keys.capture(KEY_UP,true,101).is_empty(),"test_keys_held_before_pause_need_release")
 keys.capture(KEY_UP,false,102)
 var next=keys.capture(KEY_UP,true,103)
 check(next.size()==1 and next[0].control_id!=alias[0].control_id,"test_pause_does_not_reuse_control_id")
 keys.rebind([KEY_J,KEY_L,KEY_I,KEY_K],104)
 check(keys.capture(KEY_W,true,105).is_empty() and keys.capture(KEY_I,true,106).size()==1,"custom binding survives")
 var voice=V.new();voice.configure("s1",F.catalog())
 var word=voice.command({"command":"left","epoch":1,"seq":10,"strength":0.1},0)
 check(word.kind=="explicit" and word.required_actions[0].action_id=="turn_left" and word.required_actions[0].parameters.strength==0.1,"test_voice_maps_exact_strength")
 check(voice.command({"command":"pause","epoch":1,"seq":11},0).kind=="unresolved","test_menu_word_is_not_drive_action")
 check(voice.command({"command":"left","epoch":1,"seq":10,"strength":0.1},1).event_id==word.event_id,"transport duplicate keeps event id")
 var profile={"version":1,"device":"quiet","on_rms":25.0,"off_rms":15.0,"min_call_s":0.15,"max_call_s":3.0,"release_s":0.3}
 var context={"state":"RUNNING","voice_enabled":true,"assist_id":"very_easy","profile":profile,"microphone":"quiet","opportunity_id":4,"epoch":1}
 var packet={"call_id":1,"epoch":1,"opportunity_id":4,"speech_seconds":0.4,"peak_rms":45.0,"has_command":false}
 var call=voice.activate_call(packet,context,0)
 check(call.kind=="activate" and call.required_actions.is_empty(),"valid intentional call")
 var rejected=packet.duplicate();rejected.has_command=true
 check(voice.activate_call(rejected,context,0).is_empty(),"test_rejected_word_never_becomes_call")
 var wrong=context.duplicate();wrong.microphone="other"
 check(voice.activate_call(packet,wrong,0).is_empty(),"test_call_requires_matching_device_and_window device")
 wrong=context.duplicate();wrong.opportunity_id=5
 check(voice.activate_call(packet,wrong,0).is_empty(),"test_call_requires_matching_device_and_window window")
 wrong=context.duplicate();wrong.assist_id="easy"
 check(voice.activate_call(packet,wrong,0).is_empty(),"call only on very easy")
 done()
