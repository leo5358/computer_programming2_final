extends CanvasLayer

@onready var health_bar: ProgressBar = $Panel/VBox/HealthBar
@onready var posture_bar: ProgressBar = $Panel/VBox/PostureBar
@onready var heartbeat_bar: ProgressBar = $Panel/VBox/HeartbeatBar
@onready var enemy_bar: ProgressBar = $Panel/VBox/EnemyPostureBar
@onready var boss_bar: ProgressBar = $Panel/VBox/BossPostureBar
@onready var message: Label = $Panel/VBox/Message

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var enemy = get_tree().get_first_node_in_group("minor_enemy")
	var boss = get_tree().get_first_node_in_group("boss")

	if player != null:
		health_bar.value = player.health
		posture_bar.value = player.posture
		heartbeat_bar.value = player.heartbeat
		if player.health <= 0.0:
			message.text = "You died. Restart the scene to try again."
		else:
			message.text = "A/D move  Space jump  J attack  K block"

	if enemy != null:
		enemy_bar.value = enemy.posture
		enemy_bar.modulate.a = 0.4 if enemy.defeated_flag else 1.0

	if boss != null:
		boss_bar.value = boss.posture
		boss_bar.modulate.a = 0.4 if boss.defeated_flag else 1.0
		if boss.defeated_flag:
			message.text = "Boss defeated. To be continued."
