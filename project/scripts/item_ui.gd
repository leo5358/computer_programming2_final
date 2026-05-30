extends CanvasLayer

const ITEM_ORDER: Array[String] = ["gourd", "kunai", "pill", "capsule", "ash_balls"]
const ITEM_ICON_PATHS := {
	"gourd": "res://assets/items/gourd/gourd.png",
	"kunai": "res://assets/items/kunai/kunai.png",
	"pill": "res://assets/items/pill/pill.png",
	"capsule": "res://assets/items/capsule/capsule.png",
	"ash_balls": "res://assets/items/ash_balls/ash_balls.png",
}

@export var icon_size := Vector2(56, 56)

var player: Node = null
var count_labels: Dictionary = {}

func _ready() -> void:
	layer = 12
	_build_ui()
	call_deferred("_bind_player")

func _process(_delta: float) -> void:
	if player == null:
		_bind_player()
	_update_counts()

func get_display_count(item_id: String) -> int:
	var label := count_labels.get(item_id) as Label
	if label == null:
		return 0
	return int(label.text)

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.anchor_left = 0.0
	root.anchor_top = 1.0
	root.anchor_right = 0.0
	root.anchor_bottom = 1.0
	root.offset_left = 20.0
	root.offset_top = -92.0
	root.offset_right = 520.0
	root.offset_bottom = -20.0
	add_child(root)

	var row := HBoxContainer.new()
	row.name = "ItemRow"
	row.add_theme_constant_override("separation", 12)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(row)

	for item_id in ITEM_ORDER:
		row.add_child(_create_item_slot(item_id))

func _create_item_slot(item_id: String) -> Control:
	var slot := Control.new()
	slot.name = "%sSlot" % item_id.capitalize()
	slot.custom_minimum_size = Vector2(64, 64)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(String(ITEM_ICON_PATHS[item_id])) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = icon_size
	icon.position = Vector2(0, 0)
	slot.add_child(icon)

	var count_label := Label.new()
	count_label.name = "Count"
	count_label.offset_left = 34.0
	count_label.offset_top = 34.0
	count_label.offset_right = 64.0
	count_label.offset_bottom = 64.0
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.text = "10"
	count_label.add_theme_font_size_override("font_size", 22)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	count_label.add_theme_constant_override("shadow_offset_x", 2)
	count_label.add_theme_constant_override("shadow_offset_y", 2)
	slot.add_child(count_label)

	count_labels[item_id] = count_label
	return slot

func _bind_player() -> void:
	var found_player := get_tree().get_first_node_in_group("player")
	if found_player == null or found_player == player:
		return
	player = found_player
	var callback := Callable(self, "_update_counts")
	if player.has_signal("stats_changed") and not player.is_connected("stats_changed", callback):
		player.connect("stats_changed", callback)
	_update_counts()

func _update_counts() -> void:
	if player == null or not player.has_method("get_item_count"):
		return
	for item_id in ITEM_ORDER:
		var label := count_labels.get(item_id) as Label
		if label != null:
			label.text = str(int(player.get_item_count(item_id)))
