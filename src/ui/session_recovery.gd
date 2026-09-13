class_name SessionRecovery
extends RefCounted

const STATE_CONNECTION_FAILED: StringName = &"connection_failed"
const STATE_SERVER_DISCONNECTED: StringName = &"server_disconnected"
const KIND_HOST: StringName = &"host"
const KIND_JOIN: StringName = &"join"

static func describe(state: StringName, session_kind: StringName, endpoint: String) -> Dictionary:
	var is_host := session_kind == KIND_HOST
	var title := "CONNECTION LOST"
	var message := "The network session ended."
	if state == STATE_CONNECTION_FAILED:
		title = "HOST START FAILED" if is_host else "CONNECTION FAILED"
		message = (
			"The local server started, but this client could not connect to %s." % endpoint
			if is_host
			else "Could not connect to %s. Check the address, port, firewall, and host status." % endpoint
		)
	elif state == STATE_SERVER_DISCONNECTED:
		title = "LOCAL SERVER STOPPED" if is_host else "CONNECTION LOST"
		message = (
			"The local authoritative server stopped. Restart the host to begin a fresh session."
			if is_host
			else "The server at %s disconnected. You can retry when the host is available again." % endpoint
		)
	return {
		"title": title,
		"message": message,
		"retry_label": "RESTART HOST" if is_host else "RETRY CONNECTION",
		"can_retry": session_kind == KIND_HOST or session_kind == KIND_JOIN,
	}
