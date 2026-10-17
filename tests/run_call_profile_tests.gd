extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,text:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(text)
func _initialize()->void:
	if not FileAccess.file_exists("res://scripts/input/call_profile.gd"):
		check(false,"Das Profil fuer leise Rufe fehlt.");quit(1);return
	var P=load("res://scripts/input/call_profile.gd")
	var calls:Array[Dictionary]=[]
	for i in range(3):calls.append({"rms_samples":[40.0,50.0,45.0],"duration_s":0.3,"clipped":false})
	var result:Dictionary=P.fit([5.0,6.0,5.0],calls,"Quiet mic")
	check(result.error.is_empty(),"Leise Laute genuegen ohne laute Probe.")
	check(P.validate(result.profile,"Quiet mic").is_empty(),"Das leise Profil ist gueltig.")
	check(not P.validate(result.profile,"Other mic").is_empty(),"Ein anderes Mikrofon braucht eine neue Probe.")
	check(result.profile.on_rms<40 and result.profile.on_rms>result.profile.off_rms,"Persoenliche Grenzen trennen das Geraeusch.")
	check(not P.fit([40.0,45.0],calls,"Quiet mic").error.is_empty(),"Zu viel Geraeusch ergibt kein falsches Versprechen.")
	for bad in [NAN,INF,-1.0]:
		var damaged:Dictionary=result.profile.duplicate();damaged.on_rms=bad
		check(not P.validate(damaged,"Quiet mic").is_empty(),"Ungueltige Pegel bleiben gesperrt.")
	var practice=load("res://scripts/input/call_practice.gd").new()
	practice.begin("Quiet mic")
	for i in range(120):practice.receive({"rms":5.0,"clipped":false},1.0/60)
	for call in range(3):
		for i in range(30):practice.receive({"rms":45.0,"clipped":false},1.0/60)
		for i in range(60):practice.receive({"rms":5.0,"clipped":false},1.0/60)
	check(practice.phase=="done" and not practice.profile_data().is_empty(),"Die Rufuebung braucht keine Lautstaerkestufen.")
	practice.reset()
	check(not practice.profile_data().is_empty(),"Abbruch erhaelt das bisherige Profil.")
	print("RUFPROFIL: %d Bedingungen, %d Fehler"%[checks,failures]);quit(0 if failures==0 else 1)
