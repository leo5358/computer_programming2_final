#include "native_combat_math.h"
#include "combat_math.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void NativeCombatMath::_bind_methods() {
    ClassDB::bind_method(D_METHOD("apply_damage", "current_health", "damage"), &NativeCombatMath::apply_damage);
    ClassDB::bind_method(D_METHOD("add_posture", "current_posture", "amount"), &NativeCombatMath::add_posture);
    ClassDB::bind_method(D_METHOD("add_heartbeat", "current_heartbeat", "amount"), &NativeCombatMath::add_heartbeat);
    ClassDB::bind_method(D_METHOD("block_duration_for_heartbeat", "heartbeat"), &NativeCombatMath::block_duration_for_heartbeat);
    ClassDB::bind_method(D_METHOD("damage_with_adrenaline", "base_damage", "heartbeat"), &NativeCombatMath::damage_with_adrenaline);
    ClassDB::bind_method(D_METHOD("posture_damage_with_adrenaline", "base_posture_damage", "heartbeat"), &NativeCombatMath::posture_damage_with_adrenaline);
}

double NativeCombatMath::apply_damage(double current_health, double damage) const {
    return combat_apply_damage(current_health, damage);
}

double NativeCombatMath::add_posture(double current_posture, double amount) const {
    return combat_add_posture(current_posture, amount);
}

double NativeCombatMath::add_heartbeat(double current_heartbeat, double amount) const {
    return combat_add_heartbeat(current_heartbeat, amount);
}

double NativeCombatMath::block_duration_for_heartbeat(double heartbeat) const {
    return combat_block_duration_for_heartbeat(heartbeat);
}

double NativeCombatMath::damage_with_adrenaline(double base_damage, double heartbeat) const {
    return combat_damage_with_adrenaline(base_damage, heartbeat);
}

double NativeCombatMath::posture_damage_with_adrenaline(double base_posture_damage, double heartbeat) const {
    return combat_posture_damage_with_adrenaline(base_posture_damage, heartbeat);
}
