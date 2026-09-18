extends SceneTree

func _init() -> void:
	var off := SimpleAI.make_offense()
	var deff := SimpleAI.make_defense_balanced()
	assert(off.is_valid(Formation.Kind.OFFENSE))
	assert(deff.is_valid(Formation.Kind.DEFENSE))
	var run_res := RulesEngine.resolve_run(off, deff)
	print("RUN: ", run_res.summary, " yards=", run_res.yards)
	var pass_res := RulesEngine.resolve_pass(off, deff, "L")
	print("PASS: ", pass_res.summary, " yards=", pass_res.yards)
	var fg := RulesEngine.resolve_field_goal(30)
	print("FG: ", fg.summary)
	var teams := TeamData.fake_roster()
	print("Teams: ", teams[0].name, " / ", teams[1].name)
	print("OK")
	quit()
