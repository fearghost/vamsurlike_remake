# Genesis 2 Remake (Vamsurlike) — Phase별 상세 개발 로드맵

> 원본 설계서: `genesis2_remake.md`
> 생성일: 2026-11-17

---

## 개요

창세기전 2의 세계관을 바탕으로 한 뱀서라이크(Soulslike) 생존 게임.
주요 게임 루프: **스테이지 선택 → 스토리 컷신(자동 쿼터뷰 이동) → 웨이브 전투(생존) → 보상 및 장비/스킬 관리**

---

## Phase 1 — Capability Check (기능 검증 데모)

### 목표
에셋 연결이 없는 상태(ColorRect, 기본 도형 활용)로 **플레이어블 Demo**를 구축하고,
GitHub Actions를 통한 Android APK 자동 빌드 파이프라인을 검증한다.

### 상세 작업 항목

| No | 작업 내용 | 비고 |
|----|----------|------|
| 1.1 | Godot 4.3 프로젝트 초기화 (`project.godot`, `export_presets.cfg`) | 모바일 표준 해상도(1280×720 가로) 설정, stretch 모드 적용 |
| 1.2 | 저장소 폴더 구조 생성 | `assets/`, `data/`, `scenes/`, `scripts/` 하위 디렉토리 전체 생성 |
| 1.3 | GitHub Actions 워크플로우 구축 (`.github/workflows/android_build.yml`) | debug keystore 자동 생성 → APK 빌드 → artifact 업로드 |
| 1.4 | `GameManager` autoload 노드 구현 | GameState enum(MAIN_MENU, STORY_SCENE, COMBAT, UPGRADE, PAUSE), 상태 전환 시그널 |
| 1.5 | 메인 메뉴 씬 (Placeholder) | ColorRect 기반 더미 UI — "Start", "Continue" 버튼 |
| 1.6 | 플레이어 컨트롤러 (더미 그래픽) | VirtualJoystick 연동 이동, 기본 이동 속도 200px/s |
| 1.7 | 자동 공격 시스템 뼈대 | 일정 간격으로 적을 향해 투사체 발사 (원형 더미) |
| 1.8 | 적 스포너 및 AI (더미) | 추적형/원거리형 더미 몬스터 — 스폰 웨이브 구조 |
| 1.9 | 오브젝트 풀링 (`PoolManager`) | 투사체, 적, 이펙트 노드 풀링 구현 |
| 1.10 | 쿼터뷰 스토리 컷신 전환 뼈대 | `StoryDirector` — 웨이포인트 이동(Tween) + 다이얼로그 UI 시퀀스 |
| 1.11 | HUD (더미) | HP 바, 스탯 표시 |
| 1.12 | 세이브/로드 시스템 (`SaveManager`) | `user://save_data.json` 직렬화 — 스테이지 클리어 현황 저장 |
| 1.13 | Android APK 빌드 검증 | GitHub Actions에서 실제 빌드 → artifact 다운로드 확인 |

### 산출물
- 플레이 가능한 데모 APK (에셋 미연결, 기본 도형 그래픽)
- GitHub Actions 빌드 파이프라인 동작 확인

### 완료 기준
- [ ] `main`/`master` 브랜치 푸시 시 APK가 자동으로 빌드되고 artifact로 제공됨
- [ ] 데모 APK에서 메인 메뉴 → 스토리 컷신 → 전투 → HUD 표시까지 전체 루프 플레이 가능

---

## Phase 2 — Core Skeleton (데이터 중심 모듈형 뼈대)

### 목표
캐릭터, 몬스터, NPC, 스테이지, 스토리, 스킬, 장비 시스템을 **Resource/JSON 기반**으로 확장 가능한 뼈대로 완성한다.

### 상세 작업 항목

| No | 작업 내용 | 비고 |
|----|----------|------|
| 2.1 | `CharacterData` Resource 클래스 | 고유 패시브, 기본 무기, 이동 속도, SD 스프라이트 시트 경로 |
| 2.2 | `EnemyData` Resource 클래스 | AI 패턴(추적/원거리/돌진), 스탯, 드랍 테이블 정의 |
| 2.3 | `NPCData` Resource 클래스 | 대화 이벤트, 상호작용 트리거 |
| 2.4 | `SkillBase` 클래스 + `SkillTreeManager` | 액티브/패시브 스킬 모듈화, 선행 노드(`prerequisite_ids`), 해금 레벨 관리 |
| 2.5 | 부위별 장비 시스템 (8슬롯) | `EquipmentManager` — HELMET, SHIELD, ARMOR, WEAPON, BOOTS, RING_1, RING_2, NECKLACE |
| 2.6 | 양손 무기 ↔ 방패 제약 로직 | 양손 무기 장착 시 방패 자동 해제, 방패 장착 시 양손 무기 장착 거부 |
| 2.7 | JSON 기반 데이터 로드 시스템 | `data/characters/`, `data/enemies/`, `data/items/`, `data/skills/`, `data/stages/` 폴더에서 `.tres` 또는 `.json` 읽기 |
| 2.8 | 스테이지 및 웨이브 관리 | 스테이지별 몬스터 스폰 테이블, 웨이브 진행 로직 |
| 2.9 | 스토리 연출 확장 (`StoryDirector` 완성) | JSON 스크립트 파싱 — 캐릭터 이동, 다이얼로그 순차 실행, 시퀀스 종료 시 전투 전환 |
| 2.10 | 인벤토리 UI 뼈대 | 장비 슬롯 표시, 아이템 드래그/장착 |
| 2.11 | 스킬 트리 UI 뼈대 | 노드 표시, 선행 조건 체크, 스킬 포인트 할당 |
| 2.12 | 보상 및 업그레이드 화면 | 전투 후 장비/스킬 선택 UI |
| 2.13 | `SoundManager` autoload | BGM/SFX 플레이, 볼륨 제어 |

### 산출물
- 데이터 중심의 전체 게임 시스템 뼈대 (에셋 미연결)
- 더미 JSON 데이터로 모든 시스템 검증 가능

### 완료 기준
- [ ] 새로운 캐릭터/적/스킬/장비를 JSON 리소스만 추가하면 시스템에 자동 반영됨
- [ ] 장비 장착 시 양손 무기 ↔ 방패 제약이 정상 작동
- [ ] 스킬 트리가 선행 조건에 따라 해금/비활성화됨
- [ ] 스토리 JSON 스크립트로 컷신 연출 작성 가능

---

## Phase 3 — Content & Asset Integration (콘텐츠 및 에셋 연동)

### 목표
창세기전 2 컨셉의 **SD 스프라이트, UI 테마, BGM**을 연결하고, 데이터를 실제 콘텐츠로 확장한다.

### 상세 작업 항목

| No | 작업 내용 | 비고 |
|----|----------|------|
| 3.1 | SD 스프라이트 제작/가공 | 플레이어, 몬스터, NPC 캐릭터 시트 (Pixel Art 스타일) |
| 3.2 | UI 에셋 디자인 | 메인 메뉴, HUD, 인벤토리, 스킬 트리, 스토리 다이얼로그 UI 테마 |
| 3.3 | BGM/SFX 에셋 연동 | 전투 BGM, 스토리 BGM, 타격/이동/장착 SFX |
| 3.4 | 캐릭터 스프라이트 연동 | `CharacterData`의 스프라이트 경로에 실제 이미지 연결, 애니메이션 상태 머신 구성 |
| 3.5 | 몬스터 스프라이트 연동 | `EnemyData`에 스프라이트 연결 — 공격/피격/사망 애니메이션 |
| 3.6 | UI 에셋 적용 | ColorRect 더미 → 실제 UI 그래픽 교체 |
| 3.7 | 스토리 씬 에셋 연동 | 쿼터뷰 배경, 캐릭터 스프라이트, 다이얼로그 UI 완성 |
| 3.8 | 스테이지별 데이터 확장 | 실제 창세기전 2 스토리에 맞춘 스테이지, 몬스터, 드랍 테이블 작성 |
| 3.9 | 스킬 효과 완성 | 더미 → 실제 스킬 효과 (데미지, 버프, 데버프, 이펙트) |
| 3.10 | 장비 효과 완성 | 슬롯별 스탯 보너스 계산, 장비 아이콘 연동 |
| 3.11 | 파티클/이펙트 추가 | 피격, 사망, 스킬 발사 이펙트 |
| 3.12 | 최종 QA 및 빌드 검증 | 전체 게임 루프 플레이 테스트, APK 최종 빌드 |

### 산출물
- 에셋 연동이 완료된 완성형 데모
- 실제 창세기전 2 컨셉의 콘텐츠가 반영된 APK

### 완료 기준
- [ ] 모든 캐릭터/몬스터에 SD 스프라이트가 정상 표시됨
- [ ] UI, BGM, SFX가 게임 전체에 일관되게 적용됨
- [ ] 스토리 컷신이 실제 컨셉 아트와 함께 연출됨
- [ ] 전체 게임 루프(메뉴 → 스토리 → 전투 → 보상)가 에셋 완성 상태로 플레이 가능

---

## 개발 구조 참고

### 저장소 구조 (요약)

```
vamsurlike_remake/
├── .github/workflows/android_build.yml
├── assets/
│   ├── sprites/          # 캐릭터, 몬스터, NPC SD 스프라이트
│   ├── ui/               # UI 테마 및 아이콘
│   └── audio/            # BGM 및 SFX
├── data/
│   ├── characters/       # 플레이어블 캐릭터 데이터
│   ├── enemies/          # 몬스터 데이터
│   ├── items/            # 부위별 장비 아이템 데이터
│   ├── skills/           # 스킬 및 스킬 트리 데이터
│   └── stages/           # 스테이지 및 스토리 스크립트
├── scenes/
│   ├── common/           # Hitbox, Hurtbox, VirtualJoystick
│   ├── ui/               # 메인 메뉴, HUD, 인벤토리, 스킬트리 UI
│   ├── game/             # 전투 씬
│   └── story/            # 쿼터뷰 스토리 연출 씬
├── scripts/
│   ├── autoload/         # GameManager, SaveManager, SoundManager, PoolManager
│   ├── player/           # 플레이어 컨트롤러, 스테이터스
│   ├── enemy/            # 적 AI, 스포너
│   ├── item/             # 아이템 및 장비 슬롯 로직
│   ├── skill/            # 스킬 발동 및 스킬 트리 로직
│   └── story/            # 스토리 컷신 연출 컨트롤러
├── export_presets.cfg
└── project.godot
```

### 핵심 시스템 아키텍처

| 시스템 | 파일 | 주요 역할 |
|--------|------|----------|
| 전역 게임 매니저 | `scripts/autoload/game_manager.gd` | GameState 관리, 상태 전환 |
| 스토리 연출 | `scripts/story/story_director.gd` | 쿼터뷰 자동 이동 + 다이얼로그 시퀀스 |
| 장비 관리 | `scripts/item/equipment_manager.gd` | 8슬롯 장착, 양손/방패 제약 |
| 오브젝트 풀링 | `scripts/autoload/pool_manager.gd` | 인스턴스화 부하 감소 |
| 세이브 관리 | `scripts/autoload/save_manager.gd` | JSON 직렬화 저장/로드 |

### 모바일 필수 사항
- VirtualJoystick: 화면 터치 드래그 이동
- Viewport: 1280×720 가로, `stretch/mode="canvas_items"`, `stretch/aspect="keep"`
- 세이브 위치: `user://save_data.json`
