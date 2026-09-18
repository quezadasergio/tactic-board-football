extends Node3D

## Dado 3D con caras numeradas; el color base viene del equipo.

signal roll_finished(value: int)

var value: int = 1
var _tween: Tween
var mesh_instance: MeshInstance3D
var primary: Color = Color.WHITE
var secondary: Color = Color.BLACK


func _ready() -> void:
	mesh_instance = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	mesh_instance.mesh = box
	add_child(mesh_instance)
	_apply_material()
	_add_pip_labels()


func setup_colors(p: Color, s: Color) -> void:
	primary = p
	secondary = s
	if mesh_instance:
		_apply_material()


func _apply_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = primary
	mat.roughness = 0.45
	mat.metallic = 0.05
	mesh_instance.material_override = mat


func _add_pip_labels() -> void:
	# Etiquetas 3D simples en cada cara (Label3D)
	var faces := [
		{"n": 1, "pos": Vector3(0, 0.46, 0), "rot": Vector3(-90, 0, 0)},
		{"n": 6, "pos": Vector3(0, -0.46, 0), "rot": Vector3(90, 0, 0)},
		{"n": 2, "pos": Vector3(0, 0, 0.46), "rot": Vector3(0, 0, 0)},
		{"n": 5, "pos": Vector3(0, 0, -0.46), "rot": Vector3(0, 180, 0)},
		{"n": 3, "pos": Vector3(0.46, 0, 0), "rot": Vector3(0, -90, 0)},
		{"n": 4, "pos": Vector3(-0.46, 0, 0), "rot": Vector3(0, 90, 0)},
	]
	for f in faces:
		var lbl := Label3D.new()
		lbl.text = str(f.n)
		lbl.font_size = 96
		lbl.modulate = secondary
		lbl.outline_modulate = primary.darkened(0.4)
		lbl.outline_size = 10
		lbl.position = f.pos
		lbl.rotation_degrees = f.rot
		# ~80% del área de la cara (antes ~100%)
		lbl.pixel_size = 0.012
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		add_child(lbl)


func show_value(v: int) -> void:
	value = clampi(v, 1, 6)
	rotation_degrees = _rotation_for(value)


func animate_to(v: int, delay: float = 0.0) -> void:
	value = clampi(v, 1, 6)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(false)
	if delay > 0.0:
		_tween.tween_interval(delay)
	var start_rot := rotation_degrees
	var spins := Vector3(360.0 * randi_range(2, 4), 360.0 * randi_range(2, 4), 360.0 * randi_range(1, 3))
	var target := _rotation_for(value)
	_tween.tween_property(self, "rotation_degrees", start_rot + spins + target, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func():
		rotation_degrees = target
		roll_finished.emit(value)
	)


func _rotation_for(v: int) -> Vector3:
	# Orientación para que la cara `v` quede arriba (+Y)
	match v:
		1:
			return Vector3.ZERO
		2:
			return Vector3(90, 0, 0)
		3:
			return Vector3(0, 0, -90)
		4:
			return Vector3(0, 0, 90)
		5:
			return Vector3(-90, 0, 0)
		6:
			return Vector3(180, 0, 0)
		_:
			return Vector3.ZERO
