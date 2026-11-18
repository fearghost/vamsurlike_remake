# Sub-Phase 3-5: 스토리 씬 에셋 연동

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: 쿼터뷰 배경, 캐릭터 스프라이트, 다이얼로그 UI 완성

---

## 3.5.1 쿼터뷰 배경 에셋

### 작업 내용
- 스토리 컷신용 쿼터뷰 배경 이미지 제작/적용
- 스테이지별 배경 교체 가능 구조

### 스펙

| 항목 | 내용 |
|------|------|
| 배경 크기 | 1280×720 (Viewport 해상도 맞춤) |
| 형식 | PNG, 투명 레이어 포함 가능 |
| 경로 | `assets/ui/bg_story_stage_01.png` 등 |
| 스테이지별 | StageData.story_background_path 필드 추가 |

### 배경 디자인 방향
- 창세기전 2 컨셉: 어두운 판타지 풍경, 군사 캠프, 폐허, 성벽
- 쿼터뷰 느낌: 약간 위에서 내려다보는 각도 (isometric-ish)
- 레이어 구조: 배경(원경) + 중간(중경) + 캐릭터(전경)

### 완료 기준
- [ ] `assets/ui/bg_story_*.png` 파일 생성/배치됨
- [ ] StoryDirector가 StageData에서 배경 경로 읽음
- [ ] 스토리 씬에 배경 이미지 표시 확인

---

## 3.5.2 쿼터뷰 액터 완성

### 작업 내용
- StoryDirector의 actors에 실제 SD 스프라이트 연결
- 이동 + 대화 연출 시 스프라이트 애니메이션 정상 동작

### 수정 사항

```
StoryDemo 씬 (수정):
├── StoryDirector (StoryDirector)
│   ├── script_file: "res://data/stages/story_stage_01.json"
│   └── actors: {
│       "G.S": ActorNode_GS,    # AnimatedSprite2D + player_gs 스프라이트
│       "Iolin": ActorNode_Iolin # AnimatedSprite2D + player_iolin 스프라이트
│   }
├── BackgroundLayer (TextureRect - 배경 이미지)
└── DialogueUI (DialogueUI - 에셋 적용 완료)

ActorNode_GS:
├── AnimatedSprite2D (player_gs 스프라이트 시트)
├── AnimationStateMachine
│   ├── idle ↔ walk (웨이포인트 이동 중)
│   └── talk (대화 중 - 선택사항)
└── ActorMover (웨이포인트 따라 이동)
```

### 동작 스펙
1. **스토리 씬 로드**: 배경 이미지 + 액터 스프라이트 표시
2. **이동 시작**: ActorMover가 웨이포인트 따라 이동 → walk 애니메이션
3. **도착**: walk → idle 애니메이션 전환
4. **대화 시작**: DialogueUI 표시 → 액터가 talk 애니메이션 (선택사항)
5. **대화 종료**: DialogueUI 숨김 → 다음 스텝 진행

### 완료 기준
- [ ] StoryDirector의 actors에 실제 SD 스프라이트 연결됨
- [ ] 이동 중 walk 애니메이션, 정지 시 idle 애니메이션 확인
- [ ] 배경 이미지가 쿼터뷰 공간에 정상 표시됨
- [ ] DialogueUI(에셋 적용 완료)와 액터 스프라이트가 시각적으로 조화

---

## 3.5.3 스토리 JSON 스크립트 실제 콘텐츠 작성

### 작업 내용
- 더미 story_demo.json → 창세기전 2 컨셉의 실제 스토리 스크립트로 교체
- 여러 스테이지별 JSON 파일 생성

### 스토리 예시 (Stage 1-1)

```json
[
    {
        "type": "move",
        "actor": "G.S",
        "waypoints": [[100, 400], [350, 300]]
    },
    {
        "type": "dialogue",
        "speaker": "G.S",
        "text": "제2부대가 진지를 점령했다. 우리도前进해야 한다."
    },
    {
        "type": "move",
        "actor": "Iolin",
        "waypoints": [[700, 450], [500, 320]]
    },
    {
        "type": "dialogue",
        "speaker": "Iolin",
        "text": "적의 저격수가 관측된다. 경계하라."
    },
    {
        "type": "move",
        "actor": "G.S",
        "waypoints": [[350, 300], [450, 280]]
    },
    {
        "type": "dialogue",
        "speaker": "G.S",
        "text": "알았다. 준비되면 출발한다."
    },
    {
        "type": "transition",
        "target_scene": "scenes/game/combat_stage_01_01.tscn",
        "message": "제1구역 전투 개시"
    }
]
```

### 완료 기준
- [ ] `data/stages/story_stage_*.json` 파일 3개 이상 생성됨
- [ ] 창세기전 2 세계관/대사 컨셉 반영 확인
- [ ] StoryDirector가 모든 JSON 파일 정상 파싱 확인
- [ ] 시퀀스 진행 시 대사 내용이 실제 콘텐츠로 표시됨

---

## Sub-Phase 3-5 완료 체크리스트

- [ ] 쿼터뷰 배경 에셋 생성/적용 완료
- [ ] StoryDirector actors에 SD 스프라이트 연동 완료
- [ ] 이동 + 대화 연출에서 애니메이션 정상 동작 확인
- [ ] 실제 창세기전 2 컨셉의 스토리 JSON 3개 이상 작성 완료
- [ ] 스토리 씬 전체(배경 + 액터 + DialogueUI)가 에셋 완성 상태로 플레이 가능
