extends "res://tests/control/test_base.gd"
const V=preload("res://scripts/track/spatial/verification.gd")
const Runner=preload("res://scripts/vehicle/spatial/drive_runner.gd")
const Fixtures=preload("res://tests/spatial/fixtures.gd")
const Assist=preload("res://scripts/vehicle/spatial/stunt_assist.gd")
func _initialize()->void:
 for path in ["addons/accessible_controls/core/controller.gd","scripts/control/stuntcar_port.gd","scripts/control/keyboard_source.gd"]:check(path in V.SOURCES,"Digest includes "+path)
 check("tracks/reports/06_stuntlabor.json" not in V.SOURCES,"Report does not hash itself")
 var track=Fixtures.make(["straight_24","straight_24","curve_right_45","straight_24"])
 var inputs:Array[Dictionary]=[{"tick":0,"kind":"turn","value":-1,"event_id":"wrong"}]
 var first=Runner.run(track,Assist.profile("very_easy"),inputs,400)
 var second=Runner.run(track,Assist.profile("very_easy"),inputs,400)
 check(first.crashed and first.final.lateral_m<0,"Wrong direction remains wrong in replay")
 check(first.trace_digest==second.trace_digest and first.help_used==second.help_used and first.inputs==second.inputs,"Same inputs reproduce movement and help")
 done()
