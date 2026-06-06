extends SceneTree

func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_approx(actual: float, expected: float, message: String) -> bool:
	if not is_equal_approx(actual, expected):
		_fail("%s (expected %.3f, got %.3f)" % [message, expected, actual])
		return false
	return true


func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	var torchman_scene: PackedScene = load("res://scenes/TorchmanEnemy.tscn")
	var archer_scene: PackedScene = load("res://scenes/ArcherEnemy.tscn")
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var arrow_scene: PackedScene = load("res://scenes/Arrow.tscn")
	if player_scene == null or warrior_scene == null or torchman_scene == null or archer_scene == null or boss_scene == null or arrow_scene == null:
		_fail("Combat tuning test should load player, enemy, boss, and arrow scenes")
		return

	var root := Node2D.new()
	get_root().add_child(root)

	var player = player_scene.instantiate()
	var warrior = warrior_scene.instantiate()
	var torchman = torchman_scene.instantiate()
	var archer = archer_scene.instantiate()
	var boss = boss_scene.instantiate()
	var arrow = arrow_scene.instantiate()
	root.add_child(player)
	root.add_child(warrior)
	root.add_child(torchman)
	root.add_child(archer)
	root.add_child(boss)
	root.add_child(arrow)
	await process_frame

	if not _assert_approx(float(player.get("max_health")), 120.0, "Player max health should use the higher soulslike tuning"):
		return
	if not _assert_approx(float(player.get("base_attack_damage")), 13.0, "Player base attack damage should use the new tuning"):
		return
	if not _assert_approx(float(warrior.get("max_health")), 70.0, "Warrior max health should use the new tuning"):
		return
	if not _assert_approx(float(warrior.get("attack_damage")), 26.0, "Warrior attack damage should use the new tuning"):
		return
	if not _assert_approx(float(torchman.get("max_health")), 42.0, "Torchman max health should use the new tuning"):
		return
	if not _assert_approx(float(torchman.get("attack_damage")), 18.0, "Torchman attack damage should use the new tuning"):
		return
	if not _assert_approx(float(archer.get("max_health")), 64.0, "Archer max health should use the new tuning"):
		return
	if not _assert_approx(float(archer.get("attack_damage")), 23.0, "Archer script attack damage should use the new tuning"):
		return
	if not _assert_approx(float(arrow.get("damage")), 23.0, "Archer arrows should use the same tuned damage the player actually receives"):
		return
	if not _assert_approx(float(boss.get("max_health")), 400.0, "Boss max health should use the higher difficulty tuning"):
		return

	for profile_name in ["attack", "chop", "thrust"]:
		boss._apply_attack_profile_boss_internal(profile_name)
		if not _assert_approx(float(boss.get("attack_damage")), 45.0, "Boss %s profile damage should use the new tuning" % profile_name):
			return

	root.queue_free()
	await process_frame
	quit(0)
