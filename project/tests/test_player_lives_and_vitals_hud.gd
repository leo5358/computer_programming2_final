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

	if int(player.get("lives")) != 2:
		push_error("Player should start with two lives")
		quit(1)
		return
	if hud.get_node_or_null("Root/Life3") != null:
		push_error("Vitals HUD should only build two death icons")
		quit(1)
		return

	player.receive_enemy_attack(999.0, 0.0, null)
	await process_frame
	if int(player.get("lives")) != 2:
		push_error("First depleted HP bar should not consume a life until revive is confirmed")
		quit(1)
		return
	if float(player.get("health")) > 0.0:
		push_error("First depleted HP bar should leave the player at zero HP while waiting for revive")
		quit(1)
		return
	if player._state_name() == "DEAD":
		pass
	else:
		push_error("Player should enter the death animation while revive lives remain")
		quit(1)
		return
	if player.current_animation != "death":
		push_error("Revive-eligible defeat should use the death animation")
		quit(1)
		return
	if not player.has_method("is_waiting_for_revive") or not player.is_waiting_for_revive():
		push_error("Player should report waiting for revive while extra lives remain")
		quit(1)
		return

	var life2 := hud.get_node_or_null("Root/Life2") as TextureRect
	if life2 == null or not life2.visible:
		push_error("Vitals HUD should keep all life icons visible until revive is confirmed")
		quit(1)
		return

	if not player.has_method("revive_in_place") or not player.revive_in_place():
		push_error("Player should support in-place revive while waiting for revive")
		quit(1)
		return
	if int(player.get("lives")) != 1:
		push_error("Reviving in place should consume one life")
		quit(1)
		return
	if float(player.get("health")) != float(player.get("max_health")):
		push_error("Reviving in place should refill HP")
		quit(1)
		return
	if int(player.get("heartbeat")) != 70:
		push_error("Reviving in place should reset heartbeat to 70")
		quit(1)
		return

	player.receive_enemy_attack(999.0, 0.0, null)
	await physics_frame
	if player._state_name() != "DEAD":
		push_error("Player should enter final death when both lives are consumed")
		quit(1)
		return
	if player.has_method("is_waiting_for_revive") and player.is_waiting_for_revive():
		push_error("Player should not wait for revive after the final life is gone")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
