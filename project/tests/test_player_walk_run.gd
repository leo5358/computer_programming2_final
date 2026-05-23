extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player = scene.instantiate()
	get_root().add_child(player)
	await process_frame

	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	if not sprite.sprite_frames.has_animation("walk"):
		push_error("Player should build walk animation from walk.png")
		quit(1)
		return
	var walk_first_frame := sprite.sprite_frames.get_frame_texture("walk", 0) as AtlasTexture
	if walk_first_frame == null or walk_first_frame.region != Rect2(0, 0, 96, 96):
		push_error("Player walk strip should use 96x96 frames")
		quit(1)
		return

	player._set_state(player.PlayerState.MOVE)
	player.is_running = false
	player._update_visuals()
	if player.current_animation != "walk":
		push_error("Player should use walk animation while moving without run held")
		quit(1)
		return

	player.is_running = true
	player.current_animation = ""
	player._update_visuals()
	if player.current_animation != "run":
		push_error("Player should use run animation while run is held")
		quit(1)
		return

	if player.walk_speed >= player.run_speed:
		push_error("Walk speed should be lower than run speed")
		quit(1)
		return
	if player.dash_impulse * player.dash_duration > 100.0:
		push_error("Dash should be tuned as a short dodge, not a long traversal move")
		quit(1)
		return

	player.queue_free()
	await process_frame
	quit(0)
