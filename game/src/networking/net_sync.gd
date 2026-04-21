## Handles network state synchronization for a player.
## Attach as child of a player CharacterBody2D.
## Sends local player state to all peers, receives remote player state.
extends Node

var player: CharacterBody2D
var _sync_rate: float = 1.0 / 20.0  # 20 Hz
var _sync_timer: float = 0.0

# Remote state for interpolation
var _remote_position: Vector2 = Vector2.ZERO
var _remote_velocity: Vector2 = Vector2.ZERO
var _remote_state: int = 0  # Player.State enum
var _remote_facing_right: bool = true
var _remote_aim_angle: float = 0.0
var _is_local: bool = true


func _ready() -> void:
	player = get_parent()
	if NetworkManager.is_online:
		_is_local = player.get_multiplayer_authority() == multiplayer.get_unique_id()
	else:
		_is_local = true


func _physics_process(delta: float) -> void:
	if not NetworkManager.is_online:
		return

	if _is_local:
		# Send our state to others
		_sync_timer += delta
		if _sync_timer >= _sync_rate:
			_sync_timer = 0.0
			_send_state.rpc()
	else:
		# Interpolate toward received remote state
		player.global_position = player.global_position.lerp(_remote_position, 10.0 * delta)
		player.velocity = _remote_velocity
		player.current_state = _remote_state as player.State
		player.facing_right = _remote_facing_right


@rpc("any_peer", "unreliable_ordered")
func _send_state() -> void:
	# This runs on all OTHER peers when called
	_remote_position = player.global_position
	_remote_velocity = player.velocity
	_remote_state = player.current_state
	_remote_facing_right = player.facing_right


@rpc("any_peer", "reliable")
func sync_damage(victim_id: int, attacker_id: int, damage: float, weapon_name: String) -> void:
	# Server validates and applies damage
	if not multiplayer.is_server():
		return

	for node in get_tree().get_nodes_in_group("players"):
		if node is CharacterBody2D and node.player_id == victim_id:
			var health: Node = node.get_node_or_null("HealthSystem")
			if health:
				health.take_damage(damage, attacker_id, weapon_name)
			break


@rpc("any_peer", "reliable")
func sync_kill(victim_id: int, killer_id: int, weapon_name: String) -> void:
	# Broadcast kill to all peers
	EventBus.player_died.emit(victim_id, killer_id, weapon_name)
	GameState.record_kill(killer_id, victim_id)
