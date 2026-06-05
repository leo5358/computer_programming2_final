extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const WARRIOR_SCENE: PackedScene = preload("res://scenes/WarriorEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/Boss.tscn")

func _initialize() -> void:
	var root := Node2D.new()
	root.name = "PostureDisengageDecayTest"
	get_root().add_child(root)

	var player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	player.reset_combat_state()
	player.health = player.max_health * 0.8
	player.posture = 80.0
	player.register_posture_contact()
	player._update_posture_decay(5.0)
	if absf(player.posture - 80.0) > 0.01:
		push_error("Player posture should not decay before the 6 second disengage window expires")
		quit(1)
		return
	if not player.is_posture_bar_visible():
		push_error("Player posture bar should stay visible while the player is still in combat")
		quit(1)
		return
	player._update_posture_decay(1.1)
	if absf(player.posture - 79.36) > 0.05:
		push_error("Player posture should decay at 8% max posture per second scaled by current health after disengaging")
		quit(1)
		return
	if not player.is_posture_bar_visible():
		push_error("Player posture bar should stay visible while posture is naturally decaying")
		quit(1)
		return
	player.register_posture_contact()
	player._update_posture_decay(1.0)
	if absf(player.posture - 79.36) > 0.05:
		push_error("Player posture recovery should pause immediately if combat resumes during recovery")
		quit(1)
		return
	player.posture = 0.0
	player._update_posture_decay(0.1)
	if player.is_posture_bar_visible():
		push_error("Player posture bar should hide once posture is stable at zero and combat has ended")
		quit(1)
		return

	var enemy = WARRIOR_SCENE.instantiate()
	root.add_child(enemy)
	await process_frame
	enemy.reset_combat_state()
	enemy.health = enemy.max_health * 0.8
	enemy.posture = 80.0
	enemy._mark_combat_pressure()
	enemy._update_pressure_and_posture(5.0)
	if absf(enemy.posture - 80.0) > 0.01:
		push_error("Minor enemy posture should not decay before the 6 second disengage timer expires")
		quit(1)
		return
	if not enemy.is_posture_bar_visible():
		push_error("Minor enemy posture bar should stay visible while still in combat")
		quit(1)
		return
	enemy._update_pressure_and_posture(1.1)
	if absf(enemy.posture - 79.6) > 0.05:
		push_error("Minor enemy posture should decay at 5% max posture per second scaled by current health after disengaging")
		quit(1)
		return
	enemy._mark_combat_pressure()
	enemy._update_pressure_and_posture(1.0)
	if absf(enemy.posture - 79.6) > 0.05:
		push_error("Minor enemy posture recovery should pause immediately if combat resumes during recovery")
		quit(1)
		return

	var boss = BOSS_SCENE.instantiate()
	root.add_child(boss)
	await process_frame
	boss.reset_combat_state()
	boss.health = boss.max_health * 0.8
	boss.posture = 80.0
	boss._mark_combat_pressure()
	boss._update_pressure_and_posture(6.5)
	if absf(boss.posture - 73.6) > 0.1:
		push_error("Boss posture should decay at 10% max posture per second scaled by current health after disengaging")
		quit(1)
		return
	if not boss.is_posture_bar_visible():
		push_error("Boss posture bar should stay visible while posture is changing")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
