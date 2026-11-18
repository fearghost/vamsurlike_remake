# Sub-Phase 3-3: BGM/SFX 에셋 연동

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: 전투 BGM, 스토리 BGM, 타격/이동/장착 SFX 연동

---

## 3.3.1 BGM 에셋 준비

### 작업 내용
- 전투용 BGM 1~2곡, 스토리용 BGM 1곡 준비
- Godot AudioStream 형식 (OGG 권장)

### BGM 스펙

|曲目 | 용도 | 길이 | 형식 | 파일명 예시 |
|-----|------|------|------|------------|
| **Battle Theme** | 전투 중 배경음악 | 2~3분 반복 | OGG, 192kbps | `bgm_battle.ogg` |
| **Story Theme** | 스토리 컷신 배경음악 | 1~2분 반복 | OGG, 192kbps | `bgm_story.ogg` |
| **Boss Theme** (선택) | 보스전 배경음악 | 2~3분 반복 | OGG, 192kbps | `bgm_boss.ogg` |

### Godot 설정
- `project.godot`의 `audio/effects/` 폴더에 BGM 파일 배치
- AudioStreamOGGVP 또는 AudioStreamMP3로 로드

### 완료 기준
- [ ] `assets/audio/bgm/` 폴더에 BGM 파일 배치됨
- [ ] Godot에서 OGG 파일이 AudioStream으로 정상 로드됨
- [ ] BGM 길이가 1분 이상 (반복 재생 적합)

---

## 3.3.2 SFX 에셋 준비

### 작업 내용
- 게임 내 효과음 5~8종 준비
- 짧은 파장 (0.1~0.5초), OGG 형식

### SFX 스펙

| SFX 이름 | 용도 | 길이 | 파일명 예시 |
|----------|------|------|------------|
| **sword_slash** | 공격 타격음 | 0.2초 | `sfx_sword_slash.ogg` |
| **hit** | 피격음 | 0.15초 | `sfx_hit.ogg` |
| **death** | 사망음 | 0.4초 | `sfx_death.ogg` |
| **equip** | 장비 착용음 | 0.2초 | `sfx_equip.ogg` |
| **unequip** | 장비 해제음 | 0.15초 | `sfx_unequip.ogg` |
| **level_up** | 레벨업/스킬 해금음 | 0.3초 | `sfx_level_up.ogg` |
| **ui_click** | UI 클릭음 | 0.05초 | `sfx_ui_click.ogg` |
| **step** | 이동 발소리 | 0.1초 | `sfx_step.ogg` |

### 완료 기준
- [ ] `assets/audio/sfx/` 폴더에 SFX 파일 배치됨
- [ ] Godot에서 모든 SFX가 정상 로드됨
- [ ] SFX 길이가 적절함 (너무 길지 않음)

---

## 3.3.3 SoundManager 연동

### 작업 내용
- SoundManager에서 실제 BGM/SFX 파일 경로 연동
- GameManager 상태에 따라 BGM 자동 전환

### 수정 사항

```
SoundManager (수정):
├── BGM 매핑:
│   ├── "battle" → res://assets/audio/bgm/bgm_battle.ogg
│   ├── "story" → res://assets/audio/bgm/bgm_story.ogg
│   └── "boss" → res://assets/audio/bgm/bgm_boss.ogg
├── SFX 매핑:
│   ├── "sword_slash" → res://assets/audio/sfx/sfx_sword_slash.ogg
│   ├── "hit" → res://assets/audio/sfx/sfx_hit.ogg
│   └── ... (전체 SFX 매핑)

GameManager 연동:
├── state_changed 시그널 수신
│   ├── MAIN_MENU → play_bgm("menu") (없으면 silence)
│   ├── STORY_SCENE → play_bgm("story")
│   ├── COMBAT → play_bgm("battle")
│   └── UPGRADE → stop_bgm() 또는 play_bgm("story")
```

### 동작 스펙
1. **GameManager 상태 전환 시**: `state_changed` 시그널 수신 → 해당 상태의 BGM 재생
2. **전투 시작 시**: `bgm_battle.ogg` 재생 (fade_in 2초)
3. **스토리 진입 시**: `bgm_story.ogg` 재생 (기존 BGM fade_out 1초 후)
4. **SFX 발동 시**: 해당 SFX 파일 경로에서 AudioStream 로드 → play_sfx() 호출

### 완료 기준
- [ ] SoundManager가 실제 BGM/SFX 파일 경로로 연동됨
- [ ] GameManager 상태 전환 시 BGM이 자동 전환됨
- [ ] 전투 중 BGM 재생 확인
- [ ] 스토리 컷신 진입 시 BGM 전환 확인
- [ ] 공격/피격/장착 등 SFX가 이벤트 시 정상 재생 확인
- [ ] 볼륨 조절, mute 기능이 실제 에셋에 적용됨

---

## Sub-Phase 3-3 완료 체크리스트

- [ ] BGM 에셋 2~3곡 준비 완료 (`assets/audio/bgm/`)
- [ ] SFX 에셋 5~8종 준비 완료 (`assets/audio/sfx/`)
- [ ] SoundManager가 실제 파일 경로로 연동됨
- [ ] GameManager 상태 전환 → BGM 자동 전환 확인
- [ ] 전투/스토리/SFX 모두 실제 사운드 재생 확인
- [ ] 볼륨/mute 기능 정상 작동 확인
