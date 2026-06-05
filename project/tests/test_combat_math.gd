extends SceneTree

func _initialize() -> void:
	var script := load("res://scripts/combat_math.gd")
	if script == null:
		push_error("combat_math.gd should exist")
		quit(1)
		return

	var math = script.new()
	_assert_close(math.apply_damage(100.0, 25.0), 75.0, "damage reduces health")
	_assert_close(math.add_posture(90.0, 20.0), 100.0, "posture clamps to max")
	_assert_close(math.add_heartbeat(110.0, 20.0), 130.0, "heartbeat still adds normally below cap")
	_assert_close(math.add_heartbeat(240.0, 20.0), 250.0, "heartbeat clamps at the new death threshold")
	_assert_close(math.block_duration_for_heartbeat(70.0), 1.2, "calm heartbeat allows longer block")
	_assert_close(math.block_duration_for_heartbeat(120.0), 0.35, "high heartbeat shortens block")
	_assert_close(math.block_duration_for_heartbeat(250.0), 0.2, "lethal heartbeat barely allows held block")
	_assert_close(math.damage_with_adrenaline(20.0, 109.0), 20.0, "sub-threshold heartbeat keeps base damage")
	_assert_close(math.damage_with_adrenaline(20.0, 110.0), 21.0, "110 heartbeat adds 3 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 130.0), 21.0, "130 heartbeat adds 5 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 160.0), 22.0, "160 heartbeat adds 8 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 180.0), 23.0, "180 heartbeat adds 12 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 200.0), 24.0, "200 heartbeat adds 18 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 210.0), 25.0, "210 heartbeat adds 25 percent and rounds up")
	_assert_close(math.damage_with_adrenaline(20.0, 220.0), 27.0, "220 heartbeat adds 35 percent and rounds up")
	_assert_close(math.posture_damage_with_adrenaline(20.0, 70.0), 20.0, "calm heartbeat keeps posture damage neutral")
	_assert_close(math.posture_damage_with_adrenaline(20.0, 220.0), 20.0, "heartbeat no longer boosts posture damage")
	quit(0)

func _assert_close(actual: float, expected: float, label: String) -> void:
	if abs(actual - expected) > 0.001:
		push_error("%s: expected %.3f, got %.3f" % [label, expected, actual])
		quit(1)
