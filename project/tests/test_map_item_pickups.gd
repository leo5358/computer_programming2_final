extends SceneTree

const AB_EXPECTED := [
	{"position": Vector2(1515.0, 571.0), "item_id": "gourd"},
	{"position": Vector2(2626.0, 475.0), "item_id": "pill"},
	{"position": Vector2(3886.0, 80.0), "item_id": "ash_balls"},
	{"position": Vector2(3791.0, 624.2), "item_id": "capsule"},
	{"position": Vector2(5243.2, 39.4), "item_id": "gourd"},
	{"position": Vector2(6910.1, 74.4), "item_id": "kunai"},
	{"position": Vector2(7649.7, 627.7), "item_id": "kunai"},
	{"position": Vector2(9381.7, -306.4), "item_id": "ash_balls"},
	{"position": Vector2(10692.4, 2.6), "item_id": "capsule"},
	{"position": Vector2(13964.3, 73.8), "item_id": "pill"},
]
const PLAZA_EXPECTED := [
	{"position": Vector2(835.1, 530.5), "item_id": "gourd"},
	{"position": Vector2(1088.2, 530.5), "item_id": "pill"},
	{"position": Vector2(1330.2, 530.5), "item_id": "capsule"},
	{"position": Vector2(1593.0, 530.5), "item_id": "ash_balls"},
	{"position": Vector2(523.7, 530.5), "item_id": "kunai"},
]

func _initialize() -> void:
	await _validate_pickup_scene()
	await _validate_map_pickups("res://scenes/maps/chapter1_ab_foothill_stairs.tscn", AB_EXPECTED)
	await _validate_map_pickups("res://scenes/maps/chapter1_h_stone_plaza.tscn", PLAZA_EXPECTED)
	await _validate_main_pickup_flow()
	quit(0)

func _validate_pickup_scene() -> void:
	var pickup_scene: PackedScene = load("res://scenes/MapItemPickup.tscn")
	if pickup_scene == null:
		push_error("Map item pickup scene should load")
		quit(1)
		return
	var pickup := pickup_scene.instantiate()
	get_root().add_child(pickup)
	await process_frame
	if not pickup.is_in_group("map_item_pickup"):
		push_error("Map item pickup should be in map_item_pickup group")
		quit(1)
		return
	if not pickup.has_method("is_player_in_range") or not pickup.has_method("collect"):
		push_error("Map item pickup should expose range and collect APIs")
		quit(1)
		return
	var sprite := pickup.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null or sprite.texture.resource_path != "res://assets/items/bag/bag.png":
		push_error("Map item pickup should render with the shared bag.png art")
		quit(1)
		return
	if not is_equal_approx(sprite.scale.x, (0.55 / 30.0) * 8.0) or not is_equal_approx(sprite.scale.y, (0.55 / 30.0) * 8.0):
		push_error("Map item pickup bag art should be 8 times larger than the tiny 0.55 / 30 scale")
		quit(1)
		return
	pickup.queue_free()
	await process_frame

func _validate_map_pickups(scene_path: String, expected: Array) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("%s should load" % scene_path)
		quit(1)
		return
	var map: Node = scene.instantiate()
	get_root().add_child(map)
	await process_frame
	var pickup_root := map.get_node_or_null("ItemPickups")
	if pickup_root == null:
		push_error("%s should own ItemPickups" % scene_path)
		quit(1)
		return
	if pickup_root.get_child_count() != expected.size():
		push_error("%s should include %d item pickups" % [scene_path, expected.size()])
		quit(1)
		return
	for expected_pickup in expected:
		var found := false
		for child in pickup_root.get_children():
			var pickup := child as Node2D
			if pickup == null:
				continue
			if pickup.global_position.distance_to(expected_pickup["position"]) > 1.0:
				continue
			if String(pickup.get("item_id")) != String(expected_pickup["item_id"]):
				push_error("Pickup at %s should contain %s" % [expected_pickup["position"], expected_pickup["item_id"]])
				quit(1)
				return
			found = true
			break
		if not found:
			push_error("%s should include %s pickup at %s" % [scene_path, expected_pickup["item_id"], expected_pickup["position"]])
			quit(1)
			return
	map.queue_free()
	await process_frame

func _validate_main_pickup_flow() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return
	var main: Node = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	var player := main.get_node_or_null("Player") as Node2D
	var prompt := main.get_node_or_null("MapTransitionUI/PromptLabel") as Label
	var notice := main.get_node_or_null("MapTransitionUI/PickupNotice") as Control
	if player == null or prompt == null or notice == null:
		push_error("Main should include player, interaction prompt, and pickup notice")
		quit(1)
		return
	var pickup := main.get_node_or_null("Chapter1Map/ItemPickups/FoothillGourd01") as Node2D
	if pickup == null:
		push_error("AB foothill should include FoothillGourd01")
		quit(1)
		return
	player.global_position = pickup.global_position
	main._update_map_interaction_prompt()
	if not prompt.visible or prompt.text != "按F撿起":
		push_error("Item pickup should show the F pickup prompt nearby")
		quit(1)
		return
	var before_count := int(player.get_item_count("gourd"))
	if not main._collect_nearest_map_item():
		push_error("F item interaction should collect the nearest pickup")
		quit(1)
		return
	if int(player.get_item_count("gourd")) != before_count + 1:
		push_error("Collecting a map item should add one matching item to the player")
		quit(1)
		return
	await process_frame
	if is_instance_valid(pickup) and not pickup.is_queued_for_deletion():
		push_error("Collected map item should disappear from the map")
		quit(1)
		return
	await process_frame
	if not notice.visible:
		push_error("Collecting a map item should show the pickup notice")
		quit(1)
		return
	var notice_label := notice.get_node_or_null("Label") as Label
	var notice_icon := notice.get_node_or_null("Icon") as TextureRect
	if notice_label == null or notice_label.text != "獲得 x1":
		push_error("Pickup notice should show the gain text")
		quit(1)
		return
	if notice_icon == null or notice_icon.texture == null or not notice_icon.texture.resource_path.ends_with("assets/items/gourd/gourd.png"):
		push_error("Pickup notice should show the collected item icon")
		quit(1)
		return
	main.queue_free()
	await process_frame
