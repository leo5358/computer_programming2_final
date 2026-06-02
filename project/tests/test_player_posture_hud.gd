extends SceneTree

class FakePlayer:
	extends Node
	signal stats_changed
	var posture := 0.0
	var max_posture := 100.0

func _initialize() -> void:
	var hud_script: Script = load("res://scripts/player_posture_hud.gd")
	if hud_script == null:
		push_error("Player posture HUD script should load")
		quit(1)
		return

	var fake_player := FakePlayer.new()
	fake_player.add_to_group("player")
	get_root().add_child(fake_player)
	var hud: CanvasLayer = hud_script.new()
	get_root().add_child(hud)
	await process_frame

	var frame := hud.get_node_or_null("Root/Frame") as TextureRect
	var track := hud.get_node_or_null("Root/Track") as ColorRect
	var left_fill := hud.get_node_or_null("Root/LeftFill") as ColorRect
	var right_fill := hud.get_node_or_null("Root/RightFill") as ColorRect
	if frame == null or track == null or left_fill == null or right_fill == null:
		push_error("Player posture HUD should create frame and center-fill nodes")
		quit(1)
		return
	if frame.texture == null:
		push_error("Player posture HUD should use menu_selector.png as its frame")
		quit(1)
		return
	if not is_equal_approx(frame.rotation_degrees, 0.0):
		push_error("Player posture HUD frame should stay horizontal without rotation")
		quit(1)
		return
	if not is_equal_approx(frame.size.x, hud.bar_size.x) or not is_equal_approx(frame.size.y, hud.bar_size.y):
		push_error("Player posture HUD frame should use the configured horizontal bar size")
		quit(1)
		return

	fake_player.posture = 50.0
	fake_player.emit_signal("stats_changed")
	await process_frame
	if not is_equal_approx(left_fill.size.x, right_fill.size.x):
		push_error("Player posture HUD should fill equally from center to both sides")
		quit(1)
		return
	if not is_equal_approx(left_fill.size.x + right_fill.size.x, track.size.x * 0.5):
		push_error("Player posture HUD should fill half the bar at 50 posture")
		quit(1)
		return

	fake_player.posture = 100.0
	fake_player.emit_signal("stats_changed")
	await process_frame
	if not is_equal_approx(left_fill.size.x + right_fill.size.x, track.size.x):
		push_error("Player posture HUD should fill the full bar at max posture")
		quit(1)
		return

	hud.queue_free()
	fake_player.queue_free()
	await process_frame
	quit(0)
