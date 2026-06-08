extends CanvasLayer

const DEATH_ICON_PATH := "res://assets/items/death/death.png"
const HEART_ICON_PATH := "res://assets/items/heart/heart.png"
const MIN_HEARTBEAT := 70.0
const MAX_HEARTBEAT := 250.0

@export var icon_size := Vector2(42.0, 42.0)
@export var heart_size := Vector2(34.0, 34.0)
@export var hp_bar_size := Vector2(230.0, 18.0)
@export var bottom_margin := 16.0
@export var left_margin := 28.0
@export var hp_back_color := Color(0.10, 0.02, 0.018, 0.78)
@export var hp_fill_color := Color(0.86, 0.05, 0.045, 0.95)

var player: Node = null
var root: Control
var life_icons: Array[TextureRect] = []
var hp_back: ColorRect
var hp_fill: ColorRect
var heart_icon: TextureRect
var heartbeat_label: Label
var heartbeat_phase := 0.0

func _ready() -> void:
	layer = 12
	_build_ui()
	_bind_player()
	_update_layout()
	_update_stats(0.0)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_update_layout):
		get_viewport().size_changed.connect(_update_layout)

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_bind_player()
	_update_stats(delta)

func _build_ui() -> void:
	root = Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	for index in 3:
		var icon := TextureRect.new()
		icon.name = "Life%d" % (index + 1)
		icon.texture = load(DEATH_ICON_PATH) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
		life_icons.append(icon)

	hp_back = ColorRect.new()
	hp_back.name = "HpBack"
	hp_back.color = hp_back_color
	hp_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_back)

	hp_fill = ColorRect.new()
	hp_fill.name = "HpFill"
	hp_fill.color = hp_fill_color
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_fill)

	heart_icon = TextureRect.new()
	heart_icon.name = "Heart"
	heart_icon.texture = load(HEART_ICON_PATH) as Texture2D
	heart_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(heart_icon)

	heartbeat_label = Label.new()
	heartbeat_label.name = "HeartbeatValue"
	heartbeat_label.add_theme_font_size_override("font_size", 24)
	heartbeat_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.78, 1.0))
	heartbeat_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	heartbeat_label.add_theme_constant_override("shadow_offset_x", 2)
	heartbeat_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(heartbeat_label)

func _bind_player() -> void:
	var found_player: Node = get_tree().get_first_node_in_group("player")
	if found_player == player:
		return
	player = found_player
	if player != null and player.has_signal("stats_changed"):
		var callback := Callable(self, "_update_stats").bind(0.0)
		if not player.is_connected("stats_changed", callback):
			player.connect("stats_changed", callback)

func _update_layout() -> void:
	if root == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var origin := Vector2(left_margin, viewport_size.y - bottom_margin - 116.0)
	for index in life_icons.size():
		var icon := life_icons[index]
		icon.position = origin + Vector2(index * (icon_size.x + 7.0), 0.0)
		icon.size = icon_size
	hp_back.position = origin + Vector2(0.0, 48.0)
	hp_back.size = hp_bar_size
	hp_fill.position = hp_back.position
	heart_icon.position = origin + Vector2(0.0, 76.0)
	heart_icon.size = heart_size
	heart_icon.pivot_offset = heart_size * 0.5
	heartbeat_label.position = origin + Vector2(42.0, 78.0)
	heartbeat_label.size = Vector2(96.0, 34.0)

func _update_stats(delta: float = 0.0) -> void:
	var lives := 3
	var max_lives := 3
	var health := 100.0
	var max_health := 100.0
	var heartbeat := MIN_HEARTBEAT
	if player != null and is_instance_valid(player):
		if player.get("lives") != null:
			lives = int(player.get("lives"))
		if player.get("max_lives") != null:
			max_lives = int(player.get("max_lives"))
		if player.get("health") != null:
			health = float(player.get("health"))
		if player.get("max_health") != null:
			max_health = max(float(player.get("max_health")), 0.001)
		if player.get("heartbeat") != null:
			heartbeat = float(player.get("heartbeat"))
	for index in life_icons.size():
		life_icons[index].visible = index < min(lives, max_lives)
	var health_ratio: float = clamp(health / max_health, 0.0, 1.0)
	hp_fill.size = Vector2(hp_bar_size.x * health_ratio, hp_bar_size.y)
	var heartbeat_ratio: float = clamp((heartbeat - MIN_HEARTBEAT) / (MAX_HEARTBEAT - MIN_HEARTBEAT), 0.0, 1.0)
	heartbeat_phase += delta * lerp(5.0, 12.0, heartbeat_ratio)
	var pulse: float = 1.0 + sin(heartbeat_phase) * lerp(0.05, 0.16, heartbeat_ratio)
	heart_icon.scale = Vector2(pulse, pulse)
	heartbeat_label.text = str(roundi(heartbeat))
