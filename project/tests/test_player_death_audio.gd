extends SceneTree

class TestBgmPlayer:
	extends Node

	var fade_calls := 0
	var last_duration := 0.0

	func _init() -> void:
		add_to_group("bgm_player")

	func fade_out_bgm(duration: float = 1.0) -> void:
		fade_calls += 1
		last_duration = duration

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if player_scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var bgm := TestBgmPlayer.new()
	get_root().add_child(bgm)
	var player = player_scene.instantiate()
	get_root().add_child(player)
	await process_frame

	player.lives = 1
	player.receive_enemy_attack(999.0, 0.0, null)
	if bgm.fade_calls != 1:
		push_error("Player death should fade out BGM exactly once")
		quit(1)
		return
	if not is_equal_approx(bgm.last_duration, 1.5):
		push_error("Player death should use the teammate BGM fade duration")
		quit(1)
		return
	if player.death_sfx.volume_db > -70.0:
		push_error("Player death SFX should start from a fade-in volume")
		quit(1)
		return
	player.begin_local_hitstop(0.2)
	player._physics_process(0.1)
	if is_equal_approx(player.sprite.speed_scale, 0.0):
		push_error("Player death animation should not be frozen by hitstop applied after the killing blow")
		quit(1)
		return
	player.reset_combat_state()
	player.force_death_for_debug()
	if player.health > 0.0:
		push_error("Debug death helper should force player HP to zero")
		quit(1)
		return

	player.queue_free()
	bgm.queue_free()
	await process_frame
	quit(0)
