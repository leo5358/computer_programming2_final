extends "res://scripts/enemy_base.gd"

signal final_execution_requested(boss: Node2D)

# --- Boss Specific Constants ---
const WALK_PATH_BOSS := "res://assets/sprites/boss/walk.png"
const ATTACK_PATH_BOSS := "res://assets/sprites/boss/attack.png"
const CHOP_PATH_BOSS := "res://assets/sprites/boss/chop.png"
const THRUST_PATH_BOSS := "res://assets/sprites/boss/thrust.png"
const THRUST_COPY_PATH_BOSS := "res://assets/sprites/boss/thrust copy.png"
const DEFLECT1_PATH_BOSS := "res://assets/sprites/boss/deflect1.png"
const DEFLECT2_PATH_BOSS := "res://assets/sprites/boss/deflect2.png"
const HURT_PATH_BOSS := "res://assets/sprites/boss/hurt.png"
const DEATH_PATH_BOSS := "res://assets/sprites/boss/death.png"
const JUMP_PATH_BOSS := "res://assets/sprites/boss/jump.png"

const BOSS_HURT_SFX_PATHS := [
	"res://assets/sfx/enemy_hurt.wav",
	"res://assets/sfx/player_hurt.wav",
]

const ANIMATION_SPEEDS_BOSS := {
	"idle": 4.0,
	"walk": 4.0,
	"attack": 6.0,
	"attack2": 5.0,
	"thrust": 5.0,
	"chop": 5.0,
	"deflect1": 5.0,
	"deflect2": 5.0,
	"hurt": 5.0,
	"death": 5.0,
	"jump": 5.0,
}

const ATTACK_PROFILES_BOSS := {
	"attack": {
		"durations": [0.12, 0.15, 0.30, 0.08, 0.06, 0.10, 0.14, 0.16],
		"cue_start": 0.62,
		"hit_start": 0.78,
		"hit_end": 0.88,
		"damage": 45.0,
		"posture_damage": 28.0,
		"attack_type": 0, # NORMAL
		"perilous": false,
	},
	"chop": {
		"durations": [0.36, 0.42, 0.32, 0.26, 0.18, 0.055, 0.07, 0.10, 0.10, 0.14, 0.18],
		"cue_start": 1.32,
		"hit_start": 1.54,
		"hit_end": 1.665,
		"damage": 45.0,
		"posture_damage": 42.0,
		"attack_type": 0, # NORMAL
		"perilous": false,
	},
	"thrust": {
		"durations": [0.18, 0.22, 0.26, 0.16, 0.07, 0.09, 0.18, 0.24],
		"cue_start": 0.42,
		"hit_start": 0.82,
		"hit_end": 0.98,
		"damage": 45.0,
		"posture_damage": 36.0,
		"attack_type": 1, # THRUST
		"perilous": true,
	},
}

const ATTACK_PROFILE_SEQUENCE_BOSS := ["attack", "attack", "chop", "attack", "thrust"]

const LOOPING_ANIMATIONS_BOSS := {
	"idle": true,
	"walk": true,
}

const ANIMATION_FRAME_SPECS_BOSS := {
	"idle": [
		[WALK_PATH_BOSS, 0, 0, 125, 128],
		[WALK_PATH_BOSS, 125, 0, 125, 128],
		[WALK_PATH_BOSS, 250, 0, 125, 128],
		[WALK_PATH_BOSS, 375, 0, 125, 128],
		[WALK_PATH_BOSS, 500, 0, 125, 128],
		[WALK_PATH_BOSS, 750, 0, 125, 128],
		[WALK_PATH_BOSS, 875, 0, 125, 128],
		[WALK_PATH_BOSS, 625, 0, 125, 128],
	],
	"walk": [
		[WALK_PATH_BOSS, 0, 0, 125, 128],
		[WALK_PATH_BOSS, 125, 0, 125, 128],
		[WALK_PATH_BOSS, 250, 0, 125, 128],
		[WALK_PATH_BOSS, 375, 0, 125, 128],
		[WALK_PATH_BOSS, 500, 0, 125, 128],
		[WALK_PATH_BOSS, 750, 0, 125, 128],
		[WALK_PATH_BOSS, 875, 0, 125, 128],
		[WALK_PATH_BOSS, 625, 0, 125, 128],
	],
	"attack": [
		[ATTACK_PATH_BOSS, 0, 0, 125, 128],
		[ATTACK_PATH_BOSS, 125, 0, 125, 128],
		[ATTACK_PATH_BOSS, 248, 0, 124, 128],
		[ATTACK_PATH_BOSS, 384, 0, 128, 128],
		[ATTACK_PATH_BOSS, 532, 0, 133, 128],
		[ATTACK_PATH_BOSS, 665, 0, 133, 128],
		[ATTACK_PATH_BOSS, 792, 0, 128, 128],
		[ATTACK_PATH_BOSS, 2, 0, 125, 128],
	],
	"attack2": [
		[ATTACK_PATH_BOSS, 0, 0, 125, 128],
		[ATTACK_PATH_BOSS, 125, 0, 125, 128],
		[ATTACK_PATH_BOSS, 248, 0, 124, 128],
		[ATTACK_PATH_BOSS, 384, 0, 128, 128],
		[ATTACK_PATH_BOSS, 532, 0, 133, 128],
		[ATTACK_PATH_BOSS, 665, 0, 133, 128],
		[ATTACK_PATH_BOSS, 792, 0, 128, 128],
		[ATTACK_PATH_BOSS, 2, 0, 125, 128],
		[CHOP_PATH_BOSS, 8, 0, 127, 128],
		[CHOP_PATH_BOSS, 135, 0, 127, 128],
		[CHOP_PATH_BOSS, 262, 0, 127, 128],
		[CHOP_PATH_BOSS, 408, 0, 127, 128],
		[CHOP_PATH_BOSS, 535, 0, 127, 128],
		[CHOP_PATH_BOSS, 687, 0, 132, 128],
		[CHOP_PATH_BOSS, 811, 0, 129, 128],
		[ATTACK_PATH_BOSS, 2, 0, 125, 128],
	],
	"chop": [
		[CHOP_PATH_BOSS, 8, 0, 127, 128],
		[CHOP_PATH_BOSS, 135, 0, 127, 128],
		[CHOP_PATH_BOSS, 262, 0, 127, 128],
		[CHOP_PATH_BOSS, 408, 0, 127, 128],
		[CHOP_PATH_BOSS, 535, 0, 127, 128],
		[CHOP_PATH_BOSS, 687, 0, 132, 128],
		[CHOP_PATH_BOSS, 811, 0, 129, 128],
		[CHOP_PATH_BOSS, 811, 0, 129, 128],
		[CHOP_PATH_BOSS, 687, 0, 132, 128],
		[CHOP_PATH_BOSS, 135, 0, 127, 128],
		[CHOP_PATH_BOSS, 940, 0, 84, 128],
	],
	"thrust": [
		[THRUST_PATH_BOSS, 0, 0, 128, 128],
		[THRUST_PATH_BOSS, 136, 0, 127, 128],
		[THRUST_PATH_BOSS, 259, 0, 126, 128],
		[THRUST_PATH_BOSS, 387, 0, 129, 128],
		[THRUST_COPY_PATH_BOSS, 0, 0, 144, 128],
		[THRUST_COPY_PATH_BOSS, 144, 0, 144, 128],
		[THRUST_PATH_BOSS, 136, 0, 127, 128],
		[THRUST_PATH_BOSS, 0, 0, 128, 128],
	],
	"deflect1": [
		[DEFLECT1_PATH_BOSS, 0, 0, 128, 128],
		[DEFLECT1_PATH_BOSS, 128, 0, 128, 128],
		[DEFLECT1_PATH_BOSS, 256, 0, 128, 128],
		[DEFLECT1_PATH_BOSS, 384, 0, 128, 128],
		[DEFLECT1_PATH_BOSS, 512, 0, 128, 128],
		[DEFLECT1_PATH_BOSS, 650, 0, 128, 128],
		[DEFLECT1_PATH_BOSS, 778, 0, 128, 128],
		[DEFLECT1_PATH_BOSS, 893, 0, 127, 128],
	],
	"deflect2": [
		[DEFLECT2_PATH_BOSS, 8, 0, 127, 128],
		[DEFLECT2_PATH_BOSS, 128, 0, 128, 128],
		[DEFLECT2_PATH_BOSS, 256, 0, 128, 128],
		[DEFLECT2_PATH_BOSS, 384, 0, 128, 128],
		[DEFLECT2_PATH_BOSS, 512, 0, 128, 128],
		[DEFLECT2_PATH_BOSS, 776, 0, 127, 128],
		[DEFLECT2_PATH_BOSS, 772, 0, 126, 128],
		[DEFLECT2_PATH_BOSS, 8, 0, 127, 128],
	],
	"death": [
		[DEATH_PATH_BOSS, 10, 0, 126, 128],
		[DEATH_PATH_BOSS, 136, 0, 126, 128],
		[DEATH_PATH_BOSS, 262, 0, 126, 128],
		[DEATH_PATH_BOSS, 379, 0, 123, 128],
		[DEATH_PATH_BOSS, 502, 0, 123, 128],
		[DEATH_PATH_BOSS, 625, 0, 123, 128],
		[DEATH_PATH_BOSS, 748, 0, 123, 128],
		[DEATH_PATH_BOSS, 871, 0, 123, 128],
	],
	"jump": [
		[JUMP_PATH_BOSS, 10, 0, 123, 128],
		[JUMP_PATH_BOSS, 133, 0, 123, 128],
		[JUMP_PATH_BOSS, 256, 0, 123, 128],
		[JUMP_PATH_BOSS, 257, 0, 126, 128],
		[JUMP_PATH_BOSS, 383, 0, 126, 128],
		[JUMP_PATH_BOSS, 509, 0, 126, 128],
		[JUMP_PATH_BOSS, 766, 0, 126, 128],
		[JUMP_PATH_BOSS, 892, 0, 126, 128],
	],
	"hurt": [
		[HURT_PATH_BOSS, 0, 0, 128, 128],
		[HURT_PATH_BOSS, 128, 0, 128, 128],
		[HURT_PATH_BOSS, 256, 0, 128, 128],
		[HURT_PATH_BOSS, 384, 0, 128, 128],
		[HURT_PATH_BOSS, 512, 0, 128, 128],
		[HURT_PATH_BOSS, 640, 0, 128, 128],
		[HURT_PATH_BOSS, 768, 0, 128, 128],
		[HURT_PATH_BOSS, 896, 0, 128, 128],
	],
}

const FRAME_BOTTOM_GAPS_BOSS := {
	"idle": [6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0],
	"walk": [6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0],
	"attack": [8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0],
	"thrust": [7.0, 9.0, 10.0, 10.0, 10.0, 10.0, 10.0, 7.0],
	"chop": [5.0, 7.0, 18.0, 22.0, 23.0, 7.0, 7.0, 7.0, 7.0, 7.0, 5.0],
	"deflect1": [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0],
	"deflect2": [7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0],
	"hurt": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	"death": [10.0, 10.0, 10.0, 10.0, 9.0, 5.0, 5.0, 5.0],
	"jump": [6.0, 6.0, 7.0, 19.0, 26.0, 21.0, 7.0, 6.0],
}

const FRAME_VERTICAL_LIFTS_BOSS := {
	"chop": [0.0, -18.0, -92.0, -128.0, -106.0, -36.0, 0.0, 0.0, -12.0, -6.0, 0.0],
}

const FRAME_CENTER_X_BOSS := {
	"idle": [74.0, 67.0, 64.5, 61.0, 55.5, 50.5, 44.0, 45.0],
	"walk": [74.0, 67.0, 64.5, 61.0, 55.5, 50.5, 44.0, 45.0],
}

const VISUAL_CENTER_X_BOSS := 64.0
const WALK_ANCHOR_STRENGTH_BOSS := 0.45

# --- Boss Parameters ---
@export var posture_gain_on_direct_damage_boss := 11.0
@export var leash_range_boss := 900.0
@export var detection_range_boss := 900.0
@export var attack_start_distance_boss := 112.0
@export var attack_hold_distance_boss := 78.0
@export var close_spacing_distance_boss := 58.0
@export var spacing_retreat_speed_boss := 72.0
@export var gap_close_thrust_min_distance_boss := 130.0
@export var gap_close_thrust_max_distance_boss := 190.0
@export var chop_gap_close_min_distance_boss := 118.0
@export var chop_gap_close_max_distance_boss := 340.0
@export var chop_gap_close_commit_min_distance_boss := 240.0
@export var chop_lunge_start_boss := 0.78
@export var chop_lunge_end_boss := 1.54
@export var chop_lunge_speed_boss := 330.0
@export var chop_lunge_stop_distance_boss := 52.0
@export var attack_step_distance_boss := 24.0
@export var attack_step_time_boss := 0.16
@export var thrust_lunge_start_boss := 0.76
@export var thrust_lunge_end_boss := 1.00
@export var thrust_lunge_speed_boss := 340.0
@export var combo_link_delay_boss := 0.22
@export var combo_max_count_boss := 2
@export var combo_vertical_tolerance_boss := 84.0
@export var perfect_parry_cooldown_boss := 1.05
@export var guard_pressure_chop_threshold_boss := 2
@export var attack_hit_frame_boss := 4
@export var attack_frame_durations_boss: Array[float] = [0.12, 0.15, 0.30, 0.08, 0.06, 0.10, 0.14, 0.16]
@export var attack_parry_window_start_boss := 0.62
@export var attack_hit_time_boss := 0.78
@export var attack_hit_window_end_boss := 0.88
@export var raw_hitstop_time_boss := 0.07
@export var parry_clash_hitstop_time_boss := 0.105
@export var hit_recoil_time_boss := 0.12
@export var hit_flash_time_boss := 0.10
@export var hit_spark_time_boss := 0.16
@export var hit_freeze_time_boss := 0.055
@export var hurt_feedback_time_boss := 0.66
@export var posture_gain_on_perfect_parried_boss := 10.0
@export var posture_gain_on_partial_guarded_boss := 6.0
@export var posture_gain_on_guard_success_boss := 6.0
@export var posture_break_idle_reset_delay_boss := 6.0
@export var posture_break_hit_reset_delay_boss := 3.0
@export var deflect_feedback_time_boss := 0.28
@export var perfect_deflect_feedback_time_boss := 0.50
@export var forced_counter_deflect_window_boss := 0.95
@export var debug_fixed_attack_profile_boss := ""
@export var minimum_health_from_player_attack_boss := 0.0
@export var attack_recovery_time_boss := 0.58
@export var attack_pressure_commit_time_boss := 0.45
@export var chop_parry_hitstop_time_boss := 0.20
@export var chop_parry_boss_rebound_speed_boss := 520.0
@export var chop_parry_recoil_time_boss := 0.34
@export var chop_parry_camera_shake_boss := 42.0

# --- Boss State ---
var current_animation_boss := "idle"
var is_chasing_boss := false
var is_attack_winding_up_boss := false
var is_attack_active_boss := false
var is_attack_recovering_boss := false
var attack_timer_boss := 0.0
var attack_animation_total_time_boss := 1.16
var attack_profile_cursor_boss := 0
var attack_chain_count_boss := 0
var pending_combo_followup_boss := false
var guard_pressure_count_boss := 0
var attack_step_timer_boss := 0.0
var hitstop_timer_boss := 0.0
var stored_velocity_boss := Vector2.ZERO
var feedback_timer_boss := 0.0
var deflect_toggle_boss := false
var has_engaged_player_boss := false
var forced_counter_profile_boss := ""
var consecutive_guard_count_boss := 0
var forced_counter_timer_boss := 0.0
var attack_pressure_timer_boss := 0.0
var is_chop_parried_recovery_boss := false
var smoke_bomb_pause_timer_boss := 0.0
var posture_break_reset_timer_boss := 0.0
var posture_break_took_followup_hit_boss := false
var final_execution_requested_boss := false

var attack_pressure_timer: float:
	get:
		return attack_pressure_timer_boss
	set(value):
		attack_pressure_timer_boss = value

var attack_pressure_commit_time: float:
	get:
		return attack_pressure_commit_time_boss
	set(value):
		attack_pressure_commit_time_boss = value

var feedback_timer: float:
	get:
		return feedback_timer_boss
	set(value):
		feedback_timer_boss = value

var deflect_feedback_time: float:
	get:
		return deflect_feedback_time_boss
	set(value):
		deflect_feedback_time_boss = value

var forced_counter_profile: String:
	get:
		return forced_counter_profile_boss
	set(value):
		forced_counter_profile_boss = value

var is_attack_winding_up: bool:
	get:
		return is_attack_winding_up_boss
	set(value):
		is_attack_winding_up_boss = value

var is_attack_active: bool:
	get:
		return is_attack_active_boss
	set(value):
		is_attack_active_boss = value

var is_attack_recovering: bool:
	get:
		return is_attack_recovering_boss
	set(value):
		is_attack_recovering_boss = value

var is_chasing: bool:
	get:
		return is_chasing_boss
	set(value):
		is_chasing_boss = value

var has_engaged_player: bool:
	get:
		return has_engaged_player_boss
	set(value):
		has_engaged_player_boss = value

var current_animation: String:
	get:
		return current_animation_boss
	set(value):
		current_animation_boss = value

var attack_windup_time: float:
	get:
		return attack_hit_window_end_boss
	set(value):
		attack_hit_time_boss = value

var attack_start_distance: float:
	get:
		return min(attack_start_distance_boss, 90.0)
	set(value):
		attack_start_distance_boss = value

var attack_step_distance: float:
	get:
		return attack_step_distance_boss
	set(value):
		attack_step_distance_boss = value

var attack_animation_total_time: float:
	get:
		return attack_animation_total_time_boss
	set(value):
		attack_animation_total_time_boss = value

var attack_frame_durations: Array[float]:
	get:
		return attack_frame_durations_boss
	set(value):
		attack_frame_durations_boss = value

var attack_parry_window_start: float:
	get:
		return attack_parry_window_start_boss
	set(value):
		attack_parry_window_start_boss = value

var attack_hit_time: float:
	get:
		return attack_hit_time_boss
	set(value):
		attack_hit_time_boss = value

var attack_hit_window_end: float:
	get:
		return attack_hit_window_end_boss
	set(value):
		attack_hit_window_end_boss = value

var hitstop_timer: float:
	get:
		return hitstop_timer_boss
	set(value):
		hitstop_timer_boss = value

var pending_combo_followup: bool:
	get:
		return pending_combo_followup_boss
	set(value):
		pending_combo_followup_boss = value

var combo_link_delay: float:
	get:
		return combo_link_delay_boss
	set(value):
		combo_link_delay_boss = value

var attack_chain_count: int:
	get:
		return attack_chain_count_boss
	set(value):
		attack_chain_count_boss = value

var perfect_parry_cooldown: float:
	get:
		return perfect_parry_cooldown_boss
	set(value):
		perfect_parry_cooldown_boss = value

var normal_attack_parry_posture_damage: float:
	get:
		return posture_gain_on_perfect_parried_boss
	set(value):
		posture_gain_on_perfect_parried_boss = value

var minimum_health_from_player_attack: float:
	get:
		return minimum_health_from_player_attack_boss
	set(value):
		minimum_health_from_player_attack_boss = value

@onready var enemy_hurt_sfx_node: AudioStreamPlayer2D = get_node_or_null("EnemyHurtSfx") as AudioStreamPlayer2D
@onready var debug_response_label_node: Label = get_node_or_null("DebugResponseLabel") as Label
@onready var perilous_label_node: Label = _create_perilous_label()

func _ready() -> void:
	super()
	var fallback_body := get_node_or_null("Body") as CanvasItem
	if fallback_body != null:
		fallback_body.visible = false
	
	add_to_group("boss")
	remove_from_group("minor_enemy")
	_update_overhead_bars()
	
	display_name = "Corrupted Guardian"
	max_health = 400.0
	max_posture = 120.0
	patrol_speed = 58.0
	patrol_distance = 120.0
	chase_speed = 86.0
	attack_range = 142.0
	attack_damage = 45.0
	attack_posture_damage = 28.0
	attack_cooldown_duration = 1.38
	posture_recovery_pause = 1.6
	posture_recovery_rate = 5.0
	posture_recovery_percent_per_second = 0.10
	guard_chance = 0.8
	minimum_health_from_player_attack_boss = 0.0
	guard_lockout_duration = 0.32
	perfect_parry_input_leeway = 0.30
	patrol_direction = 1.0
	facing = 1.0
	
	health = max_health
	posture = 0.0
	
	_setup_sprite_frames_boss()
	if sprite != null:
		sprite.position = Vector2(0.0, -64.0)
		if not sprite.frame_changed.is_connected(align_sprite_to_ground_boss):
			sprite.frame_changed.connect(align_sprite_to_ground_boss)
	
	_update_attack_hitbox_boss_internal()
	attack_animation_total_time_boss = _calc_attack_total_time_boss()
	_load_optional_sfx_boss()
	play_boss_animation("idle")
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	if feedback_timer_boss > 0.0:
		feedback_timer_boss = max(0.0, feedback_timer_boss - delta)
	forced_counter_timer_boss = max(0.0, forced_counter_timer_boss - delta)
	guard_lockout_timer = max(0.0, guard_lockout_timer - delta)
	
	_update_hit_feedback_boss_internal(delta)

	if smoke_bomb_pause_timer_boss > 0.0:
		smoke_bomb_pause_timer_boss = max(0.0, smoke_bomb_pause_timer_boss - delta)
		velocity = Vector2.ZERO
		_update_attack_visual_boss_internal(false, false)
		if sprite != null:
			sprite.speed_scale = 0.0 if smoke_bomb_pause_timer_boss > 0.0 else 1.0
		align_sprite_to_ground_boss()
		stats_changed.emit()
		return
	
	if hitstop_timer_boss > 0.0:
		hitstop_timer_boss = max(0.0, hitstop_timer_boss - delta)
		if hitstop_timer_boss <= 0.0 and sprite != null:
			sprite.speed_scale = 0.0 if current_animation_boss == current_attack_animation else 1.0
			velocity = stored_velocity_boss
		else:
			velocity = Vector2.ZERO
		align_sprite_to_ground_boss()
		return
		
	if defeated_flag:
		velocity = Vector2.ZERO
		align_sprite_to_ground_boss()
		_update_visuals_boss_internal()
		stats_changed.emit()
		return
	elif posture_broken:
		velocity.x = 0.0
		posture_break_reset_timer_boss = max(0.0, posture_break_reset_timer_boss - delta)
		play_boss_animation(current_animation_boss)
		if posture_break_reset_timer_boss <= 0.0:
			_reset_boss_posture_break_state()
			play_boss_animation("idle")
	elif feedback_timer_boss > 0.0:
		velocity.x = 0.0
	elif hit_recoil_timer > 0.0:
		pass
	elif is_attack_winding_up_boss or is_attack_active_boss or is_attack_recovering_boss or is_chop_parried_recovery_boss:
		_update_attack_state_boss_internal(delta)
	else:
		_update_pressure_and_posture(delta)
		attack_cooldown = max(0.0, attack_cooldown - delta)
		if _update_attack_pressure_boss_internal(delta):
			pass
		elif _should_start_attack_boss_internal():
			_start_normal_attack_boss_internal()
		elif _should_start_gap_close_thrust_boss_internal():
			_start_normal_attack_boss_internal("thrust")
		elif _should_chase_player_boss_internal():
			_update_chase_boss_internal()
		elif _should_hold_player_boss_internal():
			_update_engaged_hold_boss_internal()
		else:
			_update_patrol_boss_internal()
			
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()
	align_sprite_to_ground_boss()
	_update_visuals_boss_internal()
	stats_changed.emit()

func play_boss_animation(animation: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation):
		return
	current_animation_boss = animation
	sprite.speed_scale = 1.0
	if sprite.animation != animation:
		sprite.play(animation)
	align_sprite_to_ground_boss()

func align_sprite_to_ground() -> void:
	align_sprite_to_ground_boss()

func has_attack_profile(profile_name: String) -> bool:
	return ATTACK_PROFILES_BOSS.has(profile_name)

func _start_normal_attack(profile_name: String = "", combo_followup: bool = false) -> void:
	_start_normal_attack_boss_internal(profile_name, combo_followup)

func _update_attack_state(delta: float) -> void:
	_update_attack_state_boss_internal(delta)

func _should_start_attack() -> bool:
	return _should_start_attack_boss_internal()

func _update_attack_visual(show_visual: bool, active: bool) -> void:
	_update_attack_visual_boss_internal(show_visual, active)

func _sync_attack_animation_frame() -> void:
	_sync_attack_animation_frame_boss_internal()

func _connect_normal_attack() -> void:
	_connect_normal_attack_boss_internal()

func can_be_perfect_dodged_by(_player: Node) -> bool:
	return false

func can_be_executed() -> bool:
	return (posture_broken or posture >= max_posture) and not defeated_flag

func execute() -> void:
	if can_be_executed():
		defeated_flag = true
		health = 0.0
		posture_broken = false
		final_execution_requested_boss = false
		_interrupt_attack_boss_internal()
		play_boss_animation("death")
		if execute_label != null:
			execute_label.visible = false
		_disable_boss_collision()
		stats_changed.emit()

func complete_final_execution_death() -> void:
	defeated_flag = true
	health = 0.0
	posture = max_posture
	posture_broken = false
	final_execution_requested_boss = false
	_interrupt_attack_boss_internal()
	if execute_label != null:
		execute_label.visible = false
	_disable_boss_collision()
	stats_changed.emit()

func _disable_boss_collision() -> void:
	collision_layer = 0
	collision_mask = 0

func receive_dodge_feedback() -> void:
	if defeated_flag:
		return
	posture = clamp(posture + dodge_posture_damage, 0.0, max_posture)
	_mark_combat_pressure()
	_interrupt_attack_boss_internal()
	dodge_spark_timer = 0.18
	hit_flash_timer = 0.08
	hit_spark_timer = 0.16
	hit_recoil_timer = 0.12
	velocity.x = -facing * hit_recoil_force
	if posture >= max_posture:
		_start_boss_posture_break(posture_break_idle_reset_delay_boss)

func receive_smoke_bomb_pause(duration: float) -> void:
	if defeated_flag:
		return
	smoke_bomb_pause_timer_boss = max(smoke_bomb_pause_timer_boss, duration)
	_interrupt_attack_boss_internal()
	is_chop_parried_recovery_boss = false
	attack_pressure_timer_boss = 0.0
	attack_cooldown = max(attack_cooldown, duration * 0.35)
	velocity = Vector2.ZERO
	_update_attack_visual_boss_internal(false, false)
	if sprite != null:
		sprite.speed_scale = 0.0
	stats_changed.emit()

func _force_play_boss_animation(animation: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation):
		return
	current_animation_boss = animation
	sprite.speed_scale = 1.0
	sprite.play(animation)
	sprite.frame = 0
	align_sprite_to_ground_boss()

func align_sprite_to_ground_boss() -> void:
	if sprite == null:
		return
	sprite.offset = Vector2(
		_horizontal_anchor_for_frame_boss(current_animation_boss, sprite.frame),
		_bottom_gap_for_frame_boss(current_animation_boss, sprite.frame) + _vertical_lift_for_frame_boss(current_animation_boss, sprite.frame)
	)

func receive_player_attack(damage: float, posture_damage: float) -> Variant:
	if defeated_flag:
		return false
	if can_be_executed():
		health = max(0.0, health - damage)
		if posture_broken and not posture_break_took_followup_hit_boss:
			posture_break_took_followup_hit_boss = true
			posture_break_reset_timer_boss = posture_break_hit_reset_delay_boss
		if not final_execution_requested_boss:
			final_execution_requested_boss = true
			final_execution_requested.emit(self)
		stats_changed.emit()
		return true
	has_engaged_player_boss = true
	_mark_combat_pressure()
	
	if _can_chain_deflect_during_feedback_boss():
		_guard_player_attack_boss_internal()
		return {"guarded": true}
	if _is_forced_counter_protected_boss():
		if is_attack_winding_up_boss or is_attack_active_boss or is_attack_recovering_boss:
			return {"guarded": true}
		_guard_player_attack_boss_internal()
		return {"guarded": true}
	if _should_guard_player_attack_boss_internal():
		_guard_player_attack_boss_internal()
		return {"guarded": true}
		
	_spawn_damage_number_boss(damage)
	health = max(0.0, health - damage)
	posture = clamp(posture + _boss_posture_amount_from_percent(posture_gain_on_direct_damage_boss), 0.0, max_posture)
	
	_force_play_boss_animation("hurt")
	feedback_timer_boss = max(feedback_timer_boss, hurt_feedback_time_boss)
	_trigger_hit_feedback_boss_internal()
	
	if posture >= max_posture:
		_start_boss_posture_break(posture_break_idle_reset_delay_boss)
	elif health <= 0.0:
		execute()
	stats_changed.emit()
	return true

func _should_guard_player_attack_boss_internal() -> bool:
	if guard_chance <= 0.0:
		return false
	if guard_lockout_timer > 0.0:
		return false
	if defeated_flag:
		return false
	if feedback_timer_boss > 0.0:
		return false
	if _is_forced_counter_protected_boss():
		return true
	if is_attack_winding_up_boss or is_attack_recovering_boss:
		return false
	if is_attack_active_boss:
		return false
	return randf() <= guard_chance

func _guard_player_attack_boss_internal() -> void:
	_mark_combat_pressure()
	posture = clamp(posture + _boss_posture_amount_from_percent(posture_gain_on_guard_success_boss), 0.0, max_posture)
	_interrupt_attack_boss_internal()
	_queue_forced_counter_boss()
	deflect_toggle_boss = not deflect_toggle_boss
	_force_play_boss_animation("deflect1" if deflect_toggle_boss else "deflect2")
	feedback_timer_boss = deflect_feedback_time_boss
	guard_lockout_timer = guard_lockout_duration
	attack_cooldown = 0.0
	hit_spark_timer = hit_spark_time_boss
	hit_recoil_timer = min(hit_recoil_time_boss, 0.10)
	hit_flash_timer = 0.08
	velocity.x = -facing * hit_recoil_force * 0.45
	if hit_spark != null:
		hit_spark.visible = false
	if posture >= max_posture:
		_start_boss_posture_break(posture_break_idle_reset_delay_boss)
	stats_changed.emit()

func receive_block_feedback(_perfect: bool) -> void:
	_receive_block_feedback_boss_internal(_perfect)

func receive_block_feedback_from_player(_perfect: bool, _defender: Node) -> void:
	_receive_block_feedback_boss_internal(_perfect)

func _receive_block_feedback_boss_internal(_perfect: bool) -> void:
	if defeated_flag or posture_broken:
		return
	has_engaged_player_boss = true
	_mark_combat_pressure()
	var perfect := _perfect
	var posture_percent := posture_gain_on_perfect_parried_boss if _perfect else posture_gain_on_partial_guarded_boss
	posture = clamp(posture + _boss_posture_amount_from_percent(posture_percent), 0.0, max_posture)
	if posture >= max_posture:
		_start_boss_posture_break(posture_break_idle_reset_delay_boss)
		stats_changed.emit()
		return
	if perfect and current_attack_animation == "chop" and (is_attack_winding_up_boss or is_attack_active_boss):
		_start_chop_parried_recovery_boss_internal()
		stats_changed.emit()
		return
	_interrupt_attack_boss_internal()
	if perfect:
		guard_pressure_count_boss = 0
		attack_cooldown = perfect_parry_cooldown_boss
	else:
		guard_pressure_count_boss += 1
	deflect_toggle_boss = not deflect_toggle_boss
	play_boss_animation("deflect1" if deflect_toggle_boss else "deflect2")
	feedback_timer_boss = perfect_deflect_feedback_time_boss if perfect else deflect_feedback_time_boss
	if perfect:
		_begin_local_hitstop(parry_clash_hitstop_time_boss)
	stats_changed.emit()

func reset_combat_state() -> void:
	super()
	defeated_flag = false
	posture_broken = false
	velocity = Vector2.ZERO
	patrol_direction = 1.0
	facing = 1.0
	is_chasing_boss = false
	attack_cooldown = 0.65
	attack_pressure_timer_boss = 0.0
	is_attack_winding_up_boss = false
	is_attack_active_boss = false
	is_attack_recovering_boss = false
	is_chop_parried_recovery_boss = false
	attack_has_connected = false
	attack_timer_boss = 0.0
	attack_elapsed = 0.0
	attack_profile_cursor_boss = 0
	attack_chain_count_boss = 0
	pending_combo_followup_boss = false
	guard_pressure_count_boss = 0
	current_attack_animation = "attack"
	current_attack_type = 0 # NORMAL
	_apply_attack_profile_boss_internal("attack")
	attack_step_timer_boss = 0.0
	hitstop_timer_boss = 0.0
	stored_velocity_boss = Vector2.ZERO
	hit_spark_timer = 0.0
	hit_recoil_timer = 0.0
	hit_flash_timer = 0.0
	hit_flicker_timer = 0.0
	hit_flicker_elapsed = 0.0
	feedback_timer_boss = 0.0
	guard_lockout_timer = 0.0
	has_engaged_player_boss = false
	posture_recovery_pause_timer = 0.0
	posture_break_reset_timer_boss = 0.0
	posture_break_took_followup_hit_boss = false
	final_execution_requested_boss = false
	forced_counter_profile_boss = ""
	consecutive_guard_count_boss = 0
	forced_counter_timer_boss = 0.0
	smoke_bomb_pause_timer_boss = 0.0
	global_position = spawn_position
	if execute_label != null:
		execute_label.visible = false
	if attack_visual != null:
		attack_visual.visible = false
	if hit_spark != null:
		hit_spark.visible = false
	if sprite != null:
		sprite.modulate = Color.WHITE
	if debug_response_label_node != null:
		debug_response_label_node.visible = false
	if perilous_label_node != null:
		perilous_label_node.visible = false
	collision_layer = default_collision_layer
	collision_mask = default_collision_mask
	play_boss_animation("walk")
	stats_changed.emit()

func _break_posture_boss_internal() -> void:
	_start_boss_posture_break(posture_break_idle_reset_delay_boss)

func _boss_posture_amount_from_percent(percent: float) -> float:
	return ceil(max_posture * (percent / 100.0))

func _reset_boss_posture_break_state() -> void:
	posture = 0.0
	posture_broken = false
	posture_break_reset_timer_boss = 0.0
	posture_break_took_followup_hit_boss = false
	final_execution_requested_boss = false
	if execute_label != null:
		execute_label.visible = false
	if hit_spark != null:
		hit_spark.visible = false

func _start_boss_posture_break(reset_delay: float) -> void:
	if posture_broken or defeated_flag:
		return
	posture = max_posture
	posture_broken = true
	posture_break_reset_timer_boss = reset_delay
	posture_break_took_followup_hit_boss = false
	_interrupt_attack_boss_internal()
	feedback_timer_boss = max(feedback_timer_boss, perfect_deflect_feedback_time_boss)
	velocity = Vector2.ZERO
	if execute_label != null:
		execute_label.visible = false
	if attack_visual != null:
		attack_visual.visible = false
	if debug_response_label_node != null:
		debug_response_label_node.visible = false
	if hit_spark != null:
		hit_spark.visible = false
	hit_spark_timer = max(hit_spark_timer, hit_spark_time_boss)
	_force_play_boss_animation("deflect2" if deflect_toggle_boss else "deflect1")
	stats_changed.emit()

func _setup_sprite_frames_boss() -> void:
	if sprite == null:
		return
	var frames := SpriteFrames.new()
	for anim in ANIMATION_FRAME_SPECS_BOSS.keys():
		_add_strip_animation_boss_internal(frames, String(anim))
	sprite.sprite_frames = frames

func _calc_attack_total_time_boss() -> float:
	var total := 0.0
	for duration in attack_frame_durations_boss:
		total += float(duration)
	return total

func is_current_attack_perilous() -> bool:
	var profile: Dictionary = ATTACK_PROFILES_BOSS.get(current_attack_animation, {})
	return bool(profile.get("perilous", false))

func _choose_attack_profile_boss() -> String:
	if not debug_fixed_attack_profile_boss.is_empty() and ATTACK_PROFILES_BOSS.has(debug_fixed_attack_profile_boss):
		return debug_fixed_attack_profile_boss
	if not forced_counter_profile_boss.is_empty():
		var profile := forced_counter_profile_boss
		forced_counter_profile_boss = ""
		forced_counter_timer_boss = 0.0
		return profile
	if _should_use_chop_gap_close_boss_internal():
		return "chop"
	if guard_pressure_count_boss >= guard_pressure_chop_threshold_boss:
		guard_pressure_count_boss = 0
		return "chop"
	var profile_name := String(ATTACK_PROFILE_SEQUENCE_BOSS[attack_profile_cursor_boss % ATTACK_PROFILE_SEQUENCE_BOSS.size()])
	attack_profile_cursor_boss += 1
	return profile_name

func _apply_attack_profile_boss_internal(profile_name: String) -> void:
	if not ATTACK_PROFILES_BOSS.has(profile_name):
		profile_name = "attack"
	var profile: Dictionary = ATTACK_PROFILES_BOSS[profile_name]
	current_attack_animation = profile_name
	attack_frame_durations_boss.clear()
	for duration in profile["durations"]:
		attack_frame_durations_boss.append(float(duration))
	attack_parry_window_start_boss = float(profile["cue_start"])
	attack_hit_time_boss = float(profile["hit_start"])
	attack_hit_window_end_boss = float(profile["hit_end"])
	attack_damage = float(profile["damage"])
	attack_posture_damage = float(profile["posture_damage"])
	current_attack_type = int(profile["attack_type"])
	attack_animation_total_time_boss = _calc_attack_total_time_boss()

func _add_strip_animation_boss_internal(frames: SpriteFrames, animation: String) -> void:
	if not ANIMATION_FRAME_SPECS_BOSS.has(animation):
		return
	var frame_specs: Array = ANIMATION_FRAME_SPECS_BOSS[animation]
	frames.add_animation(animation)
	frames.set_animation_speed(animation, float(ANIMATION_SPEEDS_BOSS.get(animation, 10.0)))
	frames.set_animation_loop(animation, bool(LOOPING_ANIMATIONS_BOSS.get(animation, false)))
	for frame_spec in frame_specs:
		var path: String = String(frame_spec[0])
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		if texture == null:
			continue
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(
			float(frame_spec[1]),
			float(frame_spec[2]),
			float(frame_spec[3]),
			float(frame_spec[4])
		)
		atlas_texture.filter_clip = true
		frames.add_frame(animation, atlas_texture)

func _bottom_gap_for_frame_boss(animation: String, frame: int) -> float:
	if not FRAME_BOTTOM_GAPS_BOSS.has(animation):
		return 0.0
	var gaps: Array = FRAME_BOTTOM_GAPS_BOSS[animation]
	if gaps.is_empty():
		return 0.0
	var index: int = clamp(frame, 0, gaps.size() - 1)
	return float(gaps[index])

func _vertical_lift_for_frame_boss(animation: String, frame: int) -> float:
	if not FRAME_VERTICAL_LIFTS_BOSS.has(animation):
		return 0.0
	var lifts: Array = FRAME_VERTICAL_LIFTS_BOSS[animation]
	if lifts.is_empty():
		return 0.0
	var index: int = clamp(frame, 0, lifts.size() - 1)
	return float(lifts[index])

func _horizontal_anchor_for_frame_boss(animation: String, frame: int) -> float:
	if not FRAME_CENTER_X_BOSS.has(animation):
		return 0.0
	var centers: Array = FRAME_CENTER_X_BOSS[animation]
	if centers.is_empty():
		return 0.0
	var index: int = clamp(frame, 0, centers.size() - 1)
	return (VISUAL_CENTER_X_BOSS - float(centers[index])) * WALK_ANCHOR_STRENGTH_BOSS * facing

func _update_patrol_boss_internal() -> void:
	is_chasing_boss = false
	var patrol_offset: float = global_position.x - spawn_position.x
	if patrol_offset >= patrol_distance:
		patrol_direction = -1.0
	elif patrol_offset <= -patrol_distance:
		patrol_direction = 1.0
	facing = patrol_direction
	velocity.x = patrol_direction * patrol_speed
	play_boss_animation("walk")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _should_chase_player_boss_internal() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 72.0:
		return false
	var distance: float = abs(offset.x)
	if distance > leash_range_boss:
		return false
	return distance <= detection_range_boss and distance > attack_start_distance_boss

func _should_hold_player_boss_internal() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 72.0:
		return false
	var distance: float = abs(offset.x)
	return distance <= detection_range_boss and distance <= attack_start_distance_boss

func _update_engaged_hold_boss_internal() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_update_patrol_boss_internal()
		return
	var offset_x: float = player.global_position.x - global_position.x
	is_chasing_boss = false
	if absf(offset_x) > 8.0:
		facing = sign(offset_x)
	var distance := absf(offset_x)
	if distance < close_spacing_distance_boss:
		velocity.x = -facing * spacing_retreat_speed_boss
		play_boss_animation("walk")
	else:
		velocity.x = 0.0
		play_boss_animation("idle")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _update_chase_boss_internal() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_update_patrol_boss_internal()
		return
	var offset_x: float = player.global_position.x - global_position.x
	if absf(offset_x) <= 8.0:
		velocity.x = 0.0
		return
	is_chasing_boss = true
	facing = sign(offset_x)
	velocity.x = facing * chase_speed
	play_boss_animation("walk")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _should_start_attack_boss_internal() -> bool:
	if attack_cooldown > 0.0:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 56.0:
		return false
	if abs(offset.x) > detection_range_boss:
		return false
	if absf(offset.x) > 8.0:
		facing = sign(offset.x)
	var distance := absf(offset.x)
	if _can_start_chop_gap_close_from_distance_boss_internal(distance):
		return true
	var max_start_distance := 112.0 if not forced_counter_profile_boss.is_empty() else attack_start_distance_boss
	return distance >= close_spacing_distance_boss and distance <= max_start_distance

func _can_start_chop_gap_close_from_distance_boss_internal(distance: float) -> bool:
	if distance < chop_gap_close_min_distance_boss or distance > chop_gap_close_max_distance_boss:
		return false
	if debug_fixed_attack_profile_boss == "chop" or forced_counter_profile_boss == "chop":
		return true
	if guard_pressure_count_boss >= guard_pressure_chop_threshold_boss:
		return true
	if distance < chop_gap_close_commit_min_distance_boss:
		return false
	return _should_use_chop_gap_close_boss_internal()

func _should_use_chop_gap_close_boss_internal() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 56.0:
		return false
	var distance := absf(offset.x)
	if distance < chop_gap_close_commit_min_distance_boss or distance > chop_gap_close_max_distance_boss:
		return false
	return true

func _update_attack_pressure_boss_internal(delta: float) -> bool:
	if attack_pressure_timer_boss > 0.0:
		attack_pressure_timer_boss = max(0.0, attack_pressure_timer_boss - delta)
		velocity.x = 0.0
		_update_engaged_hold_boss_internal()
		if attack_pressure_timer_boss <= 0.0 and _should_start_attack_boss_internal():
			_start_normal_attack_boss_internal()
		return true
	if forced_counter_profile_boss.is_empty() and guard_pressure_count_boss < guard_pressure_chop_threshold_boss and _should_start_attack_boss_internal():
		attack_pressure_timer_boss = attack_pressure_commit_time_boss
		velocity.x = 0.0
		_update_engaged_hold_boss_internal()
		return true
	return false

func _should_start_gap_close_thrust_boss_internal() -> bool:
	if not has_engaged_player_boss:
		return false
	if attack_cooldown > 0.0:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 56.0:
		return false
	if abs(offset.x) > detection_range_boss:
		return false
	if absf(offset.x) > 8.0:
		facing = sign(offset.x)
	var distance := absf(offset.x)
	return distance >= gap_close_thrust_min_distance_boss and distance <= gap_close_thrust_max_distance_boss

func _apply_chop_lunge_boss_internal() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		velocity.x = facing * chop_lunge_speed_boss
		return
	var offset_x: float = player.global_position.x - global_position.x
	if absf(offset_x) > 8.0:
		facing = sign(offset_x)
	if absf(offset_x) > chop_lunge_stop_distance_boss:
		velocity.x = facing * chop_lunge_speed_boss
	else:
		velocity.x = 0.0

func _start_normal_attack_boss_internal(profile_name: String = "", combo_followup: bool = false) -> void:
	var selected_profile := _choose_attack_profile_boss() if profile_name.is_empty() else profile_name
	if profile_name == forced_counter_profile_boss:
		forced_counter_profile_boss = ""
		forced_counter_timer_boss = 0.0
	_apply_attack_profile_boss_internal(selected_profile)
	if current_attack_animation == "attack" or current_attack_animation == "chop":
		has_engaged_player_boss = true
	attack_chain_count_boss = attack_chain_count_boss + 1 if combo_followup else 1
	pending_combo_followup_boss = false
	is_attack_winding_up_boss = true
	is_attack_active_boss = false
	is_attack_recovering_boss = false
	is_chop_parried_recovery_boss = false
	attack_has_connected = false
	attack_elapsed = 0.0
	attack_timer_boss = attack_animation_total_time_boss
	attack_step_timer_boss = 0.0 if current_attack_animation == "thrust" else attack_step_time_boss
	velocity.x = 0.0
	_update_attack_visual_boss_internal(true, false)
	play_boss_animation(current_attack_animation)
	_sync_attack_animation_frame_boss_internal()
	if sprite != null:
		sprite.speed_scale = 0.0
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _update_attack_state_boss_internal(delta: float) -> void:
	velocity.x = 0.0
	if is_chop_parried_recovery_boss:
		attack_elapsed += delta
		attack_timer_boss = max(0.0, attack_animation_total_time_boss - attack_elapsed)
		if current_animation_boss != current_attack_animation:
			play_boss_animation(current_attack_animation)
		_sync_attack_animation_frame_boss_internal()
		_update_attack_visual_boss_internal(false, false)
		if attack_elapsed >= attack_animation_total_time_boss:
			is_chop_parried_recovery_boss = false
			attack_chain_count_boss = 0
			attack_cooldown = perfect_parry_cooldown_boss
			play_boss_animation("walk")
		return

	if is_attack_winding_up_boss and attack_step_timer_boss > 0.0:
		attack_step_timer_boss = max(0.0, attack_step_timer_boss - delta)
		velocity.x = facing * (attack_step_distance_boss / max(attack_step_time_boss, 0.001))

	if is_attack_winding_up_boss:
		attack_elapsed += delta
		attack_timer_boss = max(0.0, attack_animation_total_time_boss - attack_elapsed)
		if current_animation_boss != current_attack_animation:
			play_boss_animation(current_attack_animation)
		_sync_attack_animation_frame_boss_internal()
		is_attack_active_boss = attack_elapsed >= attack_hit_time_boss and attack_elapsed <= attack_hit_window_end_boss
		if current_attack_animation == "thrust" and attack_elapsed >= thrust_lunge_start_boss and attack_elapsed <= thrust_lunge_end_boss:
			velocity.x = facing * thrust_lunge_speed_boss
		elif current_attack_animation == "chop" and attack_elapsed >= chop_lunge_start_boss and attack_elapsed <= chop_lunge_end_boss:
			_apply_chop_lunge_boss_internal()
		_update_attack_visual_boss_internal(true, is_attack_active_boss)
		if is_attack_active_boss:
			_connect_normal_attack_boss_internal()
			if feedback_timer_boss > 0.0:
				return
		if attack_elapsed >= attack_animation_total_time_boss:
			is_attack_winding_up_boss = false
			is_attack_active_boss = false
			is_attack_recovering_boss = true
			pending_combo_followup_boss = _should_queue_combo_followup_boss_internal()
			attack_timer_boss = combo_link_delay_boss if pending_combo_followup_boss else attack_recovery_time_boss
	elif is_attack_active_boss and attack_timer_boss <= 0.0:
		is_attack_active_boss = false
		is_attack_recovering_boss = true
		attack_timer_boss = attack_recovery_time_boss
	elif is_attack_recovering_boss:
		attack_timer_boss -= delta
		if attack_timer_boss <= 0.0:
			if pending_combo_followup_boss:
				_start_normal_attack_boss_internal("attack", true)
				return
			is_attack_recovering_boss = false
			attack_chain_count_boss = 0
			attack_cooldown = attack_cooldown_duration
			_update_attack_visual_boss_internal(false, false)
			play_boss_animation("walk")

func _should_queue_combo_followup_boss_internal() -> bool:
	if current_attack_animation != "attack":
		return false
	if attack_chain_count_boss >= combo_max_count_boss:
		return false
	if not _is_player_in_combo_range_boss_internal():
		return false
	return true

func _is_player_in_combo_range_boss_internal() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > combo_vertical_tolerance_boss:
		return false
	var distance := absf(offset.x)
	return distance >= close_spacing_distance_boss and distance <= attack_start_distance_boss

func _sync_attack_animation_frame_boss_internal() -> void:
	if sprite == null or current_animation_boss != current_attack_animation:
		return
	var elapsed: float = clamp(attack_elapsed, 0.0, max(attack_animation_total_time_boss - 0.001, 0.0))
	var cursor := 0.0
	for index in attack_frame_durations_boss.size():
		cursor += float(attack_frame_durations_boss[index])
		if elapsed < cursor:
			sprite.frame = index
			align_sprite_to_ground_boss()
			return
	sprite.frame = max(0, attack_frame_durations_boss.size() - 1)
	align_sprite_to_ground_boss()

func is_attack_parry_window_open() -> bool:
	return is_attack_winding_up_boss and attack_elapsed >= attack_parry_window_start_boss and attack_elapsed <= attack_hit_window_end_boss

func can_be_perfect_parried_by(player: Node) -> bool:
	if not is_attack_parry_window_open():
		return false
	if player != null and "parry_elapsed" in player:
		return float(player.parry_elapsed) <= perfect_parry_input_leeway
	return true

func _connect_normal_attack_boss_internal() -> void:
	if attack_has_connected:
		return
	if attack_area == null:
		return
	for body in attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("receive_enemy_attack"):
			attack_has_connected = true
			body.receive_enemy_attack(attack_damage, attack_posture_damage, self, current_attack_type)
			if feedback_timer_boss > 0.0:
				return
			_begin_local_hitstop(raw_hitstop_time_boss)
			if body.has_method("begin_local_hitstop"):
				body.begin_local_hitstop(raw_hitstop_time_boss)
			return

func _update_attack_visual_boss_internal(show_visual: bool, active: bool) -> void:
	if attack_visual == null:
		return
	_update_attack_hitbox_boss_internal()
	var effective_show := show_visual and GameSettings.is_easy_mode
	attack_visual.visible = effective_show and (active or is_attack_parry_window_open())
	_update_perilous_warning_boss_internal(effective_show and is_attack_parry_window_open())
	if not effective_show:
		return
	var rect_shape := attack_collision_shape.shape as RectangleShape2D if attack_collision_shape != null else null
	if rect_shape != null and attack_area != null:
		var half_size: Vector2 = rect_shape.size * 0.5
		attack_visual.position = attack_area.position - half_size
		attack_visual.size = rect_shape.size
	if is_current_attack_perilous():
		attack_visual.color = Color(1.0, 0.08, 0.05, 0.68) if active else Color(1.0, 0.12, 0.05, 0.50)
	else:
		attack_visual.color = Color(1.0, 0.22, 0.08, 0.62) if active else Color(1.0, 0.86, 0.08, 0.48)


func _update_perilous_warning_boss_internal(show_warning: bool) -> void:
	var show := show_warning and is_current_attack_perilous()
	if perilous_label_node != null:
		perilous_label_node.visible = show
	if debug_response_label_node != null:
		debug_response_label_node.visible = false

func _update_attack_hitbox_boss_internal() -> void:
	if attack_area == null or attack_collision_shape == null:
		return
	var rect_shape := attack_collision_shape.shape as RectangleShape2D
	if current_attack_animation == "thrust":
		attack_area.position = Vector2(76.0 * facing, -36.0)
		attack_area_base_position = Vector2(76.0, -36.0)
		if rect_shape != null:
			rect_shape.size = Vector2(148.0, 54.0)
	elif rect_shape != null:
		attack_area.position = Vector2(20.0 * facing, -36.0)
		attack_area_base_position = Vector2(20.0, -36.0)
		rect_shape.size = Vector2(90.0, 80.0)

func _interrupt_attack_boss_internal() -> void:
	is_attack_winding_up_boss = false
	is_attack_active_boss = false
	is_attack_recovering_boss = false
	is_chop_parried_recovery_boss = false
	attack_has_connected = false
	attack_chain_count_boss = 0
	pending_combo_followup_boss = false
	attack_timer_boss = 0.0
	attack_elapsed = 0.0
	attack_step_timer_boss = 0.0
	attack_cooldown = attack_cooldown_duration
	_update_attack_visual_boss_internal(false, false)
	if debug_response_label_node != null:
		debug_response_label_node.visible = false
	if perilous_label_node != null:
		perilous_label_node.visible = false

func _queue_forced_counter_boss() -> void:
	consecutive_guard_count_boss += 1
	if consecutive_guard_count_boss >= 3:
		forced_counter_profile_boss = "thrust"
	elif consecutive_guard_count_boss >= 2:
		forced_counter_profile_boss = "chop"
	else:
		forced_counter_profile_boss = "attack"
	forced_counter_timer_boss = forced_counter_deflect_window_boss

func _is_forced_counter_protected_boss() -> bool:
	if not forced_counter_profile_boss.is_empty() and forced_counter_timer_boss > 0.0:
		return true
	return is_attack_winding_up_boss and current_attack_animation in ["attack", "chop", "thrust"]

func _can_chain_deflect_during_feedback_boss() -> bool:
	return not forced_counter_profile_boss.is_empty() and not is_attack_winding_up_boss and not is_attack_active_boss

func _start_chop_parried_recovery_boss_internal() -> void:
	guard_pressure_count_boss = 0
	is_attack_winding_up_boss = false
	is_attack_active_boss = false
	is_attack_recovering_boss = false
	is_chop_parried_recovery_boss = true
	attack_has_connected = true
	pending_combo_followup_boss = false
	attack_chain_count_boss = 0
	_apply_attack_profile_boss_internal("chop")
	attack_elapsed = _chop_recovery_start_time_boss_internal()
	attack_timer_boss = max(0.0, attack_animation_total_time_boss - attack_elapsed)
	attack_step_timer_boss = 0.0
	play_boss_animation("chop")
	_sync_attack_animation_frame_boss_internal()
	_update_attack_visual_boss_internal(false, false)
	_begin_local_hitstop(chop_parry_hitstop_time_boss)
	stored_velocity_boss = Vector2(-facing * chop_parry_boss_rebound_speed_boss, velocity.y)
	hit_recoil_timer = max(hit_recoil_timer, chop_parry_hitstop_time_boss + chop_parry_recoil_time_boss)
	hit_spark_timer = max(hit_spark_timer, hit_spark_time_boss)
	hit_flash_timer = max(hit_flash_timer, hit_flash_time_boss)
	if hit_spark != null:
		hit_spark.visible = false
	_shake_camera_boss_internal(chop_parry_camera_shake_boss, chop_parry_hitstop_time_boss)

func _chop_recovery_start_time_boss_internal() -> float:
	var profile: Dictionary = ATTACK_PROFILES_BOSS["chop"]
	var durations: Array = profile["durations"]
	var total := 0.0
	for index in range(min(7, durations.size())):
		total += float(durations[index])
	return min(total + 0.001, attack_animation_total_time_boss)

func _begin_local_hitstop(duration: float) -> void:
	hitstop_timer_boss = max(hitstop_timer_boss, duration)
	stored_velocity_boss = velocity
	velocity = Vector2.ZERO
	if sprite != null:
		sprite.speed_scale = 0.0

func _trigger_hit_feedback_boss_internal() -> void:
	hit_spark_timer = hit_spark_time_boss
	hit_recoil_timer = hit_recoil_time_boss
	hit_flash_timer = hit_flash_time_boss
	_start_hit_flicker(hurt_feedback_time_boss)
	var recoil_velocity := Vector2(-facing * hit_recoil_force, velocity.y)
	velocity = recoil_velocity
	if hit_spark != null:
		hit_spark.visible = false
	_begin_local_hitstop(hit_freeze_time_boss)
	stored_velocity_boss = recoil_velocity
	velocity = recoil_velocity
	_shake_camera_boss_internal(9.0, 0.08)
	_play_sfx_boss_internal(enemy_hurt_sfx_node)
	_update_hit_feedback_boss_internal(0.0)

func _update_hit_feedback_boss_internal(delta: float) -> void:
	hit_spark_timer = max(0.0, hit_spark_timer - delta)
	hit_recoil_timer = max(0.0, hit_recoil_timer - delta)
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	_update_hit_flicker(delta)
	if hit_spark != null:
		hit_spark.visible = false
	if sprite != null:
		sprite.modulate = _hit_feedback_modulate(Color(1.75, 1.75, 1.28, 1.0))

func _update_visuals_boss_internal() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	_sync_directional_nodes()
	sprite.flip_h = facing < 0.0
	var next_animation := "idle"
	if defeated_flag:
		next_animation = "death"
	elif feedback_timer_boss > 0.0:
		next_animation = "hurt"
	elif is_attack_winding_up_boss or is_attack_active_boss or is_attack_recovering_boss or is_chop_parried_recovery_boss:
		next_animation = current_attack_animation
	elif abs(velocity.x) > 1.0:
		next_animation = "walk"
	if sprite.sprite_frames.has_animation(next_animation) and sprite.animation != next_animation:
		sprite.play(next_animation)

func _load_optional_sfx_boss() -> void:
	if enemy_hurt_sfx_node != null:
		for path in BOSS_HURT_SFX_PATHS:
			if ResourceLoader.exists(path):
				enemy_hurt_sfx_node.stream = load(path)
				break

func _shake_camera_boss_internal(amount: float, duration: float) -> void:
	var camera := get_tree().get_first_node_in_group("feedback_camera")
	if camera != null and camera.has_method("shake"):
		camera.shake(amount, duration)

func _play_sfx_boss_internal(player: AudioStreamPlayer2D) -> void:
	if player != null and player.stream != null:
		player.play()

func _create_perilous_label() -> Label:
	var label := Label.new()
	label.text = "危"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.visible = false
	label.modulate = Color.RED
	label.z_index = 10
	label.set("theme_override_colors/font_outline_color", Color.BLACK)
	label.set("theme_override_constants/outline_size", 10)
	label.set("theme_override_font_sizes/font_size", 42)
	add_child(label)
	label.position = Vector2(-25, -130)
	return label

func _spawn_damage_number_boss(damage: float) -> void:
	if damage <= 0.0:
		return
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	var parent := get_parent()
	if parent == null:
		parent = get_tree().root
	parent.add_child(number)
	number.global_position = global_position + Vector2(0.0, -88.0)
	if number.has_method("setup"):
		number.setup(damage)

func _defeat() -> void:
	super()
	defeated_flag = true
	health = 0.0
	posture = max_posture
	_disable_boss_collision()
	if execute_label != null:
		execute_label.visible = false
	if debug_response_label_node != null:
		debug_response_label_node.visible = false
	if perilous_label_node != null:
		perilous_label_node.visible = false
	if hit_spark != null:
		hit_spark.visible = false
	if sprite != null:
		sprite.modulate = Color.WHITE
	play_boss_animation("death")
	defeated.emit()
