class_name RulesEngine
extends RefCounted

## Resuelve jugadas según las reglas acordadas para el MVP.


static func resolve_pass(
	off: Formation,
	deff: Formation,
	side: String, ## "L" | "R" | "" si se decide después
	forced_rolls: Dictionary = {}
) -> PlayResult:
	var res := PlayResult.new()
	res.title = "Pase"

	if not off.can_pass():
		res.ok = false
		res.summary = "Necesitas al menos un receptor para pasar."
		return res

	var ol_roll := _roll_or(forced_rolls, "ol", off.ol)
	var dl_roll := _roll_or(forced_rolls, "dl", deff.dl)
	var line_diff: int = ol_roll.total - dl_roll.total
	res.add_dice("Línea", ol_roll.rolls, dl_roll.rolls, line_diff)

	var line_out := RulesTables.line_pass_outcome(line_diff)
	match line_out:
		"sack":
			res.yards = line_diff # negativo
			res.is_sack = true
			res.summary = "Captura del pasador (%d yardas)." % res.yards
			return res
		"fumble":
			res.turnover = true
			res.is_fumble = true
			res.yards = 0
			res.summary = "Balón suelto recuperado por la defensa."
			return res
		"presion_baja":
			var o := _roll_or(forced_rolls, "pressure_o", 1)
			var d := _roll_or(forced_rolls, "pressure_d", 1)
			res.add_dice("Presión baja", o.rolls, d.rolls, o.total - d.total)
			if o.total >= d.total:
				side = side if side != "" else "L"
				res.summary = "Presión baja: el ataque elige el lado."
			else:
				side = side if side != "" else "R"
				res.summary = "Presión baja: la defensa elige el lado."
		"presion_alta":
			res.summary = "Presión alta: la defensa elige el lado."
			if side == "":
				side = "R"
		"contencion":
			res.summary = "Contención de línea: el ataque elige el lado."
			if side == "":
				side = "L"

	var wr := off.wr_l if side == "L" else off.wr_r
	var cb := deff.cb_l if side == "L" else deff.cb_r
	var sec_o := _roll_or(forced_rolls, "sec_o", wr)
	var sec_d := _roll_or(forced_rolls, "sec_d", cb)
	var sec_diff: int = sec_o.total - sec_d.total
	res.add_dice("Secundaria (%s)" % side, sec_o.rolls, sec_d.rolls, sec_diff)

	var sec_out := RulesTables.secondary_pass_outcome(sec_diff)
	match sec_out:
		"touchdown":
			res.touchdown = true
			res.is_completion = true
			res.yards = 99
			res.summary = "¡Pase para touchdown desde secundaria!"
			return res
		"incompleto":
			res.incomplete = true
			res.yards = 0
			res.summary = "Pase incompleto."
			return res
		"intercepcion":
			res.turnover = true
			res.is_interception = true
			# Desde el spot original, 3 yardas hacia la portería del ataque por punto de diferencia.
			res.turnover_spot_delta = 3 * absi(line_diff)
			res.summary = "¡Intercepción!"
			return res
		"completo":
			pass

	var deep_o := _roll_or(forced_rolls, "deep_o", 1)
	var safeties := deff.s_l if side == "L" else deff.s_r
	var deep_d := _roll_or(forced_rolls, "deep_d", safeties)
	var deep_diff: int = deep_o.total - deep_d.total
	res.add_dice("Profunda (%s)" % side, deep_o.rolls, deep_d.rolls, deep_diff)

	var acc := line_diff + sec_diff
	if deep_diff > 0:
		acc += deep_diff
		res.summary = "Pase completo y gana zona profunda."
	else:
		res.summary = "Pase completo; la defensa gana la zona profunda (solo 2 tiros)."

	res.is_completion = true
	# Solo yardas (Tabla C), sin re-clasificar completo/incompleto
	var ypp := RulesTables.pass_yards_per_point(acc)
	if ypp < 0:
		res.touchdown = true
		res.yards = 99
		res.summary += " ¡Touchdown!"
	elif ypp <= 0 or acc < 2:
		res.yards = 0
		res.summary += " Ganancia 0 yardas."
	else:
		res.yards = acc * ypp
		res.summary += " Ganancia de %d yardas." % res.yards

	return res


static func resolve_run(
	off: Formation,
	deff: Formation,
	forced_rolls: Dictionary = {}
) -> PlayResult:
	var res := PlayResult.new()
	res.title = "Carrera"

	if not off.can_run():
		res.ok = false
		res.summary = "Necesitas un corredor para correr."
		return res

	var ol_roll := _roll_or(forced_rolls, "ol", off.ol)
	var dl_roll := _roll_or(forced_rolls, "dl", deff.dl)
	var line_diff: int = ol_roll.total - dl_roll.total
	res.add_dice("Línea", ol_roll.rolls, dl_roll.rolls, line_diff)

	var line_out := RulesTables.line_pass_outcome(line_diff)
	if line_out == "fumble":
		res.turnover = true
		res.is_fumble = true
		res.summary = "Balón suelto en la línea. La defensa recupera."
		return res
	if line_out == "sack":
		res.yards = line_diff
		res.is_sack = true
		res.summary = "Captura / pérdida en línea (%d yardas)." % res.yards
		return res

	if line_diff < 0:
		res.yards = line_diff
		res.summary = "La defensa gana la línea. Retroceso de %d yardas." % res.yards
		return res

	# Ataque gana línea: 1 yd por punto, sigue a apoyadores
	var acc := line_diff
	var lb_o := _roll_or(forced_rolls, "lb_o", 1)
	var lb_d := _roll_or(forced_rolls, "lb_d", deff.lb)
	var lb_diff: int = lb_o.total - lb_d.total
	res.add_dice("Apoyadores", lb_o.rolls, lb_d.rolls, lb_diff)

	if lb_diff <= 0:
		res.yards = acc
		res.summary = "Detenido por apoyadores. Ganancia %d yardas." % res.yards
		return res

	acc += lb_diff
	var rear_o := _roll_or(forced_rolls, "rear_o", 1)
	var rear_d := _roll_or(forced_rolls, "rear_d", deff.rear)
	var rear_diff: int = rear_o.total - rear_d.total
	res.add_dice("Retaguardia", rear_o.rolls, rear_d.rolls, rear_diff)

	if rear_diff <= 0:
		res.yards = acc
		res.summary = "Detenido en retaguardia. Ganancia %d yardas." % res.yards
	else:
		res.yards = acc + (rear_diff * 3)
		res.summary = "Rompe retaguardia. Ganancia %d yardas." % res.yards
	return res


static func resolve_field_goal(
	ball_from_offense_goal: int,
	forced_rolls: Dictionary = {}
) -> PlayResult:
	## ball_from_offense_goal: yardas desde la portería del ataque hacia adelante (posición en territorio)
	## Distancia = posición del balón + 17, donde posición es yardas hasta la end zone rival?
	## Reglas: Distancia = Posición del balón + 17. Posición = yard line actual hacia la end zone rival.
	var res := PlayResult.new()
	res.title = "Gol de campo"
	var distance := ball_from_offense_goal + 17
	var o := _roll_or(forced_rolls, "fg_o", 2)
	var d := _roll_or(forced_rolls, "fg_d", 2)
	var diff: int = o.total - d.total
	res.add_dice("Gol de campo", o.rolls, d.rolls, diff)
	var length := RulesTables.field_goal_length(diff)
	if length >= distance:
		res.field_goal_good = true
		res.summary = "¡Gol de campo bueno! Distancia %d, patada %d." % [distance, length]
	else:
		res.field_goal_miss = true
		res.summary = "Gol de campo fallido. Distancia %d, patada %d." % [distance, length]
	return res


static func resolve_punt(
	off: Formation,
	deff: Formation,
	side: String,
	forced_rolls: Dictionary = {}
) -> PlayResult:
	var res := PlayResult.new()
	res.title = "Despeje"

	var kick_line := _roll_or(forced_rolls, "punt_ol", off.punt_protect)
	var press := _roll_or(forced_rolls, "punt_dl", deff.pressure)
	var line_diff: int = kick_line.total - press.total
	res.add_dice("Línea de despeje", kick_line.rolls, press.rolls, line_diff)

	var line := RulesTables.punt_line_outcome(line_diff)
	if line.kind == "bloqueado":
		res.blocked_punt = true
		res.turnover = true
		res.summary = "¡Patada bloqueada!"
		return res

	var kick_yards: int = 25 + absi(line_diff) * int(line.yards_per_point)
	if line_diff < 0:
		kick_yards = 25 + absi(line_diff) * int(line.yards_per_point)
	else:
		kick_yards = 25 + line_diff * int(line.yards_per_point)

	# Decidir lado
	if side == "":
		match line.chooser:
			"kicker":
				side = "L"
			"returner":
				side = "R"
			_:
				var po := _roll_or(forced_rolls, "side_o", 1)
				var pd := _roll_or(forced_rolls, "side_d", 1)
				res.add_dice("Decisión de lado", po.rolls, pd.rolls, po.total - pd.total)
				side = "L" if po.total >= pd.total else "R"

	res.summary = "Despeje de %d yardas hacia %s." % [kick_yards, side]

	# Cobertura
	var cov_k := off.punt_cover_l if side == "L" else off.punt_cover_r
	var cov_r := deff.ret_cover_l if side == "L" else deff.ret_cover_r
	# El regresador también cuenta? Reglas: dados según fichas en el lado. Returner is center - include in return side?
	# Usamos cobertura del lado + returner en el equipo que devuelve
	var k_roll := _roll_or(forced_rolls, "cov_k", cov_k)
	var r_roll := _roll_or(forced_rolls, "cov_r", cov_r + deff.returner)
	var cov_diff: int = k_roll.total - r_roll.total
	res.add_dice("Cobertura (%s)" % side, k_roll.rolls, r_roll.rolls, cov_diff)

	var cov := RulesTables.punt_coverage_outcome(cov_diff)
	var return_yards := 0
	match cov.kind:
		"devolucion":
			return_yards = cov_diff * int(cov.yards_per_point)
		"sin_devolucion":
			return_yards = 0
		"rebote":
			return_yards = cov_diff * int(cov.yards_per_point) # negativo
		"fumble_kicker":
			res.turnover = false # el equipo de despeje recupera — posesión se queda / cambia a kicker
			res.blocked_punt = false
			res.yards = kick_yards # se marcará especial en match
			res.summary += " Balón suelto recuperado por el equipo de despeje."
			res.dice_log.append({"label": "meta", "kick": kick_yards, "return": 0, "fumble_kicker": true, "side": side})
			return res

	res.yards = kick_yards - return_yards
	res.dice_log.append({"label": "meta", "kick": kick_yards, "return": return_yards, "side": side})
	res.summary += " Devolución %d. Neto %d." % [return_yards, res.yards]
	return res


static func _roll_or(forced: Dictionary, key: String, n: int) -> Dictionary:
	if forced.has(key):
		var rolls: Array = forced[key]
		var total := 0
		for v in rolls:
			total += int(v)
		return {"rolls": rolls, "total": total}
	return DiceUtil.roll_sum(n)
