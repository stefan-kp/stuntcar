extends RefCounted
const Drive=preload("res://scripts/vehicle/spatial_drive_model.gd")
const Runner=preload("res://scripts/vehicle/spatial/drive_runner.gd")
# Records actual commands, then replays them through the shared runner.
static func record(track,level:String,speed:float=22,case:String="clean")->Dictionary:
	var model=Drive.new(track);model.set_assist_level(level)
	model.state.velocity=-model.state.basis.z*speed;model.sync_fields()
	var controls:Dictionary=Runner.create_controls(model)
	var opposing_help:=false
	var inputs:Array[Dictionary]=[];var requested:Dictionary={}
	for tick in range(12000):
		model.refresh_assist();var hint:Dictionary=model.assist_state()
		var held:=1 if case=="faster" else (-1 if case=="slower" else (1 if tick%240<120 else -1) if case=="alternate" else 0)
		if tick==0 or case=="alternate" and tick%120==0:Runner.apply_input(model,{"tick":tick,"kind":"held_speed","value":held,"event_id":"speed:%d"%tick},controls)
		var phase:bool=hint.phase in ["early","clean"] if case!="late" else hint.phase=="late"
		if phase and case!="missing" and not requested.has(hint.opportunity_id):
			var event:={"tick":tick,"kind":"turn","value":-hint.turn_sign if case=="wrong" else hint.turn_sign,"event_id":"turn:%d"%hint.opportunity_id}
			requested[hint.opportunity_id]=true;Runner.apply_input(model,event,controls)
		Runner.step_controls(controls,tick);model.step(1.0/60.0);model.take_motion_events()
		opposing_help=opposing_help or (model.active_pedal!=0 and model.assist_speed_active and (model.assist_target_mps-model.effective_target_speed())*model.active_pedal<0)
		if model.finished or model.off_road or case=="slower" and tick>600 and model.speed_mps<0.01:break
	return {"inputs":controls.recorded,"opposing_help":opposing_help,"finished":model.finished,"seconds":model.elapsed_s,"mode":model.state.mode,"element":model.state.element_id,"help":model.state.help_used}
