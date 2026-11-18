# Sub-Phase 3-1: SD 스프라이트 제작 및 연동

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: SD 스프라이트 제작/가공, 캐릭터 애니메이션 상태 머신 구성

---

## 3.1.1 SD 스프라이트 시트 제작

### 작업 내용
- 플레이어, 몬스터, NPC용 SD 스프라이트 시트 제작 (Pixel Art)
- Godot AnimationPlayer 호환 프레임 구조

### 스프라이트 시트 규격

| 항목 | 규격 | 비고 |
|------|------|------|
| 시트 크기 | 256×64 또는 512×128 | 프레임 수에 따라 조정 |
| 프레임 방향 | 우측 향하기 기본 | 좌/우 반전으로 이동 표현 |
| 해상도 | 32×32 또는 64×64 per frame | Pixel Art 스타일 |

### 애니메이션 상태 정의

| 상태 | 프레임 수 | fps | 설명 |
|------|----------|-----|------|
| **idle** | 4 | 4 | 대기 애니메이션 (가벼운 호흡) |
| **walk** | 8 | 8 | 이동 애니메이션 |
| **attack** | 6 | 10 | 공격 애니메이션 |
| **hit** | 3 | 6 | 피격 애니메이션 |
| **death** | 6 | 8 | 사망 애니메이션 |

### 완료 기준
- [ ] 플레이어 SD 스프라이트 시트 1종 생성
- [ ] 몬스터 SD 스프라이트 시트 3종 (chase/ranged/charge) 생성
- [ ] NPC SD 스프라이트 시트 1종 생성
- [ ] 모든 상태(idle/walk/attack/hit/death) 프레임 포함
- [ ] 파일 경로: `assets/sprites/player_*.png`, `assets/sprites/enemy_*.png`, `assets/sprites/npc_*.png`

---

## 3.1.2 애니메이션 상태 머신 (`scripts/player/animation_state_machine.gd`)

### 작업 내용
- AnimationPlayer 기반 상태 머신 구현
- 스프라이트 시트 + 프레임 정보로 애니메이션 자동 구성

### 상세 스펙

```
class_name AnimationStateMachine
extends Node

@export var sprite_frames: Dictionary = {}  # { "idle": {"cols": 4, "rows": 1, "fps": 4}, ... }
@export var sprite_sheet: Texture2D

var current_state: String = "idle"
var animation_player: AnimationPlayer
var sprite_frame_size: Vector2 = Vector2(32, 32)

func _ready() -> void
func set_state(new_state: String) -> void
func _setup_animation(state_name: String) -> void
func _on_animation_finished() -> void
```

### 동작 스펙
1. **`_ready()`**: SpriteFrame 또는 TextureRect 기반 스프라이트 설정
2. **`set_state(new_state)`**: 현재 상태와 다르면 → `_setup_animation()` 호출
3. **`_setup_animation(state_name)`**: sprite_frames에서 cols/rows/fps 읽기 → AnimationPlayer 트랙 생성
4. **`_on_animation_finished()`**: idle/walk 등 루프 상태면 자동 재시작

### 완료 기준
- [ ] `animation_state_machine.gd`가 생성됨
- [ ] 스프라이트 시트가 정상 로드됨
- [ ] 상태 전환(idle→walk→attack) 시 애니메이션 변경 확인
- [ ] 루프 애니메이션이 계속 재생됨
- [ ] hit/death 등 비루프 애니메이션이 종료 시 시그널 emit

---

## 3.1.3 캐릭터 스프라이트 연동 (`scripts/player/player_controller.gd` 수정)

### 작업 내용
- PlayerController에 SD 스프라이트 연결
- 이동/공격 상태에 따라 애니메이션 전환

### 수정 사항

```
PlayerController (수정):
├── Sprite (AnimatedSprite2D 또는 TextureRect)
│   └── AnimationStateMachine (AnimationStateMachine)
├── VirtualJoystick 연동
│   └── move_direction != Vector2.ZERO → set_state("walk")
│   └── move_direction == Vector2.ZERO → set_state("idle")
└── AutoAttack 연동
    └── attack 발사 시작 → set_state("attack")
    └── attack 종료 → set_state("idle") 또는 "walk" 유지
```

### 완료 기준
- [ ] PlayerController에 SD 스프라이트 연결됨
- [ ] 이동 중 → walk 애니메이션
- [ ] 정지 시 → idle 애니메이션
- [ ] 공격 시 → attack 애니메이션
- [ ] 피격 시 → hit 애니메이션 (EnemyAI에서 데미지 받을 때)

---

## Sub-Phase 3-1 완료 체크리스트

- [ ] SD 스프라이트 시트 제작 완료 (플레이어 + 몬스터 3종 + NPC)
- [ ] `animation_state_machine.gd` 생성 + 상태 머신 구현 완료
- [ ] PlayerController에 스프라이트 연동 + 애니메이션 전환 확인 완료
- [ ] 모든 상태(idle/walk/attack/hit/death) 애니메이션 정상 재생 확인
- [ ] 스프라이트 시트 경로가 CharacterData의 `sprite_sheet_path`와 연결됨
