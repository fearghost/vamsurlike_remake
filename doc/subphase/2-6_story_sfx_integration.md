# Sub-Phase 2-6: StoryDirector 완성 + SoundManager 완성 + 통합 테스트

> Parent Phase: Phase 2 — Core Skeleton
> 목표: StoryDirector JSON 파싱 완성, SoundManager 실제 재생 연동, 전체 시스템 통합 검증

---

## 2.6.1 StoryDirector JSON 파싱 완성 (`scripts/story/story_director.gd`)

### 작업 내용
- 더미 데이터에서 실제 JSON 파일 파싱으로 전환
- move/dialogue/transition 모든 타입 처리 완성
- 시퀀스 상태 머신 구현

### 상세 스펙

```
class_name StoryDirector
extends Node2D

signal sequence_finished
signal dialogue_started(speaker: String, text: String)
signal dialogue_ended
signal actor_moved(actor_name: String, target_pos: Vector2)

@export var actors: Dictionary = {}  # { "G.S": Node2D, "Iolin": Node2D }
@export_file("*.json") var script_file: String

var sequence_steps: Array[Dictionary] = []
var current_step_index: int = 0
var is_running: bool = false
var tween: Tween

func _ready() -> void
func start_automatic_sequence() -> void
func _load_and_parse_script() -> Array[Dictionary]
func _execute_step(step: Dictionary) -> void
func _on_move_completed(actor_name: String) -> void
func _on_dialogue_completed() -> void
func _on_transition_completed(target_scene: String) -> void
func _next_step() -> void
func _all_steps_done() -> void
```

### 시퀀스 상태 머신

```
[START] → _load_and_parse_script()
    ↓
sequence_steps = parsed JSON array
current_step_index = 0
is_running = true
    ↓
_execute_step(sequence_steps[0])
    ↓
step.type == "move":
    ActorMover.set_waypoints(step.waypoints)
    ActorMover.start_movement()
    → on_reached_last_waypoint: _on_move_completed()
step.type == "dialogue":
    DialogueUI.show_dialogue(step.speaker, step.text)
    → on_continue_pressed: _on_dialogue_completed()
step.type == "transition":
    SceneTransition.transition_to_scene(step.target_scene)
    → on_transition_done: _on_transition_completed()
    ↓
_next_step(): current_step_index += 1
    ↓
current_step_index < sequence_steps.size():
    → _execute_step(next step)
else:
    → _all_steps_done(): is_running = false, sequence_finished.emit()
```

### 완료 기준
- [ ] JSON 파일 파싱이 에러 없이 동작
- [ ] move/dialogue/transition 모든 타입 처리 확인
- [ ] 시퀀스가 순차적으로 진행됨
- [ ] 마지막 스텝 후 `sequence_finished` 시그널 emit 확인
- [ ] 중간 에러 시 graceful handling (로그 출력 + 다음 스텝으로 진행)

---

## 2.6.2 SoundManager 실제 재생 연동 (`scripts/autoload/sound_manager.gd`)

### 작업 내용
- 더미(로그 출력)에서 실제 AudioStreamPlayer 연동으로 전환
- BGM/SFX 재생, 볼륨, mute 기능 완성

### 상세 스펙

```
class_name SoundManager
extends Node

var bgm_player: AudioStreamPlayer
var sfx_player_1: AudioStreamPlayer
var sfx_player_2: AudioStreamPlayer

var bgm_volume_db: float = 0.0
var sfx_volume_db: float = 0.0
var is_muted: bool = false

func _ready() -> void
func init_players() -> void
func play_bgm(stream: AudioStream, fade_in: float = 1.0) -> void
func stop_bgm(fade_out: float = 0.5) -> void
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void
func set_bgm_volume(db: float) -> void
func set_sfx_volume(db: float) -> void
func mute_all(mute: bool) -> void
func toggle_mute() -> void
```

### 동작 스펙
- **`_ready()`**: AudioStreamPlayer 노드 동적 생성 + 자식으로 추가
- **`play_bgm(stream)`**: bgm_player에 stream 설정 → play() → fade_in 시간 동안 볼륨 증가
- **`stop_bgm(fade_out)`**: fade_out 시간 동안 볼륨 감소 → stop()
- **`play_sfx(stream, volume_db)`**: 사용 가능한 sfx_player中寻找 free 상태 → stream 설정 → play()
- **`mute_all(mute)`**: 모든 플레이어.volume_db = -80 (mute) 또는 원래 값으로 복원

### 완료 기준
- [ ] AudioStreamPlayer 노드가 동적으로 생성됨
- [ ] BGM 재생/정지 확인 (에셋 없으면 에러 없이 로그만 출력)
- [ ] SFX 재생 확인 (여개 동시 재생 가능)
- [ ] 볼륨 조절 확인
- [ ] mute/unmute 확인

---

## 2.6.3 전체 시스템 통합 테스트

### 작업 내용
- Phase 2의 모든 시스템이 서로 연동되어 동작하는지 검증

### 테스트 시나리오

| No | 테스트 | 기대 결과 |
|----|--------|----------|
| T1 | DataLoader.load_all() → CharacterData 조회 | 캐시에서 정상 로드, 필드값 확인 가능 |
| T2 | DataLoader.load_all() → EnemyData 조회 | 3종 더미 데이터 로드 확인 |
| T3 | EquipmentManager.equip_item(WEAPON, two_handed_item) | 방패 자동 해제 + 시그널 emit |
| T4 | EquipmentManager.equip_item(SHIELD, when_two_handed_equipped) | 장착 거부 + 시그널 emit |
| T5 | StatCalculator.calculate_stats() | 기본 + 장비 보너스 합산 확인 |
| T6 | SkillTreeManager.load_all_skills() → unlock_skill() | 선행 조건 체크 + 해금 확인 |
| T7 | SkillExecutor.cast_skill() | MP 소모 + 쿨다운 + 효과 적용 |
| T8 | StageData 로드 → WaveManager.start_next_wave() | 몬스터 스폰 확인 |
| T9 | StoryDirector JSON 파싱 → 시퀀스 실행 | move/dialogue/transition 순차 진행 |
| T10 | SoundManager.play_bgm() + play_sfx() | 에셋 미연결 상태에서도 에러 없음 |

### 완료 기준
- [ ] T1~T10 모든 테스트 통과
- [ ] 시스템 간 연동 에러 없음 (시그널 누락, null 참조 등)
- [ ] 메모리 누수 없음 (Godot Debugger 확인)
- [ ] 더미 데이터로 전체 게임 루프(메뉴 → 스토리 → 전투 → 보상 → 메뉴) 플레이 가능

---

## Phase 2 전체 완료 체크리스트

### Sub-Phase별
- [x] 2-1: 데이터 리소스 클래스 (CharacterData, EnemyData, NPCData, DataLoader) 구현 완료
- [x] 2-2: 장비 시스템 (ItemData, EquipmentManager, StatCalculator) 구현 완료
- [x] 2-3: 스킬 시스템 (SkillData, SkillTreeManager, SkillExecutor) 구현 완료
- [x] 2-4: 스테이지/웨이브 관리 (StageData, WaveManager, CombatArena) 구현 완료
- [x] 2-5: UI 뼈대 (인벤토리, 스킬트리, 보상 화면) 구현 완료
- [x] 2-6: StoryDirector JSON 완성 + SoundManager 연동 + 통합 테스트 완료

### 공통
- [ ] 모든 엔티티가 Resource/JSON 기반 데이터 중심 설계
- [ ] 새로운 캐릭터/적/스킬/장비를 데이터만 추가하면 시스템에 자동 반영
- [ ] 장비 장착 시 양손 ↔ 방패 제약 정상 작동
- [ ] 스킬 트리가 선행 조건에 따라 해금/锁定
- [ ] 스토리 JSON 스크립트로 컷신 연출 작성 가능
- [ ] 전체 게임 루프가 데이터 중심 뼈대로 플레이 가능
