extends Control

enum Phase {
	IDLE,
	FORMING,
	CHOOSE_PLAY,
	CHOOSE_SIDE,
	ROLLING,
	RESULT,
	PAT_CHOICE,
	MATCH_OVER
}

@onready var score_label: Label = %ScoreLabel
@onready var situation_label: Label = %SituationLabel
@onready var message_label: Label = %MessageLabel
@onready var log_label: RichTextLabel = %LogLabel
@onready var field: Control = %FieldView
@onready var formation_host: VBoxContainer = %FormationHost
@onready var actions: HBoxContainer = %Actions
@onready var dice_tray = %DiceTray
@onready var cpu_reveal: Label = %CpuReveal
@onready var stats_panel = %StatsPanel

var phase: Phase = Phase.IDLE
var player_formation: Formation = Formation.new()
var cpu_formation: Formation = Formation.new()
var pending_play: String = ""
var pending_side: String = ""
var last_result: PlayResult
var _roll_queue: Array[Dictionary] = []
var _formation_editor: VBoxContainer
var _after_rolls: Callable = Callable()
var _snap_ball: int = 20
var _snap_offense_player: bool = true
var _snap_yards_to_go: int = 10
var _snap_down: int = 1


func _ready() -> void:
	if MatchState.player_team == null:
		var teams := TeamData.fake_roster()
		MatchState.configure(teams[0], teams[1], "mediano")
	dice_tray.rolls_done.connect(_on_rolls_done)
	_refresh_hud()
	_begin_play_setup()


func _refresh_hud() -> void:
	score_label.text = "%s %d  -  %d %s" % [
		MatchState.player_team.short_name, MatchState.score_player,
		MatchState.score_cpu, MatchState.cpu_team.short_name
	]
	situation_label.text = "Q%d · Jugada %d/%d · %s · %s" % [
		MatchState.quarter,
		MatchState.play_in_quarter,
		MatchState.plays_per_quarter,
		"Ataque" if MatchState.possession_player else "Defensa",
		MatchState.situation_label()
	]
	field.refresh()
	if stats_panel:
		stats_panel.refresh()


func _clear_actions() -> void:
	for c in actions.get_children():
		c.queue_free()


func _add_action(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	actions.add_child(b)


func _set_message(t: String) -> void:
	message_label.text = t


func _append_log(t: String) -> void:
	MatchState.add_log(t)
	log_label.append_text(t + "\n")


func _begin_play_setup() -> void:
	if MatchState.match_over:
		phase = Phase.MATCH_OVER
		_set_message("Fin del partido.")
		_clear_actions()
		_add_action("Menú principal", func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
		return

	if MatchState.awaiting_pat and MatchState.possession_player:
		_show_pat_choice()
		return
	if MatchState.awaiting_pat and not MatchState.possession_player:
		_cpu_pat()
		return

	phase = Phase.FORMING
	cpu_reveal.text = ""
	field.clear_formations()
	_clear_actions()
	for c in formation_host.get_children():
		c.queue_free()

	var kind := _formation_kind_for_player()
	var editor := VBoxContainer.new()
	editor.set_script(load("res://scripts/ui/formation_editor.gd"))
	formation_host.add_child(editor)
	_formation_editor = editor

	var preset: Formation
	if kind == Formation.Kind.OFFENSE:
		preset = SimpleAI.make_offense()
	elif kind == Formation.Kind.DEFENSE:
		preset = SimpleAI.make_defense_balanced()
	elif kind == Formation.Kind.PUNT_KICK:
		preset = SimpleAI.make_punt_kick()
	else:
		preset = SimpleAI.make_punt_return()

	editor.call("setup", kind, preset)
	_set_message("Coloca tus 7 fichas y confirma la formación.")
	_add_action("Confirmar formación", _on_confirm_formation)
	_add_action("Menú", func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))


func _formation_kind_for_player() -> Formation.Kind:
	# Por defecto: ofensiva/defensiva normal. Despeje se elige después.
	if MatchState.possession_player:
		return Formation.Kind.OFFENSE
	return Formation.Kind.DEFENSE


func _on_confirm_formation() -> void:
	if not _formation_editor.call("is_valid"):
		_set_message("Debes usar exactamente 7 fichas (pasador/pateador válidos).")
		return
	player_formation = _formation_editor.call("get_formation")
	_ai_pick_formation()
	_show_cpu_formation()
	_push_field_formations(false)
	if MatchState.possession_player:
		_show_play_choices()
	else:
		_cpu_offense_turn()


func _push_field_formations(is_punt: bool) -> void:
	var off: Formation
	var deff: Formation
	var off_kind: Formation.Kind
	var def_kind: Formation.Kind
	var off_color: Color
	var def_color: Color
	if MatchState.possession_player:
		off = player_formation
		deff = cpu_formation
		off_color = MatchState.player_team.primary
		def_color = MatchState.cpu_team.primary
	else:
		off = cpu_formation
		deff = player_formation
		off_color = MatchState.cpu_team.primary
		def_color = MatchState.player_team.primary
	if is_punt:
		off_kind = Formation.Kind.PUNT_KICK
		def_kind = Formation.Kind.PUNT_RETURN
	else:
		off_kind = Formation.Kind.OFFENSE
		def_kind = Formation.Kind.DEFENSE
	field.set_formations(off, deff, off_kind, def_kind, off_color, def_color, MatchState.possession_player)


func _ai_pick_formation() -> void:
	var dist := MatchState.ball_to_offense_endzone()
	if MatchState.possession_player:
		cpu_formation = SimpleAI.pick_defense(MatchState.down, MatchState.yards_to_go, dist)
	else:
		cpu_formation = SimpleAI.pick_offense(MatchState.down, MatchState.yards_to_go, dist)


func _show_cpu_formation() -> void:
	var d: Dictionary
	if MatchState.possession_player:
		d = cpu_formation.to_dict(Formation.Kind.DEFENSE)
		cpu_reveal.text = "Defensa CPU: " + str(d)
	else:
		d = cpu_formation.to_dict(Formation.Kind.OFFENSE)
		cpu_reveal.text = "Ofensiva CPU: " + str(d)


func _show_play_choices() -> void:
	phase = Phase.CHOOSE_PLAY
	_clear_actions()
	_set_message("Elige el tipo de jugada.")
	var off: Formation = player_formation
	if off.can_pass():
		_add_action("Pase", func(): _start_player_play("pass"))
	if off.can_run():
		_add_action("Carrera", func(): _start_player_play("run"))
	_add_action("Gol de campo", func(): _start_player_play("field_goal"))
	if MatchState.down == 4:
		_add_action("Despeje", func(): _start_player_punt())


func _start_player_play(play: String) -> void:
	pending_play = play
	if play == "pass":
		phase = Phase.CHOOSE_SIDE
		_clear_actions()
		_set_message("¿Hacia qué lado lanzas el pase? (puede cambiar por presión)")
		_add_action("Izquierda", func(): _resolve_and_animate_pass("L"))
		_add_action("Derecha", func(): _resolve_and_animate_pass("R"))
		return
	if play == "run":
		last_result = RulesEngine.resolve_run(player_formation, cpu_formation)
		_play_dice_then_apply()
		return
	if play == "field_goal":
		last_result = RulesEngine.resolve_field_goal(MatchState.ball_to_offense_endzone())
		_play_dice_then_apply()
		return


func _start_player_punt() -> void:
	# Reformar a punt — usar presets rápidos para MVP
	player_formation = SimpleAI.make_punt_kick()
	cpu_formation = SimpleAI.make_punt_return()
	_push_field_formations(true)
	pending_play = "punt"
	phase = Phase.CHOOSE_SIDE
	_clear_actions()
	_set_message("Despeje: elige lado preferido (sujeto a presión).")
	_add_action("Izquierda", func(): _do_punt("L"))
	_add_action("Derecha", func(): _do_punt("R"))


func _do_punt(side: String) -> void:
	last_result = RulesEngine.resolve_punt(player_formation, cpu_formation, side)
	_play_dice_then_apply()


func _resolve_and_animate_pass(side: String) -> void:
	last_result = RulesEngine.resolve_pass(player_formation, cpu_formation, side)
	_play_dice_then_apply()


func _cpu_offense_turn() -> void:
	var off := cpu_formation
	var dist := MatchState.ball_to_offense_endzone()
	var play := SimpleAI.choose_play(off, MatchState.down, MatchState.yards_to_go, dist, true)
	pending_play = play
	_set_message("La CPU juega: %s" % play)
	match play:
		"pass":
			var side := SimpleAI.choose_pass_side(player_formation)
			last_result = RulesEngine.resolve_pass(off, player_formation, side)
		"run":
			last_result = RulesEngine.resolve_run(off, player_formation)
		"field_goal":
			last_result = RulesEngine.resolve_field_goal(dist)
		"punt":
			cpu_formation = SimpleAI.make_punt_kick()
			player_formation = SimpleAI.make_punt_return()
			_push_field_formations(true)
			last_result = RulesEngine.resolve_punt(cpu_formation, player_formation, SimpleAI.choose_pass_side(player_formation))
		_:
			last_result = RulesEngine.resolve_run(off, player_formation)
	_play_dice_then_apply()


func _play_dice_then_apply() -> void:
	_start_roll_sequence(last_result.title + " — lanzando dados...", _apply_result)


func _start_roll_sequence(msg: String, when_done: Callable) -> void:
	phase = Phase.ROLLING
	_clear_actions()
	_after_rolls = when_done
	_roll_queue.clear()
	for entry in last_result.dice_log:
		if str(entry.get("label", "")) == "meta":
			continue
		_roll_queue.append(entry)
	_set_message(msg)
	if _roll_queue.is_empty():
		when_done.call()
		return
	_play_next_roll()


func _play_next_roll() -> void:
	if _roll_queue.is_empty():
		if _after_rolls.is_valid():
			_after_rolls.call()
		return
	var entry: Dictionary = _roll_queue.pop_front()
	var off_team: TeamData = MatchState.player_team if MatchState.possession_player else MatchState.cpu_team
	var def_team: TeamData = MatchState.cpu_team if MatchState.possession_player else MatchState.player_team
	dice_tray.play_rolls(
		"%s (diff %+d)" % [entry.label, entry.diff],
		entry.offense,
		entry.defense,
		off_team.primary,
		off_team.secondary,
		def_team.primary,
		def_team.secondary
	)


func _on_rolls_done(_o: Array, _d: Array) -> void:
	await get_tree().create_timer(0.35).timeout
	_play_next_roll()


func _apply_result() -> void:
	phase = Phase.RESULT
	MatchState.play_in_quarter += 1
	_snap_ball = MatchState.ball
	_snap_offense_player = MatchState.possession_player
	_snap_yards_to_go = MatchState.yards_to_go
	_snap_down = MatchState.down
	_set_message(last_result.summary)
	_append_log(last_result.summary)
	_clear_actions()

	if not last_result.ok:
		_add_action("Continuar", _begin_play_setup)
		return

	match pending_play:
		"field_goal":
			_apply_field_goal()
		"punt":
			_apply_punt()
		_:
			_apply_scrimmage_play()

	_record_stats_for_play()
	_update_previous_play_line()
	_refresh_hud()
	_check_quarter_end()
	if phase == Phase.MATCH_OVER:
		return
	_add_action("Siguiente jugada", _begin_play_setup)


func _offense_stats() -> TeamStats:
	return MatchState.stats_player if _snap_offense_player else MatchState.stats_cpu


func _defense_stats() -> TeamStats:
	return MatchState.stats_cpu if _snap_offense_player else MatchState.stats_player


func _yards_gained_capped() -> int:
	## Yardas reales de avance ofensivo (para TD usa distancia a end zone al snap).
	if last_result.touchdown:
		if _snap_offense_player:
			return maxi(0, 100 - _snap_ball)
		return maxi(0, _snap_ball)
	return last_result.yards


func _record_stats_for_play() -> void:
	if last_result == null or not last_result.ok:
		return
	var off := _offense_stats()
	var deff := _defense_stats()

	match pending_play:
		"pass":
			_record_pass_stats(off)
		"run", "pat_2":
			_record_run_stats(off)
		"field_goal":
			off.fg_attempts += 1
			if last_result.field_goal_good:
				off.fg_made += 1
		"punt":
			off.punts += 1
			# TD de regreso: lo anota el equipo que recibía (defensa del despeje)
			if last_result.touchdown:
				deff.rush_tds += 1
				deff.rush_yards += maxi(0, int(last_result.yards)) # neto de regreso si viene en meta
				deff.first_downs += 1

	if last_result.safety:
		deff.safeties_scored += 1


func _record_pass_stats(off: TeamStats) -> void:
	if last_result.is_sack:
		off.sacks_taken += 1
		return
	if last_result.is_fumble:
		off.fumbles_lost += 1
		return

	off.pass_attempts += 1
	if last_result.is_interception:
		off.interceptions += 1
		return
	if last_result.incomplete:
		return

	# Completo (incluye TD anotado por yardas aunque el motor no marcara is_completion)
	var completed := last_result.is_completion or last_result.touchdown or last_result.yards > 0
	if not completed:
		return

	off.pass_completions += 1
	var y := _yards_gained_capped()
	off.pass_yards += maxi(0, y)
	if last_result.touchdown:
		off.pass_tds += 1
	_maybe_first_down(off, y)


func _record_run_stats(off: TeamStats) -> void:
	if last_result.is_sack:
		off.sacks_taken += 1
		return
	if last_result.is_fumble:
		off.fumbles_lost += 1
		return

	var y := _yards_gained_capped()
	off.rush_yards += y
	if last_result.touchdown:
		off.rush_tds += 1
	_maybe_first_down(off, y)


func _maybe_first_down(off: TeamStats, yards_gained: int) -> void:
	if last_result.touchdown or yards_gained >= _snap_yards_to_go:
		off.first_downs += 1


func _update_previous_play_line() -> void:
	if last_result.incomplete:
		field.clear_previous_play()
		return
	var end_ball := MatchState.ball
	# Si el balón no se movió (p. ej. fumble recuperado en el mismo spot), igual marcar si hubo yards
	var positive: bool
	if pending_play == "punt" or pending_play == "field_goal":
		# Movimiento neto del balón en el campo: “positivo” si el equipo que tenía el balón avanzó su dirección
		if _snap_offense_player:
			positive = end_ball > _snap_ball
		else:
			positive = end_ball < _snap_ball
	else:
		positive = last_result.yards > 0
		# Turnovers / sack: usar desplazamiento real si yards==0
		if last_result.turnover or last_result.yards == 0:
			if _snap_offense_player:
				positive = end_ball > _snap_ball
			else:
				positive = end_ball < _snap_ball
	if end_ball == _snap_ball and last_result.yards == 0 and not last_result.turnover:
		# Sin desplazamiento visible
		if pending_play != "field_goal":
			field.clear_previous_play()
			return
	field.set_previous_play(_snap_ball, end_ball, positive)


func _apply_scrimmage_play() -> void:
	if last_result.turnover:
		var spot := MatchState.ball
		if last_result.turnover_spot_delta != 0:
			# Intercepción: mover hacia portería del ataque actual
			if MatchState.possession_player:
				spot = MatchState.ball - last_result.turnover_spot_delta
			else:
				spot = MatchState.ball + last_result.turnover_spot_delta
		MatchState.give_ball_to(not MatchState.possession_player, spot)
		_append_log("Cambio de posesión.")
		return

	if last_result.incomplete:
		MatchState.down += 1
		if MatchState.down > 4:
			MatchState.turnover_on_downs()
		return

	MatchState.apply_yards(last_result.yards)
	var score := MatchState.check_score_after_move()
	if score == "td_player":
		MatchState.ball = 100
		last_result.touchdown = true
		if pending_play == "pass":
			last_result.is_completion = true
		MatchState.after_touchdown(true)
		return
	if score == "td_cpu":
		MatchState.ball = 0
		last_result.touchdown = true
		if pending_play == "pass":
			last_result.is_completion = true
		MatchState.after_touchdown(false)
		return
	if score == "safety_cpu":
		MatchState.score_cpu += 2
		last_result.safety = true
		MatchState.give_ball_to(false, 80)
		_append_log("Safety. +2 CPU.")
		return
	if score == "safety_player":
		MatchState.score_player += 2
		last_result.safety = true
		MatchState.give_ball_to(true, 20)
		_append_log("Safety. +2 jugador.")
		return

	if last_result.yards >= 0:
		MatchState.advance_down(last_result.yards)
	else:
		MatchState.yards_to_go -= last_result.yards # yards negativo: yards_to_go aumenta
		MatchState.down += 1
	if MatchState.down > 4:
		MatchState.turnover_on_downs()


func _apply_field_goal() -> void:
	if last_result.field_goal_good:
		if MatchState.possession_player:
			MatchState.score_player += 3
			MatchState.give_ball_to(false, 80)
		else:
			MatchState.score_cpu += 3
			MatchState.give_ball_to(true, 20)
		_append_log("Gol de campo bueno. 3 puntos.")
	else:
		# Rival comienza 7 yardas adelante del spot
		if MatchState.possession_player:
			var spot := mini(100, MatchState.ball + 7)
			MatchState.give_ball_to(false, spot)
		else:
			var spot2 := maxi(0, MatchState.ball - 7)
			MatchState.give_ball_to(true, spot2)
		_append_log("Gol de campo fallido.")


func _apply_punt() -> void:
	var meta := {}
	for e in last_result.dice_log:
		if e.get("label", "") == "meta":
			meta = e
	if last_result.blocked_punt or meta.get("fumble_kicker", false):
		# Posesión para el equipo que no despejaba / o recupera despeje
		if meta.get("fumble_kicker", false):
			# despeje recupera — misma posesión, spot aproximado
			MatchState.set_first_and_ten()
			_append_log("Recupera el equipo de despeje.")
			return
		MatchState.give_ball_to(not MatchState.possession_player, MatchState.ball)
		_append_log("Patada bloqueada / turnover.")
		return

	var kick: int = int(meta.get("kick", 25))
	var ret: int = int(meta.get("return", 0))
	# Avance neto del balón en dirección del despeje
	var net := kick - ret
	var new_ball := MatchState.ball
	if MatchState.possession_player:
		new_ball = MatchState.ball + net
	else:
		new_ball = MatchState.ball - net

	if MatchState.possession_player and new_ball >= 100:
		MatchState.give_ball_to(false, 80) # touchback
		_append_log("Touchback. CPU en yarda 20.")
		return
	if not MatchState.possession_player and new_ball <= 0:
		MatchState.give_ball_to(true, 20)
		_append_log("Touchback. Jugador en yarda 20.")
		return

	# TD de regreso
	if MatchState.possession_player and ret > MatchState.ball:
		last_result.touchdown = true
		last_result.yards = ret # yardas de regreso para stats
		MatchState.after_touchdown(false)
		_append_log("¡TD de regreso CPU!")
		return
	if not MatchState.possession_player and ret > (100 - MatchState.ball):
		last_result.touchdown = true
		last_result.yards = ret
		MatchState.after_touchdown(true)
		_append_log("¡TD de regreso jugador!")
		return

	MatchState.give_ball_to(not MatchState.possession_player, clampi(new_ball, 0, 100))
	_append_log("Despeje colocado en %d." % MatchState.ball)


func _show_pat_choice() -> void:
	phase = Phase.PAT_CHOICE
	_clear_actions()
	_set_message("Touchdown. ¿Punto extra (1) o conversión de 2?")
	_add_action("Punto extra (1)", func(): _do_pat(false))
	_add_action("Conversión 2 pts", func(): _do_pat(true))


func _do_pat(two_point: bool) -> void:
	MatchState.awaiting_pat = false
	_snap_offense_player = true
	_snap_ball = MatchState.ball
	_snap_yards_to_go = 2
	if two_point:
		MatchState.ball = 98
		_snap_ball = 98
		player_formation = SimpleAI.make_offense()
		cpu_formation = SimpleAI.make_defense_balanced()
		last_result = RulesEngine.resolve_run(player_formation, cpu_formation)
		pending_play = "pat_2"
	else:
		last_result = RulesEngine.resolve_field_goal(20) # 20+17=37
		pending_play = "pat_kick"
	_start_roll_sequence("Conversión — dados...", _finish_pat)


func _finish_pat() -> void:
	if pending_play == "pat_kick":
		if last_result.field_goal_good:
			MatchState.score_player += 1
			_append_log("Punto extra bueno.")
		else:
			_append_log("Punto extra fallido.")
	else:
		MatchState.apply_yards(last_result.yards)
		if MatchState.ball >= 100:
			MatchState.score_player += 2
			_append_log("¡Conversión de 2 puntos!")
		else:
			_append_log("Conversión fallida.")
		# Stats de la carrera de conversión (sin contar TD)
		var was_td := last_result.touchdown
		last_result.touchdown = false
		_record_stats_for_play()
		last_result.touchdown = was_td
	MatchState.after_pat_done()
	_refresh_hud()
	_clear_actions()
	_set_message(last_result.summary)
	_add_action("Continuar", _begin_play_setup)


func _cpu_pat() -> void:
	MatchState.awaiting_pat = false
	last_result = RulesEngine.resolve_field_goal(20)
	pending_play = "pat_kick_cpu"
	_start_roll_sequence("CPU intenta punto extra...", _finish_cpu_pat)


func _finish_cpu_pat() -> void:
	if last_result.field_goal_good:
		MatchState.score_cpu += 1
		_append_log("CPU anota punto extra.")
	else:
		_append_log("CPU falla punto extra.")
	MatchState.after_pat_done()
	_refresh_hud()
	_clear_actions()
	_set_message(last_result.summary)
	_add_action("Continuar", _begin_play_setup)


func _check_quarter_end() -> void:
	if MatchState.play_in_quarter < MatchState.plays_per_quarter:
		return
	if MatchState.quarter >= 4:
		MatchState.match_over = true
		phase = Phase.MATCH_OVER
		var winner := "Empate"
		if MatchState.score_player > MatchState.score_cpu:
			winner = "Gana " + MatchState.player_team.name
		elif MatchState.score_cpu > MatchState.score_player:
			winner = "Gana " + MatchState.cpu_team.name
		_set_message("Fin del partido. %s (%d-%d)" % [winner, MatchState.score_player, MatchState.score_cpu])
		_clear_actions()
		_add_action("Menú principal", func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
		return
	MatchState.quarter += 1
	MatchState.play_in_quarter = 0
	if MatchState.quarter == 3:
		MatchState.start_third_quarter()
	_append_log("Fin de cuarto. Empieza Q%d." % MatchState.quarter)
