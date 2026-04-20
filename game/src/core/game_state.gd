## Tracks global game state: current match, players, scores.
## Access via the GameState autoload singleton.
extends Node

enum MatchState { NONE, LOBBY, STARTING, IN_PROGRESS, ENDED }
enum GameMode { DEATHMATCH, TEAM_DEATHMATCH }

var current_state: MatchState = MatchState.NONE
var current_mode: GameMode = GameMode.DEATHMATCH
var current_map: String = ""

# Player tracking: player_id -> { name, kills, deaths, team }
var players: Dictionary = {}

# Match config
var max_score: int = 20
var match_time_limit: float = 300.0  # 5 minutes
var match_timer: float = 0.0

var local_player_id: int = -1


func reset() -> void:
	current_state = MatchState.NONE
	players.clear()
	match_timer = 0.0


func add_player(id: int, player_name: String, team: int = -1) -> void:
	players[id] = {
		"name": player_name,
		"kills": 0,
		"deaths": 0,
		"team": team,
	}


func remove_player(id: int) -> void:
	players.erase(id)


func record_kill(killer_id: int, victim_id: int) -> void:
	if players.has(killer_id):
		players[killer_id]["kills"] += 1
	if players.has(victim_id):
		players[victim_id]["deaths"] += 1
	EventBus.score_updated.emit(killer_id, players[killer_id]["kills"], players[killer_id]["deaths"])


func get_scoreboard() -> Array:
	var scores: Array = []
	for id in players:
		var p = players[id]
		scores.append({
			"id": id,
			"name": p["name"],
			"kills": p["kills"],
			"deaths": p["deaths"],
		})
	scores.sort_custom(func(a, b): return a["kills"] > b["kills"])
	return scores


func check_win_condition() -> int:
	## Returns player_id of winner, or -1 if no winner yet.
	for id in players:
		if players[id]["kills"] >= max_score:
			return id
	return -1
