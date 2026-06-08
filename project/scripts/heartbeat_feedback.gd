extends CanvasLayer

const HEARTBEAT_SFX_PATH := "res://assets/sfx/heartbeat.MP3"
const BLOOD_OVERLAY_PATH := "res://assets/sprites/vfx/blood.png"

@export var min_heartbeat: float = 70.0
@export var max_heartbeat: float = 250.0
@export var visual_start_heartbeat: float = 135.0
@export var audio_start_heartbeat: float = 135.0
@export var max_blood_alpha: float = 1
@export var min_volume_db: float = -24.0
@export var max_volume_db: float = -9.0
@export var replay_check_interval: float = 0.03
@export var camera_shake_start_heartbeat: float = 200.0
@export var camera_shake_amount: float = 3.5
@export var camera_shake_duration: float = 0.06

var player: Node = null
var feedback_camera: Node = null
var root: Control
var blood_overlay: TextureRect
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
	_bind_feedback_camera()
	_update_layout()
	_update_feedback(0.0)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_update_layout):
		get_viewport().size_changed.connect(_update_layout)

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_bind_player()
	if feedback_camera == null or not is_instance_valid(feedback_camera):
		_bind_feedback_camera()
	_update_feedback(delta)

func _build_overlay() -> void:
	root = Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	blood_overlay = TextureRect.new()
	blood_overlay.name = "BloodOverlay"
	blood_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blood_overlay.texture = load(BLOOD_OVERLAY_PATH) as Texture2D
	blood_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blood_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	blood_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	blood_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(blood_overlay)

func _build_audio() -> void:
	heartbeat_sfx = AudioStreamPlayer.new()
	heartbeat_sfx.name = "HeartbeatSfx"
	heartbeat_sfx.stream = load(HEARTBEAT_SFX_PATH) as AudioStream
	heartbeat_sfx.volume_db = min_volume_db
	heartbeat_sfx.pitch_scale = 1.0
	add_child(heartbeat_sfx)

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

func _bind_feedback_camera() -> void:
	feedback_camera = get_tree().get_first_node_in_group("feedback_camera")

func _on_player_stats_changed() -> void:
	if player != null and is_instance_valid(player) and player.get("heartbeat") != null:
		current_heartbeat = float(player.get("heartbeat"))

func _update_layout() -> void:
	if root == null or blood_overlay == null:
		return
	blood_overlay.position = Vector2.ZERO
	blood_overlay.offset_left = 0.0
	blood_overlay.offset_top = 0.0
	blood_overlay.offset_right = 0.0
	blood_overlay.offset_bottom = 0.0

func _update_feedback(delta: float) -> void:
	_on_player_stats_changed()
	var visual_tension: float = _visual_tension_for_heartbeat(current_heartbeat)
	pulse_phase += delta * lerp(4.0, 14.0, visual_tension)
	var pulse: float = 0.74 + sin(pulse_phase) * 0.26
	var alpha: float = max_blood_alpha * visual_tension * lerp(0.72, 1.0, pulse)
	_set_blood_alpha(alpha)
	_update_heartbeat_audio(delta)

func _set_blood_alpha(alpha: float) -> void:
	if blood_overlay == null:
		return
	blood_overlay.modulate.a = clamp(alpha, 0.0, max_blood_alpha)

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
			_shake_camera_for_heartbeat()
			heartbeat_timer = _beat_interval_for_heartbeat(current_heartbeat)
		else:
			heartbeat_timer = replay_check_interval

func _shake_camera_for_heartbeat() -> void:
	if current_heartbeat <= camera_shake_start_heartbeat:
		return
	if feedback_camera == null or not is_instance_valid(feedback_camera):
		_bind_feedback_camera()
	if feedback_camera != null and feedback_camera.has_method("shake"):
		feedback_camera.shake(camera_shake_amount, camera_shake_duration)

func _can_play_heartbeat_thump() -> bool:
	return heartbeat_sfx != null and not heartbeat_sfx.playing

func _visual_tension_for_heartbeat(heartbeat: float) -> float:
	return clamp(inverse_lerp(visual_start_heartbeat, max_heartbeat, heartbeat), 0.0, 1.0)

func _audio_tension_for_heartbeat(heartbeat: float) -> float:
	return clamp(inverse_lerp(audio_start_heartbeat, max_heartbeat, heartbeat), 0.0, 1.0)

func _beat_interval_for_heartbeat(heartbeat: float) -> float:
	return 60.0 / max(1.0, heartbeat)
