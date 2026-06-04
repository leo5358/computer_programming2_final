extends "res://scripts/enemy_base.gd"

@export var ally_call_range := 420.0
@export var flee_until_distance := 160.0

var has_called_allies := false

func _ready() -> void:
	display_name = "Torchman"
	sprite_root = "res://assets/sprites/torchman"
	attack_sprite_name = "torch-attack.png"
	custom_animation_frames = {
		"idle": [
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(8.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(104.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(200.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(296.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(392.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(488.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(578.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/idle.png", "region": Rect2(8.0, 0.0, 96.0, 96.0)},
		],
		"walk": [
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(9.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(103.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(197.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(282.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(376.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(470.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(564.0, 0.0, 94.0, 96.0)},
			{"path": "res://assets/sprites/torchman/walk.png", "region": Rect2(651.0, 0.0, 93.0, 96.0)},
		],
		"attack": [
			{"path": "res://assets/sprites/torchman/torch-attack.png", "region": Rect2(2.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/torch-attack.png", "region": Rect2(98.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/torch-attack.png", "region": Rect2(194.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/torch-attack.png", "region": Rect2(396.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/torchman/torch-attack.png", "region": Rect2(489.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/torchman/torch-attack.png", "region": Rect2(582.0, 0.0, 93.0, 96.0)},
			{"path": "res://assets/sprites/torchman/torch-attack.png", "region": Rect2(675.0, 0.0, 93.0, 96.0)},
		],
		"hurt": [
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(8.0, 0.0, 95.0, 96.0)},
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(103.0, 0.0, 95.0, 96.0)},
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(198.0, 0.0, 95.0, 96.0)},
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(293.0, 0.0, 95.0, 96.0)},
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(388.0, 0.0, 95.0, 96.0)},
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(483.0, 0.0, 95.0, 96.0)},
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(578.0, 0.0, 95.0, 96.0)},
			{"path": "res://assets/sprites/torchman/hurt.png", "region": Rect2(665.0, 0.0, 95.0, 96.0)},
		],
		"death": [
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(0.0, 0.0, 96.0, 96.0)},
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(92.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(180.0, 0.0, 90.0, 96.0)},
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(270.0, 0.0, 90.0, 96.0)},
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(362.0, 0.0, 90.0, 96.0)},
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(462.0, 0.0, 92.0, 96.0)},
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(562.0, 0.0, 103.0, 96.0)},
			{"path": "res://assets/sprites/torchman/death.png", "region": Rect2(665.0, 0.0, 103.0, 96.0)},
		],
	}
	custom_animation_speeds = {"idle": 5.0, "walk": 10.0, "attack": 8.0, "hurt": 8.0, "death": 8.0}
	custom_animation_loops = {"idle": true, "walk": true, "attack": false, "hurt": false, "death": false}
	max_health = 32.0
	max_posture = 70.0
	attack_damage = 8.0
	attack_posture_damage = 14.0
	patrol_speed = 42.0
	chase_speed = 78.0
	flee_speed = 118.0
	attack_range = 58.0
	ideal_distance = 92.0
	vision_range = 360.0
	vision_height = 104.0
	super()

func _update_combat_movement() -> void:
	var offset_x: float = target.global_position.x - global_position.x
	var distance: float = abs(offset_x)
	if absf(offset_x) > 4.0:
		facing = sign(offset_x)
	if distance > attack_range and (not has_called_allies or distance < flee_until_distance):
		state = EnemyState.FLEE
		velocity.x = -sign(offset_x) * flee_speed
		if not has_called_allies:
			_call_nearby_allies()
		return
	if distance <= attack_range and attack_cooldown <= 0.0:
		_start_attack()
	else:
		state = EnemyState.CHASE
		velocity.x = facing * chase_speed

func _call_nearby_allies() -> void:
	has_called_allies = true
	for enemy in get_tree().get_nodes_in_group("minor_enemy"):
		if enemy == self:
			continue
		if not (enemy is Node2D):
			continue
		if global_position.distance_to(enemy.global_position) > ally_call_range:
			continue
		if enemy.has_method("receive_alert"):
			enemy.receive_alert(self)

func reset_combat_state() -> void:
	has_called_allies = false
	super()
