extends SceneTree

func _initialize() -> void:
	var autopilot_script: Script = load("res://scripts/combat_autopilot.gd")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	if autopilot_script == null or player_scene == null or boss_scene == null or warrior_scene == null:
		push_error("Autopilot, Player, Boss, and Warrior should load")
		quit(1)
		return

	var main := Node2D.new()
	get_root().add_child(main)
	var autopilot: Node = autopilot_script.new()
	main.add_child(autopilot)
	var player = player_scene.instantiate()
	var boss = boss_scene.instantiate()
	var warrior = warrior_scene.instantiate()
	main.add_child(player)
	main.add_child(boss)
	main.add_child(warrior)
	await process_frame

	if not autopilot.has_method("toggle"):
		push_error("Autopilot should expose a toggle method")
		quit(1)
		return
	if bool(autopilot.get("enabled")):
		push_error("Autopilot should default to off")
		quit(1)
		return
	autopilot.toggle()
	if not bool(autopilot.get("enabled")):
		push_error("Autopilot toggle should enable computer control")
		quit(1)
		return

	player.global_position = Vector2(300.0, 360.0)
	boss.global_position = Vector2(360.0, 360.0)
	boss.spawn_position = boss.global_position
	boss.facing = -1.0
	boss._start_normal_attack("attack")
	boss.attack_elapsed = boss.attack_parry_window_start + 0.02
	autopilot._physics_process(0.016)
	if player.state == player.PlayerState.PARRY:
		push_error("Autopilot should not directly enter parry before the timing window")
		quit(1)
		return
	boss.attack_elapsed = boss.attack_hit_time - 0.05
	autopilot._physics_process(0.016)
	if not player.has_method("has_pending_ai_parry") or not player.has_pending_ai_parry():
		push_error("Autopilot should request parry through Player AI intent")
		quit(1)
		return
	player._update_inputs()
	if player.state != player.PlayerState.PARRY:
		push_error("Autopilot should parry normal attacks during the perfect window")
		quit(1)
		return
	player.parry_elapsed = 0.05
	var boss_posture_before: float = boss.posture
	boss._connect_normal_attack()
	if boss.posture <= boss_posture_before:
		push_error("Autopilot parry timing should produce a perfect parry, not a block")
		quit(1)
		return

	player.reset_combat_state()
	boss.reset_combat_state()
	player.global_position = Vector2(300.0, 360.0)
	boss.global_position = Vector2(420.0, 360.0)
	boss.spawn_position = boss.global_position
	boss.facing = -1.0
	boss._start_normal_attack("thrust")
	boss.attack_elapsed = boss.attack_parry_window_start + 0.02
	autopilot._physics_process(0.016)
	if player.state == player.PlayerState.DASH:
		push_error("Autopilot should not directly dash before the timing window")
		quit(1)
		return
	boss.attack_elapsed = boss.attack_hit_time - 0.04
	autopilot._physics_process(0.016)
	if not player.has_method("has_pending_ai_dodge") or not player.has_pending_ai_dodge():
		push_error("Autopilot should request dodge through Player AI intent")
		quit(1)
		return
	player._update_inputs()
	if player.state != player.PlayerState.DASH or not player.is_perfect_dodging:
		push_error("Autopilot should perfect-dodge perilous thrust attacks")
		quit(1)
		return
	var health_before_thrust: float = player.health
	player.receive_enemy_attack(24.0, 36.0, boss, boss.current_attack_type)
	if player.health < health_before_thrust:
		push_error("Autopilot perfect dodge should keep the player invulnerable through the thrust hit")
		quit(1)
		return

	player.reset_combat_state()
	boss.reset_combat_state()
	warrior.reset_combat_state()
	player.global_position = Vector2(300.0, 360.0)
	warrior.global_position = Vector2(348.0, 360.0)
	warrior.spawn_position = warrior.global_position
	warrior.posture_broken = true
	var defeated_before: bool = warrior.defeated_flag
	autopilot._physics_process(0.016)
	if not player.has_method("has_pending_ai_attack") or not player.has_pending_ai_attack():
		push_error("Autopilot should request execute attack through Player AI intent")
		quit(1)
		return
	player._update_inputs()
	if defeated_before == warrior.defeated_flag:
		push_error("Autopilot should attack executable enemies to trigger execute")
		quit(1)
		return

	player.reset_combat_state()
	warrior.queue_free()
	boss.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = Vector2(280.0, 360.0)
	player.velocity = Vector2.ZERO
	autopilot._physics_process(0.016)
	if not player.has_method("get_ai_move_axis") or player.get_ai_move_axis() <= 0.0:
		push_error("Autopilot should request movement through Player AI intent when no defense is needed")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
