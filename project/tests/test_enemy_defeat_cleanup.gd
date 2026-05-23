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
	if warrior.corpse_timer < 4.9:
		push_error("Defeated enemy corpse should remain for about 5 seconds")
		quit(1)
		return

	warrior._physics_process(5.1)
	if not warrior.is_queued_for_deletion():
		push_error("Defeated enemy corpse should be removed after corpse lifetime")
		quit(1)
		return

	await process_frame
	quit(0)
