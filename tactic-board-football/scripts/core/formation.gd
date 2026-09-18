class_name Formation
extends RefCounted

## Ofensiva
var ol: int = 0
var wr_l: int = 0
var wr_r: int = 0
var qb: int = 1
var rb: int = 0

## Defensa
var dl: int = 0
var lb: int = 0
var rear: int = 0
var cb_l: int = 0
var cb_r: int = 0
var s_l: int = 0
var s_r: int = 0

## Despeje (pateador)
var punt_cover_l: int = 0
var punt_protect: int = 0
var punt_cover_r: int = 0
var kicker: int = 0

## Regreso de despeje
var returner: int = 0
var ret_cover_l: int = 0
var ret_cover_r: int = 0
var pressure: int = 0

const TOKEN_BUDGET := 7

enum Kind { OFFENSE, DEFENSE, PUNT_KICK, PUNT_RETURN }


func total_for(kind: Kind) -> int:
	match kind:
		Kind.OFFENSE:
			return ol + wr_l + wr_r + qb + rb
		Kind.DEFENSE:
			return dl + lb + rear + cb_l + cb_r + s_l + s_r
		Kind.PUNT_KICK:
			return punt_cover_l + punt_protect + punt_cover_r + kicker
		Kind.PUNT_RETURN:
			return returner + ret_cover_l + ret_cover_r + pressure
	return 0


func is_valid(kind: Kind) -> bool:
	if total_for(kind) != TOKEN_BUDGET:
		return false
	match kind:
		Kind.OFFENSE:
			return qb == 1 and rb <= 1
		Kind.PUNT_KICK:
			return kicker == 1
		Kind.PUNT_RETURN:
			return returner >= 1
		_:
			return true


func can_pass() -> bool:
	return wr_l + wr_r >= 1


func can_run() -> bool:
	return rb == 1


func duplicate_formation() -> Formation:
	var f := Formation.new()
	for prop in [
		"ol", "wr_l", "wr_r", "qb", "rb",
		"dl", "lb", "rear", "cb_l", "cb_r", "s_l", "s_r",
		"punt_cover_l", "punt_protect", "punt_cover_r", "kicker",
		"returner", "ret_cover_l", "ret_cover_r", "pressure"
	]:
		f.set(prop, get(prop))
	return f


func to_dict(kind: Kind) -> Dictionary:
	match kind:
		Kind.OFFENSE:
			return {"ol": ol, "wr_l": wr_l, "wr_r": wr_r, "qb": qb, "rb": rb}
		Kind.DEFENSE:
			return {"dl": dl, "lb": lb, "rear": rear, "cb_l": cb_l, "cb_r": cb_r, "s_l": s_l, "s_r": s_r}
		Kind.PUNT_KICK:
			return {
				"punt_cover_l": punt_cover_l,
				"punt_protect": punt_protect,
				"punt_cover_r": punt_cover_r,
				"kicker": kicker
			}
		Kind.PUNT_RETURN:
			return {
				"returner": returner,
				"ret_cover_l": ret_cover_l,
				"ret_cover_r": ret_cover_r,
				"pressure": pressure
			}
	return {}
