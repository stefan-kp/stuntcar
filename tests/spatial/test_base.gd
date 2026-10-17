extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func done() -> void:
	print("SPATIAL: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
