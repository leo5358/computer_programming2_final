extends CharacterBody2D

signal stats_changed
signal died

const CombatMathScript = preload("res://scripts/combat_math.gd")
const CombatServerScript = preload("res://scripts/combat_server.gd")
const PLAYER_SHEET_PATHS := [
	"res://assets/sprites/player/player4.png",
	"res://assets/sprites/player/player3_spritesheet.png",
	"res://assets/sprites/player/player2.png",
	"res://assets/sprites/player/player_sheet.png",
]
const PLAYER_STRIP_CELL_SIZE := 96
const PLAYER_STRIP_PATHS := {
	"idle": "res://assets/sprites/player/idle.png",
	"walk": "res://assets/sprites/player/walk.png",
	"run": "res://assets/sprites/player/run.png",
	"attack_a": "res://assets/sprites/player/attack.png",
	"attack_chop": "res://assets/sprites/player/chop.png",
	"deflect": "res://assets/sprites/player/deflect.png",
	"parry": "res://assets/sprites/player/deflect.png",
	"block": "res://assets/sprites/player/deflect.png",
	"dash": "res://assets/sprites/player/dash.png",
	"jump": "res://assets/sprites/player/jump.png",
	"hurt": "res://assets/sprites/player/hurt.png",
	"death": "res://assets/sprites/player/death.png",
}
const PLAYER_STRIP_FRAME_REGIONS := {
	"attack_a": [
		[0, 0, 96, 96],
		[96, 0, 96, 96],
		[192, 0, 92, 96],
		[284, 0, 92, 96],
		[376, 0, 111, 96],
		[487, 0, 109, 96],
		[596, 0, 96, 96],
		[692, 0, 96, 96],
	],
}
const HIT_IMPACT_SHEET_PATH := "res://assets/sprites/vfx/hit_impact_sheet.png"
const HIT_IMPACT_CELL_SIZE := 128
const HIT_IMPACT_FRAME_COUNT := 6
const ATTACK_HIT_SFX_PATHS := [
	"res://assets/sfx/attack1.WAV",
	"res://assets/sfx/attack2.WAV",
	"res://assets/sfx/attack3.WAV",
	"res://assets/sfx/attack4.WAV",
	"res://assets/sfx/attack5.WAV",
]
const CHOP_HIT_SFX_PATH := "res://assets/sfx/attack6.WAV"
const ATTACK_MISS_SFX_PATHS := [
	"res://assets/sfx/attack_miss1.WAV",
	"res://assets/sfx/attack_miss2.WAV",
]
const PARRY_SFX_PATH := "res://assets/sfx/player_parry.wav"
const BLOCK_SFX_PATH := "res://assets/sfx/player_block.wav"
const HURT_SFX_PATH := "res://assets/sfx/player_hurt.wav"
const DEATH_SFX_PATH := "res://assets/sfx/player_death.wav"
const DASH_SFX_PATH := "res://assets/sfx/dodge.WAV"
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

@export var walk_speed := 240.0
@export var run_speed := 400.0
@export var max_speed := 400.0
@export var acceleration := 2000.0
@export var friction := 3200.0
@export var turn_brake := 4200.0
@export var dash_impulse := 560.0
@export var jump_velocity := -430.0
@export var coyote_time := 0.1
@export var max_health := 100.0
@export var max_posture := 100.0
@export var base_attack_damage := 16.0
@export var attack_posture_damage := 18.0
@export var block_posture_damage := 14.0
@export var perfect_block_posture_damage := 36.0
@export var attack_startup := 0.375
@export var attack_active_time := 0.25
@export var attack_recovery := 0.375
@export var attack_buffer_time := 0.16
@export var attack_deflected_stun_time := 0.42
@export var attack_deflected_rebound := 260.0
@export var attack_deflected_posture_damage := 10.0
@export var attack_deflected_attack_lockout_time := 0.58
@export var attack_step_impulse := 140.0
@export var chop_step_impulse := 95.0
@export var attack_soft_lock_impulse := 260.0
@export var chop_soft_lock_impulse := 190.0
@export var attack_lunge_time := 0.38
@export var attack_soft_lock_min_distance := 58.0
@export var attack_soft_lock_max_distance := 110.0
@export var attack_soft_lock_vertical_tolerance := 52.0
@export var attack_buffer_min_recovery_elapsed := 0.0
@export var parry_window := 0.45
@export var parry_success_recovery_time := 0.12
@export var parry_flash_time := 0.14
@export var dash_duration := 0.14
@export var perfect_dodge_duration := 0.14
@export var perfect_dodge_impulse := 520.0
@export var perfect_dodge_hitstop_time := 0.09
@export var hurt_time := 1.0
@export var stunned_time := 1.2
@export var posture_break_animation_speed := 0.72
@export var impact_flash_time := 0.20
@export var attack_hitstop_time := 0.078
@export var chop_hitstop_time := 0.12
@export var attack_hit_shake_amount := 9.0
@export var chop_hit_shake_amount := 14.0
@export var attack_hit_shake_duration := 0.085
@export var chop_hit_shake_duration := 0.11
@export var hit_impact_vfx_time := 0.09
@export var parry_hitstop_time := 0.13
@export var block_knockback := 150.0
@export var hurt_knockback := 480.0
@export var hurt_slide_friction := 1100.0
@export var parry_rebound := 120.0

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
var is_running := false
var is_perfect_dodging := false
var is_invulnerable := false
var block_age := 0.0
var parry_elapsed := 0.0
var block_time_left := 0.0
var facing := 1.0
var coyote_timer := 0.0
var action_timer := 0.0
var dash_timer := 0.0
var dash_direction := 1.0
var attack_elapsed := 0.0
var attack_buffer_timer := 0.0
var attack_buffer_queued := false
var attack_lockout_timer := 0.0
var attack_has_hit := false
var attack_combo_step := 0
var current_attack_animation := "attack_a"
var hurt_animation := "hurt"
var attack_lunge_timer := 0.0
var current_animation := ""
var parry_flash_timer := 0.0
var block_flash_timer := 0.0
var hurt_flash_timer := 0.0
var perfect_dodge_timer := 0.0
var hit_impact_vfx_timer := 0.0
var hitstop_timer := 0.0
var stored_velocity := Vector2.ZERO
var combat_runtime: Node
var spawn_position := Vector2.ZERO
var sprite_sheet_layout: Dictionary = {}
var player_sheet: Texture2D = null
var attack_hit_streams: Array[AudioStream] = []
var chop_hit_stream: AudioStream = null
var attack_miss_streams: Array[AudioStream] = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var hit_impact_vfx: AnimatedSprite2D = get_node_or_null("HitImpactVfx") as AnimatedSprite2D
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
	_setup_hit_impact_vfx()
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
	if _can_start_attack() and Input.is_action_just_pressed("attack"):
		_start_attack()
	elif _can_buffer_attack() and Input.is_action_just_pressed("attack"):
		queue_attack_buffer()

	if _can_start_defensive_action() and Input.is_action_just_pressed("block"):
		_start_parry()

	if _can_start_defensive_action() and Input.is_action_just_pressed("dash"):
		_start_dash()

	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0 and _can_jump():
		_register_combat_input(CombatServerScript.InputType.JUMP)
		velocity.y = jump_velocity
		coyote_timer = 0.0
		_set_state(PlayerState.JUMP)

func _update_movement(delta: float) -> void:
	if state == PlayerState.ATTACK:
		attack_lunge_timer -= delta
		if attack_lunge_timer <= 0.0:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return

	if state == PlayerState.HURT:
		velocity.x = move_toward(velocity.x, 0.0, hurt_slide_friction * delta)
		return

	if state in [PlayerState.PARRY, PlayerState.STUNNED]:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return

	if state == PlayerState.DASH:
		velocity.x = dash_direction * (perfect_dodge_impulse if is_perfect_dodging else dash_impulse)
		return

	var direction := Input.get_axis("move_left", "move_right")
	is_running = direction != 0.0 and Input.is_key_pressed(KEY_SHIFT)
	_apply_horizontal_control(direction, delta)

	attack_area.position.x = 34.0 * facing

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
		var target_speed := run_speed if is_running else walk_speed
		velocity.x = move_toward(velocity.x, direction * target_speed, accel * delta)
	else:
		is_running = false
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _update_action_state(delta: float) -> void:
	attack_buffer_timer = max(0.0, attack_buffer_timer - delta)
	attack_lockout_timer = max(0.0, attack_lockout_timer - delta)
	if state == PlayerState.ATTACK:
		action_timer -= delta
		attack_elapsed += delta
		var active := attack_elapsed >= attack_startup and attack_elapsed < attack_startup + attack_active_time
		is_attacking = active
		if active and not attack_has_hit:
			_apply_attack_hit()
			attack_has_hit = true
		if action_timer <= 0.0:
			is_attacking = false
			attack_has_hit = false
			if attack_buffer_queued:
				attack_buffer_queued = false
				attack_buffer_timer = 0.0
				_start_attack()
			else:
				_set_state(PlayerState.IDLE)

	elif state == PlayerState.PARRY:
		action_timer -= delta
		parry_elapsed += delta
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
			sprite.speed_scale = 1.0
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
	current_attack_animation = "attack_chop" if attack_combo_step == 2 else "attack_a"
	attack_combo_step = (attack_combo_step + 1) % 3
	attack_lunge_timer = attack_lunge_time
	velocity.x = facing * _attack_step_impulse()
	_set_state(PlayerState.ATTACK)
	_force_play_animation(current_attack_animation)
	action_timer = attack_startup + attack_active_time + attack_recovery
	attack_elapsed = 0.0
	is_attacking = false
	attack_has_hit = false

func queue_attack_buffer() -> void:
	if not _should_accept_attack_buffer():
		return
	attack_buffer_queued = true
	attack_buffer_timer = attack_buffer_time

func _should_accept_attack_buffer() -> bool:
	if state != PlayerState.ATTACK:
		return false
	var active_end := attack_startup + attack_active_time
	if attack_elapsed < active_end + attack_buffer_min_recovery_elapsed:
		return false
	if _has_forward_movement_intent() and _find_attack_soft_lock_target() == null:
		return false
	return true

func _has_forward_movement_intent() -> bool:
	var direction := Input.get_axis("move_left", "move_right")
	return direction != 0.0 and sign(direction) == facing

func _attack_step_impulse() -> float:
	var has_soft_lock_target := _find_attack_soft_lock_target() != null
	if current_attack_animation == "attack_chop":
		return chop_soft_lock_impulse if has_soft_lock_target else chop_step_impulse
	return attack_soft_lock_impulse if has_soft_lock_target else attack_step_impulse

func _find_attack_soft_lock_target() -> Node2D:
	for group_name in ["enemy", "boss"]:
		for target in get_tree().get_nodes_in_group(group_name):
			if target is Node2D and _is_valid_attack_soft_lock_target(target):
				return target
	return null

func _is_valid_attack_soft_lock_target(target: Node2D) -> bool:
	var offset := target.global_position - global_position
	var forward_distance := offset.x * facing
	if forward_distance < attack_soft_lock_min_distance:
		return false
	if forward_distance > attack_soft_lock_max_distance:
		return false
	if abs(offset.y) > attack_soft_lock_vertical_tolerance:
		return false
	return true

func _apply_attack_hit() -> void:
	var damage: float = math.damage_with_adrenaline(base_attack_damage, heartbeat)
	var posture_damage: float = math.posture_damage_with_adrenaline(attack_posture_damage, heartbeat)
	var hit_confirmed := false
	var was_deflected := false
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("can_be_executed") and body.can_be_executed() and body.has_method("execute"):
			body.execute()
			hit_confirmed = true
			continue
		if body.has_method("receive_player_attack"):
			var result: Variant = body.receive_player_attack(damage, posture_damage)
			if not (result is bool and result == false):
				hit_confirmed = true
				if result is Dictionary and bool(result.get("guarded", false)):
					was_deflected = true
	if hit_confirmed:
		if was_deflected:
			_receive_attack_deflected()
		else:
			_play_random_attack_hit_sfx()
			_trigger_attack_hit_feedback()
	else:
		_play_random_attack_miss_sfx()

func _start_parry() -> void:
	_register_combat_input(CombatServerScript.InputType.PARRY)
	_set_state(PlayerState.PARRY)
	is_parrying = true
	is_blocking = false
	block_age = 0.0
	parry_elapsed = 0.0
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
	_play_sfx(dash_sfx)
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

func receive_enemy_attack(damage: float, posture_damage: float, attacker: Node = null, attack_type: int = CombatServerScript.AttackType.NORMAL) -> void:
	if health <= 0.0:
		return
	if is_invulnerable and attack_type != CombatServerScript.AttackType.SWEEP:
		return

	var can_guard := attack_type != CombatServerScript.AttackType.THRUST
	var can_block := attack_type != CombatServerScript.AttackType.SWEEP
	var perfect_parry := false
	if is_parrying and can_guard:
		perfect_parry = true
		if attacker != null and attacker.has_method("can_be_perfect_parried_by"):
			perfect_parry = attacker.can_be_perfect_parried_by(self)
	if perfect_parry or (is_parrying and can_guard and can_block) or (is_blocking and can_guard and can_block):
		var perfect := perfect_parry
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
			_trigger_hurt_feedback(_knockback_direction_from_attacker(attacker))
			hurt_animation = "hurt"
			_set_state(PlayerState.HURT)
			_force_play_animation("hurt")
			action_timer = hurt_time
			is_invulnerable = true

	if posture >= max_posture:
		_enter_stunned()

	stats_changed.emit()
	if health <= 0.0:
		_enter_dead()
		died.emit()

func begin_local_hitstop(duration: float, resume_velocity: Vector2 = Vector2.INF) -> void:
	hitstop_timer = max(hitstop_timer, duration)
	stored_velocity = velocity if resume_velocity == Vector2.INF else resume_velocity
	velocity = Vector2.ZERO
	if sprite != null:
		sprite.speed_scale = 0.0

func _set_state(next_state: int) -> void:
	if state == next_state:
		return
	previous_state = state
	state = next_state

func _enter_stunned() -> void:
	_set_state(PlayerState.STUNNED)
	posture = 100.0
	action_timer = stunned_time
	is_blocking = false
	is_attacking = false
	is_parrying = false
	is_dashing = false
	is_running = false
	is_perfect_dodging = false
	is_invulnerable = true
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	current_animation = ""

func _can_start_action() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVE, PlayerState.JUMP, PlayerState.BLOCK]

func _can_start_attack() -> bool:
	return _can_start_action() and attack_lockout_timer <= 0.0

func _can_start_defensive_action() -> bool:
	if _can_start_action():
		return true
	return state == PlayerState.HURT and hurt_animation == "deflect"

func _can_buffer_attack() -> bool:
	return state == PlayerState.ATTACK

func _can_jump() -> bool:
	return state not in [PlayerState.ATTACK, PlayerState.PARRY, PlayerState.DASH, PlayerState.HURT, PlayerState.STUNNED]

func _update_visuals() -> void:
	parry_flash_timer = max(0.0, parry_flash_timer - get_physics_process_delta_time())
	block_flash_timer = max(0.0, block_flash_timer - get_physics_process_delta_time())
	hurt_flash_timer = max(0.0, hurt_flash_timer - get_physics_process_delta_time())
	perfect_dodge_timer = max(0.0, perfect_dodge_timer - get_physics_process_delta_time())
	hit_impact_vfx_timer = max(0.0, hit_impact_vfx_timer - get_physics_process_delta_time())
	if hit_impact_vfx != null:
		hit_impact_vfx.visible = hit_impact_vfx_timer > 0.0
	sprite.flip_h = facing < 0.0
	_play_state_animation()

func _state_name() -> String:
	return PlayerState.keys()[state]

func _setup_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	if _player_strips_available():
		sprite_sheet_layout = {"cell_size": PLAYER_STRIP_CELL_SIZE, "source": "strips"}
		_add_strip_animation(frames, "idle", 6.0, true)
		_add_strip_animation(frames, "walk", 8.0, true)
		_add_strip_animation(frames, "run", 12.0, true)
		_add_strip_animation(frames, "attack_a", 8.0, false)
		_add_strip_animation(frames, "attack_chop", 8.0, false)
		_add_strip_animation(frames, "deflect", 14.0, false)
		_add_strip_animation(frames, "parry", 14.0, false)
		_add_strip_animation(frames, "block", 8.0, true)
		_add_strip_animation(frames, "dash", 18.0, false)
		_add_strip_animation(frames, "jump", 10.0, true)
		_add_strip_animation(frames, "hurt", 8.0, false)
		_add_strip_animation(frames, "death", 7.0, false)
	else:
		player_sheet = _load_first_available_player_sheet()
		if player_sheet == null:
			push_error("No player art found in res://assets/sprites/player")
			return
		sprite_sheet_layout = _resolve_sheet_layout(player_sheet.get_size())
		_add_layout_animation(frames, "idle")
		_add_layout_animation(frames, "walk", "run")
		_add_layout_animation(frames, "run")
		_add_layout_animation(frames, "attack_a")
		_add_layout_animation(frames, "attack_chop", "attack_a")
		_add_layout_animation(frames, "parry")
		_add_layout_animation(frames, "block")
		_add_layout_animation(frames, "dash")
		_add_layout_animation(frames, "jump")
		_add_layout_animation(frames, "hurt")
		_add_layout_animation(frames, "death")
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -float(sprite_sheet_layout["cell_size"]) * 0.5)
	sprite.play("idle")

func _setup_hit_impact_vfx() -> void:
	if hit_impact_vfx == null or not ResourceLoader.exists(HIT_IMPACT_SHEET_PATH):
		return
	var texture := load(HIT_IMPACT_SHEET_PATH) as Texture2D
	if texture == null:
		return
	var frames := SpriteFrames.new()
	_add_hit_impact_animation(frames, "hit", texture, 0, 28.0)
	_add_hit_impact_animation(frames, "chop", texture, 1, 24.0)
	hit_impact_vfx.sprite_frames = frames
	hit_impact_vfx.visible = false

func _add_hit_impact_animation(frames: SpriteFrames, animation: StringName, texture: Texture2D, row: int, fps: float) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, false)
	for column in HIT_IMPACT_FRAME_COUNT:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(column * HIT_IMPACT_CELL_SIZE, row * HIT_IMPACT_CELL_SIZE, HIT_IMPACT_CELL_SIZE, HIT_IMPACT_CELL_SIZE)
		frames.add_frame(animation, atlas_texture)

func _player_strips_available() -> bool:
	for path in PLAYER_STRIP_PATHS.values():
		if not ResourceLoader.exists(path):
			return false
	return true

func _load_first_available_player_sheet() -> Texture2D:
	for path in PLAYER_SHEET_PATHS:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

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

func _add_layout_animation(frames: SpriteFrames, animation: StringName, source_animation: String = "") -> void:
	var config_key := String(animation) if source_animation.is_empty() else source_animation
	var config: Dictionary = sprite_sheet_layout[config_key]
	_add_sheet_animation(
		frames,
		animation,
		int(config["row"]),
		int(config["count"]),
		float(config["fps"]),
		bool(config["loop"])
	)

func _add_strip_animation(frames: SpriteFrames, animation: StringName, fps: float, loop: bool) -> void:
	var texture := load(String(PLAYER_STRIP_PATHS[String(animation)])) as Texture2D
	var custom_regions: Array = PLAYER_STRIP_FRAME_REGIONS.get(String(animation), [])
	var cell_size := PLAYER_STRIP_CELL_SIZE
	var frame_count := int(texture.get_width() / cell_size)
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	if not custom_regions.is_empty():
		for region in custom_regions:
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
			atlas_texture.filter_clip = true
			frames.add_frame(animation, atlas_texture)
		return
	for column in frame_count:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(column * cell_size, 0, cell_size, cell_size)
		atlas_texture.filter_clip = true
		frames.add_frame(animation, atlas_texture)

func _add_sheet_animation(frames: SpriteFrames, animation: StringName, row: int, count: int, fps: float, loop: bool) -> void:
	var cell_size: int = int(sprite_sheet_layout["cell_size"])
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for column in count:
		var texture := AtlasTexture.new()
		texture.atlas = player_sheet
		texture.region = Rect2(column * cell_size, row * cell_size, cell_size, cell_size)
		frames.add_frame(animation, texture)

func _play_state_animation() -> void:
	var next_animation := "idle"
	match state:
		PlayerState.IDLE:
			next_animation = "idle"
		PlayerState.MOVE:
			next_animation = "run" if is_running else "walk"
		PlayerState.ATTACK:
			next_animation = current_attack_animation
		PlayerState.PARRY:
			next_animation = "parry"
		PlayerState.BLOCK:
			next_animation = "block"
		PlayerState.DASH:
			next_animation = "dash"
		PlayerState.JUMP:
			next_animation = "jump"
		PlayerState.HURT:
			next_animation = hurt_animation
		PlayerState.STUNNED:
			_play_stunned_animation()
			return
		PlayerState.DEAD:
			next_animation = "death"

	if current_animation != next_animation:
		current_animation = next_animation
		sprite.play(next_animation)

func _force_play_animation(animation: StringName) -> void:
	current_animation = animation
	if sprite == null:
		return
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play(animation)

func _play_stunned_animation() -> void:
	var recovery_started := action_timer <= stunned_time * 0.5
	var next_animation := "stunned_death_reverse" if recovery_started else "stunned_death_forward"
	if current_animation == next_animation:
		return
	current_animation = next_animation
	sprite.speed_scale = posture_break_animation_speed
	if recovery_started:
		sprite.play_backwards("death")
	else:
		sprite.play("death")

func _trigger_parry_feedback() -> void:
	parry_flash_timer = parry_flash_time
	action_timer = min(action_timer, parry_success_recovery_time)
	hitstop_timer = parry_hitstop_time
	stored_velocity = Vector2(-facing * parry_rebound, velocity.y)
	velocity = Vector2.ZERO
	sprite.speed_scale = 0.0
	_shake_camera(18.0, 0.11)

func _trigger_block_feedback() -> void:
	block_flash_timer = impact_flash_time
	velocity.x = -facing * block_knockback
	_shake_camera(10.0, 0.10)

func _trigger_hurt_feedback(knockback_direction := INF) -> void:
	hurt_flash_timer = impact_flash_time
	var direction := -facing if knockback_direction == INF else float(knockback_direction)
	velocity.x = direction * hurt_knockback
	_shake_camera(13.0, 0.12)

func _knockback_direction_from_attacker(attacker: Node) -> float:
	if attacker is Node2D:
		var direction: float = sign(global_position.x - (attacker as Node2D).global_position.x)
		if direction != 0.0:
			return direction
	return -facing

func _receive_attack_deflected() -> void:
	is_attacking = false
	attack_has_hit = false
	attack_buffer_queued = false
	attack_buffer_timer = 0.0
	attack_lockout_timer = attack_deflected_attack_lockout_time
	attack_lunge_timer = 0.0
	attack_combo_step = 0
	posture = math.add_posture(posture, attack_deflected_posture_damage)
	heartbeat = math.add_heartbeat(heartbeat, 6.0)
	action_timer = attack_deflected_stun_time
	hurt_flash_timer = impact_flash_time * 0.65
	velocity.x = -facing * attack_deflected_rebound
	_play_sfx(block_sfx)
	_shake_camera(8.0, 0.08)
	hurt_animation = "deflect"
	_set_state(PlayerState.HURT)
	_force_play_animation("deflect")
	stats_changed.emit()

func _trigger_attack_hit_feedback() -> void:
	var is_chop := current_attack_animation == "attack_chop"
	var shake_amount := chop_hit_shake_amount if current_attack_animation == "attack_chop" else attack_hit_shake_amount
	var shake_duration := chop_hit_shake_duration if current_attack_animation == "attack_chop" else attack_hit_shake_duration
	velocity = Vector2.ZERO
	_trigger_hit_impact_vfx(is_chop)
	_shake_camera(shake_amount, shake_duration)

func _trigger_hit_impact_vfx(is_chop: bool) -> void:
	if hit_impact_vfx == null:
		return
	hit_impact_vfx_timer = hit_impact_vfx_time
	hit_impact_vfx.visible = true
	hit_impact_vfx.position = attack_area.position + Vector2(20.0 * facing, 0.0)
	hit_impact_vfx.flip_h = facing < 0.0
	if hit_impact_vfx.sprite_frames != null:
		hit_impact_vfx.play("chop" if is_chop else "hit")

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
	attack_hit_streams = _load_optional_streams(ATTACK_HIT_SFX_PATHS)
	if ResourceLoader.exists(CHOP_HIT_SFX_PATH):
		chop_hit_stream = load(CHOP_HIT_SFX_PATH)
	attack_miss_streams = _load_optional_streams(ATTACK_MISS_SFX_PATHS)
	_load_optional_stream(PARRY_SFX_PATH, parry_sfx)
	_load_optional_stream(BLOCK_SFX_PATH, block_sfx)
	_load_optional_stream(HURT_SFX_PATH, hurt_sfx)
	_load_optional_stream(DEATH_SFX_PATH, death_sfx)
	_load_optional_stream(DASH_SFX_PATH, dash_sfx)
	_load_optional_stream(PERFECT_DODGE_SFX_PATH, perfect_dodge_sfx)

func _load_optional_stream(path: String, player: AudioStreamPlayer2D) -> void:
	if ResourceLoader.exists(path):
		player.stream = load(path)

func _load_optional_streams(paths: Array) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	for path in paths:
		if ResourceLoader.exists(path):
			streams.append(load(path))
	return streams

func _play_random_attack_hit_sfx() -> void:
	if current_attack_animation == "attack_chop" and chop_hit_stream != null:
		attack_sfx.stream = chop_hit_stream
		attack_sfx.play()
		return
	_play_random_stream(attack_sfx, attack_hit_streams)

func _play_random_attack_miss_sfx() -> void:
	_play_random_stream(attack_sfx, attack_miss_streams)

func _play_random_stream(player: AudioStreamPlayer2D, streams: Array[AudioStream]) -> void:
	if streams.is_empty():
		return
	var index := randi() % streams.size()
	player.stream = streams[index]
	player.play()

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
	parry_elapsed = 0.0
	block_time_left = 0.0
	action_timer = 0.0
	dash_timer = 0.0
	dash_direction = 1.0
	attack_elapsed = 0.0
	attack_buffer_timer = 0.0
	attack_buffer_queued = false
	attack_lockout_timer = 0.0
	attack_has_hit = false
	attack_combo_step = 0
	current_attack_animation = "attack_a"
	hurt_animation = "hurt"
	attack_lunge_timer = 0.0
	parry_flash_timer = 0.0
	block_flash_timer = 0.0
	hurt_flash_timer = 0.0
	perfect_dodge_timer = 0.0
	hit_impact_vfx_timer = 0.0
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	global_position = spawn_position
	sprite.speed_scale = 1.0
	if hit_impact_vfx != null:
		hit_impact_vfx.visible = false
	_set_state(PlayerState.IDLE)
	_update_visuals()
	stats_changed.emit()
