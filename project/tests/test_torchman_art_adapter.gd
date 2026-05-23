extends SceneTree

func _initialize() -> void:
	var torchman_scene: PackedScene = load("res://scenes/TorchmanEnemy.tscn")
	if torchman_scene == null:
		push_error("TorchmanEnemy scene should load")
		quit(1)
		return

	var torchman: Node = torchman_scene.instantiate()
	get_root().add_child(torchman)
	await process_frame

	var sprite: AnimatedSprite2D = torchman.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("Torchman should create AnimatedSprite2D frames")
		quit(1)
		return

	var frames: SpriteFrames = sprite.sprite_frames
	if frames.get_frame_count("idle") != 8:
		push_error("Torchman idle should use teammate tscn's 8 idle frames")
		quit(1)
		return
	if frames.get_frame_count("attack") != 7:
		push_error("Torchman attack should use teammate tscn's 7 torch attack frames")
		quit(1)
		return
	if frames.get_frame_count("walk") != 8:
		push_error("Torchman walk should use teammate tscn's 8 nonuniform walk frames")
		quit(1)
		return
	var idle_frame_1: AtlasTexture = frames.get_frame_texture("idle", 0) as AtlasTexture
	var walk_frame_8: AtlasTexture = frames.get_frame_texture("walk", 7) as AtlasTexture
	var attack_frame_4: AtlasTexture = frames.get_frame_texture("attack", 3) as AtlasTexture
	var death_frame_7: AtlasTexture = frames.get_frame_texture("death", 6) as AtlasTexture
	if idle_frame_1 == null or walk_frame_8 == null or attack_frame_4 == null or death_frame_7 == null:
		push_error("Torchman frames should be AtlasTextures")
		quit(1)
		return
	if idle_frame_1.region != Rect2(8.0, 0.0, 96.0, 96.0):
		push_error("Torchman idle frame 1 should match teammate tscn crop")
		quit(1)
		return
	if attack_frame_4.region != Rect2(396.0, 0.0, 93.0, 96.0):
		push_error("Torchman attack frame 4 should match teammate tscn crop")
		quit(1)
		return
	if walk_frame_8.region != Rect2(651.0, 0.0, 93.0, 96.0):
		push_error("Torchman walk frame 8 should match teammate tscn crop")
		quit(1)
		return
	if death_frame_7.region != Rect2(562.0, 0.0, 103.0, 96.0):
		push_error("Torchman death frame 7 should match teammate tscn crop")
		quit(1)
		return

	torchman.queue_free()
	await process_frame
	quit(0)
