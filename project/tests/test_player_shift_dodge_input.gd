extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if player_scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player: Node = player_scene.instantiate()
	get_root().add_child(player)
	await process_frame

	Input.action_press("perfect_dodge_shift")
	player._update_inputs()
	Input.action_release("perfect_dodge_shift")

	if bool(player.is_dashing):
		push_error("Shift should not start a normal dash when there is no perfect dodge target")
		quit(1)
		return

	quit(0)
