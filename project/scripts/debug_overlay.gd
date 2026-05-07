extends CanvasLayer

@export var visible_on_start := false

const CombatServerScript = preload("res://scripts/combat_server.gd")

var combat: RefCounted = CombatServerScript.new()
var runtime: Node

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

func _ready() -> void:
	visible = visible_on_start
	runtime = get_tree().get_first_node_in_group("combat_runtime")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible
	elif event.is_action_pressed("force_bpm"):
		_get_combat_source().force_bpm(200.0)
	elif event.is_action_pressed("reset_combat"):
		_get_combat_source().reset_combat()

func _process(delta: float) -> void:
	if combat == null:
		return

	var update: Dictionary = _get_combat_source().get_combat_update(delta)
	label.text = "\n".join([
		"DEBUG COMBAT",
		"Player HP: %.1f" % update["player_hp"],
		"Player Posture: %.1f" % update["player_posture"],
		"Player BPM: %.1f" % update["player_bpm"],
		"Player State: %d" % update["player_state"],
		"Boss HP: %.1f" % update["boss_hp"],
		"Boss Posture: %.1f" % update["boss_posture"],
		"Boss AI State: %d" % update["boss_ai_state"],
		"Attack ID: %d" % update["current_attack_id"],
		"Last Attack Time: %d" % update["last_attack_timestamp_ms"],
		"Input Buffer: %d" % update["input_buffer_type"],
		"Input Age: %d" % update.get("input_buffer_age", 0),
		"Parry Delta: %d ms" % update["last_parry_delta_ms"],
		"Parry Success: %s" % str(update["is_parry_successful"]),
	])

func _get_combat_source() -> Object:
	if runtime == null:
		runtime = get_tree().get_first_node_in_group("combat_runtime")
	return runtime if runtime != null else combat
