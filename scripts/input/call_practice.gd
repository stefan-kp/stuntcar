extends RefCounted
const Profile = preload("res://scripts/input/call_profile.gd")
var phase := "ready"
var error := ""
var device := ""
var noise: Array[float] = []
var calls: Array[Dictionary] = []
var samples: Array[float] = []
var elapsed := 0.0
var call_seconds := 0.0
var silent_seconds := 0.0
var threshold := 0.0
var saved: Dictionary = {}
func reset() -> void:
	phase = "ready"
	error = ""
	noise.clear()
	calls.clear()
	samples.clear()
	elapsed = 0.0
	call_seconds = 0.0
	silent_seconds = 0.0
func begin(microphone: String) -> void:
	reset()
	device = microphone
	phase = "noise"
func profile_data() -> Dictionary: return saved.duplicate(true)
func receive(level: Dictionary, delta: float) -> void:
	if phase not in ["noise","call","pause"] or delta <= 0: return
	var rms = level.get("rms",-1.0)
	if not Profile.Calibration.valid_signal(rms): return
	if level.get("clipped",false):
		phase = "retry";error = "I18N_CALL_RETRY";return
	if phase == "noise":
		noise.append(float(rms))
		elapsed += delta
		if elapsed >= 2.0 - 0.00001:
			var sorted := noise.duplicate();sorted.sort()
			threshold = maxf(0.001,2.0*sorted[mini(sorted.size()-1,int(ceil(sorted.size()*0.95))-1)])
			phase = "call"
		return
	if rms > threshold:
		phase = "call"
		silent_seconds = 0.0
		call_seconds += delta
		if samples.size() < 600: samples.append(float(rms))
		if call_seconds > 3.0:
			phase = "retry";error = "I18N_CALL_RETRY"
	elif not samples.is_empty():
		phase = "pause"
		silent_seconds += delta
		if silent_seconds >= 0.3:
			if call_seconds < 0.15:
				phase = "retry";error = "I18N_CALL_RETRY";return
			calls.append({"rms_samples":samples.duplicate(),"duration_s":call_seconds,"clipped":false})
			samples.clear();call_seconds=0.0;silent_seconds=0.0;phase="call"
			if calls.size() == 3:
				var result: Dictionary = Profile.fit(noise,calls,device)
				error = result.error
				phase = "done" if error.is_empty() else "retry"
				if error.is_empty(): saved = result.profile
