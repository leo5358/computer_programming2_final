extends SceneTree

class SmokeBoss:
	extends Node2D

	var pause_duration := 0.0

	func _init() -> void:
		add_to_group("boss")

	func receive_smoke_bomb_pause(duration: float) -> void:
		pause_duration = duration

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player: Node = scene.instantiate()
	get_root().add_child(player)
	await process_frame
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("Player should build item action animations")
		quit(1)
		return
	for animation_name in ["eat", "mudra", "throw"]:
		if not sprite.sprite_frames.has_animation(animation_name):
			push_error("Player should load %s animation for item use" % animation_name)
			quit(1)
			return
	var mudra_total_duration_weight := 0.0
	for index in sprite.sprite_frames.get_frame_count("mudra"):
		mudra_total_duration_weight += sprite.sprite_frames.get_frame_duration("mudra", index)
	if not is_equal_approx(mudra_total_duration_weight, float(sprite.sprite_frames.get_frame_count("mudra"))):
		push_error("Mudra duration weights should preserve the original total animation length")
		quit(1)
		return
	var mudra_focus_duration_weight := 0.0
	for index in [3, 4, 5]:
		mudra_focus_duration_weight += sprite.sprite_frames.get_frame_duration("mudra", index)
	if not is_equal_approx(mudra_focus_duration_weight / mudra_total_duration_weight, 0.7):
		push_error("Mudra frames 4/5/6 should occupy 70 percent of the animation duration")
		quit(1)
		return

	for item_id in ["gourd", "kunai", "pill", "capsule", "ash_balls"]:
		if not player.has_method("get_item_count"):
			push_error("Player should expose item counts")
			quit(1)
			return
		if player.get_item_count(item_id) != 10:
			push_error("Player should start with 10 %s" % item_id)
			quit(1)
			return

	if not player.has_method("use_item"):
		push_error("Player should expose item use")
		quit(1)
		return
	if not player.use_item("gourd"):
		push_error("Gourd should be usable")
		quit(1)
		return
	if player.get_item_count("gourd") != 9:
		push_error("Using gourd should consume one count")
		quit(1)
		return
	if float(player.get("max_health")) <= 100.0:
		push_error("Gourd expansion should increase max health")
		quit(1)
		return
	if player.velocity != Vector2.ZERO:
		push_error("Using an eat item should stop movement")
		quit(1)
		return
	if player.get_current_animation() != "eat":
		push_error("Using gourd/pill/capsule should play eat animation")
		quit(1)
		return
	if not is_equal_approx(float(player.get("action_timer")), 0.8):
		push_error("Using an eat item should lock the player for about 0.8 seconds")
		quit(1)
		return
	if player.is_action_locked():
		for frame in 120:
			await process_frame
			if not player.is_action_locked():
				break
	if player.is_action_locked():
		push_error("Eat item action should finish after mudra animation")
		quit(1)
		return

	var base_heartbeat := float(player.get("heartbeat"))
	if not player.use_item("capsule"):
		push_error("Adrenaline capsule should be usable")
		quit(1)
		return
	if player.get_current_animation() != "eat" or not is_equal_approx(float(player.get("action_timer")), 0.8):
		push_error("Adrenaline capsule should use the 0.8s eat animation")
		quit(1)
		return
	if float(player.get("heartbeat")) <= base_heartbeat:
		push_error("Adrenaline capsule should raise heartbeat")
		quit(1)
		return
	player.set("action_timer", 0.0)
	player._update_action_state(0.01)
	var raised_heartbeat := float(player.get("heartbeat"))
	if not player.use_item("pill"):
		push_error("Blood pressure pill should be usable")
		quit(1)
		return
	if player.get_current_animation() != "eat" or not is_equal_approx(float(player.get("action_timer")), 0.8):
		push_error("Blood pressure pill should use the 0.8s eat animation")
		quit(1)
		return
	if float(player.get("heartbeat")) >= raised_heartbeat:
		push_error("Blood pressure pill should lower heartbeat")
		quit(1)
		return
	player.set("action_timer", 0.0)
	player._update_action_state(0.01)

	var boss := SmokeBoss.new()
	get_root().add_child(boss)
	boss.global_position = player.global_position + Vector2(32.0, 0.0)
	if not player.use_item("ash_balls"):
		push_error("Smoke bomb should be usable")
		quit(1)
		return
	if player.get_current_animation() != "throw" or not is_equal_approx(float(player.get("action_timer")), 0.8):
		push_error("Smoke bomb should use the 0.8s throw animation")
		quit(1)
		return
	await process_frame
	var ash_ball: Node = null
	for projectile in get_nodes_in_group("player_projectile"):
		if projectile.get_script() != null and String(projectile.get_script().resource_path).ends_with("ash_ball_projectile.gd"):
			ash_ball = projectile
			break
	if ash_ball == null:
		push_error("Smoke bomb should spawn a thrown ash ball projectile")
		quit(1)
		return
	var ash_sprite := ash_ball.get_node_or_null("Sprite2D") as Sprite2D
	if ash_sprite == null or ash_sprite.texture == null or ash_sprite.texture.resource_path != "res://assets/items/ash_balls/ash_ball_throwed.png":
		push_error("Thrown ash ball should use ash_ball_throwed.png")
		quit(1)
		return
	(ash_ball as Node2D).global_position = boss.global_position
	ash_ball.explode()
	if boss.pause_duration <= 0.0:
		push_error("Smoke bomb should pause boss actions")
		quit(1)
		return
	player.set("action_timer", 0.0)
	player._update_action_state(0.01)

	if not player.use_item("kunai"):
		push_error("Kunai should be throwable")
		quit(1)
		return
	if player.get_current_animation() != "mudra" or not is_equal_approx(float(player.get("action_timer")), 0.8):
		push_error("Kunai should use the 0.8s mudra animation")
		quit(1)
		return
	if player.get_item_count("kunai") != 9:
		push_error("Throwing kunai should consume one count")
		quit(1)
		return
	var active_kunai: Node2D = player.get("active_teleport_kunai") as Node2D
	if active_kunai == null:
		push_error("Thrown kunai should become a teleport anchor")
		quit(1)
		return
	var kunai_sprite := active_kunai.get_node_or_null("Sprite2D") as Sprite2D
	if kunai_sprite == null or kunai_sprite.position.y >= -10.0:
		push_error("Thrown kunai sprite should be lifted above its collision/teleport anchor")
		quit(1)
		return
	active_kunai.global_position = Vector2(321.0, 123.0)
	if not player.use_item("kunai"):
		push_error("Using kunai again should teleport to the active kunai")
		quit(1)
		return
	var kunai_sfx := player.get_node_or_null("KunaiSfx") as AudioStreamPlayer2D
	if kunai_sfx == null or kunai_sfx.stream == null:
		push_error("Player should include kunai teleport SFX")
		quit(1)
		return
	if kunai_sfx.stream.resource_path != "res://assets/sfx/kunai.MP3":
		push_error("Kunai teleport SFX should use assets/sfx/kunai.MP3")
		quit(1)
		return
	if not kunai_sfx.playing:
		push_error("Teleporting to kunai should play kunai SFX")
		quit(1)
		return
	if player.get_item_count("kunai") != 9:
		push_error("Teleporting to kunai should not consume another count")
		quit(1)
		return
	if player.global_position != Vector2(321.0, 123.0):
		push_error("Player should teleport to the active kunai position")
		quit(1)
		return

	player.queue_free()
	boss.queue_free()
	await process_frame
	quit(0)
