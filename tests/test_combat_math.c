#include "../src/combat_math.h"

#include <math.h>
#include <stdio.h>

static int failures = 0;

static void assert_double_eq(const char *label, double actual, double expected) {
    if (fabs(actual - expected) > 0.001) {
        printf("FAIL %s: expected %.3f, got %.3f\n", label, expected, actual);
        failures++;
    }
}

int main(void) {
    assert_double_eq("heartbeat rises above old cap", combat_add_heartbeat(110.0, 20.0), 130.0);
    assert_double_eq("heartbeat clamps at death threshold", combat_add_heartbeat(190.0, 20.0), 200.0);
    assert_double_eq("calm block duration", combat_block_duration_for_heartbeat(65.0), 1.2);
    assert_double_eq("high tension block duration", combat_block_duration_for_heartbeat(120.0), 0.35);
    assert_double_eq("lethal block duration", combat_block_duration_for_heartbeat(200.0), 0.2);
    assert_double_eq("adrenaline damage cap", combat_damage_with_adrenaline(20.0, 200.0), 30.0);
    assert_double_eq("adrenaline posture cap", combat_posture_damage_with_adrenaline(20.0, 200.0), 28.0);

    if (failures > 0) {
        return 1;
    }

    printf("combat_math tests passed\n");
    return 0;
}
