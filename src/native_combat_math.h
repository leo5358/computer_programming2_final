#ifndef NATIVE_COMBAT_MATH_H
#define NATIVE_COMBAT_MATH_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class NativeCombatMath : public RefCounted {
    GDCLASS(NativeCombatMath, RefCounted)

protected:
    static void _bind_methods();

public:
    double apply_damage(double current_health, double damage) const;
    double add_posture(double current_posture, double amount) const;
    double add_heartbeat(double current_heartbeat, double amount) const;
    double block_duration_for_heartbeat(double heartbeat) const;
    double damage_with_adrenaline(double base_damage, double heartbeat) const;
    double posture_damage_with_adrenaline(double base_posture_damage, double heartbeat) const;
};

}

#endif
