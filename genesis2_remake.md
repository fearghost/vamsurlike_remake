ore Loop)**: 스테이지 선택 ➔ 스토리 컷신(자동 쿼터뷰 이동) ➔ 웨이브 전투 (뱀서라이크 생존) ➔ 보상 및 장비/스킬 관리

---

## 2. 개발 로드맵 및 마일스톤
1. **Phase 1 (Capability Check)**: 에셋 연결이 없는 상태(ColorRect, 기본 도형 활용)의 Playable Demo 구축 및 GitHub Actions를 통한 Android APK 자동 빌드 검증.
2. **Phase 2 (Core Skeleton)**: 캐릭터, 몬스터, NPC, 스테이지, 스토리, 스킬, 장비 시스템을 쉽게 확장할 수 있는 데이터 중심(Resource/JSON) 모듈형 뼈대 완성.
3. **Phase 3 (Content & Asset Integration)**: 창세기전 2 컨셉의 SD 스프라이트, UI, BGM 연결 및 데이터 확장.

---

## 3. 저장소 구조 (Repository Structure)

```text
vamsurlike_remake/
├── .github/
│   └── workflows/
│       └── android_build.yml      # GitHub Actions APK 빌드 파이프라인
├── assets/                        # 에셋 (Placeholder 및 실제 그래픽/사운드)
│   ├── sprites/                   # 플레이어, 몬스터, NPC, 장비 SD 스프라이트
│   ├── ui/                        # UI 테마 및 아이콘
│   └── audio/                     # BGM 및 SFX
├── data/                          # 게임 데이터 리소스 (.tres 또는 .json)
│   ├── characters/                # 플레이어블 캐릭터 데이터
│   ├── enemies/                   # 몬스터 데이터
│   ├── items/                     # 부위별 장비 아이템 데이터
│   ├── skills/                    # 스킬 및 스킬 트리 데이터
│   └── stages/                    # 스테이지 및 스토리 스크립트 데이터
├── scenes/
│   ├── common/                    # 공용 컴포넌트 (Hitbox, Hurtbox, VirtualJoystick)
│   ├── ui/                        # 메인 메뉴, HUD, 인벤토리, 스킬트리 UI
│   ├── game/                      # 전투 씬 (플레이어, 적, 투사체, 파티클)
│   └── story/                     # 쿼터뷰 스토리 연출 씬
├── scripts/
│   ├── autoload/                  # GameManager, SaveManager, SoundManager, PoolManager
│   ├── player/                    # 플레이어 컨트롤러, 스테이터스
│   ├── enemy/                     # 적 AI, 스포너
│   ├── item/                      # 아이템 및 장비 슬롯 로직
│   ├── skill/                     # 스킬 발동 및 스킬 트리 로직
│   └── story/                     # 스토리 컷신 연출 컨트롤러
├── export_presets.cfg             # Godot Android Export 설정
└── project.godot                  # 프로젝트 설정
```

---

## 4. 핵심 시스템 아키텍처 및 뼈대 설계 (Skeleton Code Architecture)

### 4.1. 전역 게임 매니저 (`scripts/autoload/game_manager.gd`)
게임의 전체 상태(스테이지 진행도, 일시정지, 게임 루프 페이즈)를 관리합니다.

```gdscript
extends Node

signal state_changed(new_state: GameState)

enum GameState { MAIN_MENU, STORY_SCENE, COMBAT, UPGRADE, PAUSE }
var current_state: GameState = GameState.MAIN_MENU

var current_stage_id: int = 1
var player_base_stats: Dictionary = {
    "hp": 100,
    "max_hp": 100,
    "attack": 10,
    "defense": 5,
    "speed": 200.0
}

func change_state(new_state: GameState) -> void:
    current_state = new_state
    state_changed.emit(current_state)
```

### 4.2. 스테이지 및 쿼터뷰 스토리 씬 시스템 (`scripts/story/story_director.gd`)
전투 스테이지 전후로 쿼터뷰 공간에서 캐릭터들이 지정된 웨이포인트를 따라 자동으로 이동하며 대화를 나누는 구조입니다.

```gdscript
class_name StoryDirector
extends Node2D

signal sequence_finished

@export var actors: Dictionary = {} # { "G.S": Node2D, "Iolin": Node2D }
@export_file("*.json") var script_file: String

func _ready() -> void:
    if script_file != "":
        start_automatic_sequence()

func start_automatic_sequence() -> void:
    # JSON 스크립트를 파싱하여 캐릭터 이동(Tween/Navigation) 및 다이얼로그 UI 순차 실행
    print("스토리 시퀀스 시작: 쿼터뷰 자동 이동 및 대화 연출")
    # 연출 종료 시 sequence_finished.emit() 호출 후 전투 씬 전환
```

### 4.3. 부위별 장비 및 제약 시스템 (`scripts/item/equipment_manager.gd`)
* **장착 슬롯 (총 8개)**: 투구(HELMET), 방패(SHIELD), 갑옷(ARMOR), 무기(WEAPON), 신발(BOOTS), 반지 1(RING_1), 반지 2(RING_2), 목걸이(NECKLACE)
* **제약 조건**: 무기 타입이 양손 무기(`is_two_handed == true`)일 경우 방패를 장착할 수 없으며, 기존에 장착된 방패는 자동 해제됩니다.

```gdscript
extends Node

signal equipment_changed(slot: SlotType, item_data: Dictionary)

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

func equip_item(slot: SlotType, item_data: Dictionary) -> bool:
    # 양손 무기 착용 시 방패 강제 해제
    if slot == SlotType.WEAPON and item_data.get("is_two_handed", false):
        if equipped_items[SlotType.SHIELD] != null:
            equipped_items[SlotType.SHIELD] = null
            equipment_changed.emit(SlotType.SHIELD, {})
            print("양손 무기 장착으로 인해 방패가 해제되었습니다.")
    
    # 방패 착용 시 현재 무기가 양손 무기면 장착 거부
    if slot == SlotType.SHIELD:
        var current_weapon = equipped_items[SlotType.WEAPON]
        if current_weapon != null and current_weapon.get("is_two_handed", false):
            print("양손 무기를 장착 중이므로 방패를 장착할 수 없습니다.")
            return false

    equipped_items[slot] = item_data
    equipment_changed.emit(slot, item_data)
    return true
```

### 4.4. 모듈형 확장 뼈대 스펙 (Data-Driven Design)
추후 기능과 에셋을 쉽게 붙일 수 있도록 모든 엔티티는 데이터(`Resource` 또는 `JSON`)와 로직을 분리합니다.
* **플레이어블 캐릭터**: 고유 패시브, 기본 무기, 이동 속도, SD 스프라이트 시트를 담은 `CharacterData` 리소스 구조.
* **적 몬스터 & NPC**: AI 패턴(추적형, 원거리형, 돌진형), 스탯, 드랍 테이블을 정의한 `EnemyData` 및 대화/상호작용 이벤트를 가진 `NPCData` 구조.
* **스킬 및 스킬 트리**: 액티브/패시브 스킬 효과를 모듈화한 `SkillBase` 클래스와 선행 스킬 노드(`prerequisite_ids`), 해금 레벨을 관리하는 `SkillTreeManager` 구조.

---

## 5. 추가 고려 사항 (필수 반영 항목)

1. **모바일 터치 조작 (Virtual Joystick)**:
   * Android 환경 테스트 및 플레이를 위해 화면 터치 드래그로 작동하는 가상 조이스틱(`VirtualJoystick`)을 플레이어 이동 입력에 기본 연동합니다.
2. **오브젝트 풀링 (`PoolManager`)**:
   * 뱀서라이크 특성상 다수의 몬스터, 투사체, 경험치 보석이 동시 생성되므로 `instantiate()`/`queue_free()` 부하를 줄이기 위한 노드 풀링 시스템을 뼈대에 포함합니다.
3. **세이브/로드 시스템 (`SaveManager`)**:
   * 스테이지 클리어 현황, 보유 장비, 스킬 트리 투자 내역을 `user://save_data.json`으로 직렬화하여 저장/불러오기 처리합니다.
4. **해상도 및 화면 비율 대응**:
   * `project.godot`에서 Viewport 크기를 모바일 표준(예: `720x1280` 세로형 또는 `1280x720` 가로형 - *기본 가로형 권장*)으로 설정하고 `stretch/mode="canvas_items"`, `stretch/aspect="keep"`을 적용합니다.

---

## 6. GitHub Actions 자동 APK 빌드 파이프라인 (`.github/workflows/android_build.yml`)

```yaml
name: Build Android APK

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    name: Build Godot APK
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.3-stable

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Create Export Directory
        run: mkdir -p build/android

      - name: Setup Debug Keystore
        run: |
          mkdir -p ~/.android
          keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore ~/.android/debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 10000

      - name: Export APK
        run: |
          godot --headless --export-debug "Android" build/android/vamsurlike_remake.apk

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: vamsurlike-remake-apk
          path: build/android/vamsurlike_remake.apk
```

---

## 7. 코딩 에이전트(Vibe Coding) 작업 지시 가이드

이 문서를 컨텍스트로 제공한 뒤, 코딩 에이전트에게 아래 단계별로 작업을 지시하세요.

* **Step 1 (프로젝트 초기화 및 CI 구축)**:
  > "첨부된 `GDD_vamsurlike_remake.md` 설계서를 바탕으로 Godot 4.3 프로젝트의 기본 폴더 구조, `project.godot`, `export_presets.cfg`(Android), 그리고 `.github/workflows/android_build.yml` 파일을 생성해줘."
* **Step 2 (Playable Demo & 뼈대 구현)**:
  > "설계서의 4장 아키텍처를 기반으로 에셋 없이도 실행 가능한 Playable Demo를 만들어줘. 더미 그래픽(사각형/원)을 사용해 플레이어 이동(가상 조이스틱 포함), 기본 자동 공격, 적 스폰, 쿼터뷰 스토리 컷신 전환 뼈대를 구현해줘."
* **Step 3 (장비 및 스킬 시스템 확장)**:
  > "설계서의 4.3, 4.4 항목에 따라 8부위 장비 장착 시스템(양손 무기-방패 제약 포함)과 스킬 트리 뼈대 코드 및 테스트용 더미 UI를 추가해줘."
