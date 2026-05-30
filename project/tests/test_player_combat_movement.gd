extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")

func _initialize() -> void:
	var arena := Node2D.new()
	get_root().add_child(arena)

	var player: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	arena.add_child(player)
	await process_frame
	player.global_position = Vector2(300, 360)
	if "spawn_position" in player:
		player.spawn_position = player.global_position
	if player.has_method("reset_combat_state"):
		player.reset_combat_state()

	if not player.has_method("set_ai_move_axis"):
		push_error("Player should expose AI movement intent for combat movement tests")
		quit(1)
		return

	player.set_ai_move_axis(-1.0)
	player._update_movement(0.10)
	if player.facing >= 0.0:
		push_error("Without nearby enemies, moving left should turn player left")
		quit(1)
		return
	var normal_retreat_speed: float = abs(player.velocity.x)

	player.clear_ai_intent()
	player.velocity = Vector2.ZERO
	player.facing = 1.0
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	arena.add_child(enemy)
	enemy.global_position = Vector2(410, 360)
	player.set_ai_move_axis(-1.0)
	player._update_movement(0.10)

	if player.facing <= 0.0:
		push_error("Combat retreat should keep player facing the nearby enemy")
		quit(1)
		return
	if player.velocity.x >= 0.0:
		push_error("Combat retreat should still move away from the enemy")
		quit(1)
		return
	if abs(player.velocity.x) >= normal_retreat_speed:
		push_error("Combat retreat should be slower than normal movement")
		quit(1)
		return

	player.clear_ai_intent()
	player.velocity = Vector2.ZERO
	player.set_ai_move_axis(1.0)
	player._update_movement(0.10)
	if player.facing <= 0.0 or player.velocity.x <= 0.0:
		push_error("Combat forward movement should face and move toward the nearby enemy")
		quit(1)
		return

	arena.queue_free()
	await process_frame
	quit(0)
