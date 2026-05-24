extends Node

const CombatServerScript = preload("res://scripts/combat_server.gd")

@export var enabled := false
@export var attack_opportunity_range := 76.0
@export var projectile_cut_range := 128.0
@export var action_cooldown_time := 0.04
@export var parry_timing_lead := 0.07
@export var dodge_timing_lead := 0.06
@export var approach_speed := 260.0
@export var preferred_attack_range := 58.0
@export var range_tolerance := 10.0

var action_cooldown := 0.0
var status_label: Label

func _ready() -> void:
	add_to_group("combat_autopilot")
	process_physics_priority = 100
	status_label = get_node_or_null("AutopilotStatus/StatusLabel") as Label
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	if event.keycode == KEY_P or event.is_action_pressed("toggle_autopilot"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	enabled = not enabled
	_update_status()

func set_enabled(value: bool) -> void:
	enabled = value
	_update_status()

func _physics_process(delta: float) -> void:
	action_cooldown = max(0.0, action_cooldown - delta)
	if not enabled:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or _player_is_dead(player):
		return
	var threat := _find_best_threat(player)
	if not threat.is_empty():
		_answer_threat(player, threat)
		return
	if _attack_executable_target(player):
		_set_action_cooldown()
		return
	if _cut_projectile(player):
		_set_action_cooldown()
		return
	if action_cooldown <= 0.0 and _attack_nearest_opening(player):
		return
	_move_to_best_position(player)

func _find_best_threat(player: Node2D) -> Dictionary:
	var best: Dictionary = {}
	for actor in _hostile_actors():
		if not (actor is Node2D):
			continue
		var threat: Dictionary = _read_actor_threat(actor as Node2D, player)
		if threat.is_empty():
			continue
		if best.is_empty() or float(threat["time_to_hit"]) < float(best["time_to_hit"]):
			best = threat
	return best

func _read_actor_threat(actor: Node2D, player: Node2D) -> Dictionary:
	if not _is_actor_attacking(actor):
		return {}
	var cue_start: float = _actor_cue_start(actor)
	var hit_start: float = _actor_hit_start(actor)
	var hit_end: float = _actor_hit_end(actor)
	var elapsed: float = _actor_attack_elapsed(actor)
	if elapsed < cue_start or elapsed > hit_end:
		return {}
	if not _actor_attack_can_reach_player(actor, player):
		return {}
	return {
		"actor": actor,
		"perilous": _actor_attack_is_perilous(actor),
		"time_to_hit": max(0.0, hit_start - elapsed),
		"elapsed": elapsed,
		"hit_start": hit_start,
	}

func _answer_threat(player: Node2D, threat: Dictionary) -> void:
	var actor := threat["actor"] as Node2D
	if actor == null:
		return
	var time_to_hit := float(threat["time_to_hit"])
	if bool(threat["perilous"]):
		if time_to_hit <= dodge_timing_lead and player.has_method("_start_perfect_dodge"):
			player._start_perfect_dodge(actor)
		return
	if time_to_hit <= parry_timing_lead and player.has_method("_start_parry") and _player_can_defend(player):
		player._start_parry()

func _attack_executable_target(player: Node2D) -> bool:
	for actor in _hostile_actors():
		if not (actor is Node2D):
			continue
		if not actor.has_method("can_be_executed") or not actor.can_be_executed():
			continue
		if abs((actor as Node2D).global_position.y - player.global_position.y) > 56.0:
			continue
		if abs((actor as Node2D).global_position.x - player.global_position.x) > attack_opportunity_range:
			continue
		_face_target(player, actor as Node2D)
		if player.has_method("_start_attack"):
			player._start_attack()
		if actor.has_method("execute"):
			actor.execute()
		return true
	return false

func _cut_projectile(player: Node2D) -> bool:
	for projectile in get_tree().get_nodes_in_group("enemy_projectile"):
		if not (projectile is Node2D):
			continue
		var offset := (projectile as Node2D).global_position - player.global_position
		if abs(offset.y) > 48.0 or abs(offset.x) > projectile_cut_range:
			continue
		_face_target(player, projectile as Node2D)
		if player.has_method("_start_attack"):
			player._start_attack()
			return true
	return false

func _attack_nearest_opening(player: Node2D) -> bool:
	var target := _nearest_attackable_target(player)
	if target == null:
		return false
	_face_target(player, target)
	if player.has_method("_can_start_attack") and not player._can_start_attack():
		return false
	if player.has_method("_start_attack"):
		player._start_attack()
		_set_action_cooldown()
		return true
	return false

func _move_to_best_position(player: Node2D) -> void:
	if not _player_can_move(player):
		return
	var target: Node2D = _nearest_living_target(player)
	if target == null:
		return
	var offset: Vector2 = target.global_position - player.global_position
	if abs(offset.y) > 72.0:
		_try_jump_toward_target(player, target)
		return
	var distance: float = abs(offset.x)
	if distance > preferred_attack_range + range_tolerance:
		_face_target(player, target)
		player.velocity.x = sign(offset.x) * approach_speed
	elif distance < preferred_attack_range - range_tolerance:
		player.velocity.x = -sign(offset.x) * approach_speed * 0.65
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, approach_speed * get_physics_process_delta_time())

func _nearest_living_target(player: Node2D) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for actor in _hostile_actors():
		if not (actor is Node2D):
			continue
		if _actor_is_defeated(actor):
			continue
		var distance: float = player.global_position.distance_to((actor as Node2D).global_position)
		if distance < nearest_distance:
			nearest = actor as Node2D
			nearest_distance = distance
	return nearest

func _try_jump_toward_target(player: Node2D, target: Node2D) -> void:
	if target.global_position.y >= player.global_position.y - 32.0:
		return
	if player.has_method("_can_jump") and not player._can_jump():
		return
	if "jump_velocity" in player:
		player.velocity.y = float(player.get("jump_velocity"))

func _nearest_attackable_target(player: Node2D) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for actor in _hostile_actors():
		if not (actor is Node2D):
			continue
		if _actor_is_defeated(actor):
			continue
		var offset: Vector2 = (actor as Node2D).global_position - player.global_position
		var distance: float = abs(offset.x)
		if abs(offset.y) > 56.0 or distance > attack_opportunity_range:
			continue
		if distance < nearest_distance:
			nearest = actor as Node2D
			nearest_distance = distance
	return nearest

func _hostile_actors() -> Array:
	var actors: Array = []
	actors.append_array(get_tree().get_nodes_in_group("enemy"))
	actors.append_array(get_tree().get_nodes_in_group("boss"))
	return actors

func _is_actor_attacking(actor: Node) -> bool:
	if "is_attack_winding_up" in actor and bool(actor.get("is_attack_winding_up")):
		return true
	if "is_attack_active" in actor and bool(actor.get("is_attack_active")):
		return true
	if "state" in actor and "EnemyState" in actor:
		return int(actor.get("state")) == int(actor.EnemyState.ATTACK)
	return false

func _actor_attack_elapsed(actor: Node) -> float:
	if "attack_elapsed" in actor:
		return float(actor.get("attack_elapsed"))
	return 0.0

func _actor_cue_start(actor: Node) -> float:
	if "attack_parry_window_start" in actor:
		return float(actor.get("attack_parry_window_start"))
	if "current_attack_cue_start" in actor:
		return float(actor.get("current_attack_cue_start"))
	if "attack_cue_start" in actor:
		return float(actor.get("attack_cue_start"))
	return 0.0

func _actor_hit_start(actor: Node) -> float:
	if "attack_hit_time" in actor:
		return float(actor.get("attack_hit_time"))
	if "current_attack_hit_start" in actor:
		return float(actor.get("current_attack_hit_start"))
	if "attack_hit_start" in actor:
		return float(actor.get("attack_hit_start"))
	return _actor_cue_start(actor)

func _actor_hit_end(actor: Node) -> float:
	if "attack_hit_window_end" in actor:
		return float(actor.get("attack_hit_window_end"))
	if "current_attack_hit_end" in actor:
		return float(actor.get("current_attack_hit_end"))
	if "attack_hit_end" in actor:
		return float(actor.get("attack_hit_end"))
	return _actor_hit_start(actor)

func _actor_attack_is_perilous(actor: Node) -> bool:
	if actor.has_method("is_current_attack_perilous") and actor.is_current_attack_perilous():
		return true
	if "current_attack_type" in actor and int(actor.get("current_attack_type")) == CombatServerScript.AttackType.THRUST:
		return true
	if "current_attack_profile" in actor and String(actor.get("current_attack_profile")) == "thrust":
		return true
	if "current_attack_animation" in actor and String(actor.get("current_attack_animation")) == "thrust":
		return true
	if "is_perilous_attack" in actor and bool(actor.get("is_perilous_attack")):
		return true
	return false

func _actor_attack_can_reach_player(actor: Node2D, player: Node2D) -> bool:
	var area := actor.get_node_or_null("AttackArea") as Area2D
	if area != null:
		for body in area.get_overlapping_bodies():
			if body == player:
				return true
	var offset: Vector2 = player.global_position - actor.global_position
	var forward: float = _actor_facing(actor) * offset.x
	return forward >= 0.0 and forward <= _fallback_attack_reach(actor) and abs(offset.y) <= 72.0

func _fallback_attack_reach(actor: Node) -> float:
	if "thrust_range" in actor and _actor_attack_is_perilous(actor):
		return max(120.0, float(actor.get("thrust_range")))
	if "attack_start_distance" in actor:
		return float(actor.get("attack_start_distance")) + 48.0
	if "attack_range" in actor:
		return float(actor.get("attack_range")) + 48.0
	return 120.0

func _actor_facing(actor: Node) -> float:
	if "facing" in actor:
		var value: float = float(actor.get("facing"))
		return value if value != 0.0 else 1.0
	return 1.0

func _actor_is_defeated(actor: Node) -> bool:
	return "defeated_flag" in actor and bool(actor.get("defeated_flag"))

func _player_can_defend(player: Node) -> bool:
	if player.has_method("_can_start_defensive_action"):
		return player._can_start_defensive_action()
	return true

func _player_can_move(player: Node) -> bool:
	if not ("state" in player and "PlayerState" in player):
		return true
	var state := int(player.get("state"))
	return state in [
		int(player.PlayerState.IDLE),
		int(player.PlayerState.MOVE),
		int(player.PlayerState.JUMP),
		int(player.PlayerState.BLOCK),
	]

func _player_is_dead(player: Node) -> bool:
	return "health" in player and float(player.get("health")) <= 0.0

func _face_target(player: Node2D, target: Node2D) -> void:
	var direction: float = sign(target.global_position.x - player.global_position.x)
	if direction == 0.0:
		return
	if "facing" in player:
		player.set("facing", direction)
	var attack_area := player.get_node_or_null("AttackArea") as Area2D
	if attack_area != null:
		attack_area.position.x = 34.0 * direction

func _set_action_cooldown() -> void:
	action_cooldown = action_cooldown_time

func _update_status() -> void:
	if status_label != null:
		status_label.visible = enabled
		status_label.text = "AUTOPILOT ON"
