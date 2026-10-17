extends "res://tests/spatial/test_base.gd"
const Fixtures=preload("res://tests/spatial/fixtures.gd")
const Verification=preload("res://scripts/track/spatial/verification.gd")
func _initialize()->void:
	var track=Fixtures.make(["straight_24"])
	var profile:Dictionary=load("res://scripts/vehicle/spatial/stunt_assist.gd").profile("very_easy")
	var digest:String=Verification.digest(track,profile)
	check(digest.length()==64,"digest identifies complete driving data")
	var changed:Dictionary=profile.duplicate();changed.hold_mps2+=1
	check(Verification.digest(track,changed)!=digest,"changed force invalidates report")
	var report:={"digest":digest,"status":"tested_samples","samples":[{"element_id":"e0","speed_mps":22.0,"lateral_m":0.0,"mode":"grounded","min_mps":20.0,"max_mps":25.0,"target_mps":22.0}]}
	var state:={"speed_mps":22.0,"lateral_m":0.0,"mode":"grounded"}
	check(not Verification.speed_hint(report,digest,"e0",state).is_empty(),"matching measured sample provides hint")
	check(Verification.speed_hint(report,"other","e0",state).is_empty(),"stale report gives no hint")
	state.speed_mps=23.0
	check(Verification.speed_hint(report,digest,"e0",state).is_empty(),"unmeasured speed not promised")
	track.definition.styles.road="contrast"
	check(Verification.digest(track,profile)==digest,"visual swap retains drive digest")
	track.definition.elements[0].entry_transform.position[0]=1
	check(Verification.digest(track,profile)!=digest,"changed track invalidates report")
	track.definition.elements[0].entry_transform.position[0]=0
	var Runner=load("res://scripts/vehicle/spatial/drive_runner.gd")
	var inputs:Array[Dictionary]=[]
	var first:Dictionary=Runner.run(track,profile,inputs,200)
	var second:Dictionary=Runner.run(track,profile,inputs,200)
	check(first.finished and first.trace==second.trace,"same inputs reproduce complete drive")
	var model=load("res://scripts/vehicle/spatial_drive_model.gd").new(track)
	var manual:Array=[]
	for tick in range(200):
		model.step(1.0/60.0);manual.append(model.state.snapshot())
		if model.finished or model.off_road:break
	check(manual==first.trace,"runner uses actual game movement")
	done()
