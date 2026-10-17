extends RefCounted
const Legacy=preload("res://scripts/vehicle/drive_model.gd")
const Spatial=preload("res://scripts/vehicle/spatial_drive_model.gd")
static func create(track):
	return Spatial.new(track) if track.get("format_version")==2 else Legacy.new(track)
