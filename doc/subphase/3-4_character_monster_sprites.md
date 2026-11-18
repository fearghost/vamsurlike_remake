# Sub-Phase 3-4: 캐릭터/몬스터 스프라이트 연동

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: CharacterData/EnemyData에 SD 스프라이트 연결, 애니메이션 완성

---

## 3.4.1 플레이어 캐릭터 스프라이트 연동

### 작업 내용
- PlayerController의 스프라이트를 실제 SD 스프라이트 시트로 교체
- CharacterData의 `sprite_sheet_path`와 연동

### 수정 사항

```
PlayerController (수정):
├── Sprite: AnimatedSprite2D (또는 TextureRect + AnimationStateMachine)
│   ├── sprite_frames: CharacterData.sprite_sheet_path에서 로드
│   └── animation_state_machine: set_state() 호출로 상태 전환

CharacterData (연동):
├── sprite_sheet_path: "res://assets/sprites/player_gs.png"
├── sprite_frames: {
│       "idle": {"cols": 4, "rows": 1, "fps": 4},
│       "walk": {"cols": 8, "rows": 1, "fps": 8},
│       "attack": {"cols": 6, "rows": 1, "fps": 10},
│       "hit": {"cols": 3, "rows": 1, "fps": 6},
│       "death": {"cols": 6, "rows": 1, "fps": 8}
│   }
```

### 동작 스펙
1. **`_ready()`**: CharacterData에서 `sprite_sheet_path` 읽기 → Texture2D 로드
2. **`set_state(state_name)`**: sprite_frames에서 cols/rows/fps 읽기 → 애니메이션 설정
3. **이동 중**: VirtualJoystick 방향 입력 → set_state("walk")
4. **정지 시**: set_state("idle")
5. **공격 시**: AutoAttack 발사 시작 → set_state("attack")

### 완료 기준
- [ ] PlayerController에 실제 SD 스프라이트 시트 연결됨
- [ ] CharacterData의 sprite_sheet_path가 실제 파일 경로와 일치
- [ ] idle/walk/attack/hit/death 애니메이션 모두 정상 재생
- [ ] 상태 전환이 부드럽게 동작 (애니메이션 끊김 없음)

---

## 3.4.2 몬스터 스프라이트 연동

### 작업 내용
- EnemyAI의 스프라이트를 실제 SD 스프라이트 시트로 교체
- EnemyData의 `sprite_sheet_path`와 연동

### 수정 사항

```
EnemyAI (수정):
├── Sprite: AnimatedSprite2D
│   ├── sprite_frames: EnemyData.sprite_sheet_path에서 로드
│   └── animation_state_machine: 상태 전환 로직

EnemyData (연동):
├── chase_01:
│   ├── sprite_sheet_path: "res://assets/sprites/enemy_chase.png"
│   └── sprite_frames: idle(4)/walk(6)/attack(4)/hit(3)/death(5)
├── ranged_01:
│   ├── sprite_sheet_path: "res://assets/sprites/enemy_ranged.png"
│   └── sprite_frames: idle(4)/walk(4)/attack(6)/hit(3)/death(5)
└── charge_01:
    ├── sprite_sheet_path: "res://assets/sprites/enemy_charge.png"
    └── sprite_frames: idle(4)/charge_windup(2)/charge_dash(1)/hit(3)/death(5)
```

### 동작 스펙
1. **`_ready()`**: EnemyData에서 `sprite_sheet_path` 읽기 → Texture2D 로드
2. **AI 패턴별 애니메이션**:
   - chase: idle ↔ walk (플레이어 거리 기반 전환)
   - ranged: idle (원거리 유지 중), attack (투사체 발사 시)
   - charge: idle → windup → dash → idle (패턴 사이클)
3. **피격 시**: 데미지 받음 → set_state("hit") → idle로 복귀
4. **사망 시**: HP 0 → set_state("death") → death 애니메이션 종료 후 queue_free()

### 완료 기준
- [ ] chase/ranged/charge 몬스터 모두 SD 스프라이트 연결됨
- [ ] EnemyData의 sprite_sheet_path가 실제 파일 경로와 일치
- [ ] 각 AI 패턴에 맞는 애니메이션 정상 재생
- [ ] 피격 → 사망까지의 애니메이션 체인 확인
- [ ] death 애니메이션 종료 후 적 노드 제거 확인

---

## 3.4.3 NPC 스프라이트 연동

### 작업 내용
- NPC 데이터에 스프라이트 연결 (스토리 컷신에서 사용)

### 수정 사항

```
NPCData (연동):
├── sprite_sheet_path: "res://assets/sprites/npc_merchant.png"
└── sprite_frames: idle(4)/talk(6)

StoryDirector (연동):
├── actors: {
│       "Merchant": NPCActorNode,  # NPCData.sprite_sheet_path 연결
│       "G.S": PlayerActorNode,
│       "Iolin": PlayerActorNode
│   }
```

### 완료 기준
- [ ] NPC 스프라이트 시트 생성/연동 완료
- [ ] StoryDirector의 actors에 NPC 스프라이트 표시 확인
- [ ] 대화 중 talk 애니메이션 재생 (선택사항)

---

## Sub-Phase 3-4 완료 체크리스트

- [ ] 플레이어 SD 스프라이트 연동 + 모든 애니메이션 확인 완료
- [ ] chase/ranged/charge 몬스터 SD 스프라이트 연동 완료
- [ ] NPC 스프라이트 연동 완료
- [ ] CharacterData/EnemyData/NPCData의 sprite_sheet_path가 실제 파일과 일치
- [ ] 상태 전환(idle→walk→attack→hit→death)이 모든 캐릭터/몬스터에서 정상 동작
- [ ] death 애니메이션 종료 후 노드 제거 확인
