extends "res://scripts/enemy_base.gd"

func _ready() -> void:
	display_name = "Warrior"
	sprite_root = "res://assets/sprites/warrior"
	attack_sprite_name = "attack.png"
	custom_animation_frames = {
		"attack": [
			{"path": "res://assets/sprites/warrior/attack.png", "region": Rect2(13.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/warrior/attack.png", "region": Rect2(96.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/warrior/attack.png", "region": Rect2(188.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/warrior/attack.png", "region": Rect2(279.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/warrior/attack1.png", "region": Rect2(373.0, 0.0, 122.0, 96.0)},
			{"path": "res://assets/sprites/warrior/attack1.png", "region": Rect2(525.0, 0.0, 102.0, 96.0)},
			{"path": "res://assets/sprites/warrior/attack1.png", "region": Rect2(651.0, 0.0, 93.0, 96.0)},
		],
		"deflect": [
			{"path": "res://assets/sprites/warrior/deflect.png", "region": Rect2(9.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/warrior/deflect.png", "region": Rect2(102.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/warrior/deflect.png", "region": Rect2(289.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/warrior/deflect.png", "region": Rect2(376.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/warrior/deflect.png", "region": Rect2(470.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/warrior/deflect.png", "region": Rect2(564.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/warrior/deflect.png", "region": Rect2(658.0, 0.0, 94.0, 96.0)},
		],
		"thrust": [
			{"path": "res://assets/sprites/warrior/thrust.png", "region": Rect2(0.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/warrior/thrust.png", "region": Rect2(96.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/warrior/thrust.png", "region": Rect2(192.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/warrior/thrust1.png", "region": Rect2(282.0, 0.0, 141.0, 96.0)},
			{"path": "res://assets/sprites/warrior/thrust2.png", "region": Rect2(360.0, 0.0, 180.0, 96.0)},
			{"path": "res://assets/sprites/warrior/thrust1.png", "region": Rect2(474.0, 0.0, 158.0, 96.0)},
			{"path": "res://assets/sprites/warrior/thrust2.png", "region": Rect2(545.0, 0.0, 109.0, 96.0)},
			{"path": "res://assets/sprites/warrior/thrust.png", "region": Rect2(672.0, 0.0, 96.0, 96.0)},
		],
	}
	custom_animation_speeds = {"attack": 5.0, "deflect": 14.0, "thrust": 8.0}
	custom_animation_loops = {"attack": false, "deflect": false, "thrust": false}
	max_health = 60.0
	max_posture = 100.0
	attack_damage = 13.0
	attack_posture_damage = 22.0
	patrol_speed = 38.0
	chase_speed = 92.0
	flee_speed = 96.0
	attack_range = 88.0
	ideal_distance = 78.0
	too_close_distance = 48.0
	vision_range = 340.0
	vision_height = 104.0
	attack_cue_start = 0.74
	attack_hit_start = 0.98
	attack_hit_end = 1.10
	attack_total_time = 1.35
	attack_cooldown_duration = 1.55
	counter_cue_start = 0.10
	counter_hit_start = 0.24
	counter_hit_end = 0.40
	counter_total_time = 0.72
	counter_step_time = 0.12
	counter_step_speed = 120.0
	thrust_range = 168.0
	thrust_cue_start = 0.32
	thrust_hit_start = 0.48
	thrust_hit_end = 0.62
	thrust_total_time = 0.96
	thrust_step_time = 0.24
	thrust_step_speed = 250.0
	thrust_hitbox_size = Vector2(124.0, 42.0)
	thrust_hitbox_offset = Vector2(64.0, -34.0)
	pressure_duration = 2.2
	pressure_thrust_range_multiplier = 1.25
	whiff_cooldown_multiplier = 0.42
	posture_recovery_pause = 1.25
	posture_recovery_rate = 12.0
	perfect_parry_posture_damage = 20.0
	normal_block_posture_damage = 8.0
	parried_recovery_duration = 1.55
	guard_chance = 0.5
	guard_posture_damage = 3.0
	deflect_duration = 0.28
	guard_lockout_duration = 0.45
	direct_hit_thrust_lockout_time = 0.72
	is_perilous_attack = false
	super()
