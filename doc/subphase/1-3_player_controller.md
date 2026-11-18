# Sub-Phase 1-3: 플레이어 컨트롤러 및 가상 조이스틱

> Parent Phase: Phase 1 — Capability Check
> 목표: VirtualJoystick 연동 이동, 기본 자동 공격 시스템 구현 (더미 그래픽)

---

## 1.3.1 VirtualJoystick 컴포넌트 (`scenes/common/virtual_joystick.gd`)

### 작업 내용
- 화면 터치 드래그로 작동하는 가상 조이스틱 노드 생성
- 플레이어 이동 입력에 연동

### 상세 스펙

```
class_name VirtualJoystick
extends Control

signal value_changed(direction: Vector2)

var base_position: Vector2
var stick_position: Vector2
var max_radius: float = 50.0
var is_active: bool = false
var touch_id: int = -1

func _input(event: InputEvent) -> void
func _process(delta: float) -> void
func get_direction() -> Vector2
```

### 동작 스펙
- **터치 시작**: 화면 하단 영역 터치 시 조이스틱 베이스 표시
- **드래그**: 터치 위치와 베이스 위치의 차이로 방향 벡터 계산
- **반경 제한**: 최대 반경(`max_radius`) 내에서 스틱 이동
- **터치 종료**: 스틱 원위치, 방향 0

### 완료 기준
- [ ] `virtual_joystick.gd`가 `scenes/common/`에 생성됨
- [ ] 화면 터치 시 조이스틱 UI 표시 (ColorRect 기반 더미)
- [ ] 드래그 방향이 `direction: Vector2`로 정상 emit됨
- [ ] 터치 종료 시 스틱이 원위치함
- [ ] 멀티터치 지원 (한 손 조이스틱, 다른 손 탭 버튼)

---

## 1.3.2 플레이어 컨트롤러 (`scripts/player/player_controller.gd`)

### 작업 내용
- 플레이어 이동 로직 구현 (VirtualJoystick 연동)
- 기본 이동 속도 적용 (`player_base_stats.speed = 200.0`)
- 더미 그래픽: ColorRect 또는 Rectangle2D 사용

### 상세 스펙

```
class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 200.0

var current_direction: Vector2 = Vector2.ZERO
var is_attacking: bool = false

func _process(delta: float) -> void
    # VirtualJoystick direction 입력 수신
    velocity = current_direction * move_speed
    move_and_slide()

func set_input_direction(direction: Vector2) -> void
func start_auto_attack() -> void
func stop_auto_attack() -> void
```

### 완료 기준
- [ ] `player_controller.gd`가 생성됨
- [ ] VirtualJoystick 방향 입력으로 캐릭터 이동 가능
- [ ] 이동 속도가 `move_speed` (기본 200px/s)로 적용됨
- [ ] 더미 그래픽이 플레이어 노드에 연결됨 (ColorRect 사각형)
- [ ] `move_and_slide()`로 벽/장애물 충돌 처리

---

## 1.3.3 자동 공격 시스템 (`scripts/player/auto_attack.gd`)

### 작업 내용
- 일정 간격으로 적을 향해 투사체 발사
- PoolManager를 통한 투사체 풀링 연동

### 상세 스펙

```
class_name AutoAttack
extends Node

@export var attack_interval: float = 1.0
@export var projectile_template: PackedScene
@export var attack_range: float = 300.0
@export var attack_damage: int = 10

var timer: Timer
var nearest_enemy: Node2D

func _ready() -> void
func _process(delta: float) -> void
func _on_attack_timer_timeout() -> void
func find_nearest_enemy() -> Node2D
func fire_projectile(target_position: Vector2) -> void
```

### 동작 스펙
- **타이머**: `attack_interval` 초마다 자동 발사
- **목표 선택**: `attack_range` 내 가장 가까운 적 추적
- **발사**: PoolManager에서 투사체 획득 → 적 방향 발사
- **데미지**: 투사체가 적에 도달 시 `attack_damage` 적용

### 완료 기준
- [ ] `auto_attack.gd`가 플레이어에 자식 노드로 연결됨
- [ ] `attack_interval` 간격으로 투사체가 발사됨
- [ ] 가장 가까운 적이 향해 발사됨 (방향 계산 확인)
- [ ] PoolManager에서 투사체 재사용됨
- [ ] 투사체가 적에 충돌 시 데미지 적용 (더미: 로그 출력)

---

## 1.3.4 플레이어 HUD (`scenes/ui/player_hud.gd`)

### 작업 내용
- HP 바 표시 UI (더미 ColorRect 기반)
- GameManager의 `player_base_stats` 연동

### 상세 스펙

```
class_name PlayerHud
extends CanvasLayer

@onready var hp_bar: TextureProgressBar = $HPBar
@onready var stage_label: Label = $StageLabel

func update_hp(current: int, max_hp: int) -> void
func update_stage(stage_id: int) -> void
```

### 완료 기준
- [ ] `player_hud.gd`가 `scenes/ui/`에 생성됨
- [ ] HP 바가 현재 HP / 최대 HP로 업데이트됨
- [ ] 스테이지 번호 표시
- [ ] GameManager 상태 변경 시 HUD 자동 갱신 (시그널 연결)

---

## Sub-Phase 1-3 완료 체크리스트

- [ ] `virtual_joystick.gd` 생성 + 터치 드래그 테스트 완료
- [ ] `player_controller.gd` 생성 + 이동 테스트 완료
- [ ] `auto_attack.gd` 생성 + 자동 발사 테스트 완료
- [ ] `player_hud.gd` 생성 + HP 바/스테이지 표시 테스트 완료
- [ ] VirtualJoystick → PlayerController 연동 확인
- [ ] AutoAttack → PoolManager → 투사체 발사 확인
- [ ] GameManager → PlayerHud 연동 확인
