extends CharacterBody2D

@export var speed := 520.0
@export var gravity_scale := 0.35
@export var upward_impulse := -90.0
@export var lifetime := 3.0
@export var effect_radius := 160.0
@export var floor_collision_normal_threshold := -0.55

var direction := 1.0
var destroyed := false
var owner_player: Node = null
var boss_pause_duration := 2.5
var minor_stun_duration := 1.25
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

const SmokeEffectScene = preload("res://scenes/SmokeEffect.tscn")

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player_projectile")
	velocity = Vector2(direction * speed, upward_impulse)
	if sprite != null:
		sprite.flip_h = direction < 0.0

func setup(fire_direction: float, source: Node, boss_pause_time: float, minor_stun_time: float) -> void:
	direction = sign(fire_direction)
	if direction == 0.0:
		direction = 1.0
	owner_player = source
	boss_pause_duration = boss_pause_time
	minor_stun_duration = minor_stun_time
	if sprite != null:
		sprite.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	velocity.y += gravity * gravity_scale * delta
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return
	if collision.get_collider() == owner_player:
		return
	if _is_floor_collision(collision):
		explode(collision.get_position())
	else:
		velocity = velocity.slide(collision.get_normal())

func explode(effect_position := Vector2.INF) -> void:
	if destroyed:
		return
	destroyed = true
	var origin := global_position if effect_position == Vector2.INF else effect_position
	
	var smoke = SmokeEffectScene.instantiate()
	get_parent().add_child(smoke)
	smoke.global_position = origin
	
	for target in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("boss"):
		if not (target is Node2D):
			continue
		if origin.distance_to((target as Node2D).global_position) > effect_radius:
			continue
		if target.is_in_group("boss") and target.has_method("receive_smoke_bomb_pause"):
			target.receive_smoke_bomb_pause(boss_pause_duration)
		elif target.has_method("receive_ash_ball_stun"):
			target.receive_ash_ball_stun(minor_stun_duration)
		elif target.has_method("_start_direct_hurt_feedback"):
			target._start_direct_hurt_feedback()
	queue_free()

func _is_floor_collision(collision: KinematicCollision2D) -> bool:
	return collision.get_normal().y <= floor_collision_normal_threshold
