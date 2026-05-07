# 《心音之忍 Heartbeat of Shinobi》Codex 最終開發規格書 v1.0

> 本文件為交給 Codex / Claude Code / 其他程式碼生成工具使用的單一開發規格書。  
> 目標是讓 AI 直接依照本文件建立 Godot 4.6.2 + C GDExtension 的可執行 Vertical Slice Prototype。  
> 請優先完成可編譯、可執行、可展示 Debug Overlay 的最小版本，不要一開始追求完整美術或過度 polish。

---

## 0. 專案定位

專案名稱：**心音之忍 Heartbeat of Shinobi**

本專案是一個 **2D 橫向捲軸動作遊戲 Vertical Slice**，核心玩法致敬《隻狼》式的「打鐵」彈反戰鬥，但加入原創的 **模擬心跳 BPM 系統**。

本專案目標不是製作完整長篇遊戲，而是在 Demo 中展示一場具備以下特色的 Boss 戰：

1. 精準彈反 Parry
2. 軀幹條 Posture
3. 模擬心跳 BPM 系統
4. Boss 二階段轉換
5. Debug Overlay 顯示 C 模組內部邏輯
6. Ubuntu 24.04 可編譯、可執行、可展示

核心體驗：

> 玩家在高壓戰鬥中透過精準彈反維持節奏。BPM 越高，壓力越大，Posture 回復越慢，但攻擊收益提高。玩家必須在「高傷害收益」與「破防風險」之間做出判斷。

---

## 1. 技術棧與開發環境

### 1.1 Engine

- Godot **4.6.2**
- Godot Standard Version
- 2D project
- Renderer 以穩定為優先，可使用 Compatibility 或 Forward+

### 1.2 開發環境

- Ubuntu 24.04
- C / GDExtension
- GDScript
- SCons

### 1.3 Ubuntu 24.04 依賴

請在 Ubuntu 24.04 執行：

```bash
sudo apt update && sudo apt install -y build-essential scons \
pkg-config libx11-dev libxcursor-dev libxinerama-dev \
libxrandr-dev libxi-dev libgl-dev libasound2-dev libpulse-dev
```

---

## 2. C 與 Godot 職責劃分

### 2.1 C / GDExtension 負責

C 模組負責核心邏輯，不負責畫面表現。

C 模組名稱建議：

- CombatServer
- AIBrain

C 模組負責：

1. HP / Posture / BPM 數值管理
2. Parry Timing 判定
3. Input Buffer
4. Attack ID System
5. Boss AI FSM 決策
6. State Priority 判斷
7. Boss Phase Transition 邏輯
8. Debug Data 輸出
9. Reset_Combat 的核心數值重置

### 2.2 GDScript 負責

GDScript 負責表現層與 Godot 場景串接。

GDScript 負責：

1. Input capture
2. CharacterBody2D 物理移動
3. AnimationPlayer / AnimatedSprite2D 切換
4. 在攻擊 Active Frame 通知 C 模組
5. UI / HUD
6. Debug Overlay
7. Shader / VFX
8. SFX Pool
9. Camera Shake
10. Fake Hitstop 視覺暫停
11. Reset_Combat 的場景位置與視覺重置

### 2.3 明確禁止

1. 不要讓 C 模組直接控制 Godot 物件的生命週期
2. 不要在 C 裡主動 malloc Godot Entity
3. 不要讓 Animation 主導 gameplay movement
4. 不要使用 `Engine.time_scale = 0`
5. 不要 reload scene 來重置戰鬥
6. 不要讓 Parry Window 隨 BPM 縮短
7. 不要為了特效犧牲危字攻擊可讀性

---

## 3. 專案目錄結構

本規格書後續提到的所有路徑，皆以**目前這個 repo 根目錄**為準，不再假設額外包一層 `HeartbeatOfShinobi/` 或 `godot_project/`。

目前專案目錄結構應以下列形式為主：

```text
computer_programming2_final/
├── build/
├── docs/
├── project/
│   ├── assets/
│   │   ├── sfx/
│   │   │   ├── player_attack.wav
│   │   │   ├── player_block.wav
│   │   │   ├── player_death.wav
│   │   │   ├── player_hurt.wav
│   │   │   └── player_parry.wav
│   │   └── sprites/
│   │       ├── enemy/
│   │       │   └── enemy_sheet.png
│   │       └── player/
│   │           └── player_sheet.png
│   ├── bin/
│   ├── scenes/
│   │   ├── Boss.tscn
│   │   ├── Enemy.tscn
│   │   ├── Main.tscn
│   │   └── Player.tscn
│   ├── scripts/
│   │   ├── boss.gd
│   │   ├── combat_math.gd
│   │   ├── combat_runtime.gd
│   │   ├── combat_server.gd
│   │   ├── combat_ui.gd
│   │   ├── debug_overlay.gd
│   │   ├── enemy.gd
│   │   └── player.gd
│   ├── tests/
│   ├── example.gdextension
│   └── project.godot
├── src/
│   ├── combat_math.h
│   ├── combat_math.c
│   ├── combat_mgr.h
│   ├── combat_mgr.c
│   ├── native_combat_math.h
│   ├── native_combat_math.cpp
│   ├── native_combat_server.h
│   ├── native_combat_server.cpp
│   ├── register_types.h
│   └── register_types.cpp
├── tests/
├── SConstruct
└── README.md
```

補充原則：

1. Godot 專案根目錄是 `project/`
2. GDScript 場景與資源路徑應使用 `res://` 對應 `project/` 內部結構
3. C / GDExtension 原始碼與建置腳本以 repo 根目錄下的 `src/`、`SConstruct` 為主
4. 後續若新增檔案，請優先延續目前 repo 內的資料夾分層，不要再建立第二套平行結構

---

## 4. C 核心資料結構

請在 `src/combat_mgr.h` 中定義以下資料結構。

```c
#ifndef COMBAT_MGR_H
#define COMBAT_MGR_H

#include <stdint.h>
#include <stdbool.h>

typedef enum {
    STATE_IDLE,
    STATE_MOVE,
    STATE_ATTACK,
    STATE_PARRY,
    STATE_BLOCK,
    STATE_HURT,
    STATE_STUNNED,
    STATE_EXECUTION
} EntityState;

typedef enum {
    INPUT_ATTACK = 0,
    INPUT_PARRY  = 1,
    INPUT_JUMP   = 2,
    INPUT_DASH   = 3
} InputType;

typedef enum {
    ATTACK_NORMAL = 0,
    ATTACK_THRUST = 1,
    ATTACK_SWEEP  = 2,
    ATTACK_GRAB   = 3
} AttackType;

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
} AttackPacket;

typedef struct {
    InputType input_type;
    uint64_t timestamp_ms;
    bool valid;
} InputBuffer;

#endif
```

---

## 5. GDExtension API Protocol

C 模組必須暴露給 Godot 以下功能。

### 5.1 必要 API

```c
void register_input(int input_type, uint64_t timestamp_ms);

void notify_attack_active(int attack_id, int attack_type, uint64_t timestamp_ms);

void update_combat(float delta);

bool is_parry_successful(void);

void reset_combat(void);

void force_bpm(float value);

float get_player_hp(void);
float get_player_posture(void);
float get_player_bpm(void);
int get_player_state(void);

float get_boss_hp(void);
float get_boss_posture(void);
int get_boss_state(void);

int get_last_parry_delta_ms(void);
int get_current_attack_id(void);
int get_boss_ai_state(void);
```

### 5.2 GDScript 包裝建議

Godot 端可以用 `Dictionary get_combat_update(float delta)` 包裝資料，方便 ViewManager 與 HUD 更新。

回傳 Dictionary 至少包含：

```gdscript
{
    "player_hp": float,
    "player_posture": float,
    "player_bpm": float,
    "player_state": int,
    "boss_hp": float,
    "boss_posture": float,
    "boss_state": int,
    "boss_ai_state": int,
    "current_attack_id": int,
    "last_parry_delta_ms": int,
    "is_parry_successful": bool
}
```

---

## 6. 時間來源與判定規則

### 6.1 統一時間來源

Godot 使用：

```gdscript
Time.get_ticks_msec()
```

所有 input timestamp 與 attack active timestamp 都從 Godot 傳入 C。

C 不自行取得 engine time，避免時間來源不一致。

---

### 6.2 Attack Active Timestamp

Boss 動畫進入攻擊判定幀時，由 Godot 呼叫：

```gdscript
combat.notify_attack_active(attack_id, attack_type, Time.get_ticks_msec())
```

例如：

| 動作 | 總幀數 | Active Frame |
|---|---:|---:|
| BossThrust | 24 | 第 18 幀 |
| BossSweep | 30 | 第 22 幀 |

---

### 6.3 Parry Window

Perfect Parry 判定：

```text
delta = parry_input_timestamp - attack_active_timestamp
```

成功條件：

```text
-100ms <= delta <= +50ms
```

意思：

- 玩家可稍微早按
- 玩家不可太晚按
- 保留動作遊戲需要的手感容錯

---

### 6.4 Input Buffer

採用 single-slot input buffer。

規則：

```text
Parry input 保留 150ms
Attack input 保留 150ms
Jump input 保留 150ms
Dash input 保留 150ms
```

新 input 進來時覆蓋舊 input。

若角色進入 STUNNED 或 EXECUTION，input buffer 必須立刻清空。

---

## 7. 輸入映射

| Action | Key | 說明 |
|---|---|---|
| Move Left | A | 向左移動 |
| Move Right | D | 向右移動 |
| Attack | J | 攻擊，不可取消 Startup |
| Parry / Block | K | 按下瞬間為 Parry，持續按住為 Block |
| Dodge / Dash | L | 0.2s 無敵，中斷 BPM 回復 |
| Jump | Space | 應對 Sweep 下段攻擊 |
| Toggle Debug | F1 | 切換 Debug Overlay |
| Force BPM | F2 | 強制 BPM = 200 |
| Reset Combat | F5 / R | 快速重置 Boss 房 |

---

## 8. 玩家物理與移動

位移由 Godot `CharacterBody2D` 的 physics velocity 主導。

Animation 只負責視覺，不主導位移。

### 8.1 移動參數

```gdscript
MAX_SPEED = 400.0
ACCELERATION = 2000.0
FRICTION = 1500.0
DASH_IMPULSE = 1200.0
JUMP_VELOCITY = -600.0
JUMP_STARTUP = 0.05
COYOTE_TIME = 0.1
LANDING_RECOVERY_FRAMES = 5
```

### 8.2 Dodge / Dash

```text
Dodge i-frame: 0.2s
Dodge 不消耗 stamina
Dodge 會中斷 BPM 回復 1 秒
Dodge 主要作為位置調整，不應取代 Parry
```

### 8.3 Jump

```text
Jump startup: 3 frames / 0.05s
Coyote time: 0.1s
Landing recovery: 5 frames
```

---

## 9. 戰鬥狀態機

### 9.1 EntityState Priority

由高到低：

| Priority | State | 可被覆蓋 | 說明 |
|---:|---|---|---|
| 100 | EXECUTION | No | 處決中，忽略所有輸入 |
| 90 | STUNNED | No | 破防僵直，含 i-frame |
| 80 | HURT | Yes | 可被 STUNNED 覆蓋 |
| 70 | PARRY | Yes | 可被 STUNNED 覆蓋 |
| 60 | ATTACK | Recovery only | Startup 不可取消，Recovery 可被 Parry / Dodge 取消 |
| 50 | BLOCK | Yes | 持續防禦 |
| 10 | MOVE | Yes | 基礎狀態 |
| 0 | IDLE | Yes | 基礎狀態 |

### 9.2 轉換規則

```text
IDLE -> MOVE:
    velocity.x != 0

ANY -> STUNNED:
    posture >= 100

ANY -> EXECUTION:
    boss posture >= 100 且玩家觸發處決

IDLE / MOVE / BLOCK -> PARRY:
    parry input within buffer

ATTACK -> PARRY:
    只有 Attack Recovery 階段可以取消

ATTACK -> DODGE:
    只有 Attack Recovery 階段可以取消

STUNNED / EXECUTION:
    清空所有 input buffer
```

---

## 10. 攻擊相位與重量感

重量感來自時間分配，不是單純靠 screen shake。

### 10.1 Attack Phases

每個攻擊分為：

1. Anticipation 前搖
2. Active 判定
3. Recovery 收招

### 10.2 時間分配原則

```text
Anticipation: 佔動作約 60%
Active: 極短，約 3 至 5 幀
Recovery: 佔動作約 30%
```

### 10.3 動畫曲線

```text
前搖使用 ease-in，從慢到快
Active frame 配合物理衝量
Recovery 需要有明顯重心恢復與慣性
```

---

## 11. BPM 系統

### 11.1 基本值

```text
MIN_BPM = 65
MAX_BPM = 200
```

### 11.2 BPM 變化

| 行為 | BPM 變化 |
|---|---:|
| 攻擊命中 | +10 |
| 普通格擋 | +5 |
| 被擊中 | +30 |
| Dash / Dodge | 中斷 BPM 回復 1 秒 |
| 非戰鬥狀態 | 緩慢回復至 65 |

### 11.3 BPM 對 Posture Recovery 的影響

```c
recovery_mul = max(0.1f, 1.0f - bpm / 200.0f);
posture_recovery = base_recovery * recovery_mul;
```

當 BPM 高時：

- Posture 回復變慢
- 玩家壓力變大
- 但攻擊收益提高

### 11.4 高 BPM 壓力效果

當 BPM > 160：

Godot 表現層啟動：

1. 紅色 vignette shader
2. BPM 數字微抖動
3. 心跳聲音量提高
4. BGM low-pass filter
5. 背景音降低

### 11.5 Heartbeat Pitch Formula

```gdscript
pitch = 1.0 + pow((bpm - 65.0) / 135.0, 1.5) * 0.3
pitch = clamp(pitch, 1.0, 1.3)
```

避免 pitch 過高產生「花栗鼠效應」。

---

## 12. Posture 系統

### 12.1 基本規則

```text
Posture 範圍：0 到 100
```

| 事件 | 玩家 Posture | Boss Posture |
|---|---:|---:|
| Perfect Parry | +5 | +20 |
| Normal Block | +30 | +5 |
| 被直接擊中 | +30 | +0 |
| 玩家攻擊命中 | +0 | +10 |

### 12.2 Block Tax

普通格擋懲罰：

```text
玩家 Posture Gain 加倍
玩家 BPM +5
玩家 Knockback 50px / 0.1s
播放 block_dull.wav
```

目的：

> 防止玩家只靠長按 Block 通關，鼓勵 Perfect Parry。

### 12.3 Posture Break

當 posture >= 100：

```text
進入 STUNNED
獲得 0.5s i-frame
清空 input buffer
觸發 posture_crack.wav
```

Boss Posture Break 後，玩家可觸發 Execution。

---

## 13. Attack ID System

每次 Boss 攻擊 Active Frame 觸發時，生成新的 AttackPacket。

```c
AttackPacket packet;
packet.id = attack_id;
packet.type = attack_type;
packet.active_frame_ms = timestamp_ms;
packet.processed = false;
```

規則：

1. 同一個 attack_id 只能被處理一次
2. processed == true 後不可再次 parry
3. 多段攻擊必須使用不同 attack_id
4. Phase Transition 時清空目前 AttackPacket
5. Reset_Combat 時清空目前 AttackPacket

---

## 14. Perilous Attack 危字攻擊

### 14.1 Attack Type

| Type | 名稱 | 應對方式 |
|---:|---|---|
| 0 | Normal | 可 Block，可 Parry |
| 1 | Thrust | 可 Parry，但不可普通 Block |
| 2 | Sweep | 必須 Jump |
| 3 | Grab | 必須 Dodge |

### 14.2 Silhouette Readability

Boss 動畫必須讓玩家在極短時間內辨識攻擊類型。

| 類型 | 視覺語言 |
|---|---|
| Thrust | 武器向後收縮，呈點狀輪廓 |
| Sweep | Boss 重心降低，武器貼地橫掃，呈扁平輪廓 |
| Grab | 手臂大幅張開，呈擴張輪廓 |

### 14.3 Readability First

當危字提示出現時：

```text
暫停所有 screen shake
暫停 motion blur
確保玩家看得清攻擊方向
```

---

## 15. Hitstop 與打擊感

### 15.1 禁止事項

嚴禁使用：

```gdscript
Engine.time_scale = 0
```

### 15.2 Fake Hitstop

Perfect Parry 時：

```text
暫停玩家與 Boss AnimationPlayer 0.05s
暫停視覺位移 0.05s
不暫停 C 戰鬥時鐘
不暫停 UI
不暫停 Audio
不暫停 Shader
```

目的：

> 產生打擊感，但避免 Timer / Audio / Shader 出錯。

---

## 16. Juice Hierarchy

| 事件 | 回饋 |
|---|---|
| Hurt | 小粒子、微震 |
| Block | 悶聲、50px knockback、小火花 |
| Perfect Parry | 金色火花、0.05s hitstop、清脆 clang |
| Posture Break | 全場 audio ducking、金屬碎裂聲、低頻震動 |
| Execution | 0.1s 完全寂靜 -> 慢動作紅色斬擊 -> 爆發音效 |

---

## 17. Audio System

建立 `SFX_Manager.gd`。

### 17.1 Audio Pool

```text
Parry_Pool:
    4 個 AudioStreamPlayer
    輪流播放 clang.wav

Posture_Crack:
    單一高優先權 AudioStreamPlayer

Heartbeat:
    循環 AudioStreamPlayer
    pitch_scale 根據 bpm 改變
```

### 17.2 Audio Priority

| Priority | SFX |
|---:|---|
| 100 | Execution |
| 90 | Posture Break |
| 80 | Perfect Parry |
| 60 | Hurt |
| 50 | Block |
| 20 | Footstep |

高優先權音效可 duck 低優先權音效。

---

## 18. Boss AI FSM

Boss AI 由 C 計算，Godot 根據回傳狀態播放動畫。

### 18.1 AI State

```c
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
```

### 18.2 決策表

| 條件 | Boss 行為 |
|---|---|
| distance > 400px | CHASE |
| distance < 150px 且玩家非防禦 | 70% ATTACK_COMBO, 30% SWEEP |
| distance < 150px 且玩家防禦中 | 50% GRAB, 50% HEAVY_THRUST |
| Boss HP < 50% 且尚未轉階段 | PHASE_TRANSITION |
| Player BPM > 160 | 攻擊頻率 +15%，但不縮短判定窗口 |

### 18.3 節奏系統

Boss 攻擊前搖與判定點盡量對齊節拍。

```text
Beat_Duration = 60.0 / Current_BPM
```

公平性原則：

```text
BPM 提高時，Boss 攻擊頻率可以提高。
但 Parry Window 不可縮短。
```

即：

> 戰鬥變快，但規則不變。

---

## 19. Rhythm Interruption

玩家連續兩次 Perfect Parry 可中斷 Boss 一般連段，讓玩家搶回主導權。

限制：

```text
Rhythm Interruption cooldown: 5 秒
Boss Phase Transition 不可被中斷
Boss Execution 狀態不可被中斷
```

---

## 20. Boss Phase 2

### 20.1 觸發條件

```text
Boss HP <= 50%
```

### 20.2 轉階段流程

```text
Boss 進入 AI_PHASE_TRANSITION
Boss 無敵
清空 AttackPacket
清空 InputBuffer
播放全螢幕紅色 Shader
BGM pitch_scale 提升
背景加入心跳脈動
Phase 2 開始
```

Phase Transition 期間：

1. Boss 不可被傷害
2. 玩家輸入不應觸發攻擊判定
3. 目前攻擊事件全部清空
4. 避免 transition 被打斷造成狀態錯亂

---

## 21. UI / HUD

### 21.1 HUD Layout

| 位置 | 元素 |
|---|---|
| 左上角 | Player HP、BPM |
| 中央底部 | 雙向 Posture Bar，Player 左，Boss 右 |
| 角色頭頂 / CanvasLayer | 危字提示 |
| F1 Debug | Timestamp、DeltaT、AI State、Attack ID |

### 21.2 Debug Overlay

F1 切換顯示。

必須顯示：

```text
Player HP
Player Posture
Player BPM
Player State
Boss HP
Boss Posture
Boss AI State
Current Attack ID
Last Parry Delta
Last Attack Timestamp
Input Buffer Type
Input Buffer Age
Is Parry Successful
Is Boss Phase 2
```

### 21.3 Demo UI Strategy

Demo 分兩段：

```text
解說階段：開啟 Debug Overlay
實戰階段：關閉 Debug Overlay，只保留正式 HUD
```

---

## 22. Debug Hotkeys

| Key | 功能 |
|---|---|
| F1 | Toggle Debug Overlay |
| F2 | Force BPM = 200 |
| F5 | Reset_Combat |
| R | 快速重置 Boss 房 |

---

## 23. Reset_Combat

Reset_Combat 不可 reload scene。

必須在 0.5 秒內完成：

```text
Player 回初始位置
Boss 回初始位置
Player HP reset
Player Posture reset
Player BPM reset
Boss HP reset
Boss Posture reset
Boss phase reset
Input buffer clear
Attack packet clear
HUD reset
Camera reset
Fade-to-black 0.5s
```

---

## 24. Camera

### 24.1 Camera Smoothing

```gdscript
smoothing_weight = 0.1
```

### 24.2 Look-ahead

```text
根據玩家面向偏移 100px
加入 deadzone
避免玩家左右轉向時相機劇烈甩動
```

### 24.3 Camera Shake

| 事件 | Shake |
|---|---|
| Hurt | Small |
| Perfect Parry | Short strong |
| Posture Break | Low-frequency long |
| Execution | One large impulse |

當危字提示出現時：

```text
暫停所有 screen shake
暫停 motion blur
確保玩家能看清攻擊
```

---

## 25. Arena

```text
寬度：約 3840px
約 2 個螢幕寬
兩側空氣牆
背景偏暗
危字使用鮮紅色
Parry spark 使用金色
```

目的：

> 減少逃跑空間，強化高壓感與 Boss 節奏。

---

## 26. Animation Manifest

MVP 動作集，不要超出此範圍。

### 26.1 Player

| 動作 | 幀數 | 備註 |
|---|---:|---|
| Idle | 4 | 可循環 |
| Run | 8 | 可循環 |
| Attack_A | 12 | Active Frame 第 6 幀 |
| Attack_B | 12 | Active Frame 第 7 幀 |
| Parry_Action | 6 | 第 1-3 幀為 Parry visual |
| Jump | 6 | 包含起跳 |
| Hurt | 4 | 短暫硬直 |
| Death | 8 | Demo 可簡化 |

### 26.2 Boss

| 動作 | 幀數 | Active Frame |
|---|---:|---:|
| Idle | 4 | 無 |
| Walk | 8 | 無 |
| Thrust_Attack | 24 | 第 18 幀 |
| Sweep_Attack | 30 | 第 22 幀 |
| Stunned | 8 | 無 |
| Phase_Transition | 24 | 無 |

---

## 27. Collision Layers

| Layer | 用途 |
|---:|---|
| 1 | Environment / Ground |
| 2 | Player Body |
| 3 | Boss / Enemy Body |
| 4 | Player Hitbox |
| 5 | Boss / Enemy Hitbox |
| 6 | UI / Detection / Misc |

---

## 28. State Validation

GDScript 不要依賴 try-catch 風格處理錯誤。

請使用狀態驗證：

```gdscript
func _physics_process(delta):
    if not is_instance_valid(player) or player.is_queued_for_deletion():
        return

    if not is_instance_valid(boss) or boss.is_queued_for_deletion():
        return

    # Normal logic here
```

C 模組也需確保：

```text
不操作已不存在的 Godot Entity
Reset 時清空所有暫存 attack/input 狀態
Pause 時清空 input buffer 與 active attack timestamp
```

---

## 29. Pause-Safe Design

當遊戲暫停時：

```text
清空 InputBuffer
清空 Attack_Active_Timestamp
清空目前未處理 AttackPacket
停止接受新 combat input
Resume 後等待下一個有效 attack active frame
```

目的：

> 防止 Resume 後瞬間觸發錯誤 hit / parry / damage。

---

## 30. Fallback Strategy

若時間不足或 C / GDExtension 出現問題，採用以下保底方案。

| 系統 | 預計方案 | 保底方案 |
|---|---|---|
| AI | C weighted FSM | 固定攻擊 Pattern |
| BPM UI | 動態電圖 | 數字 + 顏色閃爍 |
| Heartbeat 音效 | pitch_scale 連動 | Normal / Panic 兩段音軌 |
| Shader | 紅色脈動 shader | 紅色 CanvasLayer overlay |
| Posture Graph | 即時折線圖 | 文字數字顯示 |
| C Crash | GDExtension | 關鍵邏輯轉 GDScript |

---

## 31. Demo Script

6/09 展示流程：

### Step 1：技術展示

開啟 Debug Overlay。

展示：

```text
Player movement
BPM 自動回復
F2 強制 BPM = 200
Posture Recovery 變慢
```

### Step 2：防禦機制

故意普通 Block。

展示：

```text
Block Tax
Posture 快速累積
BPM +5
悶聲音效
Knockback
```

### Step 3：核心技術

連續三次 Perfect Parry。

展示：

```text
Parry_Delta_T
Attack ID
Hitstop
金色火花
clang.wav
Boss Posture 上升
```

### Step 4：Phase 2

把 Boss 打到 50% HP 以下。

展示：

```text
Boss 無敵轉場
紅色 Shader
BPM 壓力效果
Boss 攻擊頻率提升
```

### Step 5：Ending

觸發 Boss Posture Break。

展示：

```text
Audio Ducking
Posture Crack
Execution
0.1s silence
紅色斬擊
Demo 結束
```

---

## 32. Non-Cuttables

以下功能絕對不可刪：

1. Timestamp Parry Logic
2. Input Buffer
3. BPM to Posture Recovery Formula
4. Boss Phase 2 Transition
5. Debug Overlay
6. Reset_Combat
7. At least one Boss Attack with Active Frame Notification
8. Fake Hitstop
9. Attack ID System

---

## 33. 開發順序

Codex 請依照以下順序實作。

### Phase 1：最小可玩

1. 建立 Godot 4.6.2 project
2. 建立 Player CharacterBody2D
3. 建立 Boss CharacterBody2D
4. 建立 C GDExtension skeleton
5. 實作 HP / Posture / BPM
6. 實作 `register_input`
7. 實作 `notify_attack_active`
8. 實作 parry timing
9. 實作 Debug Overlay

完成標準：

```text
Boss 攻擊
玩家按 K
C 判斷 Parry 成功或失敗
HUD 顯示 DeltaT
```

---

### Phase 2：打擊感

1. Fake Hitstop
2. Parry Spark
3. Audio Pool
4. Knockback
5. Camera Shake

完成標準：

```text
Perfect Parry 時必須有 clang、hitstop、spark、shake
```

---

### Phase 3：BPM 系統

1. BPM 上升與回復
2. BPM 影響 Posture Recovery
3. BPM UI
4. Heartbeat pitch
5. BPM > 160 視覺壓力

完成標準：

```text
F2 強制 BPM = 200 後，Posture Recovery 明顯變慢
```

---

### Phase 4：Boss AI

1. CHASE
2. ATTACK_COMBO
3. SWEEP
4. GRAB 或 HEAVY_THRUST 擇一
5. Phase 2 transition

完成標準：

```text
Boss 能根據距離與玩家防禦狀態改變行為
```

---

### Phase 5：Demo Polish

1. Debug hotkeys
2. Reset_Combat
3. Execution
4. Demo Script flow
5. README

完成標準：

```text
可以從頭到尾穩定展示 3 分鐘，不 crash，不需重開 Godot。
```

---

## 34. 最終交付物

Codex 最終需要產出：

```text
1. 完整 Godot 4.6.2 project
2. C GDExtension source code
3. SConstruct
4. combat.gdextension
5. README.md
6. rebuild.sh
7. test_chamber.tscn
8. Debug Overlay
9. Reset_Combat hotkey
10. 可執行 Demo 流程
```

README 必須包含：

```text
Ubuntu 24.04 dependency installation
scons build command
Godot project open command
Debug hotkeys
Demo steps
Known fallback options
```

---

## 35. 最重要的開發原則

請先完成以下核心循環：

```text
敵人攻擊
↓
玩家彈反
↓
CLANG
↓
Hitstop
↓
Posture 增加
↓
Debug Overlay 顯示 DeltaT
```

再做其他功能。

本專案的核心不是內容量，而是：

> 精準彈反 + BPM 壓力 + 打鐵感。

請不要一開始就追求完整美術、完整 Boss、完整 Shader。

先做出可玩的方塊人 prototype，再逐步替換成正式素材。
