extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/maps/chapter1_h_stone_plaza.tscn")
	if scene == null:
		push_error("H stone plaza scene should load")
		quit(1)
		return

	var map: Node = scene.instantiate()
	get_root().add_child(map)
	await process_frame

	var checkpoint_root: Node = map.get_node_or_null("Checkpoints")
	if checkpoint_root == null:
		push_error("H stone plaza should own its checkpoint nodes")
		quit(1)
		return

	var checkpoint := checkpoint_root.get_node_or_null("CheckpointPlaza") as Node2D
	if checkpoint == null:
		push_error("H stone plaza should include CheckpointPlaza")
		quit(1)
		return
	if checkpoint.global_position.distance_to(Vector2(2087, 530)) > 1.0:
		push_error("CheckpointPlaza should be placed at x=2087 y=530")
		quit(1)
		return
	if not checkpoint.is_in_group("checkpoint"):
		push_error("CheckpointPlaza should use the shared checkpoint scene")
		quit(1)
		return
	if checkpoint.z_index != 80:
		push_error("CheckpointPlaza should render above map art and below characters")
		quit(1)
		return

	map.queue_free()
	await process_frame
	quit(0)
