# Sub-Phase 2-2: 장비 시스템

> Parent Phase: Phase 2 — Core Skeleton
> 목표: 8부위 장비 장착 시스템 + 양손 무기 ↔ 방패 제약 로직 구현

---

## 2.2.1 ItemData Resource (`scripts/data/item_data.gd`)

### 작업 내용
- 아이템(장비) 데이터를 정의하는 Resource 클래스 생성
- 부위별 슬롯, 속성, 제약 조건 포함

### 상세 스펙

```
class_name ItemData
extends Resource

enum ItemType { HELMET, SHIELD, ARMOR, WEAPON, BOOTS, RING_1, RING_2, NECKLACE }

@export_group("Basic")
@export var item_id: String = ""                # 고유 ID
@export var item_name: String = ""              # 표시 이름
@export var item_type: ItemType = ItemType.HELMET  # 부위 타입
@export var description: String = ""            # 설명

@export_group("Stats")
@export var stat_bonus: Dictionary = {}         # { "hp": +10, "attack": +3, ... }

@export_group("Constraints")
@export var is_two_handed: bool = false         # 양손 무기 여부 (WEAPON 타입 전용)
@export var required_level: int = 1             # 착용 필요 레벨
@export var required_stats: Dictionary = {}     # { "attack": 20 } 등

@export_group("Sprite")
@export var icon_path: String = ""              # UI 아이콘 경로
```

### 슬롯 타입 정의

| SlotType | 상수 | 설명 |
|----------|------|------|
| HELMET | `SlotType.HELMET` | 투구 |
| SHIELD | `SlotType.SHIELD` | 방패 |
| ARMOR | `SlotType.ARMOR` | 갑옷 |
| WEAPON | `SlotType.WEAPON` | 무기 |
| BOOTS | `SlotType.BOOTS` | 신발 |
| RING_1 | `SlotType.RING_1` | 반지 1 |
| RING_2 | `SlotType.RING_2` | 반지 2 |
| NECKLACE | `SlotType.NECKLACE` | 목걸이 |

### 완료 기준
- [ ] `item_data.gd`가 `scripts/data/`에 생성됨
- [ ] ItemType enum + 모든 필드 정의 완료
- [ ] `is_two_handed` 플래그 확인 가능
- [ ] `.tres`로 저장/로드 가능

---

## 2.2.2 EquipmentManager (`scripts/item/equipment_manager.gd`)

### 작업 내용
- 8슬롯 장비 장착 관리 autoload 노드
- 양손 무기 ↔ 방패 상호 제약 로직 구현

### 상세 스펙

```
class_name EquipmentManager
extends Node

signal equipment_changed(slot: SlotType, item_data: Dictionary)
signal equipment_slot_locked(slot: SlotType, reason: String)

enum SlotType { HELMET, SHIELD, ARMOR, WEAPON, BOOTS, RING_1, RING_2, NECKLACE }

var equipped_items: Dictionary = {
    SlotType.HELMET: null,
    SlotType.SHIELD: null,
    SlotType.ARMOR: null,
    SlotType.WEAPON: null,
    SlotType.BOOTS: null,
    SlotType.RING_1: null,
    SlotType.RING_2: null,
    SlotType.NECKLACE: null
}

func equip_item(slot: SlotType, item_data: ItemData) -> bool
func unequip_item(slot: SlotType) -> bool
func get_equipped_item(slot: SlotType) -> ItemData
func get_all_stat_bonus() -> Dictionary
func _validate_constraint(slot: SlotType, item_data: ItemData) -> bool
```

### 장착 로직 스펙

**양손 무기 장착 시:**
1. 현재 SHIELD 슬롯에 장비가 있으면 → 자동 해제
2. `equipment_changed.emit(SlotType.SHIELD, null)` 시그널 emit
3. WEAPON 슬롯에 item_data 장착
4. `equipment_changed.emit(SlotType.WEAPON, item_data)` 시그널 emit

**방패 장착 시:**
1. 현재 WEAPON 슬롯에 양손 무기(`is_two_handed == true`)가 있으면 → 장착 거부
2. `equipment_slot_locked` 시그널 emit (이유 포함)
3. false 반환

**일반 장착 시:**
1. 슬롯이 비어있거나 같은 타입 교체인 경우 → 장착 허용
2. `required_level` / `required_stats` 확인 (Phase 3에서 실제 적용)

### 완료 기준
- [ ] `equipment_manager.gd`가 생성됨
- [ ] 8슬롯 모두 null로 초기화 확인
- [ ] 일반 장비 장착 → `equipment_changed` 시그널 emit
- [ ] 양손 무기 장착 시 방패 자동 해제 확인
- [ ] 방패 장착 시 양손 무기 장착 거부 확인
- [ ] `get_all_stat_bonus()`가 장착된 모든 장비의 보너스 합산 반환

---

## 2.2.3 StatCalculation (`scripts/item/stat_calculator.gd`)

### 작업 내용
- 장착된 장비 기반 최종 스탯 계산
- 기본 스탯 + 장비 보너스 = 최종 스탯

### 상세 스펙

```
class_name StatCalculator
extends Node

func calculate_stats(base_stats: Dictionary, equipped_items: Dictionary) -> Dictionary:
    var final_stats = {
        "hp": base_stats.get("hp", 100),
        "max_hp": base_stats.get("max_hp", 100),
        "attack": base_stats.get("attack", 10),
        "defense": base_stats.get("defense", 5),
        "speed": base_stats.get("speed", 200.0)
    }
    
    for slot in equipped_items:
        var item = equipped_items[slot]
        if item != null and item.has_method("get_stat_bonus"):
            var bonus = item.get_stat_bonus()
            for stat_name in bonus:
                final_stats[stat_name] = final_stats.get(stat_name, 0) + bonus[stat_name]
    
    return final_stats
```

### 완료 기준
- [ ] `stat_calculator.gd`가 생성됨
- [ ] 기본 스탯 + 장비 보너스 합산 계산 확인
- [ ] 장비 교체 시 재계산 정상 작동
- [ ] null 아이템 처리 (보너스 0)

---

## Sub-Phase 2-2 완료 체크리스트

- [ ] `item_data.gd` 생성 + ItemData Resource 정의 완료
- [ ] `equipment_manager.gd` 생성 + 8슬롯 장착 시스템 구현 완료
- [ ] 양손 무기 ↔ 방패 제약 로직 정상 작동 확인
- [ ] `stat_calculator.gd` 생성 + 스탯 합산 계산 확인 완료
- [ ] 시그널(equipment_changed, equipment_slot_locked) emit 확인 완료
- [ ] 더미 아이템 데이터로 전체 장착/해제 테스트 완료
