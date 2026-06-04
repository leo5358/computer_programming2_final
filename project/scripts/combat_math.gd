class_name CombatMath
extends RefCounted

const MIN_HEARTBEAT := 65.0
const ADRENALINE_HEARTBEAT := 120.0
const MAX_HEARTBEAT := 200.0

var native_math: Object

func _init() -> void:
	if ClassDB.class_exists("NativeCombatMath"):
		native_math = ClassDB.instantiate("NativeCombatMath")
		if not _native_math_matches_heartbeat_model():
			native_math = null

func _native_math_matches_heartbeat_model() -> bool:
	if native_math == null:
		return false
	if abs(float(native_math.add_heartbeat(190.0, 20.0)) - MAX_HEARTBEAT) > 0.001:
		return false
	if abs(float(native_math.block_duration_for_heartbeat(MAX_HEARTBEAT)) - 0.2) > 0.001:
		return false
	return true

func apply_damage(current_health: float, damage: float) -> float:
	if native_math != null:
		return native_math.apply_damage(current_health, damage)
	return max(current_health - damage, 0.0)

func add_posture(current_posture: float, amount: float) -> float:
	if native_math != null:
		return native_math.add_posture(current_posture, amount)
	return clamp(current_posture + amount, 0.0, 100.0)

func add_heartbeat(current_heartbeat: float, amount: float) -> float:
	if native_math != null:
		return native_math.add_heartbeat(current_heartbeat, amount)
	return clamp(current_heartbeat + amount, MIN_HEARTBEAT, MAX_HEARTBEAT)

func block_duration_for_heartbeat(heartbeat: float) -> float:
	if native_math != null:
		return native_math.block_duration_for_heartbeat(heartbeat)
	var clamped_heartbeat: float = clamp(heartbeat, MIN_HEARTBEAT, MAX_HEARTBEAT)
	if clamped_heartbeat <= ADRENALINE_HEARTBEAT:
		var tension: float = inverse_lerp(MIN_HEARTBEAT, ADRENALINE_HEARTBEAT, clamped_heartbeat)
		return lerp(1.2, 0.35, tension)
	var danger_tension: float = inverse_lerp(ADRENALINE_HEARTBEAT, MAX_HEARTBEAT, clamped_heartbeat)
	return lerp(0.35, 0.2, danger_tension)

func damage_with_adrenaline(base_damage: float, heartbeat: float) -> float:
	if native_math != null:
		return native_math.damage_with_adrenaline(base_damage, heartbeat)
	var tension: float = inverse_lerp(MIN_HEARTBEAT, ADRENALINE_HEARTBEAT, clamp(heartbeat, MIN_HEARTBEAT, ADRENALINE_HEARTBEAT))
	return base_damage * lerp(1.0, 1.5, tension)

func posture_damage_with_adrenaline(base_posture_damage: float, heartbeat: float) -> float:
	if native_math != null and native_math.has_method("posture_damage_with_adrenaline"):
		return native_math.posture_damage_with_adrenaline(base_posture_damage, heartbeat)
	var tension: float = inverse_lerp(MIN_HEARTBEAT, ADRENALINE_HEARTBEAT, clamp(heartbeat, MIN_HEARTBEAT, ADRENALINE_HEARTBEAT))
	return base_posture_damage * lerp(1.0, 1.4, tension)
