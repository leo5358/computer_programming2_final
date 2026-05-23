extends Node

const TARGET_GROUPS := ["player", "boss", "minor_enemy"]
const LINE_NAME := "HurtboxDebugLine"
const ATTACK_LINE_NAME := "AttackHitboxDebugLine"
const VISION_LINE_NAME := "VisionDebugLine"

var visible_lines := false

func _ready() -> void:
	add_to_group("hurtbox_debug_overlay")
	_set_lines_visible(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_hurtbox_debug"):
		toggle_hurtbox_debug()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if visible_lines:
		_refresh_visible_lines()

func toggle_hurtbox_debug() -> void:
	visible_lines = not visible_lines
	_set_lines_visible(visible_lines)

func _set_lines_visible(show_lines: bool) -> void:
	for target in _targets():
		var line := _ensure_debug_line(target)
		line.visible = show_lines
		_update_line_shape(target, line)
		var attack_area := target.get_node_or_null("AttackArea") as Area2D
		if attack_area != null:
			var attack_line := _ensure_area_debug_line(attack_area)
			attack_line.visible = show_lines
			_update_line_shape(attack_area, attack_line)
		if target.has_method("get_vision_rect"):
			var vision_line := _ensure_vision_debug_line(target)
			vision_line.visible = show_lines
			_update_vision_shape(target, vision_line)

func _refresh_visible_lines() -> void:
	for target in _targets():
		var line := target.get_node_or_null(LINE_NAME) as Line2D
		if line != null and line.visible:
			_update_line_shape(target, line)
		var attack_area := target.get_node_or_null("AttackArea") as Area2D
		if attack_area != null:
			var attack_line := attack_area.get_node_or_null(ATTACK_LINE_NAME) as Line2D
			if attack_line != null and attack_line.visible:
				_update_line_shape(attack_area, attack_line)
		if target.has_method("get_vision_rect"):
			var vision_line := target.get_node_or_null(VISION_LINE_NAME) as Line2D
			if vision_line != null and vision_line.visible:
				_update_vision_shape(target, vision_line)

func _targets() -> Array[Node]:
	var result: Array[Node] = []
	for group_name in TARGET_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is Node2D:
				result.append(node)
	return result

func _ensure_debug_line(target: Node2D) -> Line2D:
	var line := target.get_node_or_null(LINE_NAME) as Line2D
	if line == null:
		line = Line2D.new()
		line.name = LINE_NAME
		line.width = 3.0
		line.closed = true
		line.default_color = Color(0.2, 1.0, 0.35, 0.95)
		target.add_child(line)
	return line

func _ensure_area_debug_line(target: Node2D) -> Line2D:
	var line := target.get_node_or_null(ATTACK_LINE_NAME) as Line2D
	if line == null:
		line = Line2D.new()
		line.name = ATTACK_LINE_NAME
		line.width = 3.0
		line.closed = true
		line.default_color = Color(1.0, 0.2, 0.12, 0.95)
		target.add_child(line)
	return line

func _ensure_vision_debug_line(target: Node2D) -> Line2D:
	var line := target.get_node_or_null(VISION_LINE_NAME) as Line2D
	if line == null:
		line = Line2D.new()
		line.name = VISION_LINE_NAME
		line.width = 2.0
		line.closed = true
		line.default_color = Color(1.0, 0.85, 0.1, 0.75)
		target.add_child(line)
	return line

func _update_line_shape(target: Node2D, line: Line2D) -> void:
	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return
	var rect_shape := collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	var half_size: Vector2 = rect_shape.size * 0.5
	line.position = collision_shape.position
	line.points = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])

func _update_vision_shape(target: Node2D, line: Line2D) -> void:
	var rect: Rect2 = target.get_vision_rect()
	line.position = rect.position
	line.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0.0),
		rect.size,
		Vector2(0.0, rect.size.y),
	])
	if "is_alerted" in target and target.is_alerted:
		line.default_color = Color(1.0, 0.18, 0.08, 0.85)
	else:
		line.default_color = Color(1.0, 0.85, 0.1, 0.75)
