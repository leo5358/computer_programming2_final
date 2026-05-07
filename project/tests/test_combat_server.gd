extends SceneTree

const CombatServerScript = preload("res://scripts/combat_server.gd")

func _initialize() -> void:
	var combat: RefCounted = CombatServerScript.new()
	combat.reset_combat()
	combat.register_input(CombatServerScript.InputType.PARRY, 900)
	combat.notify_attack_active(10, CombatServerScript.AttackType.NORMAL, 1000)

	var update: Dictionary = combat.get_combat_update(0.0)
	_assert_bool(update["is_parry_successful"], true, "fallback parry succeeds")
	_assert_int(update["last_parry_delta_ms"], -100, "fallback parry delta")
	_assert_int(update["current_attack_id"], 10, "fallback attack id")
	_assert_float(update["boss_posture"], 20.0, "fallback boss posture")
	quit(0)

func _assert_bool(actual: bool, expected: bool, label: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		quit(1)

func _assert_int(actual: int, expected: int, label: String) -> void:
	if actual != expected:
		push_error("%s: expected %d, got %d" % [label, expected, actual])
		quit(1)

func _assert_float(actual: float, expected: float, label: String) -> void:
	if abs(actual - expected) > 0.001:
		push_error("%s: expected %.3f, got %.3f" % [label, expected, actual])
		quit(1)
