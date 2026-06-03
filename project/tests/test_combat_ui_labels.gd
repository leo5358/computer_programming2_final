extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main := scene.instantiate()
	get_root().add_child(main)
	await process_frame

	var labels := {
		"HealthLabel": "HP",
		"PostureLabel": "Posture",
		"HeartbeatLabel": "Heartbeat",
		"EnemyPostureLabel": "Enemy Posture",
	}
	for node_name in labels:
		var label := main.get_node_or_null("CombatUI/Panel/VBox/%s" % node_name) as Label
		if label == null:
			push_error("Combat UI should include %s" % node_name)
			quit(1)
			return
		if label.text != labels[node_name]:
			push_error("%s should show '%s'" % [node_name, labels[node_name]])
			quit(1)
			return

	main.queue_free()
	await process_frame
	quit(0)
