extends SceneTree
const Track = preload("res://scripts/track/track_data.gd")
const Drive = preload("res://scripts/vehicle/drive_model.gd")
var failures := 0
var checks := 0
func _initialize() -> void:
	for route in preload("res://tests/helpers/legacy_routes.gd").catalog():
		var track = Track.new(route.path)
		for curve in track.curves:
			for at in [curve.start_m+5.0,curve.end_m-5.0]:
				for side in [-1,1]:
					for direction in [-1,1]:
						var d = Drive.new(track);d.reset(at);d.speed_mps=58;d.target_speed_mps=58
						d.lateral = side*(d.assist_profile.accept_lateral_m-0.01)
						d.position += track.right(d.heading)*d.lateral
						d.heading += direction*(d.assist_profile.accept_heading_rad-0.01)
						var accepted: bool = d.request_assisted_turn(curve.turn_sign,false,"bounds")
						for i in range(1600):
							d.step(1.0/60.0)
							if d.off_road or d.distance_m > curve.end_m+35:break
						checks += 1
						if not accepted or d.off_road or d.distance_m <= curve.end_m+35:
							failures += 1
							print("Grenze fehlgeschlagen: %s Kurve%d bei%.1f Seite%d Richtung%d angenommen%s Ende%.2f lateral%.2f"%[route.path,curve.id,at,side,direction,accepted,d.distance_m,d.lateral])
	print("ANNAHMEGRENZEN: %d Bedingungen, %d Fehler"%[checks,failures]);quit(0 if failures==0 else 1)
