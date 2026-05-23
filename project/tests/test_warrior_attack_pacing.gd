extends SceneTree

func _initialize() -> void:
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if warrior_scene == null or player_scene == null:
		push_error("Warrior and Player scenes should load")
		quit(1)
		return

	var warrior: Node2D = warrior_scene.instantiate()
	var player: Node2D = player_scene.instantiate()
	get_root().add_child(warrior)
	get_root().add_child(player)
	await process_frame

	warrior.global_position = Vector2(200.0, 360.0)
	player.global_position = Vector2(280.0, 360.0)
	warrior.receive_alert()
	warrior.target = player
	warrior.attack_cooldown = 0.0
	warrior._update_combat_movement()
	if warrior.state != warrior.EnemyState.ATTACK:
		push_error("Warrior should be able to start its first attack in range")
		quit(1)
		return

	warrior._update_attack(warrior.attack_total_time + 0.01)
	if warrior.attack_cooldown < 1.45:
		push_error("Warrior should pause after an attack instead of immediately chaining another swing")
		quit(1)
		return

	warrior._update_movement_state(0.75)
	if warrior.state == warrior.EnemyState.ATTACK:
		push_error("Warrior should not restart attack during post-attack breathing room")
		quit(1)
		return

	warrior.attack_cooldown = 0.0
	warrior._update_movement_state(0.0)
	if warrior.state != warrior.EnemyState.ATTACK:
		push_error("Warrior should attack again after cooldown expires if player stays in range")
		quit(1)
		return

	warrior.reset_combat_state()
	warrior.global_position = Vector2(200.0, 360.0)
	player.global_position = Vector2(280.0, 360.0)
	warrior.receive_alert()
	warrior.target = player
	warrior.guard_chance = 1.0
	warrior.receive_player_attack(20.0, 18.0)
	if not warrior.counter_after_deflect:
		push_error("Warrior deflect should claim counter priority instead of returning to passive hold")
		quit(1)
		return
	warrior._update_deflect(warrior.deflect_duration + 0.01)
	if warrior.state != warrior.EnemyState.ATTACK:
		push_error("Warrior deflect should flow into a counter attack when the player stays in range")
		quit(1)
		return
	if warrior.current_attack_profile != "counter":
		push_error("Warrior deflect should use a fast counter profile instead of the normal slow attack")
		quit(1)
		return
	if warrior.deflect_duration + warrior.current_attack_hit_start >= player.attack_deflected_attack_lockout_time:
		push_error("Warrior counter should become active before the player's post-deflect attack lockout ends")
		quit(1)
		return
	if warrior.attack_elapsed > 0.01:
		push_error("Warrior counter attack should start from the first attack frame")
		quit(1)
		return

	warrior.reset_combat_state()
	warrior.receive_alert()
	warrior.target = player
	warrior._start_attack()
	var posture_before_parry: float = warrior.posture
	warrior.receive_block_feedback(true)
	if warrior.attack_cooldown < 1.4:
		push_error("Warrior should recover after being perfect-parried instead of immediately chaining another attack")
		quit(1)
		return
	if warrior.posture - posture_before_parry > 24.0:
		push_error("Warrior perfect-parry posture damage should not allow three parries to instantly execute a standard enemy")
		quit(1)
		return

	warrior.queue_free()
	player.queue_free()
	await process_frame
	quit(0)
