# Sub-Phase 2-5: UI 뼈대

> Parent Phase: Phase 2 — Core Skeleton
> 목표: 인벤토리, 스킬트리, 보상 화면 UI 뼈대 구현 (더미)

---

## 2.5.1 인벤토리 UI (`scenes/ui/inventory_ui.tscn`)

### 작업 내용
- 장비 슬롯 표시 UI — 8슬롯 그리드 레이아웃
- 아이템 드래그/장착 더미 로직

### 씬 구성

```
InventoryUI (CanvasLayer):
├── Background (ColorRect - 반투명 검은색)
├── TitleLabel (Label - "Equipment")
├── SlotGrid (GridContainer - 2x4 또는 4x2)
│   ├── Slot_HELMET (Button + Label)
│   ├── Slot_SHIELD (Button + Label)
│   ├── Slot_ARMOR (Button + Label)
│   ├── Slot_WEAPON (Button + Label)
│   ├── Slot_BOOTS (Button + Label)
│   ├── Slot_RING_1 (Button + Label)
│   ├── Slot_RING_2 (Button + Label)
│   └── Slot_NECKLACE (Button + Label)
├── StatPanel ( VBoxContainer )
│   ├── Label_HP
│   ├── Label_ATK
│   ├── Label_DEF
│   └── Label_SPD
└── CloseButton ( Button - "Close" )
```

### 동작 스펙
- **슬롯 표시**: `EquipmentManager.get_equipped_item(slot)` 조회 → 이름/아이콘 표시
- **장착**: 슬롯 버튼 클릭 → 장착 가능한 아이템 목록 표시 → 선택 시 `EquipmentManager.equip_item()` 호출
- **해제**: 장착된 슬롯에서 해제 버튼 → `EquipmentManager.unequip_item()` 호출
- **스탯 패널**: `StatCalculator.get_all_stat_bonus()` 기반 최종 스탯 표시

### 완료 기준
- [ ] `inventory_ui.tscn`이 Godot에서 열림
- [ ] 8슬롯 그리드 레이아웃 확인
- [ ] EquipmentManager 연동 → 장착/해제 시 UI 갱신 확인
- [ ] StatPanel에 최종 스탯 표시 확인
- [ ] Close 버튼으로 UI 숨김 확인

---

## 2.5.2 스킬 트리 UI (`scenes/ui/skill_tree_ui.tscn`)

### 작업 내용
- 스킬 노드 표시 UI — 선행 조건 체크, 스킬 포인트 할당
- 더미: ColorRect 기반 노드 + Label

### 씬 구성

```
SkillTreeUI (CanvasLayer):
├── Background (ColorRect - 반투명 검은색)
├── TitleLabel (Label - "Skill Tree")
├── SkillPointLabel (Label - "SP: 5")
├── SkillTreeView (ScrollContainer)
│   └── SkillNodeGrid (Container)
│       ├── SkillNode_01 (Button + Label)
│       ├── SkillNode_02 (Button + Label)
│       └── ...
├── SkillInfoPanel ( VBoxContainer )
│   ├── Label_Name
│   ├── Label_Description
│   ├── Label_Type
│   └── Label_Cost
└── CloseButton ( Button - "Close" )
```

### 노드 상태 스펙

| 상태 | 색상 (더미) | 동작 |
|------|------------|------|
| **해금 가능** | 초록색 | 클릭 시 스킬 포인트 할당 |
| **선행 조건锁定** | 회색 | 클릭 시 정보 표시, 할당 불가 |
| **해금됨** | 파란색 | 클릭 시 상세 정보 표시 |
| **이미 투자됨** | 노란색 | 클릭 시 정보 + 포인트 반환 가능 |

### 동작 스펙
1. `SkillTreeManager.get_available_skills()` 조회 → 해금 가능 노드 표시
2. `SkillTreeManager.get_locked_skills()` 조회 → 선행 조건锁定 노드 표시
3. 노드 클릭 → `SkillTreeManager.allocate_point()` 호출
4. `skill_point_changed` 시그널 수신 → SkillPointLabel 갱신
5. `skill_unlocked` 시그널 수신 → 하위 노드 색상 변경

### 완료 기준
- [ ] `skill_tree_ui.tscn`이 Godot에서 열림
- [ ] 스킬 노드가 Tree 구조로 표시됨 (position 기반 배치)
- [ ] 해금 가능/锁定/해금됨 상태가 색상으로 구분됨
- [ ] 노드 클릭 시 스킬 포인트 할당 확인
- [ ] SkillTreeManager 시그널 수신 → UI 자동 갱신 확인
- [ ] Close 버튼으로 UI 숨김 확인

---

## 2.5.3 보상/업그레이드 화면 (`scenes/ui/upgrade_screen.tscn`)

### 작업 내용
- 전투 후 보상 선택 UI — 장비/스킬 선택 더미
- StageData의 rewards 기반 아이템 표시

### 씬 구성

```
UpgradeScreen (CanvasLayer):
├── Background (ColorRect - 반투명 검은색)
├── TitleLabel (Label - "Stage Cleared!")
├── RewardInfo ( VBoxContainer )
│   ├── Label_Gold ("Gold: +100")
│   ├── Label_Exp ("EXP: +50")
│   └── Label_Items (동적)
├── ChoicePanel ( VBoxContainer )
│   ├── Label_ChooseReward ("Choose a reward:")
│   ├── RewardButton_1 (Button - 더미 아이템 1)
│   ├── RewardButton_2 (Button - 더미 아이템 2)
│   └── RewardButton_3 (Button - 더미 아이템 3)
├── ContinueButton ( Button - "Continue" )
└── SkipButton ( Button - "Skip Reward" )
```

### 동작 스펙
1. `stage_cleared` 시그널 수신 → 보상 정보 계산
2. Gold/EXP/Items 표시
3. 3개 더미 보상 버튼 표시 (랜덤 선택)
4. 버튼 클릭 → 보상 적용 (EquipmentManager 또는 SkillTreeManager)
5. Continue → 메인 메뉴로 전환
6. Skip → 보상 없이 메인 메뉴로 전환

### 완료 기준
- [ ] `upgrade_screen.tscn`이 Godot에서 열림
- [ ] 스테이지 클리어 보상 정보 표시 확인
- [ ] 3개 보상 버튼 표시 + 선택 시 적용 확인
- [ ] Continue → 메인 메뉴 전환 확인
- [ ] Skip → 보상 없이 전환 확인

---

## Sub-Phase 2-5 완료 체크리스트

- [ ] `inventory_ui.tscn` 생성 + 인벤토리 UI 뼈대 완료
- [ ] `skill_tree_ui.tscn` 생성 + 스킬 트리 UI 뼈대 완료
- [ ] `upgrade_screen.tscn` 생성 + 보상 화면 UI 뼈대 완료
- [ ] EquipmentManager 연동 → 장착/해제 → UI 갱신 확인
- [ ] SkillTreeManager 연동 → 스킬 할당 → UI 갱신 확인
- [ ] StageData 연동 → 보상 계산 → 화면 표시 확인
- [ ] 모든 UI가 더미 상태로 상호작용 가능 확인
