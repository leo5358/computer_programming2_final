extends Node2D

signal activated_changed(checkpoint: Node)

const ENABLED_TEXTURE_PATH := "res://assets/items/checkpoint/checkpoint.png"
const DISABLED_TEXTURE_PATH := "res://assets/items/checkpoint/checkpoint_unable.png"

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
	var offset := player.global_position - global_position
	return abs(offset.x) <= interaction_range and abs(offset.y) <= interaction_range

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
