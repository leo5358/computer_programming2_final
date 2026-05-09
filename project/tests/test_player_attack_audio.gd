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

	if player.attack_hit_streams.size() != 5:
		push_error("Player should load five random normal hit attack sounds")
		quit(1)
		return
	if player.chop_hit_stream == null:
		push_error("Player should load fixed chop hit sound")
		quit(1)
		return
	if player.attack_miss_streams.size() != 2:
		push_error("Player should load two random miss attack sounds")
		quit(1)
		return
	if player.dash_sfx.stream == null or player.dash_sfx.stream.resource_path != "res://assets/sfx/dodge.WAV":
		push_error("Dash should use dodge.WAV")
		quit(1)
		return

	player._start_attack()
	if player.attack_sfx.playing:
		push_error("Attack should wait for hit detection before playing hit or miss audio")
		quit(1)
		return

	player._apply_attack_hit()
	if not player.attack_sfx.playing:
		push_error("Missed attack should play a random miss sound")
		quit(1)
		return
	if not player.attack_sfx.stream.resource_path in [
		"res://assets/sfx/attack_miss1.WAV",
		"res://assets/sfx/attack_miss2.WAV",
	]:
		push_error("Missed attack should choose from attack_miss1 or attack_miss2")
		quit(1)
		return

	player.attack_sfx.stop()
	player._play_random_attack_hit_sfx()
	if not player.attack_sfx.playing:
		push_error("Hit attack should play a random hit sound")
		quit(1)
		return
	if not player.attack_sfx.stream.resource_path in [
		"res://assets/sfx/attack1.WAV",
		"res://assets/sfx/attack2.WAV",
		"res://assets/sfx/attack3.WAV",
		"res://assets/sfx/attack4.WAV",
		"res://assets/sfx/attack5.WAV",
	]:
		push_error("Normal hit attack should choose from attack1 through attack5")
		quit(1)
		return

	player.attack_sfx.stop()
	player.current_attack_animation = "attack_chop"
	player._play_random_attack_hit_sfx()
	if player.attack_sfx.stream.resource_path != "res://assets/sfx/attack6.WAV":
		push_error("Chop hit should always use attack6")
		quit(1)
		return

	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if not sprite.sprite_frames.has_animation("attack_chop"):
		push_error("Player should build chop attack animation")
		quit(1)
		return

	player.reset_combat_state()
	player._start_attack()
	if player.current_attack_animation != "attack_a":
		push_error("First attack in cycle should use attack animation")
		quit(1)
		return
	player.action_timer = 0.0
	player._update_action_state(0.0)
	player._start_attack()
	if player.current_attack_animation != "attack_a":
		push_error("Second attack in cycle should use attack animation")
		quit(1)
		return
	player.action_timer = 0.0
	player._update_action_state(0.0)
	player._start_attack()
	if player.current_attack_animation != "attack_chop":
		push_error("Third attack in cycle should use chop animation")
		quit(1)
		return

	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	await process_frame
	quit(0)
