class_name TeamStats
extends RefCounted

## Estadísticas ofensivas de un equipo (MVP).

var pass_yards: int = 0
var rush_yards: int = 0
var pass_completions: int = 0
var pass_attempts: int = 0
var pass_tds: int = 0
var rush_tds: int = 0
var interceptions: int = 0 ## INT lanzadas
var fumbles_lost: int = 0
var sacks_taken: int = 0
var first_downs: int = 0
var fg_made: int = 0
var fg_attempts: int = 0
var punts: int = 0
var safeties_scored: int = 0 ## safeties a favor (defensa)


func total_yards() -> int:
	return pass_yards + rush_yards


func turnovers() -> int:
	return interceptions + fumbles_lost


func total_tds() -> int:
	return pass_tds + rush_tds


## Passer rating NFL clásico (0–158.3). Devuelve -1.0 si no hay intentos.
func qb_rating() -> float:
	if pass_attempts <= 0:
		return -1.0
	var att := float(pass_attempts)
	var a := clampf(((float(pass_completions) / att) - 0.3) * 5.0, 0.0, 2.375)
	var b := clampf(((float(pass_yards) / att) - 3.0) * 0.25, 0.0, 2.375)
	var c := clampf((float(pass_tds) / att) * 20.0, 0.0, 2.375)
	var d := clampf(2.375 - (float(interceptions) / att) * 25.0, 0.0, 2.375)
	return ((a + b + c + d) / 6.0) * 100.0


func qb_rating_text() -> String:
	var r := qb_rating()
	if r < 0.0:
		return "—"
	return "%.1f" % r


func reset() -> void:
	pass_yards = 0
	rush_yards = 0
	pass_completions = 0
	pass_attempts = 0
	pass_tds = 0
	rush_tds = 0
	interceptions = 0
	fumbles_lost = 0
	sacks_taken = 0
	first_downs = 0
	fg_made = 0
	fg_attempts = 0
	punts = 0
	safeties_scored = 0
