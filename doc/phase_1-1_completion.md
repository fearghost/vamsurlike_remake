# Phase 1-1: 프로젝트 초기화 및 CI 구축 — 완료 보고서

## 작업 일시
2026-11-18 (KST)

## 완료 상태
**완료** ✅

## 생성된 파일 총괄

| 카테고리 | 파일 수 | 설명 |
|----------|---------|------|
| 프로젝트 설정 | 2 | `project.godot`, `export_presets.cfg` |
| CI/CD | 1 | `.github/workflows/android_build.yml` |
| Autoload 매니저 | 4 | GameManager, SaveManager, PoolManager, SoundManager |
| 플레이어 시스템 | 4 | PlayerController, AutoAttack, PlayerStats, VirtualJoystick |
| 적 시스템 | 3 | EnemyAI, Spawner, EnemyData(Resource) |
| 프로젝트타일 | 2 | Projectile(.gd + .tscn) |
| 스토리 시스템 | 5 | StoryDirector, ActorMover, DialogueUI, SceneTransition, StoryDemo |
| UI 시스템 | 4 | MainMenu(.gd + .tscn), PlayerHud(.gd + .tscn) |
| 씬 파일 | 6 | main_menu.tscn, combat_demo.tscn, story_demo.tscn, enemy_ai.tscn, projectile.tscn, player_hud.tscn |
| 데이터 리소스 | 4 | chase_01.tres, ranged_01.tres, charge_01.tres, story_demo.json |
| **총계** | **33** | |

## 핵심 구현 사항

### 1. 프로젝트 설정 (`project.godot`)
- Godot 4.3 프로젝트 (config_version=5)
- 뷰포트: 1280×720, canvas_items 모드, keep aspect ratio
- 모바일 렌더링 (gl_compatibility)
- 스레드 안전성 활성화
- 4개 Autoload 등록: GameManager, SaveManager, PoolManager, SoundManager
- 모바일 입력 매핑 (move_left/right/up/down)

### 2. Android Export (`export_presets.cfg`)
- 패키지 ID: `com.vamsurlike.remake`
- 디버그 키스토어 활성화 (CI에서 keytool로 생성)
- 인터넷 권한, immersive mode
- OpenGL ES 3 (API=1)

### 3. CI 워크플로우 (`.github/workflows/android_build.yml`)
- 트리거: main/master push/PR, workflow_dispatch
- 컨테이너: `barichello/godot-ci:4.3-stable`
- 디버그 키스토어 자동 생성 → APK 빌드 → 아티팩트 업로드

### 4. Autoload 매니저
| 매니저 | 클래스 | 주요 기능 |
|--------|--------|-----------|
| GameManager | `GameManager` | GameState enum, 상태 전이, 플레이어 기본 스탯 |
| SaveManager | `SaveManager` | JSON 직렬화/역직렬화, `user://save_data.json` |
| PoolManager | `PoolManager` + `ObjectPool` | 이름 기반 객체 풀링, projectile 등록 |
| SoundManager | `SoundManager` | BGM/SFX 재생, 볼륨 제어, mute |

### 5. 플레이어 시스템
- **VirtualJoystick**: 터치 기반 가상 조이스틱 (Control 확장)
- **PlayerController**: CharacterBody2D, move_and_slide() 이동
- **AutoAttack**: nearest enemy 탐지 → PoolManager를 통한 projectile 발사
- **PlayerStats**: HP 관리, damage/heal, died signal

### 6. 적 시스템
- **EnemyAI**: chase/ranged/charge 3가지 AI 패턴
- **Spawner**: 웨이브 기반 적 스포닝, 랜덤 에지 스폰 위치
- **EnemyData**: Resource 기반 적 데이터 (ID, HP, 공격력, 방어력, 속도, 패턴)

### 7. 스토리 시스템
- **StoryDirector**: JSON 기반 시퀀스 실행 (move/dialogue/transition)
- **DialogueUI**: 화면 하단 30%에 대화 표시
- **story_demo.json**: G.S → Iolin 대사 → combat_demo.tscn 전이

## 검증 항목
- [x] project.godot autoload 등록 확인
- [x] export_presets.cfg Android 설정 확인
- [x] CI workflow 형식 확인
- [x] 모든 .gd 파일 참조 경로 일치 확인
- [x] 모든 .tscn 씬 스크립트 참조 확인
- [x] enemy_ai.tscn 서브리소스 형식 수정
- [x] projectile.tscn 스크립트 경로 수정
- [x] main_menu.tscn connection 형식 수정
- [x] spawner.gd wave_data 문자열 ID 처리 수정
- [x] enemy_ai.gd timing 함수 수정 (`get_tree().time` → `Time.get_ticks_msec()`)
- [x] enemy_ai.gd enemies 그룹 등록 추가
- [x] auto_attack.gd else 블록 구조 수정
- [x] PoolManager projectile pool 등록 (combat_demo.gd)
- [x] 중복 파일 정리 (projectile.gd, dialogue_ui.gd)

## 미정리 사항 (Phase 1-2 이후로 이관)
- Asset 스프라이트/오디오 실제 파일 대체 (현재 ColorRect 더미 그래픽 사용)
- EquipmentManager 구현 (Phase 1-2)
- UpgradeScreen 구현 (Phase 1-5)
- 실제 TTS 통합 (별도 Phase)
