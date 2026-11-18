# Sub-Phase 3-7: 스킬 효과 완성 + 장비 효과 완성

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: 더미 → 실제 스킬 효과 (데미지/버프/데버프) + 장비 보너스 계산 완성

---

## 3.7.1 스킬 효과 완성

### 작업 내용
- SkillExecutor의 effect_type별 실제 효과 적용 구현
- 데미지, 힐, 버프, 데버프 등 모듈화

### 효과 타입별 구현 스펙

| EffectType | 구현 로직 | 파라미터 예시 |
|------------|----------|--------------|
| **DAMAGE** | `target.take_damage(base_damage * scaling_factor)` | `{"base_damage": 20, "scaling": "attack", "hit_count": 1}` |
| **HEAL** | `target.heal(base_heal + max_hp * percent)` | `{"base_heal": 30, "scaling": "max_hp", "percent": 0.3}` |
| **BUFF** | `target.apply_buff(stat, bonus, duration)` → Timer 기반 지속 | `{"stat": "attack", "bonus": 10, "duration": 10.0}` |
| **DEBUFF** | `target.apply_debuff(stat, reduction_ratio, duration)` | `{"stat": "speed", "reduction": 0.2, "duration": 5.0}` |

### SkillExecutor 수정 스펙

```
SkillExecutor (수정):
├── apply_effect(effect_type, params, target):
│   ├── if effect_type == DAMAGE:
│   │   ├── scaling_factor = get_scaling_factor(params.scaling)
│   │   ├── actual_damage = params.base_damage * scaling_factor
│   │   ├── target.take_damage(actual_damage * params.hit_count)
│   │   └── play_sfx("sword_slash")
│   ├── if effect_type == HEAL:
│   │   ├── max_hp = target.get_max_hp()
│   │   ├── heal_amount = params.base_heal + (max_hp * params.percent)
│   │   ├── target.heal(heal_amount)
│   │   └── play_sfx("level_up")
│   ├── if effect_type == BUFF:
│   │   ├── target.apply_buff(params.stat, params.bonus, params.duration)
│   │   └── Timer 생성 → duration 후 buff 제거
│   └── if effect_type == DEBUFF:
│       ├── target.apply_debuff(params.stat, params.reduction, params.duration)
│       └── Timer 생성 → duration 후 debuff 제거
```

### 완료 기준
- [ ] SkillExecutor가 DAMAGE/HEAL/BUFF/DEBUFF 효과 모두 적용
- [ ] DAMAGE: 타겟 HP 감소 확인 (방어력 적용 전/후)
- [ ] HEAL: 타겟 HP 회복 확인 (최대치 초과 없음)
- [ ] BUFF: stat 보너스 duration 동안 유지 확인
- [ ] DEBUFF: stat 감소 ratio duration 동안 유지 확인
- [ ] Timer 기반 buff/debuff 자동 해제 확인

---

## 3.7.2 장비 효과 완성

### 작업 내용
- EquipmentManager의 stat_bonus가 실제 스탯에 반영되도록 완성
- StatCalculator가 모든 장착 슬롯의 보너스 합산

### StatCalculator 완성 스펙

```
StatCalculator (완성):
├── calculate_stats(base_stats, equipped_items):
│   ├── final_stats = base_stats 복사
│   ├── for each slot in equipped_items:
│   │   ├── item = equipped_items[slot]
│   │   ├── if item != null:
│   │   │   ├── for stat_name in item.stat_bonus:
│   │   │   │   ├── final_stats[stat_name] += item.stat_bonus[stat_name]
│   │   │   └── if item.has_method("special_effect"):
│   │   │       └── apply_special_effect(item)
│   └── return final_stats

PlayerController (수정):
├── _on_equipment_changed():
│   ├── var new_stats = StatCalculator.calculate_stats(base_stats, equipped_items)
│   ├── move_speed = new_stats.get("speed", 200.0)
│   ├── current_hp = new_stats.get("hp", 100)  # 최대 HP 변경 시 처리
│   └── PlayerHud.update_stats(new_stats)
```

### 동작 스펙
1. **장비 장착 시**: `equipment_changed` 시그널 수신 → `StatCalculator.calculate_stats()` 재계산
2. **스탯 반영**: 계산된 최종 스탯을 PlayerController에 적용 (이동 속도, HP 등)
3. **HUD 갱신**: `PlayerHud.update_stats()` 호출 → 표시 값 업데이트
4. **장비 해제 시**:同上 → 재계산 + 적용

### 완료 기준
- [ ] StatCalculator가 모든 장착 슬롯의 stat_bonus 합산 정확히 계산
- [ ] 장비 장착/해제 시 최종 스탯이 실시간으로 갱신됨
- [ ] HUD에 표시되는 스탯이 실제 계산값과 일치
- [ ] 이동 속도가 장비 보너스에 따라 변경됨 확인
- [ ] HP/공격력/방어력 보너스가 전투에 반영됨 확인

---

## Sub-Phase 3-7 완료 체크리스트

- [ ] SkillExecutor가 DAMAGE/HEAL/BUFF/DEBUFF 효과 모두 실제 적용 확인 완료
- [ ] Timer 기반 buff/debuff 지속 + 자동 해제 확인 완료
- [ ] StatCalculator가 모든 장비 보너스 합산 정확히 계산 확인 완료
- [ ] 장비 장착/해제 시 스탯 실시간 갱신 확인 완료
- [ ] HUD 스탯 표시가 실제 계산값과 일치 확인 완료
