extends Control

@onready var list: VBoxContainer = %List
@onready var back_btn: Button = %BackButton
@export var mode: String = "rules" ## rules | glossary


func _ready() -> void:
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))
	var title: Label = %Title
	if mode == "glossary":
		title.text = "Glosario"
		for item in ContentData.glossary():
			_add_block(item.term, item.def)
	else:
		title.text = "Reglas del juego"
		for item in ContentData.rules_sections():
			_add_block(item.title, item.body)


func _add_block(heading: String, body: String) -> void:
	var h := Label.new()
	h.text = heading
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(0.95, 0.9, 0.4))
	list.add_child(h)
	var b := Label.new()
	b.text = body
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_color_override("font_color", Color(0.92, 0.95, 0.9))
	list.add_child(b)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 10)
	list.add_child(sp)
