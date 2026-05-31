extends SceneTree

func _initialize() -> void:
	var checkpoint_scene: PackedScene = load("res://scenes/Checkpoint.tscn")
	if checkpoint_scene == null:
		push_error("Checkpoint scene should load")
		quit(1)
		return

	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var player: Node2D = player_scene.instantiate()
	get_root().add_child(player)
	var checkpoint: Node2D = checkpoint_scene.instantiate()
	get_root().add_child(checkpoint)
	checkpoint.global_position = Vector2(1200, 560)
	await process_frame

	if not checkpoint.is_in_group("checkpoint"):
		push_error("Checkpoint should be in checkpoint group")
		quit(1)
		return
	if bool(checkpoint.get("activated")):
		push_error("Checkpoint should start disabled")
		quit(1)
		return
	if not checkpoint.has_method("activate"):
		push_error("Checkpoint should expose activate(player)")
		quit(1)
		return
	if not checkpoint.has_method("is_player_in_range"):
		push_error("Checkpoint should expose player range checks")
		quit(1)
		return
	var sprite: Sprite2D = checkpoint.get_node_or_null("Sprite2D")
	if sprite == null or sprite.scale.distance_to(Vector2(0.4, 0.4)) > 0.001:
		push_error("Checkpoint art should be scaled up for map readability")
		quit(1)
		return
	if not is_equal_approx(sprite.position.y, -241.2):
		push_error("Checkpoint art bottom should sit on the floor contact point")
		quit(1)
		return
	if checkpoint.z_index != 80:
		push_error("Checkpoint should render above the map art")
		quit(1)
		return
	if player.z_index <= checkpoint.z_index:
		push_error("Player should render above checkpoint art")
		quit(1)
		return
	for scene_path in ["res://scenes/WarriorEnemy.tscn", "res://scenes/ArcherEnemy.tscn", "res://scenes/TorchmanEnemy.tscn", "res://scenes/Boss.tscn"]:
		var character_scene: PackedScene = load(scene_path)
		var character: Node2D = character_scene.instantiate()
		get_root().add_child(character)
		await process_frame
		if character.z_index <= checkpoint.z_index:
			push_error("Enemies and Boss should render above checkpoint art: %s" % scene_path)
			quit(1)
			return
		character.queue_free()

	player.global_position = checkpoint.global_position + Vector2(20, 0)
	if not checkpoint.is_player_in_range(player):
		push_error("Checkpoint should detect nearby player")
		quit(1)
		return

	checkpoint.activate(player)
	if not bool(checkpoint.get("activated")):
		push_error("Checkpoint should become activated")
		quit(1)
		return
	if player.get("spawn_position") != checkpoint.global_position:
		push_error("Checkpoint activation should update player spawn_position")
		quit(1)
		return

	player.queue_free()
	checkpoint.queue_free()
	await process_frame
	quit(0)
