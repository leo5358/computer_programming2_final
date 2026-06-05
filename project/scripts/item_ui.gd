extends CanvasLayer

const ATTACK_ITEM_IDS: Array[String] = ["kunai", "ash_balls"]
const HEAL_ITEM_IDS: Array[String] = ["gourd", "pill", "capsule"]
const ITEM_ICON_PATHS := {
	"gourd": "res://assets/items/gourd/gourd.png",
	"kunai": "res://assets/items/kunai/kunai.png",
	"pill": "res://assets/items/pill/pill.png",
	"capsule": "res://assets/items/capsule/capsule.png",
	"ash_balls": "res://assets/items/ash_balls/ash_balls.png",
}

@export var right_margin := 8.0
@export var bottom_margin := 18.0

var player: Node = null
var count_labels: Dictionary = {}
var slot_icons: Dictionary = {}
var slot_frames: Dictionary = {}

func _ready() -> void:
	layer = 12
	_build_ui()
	call_deferred("_bind_player")

func _process(_delta: float) -> void:
	if player == null:
		_bind_player()
	_update_counts()

func get_display_count(item_id: String) -> int:
	if player == null or not player.has_method("get_item_count"):
		return 0
	return int(player.get_item_count(item_id))

func get_visible_item_id(slot_id: String) -> String:
	match slot_id:
		"attack":
			return _get_selected_attack_item_id()
		"heal":
			return _get_selected_heal_item_id()
		_:
			return ""

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.anchor_left = 1.0
	root.anchor_top = 1.0
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var attack_slot := _create_display_slot("AttackSlot", Vector2(96.0, 96.0), Vector2(68.0, 68.0))
	var heal_slot := _create_display_slot("HealSlot", Vector2(70.0, 70.0), Vector2(42.0, 42.0))

	var strip_width := heal_slot.custom_minimum_size.x + attack_slot.custom_minimum_size.x + 10.0
	var strip_height := maxf(heal_slot.custom_minimum_size.y, attack_slot.custom_minimum_size.y)

	var strip := Control.new()
	strip.name = "ItemStrip"
	strip.anchor_left = 1.0
	strip.anchor_top = 1.0
	strip.anchor_right = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_left = -(strip_width + right_margin)
	strip.offset_top = -(strip_height + bottom_margin)
	strip.offset_right = -right_margin
	strip.offset_bottom = -bottom_margin
	root.add_child(strip)

	heal_slot.position = Vector2(0.0, strip_height - heal_slot.custom_minimum_size.y)
	attack_slot.position = Vector2(heal_slot.custom_minimum_size.x + 10.0, strip_height - attack_slot.custom_minimum_size.y)
	strip.add_child(heal_slot)
	strip.add_child(attack_slot)

func _create_display_slot(slot_name: String, slot_size: Vector2, icon_size: Vector2) -> Control:
	var slot := Control.new()
	slot.name = slot_name
	slot.custom_minimum_size = slot_size

	var border := ColorRect.new()
	border.name = "Border"
	border.color = Color(0.92, 0.82, 0.46, 0.95)
	border.position = Vector2.ZERO
	border.size = slot_size
	slot.add_child(border)

	var inner := ColorRect.new()
	inner.name = "InnerMask"
	inner.color = Color(0.0, 0.0, 0.0, 0.94)
	inner.position = Vector2(3.0, 3.0)
	inner.size = slot_size - Vector2(6.0, 6.0)
	slot.add_child(inner)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = icon_size
	icon.position = (slot_size - icon_size) * 0.5
	slot.add_child(icon)

	var count_label := Label.new()
	count_label.name = "Count"
	count_label.offset_left = slot_size.x - 36.0
	count_label.offset_top = slot_size.y - 34.0
	count_label.offset_right = slot_size.x - 6.0
	count_label.offset_bottom = slot_size.y - 4.0
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.text = "10"
	count_label.add_theme_font_size_override("font_size", 22)
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	count_label.add_theme_constant_override("shadow_offset_x", 2)
	count_label.add_theme_constant_override("shadow_offset_y", 2)
	slot.add_child(count_label)

	var slot_id := "attack" if slot_name == "AttackSlot" else "heal"
	count_labels[slot_id] = count_label
	slot_icons[slot_id] = icon
	slot_frames[slot_id] = border
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
	_update_slot("attack", _get_selected_attack_item_id())
	_update_slot("heal", _get_selected_heal_item_id())

func _update_slot(slot_id: String, item_id: String) -> void:
	var icon := slot_icons.get(slot_id) as TextureRect
	if icon != null:
		icon.texture = load(String(ITEM_ICON_PATHS.get(item_id, ""))) as Texture2D
	var count_label := count_labels.get(slot_id) as Label
	if count_label != null:
		count_label.text = str(int(player.get_item_count(item_id)))
	var border := slot_frames.get(slot_id) as ColorRect
	if border != null:
		border.color = Color(0.98, 0.86, 0.36, 1.0) if slot_id == "attack" else Color(0.84, 0.78, 0.48, 0.95)

func _get_selected_attack_item_id() -> String:
	if player != null and player.has_method("get_selected_attack_item_id"):
		return String(player.get_selected_attack_item_id())
	return ATTACK_ITEM_IDS[0]

func _get_selected_heal_item_id() -> String:
	if player != null and player.has_method("get_selected_heal_item_id"):
		return String(player.get_selected_heal_item_id())
	return HEAL_ITEM_IDS[0]
