extends CharacterBody2D

const CombatServerScript = preload("res://scripts/combat_server.gd")

@export var speed := 650.0
@export var damage := 15.0
@export var posture_damage := 25.0
@export var lifetime := 5.0

var direction := 1.0
var destroyed := false
var lodged := false
var has_dealt_damage := false
var owner_player: Node = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player_projectile")
	if sprite != null:
		sprite.flip_h = direction < 0.0

func setup(fire_direction: float, source: Node) -> void:
	direction = sign(fire_direction)
	if direction == 0.0:
		direction = 1.0
	owner_player = source
	if sprite != null:
		sprite.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		_destroy()
		return
	if lodged:
		velocity = Vector2.ZERO
		return
	velocity = Vector2(direction * speed, 0.0)
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return
	var body := collision.get_collider()
	if body == owner_player:
		return
	if body != null:
		if not has_dealt_damage and body.has_method("receive_player_attack"):
			body.receive_player_attack(damage, posture_damage)
			has_dealt_damage = true
		elif not has_dealt_damage and body.has_method("receive_enemy_attack") and not body.is_in_group("player"):
			# Generic enemy fallback
			body.receive_enemy_attack(damage, posture_damage)
			has_dealt_damage = true
	lodged = true
	velocity = Vector2.ZERO

func _destroy() -> void:
	if destroyed:
		return
	destroyed = true
	queue_free()
