extends Node

const CombatServerScript = preload("res://scripts/combat_server.gd")

var combat: RefCounted = CombatServerScript.new()
var attack_id_counter := 0

func _ready() -> void:
	add_to_group("combat_runtime")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("force_bpm"):
		force_bpm(200.0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reset_combat"):
		reset_combat()
		get_viewport().set_input_as_handled()

func register_input(input_type: int, timestamp_ms: int) -> void:
	combat.register_input(input_type, timestamp_ms)

func notify_attack_active(attack_type: int, timestamp_ms: int) -> int:
	attack_id_counter += 1
	combat.notify_attack_active(attack_id_counter, attack_type, timestamp_ms)
	return attack_id_counter

func force_bpm(value: float) -> void:
	combat.force_bpm(value)
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		player.heartbeat = value

func reset_combat() -> void:
	attack_id_counter = 0
	combat.reset_combat()
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("reset_combat_state"):
		player.reset_combat_state()
	for spawner in get_tree().get_nodes_in_group("enemy_test_spawner"):
		if spawner.has_method("clear_test_enemies"):
			spawner.clear_test_enemies()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("reset_combat_state"):
			enemy.reset_combat_state()
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss.has_method("reset_combat_state"):
			boss.reset_combat_state()

func get_combat_update(delta: float = 0.0) -> Dictionary:
	var update: Dictionary = combat.get_combat_update(delta)
	_sync_live_entities(update)
	return update

func _sync_live_entities(update: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		update["player_hp"] = player.health
		update["player_posture"] = player.posture
		update["player_bpm"] = player.heartbeat
		update["player_state"] = player.state

	var boss = get_tree().get_first_node_in_group("boss")
	if boss != null:
		update["boss_hp"] = boss.health
		update["boss_posture"] = boss.posture
		update["boss_state"] = 6 if boss.defeated_flag else 0
