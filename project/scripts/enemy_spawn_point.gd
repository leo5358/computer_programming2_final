extends Node2D

const TORCHMAN_SCENE: PackedScene = preload("res://scenes/TorchmanEnemy.tscn")
const WARRIOR_SCENE: PackedScene = preload("res://scenes/WarriorEnemy.tscn")
const ARCHER_SCENE: PackedScene = preload("res://scenes/ArcherEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/Boss.tscn")

@export_enum("torchman", "warrior", "archer", "boss") var enemy_type := "warrior"
@export var spawn_on_ready := true
@export var disabled := false
@export var facing := -1.0
@export var patrol_distance_override := -1.0
@export var spawn_group_id := ""

var active_enemy: Node

func _ready() -> void:
	add_to_group("enemy_spawn_point")
	if spawn_on_ready and not disabled:
		call_deferred("respawn_enemy")

func respawn_enemy() -> Node:
	if disabled:
		return null
	if is_instance_valid(active_enemy) and not active_enemy.is_queued_for_deletion():
		return active_enemy

	var scene := _scene_for_type(enemy_type)
	if scene == null:
		return null

	active_enemy = scene.instantiate()
	var parent := get_parent()
	if parent == null:
		parent = self
	parent.add_child(active_enemy)
	active_enemy.add_to_group("map_spawned_enemy")
	if active_enemy is Node2D:
		(active_enemy as Node2D).global_position = global_position
	_apply_spawn_settings(active_enemy)
	return active_enemy

func despawn_enemy() -> void:
	if is_instance_valid(active_enemy):
		active_enemy.queue_free()
	active_enemy = null

func _scene_for_type(type_name: String) -> PackedScene:
	match type_name:
		"torchman":
			return TORCHMAN_SCENE
		"warrior":
			return WARRIOR_SCENE
		"archer":
			return ARCHER_SCENE
		"boss":
			return BOSS_SCENE
		_:
			push_warning("Unknown enemy spawn type: %s" % type_name)
			return null

func _apply_spawn_settings(enemy: Node) -> void:
	var spawn_facing := -1.0 if facing < 0.0 else 1.0
	if "spawn_position" in enemy:
		enemy.set("spawn_position", global_position)
	if "facing" in enemy:
		enemy.set("facing", spawn_facing)
	if "patrol_direction" in enemy:
		enemy.set("patrol_direction", spawn_facing)
	if patrol_distance_override >= 0.0 and "patrol_distance" in enemy:
		enemy.set("patrol_distance", patrol_distance_override)
	if spawn_group_id != "":
		enemy.set_meta("spawn_group_id", spawn_group_id)
	if enemy.has_method("_sync_directional_nodes"):
		enemy.call("_sync_directional_nodes")
