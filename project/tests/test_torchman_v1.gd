extends SceneTree

func _initialize() -> void:
	var torchman_scene: PackedScene = load("res://scenes/TorchmanEnemy.tscn")
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if torchman_scene == null or warrior_scene == null or player_scene == null:
		push_error("Torchman, Warrior, and Player scenes should load")
		quit(1)
		return

	var torchman: Node2D = torchman_scene.instantiate()
	var warrior: Node2D = warrior_scene.instantiate()
	var player: Node2D = player_scene.instantiate()
	get_root().add_child(torchman)
	get_root().add_child(warrior)
	get_root().add_child(player)
	await process_frame

	torchman.global_position = Vector2(300.0, 360.0)
	warrior.global_position = Vector2(430.0, 360.0)
	player.global_position = Vector2(190.0, 360.0)
	torchman.receive_alert()
	torchman.target = player
	torchman.attack_cooldown = 0.0
	torchman._update_combat_movement()
	if torchman.state != torchman.EnemyState.FLEE or torchman.velocity.x <= 0.0:
		push_error("Torchman should flee away from player before fighting")
		quit(1)
		return
	if not torchman.has_called_allies or not warrior.is_alerted:
		push_error("Torchman should call nearby Warrior/Archer allies when fleeing")
		quit(1)
		return
	torchman._update_combat_movement()
	if torchman.state != torchman.EnemyState.FLEE or torchman.velocity.x <= 0.0:
		push_error("Torchman should keep fleeing until it has opened enough distance")
		quit(1)
		return

	player.global_position = Vector2(222.0, 360.0)
	torchman.attack_cooldown = 0.0
	torchman._update_combat_movement()
	if torchman.state != torchman.EnemyState.ATTACK:
		push_error("Torchman should stop fleeing and attack when the player reaches sword range")
		quit(1)
		return

	warrior.queue_free()
	await process_frame
	torchman.reset_combat_state()
	torchman.global_position = Vector2(300.0, 360.0)
	player.global_position = Vector2(222.0, 360.0)
	torchman.receive_alert()
	torchman.target = player
	torchman.attack_cooldown = 0.0
	torchman._update_combat_movement()
	if torchman.state != torchman.EnemyState.ATTACK:
		push_error("Lone Torchman should attack once the player is in sword range")
		quit(1)
		return

	torchman.reset_combat_state()
	torchman.global_position = Vector2(300.0, 360.0)
	player.global_position = Vector2(170.0, 360.0)
	torchman.receive_alert()
	torchman.target = player
	torchman.attack_cooldown = 0.0
	torchman._update_combat_movement()
	if torchman.state != torchman.EnemyState.CHASE:
		push_error("Lone Torchman should close distance before sword range")
		quit(1)
		return
	player.global_position = Vector2(222.0, 360.0)
	torchman.attack_cooldown = 0.0
	torchman._update_combat_movement()
	if torchman.state != torchman.EnemyState.ATTACK:
		push_error("Lone Torchman should attack after closing into sword range")
		quit(1)
		return

	torchman.queue_free()
	player.queue_free()
	await process_frame
	quit(0)
