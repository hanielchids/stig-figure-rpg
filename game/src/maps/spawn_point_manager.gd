## Manages player spawn points on a map.
## Selects spawn points using weighted-random favoring distance from enemies.
class_name SpawnPointManager
extends Node

var player_spawns: Array[Marker2D] = []


func _ready() -> void:
	_collect_spawns()


func _collect_spawns() -> void:
	if not player_spawns.is_empty():
		return
	for child in get_parent().get_children():
		if child is Marker2D and child.name.begins_with("PlayerSpawn"):
			player_spawns.append(child)


func get_spawn_point(enemy_positions: Array[Vector2] = []) -> Vector2:
	_collect_spawns()
	if player_spawns.is_empty():
		# Fallback: on the arena floor
		return Vector2(400 + randi() % 800, 820)

	if enemy_positions.is_empty():
		var idx: int = randi() % player_spawns.size()
		return player_spawns[idx].global_position

	var best_score: float = -1.0
	var candidates: Array[Vector2] = []

	for spawn in player_spawns:
		var min_dist: float = INF
		for enemy_pos in enemy_positions:
			var dist: float = spawn.global_position.distance_to(enemy_pos)
			min_dist = minf(min_dist, dist)

		if min_dist > best_score:
			best_score = min_dist
			candidates.clear()
			candidates.append(spawn.global_position)
		elif absf(min_dist - best_score) < 50.0:
			candidates.append(spawn.global_position)

	var pick: int = randi() % candidates.size()
	return candidates[pick]
