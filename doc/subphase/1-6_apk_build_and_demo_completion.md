# Sub-Phase 1-6: APK 빌드 검증 및 데모 완성

> Parent Phase: Phase 1 — Capability Check
> 목표: 전체 데모 통합 + Android APK 빌드 + 기기 테스트

---

## 1.6.1 메인 메뉴 씬 (`scenes/ui/main_menu.tscn`)

### 작업 내용
- ColorRect 기반 더미 메인 메뉴 씬 생성
- "Start", "Continue" 버튼 연결

### 상세 스펙

```
Main menu (CanvasLayer):
├── Background (ColorRect - 검은색)
├── TitleLabel (Label - "Genesis 2 Remake")
├── StartButton (Button - "Start")
│   └──pressed → GameManager.change_state(STORY_SCENE)
├── ContinueButton (Button - "Continue")
│   └──pressed → SaveManager.load() + GAME_STATE.COMBAT
└── ExitButton (Button - "Exit")
    └──pressed → get_tree().quit()
```

### 완료 기준
- [ ] `main_menu.tscn`이 Godot에서 열림
- [ ] Start 버튼 클릭 시 STORY_SCENE 상태로 전환
- [ ] Continue 버튼 클릭 시 세이브 데이터 로드 후 COMBAT으로 전환
- [ ] Exit 버튼 클릭 시 게임 종료

---

## 1.6.2 전투 씬 (`scenes/game/combat_demo.tscn`)

### 작업 내용
- 플레이어 + 적 스포너 + HUD가 포함된 전투 씬 생성
- 더미 그래픽 기반

### 씬 구성

```
CombatDemo (Node2D):
├── Player (PlayerController)
│   ├── Sprite (ColorRect - 파란색 사각형)
│   └── AutoAttack (AutoAttack)
├── Spawner (Spawner)
├── VirtualJoystick (VirtualJoystick)
└── PlayerHud (PlayerHud)
```

### 완료 기준
- [ ] `combat_demo.tscn`이 Godot에서 열림
- [ ] 플레이어가 VirtualJoystick로 이동 가능
- [ ] Spawner가 웨이브별 적 스폰
- [ ] AutoAttack가 자동 발사
- [ ] HUD에 HP/스테이지 표시

---

## 1.6.3 스토리 씬 (`scenes/story/story_demo.tscn`)

### 작업 내용
- StoryDirector + 더미 액터 + DialogueUI가 포함된 스토리 씬 생성

### 씬 구성

```
StoryDemo (Node2D):
├── StoryDirector (StoryDirector)
│   ├── actors: {"G.S": Actor1, "Iolin": Actor2}
│   └── script_file: "res://data/stages/story_demo.json"
├── Actor1 (Node2D - "G.S")
│   └── Sprite (ColorRect - 흰색)
├── Actor2 (Node2D - "Iolin")
│   └── Sprite (ColorRect - 회색)
└── DialogueUI (DialogueUI)
```

### 완료 기준
- [ ] `story_demo.tscn`이 Godot에서 열림
- [ ] 액터들이 웨이포인트 따라 이동
- [ ] 대사가 순차 표시
- [ ] 시퀀스 종료 후 전투 씬으로 전환

---

## 1.6.4 전체 게임 루프 통합 테스트

### 작업 내용
- 메인 메뉴 → 스토리 컷신 → 전투 → 보상 화면 → 메인 메뉴 전체 루프 플레이

### 테스트 시나리오

| 단계 | 동작 | 기대 결과 |
|------|------|----------|
| 1 | 메인 메뉴 시작 | TITLE 표시, Start/Continue 버튼 클릭 가능 |
| 2 | Start 버튼 클릭 | STORY_SCENE 전환, 스토리 씬 로드 |
| 3 | 스토리 시퀀스 진행 | 이동 → 대화 → 이동 → 대화 순차 실행 |
| 4 | 전투 전환 | COMBAT 상태로 전환, 전투 씬 로드 |
| 5 | 전투 플레이 | VirtualJoystick 이동, 자동 공격, 적 스폰 |
| 6 | 웨이브 클리어 | All waves cleared → UPGRADE 화면 (더미) |
| 7 | 메인 메뉴 복귀 | MAIN_MENU 상태로 전환, 메인 메뉴 로드 |

### 완료 기준
- [ ] 전체 루프가 에러 없이 한 번 돌고 끝남
- [ ] 상태 전환 시 에러 로그 없음
- [ ] 씬 전환 시 메모리 누수 없음 (Godot Debugger 확인)
- [ ] 세이브/로드가 루프 내 여러 지점에서 정상 작동

---

## 1.6.5 Android APK 빌드 및 설치 테스트

### 작업 내용
- GitHub Actions에서 APK 자동 빌드
- APK를 Android 기기/에뮬레이터에 설치하여 실제 동작 확인

### 빌드 검증 체크리스트

| 항목 | 확인 방법 |
|------|----------|
| CI 파이프라인 성공 | GitHub Actions 탭에서 green 체크 |
| Artifact 다운로드 | artifact APK 파일 다운로드 가능 |
| APK 설치 | `adb install vamsurlike_remake.apk` 성공 |
| 앱 실행 | Android 기기에서 앱 아이콘 표시, 실행됨 |
| 터치 조작 | VirtualJoystick 터치 드래그 반응 |
| 전투 동작 | 적 스폰, 자동 공격, HP 감소 확인 |
| 스토리 컷신 | 이동 + 대화 연출 확인 |

### 완료 기준
- [ ] GitHub Actions에서 APK 빌드 성공 (main/master push 시)
- [ ] Artifact APK 다운로드 가능
- [ ] Android 기기/에뮬레이터에서 설치 및 실행 완료
- [ ] 모든 게임 루프 단계가 모바일에서 정상 작동
- [ ] 터치 조작(조이스틱)이 모바일 환경에서 정상 반응

---

## Phase 1 전체 완료 체크리스트

### Sub-Phase별
- [x] 1-1: 프로젝트 초기화 및 CI 구축 완료
- [x] 1-2: Autoload 매니저 (GameManager, SaveManager, PoolManager, SoundManager) 구현 완료
- [x] 1-3: 플레이어 컨트롤러 + VirtualJoystick + 자동 공격 구현 완료
- [x] 1-4: 적 시스템 (AI 패턴, 스포너, 투사체, 데미지) 구현 완료
- [x] 1-5: 스토리 컷신 (StoryDirector, ActorMover, DialogueUI, 시퀀스) 구현 완료
- [x] 1-6: APK 빌드 검증 + 전체 게임 루프 테스트 완료

### 공통
- [ ] 에셋 미연결 (ColorRect/기본 도형) 상태로 모든 시스템 동작
- [ ] GitHub Actions CI 파이프라인 정상 작동
- [ ] Android APK 설치 및 플레이 가능
- [ ] 데모가 "플레이어블" 수준으로 완성됨
