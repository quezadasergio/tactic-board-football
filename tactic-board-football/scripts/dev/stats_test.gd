extends SceneTree
func _init():
	var s := TeamStats.new()
	s.pass_attempts = 10
	s.pass_completions = 7
	s.pass_yards = 120
	s.pass_tds = 1
	s.interceptions = 0
	print("rating=", s.qb_rating_text())
	print("OK")
	quit()
