# Sub-Phase 2-1: 데이터 리소스 클래스 설계

> Parent Phase: Phase 2 — Core Skeleton
> 목표: CharacterData, EnemyData, NPCData Resource 클래스 구현 — JSON/Resource 기반 데이터 중심 설계

---

## 2.1.1 CharacterData Resource (`scripts/data/character_data.gd`)

### 작업 내용
- 플레이어블 캐릭터 데이터를 정의하는 Resource 클래스 생성
- 고유 패시브, 기본 무기, 이동 속도, SD 스프라이트 시트 경로 포함

### 상세 스펙

```
class_name CharacterData
extends Resource

@export_group("Basic")
@export var character_id: String = ""           # 고유 ID (예: "gs_vamsur")
@export var character_name: String = ""         # 표시 이름
@export var description: String = ""            # 캐릭터 설명

@export_group("Stats")
@export var base_hp: int = 100                  # 기본 HP
@export var base_max_hp: int = 100              # 최대 HP
@export var base_attack: int = 10               # 기본 공격력
@export var base_defense: int = 5               # 기본 방어력
@export var base_speed: float = 200.0           # 기본 이동 속도

@export_group("Equipment")
@export var default_weapon_id: String = ""      # 기본 무기 ID
@export var weapon_type: String = "sword"       # 기본 무기 타입

@export_group("Sprite")
@export var sprite_sheet_path: String = ""      # SD 스프라이트 시트 경로 (res://assets/sprites/...)
@export var sprite_frames: Dictionary = {       # 프레임 정의
    "idle": {"cols": 4, "rows": 1, "fps": 4},
    "walk": {"cols": 8, "rows": 1, "fps": 8},
    "attack": {"cols": 6, "rows": 1, "fps": 10}
}

@export_group("Passive")
@export var passive_skill_ids: Array[String] = []  # 고유 패시브 스킬 ID 목록
```

### 완료 기준
- [ ] `character_data.gd`가 `scripts/data/`에 생성됨
- [ ] `class_name CharacterData extends Resource` 정의됨
- [ ] Godot에서 `.tres` 파일로 저장/로드 가능
- [ ] 모든 @export 필드가 Inspector에서 확인/편집 가능

---

## 2.1.2 EnemyData Resource (`scripts/data/enemy_data.gd`)

### 작업 내용
- 적 몬스터 데이터를 정의하는 Resource 클래스 생성
- AI 패턴, 스탯, 드랍 테이블 정의

### 상세 스펙

```
class_name EnemyData
extends Resource

@export_group("Basic")
@export var enemy_id: String = ""               # 고유 ID (예: "grunt_01")
@export var enemy_name: String = ""             # 표시 이름
@export var enemy_type: String = "normal"       # normal / elite / boss

@export_group("Stats")
@export var hp: int = 50                        # HP
@export var attack: int = 5                     # 공격력
@export var defense: int = 2                    # 방어력
@export var speed: float = 80.0                 # 이동 속도
@export var attack_range: float = 50.0          # 근접 공격 범위

@export_group("AI")
@export var ai_pattern: String = "chase"        # chase / ranged / charge

@export_group("Sprite")
@export var sprite_sheet_path: String = ""
@export var sprite_frames: Dictionary = {}

@export_group("Drops")
@export var drop_table: Array[Dictionary] = []  # [{item_id, chance, min_qty, max_qty}]
@export var exp_reward: int = 10                # 사격 시 경험치 보상
```

### 드랍 테이블 예시

```json
{
    "item_id": "gold_coin",
    "chance": 1.0,
    "min_qty": 1,
    "max_qty": 5
}
```

### 완료 기준
- [ ] `enemy_data.gd`가 `scripts/data/`에 생성됨
- [ ] `class_name EnemyData extends Resource` 정의됨
- [ ] AI 패턴, 스탯, 드랍 테이블, 경험치 보상 필드 확인 가능
- [ ] `.tres` 파일로 저장/로드 가능

---

## 2.1.3 NPCData Resource (`scripts/data/npc_data.gd`)

### 작업 내용
- NPC 데이터를 정의하는 Resource 클래스 생성
- 대화 이벤트, 상호작용 트리거 포함

### 상세 스펙

```
class_name NPCData
extends Resource

@export_group("Basic")
@export var npc_id: String = ""                 # 고유 ID
@export var npc_name: String = ""               # 표시 이름
@export var npc_role: String = "merchant"       # merchant / quest / lore / trainer

@export_group("Sprite")
@export var sprite_sheet_path: String = ""

@export_group("Dialogue")
@export var dialogue_tree: Dictionary = {}      # { "greeting": [...], "farewell": [...] }
# dialogue 예시: [{"speaker": "NPC", "text": "안녕하세요!"}, ...]

@export_group("Interaction")
@export var interaction_events: Array[Dictionary] = []  # [{type, target, params}]
# type: "trade", "quest", "info", "skill_upgrade"
```

### 완료 기준
- [ ] `npc_data.gd`가 `scripts/data/`에 생성됨
- [ ] `class_name NPCData extends Resource` 정의됨
- [ ] 대화 트리, 상호작용 이벤트 필드 확인 가능
- [ ] `.tres` 파일로 저장/로드 가능

---

## 2.1.4 데이터 로드 매니저 (`scripts/data/data_loader.gd`)

### 작업 내용
- JSON/Resource 파일을 동적으로 로드하는 매니저
- `data/` 폴더 구조에서 타입별 데이터 조회

### 상세 스펙

```
class_name DataLoader
extends Node

var character_cache: Dictionary = {}   # { character_id: CharacterData }
var enemy_cache: Dictionary = {}       # { enemy_id: EnemyData }
var npc_cache: Dictionary = {}         # { npc_id: NPCData }
var item_cache: Dictionary = {}        # { item_id: ItemData }
var skill_cache: Dictionary = {}       # { skill_id: SkillData }
var stage_cache: Dictionary = {}       # { stage_id: StageData }

func load_all() -> void
func load_characters() -> void
func load_enemies() -> void
func load_npcs() -> void
func load_items() -> void
func load_skills() -> void
func load_stages() -> void

func get_character(id: String) -> CharacterData
func get_enemy(id: String) -> EnemyData
func get_npc(id: String) -> NPCData
func get_item(id: String) -> Variant
func get_skill(id: String) -> Variant
func get_stage(id: String) -> Variant
```

### 파일 로드 경로

| 타입 | 폴더 | 확장자 |
|------|------|--------|
| CharacterData | `data/characters/` | `.tres` 또는 `.json` |
| EnemyData | `data/enemies/` | `.tres` 또는 `.json` |
| NPCData | `data/npcs/` | `.tres` 또는 `.json` |
| ItemData | `data/items/` | `.tres` 또는 `.json` |
| SkillData | `data/skills/` | `.tres` 또는 `.json` |
| StageData | `data/stages/` | `.tres` 또는 `.json` |

### 완료 기준
- [ ] `data_loader.gd`가 생성됨
- [ ] `load_all()` 호출 시 모든 폴더의 데이터 로드
- [ ] 캐시에 저장된 데이터가 `get_*()`로 조회 가능
- [ ] 파일이 없거나 파싱 에러 시 graceful fallback (null 반환 + 로그)
- [ ] `.tres`와 `.json` 모두 지원

---

## Sub-Phase 2-1 완료 체크리스트

- [ ] `character_data.gd` 생성 + CharacterData Resource 정의 완료
- [ ] `enemy_data.gd` 생성 + EnemyData Resource 정의 완료
- [ ] `npc_data.gd` 생성 + NPCData Resource 정의 완료
- [ ] `data_loader.gd` 생성 + 캐시 기반 데이터 로드/조회 구현 완료
- [ ] 더미 `.tres` 파일로 각 데이터 타입 저장/로드 확인 완료
- [ ] DataLoader가 모든 타입을 한 번에 로드 가능 확인 완료
