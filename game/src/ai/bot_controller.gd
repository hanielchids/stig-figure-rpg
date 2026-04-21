## Bot AI controller. Replaces human input with AI decisions.
## Attach as child of a player CharacterBody2D.
class_name BotController
extends Node

enum BotState { PATROL, SEEK_TARGET, ENGAGE, RETREAT, SEEK_WEAPON }

@export var difficulty: DifficultyProfile

var player: CharacterBody2D
var input_manager: InputManager
var weapon_manager: WeaponManager
var health_system: HealthSystem

var current_state: BotState = BotState.PATROL
var target: CharacterBody2D = null
var _state_timer: float = 0.0
var _fire_delay: float = 0.0
var _aim_noise: float = 0.0
var _patrol_timer: float = 0.0
var _strafe_dir: float = 0.0


func _ready() -> void:
	player = get_parent()
	input_manager = player.get_node("InputManager")
	weapon_manager = player.get_node("WeaponManager")
	health_system = player.get_node("HealthSystem")

	if difficulty == null:
		difficulty = load("res://assets/ai/medium.tres") as DifficultyProfile

	_patrol_timer = randf_range(1.0, 3.0)
	_strafe_dir = [-1.0, 1.0][randi() % 2]


func _process(delta: float) -> void:
	if player.is_dead:
		_clear_input()
		return

	_state_timer += delta
	_fire_delay = maxf(_fire_delay - delta, 0.0)

	_evaluate_state()

	match current_state:
		BotState.PATROL:
			_do_patrol(delta)
		BotState.SEEK_TARGET:
			_do_seek_target(delta)
		BotState.ENGAGE:
			_do_engage(delta)
		BotState.RETREAT:
			_do_retreat(delta)
		BotState.SEEK_WEAPON:
			_do_seek_weapon(delta)


func _evaluate_state() -> void:
	# Retreat if low health
	if health_system.get_hp_percent() < difficulty.retreat_health_threshold:
		if current_state != BotState.RETREAT:
			_change_state(BotState.RETREAT)
			return

	# Find enemies
	var all_players: Array[Node] = get_tree().get_nodes_in_group("players")
	target = _find_nearest_visible_enemy(all_players)

	if target and current_state != BotState.RETREAT:
		var dist: float = player.global_position.distance_to(target.global_position)
		var weapon: WeaponDefinition = weapon_manager.get_current_weapon()
		if weapon and dist <= weapon.range_distance * 1.2:
			_change_state(BotState.ENGAGE)
		else:
			_change_state(BotState.SEEK_TARGET)
	elif current_state != BotState.RETREAT:
		if not weapon_manager.has_weapon():
			_change_state(BotState.SEEK_WEAPON)
		elif current_state != BotState.PATROL:
			_change_state(BotState.PATROL)


func _do_patrol(delta: float) -> void:
	_patrol_timer -= delta
	if _patrol_timer <= 0:
		_strafe_dir = -_strafe_dir
		_patrol_timer = randf_range(2.0, 5.0)

	input_manager.current_input.move_direction = _strafe_dir

	# Jump when hitting a wall
	if player.is_on_wall() and player.is_on_floor():
		input_manager.current_input.jump_pressed = true
		input_manager.current_input.jump_held = true
	else:
		input_manager.current_input.jump_pressed = false
		input_manager.current_input.jump_held = false

	# Occasionally jetpack up
	if randf() < 0.01:
		input_manager.current_input.jetpack_held = true
	else:
		input_manager.current_input.jetpack_held = false

	_clear_fire()


func _do_seek_target(_delta: float) -> void:
	if not target or not is_instance_valid(target):
		_change_state(BotState.PATROL)
		return

	var dir_to_target: Vector2 = target.global_position - player.global_position
	input_manager.current_input.move_direction = signf(dir_to_target.x)

	# Jump or jetpack if target is above
	if dir_to_target.y < -50:
		if player.is_on_floor():
			input_manager.current_input.jump_pressed = true
			input_manager.current_input.jump_held = true
		elif player.jetpack_fuel > 20:
			input_manager.current_input.jetpack_held = true
	else:
		input_manager.current_input.jump_pressed = false
		input_manager.current_input.jump_held = false
		input_manager.current_input.jetpack_held = false

	# Jump when hitting a wall
	if player.is_on_wall() and player.is_on_floor():
		input_manager.current_input.jump_pressed = true
		input_manager.current_input.jump_held = true

	_clear_fire()


func _do_engage(_delta: float) -> void:
	if not target or not is_instance_valid(target) or target.is_dead:
		target = null
		_change_state(BotState.PATROL)
		return

	var to_target: Vector2 = target.global_position - player.global_position
	var dist: float = to_target.length()

	# Aim at target center mass with noise
	_aim_noise = lerpf(_aim_noise, randf_range(-difficulty.aim_noise_deg, difficulty.aim_noise_deg), _delta * 3.0)
	var aim_pos: Vector2 = target.global_position + Vector2(0, -20)
	aim_pos += Vector2.from_angle(randf() * TAU) * _aim_noise
	input_manager.current_input.aim_position = aim_pos

	# Movement while fighting
	if dist < 150:
		# Too close — back up
		input_manager.current_input.move_direction = -signf(to_target.x)
	elif dist > 400:
		# Too far — close in
		input_manager.current_input.move_direction = signf(to_target.x)
	else:
		# Strafe
		if _state_timer > 1.5:
			_strafe_dir = -_strafe_dir
			_state_timer = 0.0
		input_manager.current_input.move_direction = _strafe_dir

	# Fire with reaction delay
	if _fire_delay <= 0:
		input_manager.current_input.fire_pressed = true
		input_manager.current_input.fire_held = true
		_fire_delay = difficulty.reaction_time_sec * randf_range(0.8, 1.2)
	else:
		_clear_fire()

	# Reload if empty
	var weapon: WeaponDefinition = weapon_manager.get_current_weapon()
	if weapon and weapon.ammo_capacity >= 0 and weapon_manager.get_current_ammo() <= 0:
		input_manager.current_input.reload_pressed = true

	# Jump/jetpack occasionally
	input_manager.current_input.jump_pressed = false
	input_manager.current_input.jump_held = false
	input_manager.current_input.jetpack_held = false
	if player.is_on_wall() and player.is_on_floor():
		input_manager.current_input.jump_pressed = true
		input_manager.current_input.jump_held = true
	elif randf() < difficulty.aggression * 0.02:
		input_manager.current_input.jetpack_held = true


func _do_retreat(_delta: float) -> void:
	# Run away from target
	if target and is_instance_valid(target):
		var away_dir: float = -signf(target.global_position.x - player.global_position.x)
		input_manager.current_input.move_direction = away_dir
	else:
		input_manager.current_input.move_direction = _strafe_dir

	# Jump when hitting a wall
	if player.is_on_wall() and player.is_on_floor():
		input_manager.current_input.jump_pressed = true
		input_manager.current_input.jump_held = true
	else:
		input_manager.current_input.jump_pressed = false
		input_manager.current_input.jump_held = false

	input_manager.current_input.jetpack_held = false
	_clear_fire()

	# Exit retreat if health recovered
	if health_system.get_hp_percent() > 0.6:
		_change_state(BotState.PATROL)


func _do_seek_weapon(_delta: float) -> void:
	# Just patrol — will pick up weapons by walking over them
	_do_patrol(_delta)
	if weapon_manager.has_weapon():
		_change_state(BotState.PATROL)


func _find_nearest_visible_enemy(nodes: Array[Node]) -> CharacterBody2D:
	var nearest: CharacterBody2D = null
	var nearest_dist: float = difficulty.detection_range

	for node in nodes:
		if not node is CharacterBody2D:
			continue
		var character: CharacterBody2D = node as CharacterBody2D
		if character == player or character.is_dead:
			continue
		var dist: float = player.global_position.distance_to(character.global_position)
		if dist < nearest_dist:
			# Line of sight check
			var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
			var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
				player.global_position + Vector2(0, -20),
				character.global_position + Vector2(0, -20),
				Constants.LAYER_WORLD
			)
			var result: Dictionary = space.intersect_ray(query)
			if result.is_empty():
				nearest_dist = dist
				nearest = character

	return nearest


func _change_state(new_state: BotState) -> void:
	current_state = new_state
	_state_timer = 0.0


func _clear_input() -> void:
	input_manager.current_input.move_direction = 0.0
	input_manager.current_input.jump_pressed = false
	input_manager.current_input.jump_held = false
	input_manager.current_input.jetpack_held = false
	_clear_fire()


func _clear_fire() -> void:
	input_manager.current_input.fire_pressed = false
	input_manager.current_input.fire_held = false
	input_manager.current_input.reload_pressed = false
