#ifndef COMBAT_MGR_H
#define COMBAT_MGR_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    STATE_IDLE,
    STATE_MOVE,
    STATE_ATTACK,
    STATE_PARRY,
    STATE_BLOCK,
    STATE_DASH,
    STATE_JUMP,
    STATE_HURT,
    STATE_STUNNED,
    STATE_EXECUTION
} EntityState;

typedef enum {
    INPUT_ATTACK = 0,
    INPUT_PARRY = 1,
    INPUT_JUMP = 2,
    INPUT_DASH = 3
} InputType;

typedef enum {
    ATTACK_NORMAL = 0,
    ATTACK_THRUST = 1,
    ATTACK_SWEEP = 2,
    ATTACK_GRAB = 3
} AttackType;

typedef enum {
    AI_IDLE,
    AI_CHASE,
    AI_ATTACK_COMBO,
    AI_SWEEP,
    AI_GRAB,
    AI_HEAVY_THRUST,
    AI_STUNNED,
    AI_PHASE_TRANSITION
} AIState;

typedef struct {
    float hp;
    float posture;
    float bpm;
    EntityState current_state;
    uint64_t last_input_time;
    uint64_t last_attack_received_time;
    int current_attack_id;
    bool is_invulnerable;
    bool is_blocking;
    bool is_parrying;
} CombatStats;

typedef struct {
    int id;
    float damage;
    float posture_damage;
    uint64_t active_frame_ms;
    AttackType type;
    bool processed;
    bool valid;
} AttackPacket;

typedef struct {
    InputType input_type;
    uint64_t timestamp_ms;
    bool valid;
} InputBuffer;

void combat_mgr_reset_combat(void);
void combat_mgr_register_input(int input_type, uint64_t timestamp_ms);
void combat_mgr_notify_attack_active(int attack_id, int attack_type, uint64_t timestamp_ms);
void combat_mgr_update_combat(float delta);
bool combat_mgr_is_parry_successful(void);
void combat_mgr_force_bpm(float value);
void combat_mgr_set_player_state(int state);

float combat_mgr_get_player_hp(void);
float combat_mgr_get_player_posture(void);
float combat_mgr_get_player_bpm(void);
int combat_mgr_get_player_state(void);
float combat_mgr_get_boss_hp(void);
float combat_mgr_get_boss_posture(void);
int combat_mgr_get_boss_state(void);
int combat_mgr_get_last_parry_delta_ms(void);
int combat_mgr_get_current_attack_id(void);
int combat_mgr_get_boss_ai_state(void);
int combat_mgr_get_input_buffer_type(void);
uint64_t combat_mgr_get_input_buffer_age_ms(uint64_t now_ms);
uint64_t combat_mgr_get_last_attack_timestamp_ms(void);

#ifdef __cplusplus
}
#endif

#endif
