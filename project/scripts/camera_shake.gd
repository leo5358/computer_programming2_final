extends Camera2D

@export var decay := 45.0
@export var vertical_ratio := 0.45
@export var follow_target_path: NodePath
@export var follow_offset := Vector2.ZERO
@export var follow_smoothing_enabled := true
@export var follow_smoothing_speed := 8.0
@export var horizontal_deadzone := 24.0
@export var vertical_deadzone := 96.0
@export_range(0.0, 1.0, 0.05) var vertical_follow_ratio := 0.25
@export var lookahead_distance := 140.0
@export var lookahead_smoothing_speed := 6.0
@export var min_lookahead_speed := 30.0
@export var dynamic_bottom_limit_enabled := false
@export var bottom_limit_start_x := 12800.0
@export var bottom_limit_end_x := 15663.0
@export var bottom_limit_start := 655
@export var bottom_limit_end := -50
@export var bottom_limit_keyframes := PackedFloat32Array()

var amplitude := 0.0
var shake_time := 0.0
var base_offset := Vector2.ZERO
var sample_index := 0
var is_suppressed := false
var follow_target: Node2D = null
var smoothed_lookahead_x := 0.0

func _ready() -> void:
	add_to_group("feedback_camera")
	base_offset = offset
	if not follow_target_path.is_empty():
		var target_node: Node = get_node_or_null(follow_target_path)
		if target_node is Node2D:
			follow_target = target_node

func _process(delta: float) -> void:
	_update_follow(delta)

	if is_suppressed:
		amplitude = 0.0
		shake_time = 0.0
		offset = base_offset
		return

	var step: float = max(delta, 1.0 / 60.0)
	shake_time = max(0.0, shake_time - step)
	amplitude = move_toward(amplitude, 0.0, decay * step)
	if amplitude <= 0.01:
		offset = base_offset
		return

	sample_index += 1
	var strength: float = amplitude
	var x: float = sin(float(sample_index) * 23.7) * strength
	var y: float = cos(float(sample_index) * 31.1) * strength * vertical_ratio
	offset = base_offset + Vector2(x, y)

func shake(amount: float, duration: float) -> void:
	amplitude = max(amplitude, amount)
	shake_time = max(shake_time, duration)

func _update_follow(delta: float) -> void:
	if follow_target == null:
		return

	_update_dynamic_limits()

	var target_position: Vector2 = follow_target.global_position + follow_offset
	var target_lookahead_x: float = _get_target_lookahead_direction() * lookahead_distance
	var lookahead_weight: float = clampf(lookahead_smoothing_speed * delta, 0.0, 1.0)
	smoothed_lookahead_x = lerpf(smoothed_lookahead_x, target_lookahead_x, lookahead_weight)
	target_position.x += smoothed_lookahead_x

	var desired_position: Vector2 = global_position
	var horizontal_delta: float = target_position.x - global_position.x
	if absf(horizontal_delta) > horizontal_deadzone:
		desired_position.x = target_position.x - signf(horizontal_delta) * horizontal_deadzone

	var vertical_delta: float = target_position.y - global_position.y
	if absf(vertical_delta) > vertical_deadzone:
		var vertical_excess: float = vertical_delta - signf(vertical_delta) * vertical_deadzone
		desired_position.y = global_position.y + vertical_excess * vertical_follow_ratio

	if follow_smoothing_enabled:
		var weight: float = clampf(follow_smoothing_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(desired_position, weight)
	else:
		global_position = desired_position

func _get_target_lookahead_direction() -> float:
	if follow_target is CharacterBody2D:
		var body: CharacterBody2D = follow_target as CharacterBody2D
		if absf(body.velocity.x) >= min_lookahead_speed:
			return signf(body.velocity.x)

	var facing_value: Variant = follow_target.get("facing")
	if facing_value is float or facing_value is int:
		var facing_float: float = float(facing_value)
		if not is_zero_approx(facing_float):
			return signf(facing_float)

	return 0.0

func _update_dynamic_limits() -> void:
	if not dynamic_bottom_limit_enabled:
		return

	if bottom_limit_keyframes.size() >= 4:
		limit_bottom = _bottom_limit_from_keyframes(follow_target.global_position.x)
		return

	if is_equal_approx(bottom_limit_start_x, bottom_limit_end_x):
		limit_bottom = bottom_limit_end
		return

	var progress: float = inverse_lerp(bottom_limit_start_x, bottom_limit_end_x, follow_target.global_position.x)
	progress = clampf(progress, 0.0, 1.0)
	limit_bottom = int(round(lerpf(float(bottom_limit_start), float(bottom_limit_end), progress)))

func _bottom_limit_from_keyframes(target_x: float) -> int:
	var keyframe_count: int = bottom_limit_keyframes.size() / 2
	if keyframe_count <= 0:
		return limit_bottom

	var first_x: float = bottom_limit_keyframes[0]
	var first_limit: float = bottom_limit_keyframes[1]
	if target_x <= first_x:
		return int(round(first_limit))

	for keyframe_index in range(1, keyframe_count):
		var previous_offset: int = (keyframe_index - 1) * 2
		var current_offset: int = keyframe_index * 2
		var previous_x: float = bottom_limit_keyframes[previous_offset]
		var previous_limit: float = bottom_limit_keyframes[previous_offset + 1]
		var current_x: float = bottom_limit_keyframes[current_offset]
		var current_limit: float = bottom_limit_keyframes[current_offset + 1]
		if target_x <= current_x:
			if is_equal_approx(previous_x, current_x):
				return int(round(current_limit))

			var progress: float = inverse_lerp(previous_x, current_x, target_x)
			progress = clampf(progress, 0.0, 1.0)
			return int(round(lerpf(previous_limit, current_limit, progress)))

	var last_offset: int = (keyframe_count - 1) * 2
	return int(round(bottom_limit_keyframes[last_offset + 1]))
