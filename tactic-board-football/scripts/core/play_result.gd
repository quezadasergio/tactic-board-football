class_name PlayResult
extends RefCounted

var ok: bool = true
var title: String = ""
var summary: String = ""
var yards: int = 0 ## relativo al ataque (positivo = avance del ataque)
var turnover: bool = false
var turnover_spot_delta: int = 0 ## yardas extra al cambiar posesión (desde spot de inicio de jugada)
var touchdown: bool = false
var safety: bool = false
var incomplete: bool = false
var field_goal_good: bool = false
var field_goal_miss: bool = false
var punt_touchback: bool = false
var blocked_punt: bool = false
var is_sack: bool = false
var is_fumble: bool = false
var is_interception: bool = false
var is_completion: bool = false
var dice_log: Array[Dictionary] = []
var side_choice_needed: String = "" ## "offense" | "defense" | ""
var pending_stage: String = "" ## para UI multi-paso


func add_dice(label: String, offense_rolls: Array, defense_rolls: Array, diff: int) -> void:
	dice_log.append({
		"label": label,
		"offense": offense_rolls.duplicate(),
		"defense": defense_rolls.duplicate(),
		"diff": diff,
	})
