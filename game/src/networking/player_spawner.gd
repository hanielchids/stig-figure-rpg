## Handles spawning and despawning players in a networked match.
## Server authoritative — only the host spawns players.
extends Node

var player_scene: PackedScene = preload("res://src/player/player.tscn")
var bot_scene: PackedScene = preload("res://src/ai/bot.tscn")

var _spawned_players: Dictionary = {}  # peer_id -> CharacterBody2D
var _spawn_manager: SpawnPointManager


func _ready() -> void:
	# Find spawn manager
	for child in get_parent().get_children():
		if child is SpawnPointManager:
			_spawn_manager = child
			break


func spawn_player(peer_id: int, player_name: String) -> CharacterBody2D:
	var is_local: bool = (peer_id == NetworkManager.get_my_id()) or (not NetworkManager.is_online and peer_id == 0)

	var character: CharacterBody2D
	if is_local:
		character = player_scene.instantiate()  # has Camera2D
	else:
		character = bot_scene.instantiate()  # no Camera2D

	character.player_id = peer_id
	character.name = "Player_%d" % peer_id
	character.add_to_group("players")

	# In multiplayer, set authority so input is processed by the owning peer
	if NetworkManager.is_online:
		character.set_multiplayer_authority(peer_id)

	get_parent().add_child(character)

	# Position after adding to tree
	if _spawn_manager:
		var enemy_positions: Array[Vector2] = _get_enemy_positions(peer_id)
		character.global_position = _spawn_manager.get_spawn_point(enemy_positions)
	else:
		character.global_position = Vector2(400 + peer_id % 4 * 300, 820)

	# Disable human input on non-local players
	if not is_local:
		var input_mgr: Node = character.get_node_or_null("InputManager")
		if input_mgr:
			input_mgr.set_process(false)

	_spawned_players[peer_id] = character
	GameState.add_player(peer_id, player_name)

	return character


func spawn_bot(bot_id: int, bot_name: String) -> CharacterBody2D:
	var bot: CharacterBody2D = bot_scene.instantiate()
	bot.player_id = bot_id
	bot.name = "Bot_%d" % bot_id
	bot.add_to_group("players")

	var input_mgr: Node = bot.get_node_or_null("InputManager")
	if input_mgr:
		input_mgr.set_process(false)

	get_parent().add_child(bot)

	if _spawn_manager:
		var enemy_positions: Array[Vector2] = _get_enemy_positions(bot_id)
		bot.global_position = _spawn_manager.get_spawn_point(enemy_positions)
	else:
		bot.global_position = Vector2(200 + bot_id * 300, 820)

	_spawned_players[bot_id] = bot
	GameState.add_player(bot_id, bot_name)

	return bot


func despawn_player(peer_id: int) -> void:
	if _spawned_players.has(peer_id):
		var character: CharacterBody2D = _spawned_players[peer_id]
		if is_instance_valid(character):
			character.queue_free()
		_spawned_players.erase(peer_id)
		GameState.remove_player(peer_id)


func _get_enemy_positions(exclude_id: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for id in _spawned_players:
		if id != exclude_id:
			var character: CharacterBody2D = _spawned_players[id]
			if is_instance_valid(character) and not character.is_dead:
				positions.append(character.global_position)
	return positions
