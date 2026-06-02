extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var hud_script: Script = load("res://scripts/player_vitals_hud.gd")
	if player_scene == null or hud_script == null:
		push_error("Player scene and vitals HUD script should load")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)
	var player = player_scene.instantiate()
	root.add_child(player)
	var hud: CanvasLayer = hud_script.new()
	root.add_child(hud)
	await process_frame

	if int(player.get("lives")) != 3:
		push_error("Player should start with three lives")
		quit(1)
		return

	player.receive_enemy_attack(999.0, 0.0, null)
	await process_frame
	if int(player.get("lives")) != 2:
		push_error("First depleted HP bar should consume one life")
		quit(1)
		return
	if float(player.get("health")) != float(player.get("max_health")):
		push_error("Consuming a life should refill HP")
		quit(1)
		return
	if player._state_name() == "DEAD":
		push_error("Player should not enter final death while lives remain")
		quit(1)
		return
	if player.current_animation != "life_knockdown_forward":
		push_error("Consuming a life should use the full life knockdown animation")
		quit(1)
		return

	var life2 := hud.get_node_or_null("Root/Life3") as TextureRect
	if life2 == null or life2.visible:
		push_error("Vitals HUD should hide one death icon after one life is consumed")
		quit(1)
		return

	player.action_timer = 0.0
	player._update_action_state(0.01)
	player.receive_enemy_attack(999.0, 0.0, null)
	player.action_timer = 0.0
	player._update_action_state(0.01)
	player.receive_enemy_attack(999.0, 0.0, null)
	await physics_frame
	if player._state_name() != "DEAD":
		push_error("Player should enter final death when all three lives are consumed")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
