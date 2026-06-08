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

	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("Player should build sprite frames")
		quit(1)
		return

	if not sprite.sprite_frames.has_animation("attack_thrust"):
		push_error("Player should build an attack_thrust animation from the thrust strip")
		quit(1)
		return
	if sprite.sprite_frames.get_frame_count("attack_thrust") != 8:
		push_error("Player thrust attack should use the reference tscn's 8 animation frames")
		quit(1)
		return

	var expected_regions := [
		Rect2(0, 0, 96, 96),
		Rect2(96, 0, 96, 96),
		Rect2(192, 0, 96, 96),
		Rect2(288, 0, 96, 96),
		Rect2(0, 0, 123, 96),
		Rect2(192, 0, 96, 96),
		Rect2(605, 0, 78, 96),
		Rect2(683, 0, 78, 96),
	]
	for index in expected_regions.size():
		var thrust_frame: AtlasTexture = sprite.sprite_frames.get_frame_texture("attack_thrust", index) as AtlasTexture
		if thrust_frame == null or thrust_frame.region != expected_regions[index]:
			push_error("Player thrust frame %d should match the reference tscn crop" % index)
			quit(1)
			return

	var press_event := InputEventKey.new()
	press_event.keycode = KEY_J
	press_event.pressed = true
	Input.parse_input_event(press_event)
	await physics_frame
	for index in 18:
		await physics_frame
	if player.current_attack_animation != "attack_thrust":
		push_error("Holding J or left mouse should trigger player thrust instead of normal attack")
		quit(1)
		return
	if player.state != player.PlayerState.ATTACK:
		push_error("Player thrust should enter the normal attack state")
		quit(1)
		return
	if sprite.animation != &"attack_thrust":
		push_error("Player thrust should play the thrust animation immediately")
		quit(1)
		return
	var release_event := InputEventKey.new()
	release_event.keycode = KEY_J
	release_event.pressed = false
	Input.parse_input_event(release_event)
	await physics_frame

	player.reset_combat_state()
	press_event = InputEventKey.new()
	press_event.keycode = KEY_J
	press_event.pressed = true
	Input.parse_input_event(press_event)
	await physics_frame
	release_event = InputEventKey.new()
	release_event.keycode = KEY_J
	release_event.pressed = false
	Input.parse_input_event(release_event)
	await physics_frame
	if player.current_attack_animation != "attack_a":
		push_error("Quick tapping J or left mouse should keep the normal slash attack")
		quit(1)
		return

	player.queue_free()
	await process_frame
	quit(0)
