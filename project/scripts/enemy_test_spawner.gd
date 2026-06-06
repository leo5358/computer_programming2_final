extends Node2D

const TORCHMAN_SCENE: PackedScene = preload("res://scenes/TorchmanEnemy.tscn")
const WARRIOR_SCENE: PackedScene = preload("res://scenes/WarriorEnemy.tscn")
const ARCHER_SCENE: PackedScene = preload("res://scenes/ArcherEnemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/Boss.tscn")
const AB_FOOTHILL_SCENE: PackedScene = preload("res://scenes/maps/chapter1_ab_foothill_stairs.tscn")
const H_STONE_PLAZA_SCENE: PackedScene = preload("res://scenes/maps/chapter1_h_stone_plaza.tscn")
const BOSS_INTERIOR_SCENE: PackedScene = preload("res://scenes/maps/chapter1_boss_interior_blockout.tscn")
const START_PAGE_SCENE_PATH := "res://scenes/start_page.tscn"
const AB_EXIT_START_X := 15250.0
const AB_EXIT_END_X := 15750.0
const H_STONE_PLAZA_EXIT_START_X := 2700.0
const H_STONE_PLAZA_EXIT_END_X := 3200.0
const H_STONE_PLAZA_SPAWN := Vector2(220, 530.5)
const BOSS_INTERIOR_SPAWN := Vector2(220, 640.5)
const BOSS_INTERIOR_BOSS_SPAWN := Vector2(1050, 640.5)
const TRANSITION_FADE_TIME := 0.45
const INTERACTION_PROMPT_RADIUS := 300.0
const CHECKPOINT_PROMPT_TEXT := "按下F在此處休息(存檔)"
const DOOR_PROMPT_TEXT := "按下F進入"
const INTERACTION_FADE_START_ALPHA := 0.2
const INTERACTION_FADE_TO_BLACK_TIME := 2.0
const INTERACTION_BLACK_HOLD_TIME := 1.0
const HEARTBEAT_DEATH_FADE_START_ALPHA := 0.2
const HEARTBEAT_DEATH_FADE_TIME := 2.0
const AB_EXIT_CENTER := Vector2(15341.0, -383.0)
const AB_EXIT_PROMPT_X_RADIUS := 300.0
const AB_EXIT_INTERACTION_X_RADIUS := 150.0
const H_STONE_PLAZA_EXIT_CENTER := Vector2(2825.16, 257.44)
const H_STONE_PLAZA_EXIT_PROMPT_X_RADIUS := 300.0
const H_STONE_PLAZA_EXIT_INTERACTION_X_RADIUS := 150.0
const MAP_CLIMB_BOUNDS := {
	"ab_foothill": Vector2(0.0, 15600.0),
	"h_stone_plaza": Vector2(0.0, 3000.0),
	"boss_interior": Vector2(0.0, 2000.0),
}

var spawn_offsets: Dictionary = {
	KEY_7: Vector2(360, 360),
	KEY_8: Vector2(460, 360),
	KEY_9: Vector2(620, 360),
	KEY_0: Vector2(820, 360),
}
var current_map_id := "ab_foothill"
var is_transitioning := false
var is_pause_menu_open := false
var bgm_volume_before_pause := 0.0

@onready var interaction_prompt: Label = $MapTransitionUI/PromptLabel
@onready var fade_rect: ColorRect = $MapTransitionUI/FadeRect
@onready var bgm_player: Node = get_node_or_null("BgmPlayer")
@onready var death_overlay: CanvasLayer = get_node_or_null("DeathOverlay")
@onready var revive_overlay: CanvasLayer = get_node_or_null("ReviveOverlay")
@onready var pause_overlay: CanvasLayer = get_node_or_null("PauseOverlay")

func _ready() -> void:
	add_to_group("enemy_test_spawner")
	interaction_prompt.visible = false
	fade_rect.visible = false
	fade_rect.color = Color(0, 0, 0, 0)
	_play_start_page_fade_in_if_needed()
	_check_for_saved_game_load()
	_apply_current_map_climb_bounds()
	_update_map_bgm()
	_connect_player_death_signal()
	_connect_death_overlay()
	_connect_revive_overlay()
	_connect_pause_overlay()
	if _should_spawn_default_boss_for_current_run():
		_spawn_enemy(BOSS_SCENE, spawn_offsets[KEY_0])

func _check_for_saved_game_load() -> void:
	if not get_tree().has_meta("load_from_save"):
		return
	
	get_tree().remove_meta("load_from_save")
	if not has_node("/root/SaveManager"):
		return
		
	var sm = get_node("/root/SaveManager")
	if not sm.has_save():
		return
		
	var saved_map = sm.get_saved_map()
	var saved_pos = sm.get_saved_position()
	var saved_health = sm.get_saved_health()
	
	# Handle map loading if not the default one
	if saved_map == "h_stone_plaza":
		_switch_map(H_STONE_PLAZA_SCENE, "h_stone_plaza", saved_pos)
	elif saved_map == "boss_interior":
		_switch_map(BOSS_INTERIOR_SCENE, "boss_interior", saved_pos)
	else:
		current_map_id = "ab_foothill"
	_restore_player_save_state(saved_pos, saved_health)
	if saved_map == "boss_interior":
		_spawn_boss_for_boss_interior()
	_sync_checkpoints_to_saved_position(saved_map, saved_pos)

func _process(_delta: float) -> void:
	_update_map_interaction_prompt()

func _should_spawn_default_boss_for_current_run() -> bool:
	for argument in OS.get_cmdline_args():
		if argument.ends_with("test_boss_attack.gd") or argument.ends_with("test_boss_runtime.gd") or argument.ends_with("test_combat_runtime.gd") or argument.ends_with("test_hurtbox_debug_overlay.gd"):
			return true
	return false

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	match event.keycode:
		KEY_ESCAPE:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()
		KEY_7:
			_spawn_enemy(TORCHMAN_SCENE, spawn_offsets[KEY_7])
			get_viewport().set_input_as_handled()
		KEY_8:
			_spawn_enemy(WARRIOR_SCENE, spawn_offsets[KEY_8])
			get_viewport().set_input_as_handled()
		KEY_9:
			_spawn_enemy(ARCHER_SCENE, spawn_offsets[KEY_9])
			get_viewport().set_input_as_handled()
		KEY_0:
			_spawn_debug_boss()
			get_viewport().set_input_as_handled()
		KEY_O:
			_debug_warp_to_boss_interior()
			get_viewport().set_input_as_handled()
		KEY_N:
			_debug_kill_player()
			get_viewport().set_input_as_handled()
		KEY_F:
			if _can_activate_checkpoint():
				_activate_nearest_checkpoint()
				get_viewport().set_input_as_handled()
			elif _can_use_ab_exit():
				_transition_ab_to_h_stone_plaza()
				get_viewport().set_input_as_handled()
			elif _can_use_h_stone_plaza_exit():
				_transition_h_stone_plaza_to_boss_interior()
				get_viewport().set_input_as_handled()
		KEY_F5:
			reset_test_field()
			get_viewport().set_input_as_handled()

func reset_test_field() -> void:
	clear_test_enemies()
	call_deferred("_respawn_map_enemies")
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("reset_combat_state"):
		player.reset_combat_state()

func _debug_kill_player() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("force_death_for_debug"):
		player.force_death_for_debug()

func _spawn_debug_boss() -> void:
	var boss := _spawn_enemy(BOSS_SCENE, spawn_offsets[KEY_0])
	if boss != null:
		boss.set("debug_fixed_attack_profile_boss", "chop")

func _connect_player_death_signal() -> void:
	var player: Node = _get_player()
	var callback := Callable(self, "_on_player_died")
	if player != null and player.has_signal("died") and not player.is_connected("died", callback):
		player.connect("died", callback)
	var revive_callback := Callable(self, "_on_player_revive_prompt_requested")
	if player != null and player.has_signal("revive_prompt_requested") and not player.is_connected("revive_prompt_requested", revive_callback):
		player.connect("revive_prompt_requested", revive_callback)

func _connect_death_overlay() -> void:
	if death_overlay == null:
		return
	var retry_callback := Callable(self, "_retry_from_checkpoint")
	var menu_callback := Callable(self, "_return_to_start_page")
	if death_overlay.has_signal("retry_requested") and not death_overlay.is_connected("retry_requested", retry_callback):
		death_overlay.connect("retry_requested", retry_callback)
	if death_overlay.has_signal("main_menu_requested") and not death_overlay.is_connected("main_menu_requested", menu_callback):
		death_overlay.connect("main_menu_requested", menu_callback)

func _connect_revive_overlay() -> void:
	if revive_overlay == null:
		return
	var revive_callback := Callable(self, "_revive_player_in_place")
	var give_up_callback := Callable(self, "_give_up_from_revive")
	if revive_overlay.has_signal("revive_requested") and not revive_overlay.is_connected("revive_requested", revive_callback):
		revive_overlay.connect("revive_requested", revive_callback)
	if revive_overlay.has_signal("give_up_requested") and not revive_overlay.is_connected("give_up_requested", give_up_callback):
		revive_overlay.connect("give_up_requested", give_up_callback)

func _connect_pause_overlay() -> void:
	if pause_overlay == null:
		return
	var resume_callback := Callable(self, "_resume_from_pause")
	var save_menu_callback := Callable(self, "_save_and_return_to_start_page")
	if pause_overlay.has_signal("resume_requested") and not pause_overlay.is_connected("resume_requested", resume_callback):
		pause_overlay.connect("resume_requested", resume_callback)
	if pause_overlay.has_signal("save_and_menu_requested") and not pause_overlay.is_connected("save_and_menu_requested", save_menu_callback):
		pause_overlay.connect("save_and_menu_requested", save_menu_callback)

func _toggle_pause_menu() -> void:
	if is_pause_menu_open:
		_resume_from_pause()
	else:
		_open_pause_menu()

func _open_pause_menu() -> void:
	if pause_overlay == null or is_transitioning or _is_death_overlay_active() or _is_revive_overlay_active():
		return
	if bgm_player is AudioStreamPlayer:
		var player_bgm := bgm_player as AudioStreamPlayer
		bgm_volume_before_pause = player_bgm.volume_db
		player_bgm.volume_db = bgm_volume_before_pause - 8.0
	is_pause_menu_open = true
	if pause_overlay.has_method("show_pause"):
		pause_overlay.show_pause()
	get_tree().paused = true

func _resume_from_pause() -> void:
	if not is_pause_menu_open:
		return
	get_tree().paused = false
	is_pause_menu_open = false
	if bgm_player is AudioStreamPlayer:
		(bgm_player as AudioStreamPlayer).volume_db = bgm_volume_before_pause
	if pause_overlay != null and pause_overlay.has_method("hide_pause"):
		pause_overlay.hide_pause()

func _save_and_return_to_start_page() -> void:
	_save_current_checkpoint_progress()
	_resume_from_pause()
	call_deferred("_finish_save_and_return_to_start_page")

func _finish_save_and_return_to_start_page() -> void:
	clear_test_enemies()
	_set_player_transition_locked(false)
	get_tree().change_scene_to_file(START_PAGE_SCENE_PATH)

func _save_current_checkpoint_progress() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	if sm.has_save():
		sm.save_game(sm.get_saved_map(), sm.get_saved_position(), sm.get_saved_health())
		return

	var player := _get_player()
	if player == null:
		return
	var save_position := player.global_position
	if "spawn_position" in player:
		save_position = player.spawn_position
	var health := 100.0
	if player.get("health") != null:
		health = float(player.get("health"))
	sm.save_game(current_map_id, save_position, health)

func _is_death_overlay_active() -> bool:
	return death_overlay != null and (death_overlay.visible or bool(death_overlay.get("is_active")))

func _is_revive_overlay_active() -> bool:
	return revive_overlay != null and (revive_overlay.visible or bool(revive_overlay.get("is_active")))

func _on_player_died() -> void:
	if is_pause_menu_open:
		_resume_from_pause()
	var player := _get_player()
	if player != null and player.get("heartbeat_direct_checkpoint_respawn") != null and bool(player.get("heartbeat_direct_checkpoint_respawn")):
		if death_overlay != null and death_overlay.has_method("hide_overlay_immediate"):
			death_overlay.hide_overlay_immediate()
		call_deferred("_run_heartbeat_death_respawn")
		return
	_set_player_transition_locked(true)
	if death_overlay != null and death_overlay.has_method("show_death"):
		death_overlay.show_death()

func _on_player_revive_prompt_requested() -> void:
	if is_pause_menu_open:
		_resume_from_pause()
	is_transitioning = true
	_set_player_transition_locked(true)
	var player := _get_player()
	await _await_player_death_animation(player)
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("is_waiting_for_revive") and not player.is_waiting_for_revive():
		return
	if revive_overlay != null and revive_overlay.has_method("show_revive_prompt"):
		revive_overlay.show_revive_prompt()

func _await_player_death_animation(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("has_completed_death_animation") and player.has_completed_death_animation():
		return
	if player.has_signal("death_animation_finished"):
		await player.death_animation_finished

func _run_heartbeat_death_respawn() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	interaction_prompt.visible = false
	_set_player_transition_locked(true)
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, HEARTBEAT_DEATH_FADE_START_ALPHA)
	await _fade_to(1.0, HEARTBEAT_DEATH_FADE_TIME)
	if death_overlay != null and death_overlay.has_method("show_death"):
		death_overlay.show_death()

func _retry_from_checkpoint() -> void:
	if death_overlay != null and death_overlay.has_method("hide_overlay_immediate"):
		death_overlay.hide_overlay_immediate()
	if revive_overlay != null and revive_overlay.has_method("hide_overlay_immediate"):
		revive_overlay.hide_overlay_immediate()
	var respawn := _get_respawn_snapshot()
	clear_test_enemies()
	_switch_map(_scene_for_map_id(String(respawn["map_id"])), String(respawn["map_id"]), respawn["position"])
	if String(respawn["map_id"]) == "boss_interior":
		_spawn_boss_for_boss_interior()
	_reset_player_after_respawn(respawn["position"], float(respawn["health"]))
	_sync_checkpoints_to_saved_position(String(respawn["map_id"]), respawn["position"])
	_restart_map_bgm(String(respawn["map_id"]))
	_clear_fade()
	_set_player_transition_locked(false)
	is_transitioning = false

func _return_to_start_page() -> void:
	get_tree().paused = false
	is_pause_menu_open = false
	clear_test_enemies()
	_set_player_transition_locked(false)
	if death_overlay != null and death_overlay.has_method("hide_overlay_immediate"):
		death_overlay.hide_overlay_immediate()
	if revive_overlay != null and revive_overlay.has_method("hide_overlay_immediate"):
		revive_overlay.hide_overlay_immediate()
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		if sm.has_method("delete_save"):
			sm.delete_save()
	get_tree().change_scene_to_file(START_PAGE_SCENE_PATH)

func _get_respawn_snapshot() -> Dictionary:
	var player := _get_player()
	var spawn := Vector2(430, 571)
	var health := 100.0
	if player != null:
		spawn = player.spawn_position if "spawn_position" in player else player.global_position
		health = float(player.get("max_health")) if player.get("max_health") != null else health

	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		if sm.has_save():
			return {
				"map_id": sm.get_saved_map(),
				"position": sm.get_saved_position(),
				"health": health,
			}
	return {
		"map_id": current_map_id,
		"position": spawn,
		"health": health,
	}

func _scene_for_map_id(map_id: String) -> PackedScene:
	match map_id:
		"h_stone_plaza":
			return H_STONE_PLAZA_SCENE
		"boss_interior":
			return BOSS_INTERIOR_SCENE
		_:
			return AB_FOOTHILL_SCENE

func _reset_player_after_respawn(spawn: Vector2, health: float) -> void:
	var player := _get_player()
	if player == null:
		return
	if "spawn_position" in player:
		player.spawn_position = spawn
	if player.has_method("reset_combat_state"):
		player.reset_combat_state()
	player.global_position = spawn
	if player.get("max_health") != null:
		health = clamp(health, 1.0, float(player.get("max_health")))
	else:
		health = max(1.0, health)
	if player.get("health") != null:
		player.set("health", health)
	if player.get("max_lives") != null and player.get("lives") != null:
		player.set("lives", int(player.get("max_lives")))
	if player.has_signal("stats_changed"):
		player.emit_signal("stats_changed")

func _restore_player_save_state(spawn: Vector2, health: float) -> void:
	var player := _get_player()
	if player == null:
		return
	player.global_position = spawn
	_apply_current_map_climb_bounds()
	if "spawn_position" in player:
		player.spawn_position = spawn
	if player.get("health") != null:
		player.set("health", health)
	if player.has_signal("stats_changed"):
		player.emit_signal("stats_changed")

func clear_test_enemies() -> void:
	for group_name in ["minor_enemy", "boss"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if node != null and node != self:
				node.queue_free()

func _respawn_map_enemies() -> void:
	for spawn_point in get_tree().get_nodes_in_group("enemy_spawn_point"):
		if spawn_point != null and spawn_point.has_method("respawn_enemy"):
			spawn_point.respawn_enemy()

func _spawn_enemy(scene: PackedScene, spawn_position: Vector2) -> Node:
	var instance: Node = scene.instantiate()
	add_child(instance)
	if instance is Node2D:
		instance.global_position = spawn_position
		if "spawn_position" in instance:
			instance.spawn_position = spawn_position
	return instance

func _update_map_interaction_prompt() -> void:
	if interaction_prompt == null:
		return
	if is_transitioning:
		interaction_prompt.visible = false
		return
	var prompt_target := _current_prompt_target()
	if prompt_target.is_empty():
		interaction_prompt.visible = false
		return
	interaction_prompt.text = String(prompt_target.get("text", ""))
	interaction_prompt.visible = true
	_position_prompt_on_screen(prompt_target.get("anchor", Vector2.ZERO))

func _can_activate_checkpoint() -> bool:
	return _nearest_checkpoint() != null

func _activate_nearest_checkpoint() -> bool:
	var checkpoint := _nearest_checkpoint()
	if checkpoint == null:
		return false
	var player := _get_player()
	if player == null:
		return false
	await _rest_at_checkpoint(checkpoint)
	return true

func _nearest_checkpoint() -> Node:
	var player := _get_player()
	if player == null:
		return null
	var nearest: Node = null
	var nearest_distance := INF
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if checkpoint == null or not checkpoint.has_method("is_player_in_range"):
			continue
		if not checkpoint.is_player_in_range(player):
			continue
		var checkpoint_node := checkpoint as Node2D
		if checkpoint_node == null:
			continue
		var distance := player.global_position.distance_to(checkpoint_node.global_position)
		if distance < nearest_distance:
			nearest = checkpoint
			nearest_distance = distance
	return nearest

func _nearest_checkpoint_prompt() -> Node:
	var player := _get_player()
	if player == null:
		return null
	var nearest: Node = null
	var nearest_distance := INF
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if checkpoint == null or not checkpoint.has_method("is_player_in_prompt_range"):
			continue
		if not checkpoint.is_player_in_prompt_range(player):
			continue
		var checkpoint_node := checkpoint as Node2D
		if checkpoint_node == null:
			continue
		var distance := player.global_position.distance_to(checkpoint_node.global_position)
		if distance < nearest_distance:
			nearest = checkpoint
			nearest_distance = distance
	return nearest

func _can_use_ab_exit() -> bool:
	if is_transitioning or current_map_id != "ab_foothill":
		return false

	var player: Node2D = _get_player()
	if player == null:
		return false

	return absf(player.global_position.x - AB_EXIT_CENTER.x) <= AB_EXIT_INTERACTION_X_RADIUS

func _can_use_h_stone_plaza_exit() -> bool:
	if is_transitioning or current_map_id != "h_stone_plaza":
		return false

	var player: Node2D = _get_player()
	if player == null:
		return false

	return absf(player.global_position.x - H_STONE_PLAZA_EXIT_CENTER.x) <= H_STONE_PLAZA_EXIT_INTERACTION_X_RADIUS

func _transition_ab_to_h_stone_plaza() -> void:
	await _run_map_transition(H_STONE_PLAZA_SCENE, "h_stone_plaza", H_STONE_PLAZA_SPAWN)

func _transition_h_stone_plaza_to_boss_interior() -> void:
	await _run_map_transition(BOSS_INTERIOR_SCENE, "boss_interior", BOSS_INTERIOR_SPAWN)
	_spawn_boss_for_boss_interior()

func _debug_warp_to_boss_interior() -> void:
	clear_test_enemies()
	await _run_map_transition(BOSS_INTERIOR_SCENE, "boss_interior", BOSS_INTERIOR_SPAWN)
	_spawn_boss_for_boss_interior()

func _sync_checkpoints_to_saved_position(map_id: String, saved_position: Vector2) -> void:
	if map_id != current_map_id:
		return
	var player := _get_player()
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if checkpoint == null:
			continue
		var should_activate := _checkpoint_matches_position(checkpoint, saved_position)
		if should_activate and checkpoint.has_method("activate"):
			checkpoint.activate(player)
		elif not should_activate and checkpoint.has_method("deactivate"):
			checkpoint.deactivate()

func _checkpoint_matches_position(checkpoint: Node, saved_position: Vector2) -> bool:
	var checkpoint_node := checkpoint as Node2D
	if checkpoint_node == null:
		return false
	if checkpoint_node.global_position.distance_to(saved_position) <= 2.0:
		return true
	var respawn_position = checkpoint.get("respawn_position")
	if respawn_position is Vector2 and respawn_position != Vector2.INF:
		return (respawn_position as Vector2).distance_to(saved_position) <= 2.0
	return false

func _spawn_boss_for_boss_interior() -> void:
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss != null and not boss.is_queued_for_deletion():
			return
	_spawn_enemy(BOSS_SCENE, BOSS_INTERIOR_BOSS_SPAWN)

func _run_map_transition(next_scene: PackedScene, next_map_id: String, player_spawn: Vector2) -> void:
	is_transitioning = true
	interaction_prompt.visible = false
	_set_player_transition_locked(true)
	_begin_interaction_fade()
	await _fade_to(1.0, INTERACTION_FADE_TO_BLACK_TIME)
	_switch_map(next_scene, next_map_id, player_spawn)
	var player := _get_player()
	if player != null and player.has_method("settle_world_interaction"):
		player.settle_world_interaction(player_spawn)
	await get_tree().process_frame
	await get_tree().create_timer(INTERACTION_BLACK_HOLD_TIME).timeout
	_clear_fade()
	_set_player_transition_locked(false)
	is_transitioning = false

func _fade_to(alpha: float, duration: float = TRANSITION_FADE_TIME) -> void:
	fade_rect.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", alpha, duration)
	await tween.finished
	if alpha <= 0.0:
		fade_rect.visible = false

func _play_start_page_fade_in_if_needed() -> void:
	if not get_tree().has_meta("fade_in_from_start_page"):
		return

	get_tree().remove_meta("fade_in_from_start_page")
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, 1)
	_fade_to(0.0, TRANSITION_FADE_TIME)

func _switch_map(next_scene: PackedScene, next_map_id: String, player_spawn: Vector2) -> void:
	var old_map: Node = get_node_or_null("Chapter1Map")
	if old_map != null:
		remove_child(old_map)
		old_map.queue_free()

	var player: Node2D = _get_player()
	var new_map: Node = next_scene.instantiate()
	add_child(new_map)
	new_map.name = "Chapter1Map"
	current_map_id = next_map_id
	if player != null:
		move_child(new_map, player.get_index())
		player.global_position = player_spawn
		_apply_current_map_climb_bounds()
		if "spawn_position" in player:
			player.spawn_position = player_spawn
	_update_map_bgm()

func _update_map_bgm() -> void:
	if bgm_player != null and bgm_player.has_method("set_map_bgm"):
		bgm_player.set_map_bgm(current_map_id)

func _restart_map_bgm(map_id: String) -> void:
	if bgm_player != null and bgm_player.has_method("restart_map_bgm"):
		bgm_player.restart_map_bgm(map_id)
	elif bgm_player != null and bgm_player.has_method("set_map_bgm"):
		bgm_player.set_map_bgm(map_id)

func _apply_current_map_climb_bounds() -> void:
	var player := _get_player()
	if player == null or not player.has_method("set_map_climb_bounds"):
		return
	if not MAP_CLIMB_BOUNDS.has(current_map_id):
		if player.has_method("clear_map_climb_bounds"):
			player.clear_map_climb_bounds()
		return
	var bounds: Vector2 = MAP_CLIMB_BOUNDS[current_map_id]
	player.set_map_climb_bounds(bounds.x, bounds.y)

func _set_player_transition_locked(is_locked: bool) -> void:
	var player: Node2D = _get_player()
	if player == null:
		return

	player.set_physics_process(not is_locked)
	if player is CharacterBody2D:
		var character: CharacterBody2D = player as CharacterBody2D
		character.velocity = Vector2.ZERO

func _get_player() -> Node2D:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player is Node2D:
		return player as Node2D
	return null

func _rest_at_checkpoint(checkpoint: Node) -> void:
	var player := _get_player()
	if player == null or checkpoint == null:
		return
	is_transitioning = true
	interaction_prompt.visible = false
	_set_player_transition_locked(true)
	_begin_interaction_fade()
	await _fade_to(1.0, INTERACTION_FADE_TO_BLACK_TIME)
	var rest_position := player.global_position
	if checkpoint.has_method("get_rest_position"):
		rest_position = checkpoint.get_rest_position()
	elif checkpoint is Node2D:
		rest_position = (checkpoint as Node2D).global_position
	if checkpoint.has_method("activate"):
		checkpoint.activate(player)
	if player.has_method("settle_world_interaction"):
		player.settle_world_interaction(rest_position, true)
	elif "spawn_position" in player:
		player.spawn_position = rest_position
		player.global_position = rest_position
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		sm.save_game(current_map_id, rest_position, player.health)
	clear_test_enemies()
	await get_tree().process_frame
	_respawn_map_enemies()
	await get_tree().create_timer(INTERACTION_BLACK_HOLD_TIME).timeout
	_clear_fade()
	_set_player_transition_locked(false)
	is_transitioning = false

func _begin_interaction_fade() -> void:
	fade_rect.visible = true
	fade_rect.color = Color(0, 0, 0, INTERACTION_FADE_START_ALPHA)

func _clear_fade() -> void:
	if fade_rect == null:
		return
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.visible = false

func _revive_player_in_place() -> void:
	var player := _get_player()
	if player == null:
		return
	if revive_overlay != null and revive_overlay.has_method("hide_overlay_immediate"):
		revive_overlay.hide_overlay_immediate()
	if player.has_method("revive_in_place"):
		player.revive_in_place()
	is_transitioning = false
	_set_player_transition_locked(false)

func _give_up_from_revive() -> void:
	_retry_from_checkpoint()

func _position_prompt_on_screen(anchor_value: Variant) -> void:
	if interaction_prompt == null or get_viewport() == null:
		return
	var anchor: Vector2 = anchor_value
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * anchor
	interaction_prompt.reset_size()
	interaction_prompt.position = screen_position - Vector2(interaction_prompt.size.x * 0.5, interaction_prompt.size.y)

func _current_prompt_target() -> Dictionary:
	var best_target := {}
	var best_distance := INF
	var checkpoint := _nearest_checkpoint_prompt()
	if checkpoint != null:
		var checkpoint_anchor: Vector2 = (checkpoint as Node2D).global_position
		if checkpoint.has_method("get_prompt_anchor_position"):
			checkpoint_anchor = checkpoint.get_prompt_anchor_position()
		var checkpoint_distance: float = _get_player().global_position.distance_to((checkpoint as Node2D).global_position)
		best_target = {
			"text": CHECKPOINT_PROMPT_TEXT,
			"anchor": checkpoint_anchor,
		}
		best_distance = checkpoint_distance
	var door_target := _current_door_prompt_target()
	if not door_target.is_empty() and float(door_target.get("distance", INF)) < best_distance:
		best_target = door_target
	return best_target

func _current_door_prompt_target() -> Dictionary:
	var player := _get_player()
	if player == null:
		return {}
	var anchor := Vector2.ZERO
	match current_map_id:
		"ab_foothill":
			anchor = AB_EXIT_CENTER
		"h_stone_plaza":
			anchor = H_STONE_PLAZA_EXIT_CENTER
		_:
			return {}
	var distance := player.global_position.distance_to(anchor)
	if current_map_id == "ab_foothill":
		if absf(player.global_position.x - AB_EXIT_CENTER.x) > AB_EXIT_PROMPT_X_RADIUS:
			return {}
	elif current_map_id == "h_stone_plaza":
		if absf(player.global_position.x - H_STONE_PLAZA_EXIT_CENTER.x) > H_STONE_PLAZA_EXIT_PROMPT_X_RADIUS:
			return {}
	else:
		if distance > INTERACTION_PROMPT_RADIUS:
			return {}
	return {
		"text": DOOR_PROMPT_TEXT,
		"anchor": anchor,
		"distance": distance,
	}
