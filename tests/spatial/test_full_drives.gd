extends "res://tests/spatial/test_base.gd"
const Factory=preload("res://scripts/track/track_factory.gd")
const Cases=preload("res://tests/spatial/full_drive_cases.gd")
func _initialize()->void:
	var loaded:Dictionary=Factory.load_track("res://tracks/06_stuntlabor.json")
	check(loaded.errors.is_empty(),"course definition valid")
	if not loaded.errors.is_empty():done();return
	var matrix:Array[Dictionary]=[]
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spatial/input_cases.json"))
	for level in ["very_easy","easy"]:
		for speed in config.start_speeds_mps:
			var clean:=Cases.record(loaded.track,level,speed)
			matrix.append({"profile":level,"start_speed_mps":speed,"case":"clean","result":clean})
			check(clean.finished,"clean %s %.1f %s"%[level,speed,clean.element])
			for case in ["late","wrong","missing","faster","slower","alternate"]:
				var result:=Cases.record(loaded.track,level,speed,case)
				matrix.append({"profile":level,"start_speed_mps":speed,"case":case,"result":result})
				print(level," ",speed," ",case," ",result.mode," ",result.element," ",result.seconds)
				if case in ["late","wrong"] and result.finished:check(result.seconds>=clean.seconds,"rescue does not save time")
				if case in ["faster","alternate"]:check(result.finished,"assisted speed case finishes")
				if case=="slower":check(result.mode=="grounded","full brake stops safely")
				if case=="missing":check(not result.finished,"missing turn cannot finish")
	var file:=FileAccess.open("/private/tmp/stuntcar-full-matrix.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(matrix,"\t"));file.close()
	done()
