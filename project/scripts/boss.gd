extends "res://scripts/enemy.gd"

func _ready() -> void:
	add_to_group("boss")
	display_name = "Boss"
	max_health = 140.0
	max_posture = 100.0
	attack_damage = 18.0
	attack_posture_damage = 32.0
	attack_interval = 1.05
	posture_recovery = 4.0
	attack_range = 118.0
	health = max_health
	posture = 0.0
	super()
