extends SceneTree

class FakePlayer:
	extends Node2D
	signal stats_changed
	var heartbeat := 70.0

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
	var feedback: CanvasLayer = feedback_script.new()
	root.add_child(feedback)
	await process_frame

	var top_edge := feedback.get_node_or_null("Root/TopEdge") as ColorRect
	var bottom_edge := feedback.get_node_or_null("Root/BottomEdge") as ColorRect
	var heartbeat_sfx := feedback.get_node_or_null("HeartbeatSfx") as AudioStreamPlayer
	if top_edge == null or bottom_edge == null:
		push_error("Heartbeat feedback should build red screen edge overlays")
		quit(1)
		return
	if heartbeat_sfx == null or heartbeat_sfx.stream == null:
		push_error("Heartbeat feedback should load the single heartbeat thump sound")
		quit(1)
		return

	player.heartbeat = 70.0
	feedback._update_feedback(0.0)
	var calm_alpha := top_edge.color.a
	if calm_alpha > 0.02:
		push_error("Calm heartbeat should keep the red edge almost invisible")
		quit(1)
		return

	player.heartbeat = 180.0
	feedback._update_feedback(0.0)
	var tense_alpha := top_edge.color.a
	if tense_alpha <= calm_alpha + 0.18:
		push_error("High heartbeat should visibly intensify the red edge")
		quit(1)
		return
	if bottom_edge.color.a != top_edge.color.a:
		push_error("All heartbeat edge overlays should share the same intensity")
		quit(1)
		return
	if absf(feedback._beat_interval_for_heartbeat(180.0) - (60.0 / 180.0)) > 0.001:
		push_error("Heartbeat audio interval should follow 60 / BPM")
		quit(1)
		return

	player.heartbeat = 220.0
	feedback.heartbeat_timer = 0.0
	feedback._update_feedback(0.2)
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
