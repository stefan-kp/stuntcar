extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL: ", label)
func need(path: String):
 if not FileAccess.file_exists(path):
  check(false, "Fehlende Umsetzung: " + path)
  return null
 return load(path)
func done() -> void:
 print("CONTROL: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
