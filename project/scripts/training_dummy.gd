extends CharacterBody2D

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/DamageNumber.tscn")

@export var flash_time := 0.08
@export var knockback_force := 240.0
@export var friction := 900.0

var hit_count := 0
var last_damage := 0.0
var last_posture_damage := 0.0
var hit_flash_timer := 0.0
var default_color := Color(0.42, 0.24, 0.10, 1.0)
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var body: ColorRect = $Body

func _ready() -> void:
	add_to_group("training_dummy")
	default_color = body.color

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	body.color = Color(0.95, 0.78, 0.34, 1.0) if hit_flash_timer > 0.0 else default_color

func receive_player_attack(damage: float, posture_damage: float) -> void:
	hit_count += 1
	last_damage = damage
	last_posture_damage = posture_damage
	hit_flash_timer = flash_time
	_spawn_damage_number(damage)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var knockback_direction := 1.0
	if player != null:
		knockback_direction = sign(global_position.x - player.global_position.x)
		if knockback_direction == 0.0:
			knockback_direction = 1.0
	velocity.x = knockback_direction * knockback_force

func can_be_executed() -> bool:
	return false

func _spawn_damage_number(damage: float) -> void:
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	var parent := get_parent()
	if parent == null:
		parent = get_tree().root
	parent.add_child(number)
	number.global_position = global_position + Vector2(0.0, -64.0)
	if number.has_method("setup"):
		number.setup(damage)
