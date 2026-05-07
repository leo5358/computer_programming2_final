#include "native_combat_server.h"
#include "combat_mgr.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string_name.hpp>

using namespace godot;

void NativeCombatServer::_bind_methods() {
    ClassDB::bind_method(D_METHOD("reset_combat"), &NativeCombatServer::reset_combat);
    ClassDB::bind_method(D_METHOD("register_input", "input_type", "timestamp_ms"), &NativeCombatServer::register_input);
    ClassDB::bind_method(D_METHOD("notify_attack_active", "attack_id", "attack_type", "timestamp_ms"), &NativeCombatServer::notify_attack_active);
    ClassDB::bind_method(D_METHOD("update_combat", "delta"), &NativeCombatServer::update_combat);
    ClassDB::bind_method(D_METHOD("is_parry_successful"), &NativeCombatServer::is_parry_successful);
    ClassDB::bind_method(D_METHOD("force_bpm", "value"), &NativeCombatServer::force_bpm);
    ClassDB::bind_method(D_METHOD("get_combat_update", "delta"), &NativeCombatServer::get_combat_update);
    ClassDB::bind_method(D_METHOD("get_player_hp"), &NativeCombatServer::get_player_hp);
    ClassDB::bind_method(D_METHOD("get_player_posture"), &NativeCombatServer::get_player_posture);
    ClassDB::bind_method(D_METHOD("get_player_bpm"), &NativeCombatServer::get_player_bpm);
    ClassDB::bind_method(D_METHOD("get_player_state"), &NativeCombatServer::get_player_state);
    ClassDB::bind_method(D_METHOD("get_boss_hp"), &NativeCombatServer::get_boss_hp);
    ClassDB::bind_method(D_METHOD("get_boss_posture"), &NativeCombatServer::get_boss_posture);
    ClassDB::bind_method(D_METHOD("get_boss_state"), &NativeCombatServer::get_boss_state);
    ClassDB::bind_method(D_METHOD("get_last_parry_delta_ms"), &NativeCombatServer::get_last_parry_delta_ms);
    ClassDB::bind_method(D_METHOD("get_current_attack_id"), &NativeCombatServer::get_current_attack_id);
    ClassDB::bind_method(D_METHOD("get_boss_ai_state"), &NativeCombatServer::get_boss_ai_state);
}

void NativeCombatServer::reset_combat() {
    combat_mgr_reset_combat();
}

void NativeCombatServer::register_input(int input_type, int timestamp_ms) {
    combat_mgr_register_input(input_type, (uint64_t)timestamp_ms);
}

void NativeCombatServer::notify_attack_active(int attack_id, int attack_type, int timestamp_ms) {
    combat_mgr_notify_attack_active(attack_id, attack_type, (uint64_t)timestamp_ms);
}

void NativeCombatServer::update_combat(double delta) {
    combat_mgr_update_combat((float)delta);
}

bool NativeCombatServer::is_parry_successful() const {
    return combat_mgr_is_parry_successful();
}

void NativeCombatServer::force_bpm(double value) {
    combat_mgr_force_bpm((float)value);
}

Dictionary NativeCombatServer::get_combat_update(double delta) {
    combat_mgr_update_combat((float)delta);

    Dictionary update;
    update[StringName("player_hp")] = combat_mgr_get_player_hp();
    update[StringName("player_posture")] = combat_mgr_get_player_posture();
    update[StringName("player_bpm")] = combat_mgr_get_player_bpm();
    update[StringName("player_state")] = combat_mgr_get_player_state();
    update[StringName("boss_hp")] = combat_mgr_get_boss_hp();
    update[StringName("boss_posture")] = combat_mgr_get_boss_posture();
    update[StringName("boss_state")] = combat_mgr_get_boss_state();
    update[StringName("boss_ai_state")] = combat_mgr_get_boss_ai_state();
    update[StringName("current_attack_id")] = combat_mgr_get_current_attack_id();
    update[StringName("last_parry_delta_ms")] = combat_mgr_get_last_parry_delta_ms();
    update[StringName("last_attack_timestamp_ms")] = (int)combat_mgr_get_last_attack_timestamp_ms();
    update[StringName("input_buffer_type")] = combat_mgr_get_input_buffer_type();
    update[StringName("is_parry_successful")] = combat_mgr_is_parry_successful();
    return update;
}

double NativeCombatServer::get_player_hp() const { return combat_mgr_get_player_hp(); }
double NativeCombatServer::get_player_posture() const { return combat_mgr_get_player_posture(); }
double NativeCombatServer::get_player_bpm() const { return combat_mgr_get_player_bpm(); }
int NativeCombatServer::get_player_state() const { return combat_mgr_get_player_state(); }
double NativeCombatServer::get_boss_hp() const { return combat_mgr_get_boss_hp(); }
double NativeCombatServer::get_boss_posture() const { return combat_mgr_get_boss_posture(); }
int NativeCombatServer::get_boss_state() const { return combat_mgr_get_boss_state(); }
int NativeCombatServer::get_last_parry_delta_ms() const { return combat_mgr_get_last_parry_delta_ms(); }
int NativeCombatServer::get_current_attack_id() const { return combat_mgr_get_current_attack_id(); }
int NativeCombatServer::get_boss_ai_state() const { return combat_mgr_get_boss_ai_state(); }
