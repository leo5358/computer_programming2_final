extends SceneTree

const ENEMY_SCALES := {
	"res://scenes/TorchmanEnemy.tscn": Vector2(1.75, 1.75),
	"res://scenes/WarriorEnemy.tscn": Vector2(1.75, 1.75),
	"res://scenes/ArcherEnemy.tscn": Vector2(1.75, 1.75),
	"res://scenes/Boss.tscn": Vector2(2, 2),
}

func _initialize() -> void:
	for scene_path in ENEMY_SCALES:
		var scene: PackedScene = load(scene_path)
		if scene == null:
			push_error("Enemy scene should load: %s" % scene_path)
			quit(1)
			return

		var instance: Node = scene.instantiate()
		if not instance is Node2D:
			push_error("Enemy scene root should be Node2D: %s" % scene_path)
			quit(1)
			return

		var root := instance as Node2D
		var expected_scale: Vector2 = ENEMY_SCALES[scene_path]
		if not root.scale.is_equal_approx(expected_scale):
			push_error("Enemy scene should use expected scale: %s" % scene_path)
			quit(1)
			return
		instance.queue_free()

	quit(0)
