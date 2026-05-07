class_name CombatMath
extends RefCounted

const MIN_HEARTBEAT := 65.0
const MAX_HEARTBEAT := 120.0

var native_math: Object

func _init() -> void:
	if ClassDB.class_exists("NativeCombatMath"):
		native_math = ClassDB.instantiate("NativeCombatMath")

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
	var tension := inverse_lerp(MIN_HEARTBEAT, MAX_HEARTBEAT, clamp(heartbeat, MIN_HEARTBEAT, MAX_HEARTBEAT))
	return lerp(1.2, 0.35, tension)

func damage_with_adrenaline(base_damage: float, heartbeat: float) -> float:
	if native_math != null:
		return native_math.damage_with_adrenaline(base_damage, heartbeat)
	var tension := inverse_lerp(MIN_HEARTBEAT, MAX_HEARTBEAT, clamp(heartbeat, MIN_HEARTBEAT, MAX_HEARTBEAT))
	return base_damage * lerp(1.0, 1.5, tension)
