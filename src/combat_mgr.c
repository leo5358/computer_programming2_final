#include "combat_mgr.h"

#define PLAYER_MAX_HP 100.0f
#define BOSS_MAX_HP 140.0f
#define BPM_MIN 65.0f
#define BPM_MAX 200.0f
#define INPUT_BUFFER_MS 150
#define PARRY_EARLY_MS 100
#define PARRY_LATE_MS 50

static CombatStats player;
static CombatStats boss;
static AttackPacket current_attack;
static InputBuffer input_buffer;
static bool last_parry_successful;
static int last_parry_delta_ms;
static AIState boss_ai_state;

static float clamp_float(float value, float minimum, float maximum) {
    if (value < minimum) {
        return minimum;
    }
    if (value > maximum) {
        return maximum;
    }
    return value;
}

static void evaluate_parry(void) {
    if (!input_buffer.valid || !current_attack.valid || current_attack.processed) {
        return;
    }
    if (input_buffer.input_type != INPUT_PARRY) {
        return;
    }

    int64_t delta = (int64_t)input_buffer.timestamp_ms - (int64_t)current_attack.active_frame_ms;
    last_parry_delta_ms = (int)delta;

    if (delta >= -PARRY_EARLY_MS && delta <= PARRY_LATE_MS) {
        last_parry_successful = true;
        player.current_state = STATE_PARRY;
        player.is_parrying = true;
        boss.posture = clamp_float(boss.posture + 20.0f, 0.0f, 100.0f);
        player.posture = clamp_float(player.posture + 5.0f, 0.0f, 100.0f);
    } else {
        last_parry_successful = false;
        player.current_state = STATE_BLOCK;
        player.is_blocking = true;
        player.posture = clamp_float(player.posture + 30.0f, 0.0f, 100.0f);
        boss.posture = clamp_float(boss.posture + 5.0f, 0.0f, 100.0f);
        player.bpm = clamp_float(player.bpm + 5.0f, BPM_MIN, BPM_MAX);
    }

    current_attack.processed = true;
}

void combat_mgr_reset_combat(void) {
    player.hp = PLAYER_MAX_HP;
    player.posture = 0.0f;
    player.bpm = BPM_MIN;
    player.current_state = STATE_IDLE;
    player.last_input_time = 0;
    player.last_attack_received_time = 0;
    player.current_attack_id = -1;
    player.is_invulnerable = false;
    player.is_blocking = false;
    player.is_parrying = false;

    boss.hp = BOSS_MAX_HP;
    boss.posture = 0.0f;
    boss.bpm = BPM_MIN;
    boss.current_state = STATE_IDLE;
    boss.last_input_time = 0;
    boss.last_attack_received_time = 0;
    boss.current_attack_id = -1;
    boss.is_invulnerable = false;
    boss.is_blocking = false;
    boss.is_parrying = false;

    current_attack.id = -1;
    current_attack.damage = 0.0f;
    current_attack.posture_damage = 0.0f;
    current_attack.active_frame_ms = 0;
    current_attack.type = ATTACK_NORMAL;
    current_attack.processed = false;
    current_attack.valid = false;

    input_buffer.input_type = INPUT_ATTACK;
    input_buffer.timestamp_ms = 0;
    input_buffer.valid = false;

    last_parry_successful = false;
    last_parry_delta_ms = 0;
    boss_ai_state = AI_IDLE;
}

void combat_mgr_register_input(int input_type, uint64_t timestamp_ms) {
    input_buffer.input_type = (InputType)input_type;
    input_buffer.timestamp_ms = timestamp_ms;
    input_buffer.valid = true;
    player.last_input_time = timestamp_ms;
    evaluate_parry();
}

void combat_mgr_notify_attack_active(int attack_id, int attack_type, uint64_t timestamp_ms) {
    current_attack.id = attack_id;
    current_attack.type = (AttackType)attack_type;
    current_attack.active_frame_ms = timestamp_ms;
    current_attack.processed = false;
    current_attack.valid = true;
    boss.current_attack_id = attack_id;
    player.last_attack_received_time = timestamp_ms;
    evaluate_parry();
}

void combat_mgr_update_combat(float delta) {
    if (input_buffer.valid && current_attack.valid) {
        uint64_t attack_time = current_attack.active_frame_ms;
        uint64_t input_time = input_buffer.timestamp_ms;
        uint64_t age = input_time > attack_time ? input_time - attack_time : attack_time - input_time;
        if (age > INPUT_BUFFER_MS && current_attack.processed) {
            input_buffer.valid = false;
        }
    }

    float recovery_mul = 1.0f - (player.bpm / 200.0f);
    recovery_mul = clamp_float(recovery_mul, 0.1f, 1.0f);
    player.posture = clamp_float(player.posture - (12.0f * recovery_mul * delta), 0.0f, 100.0f);

    if (player.bpm > BPM_MIN) {
        player.bpm = clamp_float(player.bpm - (8.0f * delta), BPM_MIN, BPM_MAX);
    }
}

bool combat_mgr_is_parry_successful(void) {
    return last_parry_successful;
}

void combat_mgr_force_bpm(float value) {
    player.bpm = clamp_float(value, BPM_MIN, BPM_MAX);
}

float combat_mgr_get_player_hp(void) { return player.hp; }
float combat_mgr_get_player_posture(void) { return player.posture; }
float combat_mgr_get_player_bpm(void) { return player.bpm; }
int combat_mgr_get_player_state(void) { return (int)player.current_state; }
float combat_mgr_get_boss_hp(void) { return boss.hp; }
float combat_mgr_get_boss_posture(void) { return boss.posture; }
int combat_mgr_get_boss_state(void) { return (int)boss.current_state; }
int combat_mgr_get_last_parry_delta_ms(void) { return last_parry_delta_ms; }
int combat_mgr_get_current_attack_id(void) { return current_attack.id; }
int combat_mgr_get_boss_ai_state(void) { return (int)boss_ai_state; }
int combat_mgr_get_input_buffer_type(void) { return input_buffer.valid ? (int)input_buffer.input_type : -1; }
uint64_t combat_mgr_get_last_attack_timestamp_ms(void) { return current_attack.active_frame_ms; }

uint64_t combat_mgr_get_input_buffer_age_ms(uint64_t now_ms) {
    if (!input_buffer.valid || now_ms < input_buffer.timestamp_ms) {
        return 0;
    }
    return now_ms - input_buffer.timestamp_ms;
}
