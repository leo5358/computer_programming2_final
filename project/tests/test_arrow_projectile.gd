extends SceneTree

func _initialize() -> void:
	var arrow_scene: PackedScene = load("res://scenes/Arrow.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if arrow_scene == null or player_scene == null:
		push_error("Arrow and Player scenes should load")
		quit(1)
		return

	var arrow: CharacterBody2D = arrow_scene.instantiate() as CharacterBody2D
	var player: Node = player_scene.instantiate()
	arrow.global_position = Vector2(100.0, 360.0)
	(player as Node2D).global_position = Vector2(900.0, 360.0)
	get_root().add_child(arrow)
	get_root().add_child(player)
	await process_frame

	if not arrow.is_in_group("enemy_projectile"):
		push_error("Arrow should join enemy_projectile group")
		quit(1)
		return
	if not arrow.has_method("setup"):
		push_error("Arrow should expose setup(direction, owner)")
		quit(1)
		return
	if not arrow.has_method("receive_player_attack"):
		push_error("Arrow should be destroyable by player attacks")
		quit(1)
		return
	var attack_area := player.get_node("AttackArea") as Area2D
	if attack_area == null or (attack_area.collision_mask & 4) == 0:
		push_error("Player AttackArea should detect arrow projectile collision layer")
		quit(1)
		return

	arrow.setup(1.0, null)
	arrow._physics_process(0.25)
	if arrow.global_position.x <= 150.0:
		push_error("Arrow should travel horizontally after setup")
		quit(1)
		return

	arrow.receive_player_attack(1.0, 0.0)
	if not arrow.destroyed:
		push_error("Player attack should destroy arrow")
		quit(1)
		return

	arrow.queue_free()
	player.queue_free()
	await process_frame
	quit(0)
