extends SceneTree

func _initialize() -> void:
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	if warrior_scene == null:
		push_error("WarriorEnemy scene should load")
		quit(1)
		return

	var warrior: Node = warrior_scene.instantiate()
	var floor_body := _create_floor()
	get_root().add_child(floor_body)
	warrior.global_position = Vector2(200.0, 0.0)
	get_root().add_child(warrior)
	await process_frame
	warrior._physics_process(0.016)

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
	if int(warrior.collision_mask) != 0:
		push_error("Defeated enemy corpse should clear its collision mask so it cannot be pushed")
		quit(1)
		return
	if warrior.corpse_timer < 4.9:
		push_error("Defeated enemy corpse should remain for about 5 seconds")
		quit(1)
		return

	var player_body := _create_player_body()
	player_body.global_position = warrior.global_position
	get_root().add_child(player_body)
	var corpse_position: Vector2 = warrior.global_position
	warrior._physics_process(0.016)
	if not warrior.global_position.is_equal_approx(corpse_position):
		push_error("Grounded enemy corpse should not be pushed by player overlap after death")
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

func _create_floor() -> StaticBody2D:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(200.0, 8.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(320.0, 16.0)
	shape.shape = rect
	floor_body.add_child(shape)
	return floor_body

func _create_player_body() -> CharacterBody2D:
	var player_body := CharacterBody2D.new()
	player_body.add_to_group("player")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(42.0, 76.0)
	shape.position = Vector2(0.0, -38.0)
	shape.shape = rect
	player_body.add_child(shape)
	return player_body
