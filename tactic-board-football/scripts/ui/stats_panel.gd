extends PanelContainer

## Panel ESTADISTICAS: 2 columnas (jugador | CPU).

@onready var title_label: Label = %TitleLabel
@onready var left_body: RichTextLabel = %LeftBody
@onready var right_body: RichTextLabel = %RightBody
@onready var left_header: Label = %LeftHeader
@onready var right_header: Label = %RightHeader


func _ready() -> void:
	title_label.text = "ESTADISTICAS"
	refresh()


func refresh() -> void:
	if MatchState.player_team == null:
		return
	left_header.text = MatchState.player_team.short_name
	left_header.add_theme_color_override("font_color", MatchState.player_team.primary.lightened(0.35))
	right_header.text = MatchState.cpu_team.short_name
	right_header.add_theme_color_override("font_color", MatchState.cpu_team.primary.lightened(0.35))
	left_body.text = _format_stats(MatchState.stats_player)
	right_body.text = _format_stats(MatchState.stats_cpu)


func _format_stats(s: TeamStats) -> String:
	var lines: PackedStringArray = [
		"Yds tot %d | Pase %d | Tierra %d" % [s.total_yards(), s.pass_yards, s.rush_yards],
		"Comp/Att %d/%d" % [s.pass_completions, s.pass_attempts],
		"Rating QB %s" % s.qb_rating_text(),
		"TD P/T/Tot %d/%d/%d" % [s.pass_tds, s.rush_tds, s.total_tds()],
		"INT %d · Fum %d · TO %d" % [s.interceptions, s.fumbles_lost, s.turnovers()],
		"Sacks %d · 1ª %d" % [s.sacks_taken, s.first_downs],
		"FG %d/%d · Desp %d · Saf %d" % [s.fg_made, s.fg_attempts, s.punts, s.safeties_scored],
	]
	return "\n".join(lines)
