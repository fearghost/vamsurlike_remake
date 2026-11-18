# Sub-Phase 1-7: 게임 루프 완성 및 버그 수정

> Parent Phase: Phase 1 — Capability Check
> 목표: UPGRADE 화면 구현 + 핵심 버그 수정으로 전체 게임 루프 완성

---

## 1.7.1 업그레이드 화면 (`scenes/game/upgrade_screen.tscn`)

### 작업 내용
- 웨이브 클리어 후 표시되는 보상 선택 화면 생성
- 더미 그래픽 기반 (ColorRect)

### 씬 구성

```
UpgradeScreen (CanvasLayer):
├── Background (ColorRect - 반투명 검은색)
├── TitleLabel (Label - "Stage Cleared!")
├── HealButton (Button - "Restore HP")
│   └── pressed → HP 최대치 복구 → 메인 메뉴 복귀
├── AttackButton (Button - "Attack +5")
│   └── pressed → 공격력 +5 → 메인 메뉴 복귀
└── BackButton (Button - "Return to Menu")
    └── pressed → 메인 메뉴 복귀
```

### 상세 스펙

| 기능 | 설명 |
|------|------|
| HP 복구 | `GameManager.player_base_stats["hp"]`를 `max_hp`로 설정 |
| 공격력 증가 | `GameManager.player_base_stats["attack"]`에 +5 적용 |
| 세이브 | 선택한 보상을 `SaveManager.save_data["player_stats"]`에 저장 |
| 전환 | `SceneTransition.transition_to_main_menu()` 호출 |

### 완료 기준
- [ ] `upgrade_screen.tscn`이 Godot에서 열림
- [ ] HP 복구 버튼 클릭 시 플레이어 HP가 최대치로恢复
- [ ] 공격력 증가 버튼 클릭 시 공격 스탯이 +5 증가
- [ ] 모든 선택 후 메인 메뉴로 정상 전환

---

## 1.7.2 전투 → 업그레이드 → 메인 메뉴 루프 통합

### 작업 내용
- `combat_demo.gd`의 `_on_all_waves_cleared()` 수정: 바로 메인 메뉴 대신 UPGRADE 화면으로 전환
- 전체 루프: MAIN_MENU → STORY_SCENE → COMBAT → UPGRADE → MAIN_MENU

### 수정 사항

**기존 (`combat_demo.gd`):**
```gdscript
func _on_all_waves_cleared() -> void:
    # ... save progress ...
    await get_tree().create_timer(2.0).timeout
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

**수정 후:**
```gdscript
func _on_all_waves_cleared() -> void:
    # ... save progress ...
    get_tree().change_scene_to_file("res://scenes/game/upgrade_screen.tscn")
```

### 완료 기준
- [ ] 웨이브 클리어 시 upgrade_screen.tscn으로 전환
- [ ] 보상 선택 후 메인 메뉴로 복귀
- [ ] 메인 메뉴에서 Start 클릭 시 스토리 → 전투 → 보상 → 메뉴 전체 루프 정상 동작

---

## 1.7.3 VirtualJoystick 모바일 입력 버그 수정

### 문제
`_input()` 메서드 사용 시 Godot 4의 입력 시스템과 충돌하여 모바일 터치 이벤트가 누락될 수 있음.

### 수정
`_input()` → `_unhandled_input()` 변경

**파일:** `scenes/common/virtual_joystick.gd`

```gdscript
# Before
func _input(event: InputEvent) -> void:

# After
func _unhandled_input(event: InputEvent) -> void:
```

### 완료 기준
- [ ] 모바일에서 조이스틱 터치/드래그가 정상 반응
- [ ] 다른 노드의 입력 처리와 충돌 없음

---

## 1.7.4 적 원거리 공격 타이밍 버그 수정

### 문제
`EnemyAI.last_shot_time` 초기값이 `0.0`으로, 게임 시작 시 첫 사격이 즉시 발사됨 (의도된 간격 없이).

### 수정
```gdscript
# Before
var last_shot_time: float = 0.0

# After
var last_shot_time: float = -999.0
```

초기값을 충분히 작은 음수로 설정하여 첫 사격이 `shot_interval` 후 정상적으로 발생하도록 함.

### 완료 기준
- [ ] ranged 적의 첫 사격이 spawn 후 2초 경과 후 발생
- [ ] 이후 사격 간격이 shot_interval(2.0초)로 정상 유지

---

## 1.7.5 플레이어 컨트롤러 더미 스프라이트 중복 생성 수정

### 문제
`player_controller.gd`의 `_ready()`에서 `find_child("DummySprite")`를 확인하지만,
`combat_demo.tscn`의 Player 노드에는 `Body`라는 이름의 ColorRect가 이미 존재함.

이로 인해 코드에서 새로운 `DummySprite` ColorRect가 중복 생성됨 (보이지 않지만 불필요한 노드 추가).

### 수정
```gdscript
# Before
if find_child("DummySprite") == null:
    var dummy := ColorRect.new()
    dummy.name = "DummySprite"
    ...

# After
if find_child("Body") == null:
    var dummy := ColorRect.new()
    dummy.name = "Body"
    dummy.size = Vector2(32, 32)  # size 명시적 설정 추가
    ...
```

### 완료 기준
- [ ] 플레이어에 중복 스프라이트 노드 없음
- [ ] `combat_demo.tscn`의 Body ColorRect가 정상 표시됨

---

## Phase 1 전체 게임 루프 테스트 시나리오

| 단계 | 동작 | 기대 결과 |
|------|------|----------|
| 1 | 메인 메뉴 Start 클릭 | TITLE 표시, STORY_SCENE 전환 |
| 2 | 스토리 시퀀스 진행 | G.S 이동 → 대사 → Iolin 이동 → 대사 순차 실행 |
| 3 | combat_demo.tscn 전환 | COMBAT 상태로 전환, 전투 씬 로드 |
| 4 | VirtualJoystick로 이동 | 플레이어 이동 정상 반응 |
| 5 | AutoAttack 자동 발사 | 적을 향해 투사체 발사 |
| 6 | 웨이브 1-3 클리어 | All waves cleared 시그널 발생 |
| 7 | upgrade_screen.tscn 전환 | 보상 선택 화면 표시 |
| 8 | HP 복구 또는 공격력 증가 선택 | 스탯 적용, 세이브 저장 |
| 9 | 메인 메뉴로 복귀 | MAIN_MENU 상태로 전환 |
| 10 | Start 재클릭 | 전체 루프 반복 가능 |

### 완료 기준
- [ ] 전체 루프가 에러 없이 한 번 돌고 끝남
- [ ] 상태 전환 시 에러 로그 없음
- [ ] 모바일 터치 조작(조이스틱)이 정상 반응
- [ ] 세이브/로드가 루프 내 여러 지점에서 정상 작동
