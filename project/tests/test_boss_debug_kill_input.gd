extends SceneTree

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	if main_scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	var boss = main._spawn_boss_for_boss_interior()
	await process_frame
	if boss == null:
		push_error("Debug test should spawn boss")
		quit(1)
		return

	var event := InputEventKey.new()
	event.keycode = KEY_I
	event.pressed = true
	main._input(event)
	await process_frame

	if not bool(main.get("is_boss_final_execution_playing")):
		push_error("Pressing I should start the boss final execution ritual")
		quit(1)
		return
	if bool(boss.get("defeated_flag")):
		push_error("Pressing I should not skip directly to boss death before the ritual")
		quit(1)
		return

	while bool(main.get("is_boss_final_execution_playing")):
		await process_frame

	if not bool(boss.get("defeated_flag")):
		push_error("Boss should be defeated after the I-key final execution ritual")
		quit(1)
		return
	var defeated_y: float = boss.global_position.y
	boss._physics_process(0.25)
	if int(boss.collision_layer) != 0 or int(boss.collision_mask) != 0:
		push_error("Debug-killed boss corpse should not collide or be pushable")
		quit(1)
		return
	if absf(boss.global_position.y - defeated_y) > 0.01:
		push_error("Debug-killed boss corpse should stay fixed instead of falling")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
