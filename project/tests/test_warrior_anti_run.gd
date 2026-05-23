extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	if player_scene == null or warrior_scene == null:
		push_error("Player and Warrior scenes should load")
		quit(1)
		return

	var player: Node2D = player_scene.instantiate()
	var warrior: Node2D = warrior_scene.instantiate()
	get_root().add_child(player)
	get_root().add_child(warrior)
	await process_frame

	warrior.global_position = Vector2(200.0, 360.0)
	player.global_position = Vector2(284.0, 360.0)
	warrior.receive_alert()
	warrior.target = player
	warrior.attack_cooldown = 0.0
	warrior._update_combat_movement()
	if warrior.current_attack_animation != "attack":
		push_error("Warrior should start with normal attack inside sword range")
		quit(1)
		return

	player.global_position = Vector2(350.0, 360.0)
	warrior._update_attack(0.18)
	if warrior.current_attack_animation != "thrust":
		push_error("Warrior should convert attack windup into thrust when the player runs out of sword range")
		quit(1)
		return
	if warrior.velocity.x <= 0.0:
		push_error("Converted thrust should step forward to punish running away during windup")
		quit(1)
		return

	warrior.attack_has_connected = false
	player.global_position = Vector2(520.0, 360.0)
	warrior.attack_area = null
	warrior._update_attack(warrior.current_attack_total_time + 0.01)
	if warrior.attack_cooldown > warrior.attack_cooldown_duration * 0.55:
		push_error("Warrior whiff caused by running away should have shortened recovery instead of full cooldown: %.3f" % warrior.attack_cooldown)
		quit(1)
		return

	warrior.reset_combat_state()
	warrior.global_position = Vector2(200.0, 360.0)
	player.global_position = Vector2(390.0, 360.0)
	warrior.receive_alert()
	warrior.target = player
	warrior.attack_cooldown = 0.0
	warrior.pressure_timer = warrior.pressure_duration
	warrior._update_combat_movement()
	if warrior.current_attack_animation != "thrust":
		push_error("Warrior pressure should extend thrust threat range against hit-and-run players")
		quit(1)
		return

	warrior.reset_combat_state()
	warrior.health = warrior.max_health
	warrior.posture = 40.0
	warrior.posture_recovery_pause_timer = 0.0
	warrior._update_pressure_and_posture(1.0)
	if warrior.posture >= 40.0:
		push_error("Warrior posture should recover when the player stops maintaining pressure")
		quit(1)
		return

	warrior.queue_free()
	player.queue_free()
	await process_frame
	quit(0)
