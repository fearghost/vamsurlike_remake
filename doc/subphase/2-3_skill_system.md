# Sub-Phase 2-3: 스킬 및 스킬 트리 시스템

> Parent Phase: Phase 2 — Core Skeleton
> 목표: SkillBase 클래스 + SkillTreeManager 구현 — 액티브/패시브 모듈화, 선행 조건 관리

---

## 2.3.1 SkillData Resource (`scripts/data/skill_data.gd`)

### 작업 내용
- 스킬 데이터를 정의하는 Resource 클래스 생성
- 액티브/패시브 구분, 효과 모듈화, 선행 스킬 노드 포함

### 상세 스펙

```
class_name SkillData
extends Resource

enum SkillType { ACTIVE, PASSIVE }
enum EffectType { DAMAGE, HEAL, BUFF, DEBUFF, SUMMON, UTILITY }

@export_group("Basic")
@export var skill_id: String = ""               # 고유 ID
@export var skill_name: String = ""             # 표시 이름
@export var skill_type: SkillType = SkillType.ACTIVE  # ACTIVE / PASSIVE
@export var description: String = ""            # 설명

@export_group("Cost")
@export var mp_cost: int = 10                   # MP 소모 (ACTIVE 전용)
@export var cooldown: float = 2.0               # 재사용 대기시간 (초)

@export_group("Effect")
@export var effect_type: EffectType = EffectType.DAMAGE
@export var effect_params: Dictionary = {}      # { "damage_multiplier": 1.5, "duration": 3.0 }
# 예시: {"base_damage": 20, "scaling": "attack", "hit_count": 1}

@export_group("Tree")
@export var prerequisite_ids: Array[String] = []  # 선행 스킬 ID 목록
@export var unlock_level: int = 1               # 해금 필요 레벨
@export var tree_node_position: Vector2 = Vector2(0, 0)  # UI 트리 노드 위치

@export_group("Sprite")
@export var icon_path: String = ""              # UI 아이콘 경로
```

### 효과 파라미터 예시

| 효과 타입 | effect_params 예시 |
|----------|-------------------|
| DAMAGE | `{"base_damage": 20, "scaling": "attack", "hit_count": 1}` |
| HEAL | `{"base_heal": 30, "scaling": "max_hp", "percent": 0.3}` |
| BUFF | `{"stat": "attack", "bonus": 10, "duration": 10.0}` |
| DEBUFF | `{"stat": "speed", "reduction": 0.2, "duration": 5.0}` |

### 완료 기준
- [ ] `skill_data.gd`가 `scripts/data/`에 생성됨
- [ ] SkillType enum + EffectType enum 정의 완료
- [ ] prerequisite_ids, unlock_level 필드 확인 가능
- [ ] `.tres`로 저장/로드 가능

---

## 2.3.2 SkillTreeManager (`scripts/skill/skill_tree_manager.gd`)

### 작업 내용
- 스킬 트리 해금/선행 조건/스킬 포인트 관리
- DataLoader와 연동하여 모든 스킬 데이터 로드

### 상세 스펙

```
class_name SkillTreeManager
extends Node

signal skill_unlocked(skill_id: String)
signal skill_point_allocated(skill_id: String, points: int)
signal skill_point_changed(remaining: int)

@export var total_skill_points: int = 0
var allocated_points: Dictionary = {}   # { skill_id: invested_points }
var unlocked_skills: Array[String] = []  # 해금된 스킬 ID 목록

func _ready() -> void
func load_all_skills() -> void
func can_unlock(skill_id: String) -> bool
func unlock_skill(skill_id: String) -> bool
def allocate_point(skill_id: String, points: int = 1) -> bool
def remove_point(skill_id: String, points: int = 1) -> bool
def get_skill_level(skill_id: String) -> int
def get_available_skills() -> Array[String]
def get_locked_skills() -> Array[String]
func _check_prerequisites(skill_id: String) -> bool
```

### 로직 스펙

**`can_unlock(skill_id)`**:
1. `unlock_level` 이하의 레벨인지 확인
2. 모든 `prerequisite_ids`가 해금되었는지 확인
3. 모두 충족 → true, 아니면 → false

**`unlock_skill(skill_id)`**:
1. `can_unlock()` 체크
2. 실패 시 false 반환
3. 성공 시 `unlocked_skills`에 추가
4. `skill_unlocked.emit(skill_id)` emit
5. 하위 스킬들의 해금 상태 재평가

**`allocate_point(skill_id, points)`**:
1. `total_skill_points >= points`인지 확인
2. `allocated_points[skill_id] += points`
3. `total_skill_points -= points`
4. `skill_point_allocated.emit(skill_id, points)` emit
5. `skill_point_changed.emit(total_skill_points)` emit

### 완료 기준
- [ ] `skill_tree_manager.gd`가 생성됨
- [ ] `load_all_skills()`로 스킬 데이터 로드 확인
- [ ] 선행 조건 없는 스킬은 즉시 해금 가능
- [ ] 선행 조건 있는 스킬은 부모 해금 전까지锁定
- [ ] 스킬 포인트 할당/반환 정상 작동
- [ ] 시그널 emit 확인 완료

---

## 2.3.3 SkillExecutor (`scripts/skill/skill_executor.gd`)

### 작업 내용
- 액티브 스킬 발동 로직
- MP 소모, 쿨다운 관리, 효과 적용

### 상세 스펙

```
class_name SkillExecutor
extends Node

signal skill_cast(skill_id: String)
signal skill_on_cooldown(skill_id: String, remaining: float)
signal skill_effect_applied(effect_type: String, params: Dictionary)

var active_skills: Dictionary = {}   # { skill_id: SkillData }
var cooldown_timers: Dictionary = {}  # { skill_id: Timer }
var mp_current: int = 100
var mp_max: int = 100

func cast_skill(skill_id: String) -> bool
func _on_cooldown_finished(skill_id: String) -> void
func apply_effect(effect_type: String, params: Dictionary, target: Node2D) -> void
func regenerate_mp(amount: int) -> void
```

### 발동 로직 스펙

1. **MP 체크**: `mp_current >= skill.mp_cost` → 아니면 false 반환
2. **쿨다운 체크**: 해당 스킬의 쿨다운 타이머가 없어야 함 → 아니면 false 반환
3. **MP 소모**: `mp_current -= skill.mp_cost`
4. **쿨다운 시작**: Timer 생성, `cooldown_timers[skill_id] = timer`
5. **효과 적용**: `apply_effect()` 호출
6. **시그널 emit**: `skill_cast.emit(skill_id)`

### 완료 기준
- [ ] `skill_executor.gd`가 생성됨
- [ ] MP 소모 + 쿨다운 관리 확인
- [ ] 효과 적용 로직이 effect_type별 분기 확인 (더미: 로그 출력)
- [ ] 시그널 emit 확인 완료

---

## Sub-Phase 2-3 완료 체크리스트

- [ ] `skill_data.gd` 생성 + SkillData Resource 정의 완료
- [ ] `skill_tree_manager.gd` 생성 + 스킬 트리 해금/선행 조건 관리 구현 완료
- [ ] `skill_executor.gd` 생성 + 액티브 스킬 발동 로직 구현 완료
- [ ] 선행 조건에 따른 스킬 해금/锁定 정상 작동 확인
- [ ] 스킬 포인트 할당/반환 확인
- [ ] MP 소모 + 쿨다운 + 효과 적용 확인 (더미)
- [ ] 더미 스킬 데이터로 전체 테스트 완료
