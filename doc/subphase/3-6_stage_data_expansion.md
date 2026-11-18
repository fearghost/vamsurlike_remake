# Sub-Phase 3-6: 스테이지 데이터 확장

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: 창세기전 2 스토리에 맞춘 스테이지, 몬스터, 드랍 테이블 작성

---

## 3.6.1 창세기전 2 세계관 스테이지 설계

### 작업 내용
- 창세기전 2의 스토리 라인을 반영한 스테이지 구성 설계
- 각 스테이지별 몬스터 구성, 보스, 보상 정의

### 스테이지 구성안 (예시)

| Stage ID | Chapter | Stage Name | 설명 | 보스 |
|----------|---------|-----------|------|------|
| `s01_01` | 1 | 격투의 시작 | 전초기지 전투 | chase_01 대장 |
| `s01_02` | 1 | 저격수의 눈 | 관측소 점령 | ranged_01 정예병 |
| `s01_03` | 1 | 돌진하는 군단 | 메인 게이트 돌파 | charge_01 기갑대 |
| `s02_01` | 2 | 어둠의 심연 | 지하 감옥 탈출 | elite_chase × 2 |
| `s02_02` | 2 | 파괴의 함성 | 무기고 점거 | elite_ranged × 3 |
| `s03_01` | 3 | 최후의 저항 | 본부 돌격 | boss_01 최종보스 |

### 완료 기준
- [ ] 스테이지 설계안이 문서화됨 (이 문서 또는 별도)
- [ ] 최소 6개 스테이지의 StageData Resource 생성됨

---

## 3.6.2 StageData Resource 작성

### 작업 내용
- 각 스테이지별로 StageData `.tres` 파일 생성
- 웨이브 구성, 보스, 보상, 스토리 스크립트 경로 지정

### StageData 예시 (s01_01)

```
stage_id: "s01_01"
chapter_number: 1
stage_number: 1
stage_name: "격투의 시작"
description: "전초기지에서의 첫 전투"

waves: [
    {
        enemies: [{"enemy_id": "chase_01", "count": 5}],
        spawn_interval: 1.0
    },
    {
        enemies: [{"enemy_id": "chase_01", "count": 3}, {"enemy_id": "ranged_01", "count": 2}],
        spawn_interval: 0.8
    }
]

boss_enemy_id: ""
boss_spawn_wave: -1

reward_gold: 100
reward_exp: 50
reward_items: [{"item_id": "steel_helm", "qty": 1}]

story_script_path: "res://data/stages/story_stage_01_01.json"
post_combat_dialogue: [
    {"speaker": "G.S", "text": "전초기지는 확보했다. 하지만 시작에 불과하다."}
]
```

### 완료 기준
- [ ] `data/stages/` 폴더에 StageData `.tres` 파일이 스테이지 수만큼 생성됨
- [ ] 각 파일의 waves, boss, rewards, story_script_path가 실제 데이터와 일치
- [ ] DataLoader.load_stages()로 모든 스테이지 로드 확인

---

## 3.6.3 몬스터 데이터 확장

### 작업 내용
- 더미 3종 → 창세기전 2 컨셉의 실제 몬스터 데이터로 교체/확장
- elite/boss 타입 추가

### 몬스터 데이터 확장안

| enemy_id | 이름 | 타입 | ai_pattern | hp | attack | defense | speed |
|----------|------|------|-----------|-----|--------|---------|-------|
| `grunt_01` | 일반 보병 | normal | chase | 60 | 8 | 3 | 85 |
| `sniper_01` | 저격수 | normal | ranged | 35 | 15 | 1 | 40 |
| `tank_01` | 기갑 보병 | normal | charge | 120 | 18 | 10 | 130 |
| `elite_grunt` | 정예 보병 | elite | chase | 150 | 15 | 8 | 90 |
| `elite_sniper` | 정예 저격수 | elite | ranged | 80 | 25 | 3 | 45 |
| `boss_commander` | 지휘관 보스 | boss | charge+ranged | 500 | 30 | 15 | 100 |

### 완료 기준
- [ ] 최소 6종 몬스터 데이터 생성 (normal 3 + elite 2 + boss 1)
- [ ] 각 데이터에 sprite_sheet_path, drop_table, exp_reward 설정됨
- [ ] DataLoader.load_enemies()로 모든 몬스터 로드 확인

---

## 3.6.4 아이템/장비 데이터 확장

### 작업 내용
- 부위별 장비 아이템 데이터 생성
- 창세기전 2 컨셉의 무기/갑옷/방패 등

### 아이템 데이터 예시

| item_id | 이름 | 타입 | stat_bonus | is_two_handed |
|---------|------|------|-----------|---------------|
| `steel_helm` | 강철 투구 | HELMET | {"hp": 20, "defense": 5} | false |
| `iron_shield` | 철방패 | SHIELD | {"defense": 8, "max_hp": 10} | false |
| `plate_armor` | 플레이트 갑옷 | ARMOR | {"max_hp": 50, "defense": 10} | false |
| `longsword` | 장검 | WEAPON | {"attack": 15} | false |
| `greatsword` | 대검 | WEAPON | {"attack": 25} | true |
| `steel_boots` | 강철 구두 | BOOTS | {"speed": 20, "defense": 3} | false |
| `ring_might` | 힘의 반지 | RING_1 | {"attack": 8} | false |
| `amulet_life` | 생명 목걸이 | NECKLACE | {"max_hp": 30} | false |

### 완료 기준
- [ ] 8개 슬롯 타입별 아이템 최소 1종 이상 생성됨
- [ ] greatsword 등 양손 무기 is_two_handed = true 설정 확인
- [ ] DataLoader.load_items()로 모든 아이템 로드 확인

---

## Sub-Phase 3-6 완료 체크리스트

- [ ] 창세기전 2 컨셉 스테이지 설계안 작성 완료
- [ ] StageData Resource 파일 6개 이상 생성 완료
- [ ] 몬스터 데이터 6종 이상 생성 완료 (normal/elie/boss)
- [ ] 아이템/장비 데이터 8종 이상 생성 완료 (부위별)
- [ ] DataLoader가 모든 스테이지/몬스터/아이템 정상 로드 확인
- [ ] WaveManager가 실제 StageData로 웨이브 진행 확인
