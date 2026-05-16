extends "res://scripts/enemy.gd"

# --- Sprites and Animation Specs from feature/Boss ---
const WALK_PATH := "res://assets/sprites/boss/walk.png"
const ATTACK_PATH := "res://assets/sprites/boss/attack.png"
const CHOP_PATH := "res://assets/sprites/boss/chop.png"
const THRUST_PATH := "res://assets/sprites/boss/thrust.png"
const THRUST_COPY_PATH := "res://assets/sprites/boss/thrust copy.png"
const DEFLECT1_PATH := "res://assets/sprites/boss/defelct1.png"
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
	"stunned": [
		[HURT_PATH, 0, 0, 128, 128],
		[HURT_PATH, 128, 0, 128, 128],
		[HURT_PATH, 256, 0, 128, 128],
		[HURT_PATH, 384, 0, 128, 128],
	],
}
const FRAME_BOTTOM_GAPS := {
	"idle": [6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0],
	"walk": [6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0, 6.0],
	"attack": [8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0],
	"thrust": [7.0, 9.0, 10.0, 10.0, 10.0, 10.0, 10.0, 7.0],
	"chop": [5.0, 7.0, 18.0, 22.0, 23.0, 7.0, 7.0],
	"deflect1": [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0],
	"deflect2": [7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0],
	"hurt": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	"stunned": [0.0, 0.0, 0.0, 0.0],
	"death": [10.0, 10.0, 10.0, 10.0, 9.0, 5.0, 5.0, 5.0],
	"jump": [6.0, 6.0, 7.0, 19.0, 26.0, 21.0, 7.0, 6.0],
}
const FRAME_CENTER_X := {
	"idle": [74.0, 67.0, 64.5, 61.0, 55.5, 50.5, 44.0, 45.0],
	"walk": [74.0, 67.0, 64.5, 61.0, 55.5, 50.5, 44.0, 45.0],
}
const VISUAL_CENTER_X := 64.0
const WALK_ANCHOR_STRENGTH := 0.45

# --- New Boss specific parameters ---
@export var attack_start_distance := 84.0
@export var attack_hold_distance := 78.0
@export var attack_step_distance := 18.0
@export var attack_step_time := 0.16
@export var attack_windup_time := 0.92
@export var attack_recovery_time := 0.58
@export var attack_hit_frame := 4
@export var normal_attack_parry_posture_damage := 36.0
@export var normal_attack_block_posture_damage := 14.0
@export var deflect_feedback_time := 0.28
@export var leash_range := 420.0

# --- State flags ---
var is_attack_winding_up := false
var is_attack_recovering := false
var attack_has_connected := false
var attack_timer := 0.0
var attack_step_timer := 0.0
var feedback_timer := 0.0
var deflect_toggle := false

@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D
@onready var attack_collision_shape: CollisionShape2D = get_node_or_null("AttackArea/CollisionShape2D") as CollisionShape2D

func _ready() -> void:
	# Initialize enemy base
	super()
	add_to_group("boss")
	
	# Override boss stats
	display_name = "Boss"
	max_health = 140.0
	max_posture = 100.0
	attack_damage = 18.0
	attack_posture_damage = 28.0
	attack_interval = 1.38
	posture_recovery = 4.0
	attack_range = 142.0
	chase_speed = 86.0
	detection_range = 280.0
	
	health = max_health
	posture = 0.0
	
	# Setup specific sprite frames
	_setup_sprite_frames()
	if sprite != null:
		sprite.position = Vector2(0.0, -64.0)
		if not sprite.frame_changed.is_connected(align_sprite_to_ground):
			sprite.frame_changed.connect(align_sprite_to_ground)
	
	if body_visual != null:
		body_visual.visible = false
		
	_update_attack_hitbox_custom()
	play_boss_animation("idle")

func _physics_process(delta: float) -> void:
	_update_feedback(delta)
	
	if feedback_timer > 0.0:
		feedback_timer = max(0.0, feedback_timer - delta)
	
	if defeated_flag:
		velocity.x = 0.0
	elif feedback_timer > 0.0:
		velocity.x = 0.0
	elif is_attack_winding_up or is_attack_active or is_attack_recovering:
		_update_attack_state_custom(delta)
	elif posture_broken:
		velocity.x = 0.0
		# Stunned state: no recovery, just wait for execution
		play_boss_animation("stunned")
	else:
		# Recover posture over time if not broken
		posture = max(0.0, posture - posture_recovery * delta)
		
		attack_cooldown = max(0.0, attack_cooldown - delta)
		if _should_start_attack():
			_start_normal_attack()
		elif _should_chase_player():
			_update_chase_custom()
		elif _should_hold_player():
			_update_engaged_hold()
		else:
			_update_patrol_custom()
			
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
		
	move_and_slide()
	align_sprite_to_ground()
	stats_changed.emit()

# --- Animation Methods ---
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

func align_sprite_to_ground() -> void:
	if sprite == null:
		return
	sprite.offset = Vector2(
		_horizontal_anchor_for_frame(current_animation, sprite.frame),
		_bottom_gap_for_frame(current_animation, sprite.frame)
	)

func _setup_sprite_frames() -> void:
	if sprite == null:
		return
	var frames := SpriteFrames.new()
	for animation in ANIMATION_FRAME_SPECS.keys():
		_add_strip_animation_custom(frames, String(animation))
	sprite.sprite_frames = frames

func _add_strip_animation_custom(frames: SpriteFrames, animation: String) -> void:
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

# --- Combat Overrides ---
func receive_player_attack(damage: float, posture_damage: float) -> void:
	if defeated_flag or posture_broken:
		return
	
	_spawn_damage_number(damage)
	health = max(0.0, health - damage)
	
	# Posture damage scale: posture recovers slower as health drops (optional but common)
	var health_ratio := health / max_health
	var effective_posture_damage := posture_damage
	if health_ratio < 0.5:
		effective_posture_damage *= 1.2
	
	posture = math.add_posture(posture, effective_posture_damage)
	
	if posture >= max_posture:
		_break_posture()
		return

	if health <= 0.0:
		_defeat()
	else:
		_trigger_hit_feedback()
		play_boss_animation("hurt")
	stats_changed.emit()

func receive_block_feedback(perfect: bool) -> void:
	if defeated_flag or posture_broken:
		return
	
	# If Player parries Boss, Boss takes large posture damage
	# If Player blocks Boss, Boss takes small posture damage
	var p_damage := normal_attack_parry_posture_damage if perfect else normal_attack_block_posture_damage
	posture = math.add_posture(posture, p_damage)
	
	if posture >= max_posture:
		_break_posture()
	else:
		_interrupt_attack()
		deflect_toggle = not deflect_toggle
		play_boss_animation("deflect1" if deflect_toggle else "deflect2")
		feedback_timer = deflect_feedback_time
		_trigger_parry_feedback(perfect)
	stats_changed.emit()

func _start_normal_attack() -> void:
	is_attack_winding_up = true
	is_attack_active = false
	is_attack_recovering = false
	attack_has_connected = false
	attack_timer = attack_windup_time
	attack_step_timer = attack_step_time
	velocity.x = 0.0
	
	# Perilous attack selection
	current_attack_type = CombatServerScript.AttackType.NORMAL
	if randf() < 0.4:
		current_attack_type = CombatServerScript.AttackType.THRUST if randf() < 0.5 else CombatServerScript.AttackType.SWEEP
	
	if perilous_label != null:
		perilous_label.visible = current_attack_type != CombatServerScript.AttackType.NORMAL
		if perilous_label.visible:
			_set_camera_shake_suppressed(true)
	
	_update_attack_visual_custom(true, false)
	play_boss_animation("thrust" if current_attack_type == CombatServerScript.AttackType.THRUST else "attack")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _update_attack_state_custom(delta: float) -> void:
	velocity.x = 0.0
	if attack_step_timer > 0.0:
		attack_step_timer = max(0.0, attack_step_timer - delta)
		velocity.x = facing * (attack_step_distance / max(attack_step_time, 0.001))
	
	attack_timer -= delta
	_update_attack_visual_custom(true, is_attack_active)
	
	# Logic to transition from Windup to Active
	var transition_to_active := false
	if is_attack_winding_up:
		if (sprite != null and sprite.frame >= attack_hit_frame) or attack_timer <= 0.0:
			transition_to_active = true
	
	if transition_to_active:
		is_attack_winding_up = false
		is_attack_active = true
		attack_timer = attack_active_time
		# NOTIFY HERE: The exact moment the parry window should start
		current_attack_id = _notify_attack_active()
		if perilous_label != null:
			perilous_label.visible = false
		_set_camera_shake_suppressed(false)
		
	if is_attack_active:
		_check_for_hit_connection()
		if attack_timer <= 0.0:
			is_attack_active = false
			is_attack_recovering = true
			attack_timer = attack_recovery_time
	elif is_attack_recovering and attack_timer <= 0.0:
		is_attack_recovering = false
		attack_cooldown = attack_interval
		_update_attack_visual_custom(false, false)
		play_boss_animation("walk")

func _check_for_hit_connection() -> void:
	if attack_has_connected:
		return
	if attack_area == null:
		return
	for body in attack_area.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("receive_enemy_attack"):
			attack_has_connected = true
			body.receive_enemy_attack(attack_damage, attack_posture_damage, self)
			return

func _update_attack_visual_custom(show_visual: bool, active: bool) -> void:
	if attack_visual == null:
		return
	_update_attack_hitbox_custom()
	attack_visual.visible = show_visual
	if not show_visual:
		return
	
	# Adjust visual size based on type
	match current_attack_type:
		CombatServerScript.AttackType.THRUST:
			attack_visual.size = Vector2(attack_range * 1.5, 20)
			attack_visual.position = Vector2(20.0 * facing, -10.0) if facing > 0 else Vector2(-attack_range * 1.5 - 20, -10.0)
		CombatServerScript.AttackType.SWEEP:
			attack_visual.size = Vector2(attack_range * 1.2, 40)
			attack_visual.position = Vector2(20.0 * facing, 10.0) if facing > 0 else Vector2(-attack_range * 1.2 - 20, 10.0)
		_:
			var rect_shape := attack_collision_shape.shape as RectangleShape2D if attack_collision_shape != null else null
			if rect_shape != null:
				var half_size: Vector2 = rect_shape.size * 0.5
				attack_visual.position = attack_area.position - half_size
				attack_visual.size = rect_shape.size
				
	attack_visual.color = Color(1.0, 0.22, 0.08, 0.62) if active else Color(1.0, 0.86, 0.08, 0.48)

func _update_attack_hitbox_custom() -> void:
	if attack_area == null or attack_collision_shape == null:
		return
	attack_area.position = Vector2(20.0 * facing, -36.0)
	var rect_shape := attack_collision_shape.shape as RectangleShape2D
	if rect_shape != null:
		match current_attack_type:
			CombatServerScript.AttackType.THRUST:
				rect_shape.size = Vector2(attack_range * 1.5, 30)
			CombatServerScript.AttackType.SWEEP:
				rect_shape.size = Vector2(attack_range * 1.2, 50)
			_:
				rect_shape.size = Vector2(90.0, 80.0)

func _interrupt_attack() -> void:
	is_attack_winding_up = false
	is_attack_active = false
	is_attack_recovering = false
	attack_has_connected = false
	attack_timer = 0.0
	attack_step_timer = 0.0
	attack_cooldown = attack_interval
	_update_attack_visual_custom(false, false)
	if perilous_label != null:
		perilous_label.visible = false
	_set_camera_shake_suppressed(false)

# --- Movement Custom ---
func _update_patrol_custom() -> void:
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

func _update_chase_custom() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var offset_x: float = player.global_position.x - global_position.x
	facing = sign(offset_x) if not is_zero_approx(offset_x) else facing
	velocity.x = facing * chase_speed
	play_boss_animation("walk")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _should_chase_player() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var distance: float = abs(player.global_position.x - global_position.x)
	return distance <= detection_range and distance > attack_start_distance

func _should_hold_player() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var distance: float = abs(player.global_position.x - global_position.x)
	return distance <= detection_range and distance <= attack_hold_distance

func _update_engaged_hold() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var offset_x: float = player.global_position.x - global_position.x
	velocity.x = 0.0
	if not is_zero_approx(offset_x):
		facing = sign(offset_x)
	play_boss_animation("idle")
	if sprite != null:
		sprite.flip_h = facing < 0.0

func _should_start_attack() -> bool:
	if attack_cooldown > 0.0:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var distance: float = abs(player.global_position.x - global_position.x)
	return distance <= attack_start_distance

func _defeat() -> void:
	defeated_flag = true
	health = 0.0
	posture = max_posture
	set_collision_layer_value(1, false)
	if execute_label != null:
		execute_label.visible = false
	if perilous_label != null:
		perilous_label.visible = false
	_set_camera_shake_suppressed(false)
	play_boss_animation("death")
	defeated.emit()

func reset_combat_state() -> void:
	super()
	is_attack_winding_up = false
	is_attack_active = false
	is_attack_recovering = false
	attack_has_connected = false
	attack_timer = 0.0
	attack_step_timer = 0.0
	feedback_timer = 0.0
	deflect_toggle = false
	if attack_visual != null:
		attack_visual.visible = false
	play_boss_animation("idle")
