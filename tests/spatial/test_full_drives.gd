extends "res://tests/spatial/test_base.gd"
const Factory=preload("res://scripts/track/track_factory.gd")
const Cases=preload("res://tests/spatial/full_drive_cases.gd")
func _initialize()->void:
	var loaded:Dictionary=Factory.load_track("res://tracks/06_stuntlabor.json")
	check(loaded.errors.is_empty(),"course definition valid")
	if not loaded.errors.is_empty():done();return
	for level in ["very_easy","easy"]:
		for speed in [0.0,5.0,14.0,22.0,35.0,46.0,58.0]:
			var clean:=Cases.record(loaded.track,level,speed)
			check(clean.finished,"clean %s %.1f %s"%[level,speed,clean.element])
			for case in ["late","wrong","missing","faster","slower","alternate"]:
				var result:=Cases.record(loaded.track,level,speed,case)
				print(level," ",speed," ",case," ",result.mode," ",result.element," ",result.seconds)
				if case in ["late","wrong"] and result.finished:check(result.seconds>=clean.seconds,"rescue does not save time")
				if case in ["faster","alternate"]:check(result.finished,"assisted speed case finishes")
				if case=="slower":check(result.mode=="grounded","full brake stops safely")
				if case=="missing":check(not result.finished,"missing turn cannot finish")
	done()
