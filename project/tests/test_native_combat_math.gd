extends SceneTree

func _initialize() -> void:
	if not ClassDB.class_exists("NativeCombatMath"):
		push_error("NativeCombatMath should be registered by the GDExtension")
		quit(1)
		return

	var math: Object = ClassDB.instantiate("NativeCombatMath")
	_assert_close(math.apply_damage(100.0, 25.0), 75.0, "native damage reduces health")
	_assert_close(math.add_posture(90.0, 20.0), 100.0, "native posture clamps to max")
	_assert_close(math.add_heartbeat(110.0, 20.0), 120.0, "native heartbeat clamps to max")
	_assert_close(math.block_duration_for_heartbeat(65.0), 1.2, "native calm heartbeat allows longer block")
	_assert_close(math.block_duration_for_heartbeat(120.0), 0.35, "native high heartbeat shortens block")
	_assert_close(math.damage_with_adrenaline(20.0, 120.0), 30.0, "native high heartbeat increases damage")
	_assert_close(math.posture_damage_with_adrenaline(20.0, 120.0), 28.0, "native high heartbeat increases posture pressure")
	quit(0)

func _assert_close(actual: float, expected: float, label: String) -> void:
	if abs(actual - expected) > 0.001:
		push_error("%s: expected %.3f, got %.3f" % [label, expected, actual])
		quit(1)
