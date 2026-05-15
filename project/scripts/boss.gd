extends "res://scripts/enemy.gd"

const BOSS_STRIP_CELL_SIZE := 128
const BOSS_STRIP_PATHS := {
	"idle": "res://assets/sprites/boss/walk.png",
	"walk": "res://assets/sprites/boss/walk.png",
	"attack1": "res://assets/sprites/boss/attack.png",
	"thrust": "res://assets/sprites/boss/thrust.png",
	"chop": "res://assets/sprites/boss/chop.png",
	"deflect1": "res://assets/sprites/boss/defelct1.png",
	"deflect2": "res://assets/sprites/boss/deflect2.png",
	"hurt": "res://assets/sprites/boss/hurt.png",
	"stunned": "res://assets/sprites/boss/hurt.png",
	"death": "res://assets/sprites/boss/death.png",
}
const WALK_FRAME_OFFSETS := [-10.0, -3.0, -0.5, 3.0, 8.5, 13.5, 20.0, 19.0]
const ATTACK_ANIMATION_SPEEDS := {
	"attack1": 16.0,
	"thrust": 18.0,
	"chop": 14.0,
}

enum BossAttack {
	ATTACK1,
	ATTACK2,
	THRUST,
	CHOP,
}

@export var deflect_chance := 0.80
@export var deflect_posture_damage_taken := 0.0
@export var deflect_counter_posture_damage := 18.0
@export var combo_followup_delay := 0.22
@export var attack_hitbox_lead := 58.0
@export var thrust_hitbox_lead := 76.0
@export var chop_hitbox_lead := 48.0
@export var warning_cue_time := 0.40

var current_boss_attack := BossAttack.ATTACK1
var queued_combo_followup := false
var force_combo_followup := false
var combo_followup_timer := 0.0
var forced_animation := ""
var forced_animation_timer := 0.0
var last_player_counter := ""
var attack_has_connected := false

@onready var attack_area_node: Area2D = $AttackArea
@onready var attack_collision_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var debug_response_label: Label = get_node_or_null("DebugResponseLabel") as Label

func _ready() -> void:
	add_to_group("boss")
	display_name = "Boss"
	max_health = 140.0
	max_posture = 100.0
	attack_damage = 18.0
	attack_posture_damage = 32.0
	attack_interval = 1.05
	attack_windup = 1.30
	attack_cue_time = warning_cue_time
	attack_active_time = 0.16
	posture_recovery = 4.0
	attack_range = 118.0
	detection_range = 420.0
	patrol_distance = 128.0
	patrol_speed = 34.0
	chase_speed = 92.0
	health = max_health
	posture = 0.0
	super()
	if sprite != null:
		var frame_changed_callback := Callable(self, "_on_sprite_frame_changed")
		if not sprite.frame_changed.is_connected(frame_changed_callback):
			sprite.frame_changed.connect(frame_changed_callback)
	_update_attack_hitbox()
	_update_debug_response_label(false)

func _physics_process(delta: float) -> void:
	if combo_followup_timer > 0.0:
		combo_followup_timer -= delta
		if combo_followup_timer <= 0.0 and not defeated_flag and not posture_broken:
			queued_combo_followup = false
			force_combo_followup = true
			_start_attack_windup()
	super(delta)

func _update_movement(delta: float) -> void:
	super(delta)
	if target != null and not is_winding_up and not is_attack_active and not posture_broken and not defeated_flag:
		var distance := global_position.distance_to(target.global_position)
		if distance > detection_range:
			attack_cooldown = max(attack_cooldown, 0.35)

func _update_attack_state(delta: float) -> void:
	if is_winding_up:
		windup_timer -= delta
		_update_countdown_label()
		if windup_timer <= attack_cue_time and not is_attack_cue_active:
			_start_attack_cue()
		if _should_connect_attack():
			_connect_attack_on_hit_frame()
		elif windup_timer <= 0.0 and not attack_has_connected:
			_connect_attack_on_hit_frame()

	if is_attack_active:
		active_timer -= delta
		if active_timer <= 0.0:
			is_attack_active = false
			attack_visual.visible = false
			attack_cooldown = attack_interval
			if sprite != null:
				sprite.speed_scale = 1.0
			attack_has_connected = false

func _start_attack_windup() -> void:
	if force_combo_followup:
		current_boss_attack = BossAttack.ATTACK2
		force_combo_followup = false
	else:
		current_boss_attack = _choose_next_attack()
	is_winding_up = true
	is_attack_cue_active = false
	is_attack_active = false
	attack_has_connected = false
	velocity.x = 0.0
	windup_timer = _windup_for_current_attack()
	_update_attack_hitbox()
	_update_debug_response_label(false)
	if countdown_label != null:
		countdown_label.visible = true
	_update_countdown_label()
	_update_visuals()
	_start_slow_attack_animation()

func _choose_next_attack() -> int:
	var distance := 9999.0
	if target != null:
		distance = global_position.distance_to(target.global_position)

	var phase := 1
	if health <= max_health * 0.30:
		phase = 3
	elif health <= max_health * 0.60:
		phase = 2

	var roll := randi() % 100
	if last_player_counter == "parry" and roll < 42:
		return BossAttack.THRUST
	if last_player_counter == "dodge" and roll < 42:
		return BossAttack.CHOP
	if distance > attack_range * 1.15 and roll < 65:
		return BossAttack.THRUST
	if phase >= 2 and roll < 25:
		return BossAttack.ATTACK2
	if roll < 50:
		return BossAttack.ATTACK1
	if roll < 75:
		return BossAttack.CHOP
	return BossAttack.THRUST

func _windup_for_current_attack() -> float:
	match current_boss_attack:
		BossAttack.THRUST:
			return 1.20
		BossAttack.CHOP:
			return 1.55
		BossAttack.ATTACK2:
			return 1.05
		_:
			return attack_windup

func _start_attack_cue() -> void:
	is_attack_cue_active = true
	attack_visual.visible = true
	match current_boss_attack:
		BossAttack.THRUST:
			attack_visual.color = Color(1, 0.12, 0.08, 0.72)
		BossAttack.CHOP:
			attack_visual.color = Color(0.55, 0.95, 1.0, 0.72)
		BossAttack.ATTACK2:
			attack_visual.color = Color(1, 0.55, 0.08, 0.68)
		_:
			attack_visual.color = Color(1, 0.88, 0.08, 0.68)
	_update_attack_hitbox()
	_update_debug_response_label(true)
	_update_visuals()

func _release_attack() -> void:
	_connect_attack_on_hit_frame()

func _connect_attack_on_hit_frame() -> void:
	if attack_has_connected:
		return
	attack_has_connected = true
	is_winding_up = false
	is_attack_cue_active = false
	if countdown_label != null:
		countdown_label.visible = false
	_update_debug_response_label(false)
	is_attack_active = true
	active_timer = _active_time_for_current_attack()
	velocity.x = 0.0
	attack_visual.visible = true
	attack_visual.color = Color(1, 0.2, 0.08, 0.62)
	_update_attack_hitbox()
	current_attack_id = _notify_attack_active()
	_apply_attack_to_overlaps()
	if sprite != null:
		sprite.speed_scale = _recovery_speed_for_current_attack()
	if current_boss_attack == BossAttack.ATTACK1 and health <= max_health * 0.60 and randi() % 100 < 45:
		queued_combo_followup = true
		combo_followup_timer = combo_followup_delay
	_update_visuals()

func _should_connect_attack() -> bool:
	if attack_has_connected or sprite == null:
		return false
	if not is_winding_up:
		return false
	return current_animation == _animation_for_current_attack() and sprite.frame >= _hit_frame_for_current_attack()

func _start_slow_attack_animation() -> void:
	if sprite == null:
		return
	var animation := _animation_for_current_attack()
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
		return
	var fps := float(ATTACK_ANIMATION_SPEEDS.get(animation, 16.0))
	var hit_frame := float(_hit_frame_for_current_attack())
	var windup := max(_windup_for_current_attack(), 0.05)
	sprite.speed_scale = clamp(hit_frame / (fps * windup), 0.08, 1.0)
	current_animation = animation
	sprite.play(animation)

func _hit_frame_for_current_attack() -> int:
	match current_boss_attack:
		BossAttack.THRUST:
			return 4
		BossAttack.CHOP:
			return 5
		_:
			return 5

func _recovery_speed_for_current_attack() -> float:
	match current_boss_attack:
		BossAttack.CHOP:
			return 0.55
		BossAttack.THRUST:
			return 0.65
		_:
			return 0.70

func _apply_attack_to_overlaps() -> void:
	if attack_area_node == null:
		return
	for body in attack_area_node.get_overlapping_bodies():
		if body == self:
			continue
		if body.has_method("receive_enemy_attack"):
			body.receive_enemy_attack(attack_damage, attack_posture_damage, self, _combat_attack_type())

func _update_attack_hitbox() -> void:
	if attack_area_node == null or attack_collision_shape == null:
		return
	var lead := attack_hitbox_lead
	var size := Vector2(124.0, 78.0)
	match current_boss_attack:
		BossAttack.THRUST:
			lead = thrust_hitbox_lead
			size = Vector2(152.0, 48.0)
		BossAttack.CHOP:
			lead = chop_hitbox_lead
			size = Vector2(118.0, 98.0)
		BossAttack.ATTACK2:
			lead = attack_hitbox_lead + 8.0
			size = Vector2(132.0, 76.0)
		_:
			pass
	attack_area_node.position = Vector2(lead * facing, -40.0)
	attack_visual.position = Vector2(lead * facing, 0.0)
	var shape := attack_collision_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = size

func _update_debug_response_label(show_label: bool) -> void:
	if debug_response_label == null:
		return
	debug_response_label.visible = show_label
	if not show_label:
		return
	match current_boss_attack:
		BossAttack.THRUST:
			debug_response_label.text = "DODGE"
			debug_response_label.modulate = Color(1.0, 0.35, 0.25, 1.0)
		BossAttack.CHOP:
			debug_response_label.text = "PARRY"
			debug_response_label.modulate = Color(0.55, 0.95, 1.0, 1.0)
		_:
			debug_response_label.text = "BLOCK / PARRY"
			debug_response_label.modulate = Color(1.0, 0.9, 0.35, 1.0)

func _active_time_for_current_attack() -> float:
	if current_boss_attack == BossAttack.CHOP:
		return 0.20
	if current_boss_attack == BossAttack.ATTACK2:
		return 0.15
	return attack_active_time

func _notify_attack_active() -> int:
	if combat_runtime == null:
		combat_runtime = get_tree().get_first_node_in_group("combat_runtime")
	if combat_runtime != null and combat_runtime.has_method("notify_attack_active"):
		return combat_runtime.notify_attack_active(_combat_attack_type(), Time.get_ticks_msec())
	return -1

func _combat_attack_type() -> int:
	match current_boss_attack:
		BossAttack.THRUST:
			return CombatServerScript.AttackType.THRUST
		BossAttack.CHOP:
			return CombatServerScript.AttackType.SWEEP
		_:
			return CombatServerScript.AttackType.NORMAL

func receive_player_attack(damage: float, posture_damage: float):
	if defeated_flag:
		return false
	if posture_broken:
		super(damage, posture_damage)
		return true

	if randf() < deflect_chance:
		posture = math.add_posture(posture, deflect_posture_damage_taken)
		forced_animation = "deflect%d" % (1 + (randi() % 2))
		forced_animation_timer = 0.24
		hit_flash_timer = hit_flash_time
		hit_freeze_timer = hit_freeze_time
		hit_recoil_timer = 0.0
		velocity.x = 0.0
		if target != null and target.has_method("receive_enemy_attack"):
			target.receive_enemy_attack(0.0, deflect_counter_posture_damage, self, CombatServerScript.AttackType.NORMAL)
		_shake_camera(11.0, 0.08)
		_update_feedback(0.0)
		if posture >= max_posture:
			_break_posture()
			return false
		stats_changed.emit()
		return false

	forced_animation = "hurt"
	forced_animation_timer = 0.24
	super(damage, posture_damage)
	return true

func can_be_perfect_dodged_by(player: Node2D) -> bool:
	if current_boss_attack != BossAttack.THRUST:
		return false
	return super(player)

func receive_dodge_feedback() -> void:
	if defeated_flag:
		return
	if current_boss_attack != BossAttack.THRUST:
		return
	last_player_counter = "dodge"
	_interrupt_attack_from_parry()
	_reset_attack_animation_speed()
	super()

func receive_block_feedback(perfect: bool) -> void:
	if defeated_flag:
		return
	if current_boss_attack == BossAttack.CHOP and not perfect:
		return
	last_player_counter = "parry" if perfect else "block"
	if perfect:
		_reset_attack_animation_speed()
	super(perfect)

func _reset_attack_animation_speed() -> void:
	attack_has_connected = false
	is_winding_up = false
	is_attack_cue_active = false
	is_attack_active = false
	attack_visual.visible = false
	_update_debug_response_label(false)
	if countdown_label != null:
		countdown_label.visible = false
	if sprite != null:
		sprite.speed_scale = 1.0

func _setup_sprite_frames() -> void:
	if sprite == null:
		return
	if is_winding_up or is_attack_active:
		return
	var frames := SpriteFrames.new()
	_add_boss_strip_animation(frames, "idle", 6.0, true)
	_add_boss_strip_animation(frames, "walk", 10.0, true)
	_add_boss_strip_animation(frames, "attack1", 16.0, false)
	_add_boss_strip_animation(frames, "thrust", 18.0, false)
	_add_boss_strip_animation(frames, "chop", 14.0, false)
	_add_boss_strip_animation(frames, "deflect1", 18.0, false)
	_add_boss_strip_animation(frames, "deflect2", 18.0, false)
	_add_boss_strip_animation(frames, "hurt", 12.0, false)
	_add_boss_strip_animation(frames, "stunned", 8.0, true)
	_add_boss_strip_animation(frames, "death", 8.0, false)
	sprite.sprite_frames = frames
	sprite.play("idle")

func _add_boss_strip_animation(frames: SpriteFrames, animation: StringName, fps: float, loop: bool) -> void:
	var path := String(BOSS_STRIP_PATHS[String(animation)])
	if not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	if texture == null:
		return
	var frame_count: int = max(1, int(texture.get_width() / BOSS_STRIP_CELL_SIZE))
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	for column in frame_count:
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		var inset := _atlas_inset_for_animation(animation)
		atlas_texture.region = Rect2(column * BOSS_STRIP_CELL_SIZE + inset, 0, BOSS_STRIP_CELL_SIZE - inset * 2.0, BOSS_STRIP_CELL_SIZE)
		atlas_texture.margin = Rect2(inset, 0, BOSS_STRIP_CELL_SIZE - inset * 2.0, BOSS_STRIP_CELL_SIZE)
		atlas_texture.filter_clip = true
		frames.add_frame(animation, atlas_texture)

func _atlas_inset_for_animation(animation: StringName) -> float:
	match String(animation):
		"attack1", "chop", "thrust", "deflect1", "deflect2":
			return 2.0
		_:
			return 1.0

func _update_feedback(delta: float) -> void:
	super(delta)
	forced_animation_timer = max(0.0, forced_animation_timer - delta)
	if forced_animation_timer <= 0.0:
		forced_animation = ""

func _update_visuals() -> void:
	body_visual.visible = sprite == null
	if sprite == null:
		return
	sprite.flip_h = facing < 0.0
	var next_animation := "idle"
	if forced_animation_timer > 0.0 and not forced_animation.is_empty():
		next_animation = forced_animation
	elif defeated_flag:
		next_animation = "death"
	elif posture_broken:
		next_animation = "stunned"
	elif is_attack_active or is_winding_up or is_attack_cue_active:
		next_animation = _animation_for_current_attack()
	elif abs(velocity.x) > 1.0:
		next_animation = "walk"
	_update_attack_hitbox()
	_update_debug_response_label(is_attack_cue_active)
	if current_animation != next_animation:
		current_animation = next_animation
		sprite.play(next_animation)
	_update_sprite_alignment(next_animation)

func _on_sprite_frame_changed() -> void:
	_update_sprite_alignment(current_animation)

func _update_sprite_alignment(animation: String) -> void:
	sprite.offset = Vector2.ZERO
	if animation == "walk" or animation == "idle":
		var frame_index: int = clamp(sprite.frame, 0, WALK_FRAME_OFFSETS.size() - 1)
		sprite.offset.x = WALK_FRAME_OFFSETS[frame_index] * facing

func _animation_for_current_attack() -> String:
	match current_boss_attack:
		BossAttack.ATTACK2:
			return "attack1"
		BossAttack.THRUST:
			return "thrust"
		BossAttack.CHOP:
			return "chop"
		_:
			return "attack1"

func reset_combat_state() -> void:
	queued_combo_followup = false
	force_combo_followup = false
	combo_followup_timer = 0.0
	forced_animation = ""
	forced_animation_timer = 0.0
	last_player_counter = ""
	attack_has_connected = false
	current_boss_attack = BossAttack.ATTACK1
	super()
