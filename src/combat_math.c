#include "combat_math.h"

static double combat_clamp(double value, double minimum, double maximum) {
    if (value < minimum) {
        return minimum;
    }
    if (value > maximum) {
        return maximum;
    }
    return value;
}

static double combat_lerp(double from, double to, double weight) {
    return from + ((to - from) * weight);
}

static double combat_inverse_lerp(double from, double to, double value) {
    return combat_clamp((value - from) / (to - from), 0.0, 1.0);
}

double combat_apply_damage(double current_health, double damage) {
    double result = current_health - damage;
    return result < 0.0 ? 0.0 : result;
}

double combat_add_posture(double current_posture, double amount) {
    return combat_clamp(current_posture + amount, 0.0, 100.0);
}

double combat_add_heartbeat(double current_heartbeat, double amount) {
    return combat_clamp(current_heartbeat + amount, COMBAT_MIN_HEARTBEAT, COMBAT_MAX_HEARTBEAT);
}

double combat_block_duration_for_heartbeat(double heartbeat) {
    double clamped_heartbeat = combat_clamp(heartbeat, COMBAT_MIN_HEARTBEAT, COMBAT_MAX_HEARTBEAT);
    if (clamped_heartbeat <= COMBAT_ADRENALINE_HEARTBEAT) {
        double tension = combat_inverse_lerp(COMBAT_MIN_HEARTBEAT, COMBAT_ADRENALINE_HEARTBEAT, clamped_heartbeat);
        return combat_lerp(1.2, 0.35, tension);
    }
    double danger_tension = combat_inverse_lerp(COMBAT_ADRENALINE_HEARTBEAT, COMBAT_MAX_HEARTBEAT, clamped_heartbeat);
    return combat_lerp(0.35, 0.2, danger_tension);
}

double combat_damage_with_adrenaline(double base_damage, double heartbeat) {
    double clamped_heartbeat = combat_clamp(heartbeat, COMBAT_MIN_HEARTBEAT, COMBAT_ADRENALINE_HEARTBEAT);
    double tension = combat_inverse_lerp(COMBAT_MIN_HEARTBEAT, COMBAT_ADRENALINE_HEARTBEAT, clamped_heartbeat);
    return base_damage * combat_lerp(1.0, 1.5, tension);
}

double combat_posture_damage_with_adrenaline(double base_posture_damage, double heartbeat) {
    double clamped_heartbeat = combat_clamp(heartbeat, COMBAT_MIN_HEARTBEAT, COMBAT_ADRENALINE_HEARTBEAT);
    double tension = combat_inverse_lerp(COMBAT_MIN_HEARTBEAT, COMBAT_ADRENALINE_HEARTBEAT, clamped_heartbeat);
    return base_posture_damage * combat_lerp(1.0, 1.4, tension);
}
