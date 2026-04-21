## Quick muzzle flash effect — spawns at fire point, fades out.
class_name MuzzleFlash
extends Node2D

var _lifetime: float = 0.06
var _timer: float = 0.0
var _size: float = 8.0


static func spawn(scene_root: Node, pos: Vector2, size: float = 8.0) -> void:
	var flash := MuzzleFlash.new()
	flash.global_position = pos
	flash._size = size
	scene_root.add_child(flash)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var alpha: float = 1.0 - (_timer / _lifetime)
	var s: float = _size * (1.0 + _timer / _lifetime * 0.5)
	draw_circle(Vector2.ZERO, s, Color(1.0, 0.9, 0.3, alpha))
	draw_circle(Vector2.ZERO, s * 0.5, Color(1.0, 1.0, 0.8, alpha))
