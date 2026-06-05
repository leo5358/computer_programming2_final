extends CanvasLayer

@export var bar_width := 800.0
@export var health_height := 12.0
@export var posture_height := 8.0
@export var top_margin := 60.0
@export var back_color := Color(0.1, 0.05, 0.05, 0.6)
@export var health_color := Color(0.85, 0.1, 0.1, 0.9)
@export var posture_color := Color(1.0, 0.8, 0.2, 0.9)

var boss: Node = null
var current_bar_width := 0.0
var root: Control
var name_label: Label
var health_back: ColorRect
var health_fill: ColorRect
var posture_back: ColorRect
var posture_fill: ColorRect

func _ready() -> void:
	layer = 11
	_build_ui()
	_bind_boss()
	_update_layout()
	_update_stats()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_update_layout)

func _process(_delta: float) -> void:
	if boss == null or not is_instance_valid(boss):
		_bind_boss()
	_update_stats()

func _build_ui() -> void:
	root = Control.new()
	root.name = "BossHudRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	name_label = Label.new()
	name_label.name = "BossName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(name_label)

	health_back = ColorRect.new()
	health_back.name = "HealthBack"
	health_back.color = back_color
	root.add_child(health_back)

	health_fill = ColorRect.new()
	health_fill.name = "HealthFill"
	health_fill.color = health_color
	root.add_child(health_fill)

	posture_back = ColorRect.new()
	posture_back.name = "PostureBack"
	posture_back.color = back_color
	root.add_child(posture_back)

	posture_fill = ColorRect.new()
	posture_fill.name = "PostureFill"
	posture_fill.color = posture_color
	root.add_child(posture_fill)

func _bind_boss() -> void:
	var found_boss = get_tree().get_first_node_in_group("boss")
	if found_boss == boss:
		return
	boss = found_boss
	if boss != null:
		name_label.text = boss.get("display_name") if boss.get("display_name") != null else "Corrupted Guardian"
		root.visible = true
	else:
		root.visible = false

func _update_layout() -> void:
	if root == null: return
	var viewport_size = get_viewport().get_visible_rect().size
	var center_x = viewport_size.x * 0.5
	current_bar_width = min(bar_width, max(160.0, viewport_size.x - 48.0))
	
	name_label.position = Vector2(center_x - 300, top_margin - 45)
	name_label.size = Vector2(600, 40)
	
	health_back.position = Vector2(center_x - current_bar_width * 0.5, top_margin)
	health_back.size = Vector2(current_bar_width, health_height)
	health_fill.position = health_back.position
	
	posture_back.position = Vector2(center_x - current_bar_width * 0.5, top_margin + health_height + 4)
	posture_back.size = Vector2(current_bar_width, posture_height)
	posture_fill.position = posture_back.position

func _update_stats() -> void:
	if root == null:
		return
	if boss == null or not is_instance_valid(boss):
		if root != null: root.visible = false
		return
	
	root.visible = not boss.get("defeated_flag") if boss.get("defeated_flag") != null else true
	if not root.visible:
		return
	
	var health = float(boss.get("health")) if boss.get("health") != null else 100.0
	var max_health = float(boss.get("max_health")) if boss.get("max_health") != null else 100.0
	var posture = float(boss.get("posture")) if boss.get("posture") != null else 0.0
	var max_posture = float(boss.get("max_posture")) if boss.get("max_posture") != null else 100.0
	var show_posture := false
	if boss.has_method("is_posture_bar_visible"):
		show_posture = bool(boss.is_posture_bar_visible())
	
	var h_ratio = clamp(health / max(max_health, 1.0), 0.0, 1.0)
	var p_ratio = clamp(posture / max(max_posture, 1.0), 0.0, 1.0)
	
	health_fill.size = Vector2(current_bar_width * h_ratio, health_height)
	posture_fill.size = Vector2(current_bar_width * p_ratio, posture_height)
	posture_back.visible = show_posture
	posture_fill.visible = show_posture
