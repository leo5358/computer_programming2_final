#ifndef NATIVE_COMBAT_SERVER_H
#define NATIVE_COMBAT_SERVER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class NativeCombatServer : public RefCounted {
    GDCLASS(NativeCombatServer, RefCounted)

protected:
    static void _bind_methods();

public:
    void reset_combat();
    void register_input(int input_type, int timestamp_ms);
    void notify_attack_active(int attack_id, int attack_type, int timestamp_ms);
    void update_combat(double delta);
    bool is_parry_successful() const;
    void force_bpm(double value);
    void set_player_state(int state);

    Dictionary get_combat_update(double delta);


    double get_player_hp() const;
    double get_player_posture() const;
    double get_player_bpm() const;
    int get_player_state() const;
    double get_boss_hp() const;
    double get_boss_posture() const;
    int get_boss_state() const;
    int get_last_parry_delta_ms() const;
    int get_current_attack_id() const;
    int get_boss_ai_state() const;
};

}

#endif
