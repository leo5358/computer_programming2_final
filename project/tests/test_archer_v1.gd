extends SceneTree

func _initialize() -> void:
	var archer_scene: PackedScene = load("res://scenes/ArcherEnemy.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if archer_scene == null or player_scene == null:
		push_error("Archer and Player scenes should load")
		quit(1)
		return

	var archer: Node2D = archer_scene.instantiate()
	var player: Node2D = player_scene.instantiate()
	get_root().add_child(archer)
	get_root().add_child(player)
	await process_frame

	archer.global_position = Vector2(200.0, 360.0)
	player.global_position = Vector2(270.0, 360.0)
	archer.receive_alert()
	archer.target = player
	archer.attack_cooldown = 0.0
	archer._update_combat_movement()
	if archer.state != archer.EnemyState.FLEE or archer.velocity.x >= 0.0:
		push_error("Archer should retreat when player is too close")
		quit(1)
		return

	player.global_position = Vector2(520.0, 360.0)
	archer.attack_cooldown = 0.0
	archer._update_combat_movement()
	if archer.state != archer.EnemyState.CHASE or archer.velocity.x <= 0.0:
		push_error("Archer should chase to reach bow range")
		quit(1)
		return

	player.global_position = Vector2(420.0, 360.0)
	archer.attack_cooldown = 0.0
	archer._update_combat_movement()
	if archer.state != archer.EnemyState.ATTACK:
		push_error("Archer should attack from ideal bow range")
		quit(1)
		return
	var health_before: float = player.health
	archer._update_attack(archer.attack_hit_start + 0.01)
	if player.health != health_before:
		push_error("Archer attack should spawn an arrow instead of directly damaging player")
		quit(1)
		return
	var arrows := get_nodes_in_group("enemy_projectile")
	if arrows.size() != 1:
		push_error("Archer attack should spawn exactly one arrow projectile")
		quit(1)
		return
	var arrow := arrows[0] as Node2D
	if arrow == null or arrow.global_position.x <= archer.global_position.x:
		push_error("Archer arrow should spawn in front of the archer")
		quit(1)
		return

	archer.queue_free()
	player.queue_free()
	arrow.queue_free()
	await process_frame
	quit(0)
