class_name DiceUtil
extends RefCounted

static func roll(n: int) -> Array[int]:
	var out: Array[int] = []
	for i in range(maxi(0, n)):
		out.append(randi_range(1, 6))
	return out


static func sum(rolls: Array[int]) -> int:
	var total := 0
	for v in rolls:
		total += v
	return total


static func roll_sum(n: int) -> Dictionary:
	var rolls := roll(n)
	return {"rolls": rolls, "total": sum(rolls)}
