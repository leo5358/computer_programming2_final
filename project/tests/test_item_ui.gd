extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main: Node = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	var item_ui: Node = main.get_node_or_null("ItemUI")
	if item_ui == null:
		push_error("Main scene should include an ItemUI node")
		quit(1)
		return
	if not item_ui.has_method("get_display_count") or not item_ui.has_method("get_visible_item_id"):
		push_error("ItemUI should expose counts and visible slot items")
		quit(1)
		return

	var strip := item_ui.get_node_or_null("Root/ItemStrip") as Control
	if strip == null:
		push_error("ItemUI should expose a two-slot item strip")
		quit(1)
		return
	var heal_slot := strip.get_node_or_null("HealSlot") as Control
	var attack_slot := strip.get_node_or_null("AttackSlot") as Control
	if heal_slot == null or attack_slot == null:
		push_error("ItemUI should only create one heal slot and one attack slot")
		quit(1)
		return
	if strip.get_child_count() != 2:
		push_error("ItemUI should only display two slots")
		quit(1)
		return

	if item_ui.get_visible_item_id("attack") != "kunai":
		push_error("Attack slot should default to kunai")
		quit(1)
		return
	if item_ui.get_visible_item_id("heal") != "gourd":
		push_error("Heal slot should default to gourd")
		quit(1)
		return

	var attack_icon := attack_slot.get_node_or_null("Icon") as TextureRect
	var heal_icon := heal_slot.get_node_or_null("Icon") as TextureRect
	if attack_icon == null or heal_icon == null:
		push_error("ItemUI slots should expose icons")
		quit(1)
		return
	if attack_icon.texture == null or not attack_icon.texture.resource_path.ends_with("assets/items/kunai/kunai.png"):
		push_error("Attack slot should show the kunai icon by default")
		quit(1)
		return
	if heal_icon.texture == null or not heal_icon.texture.resource_path.ends_with("assets/items/gourd/gourd.png"):
		push_error("Heal slot should show the gourd icon by default")
		quit(1)
		return

	var player: Node = main.get_node_or_null("Player")
	if player == null or not player.has_method("use_item"):
		push_error("Main scene should include a usable player")
		quit(1)
		return

	player.set("selected_attack_item_index", 1)
	player.set("selected_heal_item_index", 2)
	player.emit_signal("stats_changed")
	await process_frame

	if item_ui.get_visible_item_id("attack") != "ash_balls":
		push_error("Attack slot should switch to ash_balls when attack category changes")
		quit(1)
		return
	if item_ui.get_visible_item_id("heal") != "capsule":
		push_error("Heal slot should switch to capsule when heal category changes")
		quit(1)
		return
	if attack_icon.texture == null or not attack_icon.texture.resource_path.ends_with("assets/items/ash_balls/ash_balls.png"):
		push_error("Attack slot icon should update with the selected attack item")
		quit(1)
		return
	if heal_icon.texture == null or not heal_icon.texture.resource_path.ends_with("assets/items/capsule/capsule.png"):
		push_error("Heal slot icon should update with the selected heal item")
		quit(1)
		return

	if not player.has_method("use_selected_heal_item") or not player.use_selected_heal_item():
		push_error("Heal category use should consume the selected heal item")
		quit(1)
		return
	await process_frame
	if item_ui.get_display_count("capsule") != 9:
		push_error("Heal slot should update the displayed count after use")
		quit(1)
		return

	player.set("action_timer", 0.0)
	player._update_action_state(0.01)
	if not player.has_method("use_selected_attack_item") or not player.use_selected_attack_item():
		push_error("Attack category use should consume the selected attack item")
		quit(1)
		return
	await process_frame
	if item_ui.get_display_count("ash_balls") != 9:
		push_error("Attack slot should update the displayed count after use")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
