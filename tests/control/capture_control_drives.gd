extends SceneTree
var now=0
func _initialize()->void:call_deferred("run")
func run()->void:
 var scene=load("res://scenes/main.tscn").instantiate()
 scene.settings_path="/private/tmp/control-drive-capture-%d.cfg"%OS.get_process_id()
 scene.control_clock=func():return now
 root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);scene.session.sound_enabled=false
 var out="res://.superpowers/sdd/2026-10-17-steuerung-modularisierung-einfache-hinweise/visual"
 var failures=0
 for path in ["res://tracks/01_erste_fahrt.json","res://tracks/06_stuntlabor.json"]:
  for level in ["very_easy","easy"]:
   scene.session.set_selected_assist(level);scene.select_track(path);scene.session.restart()
   var sent={}
   for tick in range(7000):
    if scene.session.state=="PAUSED":scene.session.activate(0);sent.clear()
    now+=17;scene.model.refresh_assist()
    var hint:Dictionary=scene.model.assist_state()
    if hint.phase in ["early","clean"] and not sent.has(hint.opportunity_id):scene.session.press(hint.turn_sign);sent[hint.opportunity_id]=true
    scene._physics_process(1.0/60.0)
    if tick%120==0:scene._process(1.0/60.0);await process_frame
    if scene.session.state in ["FINISHED","FALLING"]:break
   print("RENDER DRIVE: ",path," ",level," ",scene.session.state," ",scene.model.distance_m)
   if scene.session.state!="FINISHED":failures+=1
   scene._process(1.0/60.0)
   for frame in range(3):await process_frame
   RenderingServer.force_draw()
   root.get_texture().get_image().save_png(out+"/drive-"+path.get_file().get_basename()+"-"+level+".png")
 scene.free();quit(0 if failures==0 else 1)
