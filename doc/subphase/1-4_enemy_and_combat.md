# Sub-Phase 1-4: 적 시스템 및 전투 뼈대

> Parent Phase: Phase 1 — Capability Check
> 목표: 적 스폰, AI 패턴, 웨이브 구조, HUD 연동 구현 (더미 그래픽)

---

## 1.4.1 적 데이터 더미 (`data/enemies/enemy_dummy.tres`)

### 작업 내용
- 더미 몬스터 데이터 Resource 생성
- Phase 2의 `EnemyData`로 이어지는 뼈대

### 상세 스펙

```
class_name EnemyData
extends Resource

@export var enemy_id: String = "dummy_enemy_01"
@export var enemy_name: String = "더미 몬스터"
@export var hp: int = 50
@export var attack: int = 5
@export var defense: int = 2
@export var speed: float = 80.0
@export var ai_pattern: String = "chase"  # "chase", "ranged", "charge"
@export var drop_table: Array[Dictionary] = []
@export var sprite_path: String = ""
```

### 더미 데이터 예시 (3종)

| enemy_id | ai_pattern | hp | attack | speed |
|----------|-----------|-----|--------|-------|
| `chase_01` | chase | 50 | 5 | 80.0 |
| `ranged_01` | ranged | 30 | 8 | 40.0 |
| `charge_01` | charge | 80 | 12 | 120.0 |

### 완료 기준
- [ ] `data/enemies/` 폴더에 더미 `.tres` 파일 3종 생성됨
- [ ] Resource가 Godot에서 정상 로드됨
- [ ] `enemy_id`, `hp`, `ai_pattern` 등 필드 확인 가능

---

## 1.4.2 적 AI 베이스 (`scripts/enemy/enemy_ai.gd`)

### 작업 내용
- AI 패턴별 행동 로직 구현 (추적/원거리/돌진)
- 더미 그래픽: ColorRect 기반 적 스프라이트

### 상세 스펙

```
class_name EnemyAI
extends CharacterBody2D

@export var enemy_data: EnemyData
var current_pattern: String = "chase"

func _process(delta: float) -> void
    match current_pattern:
        "chase": _ai_chase(delta)
        "ranged": _ai_ranged(delta)
        "charge": _ai_charge(delta)

func _ai_chase(delta: float) -> void
    # 플레이어 방향으로 직진 이동
    
func _ai_ranged(delta: float) -> void
    # 일정 거리 유지 + 간헐적 투사체 발사
    
func _ai_charge(delta: float) -> void
    # 잠시 대기 → 플레이어 향해 돌진 →クール다운
```

### 패턴별 스펙

| 패턴 | 행동 | 특징 |
|------|------|------|
| **chase** | 플레이어 방향으로 직진 | 기본 추적형, 속도 `enemy_data.speed` |
| **ranged** | 일정 거리 유지 + 투사체 발사 | 원거리 공격, 발사 간격 2초 |
| **charge** | 대기 1초 → 돌진 0.5초 → 쿨다운 2초 | 순간 가속, 충돌 시 추가 데미지 |

### 완료 기준
- [ ] `enemy_ai.gd`가 생성됨
- [ ] chase 패턴: 플레이어를 따라올 수 있음
- [ ] ranged 패턴: 일정 거리 유지 + 투사체 발사
- [ ] charge 패턴: 대기 → 돌진 → 쿨다운 사이클
- [ ] 모든 패턴에서 더미 그래픽 표시 (ColorRect, 적색)

---

## 1.4.3 적 스포너 (`scripts/enemy/spawner.gd`)

### 작업 내용
- 웨이브별 적 스폰 관리
- 스테이지 시작 시 웨이브 진행 로직

### 상세 스펙

```
class_name Spawner
extends Node2D

@export var wave_data: Array[Dictionary]  # [{enemies: [...], spawn_interval: float}]
var current_wave: int = 0
var is_waving_active: bool = false

func start_wave(wave_index: int) -> void
func spawn_enemy(enemy_data: EnemyData, position: Vector2) -> void
func _on_wave_timer_timeout() -> void
func all_waves_cleared() -> bool
```

### 웨이브 예시

| 웨이브 | 몬스터 구성 | 스폰 간격 |
|--------|------------|-----------|
| 1 | chase_01 × 5 | 1.0초 |
| 2 | ranged_01 × 3 + chase_01 × 3 | 0.8초 |
| 3 | charge_01 × 2 + ranged_01 × 4 | 0.6초 |

### 완료 기준
- [ ] `spawner.gd`가 생성됨
- [ ] `start_wave()` 호출 시 웨이브 시작
- [ ] `spawn_enemy()`로 적 노드가 씬에 추가됨
- [ ] 스폰 간격이 정상 작동 (Timer 기반)
- [ ] 모든 웨이브 클리어 시 `all_waves_cleared()` → true

---

## 1.4.4 투사체 시스템 (`scenes/game/projectile.gd`)

### 작업 내용
- 플레이어 및 적 투사체 공통 클래스
- 충돌 감지 (Hitbox/Hurtbox)

### 상세 스펙

```
class_name Projectile
extends Area2D

@export var damage: int = 10
@export var speed: float = 400.0
@export var owner: String = "player"  # "player" 또는 "enemy"

var velocity: Vector2

func _process(delta: float) -> void
    position += velocity * delta

func _on_body_entered(body: Node2D) -> void
    # 충돌 처리: owner에 따라 플레이어/적 데미지 적용
```

### 충돌 스펙
- **플레이어 투사체** → 적 body에 충돌 시 적 데미지
- **적 투사체** → 플레이어 body에 충돌 시 플레이어 데미지
- PoolManager로 풀링 연동

### 완료 기준
- [ ] `projectile.gd`가 생성됨
- [ ] 방향 벡터로 이동 (속도 적용)
- [ ] Area2D 충돌 감지 정상 작동
- [ ] owner별 타겟 구분 (플레이어 vs 적)
- [ ] 충돌 후 PoolManager로 반환

---

## 1.4.5 데미지 및 체력 시스템 (`scripts/player/player_stats.gd`)

### 작업 내용
- 플레이어 HP 관리
- 적 HP 관리 (공통)
- 데미지 계산 (attack - defense)

### 상세 스펙

```
class_name PlayerStats
extends Node

@export var current_hp: int = 100
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 5

func take_damage(amount: int) -> void
    var actual_damage = max(1, amount - defense)
    current_hp = clamp(current_hp - actual_damage, 0, max_hp)
    if current_hp <= 0:
        _on_died()

func heal(amount: int) -> void
    current_hp = min(current_hp + amount, max_hp)

func _on_died() -> void
    # 사망 로직: 게임 오버 또는 리스폰
```

### 완료 기준
- [ ] `player_stats.gd`가 생성됨
- [ ] `take_damage()` 호출 시 HP 감소 (방어력 적용)
- [ ] HP 0 이하 시 `_on_died()` 호출
- [ ] `heal()` 호출 시 HP 회복 (최대치 초과 없음)
- [ ] HUD HP 바와 동기화

---

## Sub-Phase 1-4 완료 체크리스트

- [ ] 더미 EnemyData Resource 3종 생성 완료
- [ ] chase/ranged/charge AI 패턴 모두 구현 완료
- [ ] Spawner가 웨이브별 적 스폰 정상 작동
- [ ] Projectile 충돌 감지 + 데미지 적용 확인
- [ ] PlayerStats 데미지 계산 (공격력 - 방어력) 정상 작동
- [ ] 전투 루프: 적 스폰 → AI 행동 → 투사체 교전 → HP 감소 → 적 사망
- [ ] 모든 웨이브 클리어 시 전투 종료 메시지 표시
