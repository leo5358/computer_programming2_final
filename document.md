# Heartbeat of Shinobi Codebase 說明文件

本文整理這份 Godot/GDExtension 專案的架構、抽象層、重要資料流、主要變數，以及各程式檔案負責的內容。專案是一個 2D 橫向動作遊戲 prototype，核心玩法圍繞格擋/彈刀、架勢值、心跳 BPM、敵人 AI、地圖切換與存檔。

## 1. 專案總覽

- 遊戲名稱：`心音之忍 Heartbeat of Shinobi`
- 引擎：Godot 4.x
- 語言：
  - GDScript：遊戲流程、玩家/敵人、UI、音效、場景控制。
  - C/C++：高頻且可測的戰鬥計算、GDExtension 封裝。
- 主場景：`project/project.godot` 設定 `run/main_scene="res://scenes/start_page.tscn"`。
- Autoload：`SaveManager="*res://scripts/save_manager.gd"`，全域提供存檔讀寫。
- 主要輸入：
  - `A/D` 或方向鍵：左右移動。
  - `Space`：跳躍/攀爬。
  - `J`：攻擊。
  - `K`：格擋/彈刀。
  - `L`：閃避。
  - `F1`：戰鬥 debug overlay。
  - `F2`：強制 BPM 到高壓測試值。
  - `F5/R`：重置戰鬥。
  - `M`：BGM 靜音切換。
  - `B`：hurtbox/hitbox debug。
  - `P`：autopilot。

## 2. 核心抽象層與實作邏輯

### 2.1 Native Combat 計算層

位置：`src/`

這一層用 C 實作純戰鬥資料與數學，再透過 C++ GDExtension 包成 Godot 可用類別。

- `combat_math.c/.h`：純函式數學層，處理 HP 扣減、架勢值加總、BPM clamp、BPM 影響格擋時間與攻擊倍率。
- `combat_mgr.c/.h`：native 狀態管理層，用 static global state 保存玩家/ boss 的 combat snapshot、目前攻擊封包、input buffer、最後一次 parry 結果。
- `native_combat_math.cpp/.h`：把 `combat_math` 包成 Godot `RefCounted` 類別 `NativeCombatMath`。
- `native_combat_server.cpp/.h`：把 `combat_mgr` 包成 Godot `RefCounted` 類別 `NativeCombatServer`，並提供 `get_combat_update()` 字典給 GDScript 讀取。
- `register_types.cpp/.h`：GDExtension 入口，註冊 `GDExample`、`NativeCombatMath`、`NativeCombatServer`。

Native 層的重點是「可替換」。GDScript 中的 `CombatMath` 與 `CombatServer` 都會先檢查 native class 是否存在；若 GDExtension 沒有 build 成功，會使用 GDScript fallback。這讓專案可以在沒有 native library 時仍能執行測試或開發部分邏輯。

### 2.2 GDScript Combat Facade 層

位置：`project/scripts/combat_math.gd`、`project/scripts/combat_server.gd`、`project/scripts/combat_runtime.gd`

這一層是 Godot 世界和 native combat 的介面。

- `CombatMath` 是數學 facade：
  - 有 native 時呼叫 `NativeCombatMath`。
  - native 不存在或結果不符合目前 BPM model 時，用 GDScript 實作。
- `CombatServer` 是 combat state facade：
  - 有 native 時呼叫 `NativeCombatServer`。
  - native 不存在時在 GDScript 內保存 `player_hp`、`player_posture`、`player_bpm`、`boss_posture`、`current_attack_id`、`input_buffer` 等資料。
- `CombatRuntime` 是場景內唯一 runtime node：
  - 掛在 `combat_runtime` group。
  - 接收玩家輸入與敵人攻擊事件。
  - 產生 attack id。
  - 將 combat snapshot 同步回 live entity，例如玩家 `health/posture/heartbeat`、boss `health/posture`。

資料流大致如下：

1. 玩家按下攻擊/格擋/閃避等輸入。
2. `player.gd` 或 `combat_runtime.gd` 呼叫 `register_input(input_type, timestamp_ms)`。
3. 敵人攻擊進入 active frame 時呼叫 `notify_attack_active(attack_type, timestamp_ms)`。
4. `CombatServer` 或 native `combat_mgr` 比對 input buffer 和 active frame timestamp。
5. 如果 parry delta 在 `-100ms` 到 `+50ms` 內，視為成功 parry；否則走 block/受擊/架勢懲罰。
6. 每幀 `get_combat_update(delta)` 回傳 HP、posture、BPM、parry delta、attack id 等 debug/同步資料。

### 2.3 Entity 層

位置：`project/scripts/player.gd`、`enemy_base.gd`、`boss.gd`、各敵人腳本

Entity 層負責將 combat snapshot 變成角色行為、動畫、碰撞與回饋。

- `player.gd` 是玩家狀態機，整合移動、跳躍、攀爬、攻擊、格擋、彈刀、閃避、道具、音效、VFX、死亡與 AI 指令。
- `enemy_base.gd` 是小兵共用基底，提供巡邏、警戒、追擊、保持距離、攻擊時序、被打、格擋、架勢擊破、處決與 overhead bars。
- `boss.gd` 繼承 `enemy_base.gd`，但有自己的 boss 專屬參數、攻擊 profile、連段、gap close、重攻擊 parry recoil、煙霧彈暫停與大型回饋。
- `warrior_enemy.gd`、`torchman_enemy.gd`、`archer_enemy.gd` 透過 override export 參數與少量方法建立不同敵人類型。

### 2.4 Scene 組裝層

位置：`project/scenes/`

Scene 層把 script、節點、碰撞、UI、音效與地圖組合成可運行畫面。

- `start_page.tscn`：遊戲入口主選單。
- `Main.tscn`：主遊戲整合場景，包含玩家、地圖、CombatRuntime、HUD、Debug Overlay、Pause/Death Overlay、BGM、Autopilot。
- `Player.tscn`、`Boss.tscn`、`WarriorEnemy.tscn`、`TorchmanEnemy.tscn`、`ArcherEnemy.tscn`：角色 prefab。
- `maps/*.tscn`：章節地圖、敵人 spawn、地形碰撞與背景。

### 2.5 UI/Feedback 層

位置：`project/scripts/*hud.gd`、`*_overlay.gd`、`camera_shake.gd`、`heartbeat_feedback.gd`

這一層只讀玩家/敵人狀態並渲染可視化資訊：

- HP、架勢、BPM、道具數量。
- Boss HP/posture。
- Debug combat 資料。
- Hurtbox/hitbox/vision debug 線框。
- 心跳邊緣紅光與心跳音效。
- 死亡與暫停選單。
- Camera follow、lookahead 與 shake。

## 3. 重要常數、變數與狀態

### 3.1 Combat 數值

- `COMBAT_MIN_HEARTBEAT / BPM_MIN = 65`：最低 BPM。
- `COMBAT_ADRENALINE_HEARTBEAT = 120`：腎上腺素倍率上限參考點。
- `COMBAT_MAX_HEARTBEAT / BPM_MAX = 200`：最高 BPM。
- `INPUT_BUFFER_MS = 150`：input buffer 保留時間。
- `PARRY_EARLY_MS = 100`：可以早按 parry 的最大毫秒數。
- `PARRY_LATE_MS = 50`：可以晚按 parry 的最大毫秒數。
- `player_posture / boss_posture`：架勢值，通常 clamp 在 `0..100`。
- `last_parry_delta_ms`：輸入時間和敵人 active frame 的差，負數代表早按。
- `current_attack_id`：每次敵人 active attack 的識別 id。

### 3.2 Player 重要變數

在 `project/scripts/player.gd`：

- `health`、`posture`、`lives`、`heartbeat`：玩家主要生命/壓力資源。
- `state`、`previous_state`：玩家狀態機目前與前一狀態。
- `is_blocking`、`is_attacking`、`is_parrying`、`is_dashing`、`is_perfect_dodging`、`is_invulnerable`：行為旗標。
- `facing`：角色面向，通常 `1.0` 代表右、`-1.0` 代表左。
- `attack_elapsed`、`attack_buffer_timer`、`attack_buffer_queued`：攻擊時序與輸入緩衝。
- `block_age`、`parry_elapsed`、`block_time_left`：格擋/彈刀窗口。
- `dash_timer`、`perfect_dodge_timer`：閃避與完美閃避時間。
- `item_counts`、`selected_item_index`、`active_teleport_kunai`：道具系統。
- `ai_move_axis`、`ai_attack_requested`、`ai_parry_requested`、`ai_dodge_requested`、`ai_jump_requested`：autopilot 對玩家注入的意圖。

### 3.3 Enemy/Boss 重要變數

在 `enemy_base.gd`：

- `EnemyState`：`PATROL`、`ALERTED`、`CHASE`、`HOLD`、`FLEE`、`ATTACK`、`DEFLECT`、`HURT`、`POSTURE_BROKEN`、`DEAD`。
- `health`、`posture`、`state`：敵人核心狀態。
- `is_alerted`、`target`、`facing`、`patrol_direction`：AI 感知與移動。
- `attack_elapsed`、`attack_cooldown`、`attack_has_connected`：攻擊節奏。
- `current_attack_profile`、`current_attack_type`、`current_attack_hit_start/end`：目前攻擊 profile 與 hit window。
- `posture_broken`、`defeated_flag`：可處決/死亡狀態。

在 `boss.gd`：

- `ATTACK_PROFILES_BOSS`：boss 的攻擊資料表，定義 attack/chop/thrust 等 profile 的 cue/hit/recovery/範圍/危險攻擊屬性。
- `ATTACK_PROFILE_SEQUENCE_BOSS`：boss 連段選招順序。
- `attack_chain_count_boss`、`pending_combo_followup_boss`：combo 狀態。
- `guard_pressure_count_boss`、`forced_counter_profile_boss`、`forced_counter_timer_boss`：玩家連續施壓後的 boss 反制邏輯。
- `hitstop_timer_boss`、`feedback_timer_boss`、`is_chop_parried_recovery_boss`：boss 受擊與重攻擊被 parry 後的停頓/後退回饋。
- `smoke_bomb_pause_timer_boss`：煙霧彈造成的 boss 暫停時間。

## 4. 根目錄與建置檔

### `README.md`

專案介紹文件，說明遊戲主題、核心機制、技術棧、建置方式、操作按鍵與 debug overlay。

### `SConstruct`

SCons 建置腳本：

- 載入 `godot-cpp/SConstruct` 取得 Godot C++ binding 的編譯環境。
- 加入 `src` include path。
- 收集 `src/*.cpp` 與 `src/*.c`。
- 輸出 shared library 到 `project/bin/libgdexample...`。
- 使用 `env.NoCache(library)` 避免開發時 cache 造成舊 library 被沿用。

### `project/project.godot`

Godot 專案設定：

- 設定 app name、icon、main scene。
- 註冊 `SaveManager` autoload。
- 設定 viewport `1280x720` 與 canvas stretch。
- 定義所有 input action。
- 設定預設背景色與 3D physics engine。

### `project/example.gdextension`

GDExtension 設定：

- `entry_symbol = "example_library_init"` 對應 `register_types.cpp` 中的 C entry point。
- 設定 Windows/macOS library path。
- Godot 會依平台載入 `project/bin` 內對應的 native library。

## 5. Native C/C++ 檔案說明

### `src/combat_math.h`

宣告 combat math 的 C API 與 BPM 常數：

- `combat_apply_damage`
- `combat_add_posture`
- `combat_add_heartbeat`
- `combat_block_duration_for_heartbeat`
- `combat_damage_with_adrenaline`
- `combat_posture_damage_with_adrenaline`

### `src/combat_math.c`

實作純數學函式：

- `combat_clamp`、`combat_lerp`、`combat_inverse_lerp` 是內部 helper。
- `combat_apply_damage`：扣血且不低於 0。
- `combat_add_posture`：架勢值加總並限制在 `0..100`。
- `combat_add_heartbeat`：BPM 加總並限制在 `65..200`。
- `combat_block_duration_for_heartbeat`：BPM 越高，可安全 block 的時間越短；65 BPM 約 1.2 秒，120 BPM 約 0.35 秒，200 BPM 約 0.2 秒。
- `combat_damage_with_adrenaline`：65 到 120 BPM 間線性提升傷害，最高 1.5 倍。
- `combat_posture_damage_with_adrenaline`：65 到 120 BPM 間線性提升架勢傷害，最高 1.4 倍。

### `src/combat_mgr.h`

宣告 native combat state API 與資料型別：

- `EntityState`：玩家/boss 狀態。
- `InputType`：attack/parry/jump/dash。
- `AttackType`：normal/thrust/sweep/grab。
- `AIState`：boss AI 狀態。
- `CombatStats`：HP、posture、BPM、state。
- `InputBuffer`：輸入類型、時間戳、是否有效。
- `AttackPacket`：攻擊 id、攻擊類型、active frame 時間、是否已處理。

### `src/combat_mgr.c`

實作 native combat 狀態管理：

- 用 static 變數保存 `player`、`boss`、`current_attack`、`input_buffer`、`last_parry_successful`、`last_parry_delta_ms`、`boss_ai_state`。
- `combat_mgr_reset_combat` 初始化 HP、posture、BPM、state、buffer。
- `combat_mgr_register_input` 更新 input buffer 並立即嘗試 evaluate parry。
- `combat_mgr_notify_attack_active` 更新目前攻擊封包並立即嘗試 evaluate parry。
- `evaluate_parry` 是核心判定：
  - sweep 攻擊遇到玩家 `STATE_JUMP` 會當成成功處理，並給 boss 少量 posture。
  - parry input 在 `-100ms..+50ms` 內成功，boss posture +20，玩家 posture +5。
  - parry 太晚或失敗時轉為 block，玩家 posture +30，boss posture +5，BPM +5。
  - jump input 對 sweep 有額外對應。
- `combat_mgr_update_combat` 每幀恢復玩家 posture 並降低 BPM；BPM 越高，posture recovery 越慢。
- getter 函式提供 GDExtension 讀取 snapshot。

### `src/native_combat_math.h/.cpp`

Godot `RefCounted` wrapper：

- class name：`NativeCombatMath`
- `_bind_methods` 將 C++ 方法暴露給 GDScript。
- 每個 method 都直接呼叫 `combat_math.c` 的 C function。

### `src/native_combat_server.h/.cpp`

Godot `RefCounted` wrapper：

- class name：`NativeCombatServer`
- 將 `reset_combat`、`register_input`、`notify_attack_active`、`update_combat` 等方法暴露給 GDScript。
- `get_combat_update(delta)` 會先更新 native combat，再組出 Godot `Dictionary`：
  - `player_hp`
  - `player_posture`
  - `player_bpm`
  - `player_state`
  - `boss_hp`
  - `boss_posture`
  - `boss_state`
  - `boss_ai_state`
  - `current_attack_id`
  - `last_parry_delta_ms`
  - `last_attack_timestamp_ms`
  - `input_buffer_type`
  - `is_parry_successful`

### `src/gd_example.h/.cpp`

GDExtension 範例 class：

- class name：`GDExample`
- 繼承 `Sprite2D`。
- `_process(delta)` 讓 sprite 依 `sin/cos` 做小範圍移動。
- 主要是 extension 範例/驗證用途，不是遊戲核心。

### `src/register_types.h/.cpp`

GDExtension 初始化檔：

- `initialize_example_module` 在 scene 初始化階段註冊 `GDExample`、`NativeCombatMath`、`NativeCombatServer`。
- `uninitialize_example_module` 保留反初始化 hook。
- `example_library_init` 是 Godot 載入 dynamic library 時呼叫的入口。

## 6. GDScript 檔案說明

### `project/scripts/combat_math.gd`

`CombatMath` facade。負責統一提供 combat math API，並自動選擇 native 或 GDScript fallback。

重要邏輯：

- `_init`：如果存在 `NativeCombatMath` 就 instantiate。
- `_native_math_matches_heartbeat_model`：檢查 native 實作是否符合目前 heartbeat model，避免舊版 library 行為不一致。
- `apply_damage`、`add_posture`、`add_heartbeat`、`block_duration_for_heartbeat`、`damage_with_adrenaline`、`posture_damage_with_adrenaline`：與 native API 一一對應。

### `project/scripts/combat_server.gd`

`CombatServer` facade。負責 combat state、input buffer、parry timing、BPM/posture recovery。

重要邏輯：

- `_init`：若存在 `NativeCombatServer` 則使用 native。
- `reset_combat`：重置玩家/boss combat 資料。
- `register_input`：記錄輸入類型與時間。
- `notify_attack_active`：記錄攻擊 id、攻擊類型與 active frame 時間。
- `_evaluate_parry`：GDScript fallback 的 parry/block 判定。
- `get_combat_update`：提供統一 snapshot 給 UI/debug/runtime。

### `project/scripts/combat_runtime.gd`

場景內 combat runtime。

重要邏輯：

- `combat`：`CombatServerScript.new()`。
- `attack_id_counter`：為每次 attack active 生成 id。
- `_input`：接收 reset/force BPM 等 debug input。
- `register_input`、`notify_attack_active`：給玩家/敵人呼叫。
- `get_combat_update`：從 combat server 取 snapshot，並呼叫 `_sync_live_entities` 同步玩家、boss 的 live 狀態。

### `project/scripts/player.gd`

玩家主控腳本，專案最大且最重要的 gameplay script。

負責：

- 角色移動：走路、跑步、加速度、摩擦、轉向 braking。
- 跳躍/攀爬：coyote time、牆面攀爬、地圖限定攀爬範圍、auto step。
- 戰鬥：攻擊 startup/active/recovery、攻擊 buffer、soft lock、projectile slash、格擋、彈刀、完美閃避。
- 玩家資源：HP、架勢、生命數、BPM。
- 道具：葫蘆/藥丸/膠囊/苦無/灰球。
- AI intent：讓 `combat_autopilot.gd` 可以注入移動與行動請求。
- 動畫：根據 spritesheet 或 strip image 組出 `SpriteFrames`，播放 idle/walk/run/attack/chop/thrust/deflect/hurt/death 等動畫。
- 音效/VFX：攻擊音效、parry/block/hurt/death/dash/kunai SFX、hit impact VFX、camera shake。
- 死亡/重生：世界邊界死亡、HP 歸零、心跳過高死亡、debug death。

核心流程：

1. `_physics_process` 每幀讀 input、更新 movement、更新 action state、更新 combat、更新 visuals。
2. `_update_inputs` 將鍵盤輸入或 AI intent 轉換成行動。
3. `_start_attack` 建立攻擊狀態；`_apply_attack_hit` 對敵人呼叫 `receive_player_attack`。
4. `_start_parry`/`_start_block` 註冊 combat input，並開啟防禦窗口。
5. `receive_enemy_attack` 根據目前防禦/閃避狀態決定 perfect parry、block、perfect dodge 或受傷。
6. `_enter_stunned`、`_enter_dead` 處理架勢擊破與死亡。

### `project/scripts/enemy_base.gd`

小兵共用基底。大部分普通敵人都繼承它。

負責：

- 敵人狀態機：巡邏、警戒、追擊、保持距離、逃離、攻擊、被彈刀、受傷、架勢擊破、死亡。
- 視野判斷：`get_vision_rect`、`can_see_player`。
- 攻擊 profile：一般攻擊、counter、thrust 的 cue/hit/end/total time。
- 攻擊命中：在 hit window 內對玩家呼叫 `receive_enemy_attack`。
- 被玩家攻擊：扣血、加 posture、可能 guard、可能 posture break 或死亡。
- 防禦回饋：`receive_block_feedback`、`receive_dodge_feedback`。
- 處決：`can_be_executed`、`execute`。
- Overhead bars：建立並更新敵人頭上的 HP/posture bar。

擴充方式：

- 子類透過 `_ready` 調整 export 參數與 sprite root。
- 子類可 override `_update_combat_movement`、`_connect_attack`、`can_receive_attack_soft_lock` 等 hook。

### `project/scripts/enemy.gd`

較舊/較簡化的訓練敵人腳本，和 `enemy_base.gd` 類似但不走完整 shared base。

負責：

- 基礎敵人 HP/posture。
- 攻擊 windup/cue/active 三段流程。
- boss group 下有機率使用 thrust/sweep perilous attack。
- 被玩家攻擊、被 parry、被 perfect dodge、姿勢擊破、死亡。
- 使用 `CombatMath` 進行 HP/posture 計算。

### `project/scripts/boss.gd`

Boss 專用腳本，繼承 `enemy_base.gd`，但重新定義大量 boss 行為。

負責：

- Boss sprite/animation frame 資料表。
- 多攻擊 profile：`attack`、`chop`、`thrust` 等。
- 攻擊選招與連段：固定 sequence、combo followup、gap close thrust/chop。
- 玩家施壓反制：guard pressure、forced counter。
- 攻擊視覺與 hitbox：根據 profile 更新 warning、attack visual、AttackArea。
- parry/block/dodge 回饋：hitstop、recoil、camera shake、spark、damage number。
- 架勢擊破與處決。
- 煙霧彈暫停：`receive_smoke_bomb_pause`。

### `project/scripts/warrior_enemy.gd`

Warrior 小兵，繼承 `enemy_base.gd`。

負責：

- 在 `_ready` 中套用 warrior 的預設參數、sprite root、攻擊距離與節奏。
- 使用基底的巡邏、追擊、攻擊與受擊邏輯。

### `project/scripts/torchman_enemy.gd`

Torchman 小兵，繼承 `enemy_base.gd`。

負責：

- 設定火把敵人的移動/攻擊參數。
- `ally_call_range`：呼叫附近同伴的範圍。
- `flee_until_distance`：過近時逃離到指定距離。
- `_call_nearby_allies`：讓附近敵人 `receive_alert`。
- override `_update_combat_movement` 實現更偏支援/呼叫的行為。

### `project/scripts/archer_enemy.gd`

弓箭手，繼承 `enemy_base.gd`。

負責：

- 設定遠程攻擊節奏與距離。
- `ARROW_SCENE`：箭矢 prefab。
- `arrow_spawn_offset`：箭矢出生點。
- `_connect_attack`：攻擊連接時生成 `Arrow`。
- `_update_combat_movement`：保持遠程距離。
- `can_receive_attack_soft_lock`：控制玩家 soft lock 是否能吸到弓箭手。

### `project/scripts/arrow_projectile.gd`

敵人箭矢。

負責：

- 直線飛行、lifetime 到期銷毀。
- 撞到玩家時呼叫 `receive_enemy_attack(damage, posture_damage, owner_enemy)`。
- 可被玩家攻擊切掉，`receive_player_attack` 會銷毀箭矢。

### `project/scripts/kunai_projectile.gd`

玩家苦無。

負責：

- 直線飛行。
- 命中敵人時呼叫 `receive_player_attack(damage, posture_damage)`。
- 命中後 `lodged = true` 停留，供玩家 teleport/回收類玩法使用。

### `project/scripts/ash_ball_projectile.gd`

玩家灰球/煙霧彈。

負責：

- 拋物線飛行，帶 gravity。
- 撞地或到期後 `explode`。
- 爆炸時在 `effect_radius` 內對 boss 呼叫 `receive_smoke_bomb_pause`，對小兵呼叫 `receive_ash_ball_stun`。
- 生成 `SmokeEffect`。

### `project/scripts/smoke_effect.gd`

煙霧視覺效果。

負責：

- 建立簡單 animation。
- 依 `fade_duration` 漸淡並放大。
- 播完後自動消失。

### `project/scripts/training_dummy.gd`

訓練假人。

負責：

- 接收玩家攻擊並記錄 `hit_count`、`last_damage`、`last_posture_damage`。
- 受擊閃白、knockback、摩擦停下。
- 生成 damage number。
- `can_be_executed` 固定 false。

### `project/scripts/damage_number.gd`

傷害數字。

負責：

- `setup(value, color)` 設定文字與顏色。
- `_process` 讓文字向上飄、漸淡。
- `lifetime` 結束後 `queue_free`。

### `project/scripts/combat_autopilot.gd`

自動戰鬥輔助。

負責：

- `P` 切換開關。
- 掃描敵人與 projectile，判斷最近威脅。
- 根據敵人攻擊 cue/hit window 自動 parry 或 dodge。
- 自動攻擊可處決目標、切 projectile、接近敵人。
- 透過 `player.gd` 提供的 `request_ai_attack/parry/dodge/jump` 與 `set_ai_move_axis` 注入行為。

### `project/scripts/enemy_test_spawner.gd`

主場景的遊戲流程/地圖控制器。

負責：

- 載入存檔並把玩家放到正確地圖/位置。
- 管理目前 `current_map_id`。
- 重生、retry、回主選單、暫停、存檔返回。
- map transition：foothill -> plaza -> boss interior。
- 生成/清除敵人與 boss。
- checkpoint 啟用與同步。
- map BGM 切換。
- 更新地圖互動 prompt。

### `project/scripts/enemy_spawn_point.gd`

地圖敵人 spawn point。

負責：

- 根據 `enemy_type` 生成 torchman/warrior/archer/boss。
- `spawn_on_ready` 控制是否進場自動生成。
- `disabled` 停用 spawn。
- `facing`、`patrol_distance_override`、`spawn_group_id` 對生成敵人套設定。
- `respawn_enemy`、`despawn_enemy` 管理 active enemy。

### `project/scripts/checkpoint.gd`

存檔點。

負責：

- `interaction_range` 判斷玩家是否可互動。
- `activate` 啟用 checkpoint 並發出 `activated_changed`。
- `deactivate` 關閉。
- 根據啟用狀態切換 checkpoint texture。
- `respawn_position` 可 override 重生點，否則用 checkpoint 自身位置。

### `project/scripts/save_manager.gd`

autoload 存檔管理。

負責：

- 存檔路徑：`user://savegame.json`。
- `save_game(map_id, position, health)`：寫入 map id、位置、血量、時間戳。
- `load_game`：讀 JSON 到 `current_save_data`。
- `has_save`：檢查是否有有效存檔。
- `get_saved_map/get_saved_position/get_saved_health`：讀取存檔資料。
- `delete_save`：刪除存檔。

### `project/scripts/start_page.gd`

主選單控制。

負責：

- 選單項目：continue、new game、quit。
- 鍵盤與滑鼠操作。
- selector 與 glow 位置更新。
- new game 時清除存檔並切到 `Main.tscn`。
- continue 時讀存檔後切到 `Main.tscn`。
- 播放按鈕音效與 fade transition。

### `project/scripts/bgm_player.gd`

BGM 播放器。

負責：

- 一般地圖 BGM 與 boss BGM 切換。
- boss BGM loop start。
- fade out。
- `M` 切換靜音。
- `set_map_bgm`、`restart_map_bgm` 給 map controller 呼叫。

### `project/scripts/camera_shake.gd`

Camera2D 控制。

負責：

- follow 玩家或指定 `follow_target_path`。
- deadzone、lookahead、vertical follow ratio。
- `shake(amount, duration)` 疊加震動。
- dynamic bottom limit：依玩家 x 位置調整 camera limit。
- `is_suppressed` 可由危險攻擊提示暫停 shake。

### `project/scripts/combat_ui.gd`

舊版/開發用 combat UI。

負責：

- 每幀讀玩家與敵人資料。
- 更新 HP、posture、heartbeat label/bar。
- 顯示基本 combat 狀態。

### `project/scripts/debug_overlay.gd`

戰鬥 debug 面板。

負責：

- `F1` 顯示/隱藏。
- `F2` 強制 BPM。
- `F5/R` 重置 combat。
- 顯示 `CombatServer` snapshot：HP、posture、BPM、state、attack id、input buffer、parry delta。

### `project/scripts/hurtbox_debug_overlay.gd`

碰撞盒 debug。

負責：

- `B` 切換顯示。
- 對 player、boss、minor_enemy 畫出 body collision rectangle。
- 對 `AttackArea` 畫出 hitbox。
- 若目標有 `get_vision_rect`，畫出 vision rectangle。

### `project/scripts/item_ui.gd`

道具 UI。

負責：

- 依 `ITEM_ORDER` 顯示 gourd、kunai、pill、capsule、ash_balls。
- 綁定玩家並讀 `get_item_count`。
- 顯示數量與目前選取的 slot border。

### `project/scripts/player_posture_hud.gd`

玩家架勢 HUD。

負責：

- 建立底部置中的 posture bar。
- 綁定玩家 `stats_changed`。
- 依玩家 `posture/max_posture` 更新左右 fill。

### `project/scripts/player_vitals_hud.gd`

玩家生命/BPM HUD。

負責：

- 顯示生命數 icon、HP bar、心臟 icon、BPM label。
- 綁定玩家並讀 `health/max_health/lives/heartbeat`。
- 心臟 icon 依 BPM 做跳動。

### `project/scripts/boss_hud.gd`

Boss HUD。

負責：

- 綁定場景中的 boss。
- 顯示 boss 名稱、HP bar、posture bar。
- 若沒有 boss 或 boss defeated，隱藏/歸零。

### `project/scripts/heartbeat_feedback.gd`

心跳回饋。

負責：

- 綁定玩家 heartbeat。
- BPM 高於門檻後顯示螢幕邊緣紅光。
- 依 BPM 計算心跳音效間隔與音量。
- `min_heartbeat/max_heartbeat/visual_start_heartbeat/audio_start_heartbeat` 控制回饋曲線。

### `project/scripts/death_overlay.gd`

死亡選單。

負責：

- 顯示「心音斷絕」畫面。
- 選項：重新挑戰、返回主選單。
- 發出 `retry_requested`、`main_menu_requested` signals。
- 支援鍵盤與滑鼠操作。

### `project/scripts/pause_overlay.gd`

暫停選單。

負責：

- 顯示暫停遮罩。
- 選項：繼續遊戲、存檔並返回主頁。
- 發出 `resume_requested`、`save_and_menu_requested` signals。
- `process_mode = ALWAYS`，暫停時仍可操作。

## 7. Scene 檔案說明

### 主要場景

- `project/scenes/start_page.tscn`：主選單，包含背景、logo、continue/new game/quit 貼圖、selector、mist、fade rect、`start_page.gd`。
- `project/scenes/Main.tscn`：主遊戲場景，包含 `BgmPlayer`、`CombatRuntime`、`CombatAutopilot`、地圖、HUD、Death/Pause overlay、Player、CombatUI、DebugOverlay。
- `project/scenes/BossRoom.tscn`：獨立 boss 測試/展示場景，包含 Player、Boss、CombatRuntime、CombatUI、DebugOverlay、BossHud、Camera。

### 角色/物件 prefab

- `project/scenes/Player.tscn`：玩家角色，包含 AnimatedSprite2D、CollisionShape2D、AttackArea、HitImpactVfx、多個 SFX player。
- `project/scenes/Boss.tscn`：boss，包含 body/animated sprite/collision/attack visual/hit spark/parry spark/posture break spark/execute label/attack area/SFX。
- `project/scenes/WarriorEnemy.tscn`：warrior 小兵 prefab，掛 `warrior_enemy.gd`。
- `project/scenes/TorchmanEnemy.tscn`：torchman 小兵 prefab，掛 `torchman_enemy.gd`。
- `project/scenes/ArcherEnemy.tscn`：archer 小兵 prefab，掛 `archer_enemy.gd`。
- `project/scenes/Enemy.tscn`：較舊的 training enemy prefab，掛 `enemy.gd`。
- `project/scenes/TrainingDummy.tscn`：訓練假人，掛 `training_dummy.gd`。
- `project/scenes/Checkpoint.tscn`：checkpoint sprite 與 `checkpoint.gd`。
- `project/scenes/DamageNumber.tscn`：傷害數字 Label。
- `project/scenes/Kunai.tscn`：苦無 projectile。
- `project/scenes/Arrow.tscn`：箭 projectile。
- `project/scenes/AshBall.tscn`：灰球 projectile。
- `project/scenes/SmokeEffect.tscn`：煙霧效果。

### 純動畫/素材預覽場景

- `project/scenes/warrior.tscn`：warrior 分動畫 sprite preview。
- `project/scenes/torchman.tscn`：torchman 分動畫 sprite preview。
- `project/scenes/archer.tscn`：archer 分動畫 sprite preview。
- `project/scenes/bossani.tscn`：boss 分動畫 sprite preview。

### 地圖場景

- `project/scenes/maps/chapter1_ab_foothill_stairs.tscn`：第一段山腳/階梯地圖，包含大量背景、地形 polygon/line、props、pickup/路徑標示、碰撞。
- `project/scenes/maps/chapter1_h_stone_plaza.tscn`：石 plaza 地圖，包含敵人 spawn points、背景、石地板、燈籠、神社結構、碰撞。
- `project/scenes/maps/chapter1_boss_interior_blockout.tscn`：boss 室內場景，包含地板、祭壇、柱子、火炬、boss arena、camera、碰撞。
- `project/scenes/maps/chapter1_blockout.tscn`：早期 chapter1 blockout 地圖。

## 8. Asset 目錄說明

這些多數不是程式碼，但會被 scene/script 引用：

- `project/assets/sprites/player/`：玩家動畫 strip。
- `project/assets/sprites/boss/`：boss 動畫 strip。
- `project/assets/sprites/warrior/`、`torchman/`、`archer/`：小兵動畫與箭矢。
- `project/assets/sprites/vfx/`：hit impact 等 VFX。
- `project/assets/items/`：道具、checkpoint、生命/死亡 icon。
- `project/assets/audio/`、`project/assets/audio/BGMs/`：BGM。
- `project/assets/sfx/`：攻擊、格擋、受傷、死亡、心跳、UI 音效。
- `project/assets/maps/chapter1/`：地圖背景、地板、結構、props、boss interior 素材。
- `project/assets/start_page/`：主選單背景、logo、按鈕與 selector。
- `*.import`：Godot 自動產生的 import metadata。
- `*.uid`：Godot 4.4+ resource UID metadata。

## 9. 測試檔案說明

### C 測試

- `tests/test_combat_math.c`：測 `combat_math` 的 BPM clamp、block duration、adrenaline damage/posture multiplier。
- `tests/test_combat_mgr.c`：測 native combat manager 的 early parry、late parry、parry 失敗轉 block、force BPM clamp 與高 BPM 下 posture recovery。

### Godot 測試總覽

`project/tests/*.gd` 多數是 `extends SceneTree` 的 headless 測試，檢查 scene/script 行為。命名大致代表測試主題：

- `test_combat_math.gd`、`test_combat_server.gd`、`test_combat_runtime.gd`：GDScript combat facade/runtime。
- `test_native_combat_math.gd`、`test_native_combat_server.gd`：GDExtension class 是否可用與行為正確。
- `test_player_*.gd`：玩家場景、移動、攻擊、hitstop、音效、deflect miss、heartbeat、道具、死亡、AI intent、execution、HUD。
- `test_boss_*.gd`：boss runtime、攻擊 timing/profile/reach、combo AI、spacing、anti spam、guard response、hit feedback、posture break、HUD、body visual。
- `test_enemy_*.gd`：小兵 sprite、spawn point、feedback、hurt feedback、execution、defeat cleanup、overhead bars、scale、test spawner。
- `test_warrior_*.gd`、`test_torchman_*.gd`、`test_archer_*.gd`：特定小兵類型行為與 art adapter。
- `test_arrow_projectile.gd`、`test_damage_numbers.gd`、`test_camera_feedback.gd`、`test_heartbeat_feedback.gd`、`test_hurtbox_debug_overlay.gd`：projectile、VFX/UI/debug feedback。
- `test_checkpoint.gd`、`test_checkpoint_in_main.gd`、`test_map_transition.gd`、`test_map_enemy_spawns.gd`、`test_plaza_enemy_spawns.gd`：checkpoint、地圖切換與敵人生成。
- `test_start_page.gd`、`test_pause_overlay.gd`、`test_pause_return_to_menu.gd`、`test_death_overlay.gd`、`test_death_return_to_menu.gd`、`test_bgm_player.gd`、`test_item_ui.gd`：選單、overlay、BGM、道具 UI。

## 10. 常用建置與測試

### 建置 GDExtension

README 中建議：

```bash
mkdir -p project/bin
scons platform=linux target=template_debug arch=x86_64 api_version=4.6
```

macOS/Windows 需依 Godot/godot-cpp 的平台參數調整。

### 執行 C 測試

可用 C compiler 直接編譯測試與對應 source，例如：

```bash
cc -Isrc tests/test_combat_math.c src/combat_math.c -o /tmp/test_combat_math
/tmp/test_combat_math

cc -Isrc tests/test_combat_mgr.c src/combat_mgr.c -o /tmp/test_combat_mgr
/tmp/test_combat_mgr
```

### 執行 Godot headless 測試

單一測試通常可用類似：

```bash
godot --headless --path project --script res://tests/test_combat_server.gd
```

實際 Godot binary 名稱可能是 `godot`、`godot4` 或本機安裝的完整路徑。

## 11. 修改程式時的注意事項

- 優先保持 `CombatMath`/`CombatServer` 的 native 與 GDScript fallback 行為一致。
- 修改 BPM、parry window、posture recovery 時，同步更新：
  - `src/combat_math.*`
  - `src/combat_mgr.*`
  - `project/scripts/combat_math.gd`
  - `project/scripts/combat_server.gd`
  - 相關 tests。
- `player.gd` 與 `boss.gd` 參數很多，建議改數值前先確認對應測試名稱，例如 attack timing、hitstop、guard response、spacing。
- Scene 中節點名稱被腳本用 `get_node_or_null` 或 `$NodeName` 讀取，改名會破壞腳本。
- `enemy_base.gd` 是 warrior/torchman/archer 的共用抽象層，改它會影響所有小兵。
- `enemy_test_spawner.gd` 同時管地圖、checkpoint、pause/death flow 和 boss spawn，改流程時要測地圖切換、存檔、死亡 retry。
- `*.import` 與 `*.uid` 通常由 Godot 管理，不建議手動改。
