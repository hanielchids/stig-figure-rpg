## Draws the currently equipped weapon on the character.
## Attach as child of the player — renders a weapon sprite at the aim angle.
extends Node2D

var player: CharacterBody2D
var _aim_angle: float = 0.0

const GUN_METAL := Color(0.45, 0.45, 0.50)
const GUN_DARK := Color(0.30, 0.30, 0.35)
const WOOD := Color(0.55, 0.35, 0.20)
const BLADE := Color(0.75, 0.78, 0.82)
const ROCKET_BODY := Color(0.40, 0.50, 0.40)


func _ready() -> void:
	player = get_parent()
	z_index = 1  # draw on top of character


func _process(_delta: float) -> void:
	if not player:
		return

	# Get aim angle
	if player.has_node("InputManager"):
		var im: InputManager = player.get_node("InputManager")
		var center: Vector2 = player.global_position + Vector2(0, -20)
		var aim_vec: Vector2 = im.current_input.aim_position - center
		if aim_vec.length_squared() > 1.0:
			_aim_angle = aim_vec.angle()

	queue_redraw()


func _draw() -> void:
	if not player or player.is_dead:
		return

	if not player.has_node("WeaponManager"):
		return

	var wm: WeaponManager = player.get_node("WeaponManager")
	var weapon: WeaponDefinition = wm.get_current_weapon()
	if not weapon:
		return

	# Draw weapon at the shoulder position, pointing at aim angle
	var origin: Vector2 = Vector2(0, -24)  # shoulder height relative to player origin
	var dir: Vector2 = Vector2.from_angle(_aim_angle)
	var perp: Vector2 = dir.orthogonal()

	# Flip weapon visually when aiming left
	var flip: float = 1.0 if player.facing_right else -1.0

	match weapon.weapon_name:
		"Pistol":
			_draw_pistol(origin, dir, perp)
		"Shotgun":
			_draw_shotgun(origin, dir, perp)
		"SMG":
			_draw_smg(origin, dir, perp)
		"Sniper":
			_draw_sniper(origin, dir, perp)
		"Rocket Launcher":
			_draw_rocket_launcher(origin, dir, perp)
		"Knife":
			_draw_knife(origin, dir, perp)


func _draw_pistol(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	# Small handgun
	var barrel_start: Vector2 = origin + dir * 4
	var barrel_end: Vector2 = origin + dir * 12
	draw_line(barrel_start, barrel_end, GUN_METAL, 3.0)
	# Handle
	draw_line(origin + dir * 5, origin + dir * 5 + perp * 5, WOOD, 2.5)
	# Trigger guard
	draw_line(origin + dir * 6, origin + dir * 7 + perp * 3, GUN_DARK, 1.0)


func _draw_shotgun(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	# Double barrel
	var start: Vector2 = origin + dir * 3
	var end: Vector2 = origin + dir * 18
	draw_line(start + perp * 1, end + perp * 1, GUN_METAL, 2.5)
	draw_line(start - perp * 1, end - perp * 1, GUN_METAL, 2.5)
	# Stock
	draw_line(origin, origin - dir * 6, WOOD, 3.0)
	# Pump
	draw_line(start + dir * 5, start + dir * 8, GUN_DARK, 3.5)


func _draw_smg(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	# Compact body
	var start: Vector2 = origin + dir * 2
	var end: Vector2 = origin + dir * 14
	draw_line(start, end, GUN_METAL, 2.5)
	# Magazine
	draw_line(origin + dir * 7, origin + dir * 7 + perp * 6, GUN_DARK, 2.0)
	# Stock (short)
	draw_line(origin, origin - dir * 3, GUN_DARK, 2.5)
	# Grip
	draw_line(origin + dir * 4, origin + dir * 4 + perp * 4, WOOD, 2.0)


func _draw_sniper(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	# Long barrel
	var start: Vector2 = origin + dir * 3
	var end: Vector2 = origin + dir * 24
	draw_line(start, end, GUN_METAL, 2.0)
	# Scope
	draw_circle(origin + dir * 15, 2.5, GUN_DARK)
	draw_circle(origin + dir * 15, 1.5, Color(0.3, 0.5, 0.8, 0.6))
	# Stock
	draw_line(origin, origin - dir * 8, WOOD, 3.0)
	# Bipod hint
	draw_line(origin + dir * 6, origin + dir * 6 + perp * 4, GUN_DARK, 1.0)


func _draw_rocket_launcher(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	# Wide tube
	var start: Vector2 = origin + dir * 2
	var end: Vector2 = origin + dir * 20
	draw_line(start, end, ROCKET_BODY, 5.0)
	# Opening
	draw_circle(end, 3.5, GUN_DARK)
	draw_circle(end, 2.0, Color(0.2, 0.2, 0.2))
	# Grip
	draw_line(origin + dir * 8, origin + dir * 8 + perp * 5, WOOD, 2.0)
	# Sight
	draw_line(origin + dir * 12 - perp * 3, origin + dir * 14 - perp * 3, GUN_METAL, 1.5)


func _draw_knife(origin: Vector2, dir: Vector2, perp: Vector2) -> void:
	# Blade
	var blade_start: Vector2 = origin + dir * 3
	var blade_end: Vector2 = origin + dir * 14
	draw_line(blade_start, blade_end, BLADE, 2.0)
	# Blade edge (slight shine)
	draw_line(blade_start + perp * 0.5, blade_end + perp * 0.5, Color(0.9, 0.92, 0.95, 0.5), 1.0)
	# Handle
	draw_line(origin, origin + dir * 4, WOOD, 3.0)
	# Guard
	draw_line(origin + dir * 3 - perp * 2, origin + dir * 3 + perp * 2, GUN_DARK, 1.5)
