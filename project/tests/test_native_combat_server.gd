extends SceneTree

func _initialize() -> void:
	if not ClassDB.class_exists("NativeCombatServer"):
		push_error("NativeCombatServer should be registered by the GDExtension")
		quit(1)
		return

	var combat: Object = ClassDB.instantiate("NativeCombatServer")
	combat.reset_combat()
	combat.register_input(1, 900)
	combat.notify_attack_active(24, 0, 1000)

	_assert_bool(combat.is_parry_successful(), true, "native parry succeeds")
	_assert_int(combat.get_last_parry_delta_ms(), -100, "native parry delta")
	_assert_int(combat.get_current_attack_id(), 24, "native attack id")

	var update: Dictionary = combat.get_combat_update(0.0)
	_assert_bool(update["is_parry_successful"], true, "update parry flag")
	_assert_int(update["last_parry_delta_ms"], -100, "update delta")
	_assert_int(update["current_attack_id"], 24, "update attack id")
	quit(0)

func _assert_bool(actual: bool, expected: bool, label: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		quit(1)

func _assert_int(actual: int, expected: int, label: String) -> void:
	if actual != expected:
		push_error("%s: expected %d, got %d" % [label, expected, actual])
		quit(1)
