class_name SnowballPresentation
extends RefCounted

const MIN_STREAK_SPEED := 4.0
const MIN_STREAK_LENGTH := 0.16
const MAX_STREAK_LENGTH := 0.72
const STREAK_SECONDS := 0.032

static func streak_length_for_speed(speed: float) -> float:
	if speed < MIN_STREAK_SPEED:
		return 0.0
	return clampf(speed * STREAK_SECONDS, MIN_STREAK_LENGTH, MAX_STREAK_LENGTH)

static func feedback_for_event(event_text: String, local_peer_id: int) -> Dictionary:
	if event_text.is_empty():
		return {"text": "", "local_reaction": false, "emphasis": 0}
	var target_is_local := local_peer_id > 0 and event_text.contains("target=%d" % local_peer_id)
	if event_text.begins_with("head_hit"):
		return {
			"text": "HEAD HIT — KEEP MOVING" if target_is_local else "HEAD HIT!",
			"local_reaction": target_is_local,
			"emphasis": 2,
		}
	if event_text.begins_with("body_hit"):
		return {
			"text": "BODY HIT — KEEP MOVING" if target_is_local else "BODY HIT!",
			"local_reaction": target_is_local,
			"emphasis": 1,
		}
	if event_text.begins_with("caught"):
		return {
			"text": "CATCH! SNOWBALL RECOVERED" if target_is_local else "SNOWBALL CAUGHT",
			"local_reaction": target_is_local,
			"emphasis": 1,
		}
	if event_text.begins_with("protected_impact"):
		return {
			"text": "SPAWN PROTECTION" if target_is_local else "TARGET PROTECTED",
			"local_reaction": target_is_local,
			"emphasis": 1,
		}
	if event_text.begins_with("world_impact"):
		return {"text": "", "local_reaction": false, "emphasis": 0}
	if event_text.begins_with("projectiles cleared"):
		return {"text": "", "local_reaction": false, "emphasis": 0}
	return {"text": event_text, "local_reaction": false, "emphasis": 0}
