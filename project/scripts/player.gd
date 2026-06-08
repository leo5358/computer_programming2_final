extends CharacterBody2D

signal stats_changed
signal died
signal revive_prompt_requested
signal death_animation_finished(revive_pending: bool)

const CombatMathScript = preload("res://scripts/combat_math.gd")
const CombatServerScript = preload("res://scripts/combat_server.gd")
const KunaiScene = preload("res://scenes/Kunai.tscn")
const AshBallScene = preload("res://scenes/AshBall.tscn")
const PLAYER_SHEET_PATHS := [
	"res://assets/sprites/player/player4.png",
	"res://assets/sprites/player/player3_spritesheet.png",
	"res://assets/sprites/player/player2.png",
	"res://assets/sprites/player/player_sheet.png",
]
const PLAYER_STRIP_CELL_SIZE := 96
const DEFAULT_SPRITE_SCALE := Vector2.ONE
const WALK_SPRITE_SCALE := Vector2(1.1, 1.1)
const DEFLECT_MISS_SPRITE_SCALE := Vector2(1.1, 1.1)
const PLAYER_STRIP_PATHS := {
	"idle": "res://assets/sprites/player/idle.png",
	"walk": "res://assets/sprites/player/walk.png",
	"run": "res://assets/sprites/player/run.png",
	"attack_a": "res://assets/sprites/player/attack.png",
	"attack_chop": "res://assets/sprites/player/chop.png",
	"attack_thrust": "res://assets/sprites/player/thrust.png",
	"deflect": "res://assets/sprites/player/deflect.png",
	"deflect_miss": "res://assets/sprites/player/deflect_miss.png",
	"parry": "res://assets/sprites/player/deflect_miss.png",
	"block": "res://assets/sprites/player/deflect_miss.png",
	"dash": "res://assets/sprites/player/dash.png",
	"jump": "res://assets/sprites/player/jump.png",
	"climb": "res://assets/sprites/player/climb.png",
	"eat": "res://assets/sprites/player/eat.png",
	"mudra": "res://assets/sprites/player/mudra.png",
	"throw": "res://assets/sprites/player/throw.png",
	"hurt": "res://assets/sprites/player/hurt.png",
	"death": "res://assets/sprites/player/death.png",
}
const PLAYER_THRUST_WIDE_STRIP_PATH := "res://assets/sprites/player/thrust copy.png"
const ITEM_ACTION_TIME := 0.8
const MUDRA_FOCUS_FRAME_START := 3
const MUDRA_FOCUS_FRAME_END := 5
const MUDRA_FOCUS_DURATION_RATIO := 0.70
const DEFAULT_ITEM_COUNTS := {
	"kunai": 0,
	"ash_balls": 0,
	"gourd": 3,
	"pill": 0,
	"capsule": 0,
}
const ITEM_ORDER: Array[String] = ["kunai", "ash_balls", "gourd", "pill", "capsule"]
const ATTACK_ITEM_IDS: Array[String] = ["kunai", "ash_balls"]
const HEAL_ITEM_IDS: Array[String] = ["gourd", "pill", "capsule"]
const EAT_ITEM_IDS := {
	"gourd": true,
	"pill": true,
	"capsule": true,
}
const GOURD_HEAL_PERCENT := 0.30
const ADRENALINE_HEARTBEAT_BOOST := 25.0
const BLOOD_PRESSURE_HEARTBEAT_DROP := 25.0
const SMOKE_BOMB_BOSS_PAUSE_TIME := 2.5
const SMOKE_BOMB_MINOR_STUN_TIME := 1.25
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
	"hurt": [
		[0, 0, 106, 96],
		[106, 0, 101, 96],
		[207, 0, 96, 96],
		[303, 0, 96, 96],
		[399, 0, 92, 96],
		[491, 0, 96, 96],
		[587, 0, 91, 96],
		[678, 0, 90, 96],
	],
	"attack_thrust": [
		[0, 0, 96, 96],
		[96, 0, 96, 96],
		[192, 0, 96, 96],
		[288, 0, 96, 96],
		{"path": PLAYER_THRUST_WIDE_STRIP_PATH, "region": [0, 0, 123, 96]},
		[192, 0, 96, 96],
		[605, 0, 78, 96],
		[683, 0, 78, 96],
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
const KUNAI_SFX_PATH := "res://assets/sfx/kunai.MP3"
const ATTACK_ANIMATION_FPS := 11.43

enum PlayerState {
	IDLE,
	MOVE,
	ATTACK,
	PARRY,
	BLOCK,
	DASH,
	JUMP,
	WALL_CLIMB,
	EAT,
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
@export var wall_climb_speed := 130.0
@export var wall_slide_speed := 80.0
@export var wall_stick_speed := 35.0
@export var auto_step_enabled := true
@export var auto_step_max_height := 32.0
@export var auto_step_probe_distance := 14.0
@export var auto_step_increment := 4.0
@export var wall_climb_requires_jump := true
@export var jump_to_ledge_climb_lockout := 0.28
@export var world_boundary_climb_margin := 24.0
@export var max_health := 100.0
@export var max_posture := 100.0
@export var posture_disengage_delay := 6.0
@export_range(0.0, 1.0, 0.01) var posture_recovery_percent_per_second := 0.08
@export var max_lives := 2
@export var world_death_bounds_enabled := true
@export var world_death_bounds := Rect2(-1024.0, -2048.0, 22000.0, 4096.0)
@export var base_attack_damage := 16.0
@export var attack_posture_damage := 18.0
@export var block_posture_damage := 14.0
@export var perfect_block_posture_damage := 36.0
@export var attack_startup := 0.16
@export var attack_active_time := 0.24
@export var attack_recovery := 0.30
@export var attack_buffer_time := 0.16
@export var attack_deflected_stun_time := 0.42
@export var attack_deflected_rebound := 260.0
@export var attack_deflected_posture_damage := 10.0
@export var attack_deflected_attack_lockout_time := 0.58
@export var attack_step_impulse := 60.0
@export var empty_attack_step_impulse := 120.0
@export var chop_step_impulse := 45.0
@export var attack_soft_lock_impulse := 240.0
@export var chop_soft_lock_impulse := 130.0
@export var attack_lunge_time := 0.38
@export var attack_soft_lock_min_distance := 58.0
@export var attack_soft_lock_max_distance := 82.0
@export var attack_soft_lock_vertical_tolerance := 52.0
@export var attack_buffer_min_recovery_elapsed := 0.0
@export var thrust_hold_time := 0.28
@export var thrust_attack_area_forward_offset := 58.0
@export var projectile_slash_startup := 0.18
@export var projectile_slash_forward_range := 128.0
@export var projectile_slash_back_range := 16.0
@export var projectile_slash_vertical_tolerance := 42.0
@export var parry_window := 0.45
@export var parry_success_recovery_time := 0.12
@export var parry_flash_time := 0.14
@export var block_hold_frame := 3
@export var block_release_time := 0.50
@export var dash_duration := 0.14
@export var perfect_dodge_duration := 0.14
@export var perfect_dodge_impulse := 520.0
@export var perfect_dodge_hitstop_time := 0.09
@export var hurt_time := 1.0
@export var hit_invulnerability_duration := 0.55
@export var stunned_time := 1.2
@export var posture_break_animation_speed := 0.72
@export var life_loss_stunned_time := 1.65
@export var life_loss_animation_speed := 0.55
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
@export var heavy_parry_rebound := 520.0
@export var heavy_parry_hitstop_time := 0.20
@export var heavy_parry_recoil_time := 0.26
@export var heavy_parry_camera_shake := 42.0
@export var heartbeat_idle_target := 70.0
@export var heartbeat_walk_target := 95.0
@export var heartbeat_run_target := 155.0
@export var heartbeat_jump_gain := 7.0
@export var heartbeat_attack_gain := 4.0
@export var heartbeat_guard_gain := 5.0
@export var heartbeat_combat_rise_per_second := 4.0
@export var heartbeat_combat_linger_time := 2.0
@export var heartbeat_cooldown_delay := 2.0
@export var heartbeat_walk_rise_percent_per_second := 0.03
@export var heartbeat_run_rise_percent_per_second := 0.06
@export var heartbeat_cooldown_percent_per_second := 0.08
@export var heartbeat_danger_death_enabled := true

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := max_health
var posture := 0.0
var lives := max_lives
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
var wall_climb_direction := 0.0
var wall_climb_lockout_timer := 0.0
var attack_elapsed := 0.0
var attack_buffer_timer := 0.0
var attack_buffer_queued := false
var attack_lockout_timer := 0.0
var attack_has_hit := false
var attack_has_cut_projectile := false
var attack_combo_step := 0
var current_attack_animation := "attack_a"
var attack_hold_timer := 0.0
var attack_hold_active := false
var attack_hold_consumed := false
var hurt_animation := "hurt"
var attack_lunge_timer := 0.0
var current_animation := ""
var parry_flash_timer := 0.0
var block_flash_timer := 0.0
var is_block_releasing := false
var hurt_flash_timer := 0.0
var perfect_dodge_timer := 0.0
var hit_impact_vfx_timer := 0.0
var hitstop_timer := 0.0
var attack_multiplier := 1.0
var attack_buff_timer := 0.0
var stored_velocity := Vector2.ZERO
var heavy_parry_recoil_timer := 0.0
var heavy_parry_recoil_velocity := Vector2.ZERO
var stunned_animation: StringName = &"posture_knockdown"
var stunned_animation_speed := 0.72
var combat_runtime: Node
var spawn_position := Vector2.ZERO
var sprite_sheet_layout: Dictionary = {}
var item_counts: Dictionary = DEFAULT_ITEM_COUNTS.duplicate()
var item_hotkeys_down: Dictionary = {}
var selected_item_index := 0
var selected_attack_item_index := 0
var selected_heal_item_index := 0
var active_teleport_kunai: Node2D = null
var current_item_animation := "mudra"
var has_map_climb_bounds := false
var map_climb_left_x := 0.0
var map_climb_right_x := 0.0
var ai_move_axis := 0.0
var ai_attack_requested := false
var ai_parry_requested := false
var ai_dodge_requested := false
var ai_jump_requested := false
var ai_dodge_target: Node2D = null
var player_sheet: Texture2D = null
var attack_hit_streams: Array[AudioStream] = []
var chop_hit_stream: AudioStream = null
var attack_miss_streams: Array[AudioStream] = []
var posture_combat_timer := 0.0
var posture_visibility_snapshot := 0.0
var heartbeat_combat_timer := 0.0
var heartbeat_cooldown_delay_timer := 0.0
var heartbeat_direct_checkpoint_respawn := false
var heartbeat_precise: float = CombatMathScript.MIN_HEARTBEAT
var posture_recovery_pause_timer := 0.0
var was_stunned_by_damage := false
var heartbeat_modifier_item_id := ""
var heartbeat_modifier_time_left := 0.0
var revive_available_pending := false
var death_animation_reported := false
var hit_invulnerability_time_left := 0.0
var hit_invulnerability_flash_timer := 0.0
var hit_invulnerability_active := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var hit_impact_vfx: AnimatedSprite2D = get_node_or_null("HitImpactVfx") as AnimatedSprite2D
@onready var attack_sfx: AudioStreamPlayer2D = $AttackSfx
@onready var parry_sfx: AudioStreamPlayer2D = $ParrySfx
@onready var block_sfx: AudioStreamPlayer2D = $BlockSfx
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var death_sfx: AudioStreamPlayer2D = $DeathSfx
@onready var dash_sfx: AudioStreamPlayer2D = $DashSfx
@onready var perfect_dodge_sfx: AudioStreamPlayer2D = $PerfectDodgeSfx
@onready var kunai_sfx: AudioStreamPlayer2D = $KunaiSfx
@onready var math: RefCounted = CombatMathScript.new()

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	combat_runtime = get_tree().get_first_node_in_group("combat_runtime")
	_setup_sprite_frames()
	if sprite != null and not sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.connect(_on_sprite_animation_finished)
	_setup_hit_impact_vfx()
	_load_optional_sfx()
	_set_state(PlayerState.IDLE)
	posture_visibility_snapshot = posture
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	if state == PlayerState.DEAD:
		hitstop_timer = 0.0
		if sprite != null:
			sprite.speed_scale = 1.0
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		move_and_slide()
		_update_hit_invulnerability(delta)
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

	if heavy_parry_recoil_timer > 0.0:
		heavy_parry_recoil_timer = max(0.0, heavy_parry_recoil_timer - delta)
		velocity.x = heavy_parry_recoil_velocity.x
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		_update_visuals()
		stats_changed.emit()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
	wall_climb_lockout_timer = max(0.0, wall_climb_lockout_timer - delta)

	_update_inputs(delta)
	_update_movement(delta)
	_update_action_state(delta)
	_update_combat(delta)
	_update_posture_and_heartbeat(delta)

	if attack_buff_timer > 0.0:
		attack_buff_timer -= delta
		if attack_buff_timer <= 0.0:
			attack_multiplier = 1.0

	move_and_slide()
	_check_world_death_bounds()
	_update_visuals()
	stats_changed.emit()

func register_posture_contact() -> void:
	posture_combat_timer = posture_disengage_delay
	posture_recovery_pause_timer = 1.4

func is_posture_in_combat() -> bool:
	return posture_combat_timer > 0.0

func is_posture_bar_visible() -> bool:
	posture_visibility_snapshot = posture
	return posture > 0.0

func _update_posture_and_heartbeat(delta: float) -> void:
	_update_posture_decay(delta)
	_update_heartbeat(delta)

func _update_posture_decay(delta: float) -> void:
	var remaining_delta := delta
	if posture_combat_timer > 0.0:
		var consumed: float = min(remaining_delta, posture_combat_timer)
		posture_combat_timer -= consumed
		remaining_delta -= consumed
	
	posture_recovery_pause_timer = max(0.0, posture_recovery_pause_timer - delta)
	
	if state == PlayerState.DEAD or state == PlayerState.STUNNED or posture_recovery_pause_timer > 0.0:
		return
	if posture <= 0.0 or remaining_delta <= 0.0:
		return
	var health_ratio: float = clamp(health / max(max_health, 0.001), 0.0, 1.0)
	var recovery_rate := max_posture * posture_recovery_percent_per_second * health_ratio
	posture = max(0.0, posture - recovery_rate * remaining_delta)

func _update_heartbeat(delta: float) -> void:
	_sync_heartbeat_precision_from_display()
	if heartbeat_combat_timer > 0.0:
		heartbeat_combat_timer = max(0.0, heartbeat_combat_timer - delta)
		_add_heartbeat_pressure(heartbeat_combat_rise_per_second * delta)
		if state == PlayerState.DEAD:
			return
	else:
		_adjust_heartbeat_toward_current_target(delta)

func _update_inputs(delta: float = -1.0) -> void:
	if _try_use_item_hotkey():
		_clear_ai_action_intents()
		return

	var attack_requested := _consume_attack_request(delta)
	var parry_requested := Input.is_action_just_pressed("block") or ai_parry_requested
	var shift_dodge_target: Node2D = null
	if Input.is_action_just_pressed("perfect_dodge_shift"):
		shift_dodge_target = _find_perfect_dodge_target()
	var dodge_requested := Input.is_action_just_pressed("dash") or ai_dodge_requested or shift_dodge_target != null
	var jump_requested := Input.is_action_just_pressed("jump") or ai_jump_requested

	if _can_start_attack() and attack_requested:
		_start_attack()
	elif _can_buffer_attack() and attack_requested:
		queue_attack_buffer()

	if _can_start_defensive_action() and parry_requested:
		_start_parry()

	if _can_start_defensive_action() and dodge_requested:
		if ai_dodge_requested and ai_dodge_target != null:
			_start_perfect_dodge(ai_dodge_target)
		elif shift_dodge_target != null:
			_start_perfect_dodge(shift_dodge_target)
		else:
			_start_dash()

	if jump_requested and coyote_timer > 0.0 and _can_jump():
		_register_combat_input(CombatServerScript.InputType.JUMP)
		_add_heartbeat_pressure(heartbeat_jump_gain)
		if state == PlayerState.DEAD:
			_clear_ai_action_intents()
			return
		velocity.y = jump_velocity
		coyote_timer = 0.0
		wall_climb_lockout_timer = jump_to_ledge_climb_lockout
		_set_state(PlayerState.JUMP)
	_clear_ai_action_intents()

func _update_movement(delta: float) -> void:
	if state == PlayerState.ATTACK:
		attack_lunge_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return

	if state == PlayerState.HURT:
		if hurt_animation == "deflect_miss" or hurt_animation == "deflect":
			velocity.x = 0.0
			return
		velocity.x = move_toward(velocity.x, 0.0, hurt_slide_friction * delta)
		return

	if state in [PlayerState.PARRY, PlayerState.BLOCK]:
		velocity.x = 0.0
		return

	if state in [PlayerState.EAT, PlayerState.STUNNED]:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return

	if state == PlayerState.DASH:
		velocity.x = dash_direction * (perfect_dodge_impulse if is_perfect_dodging else dash_impulse)
		return

	var direction := _read_move_axis()
	is_running = direction != 0.0 and Input.is_key_pressed(KEY_SHIFT)

	if direction != 0.0:
		_try_auto_step(direction)

	if _should_use_wall_climb(direction):
		_apply_wall_climb(direction)
		attack_area.position.x = 34.0 * facing
		return
	elif state == PlayerState.WALL_CLIMB:
		_set_state(PlayerState.JUMP)

	_apply_horizontal_control(direction, delta)

	attack_area.position.x = 34.0 * facing

	if state in [PlayerState.IDLE, PlayerState.MOVE, PlayerState.JUMP, PlayerState.WALL_CLIMB]:
		if not is_on_floor():
			_set_state(PlayerState.JUMP)
		elif abs(velocity.x) > 4.0:
			_set_state(PlayerState.MOVE)
		else:
			_set_state(PlayerState.IDLE)

func _apply_horizontal_control(direction: float, delta: float) -> void:
	if direction != 0.0:
		var movement_facing: float = sign(direction)
		facing = movement_facing
		var accel := turn_brake if velocity.x != 0.0 and sign(velocity.x) != sign(direction) else acceleration
		var target_speed := run_speed if is_running else walk_speed
		velocity.x = move_toward(velocity.x, direction * target_speed, accel * delta)
	else:
		is_running = false
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _can_wall_interact() -> bool:
	return is_on_wall() and not is_on_floor() and _can_jump() and _has_climbable_wall_contact()

func _has_climbable_wall_contact() -> bool:
	var slide_count := get_slide_collision_count()
	if slide_count == 0:
		return true
	var saw_wall_contact := false
	for index in range(slide_count):
		var collision: KinematicCollision2D = get_slide_collision(index)
		if collision == null:
			continue
		if collision.get_normal().x == 0.0:
			continue
		saw_wall_contact = true
		if not _is_wall_climb_blocked_by_collider(collision.get_collider()):
			return true
	return not saw_wall_contact

func _is_wall_climb_blocked_by_collider(collider: Object) -> bool:
	var node := collider as Node
	while node != null:
		if node.is_in_group("enemy") or node.is_in_group("boss"):
			return true
		node = node.get_parent()
	return false

func _should_use_wall_climb(direction: float) -> bool:
	return (
		_can_wall_interact()
		and _is_pressing_into_wall(direction)
		and _has_wall_climb_input()
		and not _is_at_world_horizontal_boundary(direction)
		and not _should_prefer_auto_step_over_climb()
		and not _should_defer_wall_climb_for_jump()
	)

func _has_wall_climb_input() -> bool:
	return not wall_climb_requires_jump or Input.is_action_pressed("jump") or state == PlayerState.WALL_CLIMB

func _should_defer_wall_climb_for_jump() -> bool:
	return wall_climb_lockout_timer > 0.0 and state != PlayerState.WALL_CLIMB

func set_map_climb_bounds(left_x: float, right_x: float) -> void:
	has_map_climb_bounds = true
	map_climb_left_x = min(left_x, right_x)
	map_climb_right_x = max(left_x, right_x)

func clear_map_climb_bounds() -> void:
	has_map_climb_bounds = false

func _is_at_world_horizontal_boundary(direction: float) -> bool:
	if direction == 0.0:
		return false
	if not has_map_climb_bounds and not world_death_bounds_enabled:
		return false
	var left_edge: float = map_climb_left_x if has_map_climb_bounds else world_death_bounds.position.x
	var right_edge: float = map_climb_right_x if has_map_climb_bounds else world_death_bounds.position.x + world_death_bounds.size.x
	var center_margin: float = world_boundary_climb_margin + _body_half_width()
	if direction < 0.0:
		return global_position.x <= left_edge + center_margin
	return global_position.x >= right_edge - center_margin

func _body_half_width() -> float:
	if body_collision_shape == null or body_collision_shape.shape == null:
		return 0.0
	if body_collision_shape.shape is RectangleShape2D:
		return ((body_collision_shape.shape as RectangleShape2D).size.x * absf(body_collision_shape.scale.x)) * 0.5
	return 0.0

func _should_prefer_auto_step_over_climb() -> bool:
	return auto_step_enabled and (is_on_floor() or coyote_timer > 0.0)

func _try_auto_step(direction: float) -> bool:
	if not _can_attempt_auto_step(direction):
		return false
	var step_direction: float = sign(direction)
	var horizontal_motion := Vector2(step_direction * auto_step_probe_distance, 0.0)
	if not test_move(global_transform, horizontal_motion):
		return false

	var step_height: float = auto_step_increment
	while step_height <= auto_step_max_height:
		var probe_transform: Transform2D = global_transform
		probe_transform.origin += Vector2(0.0, -step_height)
		if not test_move(probe_transform, horizontal_motion):
			global_position.y -= step_height
			velocity.y = min(velocity.y, 0.0)
			coyote_timer = coyote_time
			return true
		step_height += auto_step_increment
	return false

func _can_attempt_auto_step(direction: float) -> bool:
	return auto_step_enabled and direction != 0.0 and _should_prefer_auto_step_over_climb() and _can_jump()

func _is_pressing_into_wall(direction: float) -> bool:
	var wall_direction := _wall_direction()
	return direction != 0.0 and wall_direction != 0.0 and sign(direction) == wall_direction

func _wall_direction() -> float:
	var normal := get_wall_normal()
	if normal.x == 0.0:
		return 0.0
	return -sign(normal.x)

func _apply_wall_climb(direction: float) -> void:
	wall_climb_direction = _wall_direction()
	if wall_climb_direction == 0.0:
		wall_climb_direction = sign(direction)
	facing = wall_climb_direction
	is_running = false
	coyote_timer = 0.0
	velocity.x = wall_climb_direction * wall_stick_speed
	if Input.is_action_pressed("jump"):
		velocity.y = -wall_climb_speed
	else:
		velocity.y = min(velocity.y, wall_slide_speed)
	_set_state(PlayerState.WALL_CLIMB)

func _update_action_state(delta: float) -> void:
	attack_buffer_timer = max(0.0, attack_buffer_timer - delta)
	attack_lockout_timer = max(0.0, attack_lockout_timer - delta)
	if state == PlayerState.ATTACK:
		action_timer -= delta
		attack_elapsed += delta
		if attack_elapsed >= projectile_slash_startup and not attack_has_cut_projectile:
			attack_has_cut_projectile = _apply_projectile_slash()
		var active := attack_elapsed >= attack_startup and attack_elapsed < attack_startup + attack_active_time
		is_attacking = active
		if active and not attack_has_hit:
			_apply_attack_hit()
			attack_has_hit = true
		if action_timer <= 0.0:
			is_attacking = false
			attack_has_hit = false
			attack_has_cut_projectile = false
			if attack_buffer_queued:
				attack_buffer_queued = false
				attack_buffer_timer = 0.0
				_start_attack()
			else:
				_clear_attack_hold()
				_set_state(PlayerState.IDLE)

	elif state == PlayerState.PARRY:
		action_timer -= delta
		parry_elapsed += delta
		is_parrying = action_timer > 0.0
		if action_timer <= 0.0:
			_start_block()

	elif state == PlayerState.BLOCK:
		if is_block_releasing:
			action_timer -= delta
			if action_timer <= 0.0:
				is_block_releasing = false
				_set_state(PlayerState.IDLE)

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

	elif state == PlayerState.EAT:
		action_timer -= delta
		if action_timer <= 0.0:
			_set_state(PlayerState.IDLE)

	elif state == PlayerState.STUNNED:
		action_timer -= delta
		if action_timer <= 0.0:
			if was_stunned_by_damage:
				if heartbeat > 120:
					_set_heartbeat_value(120.0)
			was_stunned_by_damage = false
			posture = min(posture, max_posture * 0.55)
			is_invulnerable = false
			sprite.speed_scale = 1.0
			_set_state(PlayerState.IDLE)

func _update_combat(delta: float) -> void:
	_sync_heartbeat_precision_from_display()
	_update_hit_invulnerability(delta)
	if is_blocking:
		block_age += delta
		block_time_left -= delta
		if not Input.is_action_pressed("block") or block_time_left <= 0.0:
			_start_block_release()

	if heartbeat_combat_timer > 0.0:
		if state == PlayerState.DEAD:
			return

func _add_heartbeat_pressure(amount: float) -> void:
	_sync_heartbeat_precision_from_display()
	_set_heartbeat_value(math.add_heartbeat(heartbeat_precise, amount))
	_check_heartbeat_death()

func _check_heartbeat_death() -> bool:
	if not heartbeat_danger_death_enabled:
		return false
	if state == PlayerState.DEAD:
		return true
	if heartbeat < CombatMathScript.MAX_HEARTBEAT - 0.001:
		return false
	_set_heartbeat_value(CombatMathScript.MAX_HEARTBEAT)
	heartbeat_direct_checkpoint_respawn = true
	_enter_dead()
	stats_changed.emit()
	died.emit()
	return true

func _adjust_heartbeat_toward_current_target(delta: float) -> void:
	var target_heartbeat: float = _current_heartbeat_target()
	if is_equal_approx(heartbeat_precise, target_heartbeat):
		heartbeat_cooldown_delay_timer = 0.0
		return
	if heartbeat_precise < target_heartbeat:
		heartbeat_cooldown_delay_timer = 0.0
		var rise_amount: float = target_heartbeat * _current_heartbeat_rise_percent_per_second() * delta
		_set_heartbeat_value(min(target_heartbeat, heartbeat_precise + rise_amount))
		return
	if heartbeat_cooldown_delay_timer < heartbeat_cooldown_delay:
		heartbeat_cooldown_delay_timer += delta
		if heartbeat_cooldown_delay_timer < heartbeat_cooldown_delay:
			return
	var next_heartbeat: float = max(target_heartbeat, heartbeat_precise - (heartbeat_precise * heartbeat_cooldown_percent_per_second * delta))
	_set_heartbeat_value(next_heartbeat)

func _current_heartbeat_target() -> float:
	if is_running:
		return heartbeat_run_target
	if state in [PlayerState.MOVE, PlayerState.JUMP, PlayerState.WALL_CLIMB] and absf(velocity.x) > 4.0:
		return heartbeat_walk_target
	return heartbeat_idle_target

func _current_heartbeat_rise_percent_per_second() -> float:
	if is_running:
		return heartbeat_run_rise_percent_per_second
	if state in [PlayerState.MOVE, PlayerState.JUMP, PlayerState.WALL_CLIMB] and absf(velocity.x) > 4.0:
		return heartbeat_walk_rise_percent_per_second
	return 0.0

func _mark_heartbeat_combat_activity() -> void:
	heartbeat_combat_timer = heartbeat_combat_linger_time
	heartbeat_cooldown_delay_timer = 0.0

func _set_heartbeat_value(value: float) -> void:
	heartbeat_precise = clamp(value, CombatMathScript.MIN_HEARTBEAT, CombatMathScript.MAX_HEARTBEAT)
	heartbeat = floor(heartbeat_precise)

func _sync_heartbeat_precision_from_display() -> void:
	if floor(heartbeat_precise) != heartbeat:
		heartbeat_precise = heartbeat

func _start_attack() -> void:
	_start_attack_with_animation("")

func _start_attack_with_animation(animation_override: String) -> void:
	_register_combat_input(CombatServerScript.InputType.ATTACK)
	_mark_heartbeat_combat_activity()
	_add_heartbeat_pressure(heartbeat_attack_gain)
	if state == PlayerState.DEAD:
		return
	if animation_override != "":
		current_attack_animation = animation_override
		attack_combo_step = 0
	else:
		current_attack_animation = "attack_chop" if attack_combo_step == 2 else "attack_a"
		attack_combo_step = (attack_combo_step + 1) % 3
	attack_lunge_timer = attack_lunge_time
	velocity.x = facing * _attack_step_impulse()
	attack_area.position.x = _attack_area_forward_offset() * facing
	_set_state(PlayerState.ATTACK)
	_force_play_animation(current_attack_animation)
	action_timer = attack_startup + attack_active_time + attack_recovery
	attack_elapsed = 0.0
	is_attacking = false
	attack_has_hit = false
	attack_has_cut_projectile = false

func force_execution_thrust_attack() -> void:
	current_attack_animation = "attack_thrust"
	attack_combo_step = 0
	action_timer = max(action_timer, attack_startup + attack_active_time + attack_recovery)
	attack_elapsed = 0.0
	attack_area.position.x = _attack_area_forward_offset() * facing
	_set_state(PlayerState.ATTACK)
	_force_play_animation("attack_thrust")

func finish_execution_thrust_attack() -> void:
	is_attacking = false
	action_timer = 0.0
	attack_elapsed = 0.0
	attack_has_hit = false
	attack_has_cut_projectile = false
	attack_lunge_timer = 0.0
	attack_buffer_timer = 0.0
	attack_buffer_queued = false
	attack_lockout_timer = 0.0
	_clear_attack_hold()
	if state == PlayerState.ATTACK:
		_set_state(PlayerState.IDLE)

func _consume_attack_request(delta: float = -1.0) -> bool:
	if ai_attack_requested:
		_clear_attack_hold()
		return true
	if Input.is_action_just_pressed("attack"):
		attack_hold_active = true
		attack_hold_timer = 0.0
		attack_hold_consumed = false
	elif Input.is_action_pressed("attack") and not attack_hold_active and not attack_hold_consumed:
		attack_hold_active = true
		attack_hold_timer = 0.0
	if attack_hold_active and Input.is_action_pressed("attack"):
		var hold_delta: float = delta if delta >= 0.0 else get_physics_process_delta_time()
		attack_hold_timer += hold_delta
		if not attack_hold_consumed and attack_hold_timer >= thrust_hold_time:
			if _can_start_attack():
				attack_hold_consumed = true
				attack_hold_active = false
				_start_attack_with_animation("attack_thrust")
			return false
	if attack_hold_active and Input.is_action_just_released("attack"):
		var should_start_normal := not attack_hold_consumed
		_clear_attack_hold()
		return should_start_normal
	if not Input.is_action_pressed("attack") and attack_hold_consumed:
		_clear_attack_hold()
	return false

func _clear_attack_hold() -> void:
	attack_hold_active = false
	attack_hold_timer = 0.0
	attack_hold_consumed = false

func _try_use_item_hotkey() -> bool:
	if _item_select_key_just_pressed(KEY_1, 0):
		return true
	if _item_select_key_just_pressed(KEY_2, 1):
		return true
	if _item_select_key_just_pressed(KEY_3, 2):
		return true
	if _item_select_key_just_pressed(KEY_4, 3):
		return true
	if _item_select_key_just_pressed(KEY_5, 4):
		return true
	if _item_use_key_just_pressed(KEY_E, "use_attack"):
		return use_selected_attack_item()
	if _item_use_key_just_pressed(KEY_R, "use_heal"):
		return use_selected_heal_item()
	return false

func _item_select_key_just_pressed(key: Key, index: int) -> bool:
	var pressed := Input.is_key_pressed(key)
	var key_name := "select_%d" % index
	var was_pressed := bool(item_hotkeys_down.get(key_name, false))
	item_hotkeys_down[key_name] = pressed
	if pressed and not was_pressed:
		_set_selected_item_index(index)
		stats_changed.emit()
		return true
	return false

func _item_use_key_just_pressed(key: Key, action_name: String) -> bool:
	var pressed := Input.is_key_pressed(key)
	var was_pressed := bool(item_hotkeys_down.get(action_name, false))
	item_hotkeys_down[action_name] = pressed
	return pressed and not was_pressed

func _set_selected_item_index(index: int) -> void:
	selected_item_index = clampi(index, 0, ITEM_ORDER.size() - 1)
	var item_id := ITEM_ORDER[selected_item_index]
	if ATTACK_ITEM_IDS.has(item_id):
		selected_attack_item_index = ATTACK_ITEM_IDS.find(item_id)
	elif HEAL_ITEM_IDS.has(item_id):
		selected_heal_item_index = HEAL_ITEM_IDS.find(item_id)

func _read_move_axis() -> float:
	var keyboard_axis := Input.get_axis("move_left", "move_right")
	if keyboard_axis != 0.0:
		return keyboard_axis
	return ai_move_axis

func _read_dash_direction() -> float:
	var direction := _read_move_axis()
	if direction != 0.0:
		return sign(direction)
	return facing

func set_ai_move_axis(axis: float) -> void:
	ai_move_axis = clamp(axis, -1.0, 1.0)

func get_ai_move_axis() -> float:
	return ai_move_axis

func request_ai_attack() -> void:
	ai_attack_requested = true

func request_ai_parry() -> void:
	ai_parry_requested = true

func request_ai_dodge(target: Node2D = null) -> void:
	ai_dodge_requested = true
	ai_dodge_target = target

func request_ai_jump() -> void:
	ai_jump_requested = true

func has_pending_ai_attack() -> bool:
	return ai_attack_requested

func has_pending_ai_parry() -> bool:
	return ai_parry_requested

func has_pending_ai_dodge() -> bool:
	return ai_dodge_requested

func clear_ai_intent() -> void:
	ai_move_axis = 0.0
	_clear_ai_action_intents()

func _clear_ai_action_intents() -> void:
	ai_attack_requested = false
	ai_parry_requested = false
	ai_dodge_requested = false
	ai_jump_requested = false
	ai_dodge_target = null

func get_item_count(item_id: String) -> int:
	return int(item_counts.get(item_id, 0))

func get_item_counts() -> Dictionary:
	return item_counts.duplicate()

func add_item(item_id: String, quantity: int = 1) -> void:
	item_counts[item_id] = max(0, get_item_count(item_id) + quantity)
	stats_changed.emit()

func get_selected_item_id() -> String:
	var index := clampi(selected_item_index, 0, ITEM_ORDER.size() - 1)
	return ITEM_ORDER[index]

func get_selected_attack_item_id() -> String:
	return ATTACK_ITEM_IDS[clampi(selected_attack_item_index, 0, ATTACK_ITEM_IDS.size() - 1)]

func get_selected_heal_item_id() -> String:
	return HEAL_ITEM_IDS[clampi(selected_heal_item_index, 0, HEAL_ITEM_IDS.size() - 1)]

func use_selected_item() -> bool:
	return use_item(get_selected_item_id())

func use_selected_attack_item() -> bool:
	return use_item(get_selected_attack_item_id())

func use_selected_heal_item() -> bool:
	return use_item(get_selected_heal_item_id())

func use_item(item_id: String) -> bool:
	if item_id == "kunai" and is_instance_valid(active_teleport_kunai):
		return _teleport_to_active_kunai()
	if not _can_start_action():
		return false
	var count := get_item_count(item_id)
	if count <= 0:
		return false

	if EAT_ITEM_IDS.has(item_id):
		item_counts[item_id] = count - 1
		is_blocking = false
		is_attacking = false
		is_parrying = false
		is_dashing = false
		is_running = false
		is_perfect_dodging = false
		attack_buffer_queued = false
		attack_buffer_timer = 0.0
		attack_has_hit = false
		attack_has_cut_projectile = false
		velocity = Vector2.ZERO
		current_item_animation = "eat"
		_set_state(PlayerState.EAT)
		action_timer = ITEM_ACTION_TIME
		_force_play_animation(current_item_animation)
		_apply_consumable_effect(item_id)
		stats_changed.emit()
		return true
	elif item_id == "kunai":
		if _use_kunai():
			item_counts[item_id] = count - 1
			stats_changed.emit()
			return true
	elif item_id == "ash_balls":
		if _use_ash_balls():
			item_counts[item_id] = count - 1
			stats_changed.emit()
			return true
	return false

func _apply_consumable_effect(item_id: String) -> void:
	match item_id:
		"gourd":
			health = min(max_health, health + max_health * GOURD_HEAL_PERCENT)
		"pill":
			_set_heartbeat_value(max(CombatMathScript.MIN_HEARTBEAT, heartbeat_precise - BLOOD_PRESSURE_HEARTBEAT_DROP))
		"capsule":
			_add_heartbeat_pressure(ADRENALINE_HEARTBEAT_BOOST)

func _use_kunai() -> bool:
	if not _can_start_action():
		return false
	_cancel_current_action_flags()
	current_item_animation = "mudra"
	_set_state(PlayerState.EAT)
	action_timer = ITEM_ACTION_TIME
	_force_play_animation(current_item_animation)
	
	var kunai = KunaiScene.instantiate()
	kunai.global_position = global_position + Vector2(25 * facing, -45)
	kunai.setup(facing, self)
	get_parent().add_child(kunai)
	active_teleport_kunai = kunai
	return true

func _teleport_to_active_kunai() -> bool:
	if state == PlayerState.DEAD:
		return false
	if not is_instance_valid(active_teleport_kunai):
		active_teleport_kunai = null
		return false
	var target_position := active_teleport_kunai.global_position
	active_teleport_kunai.queue_free()
	active_teleport_kunai = null
	_cancel_current_action_flags()
	global_position = target_position
	velocity = Vector2.ZERO
	_set_state(PlayerState.IDLE)
	_play_sfx(kunai_sfx)
	stats_changed.emit()
	return true

func _use_ash_balls() -> bool:
	if not _can_start_action():
		return false
	_cancel_current_action_flags()
	current_item_animation = "throw"
	_set_state(PlayerState.EAT)
	action_timer = ITEM_ACTION_TIME
	_force_play_animation(current_item_animation)

	var ash_ball = AshBallScene.instantiate()
	ash_ball.global_position = global_position + Vector2(25 * facing, -45)
	ash_ball.setup(facing, self, SMOKE_BOMB_BOSS_PAUSE_TIME, SMOKE_BOMB_MINOR_STUN_TIME)
	get_parent().add_child(ash_ball)
	return true

func _cancel_current_action_flags() -> void:
	is_blocking = false
	is_attacking = false
	is_parrying = false
	is_block_releasing = false
	is_dashing = false
	is_running = false
	is_perfect_dodging = false
	attack_buffer_queued = false
	attack_buffer_timer = 0.0
	attack_has_hit = false
	attack_has_cut_projectile = false

func refill_items_to_default() -> void:
	item_counts = DEFAULT_ITEM_COUNTS.duplicate()
	stats_changed.emit()

func settle_world_interaction(anchor_position: Vector2, refill_items: bool = false) -> void:
	_cancel_current_action_flags()
	is_invulnerable = false
	_clear_hit_invulnerability()
	action_timer = 0.0
	dash_timer = 0.0
	attack_elapsed = 0.0
	attack_lockout_timer = 0.0
	attack_combo_step = 0
	block_age = 0.0
	block_time_left = 0.0
	parry_elapsed = 0.0
	attack_lunge_timer = 0.0
	parry_flash_timer = 0.0
	block_flash_timer = 0.0
	hurt_flash_timer = 0.0
	perfect_dodge_timer = 0.0
	hit_impact_vfx_timer = 0.0
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	heavy_parry_recoil_timer = 0.0
	heavy_parry_recoil_velocity = Vector2.ZERO
	current_item_animation = "mudra"
	sprite.speed_scale = 1.0
	velocity = Vector2.ZERO
	if is_instance_valid(active_teleport_kunai):
		active_teleport_kunai.queue_free()
	active_teleport_kunai = null
	if refill_items:
		item_counts = DEFAULT_ITEM_COUNTS.duplicate()
		health = max_health
		lives = max_lives
		posture = 0.0
		_set_heartbeat_value(CombatMathScript.MIN_HEARTBEAT)
		heartbeat_combat_timer = 0.0
		heartbeat_cooldown_delay_timer = 0.0
	global_position = anchor_position
	_set_state(PlayerState.IDLE)
	_update_visuals()
	stats_changed.emit()

func is_action_locked() -> bool:
	return state in [PlayerState.ATTACK, PlayerState.PARRY, PlayerState.DASH, PlayerState.EAT, PlayerState.HURT, PlayerState.STUNNED, PlayerState.DEAD]

func get_current_animation() -> String:
	return current_animation

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
	var direction := _read_move_axis()
	return direction != 0.0 and sign(direction) == facing

func _attack_step_impulse() -> float:
	var has_soft_lock_target := _find_attack_soft_lock_target() != null
	if current_attack_animation == "attack_chop":
		return chop_soft_lock_impulse if has_soft_lock_target else chop_step_impulse
	if has_soft_lock_target:
		return attack_soft_lock_impulse
	return attack_step_impulse if _has_rejected_soft_lock_target() else empty_attack_step_impulse

func _attack_area_forward_offset() -> float:
	if current_attack_animation == "attack_thrust":
		return thrust_attack_area_forward_offset
	return 34.0

func _find_attack_soft_lock_target() -> Node2D:
	for group_name in ["enemy", "boss"]:
		for target in get_tree().get_nodes_in_group(group_name):
			if target is Node2D and _is_valid_attack_soft_lock_target(target):
				return target
	return null

func _is_valid_attack_soft_lock_target(target: Node2D) -> bool:
	var target_script: Script = target.get_script() as Script
	if target_script != null and target_script.resource_path.ends_with("archer_enemy.gd"):
		return false
	if target.has_method("can_receive_attack_soft_lock") and not target.can_receive_attack_soft_lock():
		return false
	var offset := target.global_position - global_position
	var forward_distance := offset.x * facing
	if forward_distance < attack_soft_lock_min_distance:
		return false
	if forward_distance > attack_soft_lock_max_distance:
		return false
	if abs(offset.y) > attack_soft_lock_vertical_tolerance:
		return false
	return true

func _has_rejected_soft_lock_target() -> bool:
	for group_name in ["enemy", "boss"]:
		for target in get_tree().get_nodes_in_group(group_name):
			if not (target is Node2D):
				continue
			var offset := (target as Node2D).global_position - global_position
			var forward_distance := offset.x * facing
			if forward_distance >= attack_soft_lock_min_distance and forward_distance <= attack_soft_lock_max_distance and abs(offset.y) <= attack_soft_lock_vertical_tolerance:
				return true
	return false

func _apply_attack_hit() -> void:
	var damage: float = math.damage_with_adrenaline(base_attack_damage * attack_multiplier, heartbeat)
	var posture_damage: float = math.posture_damage_with_adrenaline(attack_posture_damage, heartbeat)
	var hit_confirmed := false
	var was_deflected := false
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("can_be_executed") and body.can_be_executed() and body.has_method("execute"):
			force_execution_thrust_attack()
			if body.has_method("complete_final_execution_death") and body.has_method("receive_player_attack"):
				var boss_result: Variant = body.receive_player_attack(damage, posture_damage)
				if not (boss_result is bool and boss_result == false):
					hit_confirmed = true
					if boss_result is Dictionary and bool(boss_result.get("guarded", false)):
						was_deflected = true
				continue
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
		if not attack_has_cut_projectile:
			_play_random_attack_miss_sfx()

func _apply_projectile_slash() -> bool:
	var hit_confirmed := false
	var slash_center_y := global_position.y + attack_area.position.y
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if not (projectile is Node2D):
			continue
		if not projectile.has_method("receive_player_attack"):
			continue
		var offset := (projectile as Node2D).global_position - global_position
		var forward_distance := offset.x * facing
		if forward_distance < -projectile_slash_back_range:
			continue
		if forward_distance > projectile_slash_forward_range:
			continue
		if abs((projectile as Node2D).global_position.y - slash_center_y) > projectile_slash_vertical_tolerance:
			continue
		var result: Variant = projectile.receive_player_attack(0.0, 0.0)
		if not (result is bool and result == false):
			hit_confirmed = true
	if hit_confirmed:
		_play_random_attack_hit_sfx()
		_trigger_attack_hit_feedback()
	return hit_confirmed

func _start_parry() -> void:
	_register_combat_input(CombatServerScript.InputType.PARRY)
	_set_state(PlayerState.PARRY)
	is_block_releasing = false
	is_parrying = true
	is_blocking = false
	block_age = 0.0
	parry_elapsed = 0.0
	action_timer = parry_window
	_force_play_animation("deflect_miss")

func _start_block() -> void:
	_set_state(PlayerState.BLOCK)
	is_parrying = false
	is_blocking = true
	is_block_releasing = false
	block_age = 0.0
	block_time_left = math.block_duration_for_heartbeat(heartbeat)
	_force_play_animation("block")

func _start_block_release() -> void:
	is_blocking = false
	is_parrying = false
	is_block_releasing = true
	action_timer = block_release_time
	if sprite != null:
		sprite.speed_scale = 1.0
		if sprite.animation != &"block":
			_force_play_animation("block")
		sprite.frame = max(sprite.frame, min(block_hold_frame + 1, sprite.sprite_frames.get_frame_count("block") - 1))
		sprite.frame_progress = 0.0

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
	dash_direction = _read_dash_direction()
	dash_timer = dash_duration
	_add_heartbeat_pressure(4.0)
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
	_add_heartbeat_pressure(8.0)
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
	register_posture_contact()
	_mark_heartbeat_combat_activity()
	if (_has_damage_invulnerability() and attack_type != CombatServerScript.AttackType.SWEEP) or hit_invulnerability_active:
		return

	var can_guard := attack_type != CombatServerScript.AttackType.THRUST
	var can_block := attack_type != CombatServerScript.AttackType.SWEEP
	var perfect_parry := false
	if is_parrying and can_guard:
		perfect_parry = true
		if attacker != null and attacker.has_method("can_be_perfect_parried_by"):
			perfect_parry = attacker.can_be_perfect_parried_by(self)
	var took_damage_this_hit := false
	if perfect_parry or (is_parrying and can_guard and can_block) or (is_blocking and can_guard and can_block):
		var perfect := perfect_parry
		var p_gain := 7.0 if perfect else 11.0
		posture = math.add_posture(posture, p_gain)
		_add_heartbeat_pressure(heartbeat_guard_gain)
		if state == PlayerState.DEAD:
			return
		var heavy_chop_parry := perfect and _is_attacker_chop_attack(attacker)
		if attacker != null and attacker.has_method("receive_block_feedback_from_player"):
			attacker.receive_block_feedback_from_player(perfect, self)
		elif attacker != null and attacker.has_method("receive_block_feedback"):
			attacker.receive_block_feedback(perfect)
		if perfect:
			_play_sfx(parry_sfx)
			if heavy_chop_parry:
				_trigger_parry_feedback(_knockback_direction_from_attacker(attacker), heavy_parry_rebound, heavy_parry_hitstop_time, heavy_parry_camera_shake, 0.16)
				_trigger_parry_impact_vfx(attacker)
			else:
				_trigger_parry_feedback()
				_trigger_guard_impact_vfx(attacker)
		else:
			_play_sfx(block_sfx)
			_trigger_block_feedback()
			_trigger_guard_impact_vfx(attacker)
	else:
		var health_before := health
		health = math.apply_damage(health, damage)
		took_damage_this_hit = health < health_before
		posture = math.add_posture(posture, 18.0)
		if state == PlayerState.DEAD:
			return
		if health <= 0.0:
			_handle_health_depleted()
			stats_changed.emit()
			return
		else:
			if took_damage_this_hit:
				_start_hit_invulnerability()
			_play_sfx(hurt_sfx)
			_trigger_hurt_feedback(_knockback_direction_from_attacker(attacker))
			hurt_animation = "hurt"
			_set_state(PlayerState.HURT)
			_force_play_animation("hurt")
			action_timer = hurt_time
			is_invulnerable = true

	if posture >= max_posture:
		_enter_stunned()
		if took_damage_this_hit:
			was_stunned_by_damage = true

	stats_changed.emit()
	if health <= 0.0:
		_handle_health_depleted()

func _check_world_death_bounds() -> void:
	if not world_death_bounds_enabled:
		return
	if state == PlayerState.DEAD:
		return
	if world_death_bounds.has_point(global_position):
		return
	_enter_dead()
	stats_changed.emit()
	died.emit()

func _handle_health_depleted() -> void:
	if lives > 1:
		_enter_revive_wait_state()
		revive_prompt_requested.emit()
		return
	_enter_dead()
	died.emit()

func begin_local_hitstop(duration: float, resume_velocity: Vector2 = Vector2.INF) -> void:
	if state == PlayerState.DEAD:
		return
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

func _enter_stunned(animation_name: StringName = &"posture_knockdown", duration := -1.0, animation_speed := -1.0, keep_posture_at_break := true) -> void:
	_set_state(PlayerState.STUNNED)
	was_stunned_by_damage = false
	stunned_animation = animation_name
	stunned_animation_speed = posture_break_animation_speed if animation_speed < 0.0 else animation_speed
	if keep_posture_at_break:
		posture = max_posture
	action_timer = stunned_time if duration < 0.0 else duration
	is_blocking = false
	is_attacking = false
	is_parrying = false
	is_block_releasing = false
	is_dashing = false
	is_running = false
	is_perfect_dodging = false
	is_invulnerable = true
	wall_climb_direction = 0.0
	wall_climb_lockout_timer = 0.0
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	heavy_parry_recoil_timer = 0.0
	heavy_parry_recoil_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	current_animation = ""
	_update_visuals()

func _can_start_action() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVE, PlayerState.JUMP, PlayerState.WALL_CLIMB, PlayerState.BLOCK]

func _can_start_attack() -> bool:
	return _can_start_action() and attack_lockout_timer <= 0.0

func _can_start_defensive_action() -> bool:
	if _can_start_action():
		return true
	return state == PlayerState.HURT and (hurt_animation == "deflect_miss" or hurt_animation == "deflect")

func _can_buffer_attack() -> bool:
	return state == PlayerState.ATTACK

func _can_jump() -> bool:
	return state not in [PlayerState.ATTACK, PlayerState.PARRY, PlayerState.DASH, PlayerState.EAT, PlayerState.HURT, PlayerState.STUNNED]

func _update_visuals() -> void:
	parry_flash_timer = max(0.0, parry_flash_timer - get_physics_process_delta_time())
	block_flash_timer = max(0.0, block_flash_timer - get_physics_process_delta_time())
	hurt_flash_timer = max(0.0, hurt_flash_timer - get_physics_process_delta_time())
	perfect_dodge_timer = max(0.0, perfect_dodge_timer - get_physics_process_delta_time())
	hit_impact_vfx_timer = max(0.0, hit_impact_vfx_timer - get_physics_process_delta_time())
	if hit_impact_vfx != null:
		hit_impact_vfx.visible = hit_impact_vfx_timer > 0.0
	_apply_hit_invulnerability_flicker()
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
		_add_strip_animation(frames, "attack_a", ATTACK_ANIMATION_FPS, false)
		_add_strip_animation(frames, "attack_chop", ATTACK_ANIMATION_FPS, false)
		_add_strip_animation(frames, "attack_thrust", ATTACK_ANIMATION_FPS, false)
		_add_strip_animation(frames, "deflect", 14.0, false)
		_add_strip_animation(frames, "deflect_miss", 14.0, false)
		_add_strip_animation(frames, "parry", 14.0, false)
		_add_strip_animation(frames, "block", 8.0, false)
		_add_strip_animation(frames, "dash", 18.0, false)
		_add_strip_animation(frames, "jump", 10.0, true)
		_add_strip_animation(frames, "climb", 10.0, true)
		_add_strip_animation(frames, "eat", 10.0, false)
		_add_strip_animation(frames, "mudra", 10.0, false)
		_add_strip_animation(frames, "throw", 10.0, false)
		_add_strip_animation(frames, "hurt", 8.0, false)
		_add_strip_animation(frames, "death", 7.0, false)
		_add_derived_animation(frames, &"posture_knockdown", &"death", 3, 8.0, false)
		_add_derived_animation(frames, &"life_knockdown", &"death", -1, 7.0, false)
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
		_add_layout_animation(frames, "climb", "jump")
		_add_layout_animation(frames, "mudra", "idle")
		_add_layout_animation(frames, "hurt")
		_add_layout_animation(frames, "death")
		_add_derived_animation(frames, &"posture_knockdown", &"death", 3, 8.0, false)
		_add_derived_animation(frames, &"life_knockdown", &"death", -1, 7.0, false)
	sprite.sprite_frames = frames
	sprite.position = Vector2(0, -float(sprite_sheet_layout["cell_size"]) * 0.5)
	_apply_animation_sprite_scale("idle")
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
	if not ResourceLoader.exists(PLAYER_THRUST_WIDE_STRIP_PATH):
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
		for frame_index in custom_regions.size():
			var region_entry: Variant = custom_regions[frame_index]
			var region_values: Array = []
			var frame_texture: Texture2D = texture
			if region_entry is Dictionary:
				var region_dictionary: Dictionary = region_entry
				var region_variant: Variant = region_dictionary.get("region", [])
				if region_variant is Array:
					region_values = region_variant
				var texture_path: String = String(region_dictionary.get("path", ""))
				if texture_path != "":
					frame_texture = load(texture_path) as Texture2D
			elif region_entry is Array:
				region_values = region_entry
			if frame_texture == null or region_values.size() < 4:
				continue
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = frame_texture
			atlas_texture.region = Rect2(float(region_values[0]), float(region_values[1]), float(region_values[2]), float(region_values[3]))
			atlas_texture.filter_clip = true
			frames.add_frame(animation, atlas_texture, _strip_frame_duration_weight(String(animation), custom_regions.size(), frame_index))
		return
	for column in frame_count:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(column * cell_size, 0, cell_size, cell_size)
		atlas_texture.filter_clip = true
		frames.add_frame(animation, atlas_texture, _strip_frame_duration_weight(String(animation), frame_count, column))

func _strip_frame_duration_weight(animation: String, frame_count: int, frame_index: int) -> float:
	if animation != "mudra":
		return 1.0
	var focus_count: int = MUDRA_FOCUS_FRAME_END - MUDRA_FOCUS_FRAME_START + 1
	var total_weight := float(frame_count)
	if frame_index >= MUDRA_FOCUS_FRAME_START and frame_index <= MUDRA_FOCUS_FRAME_END:
		return total_weight * MUDRA_FOCUS_DURATION_RATIO / float(focus_count)
	var outside_count: int = max(frame_count - focus_count, 1)
	return total_weight * (1.0 - MUDRA_FOCUS_DURATION_RATIO) / float(outside_count)

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

func _add_derived_animation(frames: SpriteFrames, animation: StringName, source_animation: StringName, frame_limit: int, fps: float, loop: bool) -> void:
	if not frames.has_animation(source_animation):
		return
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	var source_count: int = frames.get_frame_count(source_animation)
	var copy_count: int = source_count if frame_limit < 0 else min(frame_limit, source_count)
	for index in copy_count:
		frames.add_frame(animation, frames.get_frame_texture(source_animation, index))

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
			next_animation = "deflect_miss"
		PlayerState.BLOCK:
			next_animation = "block"
		PlayerState.DASH:
			next_animation = "dash"
		PlayerState.JUMP:
			next_animation = "jump"
		PlayerState.WALL_CLIMB:
			next_animation = "climb"
		PlayerState.EAT:
			next_animation = current_item_animation
		PlayerState.HURT:
			next_animation = hurt_animation
		PlayerState.STUNNED:
			_play_stunned_animation()
			return
		PlayerState.DEAD:
			next_animation = "death"

	if current_animation != next_animation:
		current_animation = next_animation
		_apply_animation_sprite_scale(next_animation)
		sprite.play(next_animation)
	_update_block_hold_animation()

func _update_block_hold_animation() -> void:
	if sprite == null:
		return
	if state != PlayerState.BLOCK or not is_blocking or is_block_releasing:
		return
	if sprite.animation != &"block":
		return
	if sprite.frame >= block_hold_frame:
		sprite.frame = block_hold_frame
		sprite.frame_progress = 0.0
		sprite.speed_scale = 0.0

func _force_play_animation(animation: StringName) -> void:
	current_animation = animation
	if sprite == null:
		return
	_apply_animation_sprite_scale(String(animation))
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play(animation)

func _apply_animation_sprite_scale(animation: String) -> void:
	if sprite == null:
		return
	if animation == "walk":
		sprite.scale = WALK_SPRITE_SCALE
	elif animation == "deflect_miss" or animation == "block" or animation == "parry":
		sprite.scale = DEFLECT_MISS_SPRITE_SCALE
	else:
		sprite.scale = DEFAULT_SPRITE_SCALE

func _animation_duration(animation: StringName) -> float:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
		return 0.8
	var fps := sprite.sprite_frames.get_animation_speed(animation)
	if fps <= 0.0:
		return 0.8
	var frame_count := sprite.sprite_frames.get_frame_count(animation)
	return max(0.1, float(frame_count) / fps)

func _play_stunned_animation() -> void:
	var total_time := life_loss_stunned_time if stunned_animation == &"life_knockdown" else stunned_time
	var recovery_started := action_timer <= total_time * 0.5
	var next_animation := "%s_reverse" % String(stunned_animation) if recovery_started else "%s_forward" % String(stunned_animation)
	if current_animation == next_animation:
		return
	current_animation = next_animation
	sprite.speed_scale = stunned_animation_speed
	if recovery_started:
		sprite.play_backwards(stunned_animation)
	else:
		sprite.play(stunned_animation)

func _trigger_parry_feedback(knockback_direction := INF, rebound := -1.0, hitstop_duration := -1.0, shake_amount := 18.0, shake_duration := 0.11) -> void:
	parry_flash_timer = parry_flash_time
	action_timer = min(action_timer, parry_success_recovery_time)
	hitstop_timer = parry_hitstop_time if hitstop_duration < 0.0 else hitstop_duration
	var direction := -facing if knockback_direction == INF else float(knockback_direction)
	var final_rebound := parry_rebound if rebound < 0.0 else rebound
	stored_velocity = Vector2(direction * final_rebound, velocity.y)
	if rebound >= heavy_parry_rebound:
		heavy_parry_recoil_timer = heavy_parry_recoil_time
		heavy_parry_recoil_velocity = stored_velocity
	velocity = Vector2.ZERO
	sprite.speed_scale = 0.0
	_shake_camera(shake_amount, shake_duration)

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

func _is_attacker_chop_attack(attacker: Node) -> bool:
	if attacker == null:
		return false
	var anim = attacker.get("current_attack_animation")
	return anim != null and str(anim) == "chop"

func _receive_attack_deflected() -> void:
	is_attacking = false
	attack_has_hit = false
	attack_buffer_queued = false
	attack_buffer_timer = 0.0
	attack_lockout_timer = attack_deflected_attack_lockout_time
	attack_lunge_timer = 0.0
	attack_combo_step = 0
	register_posture_contact()
	posture = math.add_posture(posture, 6.0)
	_add_heartbeat_pressure(6.0)
	if state == PlayerState.DEAD:
		return
	action_timer = attack_deflected_stun_time
	hurt_flash_timer = impact_flash_time * 0.65
	velocity.x = -facing * attack_deflected_rebound
	_play_sfx(block_sfx)
	_shake_camera(8.0, 0.08)
	hurt_animation = "deflect_miss"
	_set_state(PlayerState.HURT)
	_force_play_animation("deflect_miss")
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

func _trigger_parry_impact_vfx(attacker: Node) -> void:
	if hit_impact_vfx == null:
		return
	hit_impact_vfx_timer = max(hit_impact_vfx_time, heavy_parry_hitstop_time)
	hit_impact_vfx.visible = true
	if attacker is Node2D:
		var attacker_position := (attacker as Node2D).global_position
		hit_impact_vfx.global_position = global_position.lerp(attacker_position, 0.5) + Vector2(0.0, -58.0)
	else:
		hit_impact_vfx.position = attack_area.position + Vector2(20.0 * facing, -18.0)
	hit_impact_vfx.flip_h = facing < 0.0
	if hit_impact_vfx.sprite_frames != null:
		hit_impact_vfx.play("chop")

func _trigger_guard_impact_vfx(attacker: Node) -> void:
	if hit_impact_vfx == null:
		return
	hit_impact_vfx_timer = hit_impact_vfx_time
	hit_impact_vfx.visible = true
	if attacker is Node2D:
		var attacker_position := (attacker as Node2D).global_position
		hit_impact_vfx.global_position = global_position.lerp(attacker_position, 0.5) + Vector2(0.0, -48.0)
	else:
		hit_impact_vfx.position = attack_area.position + Vector2(18.0 * facing, -12.0)
	hit_impact_vfx.flip_h = facing < 0.0
	if hit_impact_vfx.sprite_frames != null:
		hit_impact_vfx.play("hit")

func _shake_camera(amount: float, duration: float) -> void:
	var camera := get_tree().get_first_node_in_group("feedback_camera")
	if camera != null and camera.has_method("shake"):
		camera.shake(amount, duration)

func _enter_dead() -> void:
	health = 0.0
	lives = 0
	revive_available_pending = false
	death_animation_reported = false
	_clear_hit_invulnerability()
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
	heavy_parry_recoil_timer = 0.0
	heavy_parry_recoil_velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	var bgm_player = get_tree().get_first_node_in_group("bgm_player")
	if bgm_player != null and bgm_player.has_method("fade_out_bgm"):
		bgm_player.fade_out_bgm(1.5)
	_fade_in_sfx(death_sfx, 1.0)
	_set_state(PlayerState.DEAD)
	_update_visuals()

func _enter_revive_wait_state() -> void:
	health = 0.0
	revive_available_pending = true
	death_animation_reported = false
	_clear_hit_invulnerability()
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
	heavy_parry_recoil_timer = 0.0
	heavy_parry_recoil_velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	_fade_in_sfx(death_sfx, 1.0)
	_set_state(PlayerState.DEAD)
	_update_visuals()
	stats_changed.emit()

func force_death_for_debug() -> void:
	if state == PlayerState.DEAD:
		return
	if lives > 1:
		_enter_revive_wait_state()
		revive_prompt_requested.emit()
		return
	_enter_dead()
	stats_changed.emit()
	died.emit()

func is_waiting_for_revive() -> bool:
	return revive_available_pending

func has_completed_death_animation() -> bool:
	return death_animation_reported

func revive_in_place() -> bool:
	if not revive_available_pending:
		return false
	lives = max(0, lives - 1)
	revive_available_pending = false
	death_animation_reported = false
	health = max_health
	posture = 0.0
	posture_combat_timer = 0.0
	posture_visibility_snapshot = posture
	posture_recovery_pause_timer = 0.0
	was_stunned_by_damage = false
	_set_heartbeat_value(CombatMathScript.MIN_HEARTBEAT)
	heartbeat_combat_timer = 0.0
	heartbeat_cooldown_delay_timer = 0.0
	heartbeat_direct_checkpoint_respawn = false
	_clear_hit_invulnerability()
	state = PlayerState.IDLE
	previous_state = PlayerState.IDLE
	is_blocking = false
	is_attacking = false
	is_parrying = false
	is_dashing = false
	is_running = false
	is_perfect_dodging = false
	is_invulnerable = false
	is_block_releasing = false
	block_age = 0.0
	parry_elapsed = 0.0
	block_time_left = 0.0
	action_timer = 0.0
	dash_timer = 0.0
	dash_direction = 1.0
	wall_climb_direction = 0.0
	wall_climb_lockout_timer = 0.0
	attack_elapsed = 0.0
	attack_buffer_timer = 0.0
	attack_buffer_queued = false
	attack_lockout_timer = 0.0
	attack_has_hit = false
	attack_has_cut_projectile = false
	attack_combo_step = 0
	current_attack_animation = "attack_a"
	_clear_attack_hold()
	hurt_animation = "hurt"
	attack_lunge_timer = 0.0
	current_animation = ""
	parry_flash_timer = 0.0
	block_flash_timer = 0.0
	hurt_flash_timer = 0.0
	perfect_dodge_timer = 0.0
	hit_impact_vfx_timer = 0.0
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	heavy_parry_recoil_timer = 0.0
	heavy_parry_recoil_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	sprite.speed_scale = 1.0
	if hit_impact_vfx != null:
		hit_impact_vfx.visible = false
	_update_visuals()
	stats_changed.emit()
	return true

func _on_sprite_animation_finished() -> void:
	if sprite == null or state != PlayerState.DEAD or sprite.animation != &"death" or death_animation_reported:
		return
	death_animation_reported = true
	death_animation_finished.emit(revive_available_pending)

func _has_damage_invulnerability() -> bool:
	return is_invulnerable

func _start_hit_invulnerability() -> void:
	hit_invulnerability_time_left = hit_invulnerability_duration
	hit_invulnerability_flash_timer = 0.0
	if not hit_invulnerability_active:
		hit_invulnerability_active = true
	else:
		_refresh_enemy_collision_exceptions()
	_apply_hit_invulnerability_flicker()
	_refresh_enemy_collision_exceptions()

func _update_hit_invulnerability(delta: float) -> void:
	if not hit_invulnerability_active:
		return
	hit_invulnerability_time_left = max(0.0, hit_invulnerability_time_left - delta)
	hit_invulnerability_flash_timer += delta
	if hit_invulnerability_time_left <= 0.0:
		_clear_hit_invulnerability()

func _apply_hit_invulnerability_flicker() -> void:
	if sprite == null:
		return
	if not hit_invulnerability_active:
		sprite.modulate.a = 1.0
		return
	var flash_phase: int = int(floor(hit_invulnerability_flash_timer / 0.07))
	sprite.modulate.a = 0.42 if flash_phase % 2 == 0 else 0.9

func _clear_hit_invulnerability() -> void:
	hit_invulnerability_time_left = 0.0
	hit_invulnerability_flash_timer = 0.0
	if not hit_invulnerability_active:
		if sprite != null:
			sprite.modulate.a = 1.0
		return
	hit_invulnerability_active = false
	if sprite != null:
		sprite.modulate.a = 1.0
	_refresh_enemy_collision_exceptions()

func _refresh_enemy_collision_exceptions() -> void:
	for group_name in ["enemy", "boss"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is PhysicsBody2D:
				var body: PhysicsBody2D = node as PhysicsBody2D
				if hit_invulnerability_active:
					add_collision_exception_with(body)
					body.add_collision_exception_with(self)
				else:
					remove_collision_exception_with(body)
					body.remove_collision_exception_with(self)

func _fade_in_sfx(player: AudioStreamPlayer2D, duration: float) -> void:
	if player == null:
		return
	player.volume_db = -80.0
	if player.stream != null:
		player.play()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", 0.0, duration)

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
	_load_optional_stream(KUNAI_SFX_PATH, kunai_sfx)

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
	lives = max_lives
	posture = 0.0
	posture_combat_timer = 0.0
	posture_visibility_snapshot = posture
	posture_recovery_pause_timer = 0.0
	was_stunned_by_damage = false
	_set_heartbeat_value(CombatMathScript.MIN_HEARTBEAT)
	heartbeat_combat_timer = 0.0
	heartbeat_cooldown_delay_timer = 0.0
	heartbeat_direct_checkpoint_respawn = false
	_clear_hit_invulnerability()
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
	wall_climb_direction = 0.0
	wall_climb_lockout_timer = 0.0
	attack_elapsed = 0.0
	attack_buffer_timer = 0.0
	attack_buffer_queued = false
	attack_lockout_timer = 0.0
	attack_has_hit = false
	attack_has_cut_projectile = false
	attack_combo_step = 0
	current_attack_animation = "attack_a"
	_clear_attack_hold()
	hurt_animation = "hurt"
	current_item_animation = "mudra"
	item_counts = DEFAULT_ITEM_COUNTS.duplicate()
	selected_item_index = 0
	selected_attack_item_index = 0
	selected_heal_item_index = 0
	item_hotkeys_down.clear()
	if is_instance_valid(active_teleport_kunai):
		active_teleport_kunai.queue_free()
	active_teleport_kunai = null
	clear_ai_intent()
	attack_lunge_timer = 0.0
	parry_flash_timer = 0.0
	block_flash_timer = 0.0
	hurt_flash_timer = 0.0
	perfect_dodge_timer = 0.0
	hit_impact_vfx_timer = 0.0
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	heavy_parry_recoil_timer = 0.0
	heavy_parry_recoil_velocity = Vector2.ZERO
	stunned_animation = &"posture_knockdown"
	stunned_animation_speed = posture_break_animation_speed
	velocity = Vector2.ZERO
	global_position = spawn_position
	sprite.speed_scale = 1.0
	if hit_impact_vfx != null:
		hit_impact_vfx.visible = false
	_set_state(PlayerState.IDLE)
	_update_visuals()
	stats_changed.emit()
