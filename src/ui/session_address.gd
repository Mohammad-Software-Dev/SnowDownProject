class_name SessionAddress
extends RefCounted

const MIN_PORT := 1024
const MAX_PORT := 65535

static func parse(value: String, default_port: int) -> Dictionary:
	var text := value.strip_edges()
	if text.begins_with("snowdown://"):
		text = text.trim_prefix("snowdown://")
	if text.is_empty():
		return _invalid("Enter a host name or IP address.")

	var host := text
	var port := default_port
	if text.begins_with("["):
		var closing := text.find("]")
		if closing < 0:
			return _invalid("IPv6 address is missing a closing bracket.")
		host = text.substr(1, closing - 1)
		var suffix := text.substr(closing + 1)
		if not suffix.is_empty():
			if not suffix.begins_with(":"):
				return _invalid("Unexpected text after IPv6 address.")
			var port_text := suffix.trim_prefix(":")
			if not port_text.is_valid_int():
				return _invalid("Port must be a number.")
			port = port_text.to_int()
	elif text.count(":") == 1:
		var separator := text.rfind(":")
		var port_text := text.substr(separator + 1)
		if port_text.is_valid_int():
			host = text.substr(0, separator)
			port = port_text.to_int()

	host = host.strip_edges()
	if host.is_empty():
		return _invalid("Host cannot be empty.")
	if host.length() > 253 or host.contains(" ") or host.contains("\t") or host.contains("\n"):
		return _invalid("Host name is not valid.")
	if port < MIN_PORT or port > MAX_PORT:
		return _invalid("Port must be between %d and %d." % [MIN_PORT, MAX_PORT])
	return {"valid": true, "host": host, "port": port, "error": ""}

static func format_endpoint(host: String, port: int) -> String:
	var normalized := host.strip_edges()
	if normalized.contains(":") and not normalized.begins_with("["):
		normalized = "[%s]" % normalized
	return "%s:%d" % [normalized, port]

static func _invalid(message: String) -> Dictionary:
	return {"valid": false, "host": "", "port": 0, "error": message}
