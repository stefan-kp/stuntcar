extends RefCounted
# Spiele überschreiben diese vier Methoden. Der Kern bewegt keine Spielfigur.
func describe_actions() -> Dictionary: return {}
func assess(_request: Dictionary) -> Dictionary: return {}
func apply(_decision: Dictionary, _now_ms: int) -> Dictionary:
 return {"result":"rejected","reason_code":"not_implemented","actions":[]}
func cancel(_request: Dictionary, _now_ms: int) -> Dictionary:
 return {"result":"rejected","reason_code":"not_implemented","actions":[]}
