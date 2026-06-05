extends Node2D

signal activated_changed(checkpoint: Node)

const ENABLED_TEXTURE_PATH := "res://assets/items/checkpoint/checkpoint.png"
const DISABLED_TEXTURE_PATH := "res://assets/items/checkpoint/checkpoint_unable.png"
const PROMPT_RADIUS := 300.0
const PROMPT_MARGIN_Y := 18.0

@export var interaction_range := 96.0
@export var respawn_position := Vector2.INF

var activated := false
var enabled_texture: Texture2D
var disabled_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("checkpoint")
	enabled_texture = load(ENABLED_TEXTURE_PATH) as Texture2D
	disabled_texture = load(DISABLED_TEXTURE_PATH) as Texture2D
	_update_visual()

func is_player_in_range(player: Node2D) -> bool:
	if player == null:
		return false
	return _interaction_rect().has_point(player.global_position)

func is_player_in_prompt_range(player: Node2D) -> bool:
	if player == null:
		return false
	return player.global_position.distance_to(global_position) <= PROMPT_RADIUS

func get_prompt_anchor_position() -> Vector2:
	var rect := _interaction_rect()
	return Vector2(rect.get_center().x, rect.position.y - PROMPT_MARGIN_Y)

func get_rest_position() -> Vector2:
	return _resolved_respawn_position()

func activate(player: Node = null) -> bool:
	activated = true
	_update_visual()
	if player != null and "spawn_position" in player:
		player.spawn_position = _resolved_respawn_position()
	activated_changed.emit(self)
	return true

func deactivate() -> void:
	activated = false
	_update_visual()
	activated_changed.emit(self)

func _resolved_respawn_position() -> Vector2:
	if respawn_position != Vector2.INF:
		return respawn_position
	return global_position

func _update_visual() -> void:
	if sprite == null:
		return
	sprite.texture = enabled_texture if activated else disabled_texture

func _interaction_rect() -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2(global_position - Vector2.ONE * interaction_range, Vector2.ONE * interaction_range * 2.0)
	var sprite_size := sprite.texture.get_size() * sprite.scale.abs()
	var top_left := global_position + sprite.position - sprite_size * 0.5
	return Rect2(top_left, sprite_size)
