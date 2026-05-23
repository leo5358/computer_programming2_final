extends CharacterBody2D

signal defeated
signal stats_changed

const CombatMathScript = preload("res://scripts/combat_math.gd")
const CombatServerScript = preload("res://scripts/combat_server.gd")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/DamageNumber.tscn")

enum EnemyState {
	PATROL,
	ALERTED,
	CHASE,
	HOLD,
	FLEE,
	ATTACK,
	DEFLECT,
	HURT,
	POSTURE_BROKEN,
	DEAD,
}

@export var display_name := "Enemy"
@export var sprite_root := "res://assets/sprites/warrior"
@export var attack_sprite_name := "attack.png"
@export var max_health := 55.0
@export var max_posture := 100.0
@export var attack_damage := 12.0
@export var attack_posture_damage := 20.0
@export var patrol_speed := 38.0
@export var chase_speed := 85.0
@export var flee_speed := 105.0
@export var patrol_distance := 120.0
@export var attack_range := 72.0
@export var ideal_distance := 62.0
@export var too_close_distance := 36.0
@export var vision_range := 320.0
@export var vision_height := 96.0
@export var vision_offset := Vector2(24.0, -48.0)
@export var attack_cue_start := 0.38
@export var attack_hit_start := 0.52
@export var attack_hit_end := 0.62
@export var attack_total_time := 0.82
@export var attack_cooldown_duration := 1.0
@export var counter_cue_start := 0.10
@export var counter_hit_start := 0.24
@export var counter_hit_end := 0.38
@export var counter_total_time := 0.70
@export var counter_step_time := 0.12
@export var counter_step_speed := 120.0
@export var thrust_range := 0.0
@export var thrust_cue_start := 0.30
@export var thrust_hit_start := 0.46
@export var thrust_hit_end := 0.60
@export var thrust_total_time := 0.92
@export var thrust_step_time := 0.22
@export var thrust_step_speed := 220.0
@export var thrust_hitbox_size := Vector2(112.0, 42.0)
@export var thrust_hitbox_offset := Vector2(62.0, -34.0)
@export var pressure_duration := 2.0
@export var pressure_thrust_range_multiplier := 1.25
@export var whiff_cooldown_multiplier := 0.45
@export var posture_recovery_pause := 1.4
@export var posture_recovery_rate := 10.0
@export var perfect_parry_input_leeway := 0.16
@export var is_perilous_attack := false
@export var perfect_parry_posture_damage := 22.0
@export var normal_block_posture_damage := 10.0
@export var parried_recovery_duration := 1.25
@export var hit_recoil_force := 120.0
@export var direct_hit_hurt_time := 0.28
@export var direct_hit_recoil_force := 210.0
@export var direct_hit_thrust_lockout_time := 0.65
@export var parry_recoil_force := 155.0
@export var dodge_posture_damage := 8.0
@export_range(0.0, 1.0, 0.05) var guard_chance := 0.0
@export var guard_posture_damage := 8.0
@export var deflect_duration := 0.28
@export var guard_lockout_duration := 0.45
@export var corpse_lifetime := 5.0

var math: RefCounted = CombatMathScript.new()
var health := max_health
var posture := 0.0
var state := EnemyState.PATROL
var spawn_position := Vector2.ZERO
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing := -1.0
var patrol_direction := -1.0
var target: Node2D
var is_alerted := false
var defeated_flag := false
var posture_broken := false
var attack_elapsed := 0.0
var attack_cooldown := 0.5
var attack_has_connected := false
var hit_flash_timer := 0.0
var hit_recoil_timer := 0.0
var hit_spark_timer := 0.0
var dodge_spark_timer := 0.0
var direct_hit_thrust_lockout_timer := 0.0
var deflect_timer := 0.0
var guard_lockout_timer := 0.0
var counter_after_deflect := false
var pressure_timer := 0.0
var posture_recovery_pause_timer := 0.0
var corpse_timer := 0.0
var attack_area_base_position := Vector2.ZERO
var attack_hitbox_base_size := Vector2.ZERO
var current_attack_profile := "attack"
var current_attack_animation := "attack"
var current_attack_cue_start := 0.0
var current_attack_hit_start := 0.0
var current_attack_hit_end := 0.0
var current_attack_total_time := 0.0
var current_attack_step_time := 0.0
var current_attack_step_speed := 0.0
var current_attack_type := CombatServerScript.AttackType.NORMAL
var custom_animation_frames: Dictionary = {}
var custom_animation_speeds: Dictionary = {}
var custom_animation_loops: Dictionary = {}

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D
@onready var attack_collision_shape: CollisionShape2D = get_node_or_null("AttackArea/CollisionShape2D") as CollisionShape2D
@onready var attack_visual: ColorRect = get_node_or_null("AttackVisual") as ColorRect
@onready var hit_spark: ColorRect = get_node_or_null("HitSpark") as ColorRect
@onready var execute_label: Label = get_node_or_null("ExecuteLabel") as Label
@onready var warning_label: Label = get_node_or_null("WarningLabel") as Label

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("minor_enemy")
	spawn_position = global_position
	health = max_health
	posture = 0.0
	_setup_sprite_frames()
	if attack_area != null:
		attack_area_base_position = attack_area.position
	if attack_collision_shape != null and attack_collision_shape.shape is RectangleShape2D:
		attack_hitbox_base_size = (attack_collision_shape.shape as RectangleShape2D).size
	_apply_attack_profile("attack")
	_sync_directional_nodes()
	_set_attack_visual(false, false)
	if execute_label != null:
		execute_label.visible = false
	if warning_label != null:
		warning_label.visible = false
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	_update_feedback(delta)
	_update_pressure_and_posture(delta)
	guard_lockout_timer = max(0.0, guard_lockout_timer - delta)
	if defeated_flag:
		corpse_timer = max(0.0, corpse_timer - delta)
		if corpse_timer <= 0.0:
			queue_free()
			return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	if defeated_flag:
		velocity.x = 0.0
	elif posture_broken:
		velocity.x = 0.0
	elif state == EnemyState.ATTACK:
		_update_attack(delta)
	elif state == EnemyState.DEFLECT:
		_update_deflect(delta)
	else:
		_update_awareness()
		_update_movement_state(delta)

	move_and_slide()
	_update_visuals()
	stats_changed.emit()

func get_vision_rect() -> Rect2:
	var x := vision_offset.x if facing >= 0.0 else -vision_offset.x - vision_range
	return Rect2(Vector2(x, vision_offset.y - vision_height * 0.5), Vector2(vision_range, vision_height))

func can_see_player() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var local_player := to_local(player.global_position)
	return get_vision_rect().has_point(local_player)

func receive_alert(_source: Node = null) -> void:
	is_alerted = true
	if state == EnemyState.PATROL:
		state = EnemyState.ALERTED

func receive_player_attack(damage: float, posture_damage: float) -> Variant:
	if defeated_flag:
		return false
	if _should_guard_player_attack():
		_guard_player_attack()
		return {"guarded": true}
	_spawn_damage_number(damage)
	health = max(0.0, health - damage)
	posture = clamp(posture + posture_damage, 0.0, max_posture)
	_mark_combat_pressure()
	receive_alert()
	if posture >= max_posture:
		_break_posture()
	elif health <= 0.0:
		_defeat()
	else:
		_start_direct_hurt_feedback()
	return true

func _start_direct_hurt_feedback() -> void:
	state = EnemyState.HURT
	_interrupt_attack()
	hit_flash_timer = direct_hit_hurt_time * 0.75
	hit_spark_timer = 0.16
	hit_recoil_timer = direct_hit_hurt_time
	direct_hit_thrust_lockout_timer = direct_hit_thrust_lockout_time
	velocity.x = -facing * direct_hit_recoil_force
	_force_play_animation("hurt")

func receive_block_feedback(perfect: bool) -> void:
	if defeated_flag:
		return
	posture = clamp(posture + (perfect_parry_posture_damage if perfect else normal_block_posture_damage), 0.0, max_posture)
	_mark_combat_pressure()
	_interrupt_attack()
	attack_cooldown = max(attack_cooldown, parried_recovery_duration if perfect else attack_cooldown_duration * 0.45)
	hit_flash_timer = 0.08
	hit_spark_timer = 0.20 if perfect else 0.10
	hit_recoil_timer = 0.16 if perfect else 0.08
	velocity.x = -facing * (parry_recoil_force if perfect else hit_recoil_force * 0.5)
	if posture >= max_posture:
		_break_posture()

func can_be_perfect_dodged_by(player: Node2D) -> bool:
	if defeated_flag or posture_broken or player == null:
		return false
	if state != EnemyState.ATTACK:
		return false
	if attack_elapsed < current_attack_cue_start or attack_elapsed > current_attack_hit_end:
		return false
	return global_position.distance_to(player.global_position) <= attack_range + 24.0

func receive_dodge_feedback() -> void:
	if defeated_flag:
		return
	posture = clamp(posture + dodge_posture_damage, 0.0, max_posture)
	_mark_combat_pressure()
	_interrupt_attack()
	dodge_spark_timer = 0.18
	hit_flash_timer = 0.08
	hit_spark_timer = 0.16
	hit_recoil_timer = 0.12
	velocity.x = -facing * hit_recoil_force
	if posture >= max_posture:
		_break_posture()

func can_be_executed() -> bool:
	return posture_broken and not defeated_flag

func execute() -> void:
	if can_be_executed():
		_defeat()

func can_be_perfect_parried_by(player: Node) -> bool:
	if state != EnemyState.ATTACK:
		return false
	if attack_elapsed < current_attack_cue_start or attack_elapsed > current_attack_hit_end:
		return false
	if player != null and "parry_elapsed" in player:
		return float(player.parry_elapsed) <= perfect_parry_input_leeway
	return true

func reset_combat_state() -> void:
	health = max_health
	posture = 0.0
	state = EnemyState.PATROL
	is_alerted = false
	defeated_flag = false
	posture_broken = false
	attack_elapsed = 0.0
	attack_cooldown = 0.5
	attack_has_connected = false
	current_attack_profile = "attack"
	current_attack_animation = "attack"
	_apply_attack_profile("attack")
	hit_flash_timer = 0.0
	hit_recoil_timer = 0.0
	hit_spark_timer = 0.0
	dodge_spark_timer = 0.0
	direct_hit_thrust_lockout_timer = 0.0
	deflect_timer = 0.0
	guard_lockout_timer = 0.0
	counter_after_deflect = false
	pressure_timer = 0.0
	posture_recovery_pause_timer = 0.0
	corpse_timer = 0.0
	velocity = Vector2.ZERO
	global_position = spawn_position
	set_collision_layer_value(1, true)
	_set_attack_visual(false, false)
	if execute_label != null:
		execute_label.visible = false
	if warning_label != null:
		warning_label.visible = false
	_update_visuals()

func _update_awareness() -> void:
	if can_see_player():
		receive_alert()
	if is_alerted and target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D

func _update_movement_state(delta: float) -> void:
	attack_cooldown = max(0.0, attack_cooldown - delta)
	direct_hit_thrust_lockout_timer = max(0.0, direct_hit_thrust_lockout_timer - delta)
	if state == EnemyState.HURT and hit_recoil_timer > 0.0:
		return
	if is_alerted and target != null:
		_update_combat_movement()
	else:
		_update_patrol()

func _update_combat_movement() -> void:
	var offset_x: float = target.global_position.x - global_position.x
	var distance: float = abs(offset_x)
	if absf(offset_x) > 4.0:
		facing = sign(offset_x)
	if distance < too_close_distance:
		state = EnemyState.FLEE
		velocity.x = -facing * flee_speed
	elif distance <= attack_range and attack_cooldown <= 0.0:
		_start_attack()
	elif _can_start_thrust(distance):
		_start_thrust_attack()
	elif distance > ideal_distance:
		state = EnemyState.CHASE
		velocity.x = facing * chase_speed
	else:
		state = EnemyState.HOLD
		velocity.x = 0.0

func _should_guard_player_attack() -> bool:
	if guard_chance <= 0.0:
		return false
	if guard_lockout_timer > 0.0:
		return false
	if state == EnemyState.HURT or state == EnemyState.DEFLECT:
		return false
	if state == EnemyState.ATTACK and attack_elapsed >= attack_hit_start and attack_elapsed <= attack_hit_end:
		return false
	if posture_broken or defeated_flag:
		return false
	return randf() <= guard_chance

func _guard_player_attack() -> void:
	receive_alert()
	posture = clamp(posture + guard_posture_damage, 0.0, max_posture)
	_mark_combat_pressure()
	state = EnemyState.DEFLECT
	deflect_timer = deflect_duration
	counter_after_deflect = true
	guard_lockout_timer = guard_lockout_duration
	attack_elapsed = 0.0
	attack_has_connected = false
	attack_cooldown = 0.0
	hit_flash_timer = 0.08
	hit_spark_timer = 0.18
	hit_recoil_timer = 0.10
	velocity.x = -facing * hit_recoil_force * 0.45
	_set_attack_visual(false, false)
	if posture >= max_posture:
		_break_posture()

func _update_deflect(delta: float) -> void:
	velocity.x = 0.0
	deflect_timer = max(0.0, deflect_timer - delta)
	if deflect_timer <= 0.0:
		if counter_after_deflect:
			_start_deflect_counter()
		else:
			state = EnemyState.HOLD if is_alerted else EnemyState.PATROL

func _start_deflect_counter() -> void:
	counter_after_deflect = false
	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		state = EnemyState.HOLD if is_alerted else EnemyState.PATROL
		return
	var offset_x: float = target.global_position.x - global_position.x
	if absf(offset_x) > 4.0:
		facing = sign(offset_x)
	if absf(offset_x) <= attack_range:
		_start_counter_attack()
	elif _can_start_thrust(absf(offset_x)):
		_start_thrust_attack()
	else:
		state = EnemyState.CHASE
		velocity.x = facing * chase_speed

func _can_start_thrust(distance: float) -> bool:
	if direct_hit_thrust_lockout_timer > 0.0:
		return false
	var effective_range := thrust_range * (pressure_thrust_range_multiplier if pressure_timer > 0.0 else 1.0)
	return thrust_range > attack_range and attack_cooldown <= 0.0 and distance > attack_range and distance <= effective_range

func _update_patrol() -> void:
	var offset := global_position.x - spawn_position.x
	if offset >= patrol_distance:
		patrol_direction = -1.0
	elif offset <= -patrol_distance:
		patrol_direction = 1.0
	facing = patrol_direction
	velocity.x = patrol_direction * patrol_speed

func _start_attack() -> void:
	_start_attack_profile("attack")

func _start_thrust_attack() -> void:
	_start_attack_profile("thrust")

func _start_counter_attack() -> void:
	_start_attack_profile("counter")

func _start_attack_profile(profile: StringName) -> void:
	state = EnemyState.ATTACK
	_apply_attack_profile(profile)
	attack_elapsed = 0.0
	attack_has_connected = false
	velocity.x = facing * current_attack_step_speed if current_attack_step_time > 0.0 else 0.0
	_set_attack_visual(false, false)
	if sprite != null and sprite.sprite_frames.has_animation(current_attack_animation):
		sprite.play(current_attack_animation)

func _apply_attack_profile(profile: StringName) -> void:
	current_attack_profile = String(profile)
	current_attack_animation = String(profile)
	current_attack_type = CombatServerScript.AttackType.NORMAL
	if profile == &"thrust":
		current_attack_cue_start = thrust_cue_start
		current_attack_hit_start = thrust_hit_start
		current_attack_hit_end = thrust_hit_end
		current_attack_total_time = thrust_total_time
		current_attack_step_time = thrust_step_time
		current_attack_step_speed = thrust_step_speed
		_set_attack_hitbox(thrust_hitbox_size, thrust_hitbox_offset)
	elif profile == &"counter":
		current_attack_animation = "attack"
		current_attack_cue_start = counter_cue_start
		current_attack_hit_start = counter_hit_start
		current_attack_hit_end = counter_hit_end
		current_attack_total_time = counter_total_time
		current_attack_step_time = counter_step_time
		current_attack_step_speed = counter_step_speed
		_set_attack_hitbox(attack_hitbox_base_size, attack_area_base_position)
	else:
		current_attack_profile = "attack"
		current_attack_animation = "attack"
		current_attack_cue_start = attack_cue_start
		current_attack_hit_start = attack_hit_start
		current_attack_hit_end = attack_hit_end
		current_attack_total_time = attack_total_time
		current_attack_step_time = 0.0
		current_attack_step_speed = 0.0
		_set_attack_hitbox(attack_hitbox_base_size, attack_area_base_position)

func _set_attack_hitbox(size: Vector2, offset: Vector2) -> void:
	if attack_area != null:
		attack_area_base_position = offset
	if attack_collision_shape != null and attack_collision_shape.shape is RectangleShape2D and size != Vector2.ZERO:
		(attack_collision_shape.shape as RectangleShape2D).size = size
	_sync_directional_nodes()

func _update_attack(delta: float) -> void:
	attack_elapsed += delta
	_maybe_convert_windup_to_thrust()
	if current_attack_step_time > 0.0 and attack_elapsed <= current_attack_step_time:
		velocity.x = facing * current_attack_step_speed
	else:
		velocity.x = 0.0
	var active := attack_elapsed >= current_attack_hit_start and attack_elapsed <= current_attack_hit_end
	_set_attack_visual(attack_elapsed >= current_attack_cue_start and attack_elapsed <= current_attack_hit_end, active)
	if attack_elapsed >= current_attack_hit_start and not attack_has_connected:
		_connect_attack()
	if attack_elapsed >= current_attack_total_time:
		var whiffed := not attack_has_connected
		_interrupt_attack()
		attack_cooldown = attack_cooldown_duration * (whiff_cooldown_multiplier if whiffed else 1.0)
		state = EnemyState.HOLD

func _connect_attack() -> void:
	if attack_area == null:
		return
	for body in attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("receive_enemy_attack"):
			attack_has_connected = true
			body.receive_enemy_attack(attack_damage, attack_posture_damage, self, current_attack_type)
			return

func _interrupt_attack() -> void:
	if state == EnemyState.ATTACK:
		state = EnemyState.HOLD
	attack_elapsed = 0.0
	attack_has_connected = false
	_apply_attack_profile("attack")
	_set_attack_visual(false, false)

func _maybe_convert_windup_to_thrust() -> void:
	if current_attack_animation != "attack" or thrust_range <= attack_range:
		return
	if target == null or attack_elapsed >= current_attack_hit_start:
		return
	var offset_x: float = target.global_position.x - global_position.x
	var distance := absf(offset_x)
	if absf(offset_x) > 4.0:
		facing = sign(offset_x)
	if _can_start_thrust(distance):
		_start_thrust_attack()

func _mark_combat_pressure() -> void:
	pressure_timer = pressure_duration
	posture_recovery_pause_timer = posture_recovery_pause

func _update_pressure_and_posture(delta: float) -> void:
	pressure_timer = max(0.0, pressure_timer - delta)
	posture_recovery_pause_timer = max(0.0, posture_recovery_pause_timer - delta)
	if defeated_flag or posture_broken:
		return
	if posture_recovery_pause_timer > 0.0 or posture <= 0.0:
		return
	var health_ratio: float = clamp(health / max(max_health, 0.001), 0.0, 1.0)
	var recovery_rate := posture_recovery_rate * (0.35 + 0.65 * health_ratio)
	posture = max(0.0, posture - recovery_rate * delta)

func _set_attack_visual(show_visual: bool, active: bool) -> void:
	if attack_visual != null:
		attack_visual.visible = show_visual
		attack_visual.color = Color(1.0, 0.12, 0.04, 0.62) if active else Color(1.0, 0.84, 0.08, 0.48)
	if warning_label != null:
		warning_label.visible = show_visual and is_perilous_attack

func _break_posture() -> void:
	posture_broken = true
	state = EnemyState.POSTURE_BROKEN
	_interrupt_attack()
	if execute_label != null:
		execute_label.visible = true

func _defeat() -> void:
	defeated_flag = true
	state = EnemyState.DEAD
	health = 0.0
	corpse_timer = corpse_lifetime
	velocity = Vector2.ZERO
	_set_attack_visual(false, false)
	set_collision_layer_value(1, false)
	defeated.emit()

func _update_feedback(delta: float) -> void:
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	hit_recoil_timer = max(0.0, hit_recoil_timer - delta)
	hit_spark_timer = max(0.0, hit_spark_timer - delta)
	dodge_spark_timer = max(0.0, dodge_spark_timer - delta)
	if hit_spark != null:
		hit_spark.visible = hit_spark_timer > 0.0 or dodge_spark_timer > 0.0
	if sprite != null:
		sprite.modulate = Color(1.65, 1.65, 1.22, 1.0) if hit_flash_timer > 0.0 else Color.WHITE

func _update_visuals() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	_sync_directional_nodes()
	sprite.flip_h = facing < 0.0
	var next_animation := "idle"
	if defeated_flag:
		next_animation = "death"
	elif state == EnemyState.HURT:
		next_animation = "hurt"
	elif state == EnemyState.DEFLECT:
		next_animation = "deflect"
	elif state == EnemyState.ATTACK:
		next_animation = current_attack_animation
	elif abs(velocity.x) > 1.0:
		next_animation = "walk"
	if sprite.sprite_frames.has_animation(next_animation) and sprite.animation != next_animation:
		sprite.play(next_animation)

func _force_play_animation(animation: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(animation):
		return
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.play(animation)

func _sync_directional_nodes() -> void:
	if attack_area != null:
		var base_x: float = absf(attack_area_base_position.x)
		attack_area.position.x = base_x * facing
		attack_area.position.y = attack_area_base_position.y
	if attack_area != null and attack_visual != null and attack_collision_shape != null and attack_collision_shape.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = attack_collision_shape.shape as RectangleShape2D
		attack_visual.size = rect_shape.size
		attack_visual.position = attack_area.position - rect_shape.size * 0.5

func _setup_sprite_frames() -> void:
	if sprite == null:
		return
	var frames := SpriteFrames.new()
	if custom_animation_frames.has("idle"):
		_add_custom_animation(frames, "idle")
	else:
		_add_strip(frames, "idle", "%s/idle.png" % sprite_root, 8, 6.0, true)
	if custom_animation_frames.has("walk"):
		_add_custom_animation(frames, "walk")
	else:
		_add_strip(frames, "walk", "%s/walk.png" % sprite_root, 8, 10.0, true)
	if custom_animation_frames.has("attack"):
		_add_custom_animation(frames, "attack")
	else:
		_add_strip(frames, "attack", "%s/%s" % [sprite_root, attack_sprite_name], 8, 10.0, false)
	if custom_animation_frames.has("deflect"):
		_add_custom_animation(frames, "deflect")
	if custom_animation_frames.has("thrust"):
		_add_custom_animation(frames, "thrust")
	if custom_animation_frames.has("hurt"):
		_add_custom_animation(frames, "hurt")
	else:
		_add_strip(frames, "hurt", "%s/hurt.png" % sprite_root, 8, 10.0, false)
	if custom_animation_frames.has("death"):
		_add_custom_animation(frames, "death")
	else:
		_add_strip(frames, "death", "%s/death.png" % sprite_root, 8, 8.0, false)
	sprite.sprite_frames = frames
	sprite.position = Vector2(0.0, -48.0)

func _add_custom_animation(frames: SpriteFrames, animation: StringName) -> void:
	var animation_key := String(animation)
	var frame_specs: Array = custom_animation_frames.get(animation_key, [])
	if frame_specs.is_empty():
		return
	frames.add_animation(animation)
	frames.set_animation_speed(animation, float(custom_animation_speeds.get(animation_key, 10.0)))
	frames.set_animation_loop(animation, bool(custom_animation_loops.get(animation_key, false)))
	for spec in frame_specs:
		var frame_spec: Dictionary = spec
		var texture := load(String(frame_spec["path"])) as Texture2D
		if texture == null:
			continue
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = frame_spec["region"]
		atlas_texture.filter_clip = true
		frames.add_frame(animation, atlas_texture)

func _add_strip(frames: SpriteFrames, animation: StringName, path: String, count: int, fps: float, loop: bool) -> void:
	if not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	if texture == null:
		return
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for column in count:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(column * 96, 0, 96, 96)
		atlas_texture.filter_clip = true
		frames.add_frame(animation, atlas_texture)

func _spawn_damage_number(damage: float) -> void:
	if damage <= 0.0:
		return
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	var parent := get_parent()
	if parent == null:
		parent = get_tree().root
	parent.add_child(number)
	number.global_position = global_position + Vector2(0.0, -72.0)
	if number.has_method("setup"):
		number.setup(damage)
