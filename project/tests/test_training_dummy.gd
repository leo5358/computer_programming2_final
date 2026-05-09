extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var dummy_scene: PackedScene = load("res://scenes/TrainingDummy.tscn")
	if player_scene == null or dummy_scene == null:
		push_error("Player and training dummy scenes should load")
		quit(1)
		return

	var player = player_scene.instantiate()
	var dummy = dummy_scene.instantiate()
	get_root().add_child(player)
	get_root().add_child(dummy)
	player.global_position = Vector2(160, 408)
	dummy.global_position = Vector2(96, 408)
	player.facing = -1.0
	await process_frame
	await physics_frame

	if not dummy is CharacterBody2D:
		push_error("Training dummy should be a CharacterBody2D so it can be knocked back")
		quit(1)
		return

	player._apply_attack_hit()
	if dummy.hit_count != 1:
		push_error("Training dummy should receive player attack hits")
		quit(1)
		return
	if dummy.velocity.x >= 0.0:
		push_error("Training dummy should be knocked away from the player when hit")
		quit(1)
		return
	if not player.attack_sfx.playing:
		push_error("Hitting training dummy should trigger hit attack audio")
		quit(1)
		return
	if not player.has_node("HitImpactVfx"):
		push_error("Player should have a visible hit impact VFX node")
		quit(1)
		return
	var hit_vfx := player.get_node("HitImpactVfx") as Node2D
	if not hit_vfx.visible:
		push_error("Hitting training dummy should show hit impact VFX")
		quit(1)
		return
	var hit_sprite := hit_vfx as AnimatedSprite2D
	if hit_sprite.sprite_frames == null or not hit_sprite.sprite_frames.has_animation("hit"):
		push_error("Hit impact VFX should use the generated spritesheet animation")
		quit(1)
		return

	player.heartbeat = 120.0
	player._apply_attack_hit()
	if abs(dummy.last_damage - 24.0) > 0.001:
		push_error("High heartbeat should increase player attack health damage")
		quit(1)
		return
	if abs(dummy.last_posture_damage - 25.2) > 0.001:
		push_error("High heartbeat should increase player attack posture damage")
		quit(1)
		return

	player.set_physics_process(false)
	dummy.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	dummy.queue_free()
	await process_frame
	quit(0)
