#include "../src/combat_mgr.h"

#include <math.h>
#include <stdio.h>

static int failures = 0;

static void assert_int_eq(const char *label, int actual, int expected) {
    if (actual != expected) {
        printf("FAIL %s: expected %d, got %d\n", label, expected, actual);
        failures++;
    }
}

static void assert_float_eq(const char *label, float actual, float expected) {
    if (fabsf(actual - expected) > 0.001f) {
        printf("FAIL %s: expected %.3f, got %.3f\n", label, expected, actual);
        failures++;
    }
}

static void assert_bool_eq(const char *label, bool actual, bool expected) {
    if (actual != expected) {
        printf("FAIL %s: expected %d, got %d\n", label, expected ? 1 : 0, actual ? 1 : 0);
        failures++;
    }
}

static void test_perfect_parry_when_input_arrives_before_active_frame(void) {
    combat_mgr_reset_combat();
    combat_mgr_register_input(INPUT_PARRY, 900);
    combat_mgr_notify_attack_active(12, ATTACK_NORMAL, 1000);

    assert_bool_eq("early parry success", combat_mgr_is_parry_successful(), true);
    assert_int_eq("early parry delta", combat_mgr_get_last_parry_delta_ms(), -100);
    assert_int_eq("current attack id", combat_mgr_get_current_attack_id(), 12);
    assert_float_eq("boss posture gain", combat_mgr_get_boss_posture(), 20.0f);
    assert_float_eq("player posture tax", combat_mgr_get_player_posture(), 5.0f);
}

static void test_perfect_parry_when_input_arrives_after_active_frame(void) {
    combat_mgr_reset_combat();
    combat_mgr_notify_attack_active(3, ATTACK_THRUST, 1000);
    combat_mgr_register_input(INPUT_PARRY, 1050);

    assert_bool_eq("late parry success", combat_mgr_is_parry_successful(), true);
    assert_int_eq("late parry delta", combat_mgr_get_last_parry_delta_ms(), 50);
}

static void test_late_parry_becomes_normal_block(void) {
    combat_mgr_reset_combat();
    combat_mgr_notify_attack_active(7, ATTACK_NORMAL, 1000);
    combat_mgr_register_input(INPUT_PARRY, 1060);

    assert_bool_eq("too late parry fails", combat_mgr_is_parry_successful(), false);
    assert_int_eq("failed parry delta", combat_mgr_get_last_parry_delta_ms(), 60);
    assert_float_eq("block player posture tax", combat_mgr_get_player_posture(), 30.0f);
    assert_float_eq("block boss posture gain", combat_mgr_get_boss_posture(), 5.0f);
    assert_float_eq("block bpm gain", combat_mgr_get_player_bpm(), 70.0f);
}

static void test_force_bpm_clamps_and_slows_posture_recovery(void) {
    combat_mgr_reset_combat();
    combat_mgr_notify_attack_active(1, ATTACK_NORMAL, 1000);
    combat_mgr_register_input(INPUT_PARRY, 1060);
    combat_mgr_force_bpm(999.0f);
    combat_mgr_update_combat(1.0f);

    assert_float_eq("force bpm clamps", combat_mgr_get_player_bpm(), 192.0f);
    assert_float_eq("high bpm slow posture recovery", combat_mgr_get_player_posture(), 28.8f);
}

int main(void) {
    test_perfect_parry_when_input_arrives_before_active_frame();
    test_perfect_parry_when_input_arrives_after_active_frame();
    test_late_parry_becomes_normal_block();
    test_force_bpm_clamps_and_slows_posture_recovery();

    if (failures > 0) {
        return 1;
    }

    printf("combat_mgr tests passed\n");
    return 0;
}
