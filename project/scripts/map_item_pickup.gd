extends Node2D

signal collected(pickup: Node, item_id: String)

const BAG_TEXTURE_PATH := "res://assets/items/bag/bag.png"
const PROMPT_RADIUS := 180.0
const PROMPT_MARGIN_Y := 18.0

@export var item_id := "gourd"
@export var quantity := 1
@export var interaction_range := 72.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("map_item_pickup")
	if sprite != null:
		sprite.texture = load(BAG_TEXTURE_PATH) as Texture2D

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

func collect(player: Node) -> bool:
	if player == null or quantity <= 0:
		return false
	if player.has_method("add_item"):
		player.add_item(item_id, quantity)
	elif "item_counts" in player:
		var counts: Dictionary = player.get("item_counts")
		counts[item_id] = int(counts.get(item_id, 0)) + quantity
		player.set("item_counts", counts)
		if player.has_signal("stats_changed"):
			player.emit_signal("stats_changed")
	else:
		return false
	visible = false
	collected.emit(self, item_id)
	queue_free()
	return true

func _interaction_rect() -> Rect2:
	return Rect2(global_position - Vector2.ONE * interaction_range, Vector2.ONE * interaction_range * 2.0)
