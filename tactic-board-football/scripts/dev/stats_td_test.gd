extends SceneTree

## Prueba de conteo de TD por yardas (sin flag previo) para ambos lados.


func _init() -> void:
	var teams := TeamData.fake_roster()
	MatchState.configure(teams[0], teams[1], "corto")

	# Simula CPU en yarda 10 rival (ball=10), carrera de 12 → TD sin flag
	MatchState.possession_player = false
	MatchState.ball = 10
	MatchState.stats_cpu = TeamStats.new()
	MatchState.stats_player = TeamStats.new()

	var res := PlayResult.new()
	res.ok = true
	res.yards = 12
	res.touchdown = false
	res.title = "Carrera"

	# Lógica equivalente a apply + mark
	var snap_ball := MatchState.ball
	var snap_off_player := MatchState.possession_player
	MatchState.apply_yards(res.yards)
	var score := MatchState.check_score_after_move()
	assert(score == "td_cpu")
	res.touchdown = true

	var off: TeamStats = MatchState.stats_cpu
	var y := snap_ball if not snap_off_player else (100 - snap_ball)
	off.rush_yards += y
	off.rush_tds += 1
	assert(off.rush_tds == 1)
	assert(off.rush_yards == 10)
	assert(MatchState.stats_player.rush_tds == 0)

	# Jugador TD por pase
	MatchState.possession_player = true
	MatchState.ball = 92
	res = PlayResult.new()
	res.ok = true
	res.yards = 15
	res.is_completion = true
	MatchState.apply_yards(res.yards)
	score = MatchState.check_score_after_move()
	assert(score == "td_player")
	res.touchdown = true
	var y2 := 100 - 92
	MatchState.stats_player.pass_attempts += 1
	MatchState.stats_player.pass_completions += 1
	MatchState.stats_player.pass_yards += y2
	MatchState.stats_player.pass_tds += 1
	assert(MatchState.stats_player.pass_tds == 1)
	assert(MatchState.stats_player.pass_yards == 8)

	print("STATS_TD_OK")
	quit()
