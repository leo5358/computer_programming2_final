extends SceneTree

func _initialize() -> void:
	if not ClassDB.class_exists("NativeCombatMath"):
		push_error("NativeCombatMath should be registered by the GDExtension")
		quit(1)
		return

	var math: Object = ClassDB.instantiate("NativeCombatMath")
	if not math.has_method("posture_damage_with_adrenaline"):
		push_error("NativeCombatMath should be rebuilt with posture_damage_with_adrenaline binding")
		quit(1)
		return
	_assert_close(math.apply_damage(100.0, 25.0), 75.0, "native damage reduces health")
	_assert_close(math.add_posture(90.0, 20.0), 100.0, "native posture clamps to max")
	_assert_close(math.add_heartbeat(110.0, 20.0), 130.0, "native heartbeat still adds normally below cap")
	_assert_close(math.add_heartbeat(240.0, 20.0), 250.0, "native heartbeat clamps at the new death threshold")
	_assert_close(math.block_duration_for_heartbeat(70.0), 1.2, "native calm heartbeat allows longer block")
	_assert_close(math.block_duration_for_heartbeat(120.0), 0.35, "native high heartbeat shortens block")
	_assert_close(math.block_duration_for_heartbeat(250.0), 0.2, "native lethal heartbeat barely allows held block")
	_assert_close(math.damage_with_adrenaline(20.0, 109.0), 20.0, "native sub-threshold heartbeat keeps base damage")
	_assert_close(math.damage_with_adrenaline(20.0, 110.0), 21.0, "native 110 heartbeat adds 3 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 130.0), 21.0, "native 130 heartbeat adds 5 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 160.0), 22.0, "native 160 heartbeat adds 8 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 180.0), 23.0, "native 180 heartbeat adds 12 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 200.0), 24.0, "native 200 heartbeat adds 18 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 210.0), 25.0, "native 210 heartbeat adds 25 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 220.0), 27.0, "native 220 heartbeat adds 35 percent and rounds up")
	_assert_close(math.posture_damage_with_adrenaline(20.0, 220.0), 20.0, "native heartbeat no longer boosts posture damage")
	quit(0)

func _assert_close(actual: float, expected: float, label: String) -> void:
	if abs(actual - expected) > 0.001:
		push_error("%s: expected %.3f, got %.3f" % [label, expected, actual])
		quit(1)
