extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")

func _initialize() -> void:
	var arena := Node2D.new()
	get_root().add_child(arena)
	_add_floor(arena)
	var player: CharacterBody2D = PLAYER_SCENE.instantiate() as CharacterBody2D
	arena.add_child(player)
	await process_frame
	player.global_position = Vector2(300, 340)
	if "spawn_position" in player:
		player.spawn_position = player.global_position
	if player.has_method("reset_combat_state"):
		player.reset_combat_state()
	for frame in 12:
		await physics_frame

	for method_name in ["set_ai_move_axis", "request_ai_attack", "request_ai_parry", "request_ai_dodge", "request_ai_jump", "clear_ai_intent", "get_ai_move_axis"]:
		if not player.has_method(method_name):
			push_error("Player should expose AI intent method: %s" % method_name)
			quit(1)
			return

	player.set_ai_move_axis(1.0)
	await physics_frame
	if player.velocity.x <= 0.0:
		push_error("AI move intent should flow through Player movement logic")
		quit(1)
		return

	player.clear_ai_intent()
	player.request_ai_attack()
	await physics_frame
	if int(player.state) != int(player.PlayerState.ATTACK):
		push_error("AI attack intent should flow through Player input logic")
		quit(1)
		return

	player.queue_free()
	arena.queue_free()
	await process_frame
	quit(0)

func _add_floor(arena: Node2D) -> void:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(300, 386)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(900, 24)
	shape.shape = rectangle
	floor_body.add_child(shape)
	arena.add_child(floor_body)
