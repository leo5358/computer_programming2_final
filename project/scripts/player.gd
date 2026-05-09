extends CharacterBody2D

signal stats_changed
signal died

const CombatMathScript = preload("res://scripts/combat_math.gd")
const CombatServerScript = preload("res://scripts/combat_server.gd")
const PLAYER_SHEET: Texture2D = preload("res://assets/sprites/player/player4.png")
const ATTACK_SFX_PATH := "res://assets/sfx/player_attack.wav"
const PARRY_SFX_PATH := "res://assets/sfx/player_parry.wav"
const BLOCK_SFX_PATH := "res://assets/sfx/player_block.wav"
const HURT_SFX_PATH := "res://assets/sfx/player_hurt.wav"
const DEATH_SFX_PATH := "res://assets/sfx/player_death.wav"
const DASH_SFX_PATH := "res://assets/sfx/player_dash.wav"
const PERFECT_DODGE_SFX_PATH := "res://assets/sfx/player_perfect_dodge.wav"

enum PlayerState {
	IDLE,
	MOVE,
	ATTACK,
	PARRY,
	BLOCK,
	DASH,
	JUMP,
	HURT,
	STUNNED,
	DEAD,
}

@export var max_speed := 400.0
@export var acceleration := 2000.0
@export var friction := 3200.0
@export var turn_brake := 4200.0
@export var dash_impulse := 1200.0
@export var jump_velocity := -430.0
@export var coyote_time := 0.1
@export var max_health := 100.0
@export var max_posture := 100.0
@export var base_attack_damage := 16.0
@export var attack_posture_damage := 18.0
@export var block_posture_damage := 14.0
@export var perfect_block_posture_damage := 36.0
@export var attack_startup := 0.25
@export var attack_active_time := 0.08
@export var attack_recovery := 0.17
@export var parry_window := 0.45
@export var parry_flash_time := 0.14
@export var dash_duration := 0.20
@export var perfect_dodge_duration := 0.16
@export var perfect_dodge_impulse := 680.0
@export var perfect_dodge_hitstop_time := 0.09
@export var hurt_time := 0.22
@export var stunned_time := 0.5
@export var impact_flash_time := 0.20
@export var attack_hitstop_time := 0.055
@export var parry_hitstop_time := 0.13
@export var block_knockback := 150.0
@export var hurt_knockback := 240.0
@export var parry_rebound := 120.0
@export var show_debug_shapes := false

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := max_health
var posture := 0.0
var heartbeat: float = CombatMathScript.MIN_HEARTBEAT
var state := PlayerState.IDLE
var previous_state := PlayerState.IDLE
var is_blocking := false
var is_attacking := false
var is_parrying := false
var is_dashing := false
var is_perfect_dodging := false
var is_invulnerable := false
var block_age := 0.0
var block_time_left := 0.0
var facing := 1.0
var coyote_timer := 0.0
var action_timer := 0.0
var dash_timer := 0.0
var dash_direction := 1.0
var attack_has_hit := false
var current_animation := ""
var parry_flash_timer := 0.0
var block_flash_timer := 0.0
var hurt_flash_timer := 0.0
var perfect_dodge_timer := 0.0
var hitstop_timer := 0.0
var stored_velocity := Vector2.ZERO
var combat_runtime: Node
var spawn_position := Vector2.ZERO
var sprite_sheet_layout: Dictionary = {}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_visual: ColorRect = $Body
@onready var attack_area: Area2D = $AttackArea
@onready var attack_visual: ColorRect = $AttackVisual
@onready var block_visual: ColorRect = $BlockVisual
@onready var parry_visual: ColorRect = $ParryVisual
@onready var block_impact_visual: ColorRect = $BlockImpactVisual
@onready var hurt_impact_visual: ColorRect = $HurtImpactVisual
@onready var dash_visual: ColorRect = $DashVisual
@onready var attack_slash_vfx: Line2D = get_node_or_null("AttackSlashVfx") as Line2D
@onready var parry_spark_vfx: Line2D = get_node_or_null("ParrySparkVfx") as Line2D
@onready var block_spark_vfx: Line2D = get_node_or_null("BlockSparkVfx") as Line2D
@onready var hurt_slash_vfx: Line2D = get_node_or_null("HurtSlashVfx") as Line2D
@onready var perfect_dodge_vfx: Line2D = get_node_or_null("PerfectDodgeVfx") as Line2D
@onready var dodge_afterimage_vfx: Line2D = get_node_or_null("DodgeAfterimageVfx") as Line2D
@onready var state_label: Label = $StateLabel
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSfx
@onready var parry_sfx: AudioStreamPlayer2D = $ParrySfx
@onready var block_sfx: AudioStreamPlayer2D = $BlockSfx
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var death_sfx: AudioStreamPlayer2D = $DeathSfx
@onready var dash_sfx: AudioStreamPlayer2D = $DashSfx
@onready var perfect_dodge_sfx: AudioStreamPlayer2D = $PerfectDodgeSfx
@onready var math: RefCounted = CombatMathScript.new()

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	combat_runtime = get_tree().get_first_node_in_group("combat_runtime")
	_setup_sprite_frames()
	_load_optional_sfx()
	_set_state(PlayerState.IDLE)
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	if state == PlayerState.DEAD:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		move_and_slide()
		_update_visuals()
		stats_changed.emit()
		return

	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		if hitstop_timer <= 0.0:
			velocity = stored_velocity
			sprite.speed_scale = 1.0
		_update_visuals()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time

	_update_inputs()
	_update_movement(delta)
	_update_action_state(delta)
	_update_combat(delta)

	move_and_slide()
	_update_visuals()
	stats_changed.emit()

func _update_inputs() -> void:
	if _can_start_action() and Input.is_action_just_pressed("attack"):
		_start_attack()

	if _can_start_action() and Input.is_action_just_pressed("block"):
		_start_parry()

	if _can_start_action() and Input.is_action_just_pressed("dash"):
		_start_dash()

	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0 and _can_jump():
		_register_combat_input(CombatServerScript.InputType.JUMP)
		velocity.y = jump_velocity
		coyote_timer = 0.0
		_set_state(PlayerState.JUMP)

func _update_movement(delta: float) -> void:
	if state in [PlayerState.ATTACK, PlayerState.PARRY, PlayerState.HURT, PlayerState.STUNNED]:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return

	if state == PlayerState.DASH:
		velocity.x = dash_direction * (perfect_dodge_impulse if is_perfect_dodging else dash_impulse)
		return

	var direction := Input.get_axis("move_left", "move_right")
	_apply_horizontal_control(direction, delta)

	attack_area.position.x = 34.0 * facing
	attack_visual.position.x = 18.0 * facing

	if state in [PlayerState.IDLE, PlayerState.MOVE, PlayerState.JUMP]:
		if not is_on_floor():
			_set_state(PlayerState.JUMP)
		elif abs(velocity.x) > 4.0:
			_set_state(PlayerState.MOVE)
		else:
			_set_state(PlayerState.IDLE)

func _apply_horizontal_control(direction: float, delta: float) -> void:
	if direction != 0.0:
		facing = sign(direction)
		var accel := turn_brake if velocity.x != 0.0 and sign(velocity.x) != sign(direction) else acceleration
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _update_action_state(delta: float) -> void:
	if state == PlayerState.ATTACK:
		action_timer -= delta
		var active_start := attack_recovery + attack_active_time
		var active_end := attack_recovery
		var active := action_timer <= active_start and action_timer > active_end
		is_attacking = active
		if active and not attack_has_hit:
			_apply_attack_hit()
			attack_has_hit = true
		if action_timer <= 0.0:
			is_attacking = false
			attack_has_hit = false
			_set_state(PlayerState.IDLE)

	elif state == PlayerState.PARRY:
		action_timer -= delta
		is_parrying = action_timer > 0.0
		if action_timer <= 0.0:
			_start_block()

	elif state == PlayerState.DASH:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			is_perfect_dodging = false
			is_invulnerable = false
			_set_state(PlayerState.IDLE)

	elif state == PlayerState.HURT:
		action_timer -= delta
		if action_timer <= 0.0:
			is_invulnerable = false
			_set_state(PlayerState.IDLE)

	elif state == PlayerState.STUNNED:
		action_timer -= delta
		if action_timer <= 0.0:
			posture = min(posture, max_posture * 0.55)
			is_invulnerable = false
			_set_state(PlayerState.IDLE)

func _update_combat(delta: float) -> void:
	if is_blocking:
		block_age += delta
		block_time_left -= delta
		heartbeat = math.add_heartbeat(heartbeat, 18.0 * delta)
		if not Input.is_action_pressed("block") or block_time_left <= 0.0:
			is_blocking = false
			_set_state(PlayerState.IDLE)
	else:
		heartbeat = max(CombatMathScript.MIN_HEARTBEAT, heartbeat - 8.0 * delta)

func _start_attack() -> void:
	_register_combat_input(CombatServerScript.InputType.ATTACK)
	_play_sfx(attack_sfx)
	_set_state(PlayerState.ATTACK)
	action_timer = attack_startup + attack_active_time + attack_recovery
	is_attacking = false
	attack_has_hit = false

func _apply_attack_hit() -> void:
	var damage: float = math.damage_with_adrenaline(base_attack_damage, heartbeat)
	var hit_confirmed := false
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("can_be_executed") and body.can_be_executed() and body.has_method("execute"):
			body.execute()
			hit_confirmed = true
			continue
		if body.has_method("receive_player_attack"):
			body.receive_player_attack(damage, attack_posture_damage)
			hit_confirmed = true
	if hit_confirmed:
		_trigger_attack_hit_feedback()

func _start_parry() -> void:
	_register_combat_input(CombatServerScript.InputType.PARRY)
	_set_state(PlayerState.PARRY)
	is_parrying = true
	is_blocking = false
	block_age = 0.0
	action_timer = parry_window

func _start_block() -> void:
	_set_state(PlayerState.BLOCK)
	is_parrying = false
	is_blocking = true
	block_age = 0.0
	block_time_left = math.block_duration_for_heartbeat(heartbeat)

func _start_dash() -> void:
	_register_combat_input(CombatServerScript.InputType.DASH)
	var dodge_target := _find_perfect_dodge_target()
	if dodge_target != null:
		_start_perfect_dodge(dodge_target)
		return
	_set_state(PlayerState.DASH)
	is_dashing = true
	is_perfect_dodging = false
	is_invulnerable = true
	dash_direction = facing
	dash_timer = dash_duration
	heartbeat = math.add_heartbeat(heartbeat, 4.0)
	_play_sfx(dash_sfx)

func _start_perfect_dodge(attacker: Node2D) -> void:
	_set_state(PlayerState.DASH)
	is_dashing = true
	is_perfect_dodging = true
	is_invulnerable = true
	dash_direction = sign(global_position.x - attacker.global_position.x)
	if dash_direction == 0.0:
		dash_direction = -facing
	facing = -dash_direction
	dash_timer = perfect_dodge_duration
	perfect_dodge_timer = impact_flash_time
	heartbeat = math.add_heartbeat(heartbeat, 8.0)
	velocity.x = dash_direction * perfect_dodge_impulse
	hitstop_timer = perfect_dodge_hitstop_time
	stored_velocity = Vector2(dash_direction * perfect_dodge_impulse, velocity.y)
	sprite.speed_scale = 0.0
	_play_sfx(perfect_dodge_sfx)
	if attacker.has_method("receive_dodge_feedback"):
		attacker.receive_dodge_feedback()
	_shake_camera(14.0, 0.10)

func _find_perfect_dodge_target() -> Node2D:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and enemy.has_method("can_be_perfect_dodged_by") and enemy.can_be_perfect_dodged_by(self):
			return enemy
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss is Node2D and boss.has_method("can_be_perfect_dodged_by") and boss.can_be_perfect_dodged_by(self):
			return boss
	return null

func receive_enemy_attack(damage: float, posture_damage: float, attacker: Node = null) -> void:
	if health <= 0.0:
		return
	if is_invulnerable:
		return

	if is_parrying or is_blocking:
		var perfect := is_parrying
		posture = math.add_posture(posture, 5.0 if perfect else posture_damage * 2.0)
		heartbeat = math.add_heartbeat(heartbeat, 4.0 if perfect else 5.0)
		if attacker != null and attacker.has_method("receive_block_feedback"):
			attacker.receive_block_feedback(perfect)
		if perfect:
			_play_sfx(parry_sfx)
			_trigger_parry_feedback()
		else:
			_play_sfx(block_sfx)
			_trigger_block_feedback()
	else:
		health = math.apply_damage(health, damage)
		posture = math.add_posture(posture, posture_damage * 1.35)
		heartbeat = math.add_heartbeat(heartbeat, 20.0)
		if health <= 0.0:
			_enter_dead()
			stats_changed.emit()
			died.emit()
			return
		else:
			_play_sfx(hurt_sfx)
			_trigger_hurt_feedback()
			_set_state(PlayerState.HURT)
			action_timer = hurt_time
			is_invulnerable = true

	if posture >= max_posture:
		_set_state(PlayerState.STUNNED)
		posture = 100.0
		action_timer = stunned_time
		is_blocking = false
		is_parrying = false
		is_invulnerable = true

	stats_changed.emit()
	if health <= 0.0:
		_enter_dead()
		died.emit()

func _set_state(next_state: int) -> void:
	if state == next_state:
		return
	previous_state = state
	state = next_state

func _can_start_action() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVE, PlayerState.JUMP, PlayerState.BLOCK]

func _can_jump() -> bool:
	return state not in [PlayerState.ATTACK, PlayerState.PARRY, PlayerState.DASH, PlayerState.HURT, PlayerState.STUNNED]

func _update_visuals() -> void:
	attack_visual.visible = show_debug_shapes and state == PlayerState.ATTACK
	block_visual.visible = show_debug_shapes and is_blocking
	parry_flash_timer = max(0.0, parry_flash_timer - get_physics_process_delta_time())
	block_flash_timer = max(0.0, block_flash_timer - get_physics_process_delta_time())
	hurt_flash_timer = max(0.0, hurt_flash_timer - get_physics_process_delta_time())
	perfect_dodge_timer = max(0.0, perfect_dodge_timer - get_physics_process_delta_time())
	parry_visual.visible = show_debug_shapes and (is_parrying or parry_flash_timer > 0.0)
	block_impact_visual.visible = show_debug_shapes and block_flash_timer > 0.0
	hurt_impact_visual.visible = show_debug_shapes and hurt_flash_timer > 0.0
	dash_visual.visible = is_dashing
	if attack_slash_vfx != null:
		attack_slash_vfx.visible = state == PlayerState.ATTACK
		attack_slash_vfx.scale.x = facing
	if parry_spark_vfx != null:
		parry_spark_vfx.visible = is_parrying or parry_flash_timer > 0.0
	if block_spark_vfx != null:
		block_spark_vfx.visible = block_flash_timer > 0.0
	if hurt_slash_vfx != null:
		hurt_slash_vfx.visible = hurt_flash_timer > 0.0
	if perfect_dodge_vfx != null:
		perfect_dodge_vfx.visible = perfect_dodge_timer > 0.0
		perfect_dodge_vfx.scale.x = dash_direction
	if dodge_afterimage_vfx != null:
		dodge_afterimage_vfx.visible = is_perfect_dodging or perfect_dodge_timer > 0.0
		dodge_afterimage_vfx.scale.x = dash_direction
	state_label.text = _state_name()
	body_visual.visible = show_debug_shapes
	body_visual.color = _state_color()
	sprite.flip_h = facing < 0.0
	_play_state_animation()

func _state_name() -> String:
	return PlayerState.keys()[state]

func _state_color() -> Color:
	match state:
		PlayerState.IDLE:
			return Color(0.12, 0.42, 0.9, 1)
		PlayerState.MOVE:
			return Color(0.1, 0.62, 0.95, 1)
		PlayerState.ATTACK:
			return Color(0.95, 0.83, 0.25, 1)
		PlayerState.PARRY:
			return Color(0.5, 0.9, 1.0, 1)
		PlayerState.BLOCK:
			return Color(0.2, 0.55, 0.9, 1)
		PlayerState.DASH:
			return Color(0.8, 0.8, 1.0, 1)
		PlayerState.HURT, PlayerState.STUNNED:
			return Color(1.0, 0.25, 0.25, 1)
		PlayerState.DEAD:
			return Color(0.1, 0.1, 0.1, 1)
		_:
			return Color(0.12, 0.42, 0.9, 1)

func _setup_sprite_frames() -> void:
	sprite_sheet_layout = _resolve_sheet_layout(PLAYER_SHEET.get_size())
	var frames := SpriteFrames.new()
	_add_layout_animation(frames, "idle")
	_add_layout_animation(frames, "run")
	_add_layout_animation(frames, "attack_a")
	_add_layout_animation(frames, "parry")
	_add_layout_animation(frames, "block")
	_add_layout_animation(frames, "dash")
	_add_layout_animation(frames, "jump")
	_add_layout_animation(frames, "hurt")
	_add_layout_animation(frames, "death")
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -float(sprite_sheet_layout["cell_size"]) * 0.5)
	sprite.play("idle")

func _resolve_sheet_layout(size: Vector2i) -> Dictionary:
	if size == Vector2i(576, 864):
		return {
			"cell_size": 96,
			"idle": {"row": 0, "count": 6, "fps": 6.0, "loop": true, "source": "standard-96-idle"},
			"run": {"row": 1, "count": 6, "fps": 12.0, "loop": true, "source": "standard-96-run"},
			"attack_a": {"row": 6, "count": 6, "fps": 14.0, "loop": false, "source": "standard-96-attack"},
			"parry": {"row": 4, "count": 6, "fps": 14.0, "loop": false, "source": "standard-96-parry"},
			"block": {"row": 4, "count": 3, "fps": 8.0, "loop": true, "source": "standard-96-guard"},
			"dash": {"row": 2, "count": 6, "fps": 18.0, "loop": false, "source": "standard-96-dash"},
			"jump": {"row": 3, "count": 6, "fps": 10.0, "loop": true, "source": "standard-96-jump"},
			"hurt": {"row": 5, "count": 6, "fps": 8.0, "loop": false, "source": "standard-96-hurt"},
			"death": {"row": 8, "count": 6, "fps": 7.0, "loop": false, "source": "standard-96-death"},
		}
	if size == Vector2i(1024, 1536):
		return {
			"cell_size": 128,
			"idle": {"row": 0, "count": 6, "fps": 6.0, "loop": true, "source": "player4-idle"},
			"run": {"row": 1, "count": 6, "fps": 12.0, "loop": true, "source": "player4-run"},
			"attack_a": {"row": 6, "count": 6, "fps": 14.0, "loop": false, "source": "player4-attack"},
			"parry": {"row": 4, "count": 6, "fps": 14.0, "loop": false, "source": "player4-parry"},
			"block": {"row": 4, "count": 3, "fps": 8.0, "loop": true, "source": "player4-guard"},
			"dash": {"row": 2, "count": 6, "fps": 18.0, "loop": false, "source": "player4-dash"},
			"jump": {"row": 3, "count": 6, "fps": 10.0, "loop": true, "source": "player4-jump"},
			"hurt": {"row": 5, "count": 6, "fps": 8.0, "loop": false, "source": "player4-hurt"},
			"death": {"row": 8, "count": 6, "fps": 7.0, "loop": false, "source": "player4-death"},
		}
	if size == Vector2i(768, 1152):
		return {
			"cell_size": 128,
			"idle": {"row": 0, "count": 6, "fps": 6.0, "loop": true, "source": "player3-idle"},
			"run": {"row": 1, "count": 6, "fps": 12.0, "loop": true, "source": "player3-run"},
			"attack_a": {"row": 6, "count": 6, "fps": 14.0, "loop": false, "source": "player3-attack"},
			"parry": {"row": 4, "count": 3, "fps": 14.0, "loop": false, "source": "player3-parry"},
			"block": {"row": 4, "count": 3, "fps": 8.0, "loop": true, "source": "player3-guard"},
			"dash": {"row": 2, "count": 6, "fps": 18.0, "loop": false, "source": "player3-dash"},
			"jump": {"row": 3, "count": 3, "fps": 10.0, "loop": true, "source": "player3-jump"},
			"hurt": {"row": 5, "count": 3, "fps": 8.0, "loop": false, "source": "player3-hurt"},
			"death": {"row": 8, "count": 6, "fps": 7.0, "loop": false, "source": "player3-death"},
		}
	if size == Vector2i(1086, 1448):
		return {
			"cell_size": 181,
			"idle": {"row": 0, "count": 6, "fps": 6.0, "loop": true, "source": "player2-idle"},
			"run": {"row": 1, "count": 6, "fps": 12.0, "loop": true, "source": "player2-run"},
			"attack_a": {"row": 2, "count": 6, "fps": 14.0, "loop": false, "source": "player2-attack"},
			"parry": {"row": 4, "count": 6, "fps": 14.0, "loop": false, "source": "player2-parry"},
			"block": {"row": 3, "count": 6, "fps": 8.0, "loop": true, "source": "player2-guard"},
			"dash": {"row": 1, "count": 6, "fps": 18.0, "loop": false, "source": "player2-run-as-dash"},
			"jump": {"row": 1, "count": 6, "fps": 10.0, "loop": true, "source": "player2-run-as-jump"},
			"hurt": {"row": 5, "count": 6, "fps": 8.0, "loop": false, "source": "player2-hurt"},
			"death": {"row": 7, "count": 6, "fps": 7.0, "loop": false, "source": "player2-death"},
		}
	if size == Vector2i(1152, 864):
		return {
			"cell_size": 96,
			"idle": {"row": 0, "count": 4, "fps": 6.0, "loop": true, "source": "idle"},
			"run": {"row": 1, "count": 8, "fps": 12.0, "loop": true, "source": "run-right"},
			"attack_a": {"row": 2, "count": 12, "fps": 18.0, "loop": false, "source": "attack-light"},
			"parry": {"row": 3, "count": 6, "fps": 14.0, "loop": false, "source": "parry"},
			"block": {"row": 4, "count": 4, "fps": 8.0, "loop": true, "source": "guard"},
			"dash": {"row": 5, "count": 6, "fps": 14.0, "loop": false, "source": "dash"},
			"jump": {"row": 6, "count": 6, "fps": 10.0, "loop": true, "source": "jump"},
			"hurt": {"row": 7, "count": 4, "fps": 8.0, "loop": false, "source": "hurt"},
			"death": {"row": 8, "count": 8, "fps": 8.0, "loop": false, "source": "death"},
		}
	return {
		"cell_size": 64,
		"idle": {"row": 0, "count": 4, "fps": 6.0, "loop": true, "source": "idle"},
		"run": {"row": 1, "count": 8, "fps": 12.0, "loop": true, "source": "run"},
		"attack_a": {"row": 2, "count": 12, "fps": 24.0, "loop": false, "source": "attack_a"},
		"parry": {"row": 3, "count": 6, "fps": 18.0, "loop": false, "source": "parry"},
		"block": {"row": 4, "count": 4, "fps": 8.0, "loop": true, "source": "block"},
		"dash": {"row": 5, "count": 6, "fps": 20.0, "loop": false, "source": "dash"},
		"jump": {"row": 6, "count": 6, "fps": 8.0, "loop": true, "source": "jump"},
		"hurt": {"row": 7, "count": 4, "fps": 10.0, "loop": false, "source": "hurt"},
		"death": {"row": 7, "count": 8, "fps": 8.0, "loop": false, "source": "death"},
	}

func _add_layout_animation(frames: SpriteFrames, animation: StringName) -> void:
	var config: Dictionary = sprite_sheet_layout[String(animation)]
	_add_sheet_animation(
		frames,
		animation,
		int(config["row"]),
		int(config["count"]),
		float(config["fps"]),
		bool(config["loop"])
	)

func _add_sheet_animation(frames: SpriteFrames, animation: StringName, row: int, count: int, fps: float, loop: bool) -> void:
	var cell_size: int = int(sprite_sheet_layout["cell_size"])
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for column in count:
		var texture := AtlasTexture.new()
		texture.atlas = PLAYER_SHEET
		texture.region = Rect2(column * cell_size, row * cell_size, cell_size, cell_size)
		frames.add_frame(animation, texture)

func _play_state_animation() -> void:
	var next_animation := "idle"
	match state:
		PlayerState.IDLE:
			next_animation = "idle"
		PlayerState.MOVE:
			next_animation = "run"
		PlayerState.ATTACK:
			next_animation = "attack_a"
		PlayerState.PARRY:
			next_animation = "parry"
		PlayerState.BLOCK:
			next_animation = "block"
		PlayerState.DASH:
			next_animation = "dash"
		PlayerState.JUMP:
			next_animation = "jump"
		PlayerState.HURT, PlayerState.STUNNED:
			next_animation = "hurt"
		PlayerState.DEAD:
			next_animation = "death"

	if current_animation != next_animation:
		current_animation = next_animation
		sprite.play(next_animation)

func _trigger_parry_feedback() -> void:
	parry_flash_timer = parry_flash_time
	hitstop_timer = parry_hitstop_time
	stored_velocity = Vector2(-facing * parry_rebound, velocity.y)
	velocity = Vector2.ZERO
	sprite.speed_scale = 0.0
	_shake_camera(18.0, 0.11)

func _trigger_block_feedback() -> void:
	block_flash_timer = impact_flash_time
	velocity.x = -facing * block_knockback
	_shake_camera(10.0, 0.10)

func _trigger_hurt_feedback() -> void:
	hurt_flash_timer = impact_flash_time
	velocity.x = -facing * hurt_knockback
	_shake_camera(13.0, 0.12)

func _trigger_attack_hit_feedback() -> void:
	hitstop_timer = max(hitstop_timer, attack_hitstop_time)
	stored_velocity = velocity
	velocity = Vector2.ZERO
	sprite.speed_scale = 0.0
	_shake_camera(7.0, 0.075)

func _shake_camera(amount: float, duration: float) -> void:
	var camera := get_tree().get_first_node_in_group("feedback_camera")
	if camera != null and camera.has_method("shake"):
		camera.shake(amount, duration)

func _enter_dead() -> void:
	health = 0.0
	posture = min(posture, max_posture)
	is_blocking = false
	is_attacking = false
	is_parrying = false
	is_dashing = false
	is_perfect_dodging = false
	is_invulnerable = true
	action_timer = 0.0
	dash_timer = 0.0
	attack_has_hit = false
	hitstop_timer = 0.0
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	_play_sfx(death_sfx)
	_set_state(PlayerState.DEAD)
	_update_visuals()

func _load_optional_sfx() -> void:
	_load_optional_stream(ATTACK_SFX_PATH, attack_sfx)
	_load_optional_stream(PARRY_SFX_PATH, parry_sfx)
	_load_optional_stream(BLOCK_SFX_PATH, block_sfx)
	_load_optional_stream(HURT_SFX_PATH, hurt_sfx)
	_load_optional_stream(DEATH_SFX_PATH, death_sfx)
	_load_optional_stream(DASH_SFX_PATH, dash_sfx)
	_load_optional_stream(PERFECT_DODGE_SFX_PATH, perfect_dodge_sfx)

func _load_optional_stream(path: String, player: AudioStreamPlayer2D) -> void:
	if ResourceLoader.exists(path):
		player.stream = load(path)

func _play_sfx(player: AudioStreamPlayer2D) -> void:
	if player.stream != null:
		player.play()

func _register_combat_input(input_type: int) -> void:
	if combat_runtime == null:
		combat_runtime = get_tree().get_first_node_in_group("combat_runtime")
	if combat_runtime != null and combat_runtime.has_method("register_input"):
		combat_runtime.register_input(input_type, Time.get_ticks_msec())

func reset_combat_state() -> void:
	health = max_health
	posture = 0.0
	heartbeat = CombatMathScript.MIN_HEARTBEAT
	state = PlayerState.IDLE
	previous_state = PlayerState.IDLE
	is_blocking = false
	is_attacking = false
	is_parrying = false
	is_dashing = false
	is_perfect_dodging = false
	is_invulnerable = false
	block_age = 0.0
	block_time_left = 0.0
	action_timer = 0.0
	dash_timer = 0.0
	dash_direction = 1.0
	attack_has_hit = false
	parry_flash_timer = 0.0
	block_flash_timer = 0.0
	hurt_flash_timer = 0.0
	perfect_dodge_timer = 0.0
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	global_position = spawn_position
	sprite.speed_scale = 1.0
	_set_state(PlayerState.IDLE)
	_update_visuals()
	stats_changed.emit()
