extends SceneTree

const BLOOD_OVERLAY_PATH := "res://assets/sprites/vfx/blood.png"

class FakePlayer:
	extends Node2D
	signal stats_changed
	var heartbeat := 70.0

class FakeCamera:
	extends Node2D
	var shake_count := 0
	var last_amount := 0.0
	var last_duration := 0.0

	func shake(amount: float, duration: float) -> void:
		shake_count += 1
		last_amount = amount
		last_duration = duration

func _initialize() -> void:
	var feedback_script: Script = load("res://scripts/heartbeat_feedback.gd")
	if feedback_script == null:
		push_error("Heartbeat feedback script should load")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)
	var player := FakePlayer.new()
	player.add_to_group("player")
	root.add_child(player)
	var camera := FakeCamera.new()
	camera.add_to_group("feedback_camera")
	root.add_child(camera)
	var feedback: CanvasLayer = feedback_script.new()
	root.add_child(feedback)
	await process_frame

	var blood_overlay := feedback.get_node_or_null("Root/BloodOverlay") as TextureRect
	var heartbeat_sfx := feedback.get_node_or_null("HeartbeatSfx") as AudioStreamPlayer
	if blood_overlay == null:
		push_error("Heartbeat feedback should build a full-screen blood texture overlay")
		quit(1)
		return
	if blood_overlay.texture == null:
		push_error("Heartbeat feedback should always provide a blood overlay texture")
		quit(1)
		return
	if blood_overlay.texture.resource_path != "" and blood_overlay.texture.resource_path != BLOOD_OVERLAY_PATH:
		push_error("Heartbeat feedback should use the shared blood.png VFX asset or a runtime fallback from it")
		quit(1)
		return
	if heartbeat_sfx == null or heartbeat_sfx.stream == null:
		push_error("Heartbeat feedback should load the single heartbeat thump sound")
		quit(1)
		return

	player.heartbeat = 70.0
	feedback._update_feedback(0.0)
	var calm_alpha := blood_overlay.modulate.a
	if calm_alpha > 0.02:
		push_error("Calm heartbeat should keep the blood overlay almost invisible")
		quit(1)
		return

	player.heartbeat = 134.0
	feedback._update_feedback(0.0)
	if blood_overlay.modulate.a > 0.02:
		push_error("Heartbeat warning should stay invisible below 135 BPM")
		quit(1)
		return
	feedback._update_heartbeat_audio(0.0)
	if heartbeat_sfx.volume_db != feedback.min_volume_db:
		push_error("Heartbeat audio should stay at minimum volume below 135 BPM")
		quit(1)
		return

	player.heartbeat = 180.0
	feedback._update_feedback(0.0)
	var tense_alpha := blood_overlay.modulate.a
	if tense_alpha <= calm_alpha + 0.05:
		push_error("High heartbeat should visibly intensify the blood overlay")
		quit(1)
		return
	if camera.shake_count != 0:
		push_error("Heartbeat feedback should not shake the camera at or below 200 BPM")
		quit(1)
		return
	heartbeat_sfx.stop()
	if absf(feedback._beat_interval_for_heartbeat(180.0) - (60.0 / 180.0)) > 0.001:
		push_error("Heartbeat audio interval should follow 60 / BPM")
		quit(1)
		return

	player.heartbeat = 220.0
	feedback.heartbeat_timer = 0.0
	feedback._update_feedback(0.2)
	if camera.shake_count != 1:
		push_error("Heartbeat feedback should shake the camera once with the heartbeat thump above 200 BPM")
		quit(1)
		return
	if camera.last_amount <= 0.0 or camera.last_duration <= 0.0:
		push_error("Heartbeat camera shake should use a visible positive amount and duration")
		quit(1)
		return
	if feedback.heartbeat_timer <= 0.0:
		push_error("Heartbeat feedback should schedule the next thump after playing")
		quit(1)
		return
	if heartbeat_sfx.pitch_scale != 1.0:
		push_error("Heartbeat thump should keep the original audio pitch")
		quit(1)
		return
	if not feedback._can_play_heartbeat_thump():
		pass
	else:
		push_error("Heartbeat feedback should know that an already playing thump cannot be restarted")
		quit(1)
		return
	feedback.heartbeat_timer = 0.0
	feedback._update_feedback(0.2)
	if camera.shake_count != 1:
		push_error("Heartbeat camera shake should stay synced to actual thumps instead of replay checks")
		quit(1)
		return
	if heartbeat_sfx.volume_db >= -6.0:
		push_error("Heartbeat thump should stay mixed under combat audio")
		quit(1)
		return

	root.queue_free()
	await process_frame

	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	if main_scene == null:
		push_error("Main scene should load for heartbeat feedback integration")
		quit(1)
		return
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	var main_feedback := main.get_node_or_null("HeartbeatFeedback")
	if main_feedback == null:
		push_error("Main should include HeartbeatFeedback")
		quit(1)
		return
	var main_sfx := main_feedback.get_node_or_null("HeartbeatSfx") as AudioStreamPlayer
	if main_sfx == null or main_sfx.stream == null:
		push_error("Main HeartbeatFeedback should load heartbeat.MP3")
		quit(1)
		return
	main.queue_free()
	await process_frame
	quit(0)
