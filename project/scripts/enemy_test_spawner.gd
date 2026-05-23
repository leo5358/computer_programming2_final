extends Node2D

const TORCHMAN_SCENE: PackedScene = preload("res://scenes/TorchmanEnemy.tscn")
const WARRIOR_SCENE: PackedScene = preload("res://scenes/WarriorEnemy.tscn")
const ARCHER_SCENE: PackedScene = preload("res://scenes/ArcherEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/Boss.tscn")

var spawn_offsets: Dictionary = {
	KEY_7: Vector2(360, 360),
	KEY_8: Vector2(460, 360),
	KEY_9: Vector2(620, 360),
	KEY_0: Vector2(820, 360),
}

func _ready() -> void:
	add_to_group("enemy_test_spawner")

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	match event.keycode:
		KEY_7:
			_spawn_enemy(TORCHMAN_SCENE, spawn_offsets[KEY_7])
			get_viewport().set_input_as_handled()
		KEY_8:
			_spawn_enemy(WARRIOR_SCENE, spawn_offsets[KEY_8])
			get_viewport().set_input_as_handled()
		KEY_9:
			_spawn_enemy(ARCHER_SCENE, spawn_offsets[KEY_9])
			get_viewport().set_input_as_handled()
		KEY_0:
			_spawn_enemy(BOSS_SCENE, spawn_offsets[KEY_0])
			get_viewport().set_input_as_handled()
		KEY_R:
			reset_test_field()
			get_viewport().set_input_as_handled()

func reset_test_field() -> void:
	clear_test_enemies()
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("reset_combat_state"):
		player.reset_combat_state()

func clear_test_enemies() -> void:
	for group_name in ["minor_enemy", "boss"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node != null and node != self:
				node.queue_free()

func _spawn_enemy(scene: PackedScene, spawn_position: Vector2) -> void:
	var instance: Node = scene.instantiate()
	add_child(instance)
	if instance is Node2D:
		instance.global_position = spawn_position
		if "spawn_position" in instance:
			instance.spawn_position = spawn_position
