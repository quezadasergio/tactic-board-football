extends Node

## Estado global del encuentro y configuración previa.

signal match_configured

var player_team: TeamData
var cpu_team: TeamData
var duration_key: String = "mediano"
var plays_per_quarter: int = 15

## Coordenada absoluta 0..100: 0 = portería del jugador, 100 = portería de la CPU.
## El jugador anota hacia 100; la CPU anota hacia 0.
var ball: int = 20
var possession_player: bool = true
var quarter: int = 1
var play_in_quarter: int = 0
var down: int = 1
var yards_to_go: int = 10
var score_player: int = 0
var score_cpu: int = 0
var timeouts_player: int = 2
var timeouts_cpu: int = 2
var half: int = 1
var penalty_count_player: int = 0
var penalty_count_cpu: int = 0
var last_timeout_by_player: bool = false
var starter_was_player_offense: bool = true
var log_lines: PackedStringArray = []
var match_over: bool = false
var awaiting_pat: bool = false ## tras TD: elegir PAT/2pt
var stats_player: TeamStats = TeamStats.new()
var stats_cpu: TeamStats = TeamStats.new()


func configure(p_team: TeamData, c_team: TeamData, duration: String) -> void:
	player_team = p_team
	cpu_team = c_team
	duration_key = duration
	plays_per_quarter = RulesTables.DURATION_PLAYS.get(duration, 15)
	reset_match()
	match_configured.emit()


func reset_match() -> void:
	ball = 20
	possession_player = true
	starter_was_player_offense = true
	quarter = 1
	play_in_quarter = 0
	down = 1
	yards_to_go = 10
	score_player = 0
	score_cpu = 0
	timeouts_player = 2
	timeouts_cpu = 2
	half = 1
	penalty_count_player = 0
	penalty_count_cpu = 0
	last_timeout_by_player = false
	log_lines = PackedStringArray()
	match_over = false
	awaiting_pat = false
	stats_player = TeamStats.new()
	stats_cpu = TeamStats.new()
	add_log("Inicio. %s vs %s. Duración: %s." % [
		player_team.short_name, cpu_team.short_name, duration_key
	])


func add_log(line: String) -> void:
	log_lines.append("Q%d #%d · %s" % [quarter, play_in_quarter, line])


func offense_is_player() -> bool:
	return possession_player


func ball_to_offense_endzone() -> int:
	## Distancia desde el balón hasta la end zone que el ataque intenta alcanzar.
	if possession_player:
		return 100 - ball
	return ball


func ball_yard_line_display() -> Dictionary:
	## Para HUD: territorio y número de yarda estilo americano.
	if ball == 50:
		return {"territory": "mid", "yard": 50, "label": "Medio campo"}
	if ball < 50:
		return {"territory": "player", "yard": ball, "label": "%s %d" % [player_team.short_name, ball]}
	return {"territory": "cpu", "yard": 100 - ball, "label": "%s %d" % [cpu_team.short_name, 100 - ball]}


func situation_label() -> String:
	var yl := ball_yard_line_display()
	var dist := ball_to_offense_endzone()
	var pa := "GOL" if dist <= yards_to_go else str(yards_to_go)
	return "%sª y %s · %s" % [_down_str(down), pa, yl.label]


func goal_distance() -> int:
	return ball_to_offense_endzone()


func _down_str(d: int) -> String:
	match d:
		1: return "1"
		2: return "2"
		3: return "3"
		4: return "4"
	return str(d)


func apply_yards(yards: int) -> void:
	## yards positivo = avance del ataque actual
	if possession_player:
		ball = clampi(ball + yards, 0, 100)
	else:
		ball = clampi(ball - yards, 0, 100)


func check_score_after_move() -> String:
	## Devuelve "" | "td_player" | "td_cpu" | "safety_player" | "safety_cpu"
	if possession_player:
		if ball >= 100:
			return "td_player"
		if ball <= 0:
			return "safety_cpu" # defensa (cpu) anota safety? Si ataque player queda en 0 o menos = safety for CPU
	else:
		if ball <= 0:
			return "td_cpu"
		if ball >= 100:
			return "safety_player"
	return ""


func set_first_and_ten() -> void:
	down = 1
	var dist := ball_to_offense_endzone()
	yards_to_go = mini(10, dist)


func advance_down(yards_gained: int) -> void:
	yards_to_go -= yards_gained
	if yards_to_go <= 0:
		set_first_and_ten()
	else:
		down += 1


func turnover_on_downs() -> void:
	possession_player = not possession_player
	set_first_and_ten()
	add_log("Balón entregado por downs.")


func give_ball_to(player: bool, spot: int) -> void:
	possession_player = player
	ball = clampi(spot, 0, 100)
	set_first_and_ten()


func after_touchdown(scorer_player: bool) -> void:
	if scorer_player:
		score_player += 6
	else:
		score_cpu += 6
	awaiting_pat = true
	add_log("¡TOUCHDOWN! Marcador %d - %d" % [score_player, score_cpu])


func after_pat_done() -> void:
	awaiting_pat = false
	# Tras PAT, el otro equipo ataca desde su 20 (sin kickoff en MVP)
	if possession_player:
		# player acabó de anotar
		give_ball_to(false, 80) # CPU propia 20
	else:
		give_ball_to(true, 20)
	add_log("Tras la conversión, posesión al rival en yarda 20.")


func start_third_quarter() -> void:
	# Ataca quien defendió al inicio, en su yarda 20
	possession_player = not starter_was_player_offense
	if possession_player:
		ball = 20
	else:
		ball = 80
	set_first_and_ten()
	timeouts_player = 2
	timeouts_cpu = 2
	half = 2
	add_log("Inicio 3er cuarto. Posesión reiniciada en yarda 20.")
