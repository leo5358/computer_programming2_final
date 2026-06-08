extends CanvasLayer

const HEARTBEAT_SFX_PATH := "res://assets/sfx/heartbeat.MP3"

@export var min_heartbeat: float = 70.0
@export var max_heartbeat: float = 250.0
@export var visual_start_heartbeat: float = 115.0
@export var audio_start_heartbeat: float = 105.0
@export var edge_thickness: float = 90.0
@export var max_edge_alpha: float = 0.42
@export var min_volume_db: float = -24.0
@export var max_volume_db: float = -9.0
@export var replay_check_interval: float = 0.03

var player: Node = null
var root: Control
var top_edge: ColorRect
var bottom_edge: ColorRect
var left_edge: ColorRect
var right_edge: ColorRect
var heartbeat_sfx: AudioStreamPlayer
var pulse_phase: float = 0.0
var heartbeat_timer: float = 0.0
var current_heartbeat: float = 70.0

func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_overlay()
	_build_audio()
	_bind_player()
	_update_layout()
	_update_feedback(0.0)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_update_layout):
		get_viewport().size_changed.connect(_update_layout)

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_bind_player()
	_update_feedback(delta)

func _build_overlay() -> void:
	root = Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	top_edge = _create_edge("TopEdge")
	bottom_edge = _create_edge("BottomEdge")
	left_edge = _create_edge("LeftEdge")
	right_edge = _create_edge("RightEdge")

func _build_audio() -> void:
	heartbeat_sfx = AudioStreamPlayer.new()
	heartbeat_sfx.name = "HeartbeatSfx"
	heartbeat_sfx.stream = load(HEARTBEAT_SFX_PATH) as AudioStream
	heartbeat_sfx.volume_db = min_volume_db
	heartbeat_sfx.pitch_scale = 1.0
	add_child(heartbeat_sfx)

func _create_edge(edge_name: String) -> ColorRect:
	var edge := ColorRect.new()
	edge.name = edge_name
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.color = Color(0.8, 0.0, 0.0, 0.0)
	root.add_child(edge)
	return edge

func _bind_player() -> void:
	var found_player := get_tree().get_first_node_in_group("player")
	if found_player == player:
		return
	player = found_player
	if player != null and player.has_signal("stats_changed"):
		var callback := Callable(self, "_on_player_stats_changed")
		if not player.is_connected("stats_changed", callback):
			player.connect("stats_changed", callback)
	_on_player_stats_changed()

func _on_player_stats_changed() -> void:
	if player != null and is_instance_valid(player) and player.get("heartbeat") != null:
		current_heartbeat = float(player.get("heartbeat"))

func _update_layout() -> void:
	if root == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	top_edge.position = Vector2.ZERO
	top_edge.size = Vector2(viewport_size.x, edge_thickness)
	bottom_edge.position = Vector2(0.0, viewport_size.y - edge_thickness)
	bottom_edge.size = Vector2(viewport_size.x, edge_thickness)
	left_edge.position = Vector2.ZERO
	left_edge.size = Vector2(edge_thickness, viewport_size.y)
	right_edge.position = Vector2(viewport_size.x - edge_thickness, 0.0)
	right_edge.size = Vector2(edge_thickness, viewport_size.y)

func _update_feedback(delta: float) -> void:
	_on_player_stats_changed()
	var visual_tension: float = _visual_tension_for_heartbeat(current_heartbeat)
	pulse_phase += delta * lerp(4.0, 14.0, visual_tension)
	var pulse: float = 0.74 + sin(pulse_phase) * 0.26
	var alpha: float = max_edge_alpha * visual_tension * lerp(0.72, 1.0, pulse)
	_set_edge_alpha(alpha)
	_update_heartbeat_audio(delta)

func _set_edge_alpha(alpha: float) -> void:
	var color := Color(0.78, 0.0, 0.0, clamp(alpha, 0.0, max_edge_alpha))
	top_edge.color = color
	bottom_edge.color = color
	left_edge.color = color
	right_edge.color = color

func _update_heartbeat_audio(delta: float) -> void:
	var audio_tension: float = _audio_tension_for_heartbeat(current_heartbeat)
	if audio_tension <= 0.0 or heartbeat_sfx == null or heartbeat_sfx.stream == null:
		heartbeat_timer = 0.0
		return
	heartbeat_sfx.volume_db = lerp(min_volume_db, max_volume_db, audio_tension)
	heartbeat_sfx.pitch_scale = 1.0
	heartbeat_timer -= delta
	if heartbeat_timer <= 0.0:
		if _can_play_heartbeat_thump():
			heartbeat_sfx.play()
			heartbeat_timer = _beat_interval_for_heartbeat(current_heartbeat)
		else:
			heartbeat_timer = replay_check_interval

func _can_play_heartbeat_thump() -> bool:
	return heartbeat_sfx != null and not heartbeat_sfx.playing

func _visual_tension_for_heartbeat(heartbeat: float) -> float:
	return clamp(inverse_lerp(visual_start_heartbeat, max_heartbeat, heartbeat), 0.0, 1.0)

func _audio_tension_for_heartbeat(heartbeat: float) -> float:
	return clamp(inverse_lerp(audio_start_heartbeat, max_heartbeat, heartbeat), 0.0, 1.0)

func _beat_interval_for_heartbeat(heartbeat: float) -> float:
	return 60.0 / max(1.0, heartbeat)
