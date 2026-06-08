extends SceneTree

const REQUIRED_ANIMATIONS := [
	"idle",
	"walk",
	"attack",
	"attack2",
	"thrust",
	"chop",
	"deflect1",
	"deflect2",
	"hurt",
	"death",
]

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Boss.tscn")
	if scene == null:
		push_error("Boss scene should load")
		quit(1)
		return

	var boss: Node = scene.instantiate()
	get_root().add_child(boss)
	await process_frame

	if not boss.is_in_group("boss"):
		push_error("Boss should register itself in the boss group")
		quit(1)
		return
	if boss.health != 400.0 or boss.posture != 0.0 or boss.defeated_flag:
		push_error("Boss V0 should start with clean combat stats")
		quit(1)
		return

	var sprite: AnimatedSprite2D = boss.get_node("AnimatedSprite2D")
	if sprite.position != Vector2(0.0, -64.0):
		push_error("Boss sprite origin should use a 128x128 cell with feet at the node origin")
		quit(1)
		return
	if sprite.sprite_frames == null:
		push_error("Boss should build SpriteFrames from boss sprites")
		quit(1)
		return

	var expected_counts := {
		"idle": 8,
		"walk": 8,
		"attack": 8,
		"attack2": 16,
		"thrust": 8,
		"chop": 11,
		"deflect1": 8,
		"deflect2": 8,
		"hurt": 8,
		"death": 8,
	}
	var expected_speeds := {
		"idle": 4.0,
		"walk": 4.0,
		"attack": 6.0,
		"attack2": 5.0,
		"thrust": 5.0,
		"chop": 5.0,
		"deflect1": 5.0,
		"deflect2": 5.0,
		"hurt": 5.0,
		"death": 5.0,
	}
	for animation in REQUIRED_ANIMATIONS:
		if not sprite.sprite_frames.has_animation(animation):
			push_error("Boss missing animation: %s" % animation)
			quit(1)
			return
		if sprite.sprite_frames.get_frame_count(animation) != int(expected_counts[animation]):
			push_error("Boss animation frame count should match teammate settings: %s" % animation)
			quit(1)
			return
		if not is_equal_approx(sprite.sprite_frames.get_animation_speed(animation), float(expected_speeds[animation])):
			push_error("Boss animation speed should match teammate settings: %s" % animation)
			quit(1)
			return
	var walk_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture("walk", 0)
	if walk_texture.region != Rect2(0.0, 0.0, 125.0, 128.0):
		push_error("Boss walk atlas regions should match teammate settings")
		quit(1)
		return
	var attack_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture("attack", 4)
	if attack_texture.region != Rect2(532.0, 0.0, 133.0, 128.0):
		push_error("Boss attack atlas regions should match teammate settings")
		quit(1)
		return
	var chop_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture("chop", 5)
	if chop_texture.region != Rect2(687.0, 0.0, 132.0, 128.0):
		push_error("Boss chop atlas regions should match teammate settings")
		quit(1)
		return
	var chop_recovery_frame: AtlasTexture = sprite.sprite_frames.get_frame_texture("chop", 10)
	if chop_recovery_frame.region != Rect2(940.0, 0.0, 84.0, 128.0):
		push_error("Boss chop recovery should use the final frame 8 crop")
		quit(1)
		return
	var thrust_texture: AtlasTexture = sprite.sprite_frames.get_frame_texture("thrust", 4)
	if thrust_texture.region != Rect2(0.0, 0.0, 144.0, 128.0):
		push_error("Boss thrust atlas regions should include teammate thrust copy frames")
		quit(1)
		return

	var before_position: Vector2 = boss.global_position
	boss.play_boss_animation("walk")
	var first_walk_offset_x := 0.0
	boss.facing = 1.0
	for frame in 8:
		sprite.frame = frame
		boss.align_sprite_to_ground()
		if frame == 0:
			first_walk_offset_x = sprite.offset.x
		elif abs(sprite.offset.x - first_walk_offset_x) < 1.0:
			push_error("Boss walk frames should use horizontal visual anchoring to prevent loop snapping")
			quit(1)
			return
		if boss.global_position != before_position:
			push_error("Changing Boss animation frames should not move the body")
			quit(1)
			return
	var right_facing_offset_x := sprite.offset.x
	boss.facing = -1.0
	boss.align_sprite_to_ground()
	if not is_equal_approx(sprite.offset.x, -right_facing_offset_x):
		push_error("Boss walk anchoring should mirror with facing direction")
		quit(1)
		return

	boss.play_boss_animation("chop")
	sprite.frame = 4
	boss.align_sprite_to_ground()
	if sprite.offset.y > -80.0:
		push_error("Boss chop airborne frames should visually lift the Boss well above the player")
		quit(1)
		return

	if boss.can_be_perfect_dodged_by(null):
		push_error("Boss V0 should not expose perfect dodge windows before attacks are rebuilt")
		quit(1)
		return

	boss.guard_chance = 0.0
	var boss_health_before_hit: float = boss.health
	boss.receive_player_attack(1.0, 1.0)
	if boss.health >= boss_health_before_hit:
		push_error("Boss should take direct player attack damage")
		quit(1)
		return
	var first_boss_hurt_alpha: float = sprite.modulate.a
	if first_boss_hurt_alpha >= 0.95:
		push_error("Boss should start a visible hit flicker when directly hit")
		quit(1)
		return
	if sprite.modulate.r > 1.05 or sprite.modulate.g > 1.05 or sprite.modulate.b > 1.05:
		push_error("Boss hit flicker should dim like the player instead of being hidden by an overbright flash")
		quit(1)
		return
	boss._physics_process(0.08)
	if is_equal_approx(sprite.modulate.a, first_boss_hurt_alpha):
		push_error("Boss hit flicker should alternate opacity while hurt feedback is active")
		quit(1)
		return

	boss.queue_free()
	await process_frame
	quit(0)
