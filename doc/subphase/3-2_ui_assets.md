# Sub-Phase 3-2: UI 에셋 디자인 및 적용

> Parent Phase: Phase 3 — Content & Core Skeleton
> 목표: 메인 메뉴, HUD, 인벤토리, 스킬 트리, 스토리 다이얼로그 UI 테마 완성

---

## 3.2.1 UI 테마 디자인

### 작업 내용
- 창세기전 2 컨셉의 UI 테마 디자인 (다크 판타지 스타일)
- ColorRect 더미 → 실제 UI 그래픽 교체

### UI 구성 요소

| UI 요소 | 포함 컴포넌트 | 디자인 방향 |
|---------|--------------|------------|
| **메인 메뉴** | 타이틀, 버튼, 배경 | 다크 판타지, 금색 테두리, 고전적 폰트 |
| **HUD** | HP 바, MP 바, 스탯 라벨, 스테이지 표시 | 반투명 패널, 간결한 아이콘 |
| **인벤토리** | 슬롯 그리드, 아이템 아이콘, 스탯 패널 | 그리드 기반, 드래그 앤 드롭 |
| **스킬 트리** | 노드 연결선, 스킬 아이콘, SP 표시 | 트리 구조, 연결선 + 원형 노드 |
| **스토리 다이얼로그** | 배경 패널, 화자 라벨, 대사 텍스트, 계속 버튼 | 하단 반투명 패널, 세련된 테두리 |

### 디자인 스펙 (더미 → 실제)

| 항목 | 더미 (Phase 1/2) | 실제 (Phase 3) |
|------|------------------|---------------|
| 배경 | ColorRect 검은색 | `assets/ui/bg_dark.png` |
| 버튼 | ColorRect + Label | `assets/ui/button_*.png` (normal/hover/pressed) |
| HP 바 | TextureProgressBar (기본) | `assets/ui/hp_bar_bg.png` + `hp_bar_fill.png` |
| 슬롯 | ColorRect 사각형 | `assets/ui/slot_empty.png` + `slot_filled.png` |
| 다이얼로그 | ColorRect 하단 패널 | `assets/ui/dialogue_panel.png` |

### 완료 기준
- [ ] `assets/ui/` 폴더에 UI 에셋 생성/배치됨
- [ ] 메인 메뉴 배경 + 버튼 에셋 적용 확인
- [ ] HUD HP/MP 바 에셋 적용 확인
- [ ] 인벤토리 슬롯 아이콘 적용 확인
- [ ] 스킬 트리 노드/연결선 에셋 적용 확인
- [ ] 다이얼로그 패널 에셋 적용 확인

---

## 3.2.2 메인 메뉴 UI 적용 (`scenes/ui/main_menu.tscn` 수정)

### 작업 내용
- ColorRect 더미 → 실제 UI 그래픽으로 교체
- 버튼 hover/pressed 상태 에셋 적용

### 수정 사항

```
Before (더미):
├── Background: ColorRect (검은색)
├── TitleLabel: Label ("Genesis 2 Remake")
├── StartButton: Button (ColorRect 기반)
└── ContinueButton: Button (ColorRect 기반)

After (에셋 적용):
├── Background: TextureRect (res://assets/ui/bg_menu.png)
├── TitleLabel: Label (폰트/색상 조정)
├── StartButton: Button (normal/hover/pressed 스프라이트)
│   ├── normal: res://assets/ui/button_normal.png
│   ├── hover: res://assets/ui/button_hover.png
│   └── pressed: res://assets/ui/button_pressed.png
└── ContinueButton: Button (同上)
```

### 완료 기준
- [ ] 메인 메뉴 배경이 실제 UI 에셋으로 교체됨
- [ ] 버튼 hover/pressed 상태 에셋 적용 확인
- [ ] 타이틀 폰드가 창세기전 2 컨셉에 맞음

---

## 3.2.3 HUD UI 적용 (`scenes/ui/player_hud.tscn` 수정)

### 작업 내용
- HP 바, MP 바, 스탯 라벨에 실제 UI 에셋 적용

### 수정 사항

```
Before (더미):
├── HPBar: TextureProgressBar (기본)
└── StageLabel: Label ("Stage 1")

After (에셋 적용):
├── HPBarPanel: Panel (res://assets/ui/hp_panel.png)
│   ├── HPBar: TextureProgressBar
│   │   ├── fill_texture: res://assets/ui/hp_bar_fill.png
│   │   └── bg_texture: res://assets/ui/hp_bar_bg.png
│   └── MPBar: TextureProgressBar (同上, mp_bar_fill.png)
└── StageLabel: Label (UI 테마 폰트 적용)
```

### 완료 기준
- [ ] HP/MP 바가 실제 에셋으로 교체됨
- [ ] 바 채움 애니메이션이 부드럽게 동작
- [ ] 스탯 라벨이 UI 테마에 맞는 폰트/색상 적용

---

## 3.2.4 인벤토리/스킬트리/다이얼로그 UI 적용

### 작업 내용
- 인벤토리, 스킬 트리, 다이얼로그 UI에 실제 에셋 적용

### 완료 기준
- [ ] 인벤토리 슬롯이 실제 아이콘/배경 에셋으로 교체됨
- [ ] 스킬 트리 노드가 원형 아이콘 + 연결선 에셋으로 교체됨
- [ ] 다이얼로그 패널이 실제 배경/테두리 에셋으로 교체됨

---

## Sub-Phase 3-2 완료 체크리스트

- [ ] UI 테마 에셋 전체 제작 완료 (`assets/ui/`)
- [ ] 메인 메뉴 UI 에셋 적용 확인
- [ ] HUD UI 에셋 적용 확인
- [ ] 인벤토리 UI 에셋 적용 확인
- [ ] 스킬 트리 UI 에셋 적용 확인
- [ ] 스토리 다이얼로그 UI 에셋 적용 확인
- [ ] 모든 UI가 창세기전 2 컨셉의 다크 판타지 테마로 통일됨
