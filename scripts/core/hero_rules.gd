class_name HeroRules
extends RefCounted
## Supported hero capabilities; pulling trigger/count are applied by GridState.


static func is_supported(kind: Variant) -> bool:
	return kind in ["red", "green"]


static func can_push(kind: String) -> bool:
	return kind == "red"


static func can_pull(kind: String) -> bool:
	return kind == "green"
