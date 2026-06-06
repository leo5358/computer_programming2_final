extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/Player.tscn"


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false


func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		return _fail("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
	return true


func _assert_approx(actual: float, expected: float, message: String) -> bool:
	if absf(actual - expected) > 0.001:
		return _fail("%s (expected %.3f, got %.3f)" % [message, expected, actual])
	return true


func _load_player_scene() -> PackedScene:
	var player_scene: PackedScene = load(PLAYER_SCENE_PATH)
	if player_scene == null:
		_fail("Player scene should load")
	return player_scene


func _spawn_player(player_scene: PackedScene) -> Node:
	var player := player_scene.instantiate()
	get_root().add_child(player)
	await process_frame
	player.reset_combat_state()
	return player


func _despawn_player(player: Node) -> void:
	player.set_physics_process(false)
	var sprite := player.get_node_or_null("AnimatedSprite2D")
	if sprite != null:
		sprite.sprite_frames = null
	player.queue_free()
	await process_frame


func _use_item_or_fail(player: Node, item_id: String, message: String) -> bool:
	if not player.use_item(item_id):
		return _fail(message)
	return true


func _finish_item_action_or_fail(player: Node, message: String) -> bool:
	if player.state != player.PlayerState.EAT:
		return _fail(message)
	player._update_action_state(player.action_timer)
	if player.state == player.PlayerState.EAT:
		return _fail("%s (item action should have finished)" % message)
	return true


func _test_pill_walk_modifier(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(70.0)
	if not _use_item_or_fail(player, "pill", "Pill should be usable during the heartbeat test"):
		return false
	if not _assert_approx(player.heartbeat_precise, 70.0, "Pill should no longer change heartbeat instantly when consumed"):
		return false
	player.state = player.PlayerState.MOVE
	player.velocity.x = 90.0
	player._update_combat(1.0)
	if not _assert_equal(player.heartbeat, 71.0, "Pill should reduce walking heartbeat rise to floor(95 * 3%% * 0.6) after one second"):
		return false
	if not _assert_approx(player.heartbeat_precise, 71.71, "Pill should preserve fractional walking heartbeat gain in heartbeat_precise"):
		return false
	await _despawn_player(player)
	return true


func _test_pill_combat_modifier(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "pill", "Pill should be usable before combat pressure assertions"):
		return false
	if not _assert_approx(player.heartbeat_precise, 100.0, "Pill should not apply the removed instant -25 heartbeat effect"):
		return false
	player.heartbeat_combat_timer = 1.5
	player._update_combat(1.0)
	if not _assert_equal(player.heartbeat, 102.0, "Pill should reduce combat pressure to floor(100 + 4 * 0.6) after one second"):
		return false
	if not _assert_approx(player.heartbeat_precise, 102.4, "Pill should reduce combat pressure in heartbeat_precise without rounding away the fraction"):
		return false
	await _despawn_player(player)
	return true


func _test_pill_duration(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "pill", "Pill should be usable before expiry assertions"):
		return false
	if not _finish_item_action_or_fail(player, "Pill duration assertions should wait for the eat action to finish before sustained combat pressure"):
		return false
	player.heartbeat_combat_timer = 25.0
	player._update_combat(19.0)
	if not _assert_approx(player.heartbeat_precise, 145.6, "Pill should stay active for the first nineteen seconds of combat pressure"):
		return false
	player._update_combat(1.0)
	if not _assert_approx(player.heartbeat_precise, 148.0, "Pill should still apply on the twentieth second before expiring"):
		return false
	player._update_combat(1.0)
	if not _assert_approx(player.heartbeat_precise, 152.0, "Pill should expire after twenty seconds so later combat pressure returns to the full rate"):
		return false
	await _despawn_player(player)
	return true


func _test_capsule_attack_modifier(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "capsule", "Capsule should be usable during the heartbeat test"):
		return false
	if not _assert_approx(player.heartbeat_precise, 100.0, "Capsule should no longer change heartbeat instantly when consumed"):
		return false
	if not _finish_item_action_or_fail(player, "Attack assertions should not run while the capsule eat action is still active"):
		return false
	player._start_attack()
	if not _assert_equal(player.heartbeat, 104.0, "Capsule should floor the boosted 4.8 attack gain to 104 heartbeat"):
		return false
	if not _assert_approx(player.heartbeat_precise, 104.8, "Capsule should boost attack heartbeat gain through heartbeat_precise by 20 percent"):
		return false
	await _despawn_player(player)
	return true


func _test_capsule_duration(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "capsule", "Capsule should be usable before expiry assertions"):
		return false
	if not _finish_item_action_or_fail(player, "Capsule duration assertions should wait for the eat action to finish before sustained combat pressure"):
		return false
	player.heartbeat_combat_timer = 20.0
	player._update_combat(14.0)
	if not _assert_approx(player.heartbeat_precise, 167.2, "Capsule should stay active for the first fourteen seconds of combat pressure"):
		return false
	player._update_combat(1.0)
	if not _assert_approx(player.heartbeat_precise, 172.0, "Capsule should still apply on the fifteenth second before expiring"):
		return false
	player._update_combat(1.0)
	if not _assert_approx(player.heartbeat_precise, 176.0, "Capsule should expire after fifteen seconds so later combat pressure returns to the full rate"):
		return false
	await _despawn_player(player)
	return true


func _test_pill_to_capsule_overwrite(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "pill", "Pill should be usable before overwrite assertions"):
		return false
	if not _finish_item_action_or_fail(player, "Overwrite sequencing should wait for the first pill eat action to finish"):
		return false
	if not _use_item_or_fail(player, "capsule", "Capsule should overwrite an earlier pill effect"):
		return false
	if not _finish_item_action_or_fail(player, "Attack assertions should not run while the capsule overwrite eat action is still active"):
		return false
	player._start_attack()
	if not _assert_approx(player.heartbeat_precise, 104.8, "Later consumables should overwrite earlier ones instead of stacking or keeping the old modifier"):
		return false
	await _despawn_player(player)

	player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "pill", "Pill should be usable before overwrite duration assertions"):
		return false
	if not _finish_item_action_or_fail(player, "Overwrite duration sequencing should wait for the first pill eat action to finish"):
		return false
	if not _use_item_or_fail(player, "capsule", "Capsule should replace the active pill duration window"):
		return false
	if not _finish_item_action_or_fail(player, "Duration assertions should not run while the capsule overwrite eat action is still active"):
		return false
	player.heartbeat_combat_timer = 20.0
	player._update_combat(15.0)
	if not _assert_approx(player.heartbeat_precise, 172.0, "Pill to capsule overwrite should keep only the capsule timer through the fifteenth second"):
		return false
	player._update_combat(1.0)
	if not _assert_approx(player.heartbeat_precise, 176.0, "Pill to capsule overwrite should expire on the capsule window instead of reverting to the older pill timer"):
		return false
	await _despawn_player(player)
	return true


func _test_capsule_to_pill_overwrite(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "capsule", "Capsule should be usable before reverse overwrite assertions"):
		return false
	if not _finish_item_action_or_fail(player, "Overwrite sequencing should wait for the first capsule eat action to finish"):
		return false
	if not _use_item_or_fail(player, "pill", "Pill should overwrite an earlier capsule effect"):
		return false
	if not _finish_item_action_or_fail(player, "Attack assertions should not run while the pill overwrite eat action is still active"):
		return false
	player._start_attack()
	if not _assert_approx(player.heartbeat_precise, 102.4, "Later consumables should also overwrite in the reverse direction instead of stacking or keeping capsule active"):
		return false
	await _despawn_player(player)

	player = await _spawn_player(player_scene)
	player._set_heartbeat_value(100.0)
	if not _use_item_or_fail(player, "capsule", "Capsule should be usable before reverse overwrite duration assertions"):
		return false
	if not _finish_item_action_or_fail(player, "Overwrite duration sequencing should wait for the first capsule eat action to finish"):
		return false
	if not _use_item_or_fail(player, "pill", "Pill should replace the active capsule duration window"):
		return false
	if not _finish_item_action_or_fail(player, "Duration assertions should not run while the pill overwrite eat action is still active"):
		return false
	player.heartbeat_combat_timer = 20.0
	player._update_combat(15.0)
	if not _assert_approx(player.heartbeat_precise, 136.0, "Capsule to pill overwrite should keep the later pill timer active past the old capsule boundary"):
		return false
	player._update_combat(1.0)
	if not _assert_approx(player.heartbeat_precise, 138.4, "Capsule to pill overwrite should continue using the pill modifier after the original capsule window would have ended"):
		return false
	await _despawn_player(player)
	return true


func _test_cooldown_unchanged(player_scene: PackedScene) -> bool:
	var player = await _spawn_player(player_scene)
	player._set_heartbeat_value(120.0)
	if not _use_item_or_fail(player, "pill", "Pill should be usable before cooldown assertions"):
		return false
	player._update_combat(1.0)
	if not _assert_equal(player.heartbeat, 120.0, "Pill should not affect the first second of heartbeat cooldown delay"):
		return false
	player._update_combat(1.0)
	if not _assert_equal(player.heartbeat, 110.0, "Pill should not change heartbeat cooldown or other decreases"):
		return false
	if not _assert_approx(player.heartbeat_precise, 110.4, "Pill should leave heartbeat_precise cooldown decreases unchanged"):
		return false
	await _despawn_player(player)

	player = await _spawn_player(player_scene)
	player._set_heartbeat_value(120.0)
	if not _use_item_or_fail(player, "capsule", "Capsule should be usable before cooldown assertions"):
		return false
	player._update_combat(1.0)
	if not _assert_equal(player.heartbeat, 120.0, "Capsule should not affect the first second of heartbeat cooldown delay"):
		return false
	player._update_combat(1.0)
	if not _assert_equal(player.heartbeat, 110.0, "Capsule should not change heartbeat cooldown or other decreases"):
		return false
	if not _assert_approx(player.heartbeat_precise, 110.4, "Capsule should leave heartbeat_precise cooldown decreases unchanged"):
		return false
	await _despawn_player(player)
	return true


func _initialize() -> void:
	var player_scene := _load_player_scene()
	if player_scene == null:
		return

	if not await _test_pill_walk_modifier(player_scene):
		return
	if not await _test_pill_combat_modifier(player_scene):
		return
	if not await _test_pill_duration(player_scene):
		return
	if not await _test_capsule_attack_modifier(player_scene):
		return
	if not await _test_capsule_duration(player_scene):
		return
	if not await _test_pill_to_capsule_overwrite(player_scene):
		return
	if not await _test_capsule_to_pill_overwrite(player_scene):
		return
	if not await _test_cooldown_unchanged(player_scene):
		return

	quit(0)
