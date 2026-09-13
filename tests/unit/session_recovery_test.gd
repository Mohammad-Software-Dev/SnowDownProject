extends SceneTree

func _init() -> void:
	var join_failure := SessionRecovery.describe(
		SessionRecovery.STATE_CONNECTION_FAILED,
		SessionRecovery.KIND_JOIN,
		"192.0.2.10:7000"
	)
	_assert_equal(join_failure["title"], "CONNECTION FAILED", "join failure title")
	_assert_equal(join_failure["retry_label"], "RETRY CONNECTION", "join retry label")
	_assert_true(String(join_failure["message"]).contains("192.0.2.10:7000"), "join recovery preserves endpoint")
	_assert_true(bool(join_failure["can_retry"]), "join failure remains retryable")

	var host_disconnect := SessionRecovery.describe(
		SessionRecovery.STATE_SERVER_DISCONNECTED,
		SessionRecovery.KIND_HOST,
		"127.0.0.1:7000"
	)
	_assert_equal(host_disconnect["title"], "LOCAL SERVER STOPPED", "local host disconnect title")
	_assert_equal(host_disconnect["retry_label"], "RESTART HOST", "local host restart label")
	_assert_true(bool(host_disconnect["can_retry"]), "local host remains restartable")

	var unknown := SessionRecovery.describe(&"other", &"", "")
	_assert_true(not bool(unknown["can_retry"]), "unknown session cannot retry blindly")

	print("SNOWDOWN_SESSION_RECOVERY_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)
