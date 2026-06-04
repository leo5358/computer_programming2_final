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
		push_error("Warrior should create sprite frames")
		quit(1)
		return

	var frames: SpriteFrames = sprite.sprite_frames
	if not frames.has_animation("walk"):
		push_error("Warrior should load teammate tscn walk animation")
		quit(1)
		return
	if frames.get_frame_count("walk") != 9:
		push_error("Warrior walk should use teammate tscn's 9 walk frames")
		quit(1)
		return

	var first_walk_frame: AtlasTexture = frames.get_frame_texture("walk", 0) as AtlasTexture
	var fourth_walk_frame: AtlasTexture = frames.get_frame_texture("walk", 3) as AtlasTexture
	var last_walk_frame: AtlasTexture = frames.get_frame_texture("walk", 8) as AtlasTexture
	if first_walk_frame == null or fourth_walk_frame == null or last_walk_frame == null:
		push_error("Warrior walk frames should be AtlasTextures")
		quit(1)
		return
	if first_walk_frame.region != Rect2(12.0, 0.0, 96.0, 96.0):
		push_error("Warrior walk frame 1 should match teammate tscn region")
		quit(1)
		return
	if fourth_walk_frame.region != Rect2(572.0, 0.0, 94.0, 96.0):
		push_error("Warrior walk frame 4 should match teammate tscn's non-linear frame order")
		quit(1)
		return
	if last_walk_frame.region != Rect2(666.0, 0.0, 94.0, 96.0):
		push_error("Warrior walk frame 9 should match teammate tscn region")
		quit(1)
		return

	if not frames.has_animation("deflect"):
		push_error("Warrior should load teammate tscn deflect animation")
		quit(1)
		return
	if frames.get_frame_count("deflect") != 7:
		push_error("Warrior deflect should use teammate tscn's 7 deflect frames")
		quit(1)
		return

	var first_deflect_frame: AtlasTexture = frames.get_frame_texture("deflect", 0) as AtlasTexture
	var third_deflect_frame: AtlasTexture = frames.get_frame_texture("deflect", 2) as AtlasTexture
	if first_deflect_frame == null or third_deflect_frame == null:
		push_error("Warrior deflect frames should be AtlasTextures")
		quit(1)
		return
	if first_deflect_frame.region != Rect2(9.0, 0.0, 94.0, 96.0):
		push_error("Warrior deflect frame 1 should match teammate tscn region")
		quit(1)
		return
	if third_deflect_frame.region != Rect2(289.0, 0.0, 92.0, 96.0):
		push_error("Warrior deflect frame 3 should match teammate tscn's non-uniform cut")
		quit(1)
		return

	warrior.guard_chance = 1.0
	warrior.state = warrior.EnemyState.HOLD
	var health_before: float = warrior.health
	var posture_before: float = warrior.posture
	var result: Variant = warrior.receive_player_attack(20.0, 18.0)
	if result is bool and result == false:
		push_error("Guarded Warrior hit should still count as attack contact")
		quit(1)
		return
	if not (result is Dictionary and bool(result.get("guarded", false))):
		push_error("Guarded Warrior hit should report guarded contact to the player")
		quit(1)
		return
	if warrior.health != health_before:
		push_error("Successful Warrior guard should prevent health damage")
		quit(1)
		return
	if warrior.posture <= posture_before:
		push_error("Successful Warrior guard should still add small posture pressure")
		quit(1)
		return
	if warrior.posture - posture_before > 4.0:
		push_error("Successful Warrior guard should not let the player farm large posture damage")
		quit(1)
		return
	if warrior.state != warrior.EnemyState.DEFLECT:
		push_error("Successful Warrior guard should enter DEFLECT state")
		quit(1)
		return
	if warrior.guard_lockout_timer < 0.4:
		push_error("Successful Warrior guard should start a lockout before it can guard again")
		quit(1)
		return
	warrior._update_visuals()
	if sprite.animation != "deflect":
		push_error("Successful Warrior guard should play deflect animation")
		quit(1)
		return

	warrior.reset_combat_state()
	warrior.guard_chance = 1.0
	warrior.guard_lockout_timer = 0.2
	health_before = warrior.health
	warrior.receive_player_attack(20.0, 18.0)
	if warrior.health >= health_before:
		push_error("Warrior should not guard again during guard lockout")
		quit(1)
		return

	warrior.reset_combat_state()
	warrior.guard_chance = 1.0
	warrior.state = warrior.EnemyState.ATTACK
	warrior.attack_elapsed = warrior.attack_cue_start
	health_before = warrior.health
	warrior.receive_player_attack(20.0, 18.0)
	if warrior.health != health_before or warrior.state != warrior.EnemyState.DEFLECT:
		push_error("Warrior should be able to guard during attack windup")
		quit(1)
		return

	warrior.reset_combat_state()
	warrior.guard_chance = 1.0
	warrior.state = warrior.EnemyState.ATTACK
	warrior.attack_elapsed = warrior.attack_hit_start
	health_before = warrior.health
	warrior.receive_player_attack(20.0, 18.0)
	if warrior.health >= health_before:
		push_error("Warrior should not guard during active attack hit frames")
		quit(1)
		return

	warrior.queue_free()
	await process_frame
	quit(0)
