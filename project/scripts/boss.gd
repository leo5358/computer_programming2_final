extends CharacterBody2D

signal stats_changed
signal defeated

const CombatServerScript = preload("res://scripts/combat_server.gd")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/DamageNumber.tscn")
const BOSS_HURT_SFX_PATHS := [
	"res://assets/sfx/enemy_hurt.wav",
	"res://assets/sfx/player_hurt.wav",
]
const WALK_PATH := "res://assets/sprites/boss/walk.png"
const ATTACK_PATH := "res://assets/sprites/boss/attack.png"
const CHOP_PATH := "res://assets/sprites/boss/chop.png"
const THRUST_PATH := "res://assets/sprites/boss/thrust.png"
const THRUST_COPY_PATH := "res://assets/sprites/boss/thrust copy.png"
const DEFLECT1_PATH := "res://assets/sprites/boss/deflect1.png"
const DEFLECT2_PATH := "res://assets/sprites/boss/deflect2.png"
const HURT_PATH := "res://assets/sprites/boss/hurt.png"
const DEATH_PATH := "res://assets/sprites/boss/death.png"
const JUMP_PATH := "res://assets/sprites/boss/jump.png"
const ANIMATION_SPEEDS := {
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
const ATTACK_PROFILES := {
	"attack": {
		"durations": [0.12, 0.15, 0.30, 0.08, 0.06, 0.10, 0.14, 0.16],
		"cue_start": 0.62,
		"hit_start": 0.78,
		"hit_end": 0.88,
		"damage": 18.0,
		"posture_damage": 28.0,
		"attack_type": CombatServerScript.AttackType.NORMAL,
		"perilous": false,
	},
	"chop": {
		"durations": [0.16, 0.24, 0.42, 0.06, 0.045, 0.12, 0.20],
		"cue_start": 0.70,
		"hit_start": 0.82,
		"hit_end": 0.93,
		"damage": 28.0,
		"posture_damage": 42.0,
		"attack_type": CombatServerScript.AttackType.NORMAL,
		"perilous": false,
	},
	"thrust": {
		"durations": [0.12, 0.16, 0.26, 0.04, 0.04, 0.07, 0.10, 0.14],
		"cue_start": 0.42,
		"hit_start": 0.54,
		"hit_end": 0.65,
		"damage": 24.0,
		"posture_damage": 36.0,
		"attack_type": CombatServerScript.AttackType.THRUST,
		"perilous": true,
	},
}
const ATTACK_PROFILE_SEQUENCE := ["attack", "attack", "chop", "attack", "thrust"]
const LOOPING_ANIMATIONS := {
	"idle": true,
	"walk": true,
}
const ANIMATION_FRAME_SPECS := {
	"idle": [
		[WALK_PATH, 0, 0, 125, 128],
		[WALK_PATH, 125, 0, 125, 128],
		[WALK_PATH, 250, 0, 125, 128],
		[WALK_PATH, 375, 0, 125, 128],
		[WALK_PATH, 500, 0, 125, 128],
		[WALK_PATH, 750, 0, 125, 128],
		[WALK_PATH, 875, 0, 125, 128],
		[WALK_PATH, 625, 0, 125, 128],
	],
	"walk": [
		[WALK_PATH, 0, 0, 125, 128],
		[WALK_PATH, 125, 0, 125, 128],
		[WALK_PATH, 250, 0, 125, 128],
		[WALK_PATH, 375, 0, 125, 128],
		[WALK_PATH, 500, 0, 125, 128],
		[WALK_PATH, 750, 0, 125, 128],
		[WALK_PATH, 875, 0, 125, 128],
		[WALK_PATH, 625, 0, 125, 128],
	],
	"attack": [
		[ATTACK_PATH, 0, 0, 125, 128],
		[ATTACK_PATH, 125, 0, 125, 128],
		[ATTACK_PATH, 248, 0, 124, 128],
		[ATTACK_PATH, 384, 0, 128, 128],
		[ATTACK_PATH, 532, 0, 133, 128],
		[ATTACK_PATH, 665, 0, 133, 128],
		[ATTACK_PATH, 792, 0, 128, 128],
		[ATTACK_PATH, 2, 0, 125, 128],
	],
	"attack2": [
		[ATTACK_PATH, 0, 0, 125, 128],
		[ATTACK_PATH, 125, 0, 125, 128],
		[ATTACK_PATH, 248, 0, 124, 128],
		[ATTACK_PATH, 532, 0, 133, 128],
		[ATTACK_PATH, 665, 0, 133, 128],
		[ATTACK_PATH, 248, 0, 124, 128],
		[ATTACK_PATH, 532, 0, 133, 128],
		[ATTACK_PATH, 665, 0, 133, 128],
		[ATTACK_PATH, 248, 0, 124, 128],
		[ATTACK_PATH, 532, 0, 133, 128],
		[ATTACK_PATH, 665, 0, 133, 128],
		[ATTACK_PATH, 248, 0, 124, 128],
		[ATTACK_PATH, 532, 0, 133, 128],
		[ATTACK_PATH, 665, 0, 133, 128],
		[ATTACK_PATH, 792, 0, 128, 128],
		[ATTACK_PATH, 2, 0, 125, 128],
	],
	"chop": [
		[CHOP_PATH, 8, 0, 127, 128],
		[CHOP_PATH, 135, 0, 127, 128],
		[CHOP_PATH, 262, 0, 127, 128],
		[CHOP_PATH, 408, 0, 127, 128],
		[CHOP_PATH, 535, 0, 127, 128],
		[CHOP_PATH, 687, 0, 132, 128],
		[CHOP_PATH, 811, 0, 129, 128],
	],
	"thrust": [
		[THRUST_PATH, 0, 0, 128, 128],
		[THRUST_PATH, 136, 0, 127, 128],
		[THRUST_PATH, 259, 0, 126, 128],
		[THRUST_PATH, 387, 0, 129, 128],
		[THRUST_COPY_PATH, 0, 0, 144, 128],
		[THRUST_COPY_PATH, 144, 0, 144, 128],
		[THRUST_PATH, 136, 0, 127, 128],
		[THRUST_PATH, 0, 0, 128, 128],
	],
	"deflect1": [
		[DEFLECT1_PATH, 0, 0, 128, 128],
		[DEFLECT1_PATH, 128, 0, 128, 128],
		[DEFLECT1_PATH, 256, 0, 128, 128],
		[DEFLECT1_PATH, 384, 0, 128, 128],
		[DEFLECT1_PATH, 512, 0, 128, 128],
		[DEFLECT1_PATH, 650, 0, 128, 128],
		[DEFLECT1_PATH, 778, 0, 128, 128],
		[DEFLECT1_PATH, 893, 0, 127, 128],
	],
	"deflect2": [
		[DEFLECT2_PATH, 8, 0, 127, 128],
		[DEFLECT2_PATH, 128, 0, 128, 128],
		[DEFLECT2_PATH, 256, 0, 128, 128],
		[DEFLECT2_PATH, 384, 0, 128, 128],
		[DEFLECT2_PATH, 512, 0, 128, 128],
		[DEFLECT2_PATH, 776, 0, 127, 128],
		[DEFLECT2_PATH, 772, 0, 126, 128],
		[DEFLECT2_PATH, 8, 0, 127, 128],
	],
	"death": [
		[DEATH_PATH, 10, 0, 126, 128],
		[DEATH_PATH, 136, 0, 126, 128],
		[DEATH_PATH, 262, 0, 126, 128],
		[DEATH_PATH, 379, 0, 123, 128],
		[DEATH_PATH, 502, 0, 123, 128],
		[DEATH_PATH, 625, 0, 123, 128],
		[DEATH_PATH, 748, 0, 123, 128],
		[DEATH_PATH, 871, 0, 123, 128],
	],
	"jump": [
		[JUMP_PATH, 10, 0, 123, 128],
		[JUMP_PATH, 133, 0, 123, 128],
		[JUMP_PATH, 256, 0, 123, 128],
		[JUMP_PATH, 257, 0, 126, 128],
		[JUMP_PATH, 383, 0, 126, 128],
		[JUMP_PATH, 509, 0, 126, 128],
		[JUMP_PATH, 766, 0, 126, 128],
		[JUMP_PATH, 892, 0, 126, 128],
	],
	"hurt": [
		[HURT_PATH, 0, 0, 128, 128],
		[HURT_PATH, 128, 0, 128, 128],
		[HURT_PATH, 256, 0, 128, 128],
		[HURT_PATH, 384, 0, 128, 128],
		[HURT_PATH, 512, 0, 128, 128],
		[HURT_PATH, 640, 0, 128, 128],
		[HURT_PATH, 768, 0, 128, 128],
		[HURT_PATH, 896, 0, 128, 128],
	],
}
const FRAME_BOTTOM_GAPS := {
	"idle": [6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0],
	"walk": [6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0],
	"attack2": [8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0],
	"attack": [8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0],
	"thrust": [7.0, 9.0, 10.0, 10.0, 10.0, 10.0, 10.0, 7.0],
	"chop": [5.0, 7.0, 18.0, 22.0, 23.0, 7.0, 7.0],
	"deflect1": [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0],
	"deflect2": [7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0],
	"hurt": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	"death": [10.0, 10.0, 10.0, 10.0, 9.0, 5.0, 5.0, 5.0],
	"jump": [6.0, 6.0, 7.0, 19.0, 26.0, 21.0, 7.0, 6.0],
}
const FRAME_CENTER_X := {
	"idle": [74.0, 67.0, 64.5, 61.0, 55.5, 50.5, 44.0, 45.0],
	"walk": [74.0, 67.0, 64.5, 61.0, 55.5, 50.5, 44.0, 45.0],
}
const VISUAL_CENTER_X := 64.0
const WALK_ANCHOR_STRENGTH := 0.45

@export var max_health := 140.0
@export var max_posture := 100.0
@export var posture_damage_taken := 18.0
@export var patrol_speed := 58.0
@export var patrol_distance := 120.0
@export var chase_speed := 86.0
@export var leash_range := 420.0
@export var detection_range := 280.0
@export var attack_range := 142.0
@export var attack_start_distance := 112.0
@export var attack_hold_distance := 78.0
@export var close_spacing_distance := 58.0
@export var spacing_retreat_speed := 72.0
@export var gap_close_thrust_min_distance := 130.0
@export var gap_close_thrust_max_distance := 190.0
@export var attack_step_distance := 36.0
@export var attack_step_time := 0.16
@export var attack_damage := 18.0
@export var attack_posture_damage := 28.0
@export var attack_cooldown_duration := 1.38
@export var combo_link_delay := 0.22
@export var combo_max_count := 2
@export var perfect_parry_cooldown := 1.05
@export var guard_pressure_chop_threshold := 2
@export var attack_windup_time := 0.92
@export var attack_active_time := 0.22
@export var attack_recovery_time := 0.58
@export var attack_hit_frame := 4
@export var attack_frame_durations: Array[float] = [0.12, 0.15, 0.30, 0.08, 0.06, 0.10, 0.14, 0.16]
@export var attack_parry_window_start := 0.62
@export var attack_hit_time := 0.78
@export var attack_hit_window_end := 0.88
@export var perfect_parry_input_leeway := 0.16
@export var raw_hitstop_time := 0.07
@export var parry_clash_hitstop_time := 0.105
@export var hit_recoil_time := 0.12
@export var hit_recoil_force := 130.0
@export var hit_flash_time := 0.10
@export var hit_spark_time := 0.16
@export var hit_freeze_time := 0.055
@export var normal_attack_parry_posture_damage := 36.0
@export var normal_attack_block_posture_damage := 14.0
@export var deflect_feedback_time := 0.28
@export var perfect_deflect_feedback_time := 0.50
@export_range(0.0, 1.0, 0.05) var guard_chance := 0.8
@export var guard_posture_damage := 6.0
@export var guard_lockout_duration := 0.32
@export var minimum_health_from_player_attack := 1.0

var health := max_health
var posture := 0.0
var defeated_flag := false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation := "idle"
var facing := 1.0
var patrol_direction := 1.0
var spawn_position := Vector2.ZERO
var is_chasing := false
var attack_cooldown := 0.65
var is_attack_winding_up := false
var is_attack_active := false
var is_attack_recovering := false
var attack_has_connected := false
var attack_timer := 0.0
var attack_elapsed := 0.0
var attack_animation_total_time := 1.16
var attack_profile_cursor := 0
var attack_chain_count := 0
var pending_combo_followup := false
var guard_pressure_count := 0
var current_attack_animation := "attack"
var current_attack_type: int = CombatServerScript.AttackType.NORMAL
var attack_step_timer := 0.0
var hitstop_timer := 0.0
var stored_velocity := Vector2.ZERO
var hit_spark_timer := 0.0
var hit_recoil_timer := 0.0
var hit_flash_timer := 0.0
var feedback_timer := 0.0
var deflect_toggle := false
var guard_lockout_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_visual: ColorRect = get_node_or_null("Body") as ColorRect
@onready var execute_label: Label = get_node_or_null("ExecuteLabel") as Label
@onready var attack_visual: ColorRect = get_node_or_null("AttackVisual") as ColorRect
@onready var hit_spark: ColorRect = get_node_or_null("HitSpark") as ColorRect
@onready var enemy_hurt_sfx: AudioStreamPlayer2D = get_node_or_null("EnemyHurtSfx") as AudioStreamPlayer2D
@onready var debug_response_label: Label = get_node_or_null("DebugResponseLabel") as Label
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D
@onready var attack_collision_shape: CollisionShape2D = get_node_or_null("AttackArea/CollisionShape2D") as CollisionShape2D

func _ready() -> void:
	add_to_group("boss")
	spawn_position = global_position
	health = max_health
	posture = 0.0
	defeated_flag = false
	_setup_sprite_frames()
	if sprite != null:
		sprite.position = Vector2(0.0, -64.0)
		if not sprite.frame_changed.is_connected(align_sprite_to_ground):
			sprite.frame_changed.connect(align_sprite_to_ground)
	if body_visual != null:
		body_visual.visible = false
	if execute_label != null:
		execute_label.visible = false
	if attack_visual != null:
		attack_visual.visible = false
	_update_attack_hitbox()
	attack_animation_total_time = _attack_total_time()
	_load_optional_sfx()
	play_boss_animation("idle")
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	if feedback_timer > 0.0:
		feedback_timer = max(0.0, feedback_timer - delta)
	guard_lockout_timer = max(0.0, guard_lockout_timer - delta)
	_update_hit_feedback(delta)
	if hitstop_timer > 0.0:
		hitstop_timer = max(0.0, hitstop_timer - delta)
		if hitstop_timer <= 0.0 and sprite != null:
			sprite.speed_scale = 0.0 if current_animation == current_attack_animation else 1.0
		velocity = Vector2.ZERO
		align_sprite_to_ground()
		return
	if defeated_flag:
		velocity.x = 0.0
	elif feedback_timer > 0.0:
		velocity.x = 0.0
	elif hit_recoil_timer > 0.0:
		pass
	elif is_attack_winding_up or is_attack_active or is_attack_recovering:
		_update_attack_state(delta)
	else:
		attack_cooldown = max(0.0, attack_cooldown - delta)
		if _should_start_attack():
			_start_normal_attack()
		elif _should_start_gap_close_thrust():
			_start_normal_attack("thrust")
		elif _should_chase_player():
			_update_chase()
		elif _should_hold_player():
			_update_engaged_hold()
		else:
			_update_patrol()
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	align_sprite_to_ground()

func play_boss_animation(animation: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation):
		return
	current_animation = animation
	sprite.speed_scale = 1.0
	if sprite.animation != animation:
		sprite.play(animation)
	align_sprite_to_ground()

func _force_play_boss_animation(animation: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation):
		return
	current_animation = animation
	sprite.speed_scale = 1.0
	sprite.play(animation)
	sprite.frame = 0
	align_sprite_to_ground()

func align_sprite_to_ground() -> void:
	if sprite == null:
		return
	sprite.offset = Vector2(
		_horizontal_anchor_for_frame(current_animation, sprite.frame),
		_bottom_gap_for_frame(current_animation, sprite.frame)
	)

func receive_player_attack(damage: float, posture_damage: float) -> Variant:
	if defeated_flag:
		return false
	if _should_guard_player_attack():
		_guard_player_attack()
		return {"guarded": true}
	_spawn_damage_number(damage)
	health = max(minimum_health_from_player_attack, health - damage)
	posture = clamp(posture + max(posture_damage, posture_damage_taken), 0.0, max_posture)
	_force_play_boss_animation("hurt")
	_trigger_hit_feedback()
	stats_changed.emit()
	return true

func _should_guard_player_attack() -> bool:
	if guard_chance <= 0.0:
		return false
	if guard_lockout_timer > 0.0:
		return false
	if defeated_flag:
		return false
	if feedback_timer > 0.0:
		return false
	if is_attack_active:
		return false
	return randf() <= guard_chance

func _guard_player_attack() -> void:
	posture = clamp(posture + guard_posture_damage, 0.0, max_posture)
	_interrupt_attack()
	deflect_toggle = not deflect_toggle
	_force_play_boss_animation("deflect1" if deflect_toggle else "deflect2")
	feedback_timer = deflect_feedback_time
	guard_lockout_timer = guard_lockout_duration
	hit_spark_timer = hit_spark_time
	hit_recoil_timer = min(hit_recoil_time, 0.10)
	hit_flash_timer = 0.08
	velocity.x = -facing * hit_recoil_force * 0.45
	if hit_spark != null:
		hit_spark.position.x = 18.0 * facing
		hit_spark.visible = true
	stats_changed.emit()

func receive_block_feedback(_perfect: bool) -> void:
	if defeated_flag:
		return
	var perfect := _perfect
	posture = clamp(posture + (normal_attack_parry_posture_damage if perfect else normal_attack_block_posture_damage), 0.0, max_posture)
	_interrupt_attack()
	if perfect:
		guard_pressure_count = 0
		attack_cooldown = perfect_parry_cooldown
	else:
		guard_pressure_count += 1
	deflect_toggle = not deflect_toggle
	play_boss_animation("deflect1" if deflect_toggle else "deflect2")
	feedback_timer = perfect_deflect_feedback_time if perfect else deflect_feedback_time
	if perfect:
		_begin_local_hitstop(parry_clash_hitstop_time)
	stats_changed.emit()

func receive_dodge_feedback() -> void:
	pass

func can_be_perfect_dodged_by(_player: Node2D) -> bool:
	return false

func can_be_executed() -> bool:
	return posture >= max_posture and not defeated_flag

func execute() -> void:
	if can_be_executed():
		_defeat()

func reset_combat_state() -> void:
	health = max_health
	posture = 0.0
	defeated_flag = false
	velocity = Vector2.ZERO
	patrol_direction = 1.0
	facing = 1.0
	is_chasing = false
	attack_cooldown = 0.65
	is_attack_winding_up = false
	is_attack_active = false
	is_attack_recovering = false
	attack_has_connected = false
	attack_timer = 0.0
	attack_elapsed = 0.0
	attack_profile_cursor = 0
	attack_chain_count = 0
	pending_combo_followup = false
	guard_pressure_count = 0
	current_attack_animation = "attack"
	current_attack_type = CombatServerScript.AttackType.NORMAL
	_apply_attack_profile("attack")
	attack_step_timer = 0.0
	hitstop_timer = 0.0
	stored_velocity = Vector2.ZERO
	hit_spark_timer = 0.0
	hit_recoil_timer = 0.0
	hit_flash_timer = 0.0
	feedback_timer = 0.0
	guard_lockout_timer = 0.0
	global_position = spawn_position
	if execute_label != null:
		execute_label.visible = false
	if attack_visual != null:
		attack_visual.visible = false
	if hit_spark != null:
		hit_spark.visible = false
	if sprite != null:
		sprite.modulate = Color.WHITE
	if debug_response_label != null:
		debug_response_label.visible = false
	set_collision_layer_value(1, true)
	play_boss_animation("walk")
	stats_changed.emit()

func _setup_sprite_frames() -> void:
	if sprite == null:
		return
	var frames := SpriteFrames.new()
	for animation in ANIMATION_FRAME_SPECS.keys():
		_add_strip_animation(frames, String(animation))
	sprite.sprite_frames = frames

func _attack_total_time() -> float:
	var total := 0.0
	for duration in attack_frame_durations:
		total += float(duration)
	return total

func has_attack_profile(profile_name: String) -> bool:
	return ATTACK_PROFILES.has(profile_name)

func is_current_attack_perilous() -> bool:
	var profile: Dictionary = ATTACK_PROFILES.get(current_attack_animation, {})
	return bool(profile.get("perilous", false))

func _choose_attack_profile() -> String:
	if guard_pressure_count >= guard_pressure_chop_threshold:
		guard_pressure_count = 0
		return "chop"
	var profile_name := String(ATTACK_PROFILE_SEQUENCE[attack_profile_cursor % ATTACK_PROFILE_SEQUENCE.size()])
	attack_profile_cursor += 1
	return profile_name

func _apply_attack_profile(profile_name: String) -> void:
	if not ATTACK_PROFILES.has(profile_name):
		profile_name = "attack"
	var profile: Dictionary = ATTACK_PROFILES[profile_name]
	current_attack_animation = profile_name
	attack_frame_durations.clear()
	for duration in profile["durations"]:
		attack_frame_durations.append(float(duration))
	attack_parry_window_start = float(profile["cue_start"])
	attack_hit_time = float(profile["hit_start"])
	attack_hit_window_end = float(profile["hit_end"])
	attack_damage = float(profile["damage"])
	attack_posture_damage = float(profile["posture_damage"])
	current_attack_type = int(profile["attack_type"])
	attack_animation_total_time = _attack_total_time()

func _add_strip_animation(frames: SpriteFrames, animation: String) -> void:
	if not ANIMATION_FRAME_SPECS.has(animation):
		return
	var frame_specs: Array = ANIMATION_FRAME_SPECS[animation]
	frames.add_animation(animation)
	frames.set_animation_speed(animation, float(ANIMATION_SPEEDS.get(animation, 10.0)))
	frames.set_animation_loop(animation, bool(LOOPING_ANIMATIONS.get(animation, false)))
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

func _bottom_gap_for_frame(animation: String, frame: int) -> float:
	if not FRAME_BOTTOM_GAPS.has(animation):
		return 0.0
	var gaps: Array = FRAME_BOTTOM_GAPS[animation]
	if gaps.is_empty():
		return 0.0
	var index: int = clamp(frame, 0, gaps.size() - 1)
	return float(gaps[index])

func _horizontal_anchor_for_frame(animation: String, frame: int) -> float:
	if not FRAME_CENTER_X.has(animation):
		return 0.0
	var centers: Array = FRAME_CENTER_X[animation]
	if centers.is_empty():
		return 0.0
	var index: int = clamp(frame, 0, centers.size() - 1)
	return (VISUAL_CENTER_X - float(centers[index])) * WALK_ANCHOR_STRENGTH * facing

func _update_patrol() -> void:
	is_chasing = false
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

func _should_chase_player() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 72.0:
		return false
	var distance: float = abs(offset.x)
	if distance > leash_range:
		return false
	return distance <= detection_range and distance > attack_start_distance

func _should_hold_player() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 72.0:
		return false
	var distance: float = abs(offset.x)
	return distance <= detection_range and distance <= attack_start_distance

func _update_engaged_hold() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_update_patrol()
		return
	var offset_x: float = player.global_position.x - global_position.x
	is_chasing = false
	if absf(offset_x) > 8.0:
		facing = sign(offset_x)
	var distance := absf(offset_x)
	if distance < close_spacing_distance:
		velocity.x = -facing * spacing_retreat_speed
		play_boss_animation("walk")
	else:
		velocity.x = 0.0
		play_boss_animation("idle")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _update_chase() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_update_patrol()
		return
	var offset_x: float = player.global_position.x - global_position.x
	if absf(offset_x) <= 8.0:
		velocity.x = 0.0
		return
	is_chasing = true
	facing = sign(offset_x)
	velocity.x = facing * chase_speed
	play_boss_animation("walk")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _should_start_attack() -> bool:
	if attack_cooldown > 0.0:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 56.0:
		return false
	if abs(offset.x) > detection_range:
		return false
	if absf(offset.x) > 8.0:
		facing = sign(offset.x)
	var distance := absf(offset.x)
	return distance >= close_spacing_distance and distance <= attack_start_distance

func _should_start_gap_close_thrust() -> bool:
	if attack_cooldown > 0.0:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 56.0:
		return false
	if abs(offset.x) > detection_range:
		return false
	if absf(offset.x) > 8.0:
		facing = sign(offset.x)
	var distance := absf(offset.x)
	return distance >= gap_close_thrust_min_distance and distance <= gap_close_thrust_max_distance

func _start_normal_attack(profile_name: String = "", combo_followup: bool = false) -> void:
	_apply_attack_profile(_choose_attack_profile() if profile_name.is_empty() else profile_name)
	attack_chain_count = attack_chain_count + 1 if combo_followup else 1
	pending_combo_followup = false
	is_attack_winding_up = true
	is_attack_active = false
	is_attack_recovering = false
	attack_has_connected = false
	attack_elapsed = 0.0
	attack_timer = attack_animation_total_time
	attack_step_timer = attack_step_time
	velocity.x = 0.0
	_update_attack_visual(true, false)
	play_boss_animation(current_attack_animation)
	_sync_attack_animation_frame()
	if sprite != null:
		sprite.speed_scale = 0.0
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _update_attack_state(delta: float) -> void:
	velocity.x = 0.0
	if is_attack_winding_up and attack_step_timer > 0.0:
		attack_step_timer = max(0.0, attack_step_timer - delta)
		velocity.x = facing * (attack_step_distance / max(attack_step_time, 0.001))

	if is_attack_winding_up:
		attack_elapsed += delta
		attack_timer = max(0.0, attack_animation_total_time - attack_elapsed)
		if current_animation != current_attack_animation:
			play_boss_animation(current_attack_animation)
		_sync_attack_animation_frame()
		is_attack_active = attack_elapsed >= attack_hit_time and attack_elapsed <= attack_hit_window_end
		_update_attack_visual(true, is_attack_active)
		if is_attack_active:
			_connect_normal_attack()
			if feedback_timer > 0.0:
				return
		if attack_elapsed >= attack_animation_total_time:
			is_attack_winding_up = false
			is_attack_active = false
			is_attack_recovering = true
			pending_combo_followup = _should_queue_combo_followup()
			attack_timer = combo_link_delay if pending_combo_followup else attack_recovery_time
	elif is_attack_active and attack_timer <= 0.0:
		is_attack_active = false
		is_attack_recovering = true
		attack_timer = attack_recovery_time
	elif is_attack_recovering:
		attack_timer -= delta
		if attack_timer <= 0.0:
			if pending_combo_followup:
				_start_normal_attack("attack", true)
				return
			is_attack_recovering = false
			attack_chain_count = 0
			attack_cooldown = attack_cooldown_duration
			_update_attack_visual(false, false)
			play_boss_animation("walk")

func _should_queue_combo_followup() -> bool:
	if current_attack_animation != "attack":
		return false
	if attack_chain_count >= combo_max_count:
		return false
	if not _is_player_in_combo_range():
		return false
	return true

func _is_player_in_combo_range() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.y) > 56.0:
		return false
	var distance := absf(offset.x)
	return distance >= close_spacing_distance and distance <= attack_start_distance

func _sync_attack_animation_frame() -> void:
	if sprite == null or current_animation != current_attack_animation:
		return
	var elapsed: float = clamp(attack_elapsed, 0.0, max(attack_animation_total_time - 0.001, 0.0))
	var cursor := 0.0
	for index in attack_frame_durations.size():
		cursor += float(attack_frame_durations[index])
		if elapsed < cursor:
			sprite.frame = index
			align_sprite_to_ground()
			return
	sprite.frame = max(0, attack_frame_durations.size() - 1)
	align_sprite_to_ground()

func is_attack_parry_window_open() -> bool:
	return is_attack_winding_up and attack_elapsed >= attack_parry_window_start and attack_elapsed <= attack_hit_window_end

func can_be_perfect_parried_by(player: Node) -> bool:
	if not is_attack_parry_window_open():
		return false
	if player != null and "parry_elapsed" in player:
		return float(player.parry_elapsed) <= perfect_parry_input_leeway
	return true

func _connect_normal_attack() -> void:
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
			if feedback_timer > 0.0:
				return
			_begin_local_hitstop(raw_hitstop_time)
			if body.has_method("begin_local_hitstop"):
				body.begin_local_hitstop(raw_hitstop_time)
			return

func _update_attack_visual(show_visual: bool, active: bool) -> void:
	if attack_visual == null:
		return
	_update_attack_hitbox()
	attack_visual.visible = show_visual and (active or is_attack_parry_window_open())
	_update_perilous_warning(show_visual and is_attack_parry_window_open())
	if not show_visual:
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

func _update_perilous_warning(show_warning: bool) -> void:
	if debug_response_label == null:
		return
	debug_response_label.visible = show_warning and is_current_attack_perilous()
	if debug_response_label.visible:
		debug_response_label.text = "危"
		debug_response_label.modulate = Color(1.0, 0.08, 0.04, 1.0)

func _update_attack_hitbox() -> void:
	if attack_area == null or attack_collision_shape == null:
		return
	attack_area.position = Vector2(20.0 * facing, -36.0)
	var rect_shape := attack_collision_shape.shape as RectangleShape2D
	if rect_shape != null:
		rect_shape.size = Vector2(90.0, 80.0)

func _interrupt_attack() -> void:
	is_attack_winding_up = false
	is_attack_active = false
	is_attack_recovering = false
	attack_has_connected = false
	attack_chain_count = 0
	pending_combo_followup = false
	attack_timer = 0.0
	attack_elapsed = 0.0
	attack_step_timer = 0.0
	attack_cooldown = attack_cooldown_duration
	_update_attack_visual(false, false)
	if debug_response_label != null:
		debug_response_label.visible = false

func _begin_local_hitstop(duration: float) -> void:
	hitstop_timer = max(hitstop_timer, duration)
	stored_velocity = velocity
	velocity = Vector2.ZERO
	if sprite != null:
		sprite.speed_scale = 0.0

func _trigger_hit_feedback() -> void:
	hit_spark_timer = hit_spark_time
	hit_recoil_timer = hit_recoil_time
	hit_flash_timer = hit_flash_time
	var recoil_velocity := Vector2(-facing * hit_recoil_force, velocity.y)
	velocity = recoil_velocity
	if hit_spark != null:
		hit_spark.position.x = 18.0 * facing
		hit_spark.visible = true
	_begin_local_hitstop(hit_freeze_time)
	stored_velocity = recoil_velocity
	velocity = recoil_velocity
	_shake_camera(9.0, 0.08)
	_play_sfx(enemy_hurt_sfx)
	_update_hit_feedback(0.0)

func _update_hit_feedback(delta: float) -> void:
	hit_spark_timer = max(0.0, hit_spark_timer - delta)
	hit_recoil_timer = max(0.0, hit_recoil_timer - delta)
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	if hit_spark != null:
		hit_spark.visible = hit_spark_timer > 0.0
	if sprite != null:
		sprite.modulate = Color(1.75, 1.75, 1.28, 1.0) if hit_flash_timer > 0.0 else Color.WHITE

func _spawn_damage_number(damage: float) -> void:
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

func _shake_camera(amount: float, duration: float) -> void:
	var camera := get_tree().get_first_node_in_group("feedback_camera")
	if camera != null and camera.has_method("shake"):
		camera.shake(amount, duration)

func _play_sfx(player: AudioStreamPlayer2D) -> void:
	if player != null and player.stream != null:
		player.play()

func _load_optional_sfx() -> void:
	if enemy_hurt_sfx != null:
		for path in BOSS_HURT_SFX_PATHS:
			if ResourceLoader.exists(path):
				enemy_hurt_sfx.stream = load(path)
				break

func _defeat() -> void:
	defeated_flag = true
	health = 0.0
	posture = max_posture
	set_collision_layer_value(1, false)
	if execute_label != null:
		execute_label.visible = false
	if debug_response_label != null:
		debug_response_label.visible = false
	if hit_spark != null:
		hit_spark.visible = false
	if sprite != null:
		sprite.modulate = Color.WHITE
	play_boss_animation("death")
	defeated.emit()
