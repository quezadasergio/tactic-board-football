extends Control

## Bandeja de dados 3D embebida en un SubViewport.

signal rolls_done(offense_values: Array, defense_values: Array)

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var world: Node3D = $SubViewportContainer/SubViewport/World
@onready var camera: Camera3D = $SubViewportContainer/SubViewport/World/Camera3D
@onready var label: Label = $Label

var _dice_root: Node3D
var _pending: int = 0
var _off_vals: Array = []
var _def_vals: Array = []
var _roll_id: int = 0


func _ready() -> void:
	_dice_root = Node3D.new()
	_dice_root.name = "DiceRoot"
	world.add_child(_dice_root)

	var light := DirectionalLight3D.new()
	light.name = "DiceLight"
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_energy = 1.1
	world.add_child(light)


func clear_dice() -> void:
	_roll_id += 1
	_pending = 0
	_off_vals.clear()
	_def_vals.clear()

	if _dice_root == null:
		return

	# Liberar al instante (queue_free deja fantasma un frame y se apilan).
	var children := _dice_root.get_children()
	for c in children:
		if c.has_signal("roll_finished") and c.roll_finished.is_connected(_on_die_done):
			c.roll_finished.disconnect(_on_die_done)
		_dice_root.remove_child(c)
		c.free()


func play_rolls(
	label_text: String,
	offense_rolls: Array,
	defense_rolls: Array,
	off_primary: Color,
	off_secondary: Color,
	def_primary: Color,
	def_secondary: Color
) -> void:
	clear_dice()
	var my_roll := _roll_id
	label.text = label_text
	_off_vals = offense_rolls.duplicate()
	_def_vals = defense_rolls.duplicate()

	var off_count := offense_rolls.size()
	var def_count := defense_rolls.size()
	_pending = off_count + def_count
	if _pending == 0:
		rolls_done.emit(_off_vals, _def_vals)
		return

	var spacing := 1.35
	var row_gap := 1.6
	var off_start := -((maxi(off_count, 1) - 1) * spacing) * 0.5
	var def_start := -((maxi(def_count, 1) - 1) * spacing) * 0.5

	for i in off_count:
		_spawn_die(
			"DieO%d" % i,
			Vector3(off_start + i * spacing, 0.6, -row_gap),
			int(offense_rolls[i]),
			off_primary,
			off_secondary,
			i * 0.08,
			my_roll
		)
	for i in def_count:
		_spawn_die(
			"DieD%d" % i,
			Vector3(def_start + i * spacing, 0.6, row_gap),
			int(defense_rolls[i]),
			def_primary,
			def_secondary,
			(off_count + i) * 0.08,
			my_roll
		)


func _spawn_die(
	die_name: String,
	pos: Vector3,
	value: int,
	p: Color,
	s: Color,
	delay: float,
	roll_id: int
) -> void:
	var die_script: GDScript = load("res://scripts/dice/die_3d.gd")
	var die: Node3D = Node3D.new()
	die.set_script(die_script)
	die.name = die_name
	die.position = pos
	_dice_root.add_child(die)
	die.call("setup_colors", p, s)
	die.roll_finished.connect(_on_die_done.bind(roll_id))
	die.call("animate_to", value, delay)


func _on_die_done(_v: int, roll_id: int) -> void:
	# Ignorar callbacks de tiradas anteriores ya limpiadas.
	if roll_id != _roll_id:
		return
	_pending -= 1
	if _pending <= 0:
		_pending = 0
		rolls_done.emit(_off_vals, _def_vals)
