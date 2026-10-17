extends RefCounted
const Calibration = preload("res://scripts/input/voice_calibration.gd")
static func validate(data: Dictionary, device: String) -> String:
	if data.get("version") != 1 or device.is_empty() or data.get("device") != device: return "profile_device"
	for key in ["on_rms","off_rms","min_call_s","max_call_s","release_s"]:
		var v = data.get(key)
		if typeof(v) not in [TYPE_FLOAT,TYPE_INT] or not is_finite(float(v)) or v <= 0: return "profile_value"
	if data.on_rms > Calibration.MAX_RMS or data.off_rms >= data.on_rms: return "profile_level"
	if data.min_call_s >= data.max_call_s or data.max_call_s > 5.0 or data.release_s > 2.0: return "profile_duration"
	return ""
static func fit(noise: Array, calls: Array[Dictionary], device: String) -> Dictionary:
	var failure := {"profile":{},"error":"I18N_CALL_RETRY"}
	if noise.is_empty() or calls.size() != 3 or device.is_empty(): return failure
	var sorted := []
	for value in noise:
		if not Calibration.valid_signal(value): return failure
		sorted.append(float(value))
	sorted.sort()
	var n: float = sorted[mini(sorted.size()-1,int(ceil(sorted.size()*0.95))-1)]
	var c := Calibration.MAX_RMS
	for call in calls:
		if call.get("clipped", true) or call.get("duration_s",0.0) < 0.15 or call.get("duration_s",4.0) > 3.0: return failure
		var samples = call.get("rms_samples",[])
		if not samples is Array or samples.is_empty(): return failure
		var total := 0.0
		for value in samples:
			if not Calibration.valid_signal(value): return failure
			total += float(value)
		c = minf(c,total/samples.size())
	if c <= n*2.0: return failure
	var profile := {"version":1,"device":device,"on_rms":n+0.5*(c-n),"off_rms":n+0.25*(c-n),
		"min_call_s":0.15,"max_call_s":3.0,"release_s":0.3}
	if not validate(profile,device).is_empty(): return failure
	return {"profile":profile,"error":""}
