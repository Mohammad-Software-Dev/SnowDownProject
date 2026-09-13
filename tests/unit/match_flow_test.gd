extends SceneTree

func _initialize() -> void:
	var flow := MatchFlow.new()
	flow.configure(2, 0.10, 0.20, 0.10, true)

	if flow.try_score(0, 1):
		_fail("waiting phase must reject score")
		return
	if not flow.tick(0.0, 2) or flow.phase != MatchFlow.PHASE_COUNTDOWN or flow.round_number != 1:
		_fail("two teams should enter countdown and round 1")
		return
	flow.tick(0.11, 2)
	if flow.phase != MatchFlow.PHASE_ACTIVE:
		_fail("countdown should enter active")
		return
	flow.tick(0.21, 2)
	if flow.phase != MatchFlow.PHASE_SUDDEN_SNOW:
		_fail("tied regulation must enter Sudden Snow")
		return
	if flow.try_score(0, 0):
		_fail("zero-point event must not resolve Sudden Snow")
		return
	if not flow.try_score(1, 1) or flow.phase != MatchFlow.PHASE_RESULTS or flow.winner_team != 1:
		_fail("next valid Sudden Snow score must resolve results")
		return
	flow.tick(0.11, 2)
	if flow.phase != MatchFlow.PHASE_COUNTDOWN or flow.round_number != 2 or flow.team_a_score != 0 or flow.team_b_score != 0:
		_fail("results must reset into a clean next round")
		return
	flow.tick(0.0, 1)
	if flow.phase != MatchFlow.PHASE_WAITING:
		_fail("pre-match player loss must return to waiting")
		return

	var regulation_win := MatchFlow.new()
	regulation_win.configure(2, 0.01, 0.05, 0.01, true)
	regulation_win.tick(0.0, 2)
	regulation_win.tick(0.02, 2)
	if not regulation_win.try_score(0, 2):
		_fail("active phase should accept score")
		return
	regulation_win.tick(0.06, 2)
	if regulation_win.phase != MatchFlow.PHASE_RESULTS or regulation_win.winner_team != 0:
		_fail("regulation leader should win at zero")
		return

	print("SNOWDOWN_MATCH_FLOW_OK")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
