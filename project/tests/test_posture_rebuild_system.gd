extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const WARRIOR_SCENE: PackedScene = preload("res://scenes/WarriorEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/Boss.tscn")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_close(actual: float, expected: float, message: String, tolerance: float = 0.05) -> bool:
	if absf(actual - expected) > tolerance:
		_fail("%s (expected %.3f, got %.3f)" % [message, expected, actual])
		return false
	return true


func _initialize() -> void:
	var root := Node2D.new()
	root.name = "PostureRebuildSystemTest"
	get_root().add_child(root)

	var player = PLAYER_SCENE.instantiate()
	var enemy = WARRIOR_SCENE.instantiate()
	var boss = BOSS_SCENE.instantiate()
	root.add_child(player)
	root.add_child(enemy)
	root.add_child(boss)
	await process_frame

	player.reset_combat_state()
	player.health = player.max_health
	player.posture = 0.0
	player.receive_enemy_attack(10.0, 99.0)
	if not _assert_close(player.health, player.max_health - 10.0, "Player direct hit should apply full damage"):
		return
	if not _assert_close(player.posture, 18.0, "Player direct hit should add ceil(17.25%) posture"):
		return

	player.reset_combat_state()
	player.posture = player.max_posture - 7.0
	player.is_parrying = true
	player.receive_enemy_attack(10.0, 99.0)
	if player.state == player.PlayerState.STUNNED:
		_fail("Perfect guard filling player posture should not stagger immediately")
		return
	if not bool(player.get("posture_locked_full_from_perfect_guard")):
		_fail("Perfect guard filling posture should set the full-lock flag")
		return
	if not player.is_posture_bar_visible():
		_fail("Player posture bar should remain visible while perfect-guard full lock is active")
		return

	player.reset_combat_state()
	player.posture = player.max_posture - 11.0
	player.is_blocking = true
	player.receive_enemy_attack(20.0, 99.0)
	if player.state != player.PlayerState.STUNNED:
		_fail("Partial guard filling player posture should stagger")
		return
	if not _assert_close(player.health, player.max_health - (20.0 * 0.25), "Partial guard should deal 25% chip damage"):
		return
	if not _assert_close(player.posture, 0.0, "Player stagger should clear posture after break"):
		return

	player.reset_combat_state()
	player.posture = player.max_posture - 18.0
	player._set_heartbeat_value(80.0)
	player.receive_enemy_attack(10.0, 99.0)
	if player.state != player.PlayerState.STUNNED:
		_fail("Player direct health hit filling posture should enter stunned state")
		return
	player._update_action_state(player.stunned_time + 0.05)
	if not _assert_close(player.heartbeat, 80.0, "Player posture-break recovery should keep heartbeat unchanged when already below 120", 0.01):
		return

	player.reset_combat_state()
	player.posture = player.max_posture - 18.0
	player._set_heartbeat_value(160.0)
	player.receive_enemy_attack(10.0, 99.0)
	if player.state != player.PlayerState.STUNNED:
		_fail("Player direct health hit filling posture should enter stunned state")
		return
	player._update_action_state(player.stunned_time + 0.05)
	if not _assert_close(player.heartbeat, 120.0, "Player posture-break recovery should clamp heartbeat back to 120 when above it", 0.01):
		return

	enemy.reset_combat_state()
	enemy.guard_chance = 0.0
	enemy.posture = enemy.max_posture - 15.0
	enemy.receive_player_attack(10.0, 999.0)
	if not enemy.posture_broken:
		_fail("Minor enemy should enter posture broken state at full posture")
		return
	if not enemy.can_be_executed():
		_fail("Minor enemy posture break should enable execute")
		return
	if not enemy.is_posture_bar_visible():
		_fail("Minor enemy posture bar should stay visible while broken")
		return
	enemy._physics_process(enemy.posture_break_idle_reset_delay + 0.1)
	if enemy.posture_broken or enemy.can_be_executed():
		_fail("Minor enemy posture break should reset after idle delay")
		return
	if not _assert_close(enemy.posture, 0.0, "Minor enemy posture reset should clear posture"):
		return

	enemy.reset_combat_state()
	enemy.guard_chance = 0.0
	enemy.posture = enemy.max_posture - 15.0
	enemy.health = enemy.max_health
	enemy.receive_player_attack(10.0, 999.0)
	var enemy_health_before_followup: float = enemy.health
	enemy.receive_player_attack(7.0, 999.0)
	if not _assert_close(enemy.health, enemy_health_before_followup - 7.0, "Broken minor enemy should take follow-up health damage only"):
		return
	if not bool(enemy.get("posture_break_took_followup_hit")):
		_fail("Broken minor enemy should record the follow-up hit flag")
		return
	enemy._physics_process(enemy.posture_break_hit_reset_delay + 0.1)
	if enemy.posture_broken:
		_fail("Broken minor enemy should reset after the shortened follow-up timer")
		return

	boss.reset_combat_state()
	boss.guard_chance = 0.0
	if not _assert_close(boss.max_posture, 120.0, "Boss max posture should use rebuilt value"):
		return
	var boss_health_before_hit: float = boss.health
	boss.receive_player_attack(16.0, 999.0)
	if not _assert_close(boss.health, boss_health_before_hit - 16.0, "Boss direct hit should reduce health without minimum floor"):
		return
	if not _assert_close(boss.posture, 11.0, "Boss direct hit should add ceil(current minor-enemy direct ratio) posture"):
		return

	boss.reset_combat_state()
	boss.guard_chance = 0.0
	boss.posture = boss.max_posture - 11.0
	boss.health = 12.0
	boss.receive_player_attack(5.0, 999.0)
	if not boss.posture_broken:
		_fail("Boss should enter posture broken state at full posture")
		return
	var boss_health_before_followup: float = boss.health
	boss.receive_player_attack(20.0, 999.0)
	if not boss.defeated_flag:
		_fail("Broken boss should die from follow-up execute damage")
		return
	if boss.health >= boss_health_before_followup:
		_fail("Broken boss follow-up should consume remaining health")
		return

	root.queue_free()
	await process_frame
	quit(0)
