class_name SimpleAI
extends RefCounted

## Rival automático simple: formaciones balanceadas y decisiones heurísticas.


static func make_offense() -> Formation:
	var f := Formation.new()
	f.qb = 1
	f.rb = 1
	f.ol = 3
	f.wr_l = 1
	f.wr_r = 1
	return f


static func make_offense_pass_heavy() -> Formation:
	var f := Formation.new()
	f.qb = 1
	f.rb = 0
	f.ol = 2
	f.wr_l = 2
	f.wr_r = 2
	return f


static func make_defense_balanced() -> Formation:
	var f := Formation.new()
	f.dl = 2
	f.lb = 1
	f.rear = 1
	f.cb_l = 1
	f.cb_r = 1
	f.s_l = 1
	f.s_r = 0
	# total 7
	return f


static func make_defense_pass() -> Formation:
	var f := Formation.new()
	f.dl = 1
	f.lb = 0
	f.rear = 0
	f.cb_l = 2
	f.cb_r = 2
	f.s_l = 1
	f.s_r = 1
	return f


static func make_punt_kick() -> Formation:
	var f := Formation.new()
	f.kicker = 1
	f.punt_protect = 3
	f.punt_cover_l = 1
	f.punt_cover_r = 2
	return f


static func make_punt_return() -> Formation:
	var f := Formation.new()
	f.returner = 1
	f.pressure = 3
	f.ret_cover_l = 1
	f.ret_cover_r = 2
	return f


static func pick_defense(down: int, yards_to_go: int, ball_to_endzone: int) -> Formation:
	if yards_to_go <= 3 or down == 4:
		return make_defense_vs_run_fixed()
	if ball_to_endzone <= 20:
		return make_defense_pass()
	return make_defense_balanced()


static func make_defense_vs_run_fixed() -> Formation:
	var f := Formation.new()
	f.dl = 3
	f.lb = 2
	f.rear = 2
	f.cb_l = 0
	f.cb_r = 0
	f.s_l = 0
	f.s_r = 0
	return f


static func pick_offense(down: int, yards_to_go: int, ball_to_endzone: int) -> Formation:
	if down == 4 and ball_to_endzone <= 40:
		# FG attempt will use normal offense or special - keep balanced
		return make_offense()
	if yards_to_go >= 8:
		return make_offense_pass_heavy()
	return make_offense()


static func choose_play(
	off: Formation,
	down: int,
	yards_to_go: int,
	ball_to_endzone: int,
	can_fg: bool
) -> String:
	if down == 4:
		if can_fg and ball_to_endzone + 17 <= 48:
			return "field_goal"
		return "punt"
	if off.can_run() and (yards_to_go <= 3 or randf() < 0.45):
		return "run"
	if off.can_pass():
		return "pass"
	if off.can_run():
		return "run"
	return "punt"


static func choose_pass_side(deff: Formation) -> String:
	# Ataca el lado más débil
	var left_strength := deff.cb_l + deff.s_l
	var right_strength := deff.cb_r + deff.s_r
	return "L" if left_strength <= right_strength else "R"


static func choose_defense_pass_side(off: Formation) -> String:
	return "L" if off.wr_l >= off.wr_r else "R"
