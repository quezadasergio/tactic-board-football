extends Control

@onready var duration_option: OptionButton = %DurationOption
@onready var team_option: OptionButton = %TeamOption
@onready var start_btn: Button = %StartButton
@onready var rules_btn: Button = %RulesButton
@onready var glossary_btn: Button = %GlossaryButton
@onready var credit_label: RichTextLabel = %CreditLabel

var _teams: Array[TeamData] = []


func _ready() -> void:
	_teams = TeamData.fake_roster()
	duration_option.clear()
	for key in ["corto", "mediano", "largo"]:
		duration_option.add_item(RulesTables.DURATION_LABELS[key])
		duration_option.set_item_metadata(duration_option.item_count - 1, key)
	duration_option.select(1)

	team_option.clear()
	for t in _teams:
		team_option.add_item("%s (%s)" % [t.name, t.short_name])
	team_option.select(0)

	start_btn.pressed.connect(_on_start)
	rules_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/rules_screen.tscn"))
	glossary_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/glossary_screen.tscn"))
	credit_label.meta_clicked.connect(_on_credit_meta_clicked)


func _on_credit_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))


func _on_start() -> void:
	var dur: String = duration_option.get_item_metadata(duration_option.selected)
	var player: TeamData = _teams[team_option.selected]
	var cpu: TeamData = _teams[(team_option.selected + 1) % _teams.size()]
	MatchState.configure(player, cpu, dur)
	get_tree().change_scene_to_file("res://scenes/match/match.tscn")
