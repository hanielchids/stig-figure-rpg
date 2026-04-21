## Map 1: Arena — Multi-level combat arena.
## Clean ColorRect visuals matching the stick-figure aesthetic.
## Includes collision, kill zone, spawns, and navigation mesh.
extends Node2D

const MAP_W: float = 1600.0
const MAP_H: float = 900.0

# Colors — dark industrial theme
const C_BG := Color(0.10, 0.11, 0.15)
const C_FLOOR := Color(0.28, 0.32, 0.38)
const C_WALL := Color(0.24, 0.28, 0.34)
const C_CEIL := Color(0.22, 0.25, 0.30)
const C_PLAT1 := Color(0.34, 0.38, 0.44)
const C_PLAT2 := Color(0.32, 0.36, 0.42)
const C_PLAT3 := Color(0.30, 0.34, 0.40)
const C_PLAT4 := Color(0.28, 0.32, 0.38)
const C_PILLAR := Color(0.26, 0.30, 0.36)

var _platform_data: Array = []


func _ready() -> void:
	_build_background()
	_build_walls()
	_build_platforms()
	_build_kill_zone()
	_build_spawn_points()
	_build_navigation()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(MAP_W, MAP_H)
	bg.color = C_BG
	bg.z_index = -10
	add_child(bg)


func _build_walls() -> void:
	_add_rect(Vector2(MAP_W / 2, MAP_H - 16), Vector2(MAP_W, 32), C_FLOOR)     # floor
	_add_rect(Vector2(16, MAP_H / 2), Vector2(32, MAP_H), C_WALL)               # left wall
	_add_rect(Vector2(MAP_W - 16, MAP_H / 2), Vector2(32, MAP_H), C_WALL)       # right wall
	_add_rect(Vector2(MAP_W / 2, 16), Vector2(MAP_W, 32), C_CEIL)               # ceiling


func _build_platforms() -> void:
	# Ground level small platforms
	_add_platform(Vector2(400, 788), Vector2(120, 16), C_PLAT1)
	_add_platform(Vector2(1200, 788), Vector2(120, 16), C_PLAT1)

	# Mid-level platforms
	_add_platform(Vector2(250, 618), Vector2(180, 16), C_PLAT2)
	_add_platform(Vector2(800, 588), Vector2(200, 16), C_PLAT2)
	_add_platform(Vector2(1350, 618), Vector2(180, 16), C_PLAT2)

	# High platforms
	_add_platform(Vector2(500, 418), Vector2(160, 16), C_PLAT3)
	_add_platform(Vector2(1100, 418), Vector2(160, 16), C_PLAT3)

	# Top center platform
	_add_platform(Vector2(800, 268), Vector2(140, 16), C_PLAT4)

	# Cover pillars
	_add_platform(Vector2(600, 728), Vector2(16, 100), C_PILLAR)
	_add_platform(Vector2(1000, 728), Vector2(16, 100), C_PILLAR)


func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = Constants.LAYER_WORLD

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	visual.color = color
	body.add_child(visual)

	add_child(body)


func _add_platform(pos: Vector2, size: Vector2, color: Color) -> void:
	_platform_data.append([pos, size])
	_add_rect(pos, size, color)


func _build_kill_zone() -> void:
	var area := Area2D.new()
	area.position = Vector2(MAP_W / 2, MAP_H + 50)
	area.collision_layer = Constants.LAYER_KILLZONE
	area.collision_mask = Constants.LAYER_PLAYERS
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(MAP_W, 60)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(_on_kill_zone_entered)
	add_child(area)


func _on_kill_zone_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_node("HealthSystem"):
		var health: HealthSystem = body.get_node("HealthSystem")
		health.take_damage(9999.0, -1, "Fell")


func _build_spawn_points() -> void:
	var positions: Array[Vector2] = [
		Vector2(200, 820), Vector2(1400, 820),
		Vector2(500, 820), Vector2(1100, 820),
		Vector2(300, 820), Vector2(700, 820),
		Vector2(900, 820), Vector2(1200, 820),
	]
	for i in positions.size():
		var marker := Marker2D.new()
		marker.name = "PlayerSpawn%d" % i
		marker.position = positions[i]
		add_child(marker)


func _build_navigation() -> void:
	var nav_region := NavigationRegion2D.new()
	add_child(nav_region)

	var nav_poly := NavigationPolygon.new()

	var margin: float = 40.0
	var outline := PackedVector2Array([
		Vector2(margin, margin),
		Vector2(MAP_W - margin, margin),
		Vector2(MAP_W - margin, MAP_H - margin),
		Vector2(margin, MAP_H - margin),
	])
	nav_poly.add_outline(outline)

	for plat in _platform_data:
		var center: Vector2 = plat[0]
		var size: Vector2 = plat[1]
		var half: Vector2 = size / 2.0
		var hole := PackedVector2Array([
			center + Vector2(-half.x, -half.y),
			center + Vector2(-half.x, half.y),
			center + Vector2(half.x, half.y),
			center + Vector2(half.x, -half.y),
		])
		nav_poly.add_outline(hole)

	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly


