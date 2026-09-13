extends Node

const PLAYER_MOVEMENT_PATH := "res://data/balance/player_movement.tres"
const SNOWBALL_PATH := "res://data/balance/snowball.tres"
const MATCH_RULES_PATH := "res://data/balance/match_rules.tres"
const GLACIER_VALLEY_PATH := "res://data/maps/glacier_valley.tres"

var player_movement: PlayerMovementConfig
var snowball: SnowballConfig
var match_rules: MatchRulesConfig
var glacier_valley: GlacierValleyConfig

func _ready() -> void:
	reload_all()

func reload_all() -> void:
	player_movement = _load_required(PLAYER_MOVEMENT_PATH) as PlayerMovementConfig
	snowball = _load_required(SNOWBALL_PATH) as SnowballConfig
	match_rules = _load_required(MATCH_RULES_PATH) as MatchRulesConfig
	glacier_valley = _load_required(GLACIER_VALLEY_PATH) as GlacierValleyConfig
	print("[Snowdown] gameplay configuration loaded")

func _load_required(path: String) -> Resource:
	var resource := load(path)
	assert(resource != null, "Required Snowdown config missing: %s" % path)
	return resource
