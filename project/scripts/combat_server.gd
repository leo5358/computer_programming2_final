class_name CombatServer
extends RefCounted

enum EntityState {
	IDLE,
	MOVE,
	ATTACK,
	PARRY,
	BLOCK,
	DASH,
	JUMP,
	HURT,
	STUNNED,
	EXECUTION,
}

enum InputType {
	ATTACK,
	PARRY,
	JUMP,
	DASH,
}

enum AttackType {
	NORMAL,
	THRUST,
	SWEEP,
	GRAB,
}

const BPM_MIN := 65.0
const BPM_MAX := 200.0
const INPUT_BUFFER_MS := 150
const PARRY_EARLY_MS := 100
const PARRY_LATE_MS := 50

var native_server: Object
var player_hp := 100.0
var player_posture := 0.0
var player_bpm := BPM_MIN
var player_state := EntityState.IDLE
var boss_hp := 140.0
var boss_posture := 0.0
var boss_state := EntityState.IDLE
var boss_ai_state := 0
var current_attack_id := -1
var last_attack_timestamp_ms := 0
var last_parry_delta_ms := 0
var _is_parry_successful := false
var input_buffer_type := -1
var input_buffer_timestamp_ms := 0
var attack_processed := false

func _init() -> void:
	if ClassDB.class_exists("NativeCombatServer"):
		native_server = ClassDB.instantiate("NativeCombatServer")
	reset_combat()

func reset_combat() -> void:
	if native_server != null:
		native_server.reset_combat()
		return

	player_hp = 100.0
	player_posture = 0.0
	player_bpm = BPM_MIN
	player_state = EntityState.IDLE
	boss_hp = 140.0
	boss_posture = 0.0
	boss_state = EntityState.IDLE
	boss_ai_state = 0
	current_attack_id = -1
	last_attack_timestamp_ms = 0
	last_parry_delta_ms = 0
	_is_parry_successful = false
	input_buffer_type = -1
	input_buffer_timestamp_ms = 0
	attack_processed = false

func register_input(input_type: int, timestamp_ms: int) -> void:
	if native_server != null:
		native_server.register_input(input_type, timestamp_ms)
		return

	input_buffer_type = input_type
	input_buffer_timestamp_ms = timestamp_ms
	_evaluate_parry()

func notify_attack_active(attack_id: int, attack_type: int, timestamp_ms: int) -> void:
	if native_server != null:
		native_server.notify_attack_active(attack_id, attack_type, timestamp_ms)
		return

	current_attack_id = attack_id
	last_attack_timestamp_ms = timestamp_ms
	attack_processed = false
	_evaluate_parry()

func update_combat(delta: float) -> void:
	if native_server != null:
		native_server.update_combat(delta)
		return

	var recovery_mul: float = max(0.1, 1.0 - player_bpm / 200.0)
	player_posture = clamp(player_posture - 12.0 * recovery_mul * delta, 0.0, 100.0)
	player_bpm = max(BPM_MIN, player_bpm - 8.0 * delta)

func force_bpm(value: float) -> void:
	if native_server != null:
		native_server.force_bpm(value)
		return

	player_bpm = clamp(value, BPM_MIN, BPM_MAX)

func is_parry_successful() -> bool:
	if native_server != null:
		return native_server.is_parry_successful()
	return _is_parry_successful

func set_player_state(state: int) -> void:
	if native_server != null:
		native_server.set_player_state(state)
		return
	player_state = state as EntityState
	_evaluate_parry()

func get_combat_update(delta: float = 0.0) -> Dictionary:
	if native_server != null:
		return native_server.get_combat_update(delta)

	update_combat(delta)
	return {
		"player_hp": player_hp,
		"player_posture": player_posture,
		"player_bpm": player_bpm,
		"player_state": player_state,
		"boss_hp": boss_hp,
		"boss_posture": boss_posture,
		"boss_state": boss_state,
		"boss_ai_state": boss_ai_state,
		"current_attack_id": current_attack_id,
		"last_parry_delta_ms": last_parry_delta_ms,
		"last_attack_timestamp_ms": last_attack_timestamp_ms,
		"input_buffer_type": input_buffer_type,
		"input_buffer_age": max(0, Time.get_ticks_msec() - input_buffer_timestamp_ms),
		"is_parry_successful": is_parry_successful(),
	}

func _evaluate_parry() -> void:
	if input_buffer_type != InputType.PARRY or current_attack_id < 0 or attack_processed:
		return

	last_parry_delta_ms = input_buffer_timestamp_ms - last_attack_timestamp_ms
	if last_parry_delta_ms >= -PARRY_EARLY_MS and last_parry_delta_ms <= PARRY_LATE_MS:
		_is_parry_successful = true
		player_state = EntityState.PARRY
		boss_posture = clamp(boss_posture + 20.0, 0.0, 100.0)
		player_posture = clamp(player_posture + 5.0, 0.0, 100.0)
	else:
		_is_parry_successful = false
		player_state = EntityState.BLOCK
		player_posture = clamp(player_posture + 30.0, 0.0, 100.0)
		boss_posture = clamp(boss_posture + 5.0, 0.0, 100.0)
		player_bpm = clamp(player_bpm + 5.0, BPM_MIN, BPM_MAX)

	attack_processed = true
