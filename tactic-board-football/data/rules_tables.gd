class_name RulesTables
extends RefCounted

## Tabla A: jugadas máximas por cuarto
const DURATION_PLAYS := {
	"corto": 10,
	"mediano": 15,
	"largo": 20,
}

const DURATION_LABELS := {
	"corto": "Corto (10 jugadas/cuarto)",
	"mediano": "Mediano (15 jugadas/cuarto)",
	"largo": "Largo (20 jugadas/cuarto)",
}


## Tabla B: tiro de línea en pase (y sack/fumble también en carrera)
static func line_pass_outcome(diff: int) -> String:
	if diff >= 0:
		return "contencion"
	if diff >= -2:
		return "presion_baja"
	if diff >= -4:
		return "presion_alta"
	if diff >= -7:
		return "sack"
	return "fumble"


## Tabla C: yardas por punto según diferencia acumulada de pase
static func pass_yards_per_point(diff: int) -> int:
	if diff >= 13:
		return -1 # señal de touchdown inmediato en secundaria
	if diff >= 10:
		return 5
	if diff >= 8:
		return 4
	if diff >= 4:
		return 3
	if diff >= 2:
		return 2
	return 0


static func secondary_pass_outcome(diff: int) -> String:
	if diff >= 13:
		return "touchdown"
	if diff >= 2:
		return "completo"
	if diff >= -4:
		return "incompleto"
	return "intercepcion"


## Tabla D: línea de despeje
static func punt_line_outcome(diff: int) -> Dictionary:
	if diff >= 0:
		return {"kind": "contencion", "yards_per_point": 4, "chooser": "kicker"}
	if diff >= -5:
		return {"kind": "presion", "yards_per_point": 3, "chooser": "roll"}
	if diff >= -9:
		return {"kind": "presion_alta", "yards_per_point": 2, "chooser": "returner"}
	return {"kind": "bloqueado", "yards_per_point": 0, "chooser": ""}


## Tabla E: cobertura de despeje
static func punt_coverage_outcome(diff: int) -> Dictionary:
	if diff >= 0:
		return {"kind": "devolucion", "yards_per_point": 3}
	if diff >= -6:
		return {"kind": "sin_devolucion", "yards_per_point": 0}
	if diff >= -10:
		return {"kind": "rebote", "yards_per_point": -3}
	return {"kind": "fumble_kicker", "yards_per_point": 0}


## Tabla F / fórmula: longitud de patada FG
static func field_goal_length(diff: int) -> int:
	return 42 + (diff * 2)


static func penalty_yards(penalty_index: int) -> int:
	# 0->5, 1->10, 2->15, 3->5...
	var cycle := penalty_index % 3
	match cycle:
		0:
			return 5
		1:
			return 10
		_:
			return 15
