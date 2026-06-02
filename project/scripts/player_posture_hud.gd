extends CanvasLayer

const SELECTOR_TEXTURE_PATH := "res://assets/start_page/menu_selector.png"

@export var bar_size := Vector2(400.0, 65.0)
@export var fill_height := 26.0
@export var track_horizontal_padding := 36.0
@export var bottom_margin := 15.0
@export var track_color := Color(0.04, 0.035, 0.03, 0.72)
@export var fill_color := Color(1.0, 0.76, 0.16, 0.92)

var player: Node = null
var root: Control
var frame_rect: TextureRect
var track_rect: ColorRect
var left_fill_rect: ColorRect
var right_fill_rect: ColorRect

func _ready() -> void:
	layer = 12
	_build_ui()
	_bind_player()
	_update_layout()
	_update_posture()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_update_layout):
		get_viewport().size_changed.connect(_update_layout)

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_bind_player()
	_update_posture()

func _build_ui() -> void:
	root = Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	track_rect = ColorRect.new()
	track_rect.name = "Track"
	track_rect.color = track_color
	track_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(track_rect)

	left_fill_rect = ColorRect.new()
	left_fill_rect.name = "LeftFill"
	left_fill_rect.color = fill_color
	left_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left_fill_rect)

	right_fill_rect = ColorRect.new()
	right_fill_rect.name = "RightFill"
	right_fill_rect.color = fill_color
	right_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right_fill_rect)

	frame_rect = TextureRect.new()
	frame_rect.name = "Frame"
	frame_rect.texture = load(SELECTOR_TEXTURE_PATH) as Texture2D
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_rect.rotation_degrees = 0.0
	root.add_child(frame_rect)

func _bind_player() -> void:
	var found_player: Node = get_tree().get_first_node_in_group("player")
	if found_player == player:
		return
	player = found_player
	if player != null and player.has_signal("stats_changed"):
		var callback := Callable(self, "_update_posture")
		if not player.is_connected("stats_changed", callback):
			player.connect("stats_changed", callback)

func _update_layout() -> void:
	if root == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var top_left: Vector2 = Vector2(
		(viewport_size.x - bar_size.x) * 0.5,
		viewport_size.y - bottom_margin - bar_size.y
	)
	frame_rect.size = bar_size
	frame_rect.pivot_offset = frame_rect.size * 0.5
	frame_rect.position = top_left
	var fill_top: float = top_left.y + (bar_size.y - fill_height) * 0.5
	track_rect.position = Vector2(top_left.x + track_horizontal_padding, fill_top)
	track_rect.size = Vector2(max(bar_size.x - track_horizontal_padding * 2.0, 0.0), fill_height)
	_update_posture()

func _update_posture() -> void:
	if left_fill_rect == null or right_fill_rect == null or track_rect == null:
		return
	var max_posture: float = 100.0
	var posture: float = 0.0
	if player != null and is_instance_valid(player):
		if player.get("max_posture") != null:
			max_posture = max(float(player.get("max_posture")), 0.001)
		if player.get("posture") != null:
			posture = float(player.get("posture"))
	var ratio: float = clamp(posture / max_posture, 0.0, 1.0)
	var track_width: float = track_rect.size.x
	var total_width: float = track_width * ratio
	var half_width: float = total_width * 0.5
	var center_x: float = track_rect.position.x + track_width * 0.5
	left_fill_rect.position = Vector2(center_x - half_width, track_rect.position.y)
	left_fill_rect.size = Vector2(half_width, fill_height)
	right_fill_rect.position = Vector2(center_x, track_rect.position.y)
	right_fill_rect.size = Vector2(half_width, fill_height)
