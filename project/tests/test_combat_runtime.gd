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

	var runtime = main.get_node("CombatRuntime")
	if runtime == null:
		push_error("CombatRuntime should exist")
		quit(1)
		return

	runtime.register_input(1, 900)
	var attack_id: int = runtime.notify_attack_active(0, 1000)
	var update: Dictionary = runtime.get_combat_update(0.0)
	if attack_id != 1:
		push_error("First runtime attack id should be 1")
		quit(1)
		return
	if update["last_parry_delta_ms"] != -100:
		push_error("Runtime should report parry delta")
		quit(1)
		return
	if not update["is_parry_successful"]:
		push_error("Runtime should report parry success")
		quit(1)
		return

	runtime.force_bpm(200.0)
	var player = get_root().get_tree().get_first_node_in_group("player")
	if abs(player.heartbeat - 200.0) > 0.001:
		push_error("Force BPM should affect live player heartbeat")
		quit(1)
		return

	runtime.reset_combat()
	if abs(player.heartbeat - 65.0) > 0.001:
		push_error("Reset combat should restore player heartbeat")
		quit(1)
		return
	if player.state != player.PlayerState.IDLE:
		push_error("Reset combat should restore player state")
		quit(1)
		return

	player.health = 1.0
	player.receive_enemy_attack(10.0, 0.0)
	if player.state != player.PlayerState.DEAD:
		push_error("Test setup should kill player before input reset check")
		quit(1)
		return

	var reset_event := InputEventAction.new()
	reset_event.action = "reset_combat"
	reset_event.pressed = true
	runtime._input(reset_event)
	if player.state != player.PlayerState.IDLE:
		push_error("Runtime _input should reset player from death")
		quit(1)
		return

	main.queue_free()
	quit(0)
