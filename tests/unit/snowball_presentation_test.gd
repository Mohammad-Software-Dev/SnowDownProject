extends SceneTree

func _init() -> void:
	_assert_equal(SnowballPresentation.streak_length_for_speed(0.0), 0.0, "stationary streak")
	_assert_equal(SnowballPresentation.streak_length_for_speed(3.0), 0.0, "slow streak")
	_assert_near(SnowballPresentation.streak_length_for_speed(14.0), 0.448, 0.001, "normal throw streak")
	_assert_equal(SnowballPresentation.streak_length_for_speed(100.0), SnowballPresentation.MAX_STREAK_LENGTH, "max streak clamp")

	var local_head := SnowballPresentation.feedback_for_event("head_hit projectile=3 target=42 at=(0,0,0)", 42)
	_assert_equal(String(local_head["text"]), "HEAD HIT — KEEP MOVING", "local head reaction copy")
	_assert_true(bool(local_head["local_reaction"]), "local head reaction")
	_assert_equal(int(local_head["emphasis"]), 2, "head emphasis")

	var remote_body := SnowballPresentation.feedback_for_event("body_hit projectile=4 target=99 at=(0,0,0)", 42)
	_assert_equal(String(remote_body["text"]), "BODY HIT!", "remote body copy")
	_assert_true(not bool(remote_body["local_reaction"]), "remote body no local reaction")

	var local_catch := SnowballPresentation.feedback_for_event("caught projectile=5 target=42 at=(0,0,0)", 42)
	_assert_equal(String(local_catch["text"]), "CATCH! SNOWBALL RECOVERED", "local catch copy")
	_assert_true(bool(local_catch["local_reaction"]), "local catch reaction")

	var world := SnowballPresentation.feedback_for_event("world_impact projectile=6 target=0 at=(0,0,0)", 42)
	_assert_equal(String(world["text"]), "", "world impact stays quiet")

	print("SNOWDOWN_SNOWBALL_PRESENTATION_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)

func _assert_near(actual: float, expected: float, tolerance: float, label: String) -> void:
	if absf(actual - expected) > tolerance:
		push_error("%s expected=%.4f actual=%.4f" % [label, expected, actual])
		quit(1)
