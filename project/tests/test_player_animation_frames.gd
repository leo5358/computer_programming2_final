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

	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if sprite == null or sprite.sprite_frames == null:
		push_error("Player should build AnimatedSprite2D sprite frames")
		quit(1)
		return
	if sprite.sprite_frames.get_frame_count("hurt") != 8:
		push_error("Player hurt animation should use the 8 custom cropped frames")
		quit(1)
		return

	var first_frame := sprite.sprite_frames.get_frame_texture("hurt", 0) as AtlasTexture
	var fifth_frame := sprite.sprite_frames.get_frame_texture("hurt", 4) as AtlasTexture
	var last_frame := sprite.sprite_frames.get_frame_texture("hurt", 7) as AtlasTexture
	if first_frame == null or fifth_frame == null or last_frame == null:
		push_error("Player hurt animation should use AtlasTexture frames")
		quit(1)
		return
	if first_frame.region != Rect2(0.0, 0.0, 106.0, 96.0):
		push_error("Player hurt frame 1 should match the custom crop")
		quit(1)
		return
	if fifth_frame.region != Rect2(399.0, 0.0, 92.0, 96.0):
		push_error("Player hurt frame 5 should match the custom crop")
		quit(1)
		return
	if last_frame.region != Rect2(678.0, 0.0, 90.0, 96.0):
		push_error("Player hurt frame 8 should match the custom crop")
		quit(1)
		return
	player.set("state", player.PlayerState.IDLE)
	player.set("current_animation", "")
	player._update_visuals()
	if not sprite.scale.is_equal_approx(Vector2.ONE):
		push_error("Player idle animation should render at normal sprite scale")
		quit(1)
		return
	player.set("state", player.PlayerState.MOVE)
	player.set("velocity", Vector2(20.0, 0.0))
	player._update_visuals()
	if not sprite.scale.is_equal_approx(Vector2(1.1, 1.1)):
		push_error("Player walk animation should render at 1.1x sprite scale")
		quit(1)
		return
	player._force_play_animation("hurt")
	if not sprite.scale.is_equal_approx(Vector2.ONE):
		push_error("Player forced hurt animation should not keep idle sprite scale")
		quit(1)
		return

	player.queue_free()
	await process_frame
	quit(0)
