# Sub-Phase 1-5: 스토리 컷신 전환 시스템

> Parent Phase: Phase 1 — Capability Check
> 목표: StoryDirector 구현, 쿼터뷰 자동 이동 + 다이얼로그 시퀀스, 전투 씬 전환

---

## 1.5.1 StoryDirector 뼈대 (`scripts/story/story_director.gd`)

### 작업 내용
- 스토리 연출 컨트롤러 클래스 생성
- JSON 스크립트 파싱 구조 준비 (더미 데이터로 테스트)
- 시퀀스 진행 상태 관리

### 상세 스펙

```
class_name StoryDirector
extends Node2D

signal sequence_finished
signal dialogue_started(text: String, speaker: String)
signal dialogue_ended
signal actor_moved(actor_name: String, target_pos: Vector2)

@export var actors: Dictionary = {}  # { "G.S": Node2D, "Iolin": Node2D }
@export_file("*.json") var script_file: String

var current_sequence: Array[Dictionary] = []
var sequence_index: int = 0
var is_running: bool = false

func _ready() -> void
func start_automatic_sequence() -> void
func parse_script(file_path: String) -> Array[Dictionary]
func execute_next_step() -> void
func _on_step_completed() -> void
```

### 완료 기준
- [ ] `story_director.gd`가 생성됨
- [ ] `_ready()`에서 script_file이 설정되면 자동 시작
- [ ] `sequence_finished` 시그널 emit 확인
- [ ] 더미 JSON 스크립트 파싱 정상 작동

---

## 1.5.2 쿼터뷰 액터 이동 (`scripts/story/actor_mover.gd`)

### 작업 내용
- 캐릭터가 지정된 웨이포인트를 따라 자동 이동
- Tween 기반 부드러운 이동 애니메이션

### 상세 스펙

```
class_name ActorMover
extends Node2D

@export var speed: float = 150.0
var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0

func set_waypoints(waypoints_array: Array[Vector2]) -> void
func start_movement() -> void
func _on_reached_waypoint() -> void
```

### 이동 스펙
- **웨이포인트 배열** 순서대로 이동
- **Tween** 사용: `tween_property(actor, "position", target_pos, duration)`
- **도착 시** 시그널 emit → 다음 웨이포인트 또는 다음 스텝으로 진행
- **쿼터뷰 각도**: 2D에서 3D 느낌의 위치 배치 (y축 깊이 표현)

### 완료 기준
- [ ] `actor_mover.gd`가 생성됨
- [ ] 웨이포인트 배열 설정 + 이동 시작 확인
- [ ] Tween으로 부드러운 이동 애니메이션
- [ ] 도착 시 다음 웨이포인트로 자동 진행
- [ ] 마지막 웨이포인트 도착 시 시퀀스 진행

---

## 1.5.3 다이얼로그 UI (`scenes/ui/dialogue_ui.gd`)

### 작업 내용
- 스토리 컷신 내 대화 표시 UI (더미)
- 화자 이름 + 대사 텍스트 표시

### 상세 스펙

```
class_name DialogueUI
extends CanvasLayer

@onready var speaker_label: Label = $SpeakerLabel
@onready var text_label: Label = $TextLabel
@onready var continue_button: Button = $ContinueButton

var is_displaying: bool = false

func show_dialogue(speaker: String, text: String) -> void
func hide_dialogue() -> void
func _on_continue_button_pressed() -> void
```

### UI 스펙 (더미)
- **배경**: ColorRect 검은색 반투명 (하단 30%)
- **화자 라벨**: 상단, 흰색 텍스트
- **대사 라벨**: 하단, 회색 텍스트
- **계속 버튼**: 클릭 시 다음 대사 또는 시퀀스 진행

### 완료 기준
- [ ] `dialogue_ui.gd`가 생성됨
- [ ] `show_dialogue()` 호출 시 화자 + 대사가 표시됨
- [ ] `hide_dialogue()` 호출 시 UI 숨겨짐
- [ ] 계속 버튼 클릭 시 다음 시퀀스 스텝 진행
- [ ] StoryDirector의 `dialogue_started`/`dialogue_ended` 시그널 연결

---

## 1.5.4 더미 스토리 JSON 스크립트 (`data/stages/story_demo.json`)

### 작업 내용
- 테스트용 스토리 시퀀스 JSON 파일 생성
- 이동 + 대화 + 전투 전환 포함

### JSON 구조 예시

```json
[
    {
        "type": "move",
        "actor": "G.S",
        "waypoints": [[200, 300], [400, 250]]
    },
    {
        "type": "dialogue",
        "speaker": "G.S",
        "text": "이곳이 창세기전의 시작점이다."
    },
    {
        "type": "move",
        "actor": "Iolin",
        "waypoints": [[600, 350], [500, 280]]
    },
    {
        "type": "dialogue",
        "speaker": "Iolin",
        "text": "준비되었는가?"
    },
    {
        "type": "transition",
        "target_scene": "scenes/game/combat_demo.tscn",
        "message": "전투 시작!"
    }
]
```

### 완료 기준
- [ ] `data/stages/story_demo.json` 생성됨
- [ ] JSON 파싱 시 배열/객체 구조 정상 확인
- [ ] move/dialogue/transition 타입 모두 파싱 가능
- [ ] StoryDirector가 이 파일을 로드하여 시퀀스 실행

---

## 1.5.5 스토리 → 전투 씬 전환 (`scripts/story/scene_transition.gd`)

### 작업 내용
- 스토리 시퀀스 종료 후 전투 씬으로 전환
- GameManager 상태 변경 연동

### 상세 스펙

```
class_name SceneTransition
extends Node

func transition_to_combat() -> void
    GameManager.change_state(GameManager.GameState.COMBAT)
    get_tree().change_scene_to_file("scenes/game/combat_demo.tscn")

func transition_to_upgrade() -> void
    GameManager.change_state(GameManager.GameState.UPGRADE)
    get_tree().change_scene_to_file("scenes/ui/upgrade_screen.tscn")

func transition_to_main_menu() -> void
    GameManager.change_state(GameManager.GameState.MAIN_MENU)
    get_tree().change_scene_to_file("scenes/ui/main_menu.tscn")
```

### 완료 기준
- [ ] `scene_transition.gd`가 생성됨
- [ ] `transition_to_combat()` 호출 시 COMBAT 상태로 전환 + 씬 변경
- [ ] `transition_to_upgrade()` 호출 시 UPGRADE 상태로 전환 + 씬 변경
- [ ] GameManager.state_changed 시그널과 연결 확인

---

## Sub-Phase 1-5 완료 체크리스트

- [ ] `story_director.gd` 생성 + 시퀀스 실행 테스트 완료
- [ ] `actor_mover.gd` 생성 + Tween 이동 테스트 완료
- [ ] `dialogue_ui.gd` 생성 + 대화 표시/계속 버튼 테스트 완료
- [ ] 더미 story_demo.json 생성 + 파싱 확인 완료
- [ ] `scene_transition.gd` 생성 + 스토리→전투 전환 테스트 완료
- [ ] 전체 시퀀스: 이동 → 대화 → 이동 → 대화 → 전투 전환 루프 확인
- [ ] GameManager 상태가 MAIN_MENU → STORY_SCENE → COMBAT으로 정상 전환
