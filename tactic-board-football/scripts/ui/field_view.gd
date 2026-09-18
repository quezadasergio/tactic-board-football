extends Control

## Campo 2D: balón, formaciones (puntitos por zona) y trazo de la jugada anterior.

const COLOR_GAIN := Color(0.45, 0.75, 1.0, 0.95) ## azul claro
const COLOR_LOSS := Color(0.95, 0.25, 0.25, 0.95) ## rojo

var _show_formations: bool = false
var _off: Formation
var _deff: Formation
var _off_kind: Formation.Kind = Formation.Kind.OFFENSE
var _def_kind: Formation.Kind = Formation.Kind.DEFENSE
var _off_color: Color = Color.WHITE
var _def_color: Color = Color.BLACK
var _offense_is_player: bool = true

var _show_prev_line: bool = false
var _prev_start: int = 0
var _prev_end: int = 0
var _prev_gain: bool = true


func set_formations(
	offense: Formation,
	defense: Formation,
	offense_kind: Formation.Kind,
	defense_kind: Formation.Kind,
	offense_color: Color,
	defense_color: Color,
	offense_is_player: bool
) -> void:
	_show_formations = true
	_off = offense.duplicate_formation()
	_deff = defense.duplicate_formation()
	_off_kind = offense_kind
	_def_kind = defense_kind
	_off_color = offense_color
	_def_color = defense_color
	_offense_is_player = offense_is_player
	queue_redraw()


func clear_formations() -> void:
	_show_formations = false
	_off = null
	_deff = null
	queue_redraw()


func set_previous_play(start_yard: int, end_yard: int, positive_for_offense: bool) -> void:
	_show_prev_line = true
	_prev_start = clampi(start_yard, 0, 100)
	_prev_end = clampi(end_yard, 0, 100)
	_prev_gain = positive_for_offense
	queue_redraw()


func clear_previous_play() -> void:
	_show_prev_line = false
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.15, 0.45, 0.22))
	var ez := size.y * 0.08
	draw_rect(Rect2(0, 0, size.x, ez), Color(0.12, 0.35, 0.55, 0.85))
	draw_rect(Rect2(0, size.y - ez, size.x, ez), Color(0.55, 0.18, 0.18, 0.85))

	var playable := size.y - 2.0 * ez

	# Yard lines + números (izquierda)
	for i in range(0, 11):
		var t := float(i) / 10.0
		var y := ez + t * playable
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.35), 1.0)
		var yard := 100 - i * 10
		var lbl := str(yard if yard <= 50 else 100 - yard)
		draw_string(ThemeDB.fallback_font, Vector2(6, y - 2), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.7))

	# Línea de jugada anterior (paralela a números, pegada a la izquierda)
	if _show_prev_line and _prev_start != _prev_end:
		var x_line := 30.0
		var y0 := _yard_to_y(_prev_start, ez, playable)
		var y1 := _yard_to_y(_prev_end, ez, playable)
		var col := COLOR_GAIN if _prev_gain else COLOR_LOSS
		draw_line(Vector2(x_line, y0), Vector2(x_line, y1), col, 3.0)
		draw_circle(Vector2(x_line, y0), 3.5, col)
		draw_circle(Vector2(x_line, y1), 3.5, col)

	if MatchState.player_team == null:
		return

	var by := _yard_to_y(MatchState.ball, ez, playable)
	var bx := size.x * 0.5

	# Formaciones respecto a la línea de scrimmage (balón)
	if _show_formations and _off != null and _deff != null:
		_draw_formations(bx, by)

	# Balón
	draw_circle(Vector2(bx, by), 8.0, Color(0.85, 0.55, 0.15))
	draw_arc(Vector2(bx, by), 8.0, 0, TAU, 24, Color(0.1, 0.05, 0), 2.0)
	var dir := -1.0 if MatchState.possession_player else 1.0
	draw_line(Vector2(bx + 14, by), Vector2(bx + 14, by + dir * 18), Color(1, 1, 0.4), 2.0)


func _yard_to_y(yard: int, ez: float, playable: float) -> float:
	var t := 1.0 - (float(yard) / 100.0)
	return ez + t * playable


func _draw_formations(cx: float, los_y: float) -> void:
	# Dirección de ataque en pantalla: jugador hacia arriba (-Y), CPU hacia abajo (+Y)
	var forward: float = -1.0 if _offense_is_player else 1.0
	var depth := 14.0
	var lane := 22.0

	# Ofensiva: detrás de la LOS (opuesto a forward)
	_draw_side_formation(
		_off, _off_kind, _off_color,
		cx, los_y, -forward, depth, lane
	)
	# Defensa: delante de la LOS (hacia forward del ataque = territorio defensivo inmediato)
	_draw_side_formation(
		_deff, _def_kind, _def_color,
		cx, los_y, forward, depth, lane
	)


func _draw_side_formation(
	f: Formation,
	kind: Formation.Kind,
	color: Color,
	cx: float,
	los_y: float,
	away_from_los: float, ## +1 o -1: sentido desde la LOS hacia el backfield de este equipo
	depth: float,
	lane: float
) -> void:
	match kind:
		Formation.Kind.OFFENSE:
			# Fila 1 (cerca LOS): WR_L | OL | WR_R
			_dots_in_zone(f.wr_l, Vector2(cx - lane * 1.6, los_y + away_from_los * depth * 0.7), color, lane * 0.55)
			_dots_in_zone(f.ol, Vector2(cx, los_y + away_from_los * depth * 0.7), color, lane * 0.9)
			_dots_in_zone(f.wr_r, Vector2(cx + lane * 1.6, los_y + away_from_los * depth * 0.7), color, lane * 0.55)
			# QB
			_dots_in_zone(f.qb, Vector2(cx, los_y + away_from_los * depth * 1.7), color, 10.0)
			# RB
			_dots_in_zone(f.rb, Vector2(cx, los_y + away_from_los * depth * 2.6), color, 10.0)
		Formation.Kind.DEFENSE:
			# Cerca LOS: CB_L | DL | CB_R
			_dots_in_zone(f.cb_l, Vector2(cx - lane * 1.6, los_y + away_from_los * depth * 0.7), color, lane * 0.55)
			_dots_in_zone(f.dl, Vector2(cx, los_y + away_from_los * depth * 0.7), color, lane * 0.9)
			_dots_in_zone(f.cb_r, Vector2(cx + lane * 1.6, los_y + away_from_los * depth * 0.7), color, lane * 0.55)
			# Apoyadores
			_dots_in_zone(f.lb, Vector2(cx, los_y + away_from_los * depth * 1.7), color, lane * 0.7)
			# Profundos + retaguardia
			_dots_in_zone(f.s_l, Vector2(cx - lane * 1.4, los_y + away_from_los * depth * 2.6), color, lane * 0.5)
			_dots_in_zone(f.rear, Vector2(cx, los_y + away_from_los * depth * 2.6), color, lane * 0.55)
			_dots_in_zone(f.s_r, Vector2(cx + lane * 1.4, los_y + away_from_los * depth * 2.6), color, lane * 0.5)
		Formation.Kind.PUNT_KICK:
			_dots_in_zone(f.punt_cover_l, Vector2(cx - lane * 1.6, los_y + away_from_los * depth * 0.7), color, lane * 0.5)
			_dots_in_zone(f.punt_protect, Vector2(cx, los_y + away_from_los * depth * 0.7), color, lane * 1.0)
			_dots_in_zone(f.punt_cover_r, Vector2(cx + lane * 1.6, los_y + away_from_los * depth * 0.7), color, lane * 0.5)
			_dots_in_zone(f.kicker, Vector2(cx, los_y + away_from_los * depth * 2.0), color, 10.0)
		Formation.Kind.PUNT_RETURN:
			_dots_in_zone(f.pressure, Vector2(cx, los_y + away_from_los * depth * 0.7), color, lane * 1.0)
			_dots_in_zone(f.ret_cover_l, Vector2(cx - lane * 1.5, los_y + away_from_los * depth * 1.8), color, lane * 0.5)
			_dots_in_zone(f.ret_cover_r, Vector2(cx + lane * 1.5, los_y + away_from_los * depth * 1.8), color, lane * 0.5)
			_dots_in_zone(f.returner, Vector2(cx, los_y + away_from_los * depth * 3.0), color, 10.0)


func _dots_in_zone(count: int, center: Vector2, color: Color, spread: float) -> void:
	if count <= 0:
		return
	var n := count
	for i in n:
		var ox := 0.0
		if n > 1:
			ox = lerpf(-spread * 0.5, spread * 0.5, float(i) / float(n - 1))
		var p := center + Vector2(ox, 0.0)
		draw_circle(p, 4.0, color)
		draw_arc(p, 4.0, 0.0, TAU, 16, Color(0, 0, 0, 0.55), 1.0)
