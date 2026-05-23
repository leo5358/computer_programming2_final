extends Camera2D

@export var decay := 45.0
@export var vertical_ratio := 0.45

var amplitude := 0.0
var shake_time := 0.0
var base_offset := Vector2.ZERO
var sample_index := 0
var is_suppressed := false

func _ready() -> void:
	add_to_group("feedback_camera")
	base_offset = offset

func _process(delta: float) -> void:
	if is_suppressed:
		amplitude = 0.0
		shake_time = 0.0
		offset = base_offset
		return

	shake_time = max(0.0, shake_time - delta)
	amplitude = move_toward(amplitude, 0.0, decay * delta)
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
