# Sub-Phase 1-2: Autoload 매니저 구현

> Parent Phase: Phase 1 — Capability Check
> 목표: GameManager, SaveManager, PoolManager, SoundManager autoload 노드 구현

---

## 1.2.1 GameManager (`scripts/autoload/game_manager.gd`)

### 작업 내용
- 전역 게임 상태 관리 autoload 노드 생성
- GameState enum 및 상태 전환 로직 구현
- 시그널 기반 이벤트 시스템 연결

### 상세 스펙

```
enum GameState { MAIN_MENU, STORY_SCENE, COMBAT, UPGRADE, PAUSE }
var current_state: GameState = GameState.MAIN_MENU
var current_stage_id: int = 1

player_base_stats: Dictionary
    hp: 100
    max_hp: 100
    attack: 10
    defense: 5
    speed: 200.0

signal state_changed(new_state: GameState)
func change_state(new_state: GameState) -> void
```

### 완료 기준
- [ ] `game_manager.gd`가 autoload에 등록됨 (Project → Project Settings → Autoload)
- [ ] `change_state()` 호출 시 `state_changed` 시그널이 emit됨
- [ ] `current_state`가 정상적으로 갱신됨
- [ ] 다른 스크립트에서 `GameManager.current_state` 접근 가능

---

## 1.2.2 SaveManager (`scripts/autoload/save_manager.gd`)

### 작업 내용
- 세이브/로드 시스템 autoload 노드 생성
- JSON 직렬화를 통한 데이터 저장/불러오기
- `user://save_data.json` 경로 사용

### 상세 스펙

```
const SAVE_PATH = "user://save_data.json"

var save_data: Dictionary = {
    "current_stage": 1,
    "cleared_stages": [],
    "player_stats": {},
    "equipment": {},
    "skill_tree": {}
}

func save() -> void
func load() -> void
func clear_save() -> void
```

### 완료 기준
- [ ] `save_manager.gd`가 autoload에 등록됨
- [ ] `save()` 호출 시 `user://save_data.json` 파일이 생성됨
- [ ] `load()` 호출 시 저장된 데이터가 `save_data`에 복원됨
- [ ] JSON 형식이 유효함 (파싱 에러 없음)
- [ ] `clear_save()` 호출 시 파일이 삭제되거나 초기화됨

---

## 1.2.3 PoolManager (`scripts/autoload/pool_manager.gd`)

### 작업 내용
- 오브젝트 풀링 autoload 노드 생성
- 뱀서라이크 특성상 다수 몬스터/투사체 생성 시 인스턴스화 부하 감소
- `instantiate()` / `queue_free()` 호출 최소화

### 상세 스펙

```
class_name ObjectPool
extends Node

var pool: Array[Node2D] = []
var template: PackedScene
var active_objects: Array[Node2D] = []
var is_active: bool = false

func init(template_scene: PackedScene, initial_size: int) -> void
func get_object() -> Node2D
func release_object(obj: Node2D) -> void
func clear_pool() -> void
```

```
PoolManager (autoload):
    var pools: Dictionary = {}  # key: scene_name, value: ObjectPool
    
    func register_pool(name: String, template: PackedScene, size: int) -> void
    func acquire(name: String) -> Node2D
    func release(name: String, obj: Node2D) -> void
```

### 완료 기준
- [ ] `pool_manager.gd`가 autoload에 등록됨
- [ ] `register_pool()` 호출로 풀이 생성됨
- [ ] `acquire()`로 오브젝트를 가져올 때 풀에서 재사용됨 (새 instantiate 아님)
- [ ] `release()`로 오브젝트가 풀로 반환됨 (inactive 상태로)
- [ ] 풀이 고갈 시 fallback으로 새 instantiate 발생

---

## 1.2.4 SoundManager (`scripts/autoload/sound_manager.gd`)

### 작업 내용
- BGM/SFX 관리 autoload 노드 생성
- 더미 상태: 플레이 시 로그 출력만 (Phase 3에서 실제 에셋 연결)

### 상세 스펙

```
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer2D  # 또는 AudioStreamPlayer

func play_bgm(stream: AudioStream, loop: bool = true) -> void
func stop_bgm(fade_out: float = 0.0) -> void
func play_sfx(stream: AudioStream) -> void
func set_bgm_volume(db: float) -> void
func set_sfx_volume(db: float) -> void
func mute_all(mute: bool) -> void
```

### 완료 기준
- [ ] `sound_manager.gd`가 autoload에 등록됨
- [ ] `play_bgm()` 호출 시 에러 없이 실행됨 (에셋 없으면 로그 출력)
- [ ] `play_sfx()` 호출 시 에러 없이 실행됨
- [ ] 볼륨 조절, mute 기능이 정상 작동

---

## Sub-Phase 1-2 완료 체크리스트

- [ ] `game_manager.gd` autoload 등록 + 상태 전환 테스트 완료
- [ ] `save_manager.gd` autoload 등록 + 저장/로드/삭제 테스트 완료
- [ ] `pool_manager.gd` autoload 등록 + 풀 생성/획득/반환 테스트 완료
- [ ] `sound_manager.gd` autoload 등록 + BGM/SFX 플레이 테스트 완료
- [ ] 4개 autoload 노드가 모두 Project Settings → Autoload에 등록됨
- [ ] 다른 스크립트에서 전역 접근 (`GameManager`, `SaveManager`, `PoolManager`, `SoundManager`) 확인
