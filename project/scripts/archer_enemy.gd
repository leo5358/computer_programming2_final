extends "res://scripts/enemy_base.gd"

const ARROW_SCENE: PackedScene = preload("res://scenes/Arrow.tscn")

@export var arrow_spawn_offset := Vector2(52.0, -46.0)

func _ready() -> void:
	display_name = "Archer"
	sprite_root = "res://assets/sprites/archer"
	attack_sprite_name = "attack.png"
	custom_animation_frames = {
		"idle": [
			{"path": "res://assets/sprites/archer/idle.png", "region": Rect2(9.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/idle.png", "region": Rect2(105.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/idle.png", "region": Rect2(201.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/idle.png", "region": Rect2(297.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/idle.png", "region": Rect2(398.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/idle.png", "region": Rect2(490.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/idle.png", "region": Rect2(583.0, 0.0, 96.0, 96.0)},
		],
		"attack": [
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(4.0, 0.0, 90.0, 96.0)},
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(100.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(192.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(288.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(386.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(482.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(578.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/archer/attack.png", "region": Rect2(669.0, 0.0, 93.0, 96.0)},
		],
		"hurt": [
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(0.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(96.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(182.0, 0.0, 91.0, 96.0)},
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(273.0, 0.0, 91.0, 96.0)},
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(372.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(475.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(568.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/archer/hurt.png", "region": Rect2(661.0, 0.0, 93.0, 96.0)},
		],
		"death": [
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(0.0, 0.0, 89.0, 96.0)},
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(89.0, 0.0, 89.0, 96.0)},
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(178.0, 0.0, 89.0, 96.0)},
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(267.0, 0.0, 89.0, 96.0)},
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(368.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(470.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(573.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/archer/death.png", "region": Rect2(667.0, 0.0, 94.0, 96.0)},
		],
	}
	custom_animation_speeds = {"idle": 5.0, "attack": 8.0, "hurt": 8.0, "death": 8.0}
	custom_animation_loops = {"idle": true, "attack": false, "hurt": false, "death": false}
	max_health = 64.0
	max_posture = 75.0
	attack_damage = 23.0
	attack_posture_damage = 18.0
	patrol_speed = 34.0
	chase_speed = 72.0
	attack_range = 380.0
	ideal_distance = 340.0
	too_close_distance = 100.0
	vision_range = 520.0
	vision_height = 140.0
	attack_cooldown_duration = 0.6
	attack_cue_start = 0.38
	attack_hit_start = 0.60
	attack_hit_end = 0.68
	attack_total_time = 0.88
	super()

func _update_combat_movement() -> void:
	var offset_x: float = target.global_position.x - global_position.x
	var distance: float = abs(offset_x)
	if absf(offset_x) > 4.0:
		facing = sign(offset_x)
	
	if distance <= attack_range and attack_cooldown <= 0.0:
		_start_attack()
		velocity.x = 0.0
	elif distance < too_close_distance:
		state = EnemyState.FLEE
		velocity.x = -sign(offset_x) * chase_speed
	elif distance > ideal_distance:
		state = EnemyState.CHASE
		velocity.x = facing * chase_speed
	else:
		state = EnemyState.HOLD
		velocity.x = 0.0

func can_receive_attack_soft_lock() -> bool:
	return false

func _connect_attack() -> void:
	if attack_has_connected:
		return
	attack_has_connected = true
	var arrow := ARROW_SCENE.instantiate()
	var parent := get_parent()
	if parent == null:
		parent = get_tree().root
	parent.add_child(arrow)
	if arrow is Node2D:
		arrow.global_position = global_position + Vector2(arrow_spawn_offset.x * facing, arrow_spawn_offset.y)
	if arrow.has_method("setup"):
		arrow.setup(facing, self)
