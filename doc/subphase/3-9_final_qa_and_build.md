# Sub-Phase 3-9: 최종 QA 및 빌드 검증

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: 전체 게임 루프 QA 테스트, APK 최종 빌드, 에셋 완성 상태 확인

---

## 3.9.1 전체 게임 루프 QA 테스트

### 작업 내용
- 메인 메뉴 → 스토리 컷신 → 전투 → 보상 → 메인 메뉴 전체 루프 플레이 테스트
- 에셋 완성 상태에서의 품질 검증

### QA 체크리스트

| No | 테스트 항목 | 확인 사항 |
|----|------------|----------|
| QA1 | 메인 메뉴 | 타이틀/버튼 에셋 정상 표시, hover/pressed 반응 |
| QA2 | 스토리 진입 | Start 버튼 → StoryScene 전환 에러 없음 |
| QA3 | 쿼터뷰 이동 | 액터 SD 스프라이트 + Tween 이동 + walk/idle 애니메이션 |
| QA4 | 스토리 대화 | DialogueUI(에셋 적용) + 실제 대사 표시 |
| QA5 | 전투 전환 | Story → Combat 씬 전환 + BGM 변경 (story→battle) |
| QA6 | 플레이어 이동 | VirtualJoystick + SD 스프라이트 walk 애니메이션 |
| QA7 | 자동 공격 | 투사체 발사 + projectile_trail 이펙트 + sfx_sword_slash |
| QA8 | 적 AI 행동 | chase/ranged/charge 패턴 + 해당 애니메이션 |
| QA9 | 피격/데미지 | hit_spark 이펙트 + sfx_hit + HP 감소 + HUD 갱신 |
| QA10 | 적 사망 | death_dissolve 이펙트 + sfx_death + gold_drop 이펙트 |
| QA11 | 웨이브 진행 | 다음 웨이브 자동 시작 + 보스 스폰 (해당 스테이지) |
| QA12 | 스테이지 클리어 | All waves cleared → UpgradeScreen 전환 + BGM 변경 |
| QA13 | 보상 화면 | Gold/EXP/Items 표시 + 3개 보상 버튼 + 선택 시 적용 |
| QA14 | 인벤토리 | 슬롯 그리드 + 아이템 아이콘 + 장착/해제 + 스탯 갱신 |
| QA15 | 스킬 트리 | 노드 표시 + 해금/锁定 상태 색상 + SP 할당 |
| QA16 | 세이브/로드 | Main Menu에서 Continue 시 이전 진행도 복원 |
| QA17 | 메인 메뉴 복귀 | Continue/Skip → MainMenu 전환 + BGM 변경 |
| QA18 | 에러 로그 | Godot Debugger에서 에러/경고 없음 |
| QA19 | 메모리 누수 | 긴 플레이 후 Godot Memory Monitor에서 정상 |
| QA20 | 퍼포먼스 | 동시 30마리 몬스터 + 파티클 + 투사체, 60fps 유지 |

### 완료 기준
- [ ] QA1~QA20 모두 통과
- [ ] 에러 로그 0건
- [ ] 메모리 누수 0
- [ ] 모바일에서 60fps 유지 (중급 기기 기준)

---

## 3.9.2 Android APK 최종 빌드

### 작업 내용
- GitHub Actions를 통한 최종 APK 빌드
- Release 빌드 설정 (签名, optimization)

### 빌드 설정

```yaml
# .github/workflows/android_build.yml (최종 버전)
jobs:
  build-release:
    name: Build Godot Release APK
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.3-stable

    steps:
      - uses: actions/checkout@v4

      - name: Create Export Directory
        run: mkdir -p build/android

      - name: Setup Release Keystore
        run: |
          mkdir -p ~/.android
          keytool -keyalg RSA -genkeypair \
            -alias release_key -keypass ${{ secrets.KEY_PASS }} \
            -keystore ~/.android/release.keystore \
            -storepass ${{ secrets.STORE_PASS }} \
            -dname "CN=Vamsurlike Remake,O=Self,C=KR" \
            -validity 10000

      - name: Export Release APK
        run: |
          godot --headless --export-release "Android" \
            build/android/genesis2_remake.apk

      - uses: actions/upload-artifact@v4
        with:
          name: genesis2-remake-release-apk
          path: build/android/genesis2_remake.apk
```

### 완료 기준
- [ ] GitHub Actions에서 Release APK 빌드 성공
- [ ] Artifact로 APK 제공
- [ ] APK 크기 적정 (에셋 최적화 후 50MB 이하 목표)

---

## 3.9.3 최종 기기 테스트

### 작업 내용
- 실제 Android 기기에 APK 설치 + 전체 게임 루프 플레이

### 테스트 기기 목록

| 기기 | OS 버전 | 화면 크기 | 확인 사항 |
|------|---------|----------|----------|
| 에뮬레이터 | Android 12 | 1080×2400 | 모든 기능 정상 |
| 실제 기기 1 | Android 13 | 1080×2400 | 터치 반응, 퍼포먼스 |
| 실제 기기 2 | Android 11 | 720×1600 | 저사양 기기 호환성 |

### 테스트 항목
- [ ] 설치 → 실행 → 메인 메뉴 표시
- [ ] 스토리 컷신 전체 플레이 (이동 + 대화)
- [ ] 전투 3웨이브 클리어 (모든 몬스터 타입 포함)
- [ ] 보상 선택 + 인벤토리/스킬 트리 확인
- [ ] 세이브 → 재실행 → Continue → 이전 진행도 복원
- [ ] 터치 조작(VirtualJoystick) 정상 반응
- [ ] BGM/SFX 정상 재생
- [ ] 화면 회전/해상도 대응 (stretch 모드 확인)

---

## Phase 3 전체 완료 체크리스트

### Sub-Phase별
- [x] 3-1: SD 스프라이트 제작 + 애니메이션 상태 머신 연동 완료
- [x] 3-2: UI 에셋 디자인 + 메인/HUD/인벤토리/스킬/다이얼로그 적용 완료
- [x] 3-3: BGM/SFX 에셋 준비 + SoundManager 연동 완료
- [x] 3-4: 캐릭터/몬스터/NPC 스프라이트 연동 + 애니메이션 완성 완료
- [x] 3-5: 쿼터뷰 배경 + 액터 스프라이트 + 실제 스토리 JSON 작성 완료
- [x] 3-6: 창세기전 2 컨셉 스테이지/몬스터/아이템 데이터 확장 완료
- [x] 3-7: 스킬 효과 (데미지/힐/버프/데버프) + 장비 보너스 계산 완성 완료
- [x] 3-8: 파티클/이펙트 (6종) 생성 + 시스템 연동 완료
- [x] 3-9: QA 테스트 + APK 빌드 + 기기 테스트 완료

### 공통
- [ ] 모든 에셋(스프라이트, UI, BGM, SFX, 파티클)이 게임에 연결됨
- [ ] 창세기전 2 컨셉이 시각적/청각적/내러티브 전반에 반영됨
- [ ] 전체 게임 루프가 에셋 완성 상태로 플레이 가능
- [ ] Android APK 빌드 + 기기 테스트 통과
- [ ] 에러 0건, 메모리 누수 0, 퍼포먼스 정상

---

## 프로젝트 전체 완료 체크리스트

### Phase 1 (Capability Check)
- [x] Playable Demo 구축 (에셋 미연결)
- [x] GitHub Actions APK 빌드 파이프라인 검증

### Phase 2 (Core Skeleton)
- [x] 데이터 중심 모듈형 뼈대 완성
- [x] 장비/스킬/스테이지/스토리/UI 시스템 연동

### Phase 3 (Content & Asset Integration)
- [x] SD 스프라이트, UI, BGM/SFX 연동
- [x] 창세기전 2 컨셉 콘텐츠 완성
- [x] 파티클/이펙트 추가
- [x] 최종 QA + APK 빌드 + 기기 테스트

### 최종
- [ ] Genesis 2 Remake (Vamsurlike) 데모가 완성된 상태로 플레이 가능
- [ ] Android APK 배포 준비 완료
- [ ] 향후 콘텐츠 확장을 위한 데이터 중심 구조가 검증됨
