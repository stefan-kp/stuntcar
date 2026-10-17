extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var scene=load("res://scenes/main.tscn").instantiate()
 scene.settings_path="/private/tmp/control-capture-%d.cfg"%OS.get_process_id()
 root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);scene.session.sound_enabled=false
 var out="res://.superpowers/sdd/2026-10-17-steuerung-modularisierung-einfache-hinweise/visual"
 DirAccess.make_dir_recursive_absolute(out)
 for case in ["normal","wrong","jump"]:
  if case=="jump":scene.select_track("res://tracks/03_sprungstrecke.json")
  scene.session.restart();scene.model.reset(400 if case=="jump" else 70)
  scene.session.ensure_controls()
  if case!="jump":scene.session.press(-1 if case=="wrong" else 1)
  if case=="wrong":scene.session.capture_key(KEY_W,true);scene.session.advance_controls(0.05)
  scene.session.refresh_control_hints();scene.car.place(scene.model)
  scene.camera.initialized=false;scene._process(0.016)
  for frame in range(6):await process_frame
  RenderingServer.force_draw()
  root.get_texture().get_image().save_png(out+"/"+case+".png")
 print("CONTROL CAPTURE: 3 images")
 scene.free();quit()
