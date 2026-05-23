extends SceneTree

func _initialize() -> void:
	var archer_scene: PackedScene = load("res://scenes/ArcherEnemy.tscn")
	if archer_scene == null:
		push_error("ArcherEnemy scene should load")
		quit(1)
		return

	var archer: Node = archer_scene.instantiate()
	get_root().add_child(archer)
	await process_frame

	var sprite: AnimatedSprite2D = archer.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("Archer should create AnimatedSprite2D frames")
		quit(1)
		return

	var frames: SpriteFrames = sprite.sprite_frames
	if frames.get_frame_count("idle") != 7:
		push_error("Archer idle should use teammate tscn's 7 idle frames")
		quit(1)
		return
	if frames.get_frame_count("attack") != 8:
		push_error("Archer attack should use teammate tscn's 8 attack frames")
		quit(1)
		return
	if frames.get_frame_count("walk") != 8:
		push_error("Archer walk should use teammate tscn's 8 walk frames")
		quit(1)
		return

	var idle_frame_1: AtlasTexture = frames.get_frame_texture("idle", 0) as AtlasTexture
	var walk_frame_8: AtlasTexture = frames.get_frame_texture("walk", 7) as AtlasTexture
	var attack_frame_1: AtlasTexture = frames.get_frame_texture("attack", 0) as AtlasTexture
	var attack_frame_8: AtlasTexture = frames.get_frame_texture("attack", 7) as AtlasTexture
	var hurt_frame_3: AtlasTexture = frames.get_frame_texture("hurt", 2) as AtlasTexture
	var death_frame_5: AtlasTexture = frames.get_frame_texture("death", 4) as AtlasTexture
	if idle_frame_1 == null or walk_frame_8 == null or attack_frame_1 == null or attack_frame_8 == null or hurt_frame_3 == null or death_frame_5 == null:
		push_error("Archer frames should be AtlasTextures")
		quit(1)
		return
	if idle_frame_1.region != Rect2(9.0, 0.0, 96.0, 96.0):
		push_error("Archer idle frame 1 should match teammate tscn crop")
		quit(1)
		return
	if attack_frame_1.region != Rect2(4.0, 0.0, 90.0, 96.0):
		push_error("Archer attack frame 1 should match teammate tscn crop")
		quit(1)
		return
	if attack_frame_8.region != Rect2(669.0, 0.0, 93.0, 96.0):
		push_error("Archer attack frame 8 should match teammate tscn crop")
		quit(1)
		return
	if walk_frame_8.region != Rect2(672.0, 0.0, 96.0, 96.0):
		push_error("Archer walk frame 8 should match teammate tscn crop")
		quit(1)
		return
	if hurt_frame_3.region != Rect2(182.0, 0.0, 91.0, 96.0):
		push_error("Archer hurt frame 3 should match teammate tscn crop")
		quit(1)
		return
	if death_frame_5.region != Rect2(368.0, 0.0, 92.0, 96.0):
		push_error("Archer death frame 5 should match teammate tscn crop")
		quit(1)
		return

	archer.queue_free()
	await process_frame
	quit(0)
