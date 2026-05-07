#ifndef COMBAT_MATH_H
#define COMBAT_MATH_H

#ifdef __cplusplus
extern "C" {
#endif

#define COMBAT_MIN_HEARTBEAT 65.0
#define COMBAT_MAX_HEARTBEAT 120.0

double combat_apply_damage(double current_health, double damage);
double combat_add_posture(double current_posture, double amount);
double combat_add_heartbeat(double current_heartbeat, double amount);
double combat_block_duration_for_heartbeat(double heartbeat);
double combat_damage_with_adrenaline(double base_damage, double heartbeat);

#ifdef __cplusplus
}
#endif

#endif
