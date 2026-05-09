extends CharacterBody2D

signal stats_changed
signal defeated

const CombatMathScript = preload("res://scripts/combat_math.gd")
const CombatServerScript = preload("res://scripts/combat_server.gd")
const ENEMY_SHEET: Texture2D = preload("res://assets/sprites/enemy/enemy_sheet.png")
const ENEMY_HURT_SFX_PATH := "res://assets/sfx/enemy_hurt.wav"
const POSTURE_BREAK_SFX_PATH := "res://assets/sfx/posture_break.wav"
const EXECUTION_SFX_PATH := "res://assets/sfx/execution.wav"
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/DamageNumber.tscn")

@export var display_name := "Enemy"
@export var max_health := 45.0
@export var max_posture := 100.0
@export var attack_damage := 12.0
@export var attack_posture_damage := 22.0
@export var attack_interval := 1.4
@export var attack_windup := 1.5
@export var attack_cue_time := 0.38
@export var attack_active_time := 0.18
@export var posture_recovery := 7.0
@export var attack_range := 78.0
@export var detection_range := 260.0
@export var patrol_distance := 96.0
@export var patrol_speed := 45.0
@export var chase_speed := 80.0
@export var hit_recoil_time := 0.14
@export var hit_recoil_force := 120.0
@export var parry_recoil_time := 0.20
@export var parry_recoil_force := 170.0
@export var hit_flash_time := 0.09
@export var hit_freeze_time := 0.055
@export var parry_spark_time := 0.24
@export var dodge_posture_damage := 8.0
@export var dodge_spark_time := 0.20

var health := max_health
var posture := 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var target: Node2D
var attack_cooldown := 0.8
var windup_timer := 0.0
var active_timer := 0.0
var is_winding_up := false
var is_attack_cue_active := false
var is_attack_active := false
var combat_runtime: Node
var current_attack_id := -1
var posture_broken := false
var defeated_flag := false
var spawn_position := Vector2.ZERO
var default_body_color := Color.WHITE
var facing := -1.0
var current_animation := ""
var patrol_direction := -1.0
var hit_spark_timer := 0.0
var parry_spark_timer := 0.0
var dodge_spark_timer := 0.0
var posture_break_spark_timer := 0.0
var hit_recoil_timer := 0.0
var hit_flash_timer := 0.0
var hit_freeze_timer := 0.0

@onready var math: RefCounted = CombatMathScript.new()
@onready var body_visual: ColorRect = $Body
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var attack_visual: ColorRect = $AttackVisual
@onready var hit_spark: ColorRect = get_node_or_null("HitSpark") as ColorRect
@onready var hit_spark_vfx: Line2D = get_node_or_null("HitSparkVfx") as Line2D
@onready var parry_spark_vfx: Line2D = get_node_or_null("ParrySparkVfx") as Line2D
@onready var posture_break_spark: ColorRect = get_node_or_null("PostureBreakSpark") as ColorRect
@onready var countdown_label: Label = get_node_or_null("CountdownLabel") as Label
@onready var execute_label: Label = get_node_or_null("ExecuteLabel") as Label
@onready var enemy_hurt_sfx: AudioStreamPlayer2D = get_node_or_null("EnemyHurtSfx") as AudioStreamPlayer2D
@onready var posture_break_sfx: AudioStreamPlayer2D = get_node_or_null("PostureBreakSfx") as AudioStreamPlayer2D
@onready var execution_sfx: AudioStreamPlayer2D = get_node_or_null("ExecutionSfx") as AudioStreamPlayer2D

func _ready() -> void:
	add_to_group("enemy")
	spawn_position = global_position
	default_body_color = body_visual.color
	combat_runtime = get_tree().get_first_node_in_group("combat_runtime")
	target = get_tree().get_first_node_in_group("player") as Node2D
	_setup_sprite_frames()
	_load_optional_sfx()
	_update_visuals()
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	_update_feedback(delta)
	_apply_gravity(delta)
	if defeated_flag:
		velocity.x = 0.0
		move_and_slide()
		_update_visuals()
		return
	if posture_broken:
		velocity.x = 0.0
		move_and_slide()
		_update_visuals()
		stats_changed.emit()
		return

	if target == null:
		target = get_tree().get_first_node_in_group("player") as Node2D

	if target != null:
		facing = sign(target.global_position.x - global_position.x)
		if facing == 0.0:
			facing = -1.0

	if hit_freeze_timer > 0.0:
		_update_visuals()
		stats_changed.emit()
		return

	posture = max(0.0, posture - posture_recovery * delta)
	_update_attack_state(delta)
	_update_movement(delta)

	if target != null and not is_winding_up and not is_attack_active:
		attack_cooldown -= delta
		var distance := global_position.distance_to(target.global_position)
		if distance <= attack_range and attack_cooldown <= 0.0:
			_start_attack_windup()

	move_and_slide()
	stats_changed.emit()
	_update_visuals()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_attack_state(delta: float) -> void:
	if is_winding_up:
		windup_timer -= delta
		_update_countdown_label()
		if windup_timer <= attack_cue_time and not is_attack_cue_active:
			_start_attack_cue()
		if windup_timer <= 0.0:
			_release_attack()

	if is_attack_active:
		active_timer -= delta
		if active_timer <= 0.0:
			is_attack_active = false
			attack_visual.visible = false
			attack_cooldown = attack_interval

func _start_attack_windup() -> void:
	is_winding_up = true
	is_attack_cue_active = false
	velocity.x = 0.0
	windup_timer = attack_windup
	if countdown_label != null:
		countdown_label.visible = true
	_update_countdown_label()
	_update_visuals()

func _update_countdown_label() -> void:
	if countdown_label != null:
		countdown_label.text = "%.1f" % max(windup_timer, 0.0)

func _start_attack_cue() -> void:
	is_attack_cue_active = true
	attack_visual.visible = true
	attack_visual.color = Color(1, 0.88, 0.08, 0.68)
	_update_visuals()

func _release_attack() -> void:
	is_winding_up = false
	is_attack_cue_active = false
	if countdown_label != null:
		countdown_label.visible = false
	is_attack_active = true
	active_timer = attack_active_time
	velocity.x = 0.0
	attack_visual.visible = true
	attack_visual.color = Color(1, 0.2, 0.08, 0.62)
	current_attack_id = _notify_attack_active()
	if target != null and global_position.distance_to(target.global_position) <= attack_range + 16.0:
		if target.has_method("receive_enemy_attack"):
			target.receive_enemy_attack(attack_damage, attack_posture_damage, self)
	_update_visuals()

func receive_player_attack(damage: float, posture_damage: float) -> void:
	if defeated_flag:
		return

	_spawn_damage_number(damage)
	health = math.apply_damage(health, damage)
	posture = math.add_posture(posture, posture_damage)
	if posture >= max_posture:
		_break_posture()
		return

	if health <= 0.0:
		_defeat()
	else:
		_trigger_hit_feedback()
		stats_changed.emit()

func receive_block_feedback(perfect: bool) -> void:
	if defeated_flag:
		return

	posture = math.add_posture(posture, 42.0 if perfect else 14.0)
	if posture >= max_posture:
		_break_posture()
	else:
		_trigger_parry_feedback(perfect)
		stats_changed.emit()

func can_be_perfect_dodged_by(player: Node2D) -> bool:
	if defeated_flag or posture_broken:
		return false
	if not is_attack_cue_active and not is_attack_active:
		return false
	return global_position.distance_to(player.global_position) <= attack_range + 24.0

func receive_dodge_feedback() -> void:
	if defeated_flag:
		return
	posture = math.add_posture(posture, dodge_posture_damage)
	if posture >= max_posture:
		_break_posture()
		return
	dodge_spark_timer = dodge_spark_time
	hit_flash_timer = hit_flash_time
	hit_freeze_timer = hit_freeze_time
	if parry_spark_vfx != null:
		parry_spark_vfx.position.x = 22.0 * facing
		parry_spark_vfx.scale.x = facing
	_shake_camera(12.0, 0.09)
	stats_changed.emit()

func can_be_executed() -> bool:
	return posture_broken and not defeated_flag

func execute() -> void:
	if can_be_executed():
		_play_sfx(execution_sfx)
		_defeat()

func _break_posture() -> void:
	posture_broken = true
	posture = max_posture
	is_winding_up = false
	is_attack_cue_active = false
	is_attack_active = false
	attack_visual.visible = false
	if hit_spark_vfx != null:
		hit_spark_vfx.visible = false
	if parry_spark_vfx != null:
		parry_spark_vfx.visible = false
	body_visual.color = Color(1.0, 0.86, 0.16, 1.0)
	if countdown_label != null:
		countdown_label.visible = false
	if execute_label != null:
		execute_label.visible = true
	_trigger_posture_break_feedback()
	_update_visuals()
	stats_changed.emit()

func _update_movement(_delta: float) -> void:
	if hit_recoil_timer > 0.0:
		return

	if is_winding_up or is_attack_active or posture_broken or defeated_flag:
		velocity.x = 0.0
		return

	if target != null:
		var offset: float = target.global_position.x - global_position.x
		var distance: float = abs(offset)
		if distance <= detection_range:
			facing = sign(offset) if offset != 0.0 else facing
			if distance > attack_range * 0.85:
				velocity.x = facing * chase_speed
			else:
				velocity.x = 0.0
			return

	var patrol_offset := global_position.x - spawn_position.x
	if abs(patrol_offset) >= patrol_distance:
		patrol_direction = -sign(patrol_offset)
	facing = patrol_direction
	velocity.x = patrol_direction * patrol_speed

func _defeat() -> void:
	defeated_flag = true
	health = 0.0
	body_visual.color = Color(0.12, 0.12, 0.12, 0.55)
	attack_visual.visible = false
	is_attack_cue_active = false
	posture_broken = false
	if countdown_label != null:
		countdown_label.visible = false
	if execute_label != null:
		execute_label.visible = false
	set_collision_layer_value(1, false)
	_update_visuals()
	defeated.emit()
	stats_changed.emit()

func _notify_attack_active() -> int:
	if combat_runtime == null:
		combat_runtime = get_tree().get_first_node_in_group("combat_runtime")
	if combat_runtime != null and combat_runtime.has_method("notify_attack_active"):
		return combat_runtime.notify_attack_active(CombatServerScript.AttackType.NORMAL, Time.get_ticks_msec())
	return -1

func reset_combat_state() -> void:
	health = max_health
	posture = 0.0
	attack_cooldown = 0.8
	windup_timer = 0.0
	active_timer = 0.0
	is_winding_up = false
	is_attack_cue_active = false
	is_attack_active = false
	current_attack_id = -1
	posture_broken = false
	defeated_flag = false
	velocity = Vector2.ZERO
	hit_spark_timer = 0.0
	parry_spark_timer = 0.0
	dodge_spark_timer = 0.0
	posture_break_spark_timer = 0.0
	hit_recoil_timer = 0.0
	hit_flash_timer = 0.0
	hit_freeze_timer = 0.0
	global_position = spawn_position
	body_visual.color = default_body_color
	if sprite != null:
		sprite.modulate = Color.WHITE
	attack_visual.visible = false
	if countdown_label != null:
		countdown_label.visible = false
	if execute_label != null:
		execute_label.visible = false
	set_collision_layer_value(1, true)
	_update_visuals()
	stats_changed.emit()

func _setup_sprite_frames() -> void:
	if sprite == null:
		return
	var frames := SpriteFrames.new()
	_add_sheet_animation(frames, "idle", 0, 4, 6.0, true)
	_add_sheet_animation(frames, "walk", 1, 8, 10.0, true)
	_add_sheet_animation(frames, "attack", 2, 12, 18.0, false)
	_add_sheet_animation(frames, "attack_cue", 3, 6, 10.0, true)
	_add_sheet_animation(frames, "stunned", 4, 6, 8.0, true)
	_add_sheet_animation(frames, "death", 5, 8, 8.0, false)
	sprite.sprite_frames = frames
	sprite.play("idle")

func _add_sheet_animation(frames: SpriteFrames, animation: StringName, row: int, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for column in count:
		var texture := AtlasTexture.new()
		texture.atlas = ENEMY_SHEET
		texture.region = Rect2(column * 64, row * 64, 64, 64)
		frames.add_frame(animation, texture)

func _update_visuals() -> void:
	body_visual.visible = sprite == null
	if sprite == null:
		return
	sprite.flip_h = facing < 0.0
	var next_animation := "idle"
	if defeated_flag:
		next_animation = "death"
	elif posture_broken:
		next_animation = "stunned"
	elif is_attack_active:
		next_animation = "attack"
	elif is_winding_up or is_attack_cue_active:
		next_animation = "attack_cue"
	elif abs(velocity.x) > 1.0:
		next_animation = "walk"
	if current_animation != next_animation:
		current_animation = next_animation
		sprite.play(next_animation)

func _trigger_hit_feedback() -> void:
	hit_spark_timer = 0.18
	hit_flash_timer = hit_flash_time
	hit_freeze_timer = hit_freeze_time
	hit_recoil_timer = hit_recoil_time
	velocity.x = -facing * hit_recoil_force
	if hit_spark != null:
		hit_spark.position.x = 18.0 * facing
	if hit_spark_vfx != null:
		hit_spark_vfx.position.x = 18.0 * facing
		hit_spark_vfx.scale.x = facing
	_shake_camera(7.0, 0.075)
	_play_sfx(enemy_hurt_sfx)
	_update_feedback(0.0)

func _spawn_damage_number(damage: float) -> void:
	var number := DAMAGE_NUMBER_SCENE.instantiate()
	var parent := get_parent()
	if parent == null:
		parent = get_tree().root
	parent.add_child(number)
	number.global_position = global_position + Vector2(0.0, -64.0)
	if number.has_method("setup"):
		number.setup(damage)

func _trigger_parry_feedback(perfect: bool) -> void:
	if perfect:
		_interrupt_attack_from_parry()
		parry_spark_timer = parry_spark_time
		hit_flash_timer = hit_flash_time
		hit_freeze_timer = hit_freeze_time
		hit_recoil_timer = parry_recoil_time
		velocity.x = -facing * parry_recoil_force
	else:
		hit_spark_timer = 0.10
		hit_recoil_timer = hit_recoil_time * 0.65
		velocity.x = -facing * (hit_recoil_force * 0.55)
	if hit_spark != null:
		hit_spark.position.x = 22.0 * facing
	if parry_spark_vfx != null:
		parry_spark_vfx.position.x = 22.0 * facing
		parry_spark_vfx.scale.x = facing
	_shake_camera(16.0 if perfect else 9.0, 0.11 if perfect else 0.08)
	_update_feedback(0.0)

func _interrupt_attack_from_parry() -> void:
	is_winding_up = false
	is_attack_cue_active = false
	is_attack_active = false
	active_timer = 0.0
	windup_timer = 0.0
	attack_cooldown = max(attack_interval * 0.45, 0.28)
	attack_visual.visible = false
	if countdown_label != null:
		countdown_label.visible = false

func _trigger_posture_break_feedback() -> void:
	posture_break_spark_timer = 0.28
	hit_spark_timer = 0.0
	parry_spark_timer = 0.0
	dodge_spark_timer = 0.0
	hit_recoil_timer = 0.0
	hit_flash_timer = 0.0
	hit_freeze_timer = 0.0
	_play_sfx(posture_break_sfx)
	_shake_camera(22.0, 0.16)
	_update_feedback(0.0)

func _update_feedback(delta: float) -> void:
	hit_spark_timer = max(0.0, hit_spark_timer - delta)
	parry_spark_timer = max(0.0, parry_spark_timer - delta)
	dodge_spark_timer = max(0.0, dodge_spark_timer - delta)
	posture_break_spark_timer = max(0.0, posture_break_spark_timer - delta)
	hit_recoil_timer = max(0.0, hit_recoil_timer - delta)
	hit_flash_timer = max(0.0, hit_flash_timer - delta)
	hit_freeze_timer = max(0.0, hit_freeze_timer - delta)
	if hit_spark != null:
		hit_spark.visible = false
		hit_spark.color = Color(0.62, 0.95, 1.0, 0.82) if parry_spark_timer > 0.0 else Color(1, 0.95, 0.45, 0.78)
	if hit_spark_vfx != null:
		hit_spark_vfx.visible = hit_spark_timer > 0.0
	if parry_spark_vfx != null:
		parry_spark_vfx.visible = parry_spark_timer > 0.0 or dodge_spark_timer > 0.0
		parry_spark_vfx.default_color = Color(0.65, 0.95, 1.0, 0.95) if dodge_spark_timer > 0.0 else Color(0.55, 0.95, 1, 0.95)
	if posture_break_spark != null:
		posture_break_spark.visible = posture_break_spark_timer > 0.0
	if sprite != null:
		if hit_flash_timer > 0.0:
			sprite.modulate = Color(1.7, 1.7, 1.35, 1.0) if parry_spark_timer <= 0.0 else Color(1.25, 1.75, 2.0, 1.0)
		else:
			sprite.modulate = Color.WHITE
	elif not posture_broken and not defeated_flag:
		body_visual.color = Color(1.0, 0.95, 0.72, 1.0) if hit_flash_timer > 0.0 else default_body_color

func _shake_camera(amount: float, duration: float) -> void:
	var camera := get_tree().get_first_node_in_group("feedback_camera")
	if camera != null and camera.has_method("shake"):
		camera.shake(amount, duration)

func _load_optional_sfx() -> void:
	_load_optional_stream(ENEMY_HURT_SFX_PATH, enemy_hurt_sfx)
	_load_optional_stream(POSTURE_BREAK_SFX_PATH, posture_break_sfx)
	_load_optional_stream(EXECUTION_SFX_PATH, execution_sfx)

func _load_optional_stream(path: String, player: AudioStreamPlayer2D) -> void:
	if player != null and ResourceLoader.exists(path):
		player.stream = load(path)

func _play_sfx(player: AudioStreamPlayer2D) -> void:
	if player != null and player.stream != null:
		player.play()
