extends VBoxContainer

## Editor de fichas por zonas.

signal formation_changed(formation: Formation)

var kind: Formation.Kind = Formation.Kind.OFFENSE
var formation: Formation = Formation.new()
var _rows: Dictionary = {} ## zone -> HBox with spin


func setup(p_kind: Formation.Kind, initial: Formation = null) -> void:
	kind = p_kind
	formation = initial.duplicate_formation() if initial else Formation.new()
	if kind == Formation.Kind.OFFENSE:
		formation.qb = 1
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_rows.clear()
	add_theme_constant_override("separation", 2)

	var title := Label.new()
	title.text = _kind_title()
	title.add_theme_font_size_override("font_size", 13)
	add_child(title)

	var budget := Label.new()
	budget.name = "BudgetLabel"
	budget.add_theme_font_size_override("font_size", 11)
	add_child(budget)

	for zone in _zones():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var lbl := Label.new()
		lbl.text = zone.label
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		var spin := SpinBox.new()
		spin.custom_minimum_size = Vector2(70, 0)
		spin.min_value = zone.min_v
		spin.max_value = zone.max_v
		spin.value = formation.get(zone.key)
		spin.value_changed.connect(_on_spin.bind(zone.key))
		row.add_child(lbl)
		row.add_child(spin)
		add_child(row)
		_rows[zone.key] = spin

	_update_budget()


func _on_spin(value: float, key: String) -> void:
	formation.set(key, int(value))
	if kind == Formation.Kind.OFFENSE:
		formation.qb = 1
		if _rows.has("qb"):
			_rows["qb"].value = 1
	_update_budget()
	formation_changed.emit(formation)


func _update_budget() -> void:
	var used := formation.total_for(kind)
	var budget: Label = get_node_or_null("BudgetLabel")
	if budget:
		var ok := formation.is_valid(kind)
		budget.text = "Fichas: %d / %d%s" % [used, Formation.TOKEN_BUDGET, "" if ok else "  (ajusta a 7)"]
		budget.modulate = Color(0.6, 1, 0.6) if ok else Color(1, 0.5, 0.4)


func get_formation() -> Formation:
	return formation.duplicate_formation()


func is_valid() -> bool:
	return formation.is_valid(kind)


func _kind_title() -> String:
	match kind:
		Formation.Kind.OFFENSE:
			return "Formación ofensiva"
		Formation.Kind.DEFENSE:
			return "Formación defensiva"
		Formation.Kind.PUNT_KICK:
			return "Equipo de despeje"
		Formation.Kind.PUNT_RETURN:
			return "Regreso de despeje"
	return "Formación"


func _zones() -> Array[Dictionary]:
	match kind:
		Formation.Kind.OFFENSE:
			return [
				{"key": "wr_l", "label": "Receptores izq.", "min_v": 0, "max_v": 6},
				{"key": "ol", "label": "Línea ofensiva", "min_v": 0, "max_v": 6},
				{"key": "wr_r", "label": "Receptores der.", "min_v": 0, "max_v": 6},
				{"key": "qb", "label": "Pasador (1)", "min_v": 1, "max_v": 1},
				{"key": "rb", "label": "Corredor", "min_v": 0, "max_v": 1},
			]
		Formation.Kind.DEFENSE:
			return [
				{"key": "dl", "label": "Línea defensiva", "min_v": 0, "max_v": 7},
				{"key": "lb", "label": "Apoyadores", "min_v": 0, "max_v": 7},
				{"key": "rear", "label": "Retaguardia vs carrera", "min_v": 0, "max_v": 7},
				{"key": "cb_l", "label": "Esquineros izq.", "min_v": 0, "max_v": 7},
				{"key": "cb_r", "label": "Esquineros der.", "min_v": 0, "max_v": 7},
				{"key": "s_l", "label": "Profundos izq.", "min_v": 0, "max_v": 7},
				{"key": "s_r", "label": "Profundos der.", "min_v": 0, "max_v": 7},
			]
		Formation.Kind.PUNT_KICK:
			return [
				{"key": "punt_cover_l", "label": "Cobertura izq.", "min_v": 0, "max_v": 6},
				{"key": "punt_protect", "label": "Protección pateador", "min_v": 0, "max_v": 6},
				{"key": "punt_cover_r", "label": "Cobertura der.", "min_v": 0, "max_v": 6},
				{"key": "kicker", "label": "Pateador (1)", "min_v": 1, "max_v": 1},
			]
		Formation.Kind.PUNT_RETURN:
			return [
				{"key": "returner", "label": "Regresador", "min_v": 1, "max_v": 1},
				{"key": "ret_cover_l", "label": "Cobertura izq.", "min_v": 0, "max_v": 6},
				{"key": "ret_cover_r", "label": "Cobertura der.", "min_v": 0, "max_v": 6},
				{"key": "pressure", "label": "Presión al pateador", "min_v": 0, "max_v": 6},
			]
	return []
