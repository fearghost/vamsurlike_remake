# Sub-Phase 2-4: 스테이지 및 웨이브 관리

> Parent Phase: Phase 2 — Core Skeleton
> 목표: 스테이지별 몬스터 스폰 테이블, 웨이브 진행 로직 구현

---

## 2.4.1 StageData Resource (`scripts/data/stage_data.gd`)

### 작업 내용
- 스테이지 데이터를 정의하는 Resource 클래스 생성
- 스테이지 정보, 웨이브 구성, 보스 정보 포함

### 상세 스펙

```
class_name StageData
extends Resource

@export_group("Basic")
@export var stage_id: String = ""               # 고유 ID (예: "stage_01_01")
@export var stage_number: int = 1               # 스테이지 번호 (계열 + 넘버)
@export var chapter_number: int = 1             # 챕터 번호
@export var stage_name: String = ""             # 표시 이름
@export var description: String = ""            # 설명

@export_group("Wave")
@export var waves: Array[Dictionary] = []       # 웨이브별 몬스터 구성
# 예시: [{"enemies": [{"enemy_id": "chase_01", "count": 5}], "spawn_interval": 1.0}]

@export_group("Boss")
@export var boss_enemy_id: String = ""          # 보스 몬스터 ID (없으면 "")
@export var boss_spawn_wave: int = -1           # 보스 스폰 웨이브 인덱스 (-1 = 없음)

@export_group("Rewards")
@export var reward_gold: int = 100              # 클리어 보상 골드
@export var reward_exp: int = 50                # 클리어 보상 경험치
@export var reward_items: Array[Dictionary] = []  # [{item_id, qty}]

@export_group("Story")
@export var story_script_path: String = ""      # 스토리 시퀀스 JSON 경로
@export var post_combat_dialogue: Array[Dictionary] = []  # 전투 후 대사
```

### 웨이브 구성 예시

```json
{
    "enemies": [
        {"enemy_id": "chase_01", "count": 5},
        {"enemy_id": "ranged_01", "count": 3}
    ],
    "spawn_interval": 1.0
}
```

### 완료 기준
- [ ] `stage_data.gd`가 `scripts/data/`에 생성됨
- [ ] waves, boss_enemy_id, rewards, story_script_path 필드 확인 가능
- [ ] `.tres`로 저장/로드 가능

---

## 2.4.2 WaveManager (`scripts/game/wave_manager.gd`)

### 작업 내용
- 스테이지 내 웨이브 진행 관리
- Spawner와 연동하여 적 스폰

### 상세 스펙

```
class_name WaveManager
extends Node

signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal all_waves_cleared
signal boss_spawned(boss_enemy_id: String)
signal stage_cleared(stage_data: StageData)

var current_stage: StageData = null
var current_wave_index: int = 0
var active_enemy_count: int = 0
var is_boss_active: bool = false

func load_stage(stage_data: StageData) -> void
func start_next_wave() -> void
func on_enemy_died() -> void
func _check_wave_cleared() -> void
func _check_all_waves_cleared() -> void
func _spawn_boss_if_ready() -> void
```

### 진행 로직 스펙

**`load_stage(stage_data)`**:
1. `current_stage = stage_data`
2. `current_wave_index = 0`
3. `active_enemy_count = 0`
4. `is_boss_active = false`
5. `start_next_wave()` 호출

**`start_next_wave()`**:
1. `waves[current_wave_index]`에서 몬스터 구성 읽기
2. 각 몬스터 타입만큼 `Spawner.spawn_enemy()` 호출
3. `active_enemy_count += total_spawned`
4. `wave_started.emit(current_wave_index)` emit

**`on_enemy_died()`**:
1. `active_enemy_count -= 1`
2. 보스인 경우: `is_boss_active = false`
3. `_check_wave_cleared()` 호출

**`_check_wave_cleared()`**:
1. `active_enemy_count == 0`이고 보스가 아니면 → 웨이브 클리어
2. `wave_cleared.emit(current_wave_index)` emit
3. 다음 웨이브가 있으면 `current_wave_index += 1`, `start_next_wave()`
4. 없으면 `_check_all_waves_cleared()` 호출

**`_spawn_boss_if_ready()`**:
1. `boss_spawn_wave == current_wave_index`이고 `!is_boss_active` → 보스 스폰
2. `Spawner.spawn_enemy(boss_enemy_id, boss_position)`
3. `is_boss_active = true`, `boss_spawned.emit(boss_enemy_id)`

### 완료 기준
- [ ] `wave_manager.gd`가 생성됨
- [ ] 스테이지 로드 → 웨이브 시작 확인
- [ ] 적 사망 시 active_enemy_count 감소 확인
- [ ] 웨이브 클리어 시 다음 웨이브 자동 시작 확인
- [ ] 보스 스폰 조건 정상 작동 확인
- [ ] 모든 웨이브 클리어 시 `stage_cleared` 시그널 emit 확인

---

## 2.4.3 CombatArena (`scenes/game/combat_arena.gd`)

### 작업 내용
- 전투 씬의 코디네이터 역할 — WaveManager, Spawner, GameManager 연동

### 상세 스펙

```
class_name CombatArena
extends Node2D

@onready var wave_manager: Node = $WaveManager
@onready var spawner: Node = $Spawner
@onready var player: Node2D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void
func start_combat(stage_id: String) -> void
func on_player_died() -> void
func on_stage_cleared(stage_data: StageData) -> void
```

### 동작 스펙
1. `start_combat(stage_id)` 호출 → DataLoader에서 StageData 로드
2. WaveManager에 스테이지 데이터 전달 → 첫 웨이브 시작
3. 플레이어 사망 → GameOver 처리 (GameManager 상태 전환)
4. 스테이지 클리어 → 보상 계산 + Upgrade 화면으로 전환

### 완료 기준
- [ ] `combat_arena.gd`가 생성됨
- [ ] `start_combat()` 호출 시 스테이지 로드 + 첫 웨이브 시작
- [ ] 플레이어 사망 시 GameOver 처리 확인
- [ ] 스테이지 클리어 시 보상 계산 + Upgrade 화면 전환 확인
- [ ] GameManager, WaveManager, Spawner 연동 확인

---

## Sub-Phase 2-4 완료 체크리스트

- [ ] `stage_data.gd` 생성 + StageData Resource 정의 완료
- [ ] `wave_manager.gd` 생성 + 웨이브 진행 로직 구현 완료
- [ ] `combat_arena.gd` 생성 + 전투 코디네이터 구현 완료
- [ ] 웨이브별 몬스터 스폰 확인
- [ ] 보스 스폰 조건 확인
- [ ] 스테이지 클리어 → 보상 → 전환 루프 확인
- [ ] 더미 StageData로 전체 테스트 완료
