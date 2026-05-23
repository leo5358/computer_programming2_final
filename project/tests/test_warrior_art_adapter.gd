extends SceneTree

func _initialize() -> void:
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	if warrior_scene == null:
		push_error("WarriorEnemy scene should load")
		quit(1)
		return

	var warrior: Node = warrior_scene.instantiate()
	get_root().add_child(warrior)
	await process_frame

	var sprite: AnimatedSprite2D = warrior.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("Warrior should create AnimatedSprite2D frames")
		quit(1)
		return

	var frames: SpriteFrames = sprite.sprite_frames
	if frames.get_frame_count("attack") != 7:
		push_error("Warrior attack should use teammate tscn's 7 attack frames")
		quit(1)
		return
	if not frames.has_animation("thrust") or frames.get_frame_count("thrust") != 8:
		push_error("Warrior thrust should use teammate tscn's 8-frame chase thrust animation")
		quit(1)
		return

	var frame_5: AtlasTexture = frames.get_frame_texture("attack", 4) as AtlasTexture
	var frame_6: AtlasTexture = frames.get_frame_texture("attack", 5) as AtlasTexture
	var frame_7: AtlasTexture = frames.get_frame_texture("attack", 6) as AtlasTexture
	if frame_5 == null or frame_6 == null or frame_7 == null:
		push_error("Warrior attack frames should be AtlasTextures")
		quit(1)
		return

	if frame_5.region != Rect2(373.0, 0.0, 122.0, 96.0):
		push_error("Warrior attack frame 5 should use attack1.png's corrected wide slash region")
		quit(1)
		return
	if frame_6.region != Rect2(525.0, 0.0, 102.0, 96.0):
		push_error("Warrior attack frame 6 should use attack1.png's corrected follow-through region")
		quit(1)
		return
	if frame_7.region != Rect2(651.0, 0.0, 93.0, 96.0):
		push_error("Warrior attack frame 7 should use attack1.png's corrected recovery region")
		quit(1)
		return

	var frame_5_path: String = frame_5.atlas.resource_path
	if not frame_5_path.ends_with("assets/sprites/warrior/attack1.png"):
		push_error("Warrior attack corrected frames should read attack1.png")
		quit(1)
		return

	var thrust_frame_4: AtlasTexture = frames.get_frame_texture("thrust", 3) as AtlasTexture
	var thrust_frame_5: AtlasTexture = frames.get_frame_texture("thrust", 4) as AtlasTexture
	var thrust_frame_6: AtlasTexture = frames.get_frame_texture("thrust", 5) as AtlasTexture
	var thrust_frame_7: AtlasTexture = frames.get_frame_texture("thrust", 6) as AtlasTexture
	if thrust_frame_4 == null or thrust_frame_5 == null or thrust_frame_6 == null or thrust_frame_7 == null:
		push_error("Warrior thrust corrected frames should be AtlasTextures")
		quit(1)
		return
	if thrust_frame_4.region != Rect2(282.0, 0.0, 141.0, 96.0):
		push_error("Warrior thrust frame 4 should match teammate tscn wide thrust1 crop")
		quit(1)
		return
	if thrust_frame_5.region != Rect2(360.0, 0.0, 180.0, 96.0):
		push_error("Warrior thrust frame 5 should match teammate tscn longest thrust2 crop")
		quit(1)
		return
	if thrust_frame_6.region != Rect2(474.0, 0.0, 158.0, 96.0):
		push_error("Warrior thrust frame 6 should match teammate tscn thrust1 follow-through crop")
		quit(1)
		return
	if thrust_frame_7.region != Rect2(545.0, 0.0, 109.0, 96.0):
		push_error("Warrior thrust frame 7 should match teammate tscn thrust2 recovery crop")
		quit(1)
		return

	warrior.queue_free()
	await process_frame
	quit(0)
