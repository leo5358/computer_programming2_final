extends CharacterBody2D

const CombatServerScript = preload("res://scripts/combat_server.gd")

@export var speed := 420.0
@export var damage := 23.0
@export var posture_damage := 14.0
@export var lifetime := 2.2

var direction := 1.0
var destroyed := false
var owner_enemy: Node = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy_projectile")
	if sprite != null:
		sprite.flip_h = direction < 0.0

func setup(fire_direction: float, source: Node) -> void:
	direction = sign(fire_direction)
	if direction == 0.0:
		direction = 1.0
	owner_enemy = source
	if sprite != null:
		sprite.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	lifetime -= delta
	if lifetime <= 0.0:
		_destroy()
		return
	velocity = Vector2(direction * speed, 0.0)
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return
	var body := collision.get_collider()
	if body == owner_enemy:
		return
	if body != null and body.has_method("receive_enemy_attack"):
		body.receive_enemy_attack(damage, posture_damage, self, CombatServerScript.AttackType.NORMAL)
	_destroy()

func receive_player_attack(_damage: float, _posture_damage: float) -> Variant:
	_destroy()
	return true

func can_be_executed() -> bool:
	return false

func _destroy() -> void:
	if destroyed:
		return
	destroyed = true
	queue_free()
