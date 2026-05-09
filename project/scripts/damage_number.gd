extends Node2D

@export var lifetime := 0.6
@export var float_speed := 42.0

var age := 0.0

@onready var label: Label = $Label

func _ready() -> void:
	add_to_group("damage_number")

func setup(value: float, color := Color(1.0, 0.94, 0.58, 1.0)) -> void:
	if label == null:
		await ready
	label.text = str(roundi(value))
	label.modulate = color

func get_text() -> String:
	if label == null:
		return ""
	return label.text

func _process(delta: float) -> void:
	age += delta
	position.y -= float_speed * delta
	var t: float = clamp(age / lifetime, 0.0, 1.0)
	scale = Vector2.ONE * lerp(1.15, 0.92, t)
	modulate.a = 1.0 - t
	if age >= lifetime:
		queue_free()
