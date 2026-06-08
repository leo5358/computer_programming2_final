extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main: Node = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	if not InputMap.has_action("toggle_hurtbox_debug"):
		push_error("InputMap should include toggle_hurtbox_debug")
		quit(1)
		return
	var has_b_key := false
	for event in InputMap.action_get_events("toggle_hurtbox_debug"):
		if event is InputEventKey and event.keycode == KEY_B:
			has_b_key = true
	if not has_b_key:
		push_error("toggle_hurtbox_debug should be bound to B")
		quit(1)
		return

	var overlay = main.get_node_or_null("HurtboxDebugOverlay")
	var player = main.get_node_or_null("Player")
	var boss = main.get_node_or_null("Boss")
	if overlay == null or player == null or boss == null:
		push_error("Main scene should contain overlay, player, and boss")
		quit(1)
		return

	overlay.toggle_hurtbox_debug()
	var player_line := player.get_node_or_null("HurtboxDebugLine") as Line2D
	var boss_line := boss.get_node_or_null("HurtboxDebugLine") as Line2D
	if player_line == null or boss_line == null:
		push_error("Toggling hurtbox debug should create player and boss line overlays")
		quit(1)
		return
	if not player_line.visible or not boss_line.visible:
		push_error("Toggling hurtbox debug on should show line overlays")
		quit(1)
		return
	if player_line.points.size() != 4 or boss_line.points.size() != 4:
		push_error("Hurtbox line overlays should outline rectangle collision shapes")
		quit(1)
		return
	var player_shape := player.get_node("CollisionShape2D").shape as RectangleShape2D
	if player_shape.size.y < 70.0:
		push_error("Player hurtbox should cover the head and torso, not only the lower body")
		quit(1)
		return
	var coordinate_label := overlay.get_node_or_null("CoordinateHudLayer/PlayerCoordinateLabel") as Label
	if coordinate_label == null:
		push_error("Toggling hurtbox debug should create a player coordinate label")
		quit(1)
		return
	if not coordinate_label.visible:
		push_error("Player coordinate label should be visible while hurtbox debug is on")
		quit(1)
		return
	player.global_position = Vector2(321.0, 654.0)
	overlay._process(0.0)
	var player_collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var hitbox_bottom_center: Vector2 = player_collision.global_transform * Vector2(0.0, player_shape.size.y * 0.5)
	var expected_coordinate_text := "Player Hitbox: x=%.1f y=%.1f" % [hitbox_bottom_center.x, hitbox_bottom_center.y]
	if coordinate_label.text != expected_coordinate_text:
		push_error("Player coordinate label should use hitbox center x and bottom y, expected '%s' but got '%s'" % [expected_coordinate_text, coordinate_label.text])
		quit(1)
		return
	var boss_attack_line := boss.get_node_or_null("AttackArea/AttackHitboxDebugLine") as Line2D
	if boss_attack_line == null:
		push_error("Toggling hurtbox debug should create a Boss attack hitbox line")
		quit(1)
		return
	if not boss_attack_line.visible:
		push_error("Boss attack hitbox line should be visible when debug is on")
		quit(1)
		return
	var boss_attack_shape_node := boss.get_node("AttackArea/CollisionShape2D") as CollisionShape2D
	var boss_attack_shape := boss_attack_shape_node.shape as RectangleShape2D
	boss_attack_shape.size = Vector2(88.0, 44.0)
	await process_frame
	if boss_attack_line.points[1].x != 44.0 or boss_attack_line.points[2].y != 22.0:
		push_error("Boss attack debug red line should refresh while visible so it stays aligned with the current hitbox")
		quit(1)
		return

	overlay.toggle_hurtbox_debug()
	if player_line.visible or boss_line.visible or boss_attack_line.visible:
		push_error("Toggling hurtbox debug off should hide line overlays")
		quit(1)
		return
	if coordinate_label.visible:
		push_error("Toggling hurtbox debug off should hide the player coordinate label")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
