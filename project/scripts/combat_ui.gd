extends CanvasLayer

@onready var health_bar: ProgressBar = get_node_or_null("Panel/VBox/HealthBar")
@onready var posture_bar: ProgressBar = get_node_or_null("Panel/VBox/PostureBar")
@onready var heartbeat_bar: ProgressBar = get_node_or_null("Panel/VBox/HeartbeatBar")
@onready var enemy_bar: ProgressBar = get_node_or_null("Panel/VBox/EnemyPostureBar")
@onready var boss_bar: ProgressBar = get_node_or_null("Panel/VBox/BossPostureBar")
@onready var message: Label = get_node_or_null("Panel/VBox/Message")

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var enemy = get_tree().get_first_node_in_group("minor_enemy")
	var boss = get_tree().get_first_node_in_group("boss")

	if player != null:
		if health_bar != null: health_bar.value = player.health
		if posture_bar != null: posture_bar.value = player.posture
		if heartbeat_bar != null: heartbeat_bar.value = player.heartbeat
		if message != null:
			if player.health <= 0.0:
				message.text = "You died. Restart the scene to try again."
			else:
				message.text = "A/D move  Space jump/climb  J attack  K block/parry  L dash/dodge"

	if enemy != null and enemy_bar != null:
		enemy_bar.value = enemy.posture
		enemy_bar.modulate.a = 0.4 if enemy.defeated_flag else 1.0

	if boss != null:
		if boss_bar != null:
			boss_bar.max_value = boss.max_posture
			boss_bar.value = boss.posture
			boss_bar.modulate.a = 0.4 if boss.defeated_flag else 1.0
		if message != null and boss.defeated_flag:
			message.text = "Boss defeated. To be continued."
