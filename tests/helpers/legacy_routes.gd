extends RefCounted
static func catalog()->Array[Dictionary]:
	var paths:Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/spatial/legacy_routes.json"))
	var result:Array[Dictionary]=[]
	var all:Array=load("res://scripts/track/track_data.gd").catalog()
	for path in paths:
		var found:=false
		for route in all:
			if route.path==path:result.append(route);found=true;break
		if not found:push_error("Missing legacy route: "+str(path))
	return result
