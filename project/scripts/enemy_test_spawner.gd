extends Node2D

const TORCHMAN_SCENE: PackedScene = preload("res://scenes/TorchmanEnemy.tscn")
const WARRIOR_SCENE: PackedScene = preload("res://scenes/WarriorEnemy.tscn")
const ARCHER_SCENE: PackedScene = preload("res://scenes/ArcherEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/Boss.tscn")
const H_STONE_PLAZA_SCENE: PackedScene = preload("res://scenes/maps/chapter1_h_stone_plaza.tscn")
const BOSS_INTERIOR_SCENE: PackedScene = preload("res://scenes/maps/chapter1_boss_interior_blockout.tscn")
const AB_EXIT_START_X := 15250.0
const AB_EXIT_END_X := 15750.0
const H_STONE_PLAZA_EXIT_START_X := 2700.0
const H_STONE_PLAZA_EXIT_END_X := 3200.0
const H_STONE_PLAZA_SPAWN := Vector2(220, 408)
const BOSS_INTERIOR_SPAWN := Vector2(220, 595)
const TRANSITION_FADE_TIME := 0.45

var spawn_offsets: Dictionary = {
	KEY_7: Vector2(360, 360),
	KEY_8: Vector2(460, 360),
	KEY_9: Vector2(620, 360),
	KEY_0: Vector2(820, 360),
}
var current_map_id := "ab_foothill"
var is_transitioning := false

@onready var interaction_prompt: Label = $MapTransitionUI/PromptLabel
@onready var fade_rect: ColorRect = $MapTransitionUI/FadeRect

func _ready() -> void:
	add_to_group("enemy_test_spawner")
	interaction_prompt.visible = false
	fade_rect.visible = false
	fade_rect.color = Color(0, 0, 0, 0)
	if _should_spawn_default_boss_for_current_run():
		_spawn_enemy(BOSS_SCENE, spawn_offsets[KEY_0])

func _process(_delta: float) -> void:
	_update_map_interaction_prompt()

func _should_spawn_default_boss_for_current_run() -> bool:
	for argument in OS.get_cmdline_args():
		if argument.ends_with("test_boss_attack.gd") or argument.ends_with("test_boss_runtime.gd") or argument.ends_with("test_combat_runtime.gd") or argument.ends_with("test_hurtbox_debug_overlay.gd"):
			return true
	return false

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
		KEY_F:
			if _can_use_ab_exit():
				_transition_ab_to_h_stone_plaza()
				get_viewport().set_input_as_handled()
			elif _can_use_h_stone_plaza_exit():
				_transition_h_stone_plaza_to_boss_interior()
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

func _update_map_interaction_prompt() -> void:
	interaction_prompt.visible = _can_use_ab_exit() or _can_use_h_stone_plaza_exit()

func _can_use_ab_exit() -> bool:
	if is_transitioning or current_map_id != "ab_foothill":
		return false

	var player: Node2D = _get_player()
	if player == null:
		return false

	return player.global_position.x >= AB_EXIT_START_X and player.global_position.x <= AB_EXIT_END_X

func _can_use_h_stone_plaza_exit() -> bool:
	if is_transitioning or current_map_id != "h_stone_plaza":
		return false

	var player: Node2D = _get_player()
	if player == null:
		return false

	return player.global_position.x >= H_STONE_PLAZA_EXIT_START_X and player.global_position.x <= H_STONE_PLAZA_EXIT_END_X

func _transition_ab_to_h_stone_plaza() -> void:
	await _run_map_transition(H_STONE_PLAZA_SCENE, "h_stone_plaza", H_STONE_PLAZA_SPAWN)

func _transition_h_stone_plaza_to_boss_interior() -> void:
	await _run_map_transition(BOSS_INTERIOR_SCENE, "boss_interior", BOSS_INTERIOR_SPAWN)

func _run_map_transition(next_scene: PackedScene, next_map_id: String, player_spawn: Vector2) -> void:
	is_transitioning = true
	interaction_prompt.visible = false
	_set_player_transition_locked(true)
	await _fade_to(1.0)
	_switch_map(next_scene, next_map_id, player_spawn)
	await get_tree().process_frame
	await _fade_to(0.0)
	_set_player_transition_locked(false)
	is_transitioning = false

func _fade_to(alpha: float) -> void:
	fade_rect.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", alpha, TRANSITION_FADE_TIME)
	await tween.finished
	if alpha <= 0.0:
		fade_rect.visible = false

func _switch_map(next_scene: PackedScene, next_map_id: String, player_spawn: Vector2) -> void:
	var old_map: Node = get_node_or_null("Chapter1Map")
	if old_map != null:
		remove_child(old_map)
		old_map.queue_free()

	var player: Node2D = _get_player()
	var new_map: Node = next_scene.instantiate()
	add_child(new_map)
	new_map.name = "Chapter1Map"
	if player != null:
		move_child(new_map, player.get_index())
		player.global_position = player_spawn
		if "spawn_position" in player:
			player.spawn_position = player_spawn
	current_map_id = next_map_id

func _set_player_transition_locked(is_locked: bool) -> void:
	var player: Node2D = _get_player()
	if player == null:
		return

	player.set_physics_process(not is_locked)
	if player is CharacterBody2D:
		var character: CharacterBody2D = player as CharacterBody2D
		character.velocity = Vector2.ZERO

func _get_player() -> Node2D:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return player as Node2D
	return null
