extends SceneTree

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	if main_scene == null or warrior_scene == null or boss_scene == null:
		push_error("Main, Warrior, and Boss scenes should load")
		quit(1)
		return

	var main: Node = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	var combat_ui := main.get_node_or_null("CombatUI") as CanvasLayer
	if combat_ui == null or combat_ui.visible:
		push_error("Old left-top CombatUI debug panel should be hidden")
		quit(1)
		return
	main.queue_free()
	await process_frame

	var root := Node2D.new()
	get_root().add_child(root)
	var warrior = warrior_scene.instantiate()
	root.add_child(warrior)
	await process_frame

	var bars := warrior.get_node_or_null("OverheadBars") as Node2D
	var hp_fill := warrior.get_node_or_null("OverheadBars/HpFill") as ColorRect
	var posture_fill := warrior.get_node_or_null("OverheadBars/PostureFill") as ColorRect
	if bars == null or hp_fill == null or posture_fill == null:
		push_error("Minor enemies should create overhead HP and posture bars")
		quit(1)
		return
	if not bars.visible:
		push_error("Minor enemy overhead bars should be visible while alive")
		quit(1)
		return
	warrior.health = warrior.max_health * 0.5
	warrior.posture = warrior.max_posture * 0.25
	warrior._update_overhead_bars()
	if not is_equal_approx(hp_fill.size.x, warrior.overhead_bar_size.x * 0.5):
		push_error("Enemy HP overhead bar should reflect current health")
		quit(1)
		return
	if not is_equal_approx(posture_fill.size.x, warrior.overhead_bar_size.x * 0.25):
		push_error("Enemy posture overhead bar should reflect current posture")
		quit(1)
		return
	warrior._defeat()
	warrior._update_overhead_bars()
	if bars.visible:
		push_error("Enemy overhead bars should hide after defeat")
		quit(1)
		return

	var boss = boss_scene.instantiate()
	root.add_child(boss)
	await process_frame
	var boss_bars := boss.get_node_or_null("OverheadBars") as Node2D
	if boss_bars != null and boss_bars.visible:
		push_error("Boss should not show minor-enemy overhead bars")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)

