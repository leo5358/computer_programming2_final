extends SceneTree

func _initialize() -> void:
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	if warrior_scene == null:
		push_error("WarriorEnemy scene should load")
		quit(1)
		return

	var warrior: Node = warrior_scene.instantiate()
	get_root().add_child(warrior)
	await process_frame

	warrior.receive_player_attack(999.0, 0.0)
	if warrior.state != warrior.EnemyState.DEAD:
		push_error("Defeated enemy should enter DEAD state")
		quit(1)
		return
	var body_shape := warrior.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape == null or body_shape.disabled:
		push_error("Defeated enemy corpse should keep its body shape enabled so it stays on the floor")
		quit(1)
		return
	if int(warrior.collision_layer) != 0:
		push_error("Defeated enemy corpse should not expose a collision layer to the player")
		quit(1)
		return
	if int(warrior.collision_mask) == 0:
		push_error("Defeated enemy corpse should keep its collision mask so it remains grounded")
		quit(1)
		return
	if warrior.corpse_timer < 4.9:
		push_error("Defeated enemy corpse should remain for about 5 seconds")
		quit(1)
		return

	warrior.reset_combat_state()
	if body_shape.disabled:
		push_error("Enemy reset should keep body collision shape enabled")
		quit(1)
		return
	if int(warrior.collision_layer) == 0 or int(warrior.collision_mask) == 0:
		push_error("Enemy reset should restore collision layer and mask")
		quit(1)
		return
	warrior.receive_player_attack(999.0, 0.0)

	warrior._physics_process(5.1)
	if not warrior.is_queued_for_deletion():
		push_error("Defeated enemy corpse should be removed after corpse lifetime")
		quit(1)
		return

	await process_frame
	quit(0)
