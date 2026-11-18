# Sub-Phase 1-1: 프로젝트 초기화 및 CI 구축

> Parent Phase: Phase 1 — Capability Check
> 목표: Godot 4.3 프로젝트 생성, 폴더 구조 정리, GitHub Actions APK 빌드 파이프라인 구축

---

## 1.1.1 `project.godot` 생성

### 작업 내용
- Godot 4.3 호환 프로젝트 설정 파일 작성
- 모바일 표준 해상도 및 stretch 모드 설정
- 기본 플러그인 설정

### 상세 스펙

| 항목 | 값 | 비고 |
|------|-----|------|
| `application/config/version` | `"1.0.0"` | 프로젝트 버전 |
| `display/width` | `1280` | 가로 해상도 |
| `display/height` | `720` | 세로 해상도 |
| `stretch/mode` | `"canvas_items"` | 캔버스 아이템 스케일링 |
| `stretch/aspect` | `"keep"` | 종횡비 유지 |
| `rendering/threads/thread_safety` | `"enabled"` | 스레드 안전성 |

### 완료 기준
- [ ] `project.godot` 파일이 Godot 4.3에서 오류 없이 열림
- [ ] Viewport가 1280×720으로 설정됨
- [ ] stretch/mode가 "canvas_items", stretch/aspect가 "keep"

---

## 1.1.2 `export_presets.cfg` 생성 (Android)

### 작업 내용
- Android Export 설정 파일 작성
- Debug 빌드용 키스토어 설정
- 필요한 Android 권한 설정

### 상세 스펙

| 항목 | 값 | 비고 |
|------|-----|------|
| `platform/name` | `"Android"` | 플랫폼명 |
| `apk/expansion/enable` | `false` | OBB 확장 파일 비활성화 |
| `keystore/debug/use` | `true` | 디버그 키스토어 사용 |
| `permissions/internet` | `true` | 인터넷 권한 (CI용) |

### 완료 기준
- [ ] Android Export Preset가 Godot Export Manager에 표시됨
- [ ] 디버그 키스토어 설정이 정상 적용됨

---

## 1.1.3 저장소 폴더 구조 생성

### 작업 내용
- 전체 디렉토리 트리를 물리적으로 생성
- 각 폴더의 purpose를 명시하는 `.gitkeep` 파일 추가 (선택)

### 생성할 디렉토리

```
assets/
├── sprites/          # 플레이어, 몬스터, NPC SD 스프라이트
├── ui/               # UI 테마 및 아이콘
└── audio/            # BGM 및 SFX

data/
├── characters/       # 플레이어블 캐릭터 데이터
├── enemies/          # 몬스터 데이터
├── items/            # 부위별 장비 아이템 데이터
├── skills/           # 스킬 및 스킬 트리 데이터
└── stages/           # 스테이지 및 스토리 스크립트 데이터

scenes/
├── common/           # 공용 컴포넌트 (Hitbox, Hurtbox, VirtualJoystick)
├── ui/               # 메인 메뉴, HUD, 인벤토리, 스킬트리 UI
├── game/             # 전투 씬 (플레이어, 적, 투사체, 파티클)
└── story/            # 쿼터뷰 스토리 연출 씬

scripts/
├── autoload/         # GameManager, SaveManager, SoundManager, PoolManager
├── player/           # 플레이어 컨트롤러, 스테이터스
├── enemy/            # 적 AI, 스포너
├── item/             # 아이템 및 장비 슬롯 로직
├── skill/            # 스킬 발동 및 스킬 트리 로직
└── story/            # 스토리 컷신 연출 컨트롤러

.github/
└── workflows/        # CI 워크플로우
```

### 완료 기준
- [ ] 모든 디렉토리가 실제 파일 시스템에 생성됨
- [ ] `godot` 명령어 또는 `ls`로 전체 구조 확인 가능

---

## 1.1.4 GitHub Actions 워크플로우 구축

### 작업 내용
- `.github/workflows/android_build.yml` 파일 생성
- Godot CI 컨테이너 기반 APK 빌드 파이프라인 구현

### 워크플로우 스펙

| 단계 | 내용 | 도구 |
|------|------|------|
| Trigger | `push`/`pull_request` (main/master), `workflow_dispatch` | GitHub Actions |
| Runner | `ubuntu-latest` + 컨테이너 `barichello/godot-ci:4.3-stable` | Docker |
| Keystore | `keytool`로 debug.keystore 자동 생성 | Shell |
| 빌드 | `godot --headless --export-debug "Android" build/android/vamsurlike_remake.apk` | Godot CLI |
| 업로드 | artifact `vamsurlike-remake-apk`로 APK 제공 | actions/upload-artifact@v4 |

### 완료 기준
- [ ] `.github/workflows/android_build.yml` 파일이 repo에 push됨
- [ ] GitHub Actions Run이 정상 시작됨 (Actions 탭 확인)
- [ | Build 단계가 에러 없이 통과됨
- [ ] Artifact로 APK가 제공됨 (다운로드 확인)

---

## Sub-Phase 1-1 완료 체크리스트

- [ ] `project.godot` 생성 및 설정 완료
- [ ] `export_presets.cfg` 생성 (Android Export Preset)
- [ ] 전체 폴더 구조 생성 완료
- [ ] GitHub Actions 워크플로우 push 완료
- [ ] 첫 번째 CI 빌드 성공 + APK artifact 다운로드 확인
- [ ] 데모 APK를 Android 기기/에뮬레이터에서 설치하고 실행해봄
