extends SceneTree

func _init() -> void:
	var direct := SessionAddress.parse("snowdown://127.0.0.1:7001", 7000)
	_assert_true(bool(direct["valid"]), "direct address should parse")
	_assert_equal(String(direct["host"]), "127.0.0.1", "direct host")
	_assert_equal(int(direct["port"]), 7001, "direct port")

	var hostname := SessionAddress.parse("example.com", 7000)
	_assert_true(bool(hostname["valid"]), "hostname should parse")
	_assert_equal(String(hostname["host"]), "example.com", "hostname")
	_assert_equal(int(hostname["port"]), 7000, "default port")

	var ipv6 := SessionAddress.parse("[::1]:7010", 7000)
	_assert_true(bool(ipv6["valid"]), "IPv6 should parse")
	_assert_equal(String(ipv6["host"]), "::1", "IPv6 host")
	_assert_equal(SessionAddress.format_endpoint("::1", 7010), "[::1]:7010", "IPv6 formatting")

	_assert_true(not bool(SessionAddress.parse("", 7000)["valid"]), "empty address should fail")
	_assert_true(not bool(SessionAddress.parse("localhost:80", 7000)["valid"]), "privileged port should fail")

	var host_args := LocalHostProcess.build_arguments(7040)
	_assert_true(host_args.has("--server"), "host process uses authoritative server role")
	_assert_true(host_args.has("--world=glacier_valley"), "host process uses Glacier Valley")
	_assert_true(host_args.has("--port=7040"), "host process forwards selected port")

	print("SNOWDOWN_SESSION_ADDRESS_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)
