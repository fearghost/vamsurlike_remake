# Sub-Phase 3-8: 파티클/이펙트 추가

> Parent Phase: Phase 3 — Content & Asset Integration
> 목표: 피격, 사망, 스킬 발사 이펙트 추가

---

## 3.8.1 파티클 시스템 설계

### 작업 내용
- Godot GPUParticles2D 기반 이펙트 시스템 구축
- 공통 파티클 프리셋 생성 → PoolManager로 관리

### 파티클 타입 정의

| 이펙트 타입 | 사용 시점 | 파티클 효과 | 색상 |
|------------|----------|------------|------|
| **hit_spark** | 피격 시 | 작은 점멸 파티클 5~10개 산산히 흩어짐 | 흰색/노란색 |
| **death_dissolve** | 사망 시 | 파티클로 분해되며 사라지는 효과 | 회색/검은색 |
| **projectile_trail** | 투사체 이동 중 | 뒤따르는 꼬리 이펙트 | 적: 붉은색, 청: 푸른색 |
| **skill_fireball** | 화염 스킬 발사 | 불꽃 파티클 전방으로 발사 | 주황/빨강 |
| **skill_heal** | 힐 스킬 적용 | 빛나는 입자가 위로 상승 | 초록/흰색 |
| **gold_drop** | 경험치/골드 드랍 | 반짝이는 보석 이펙트 | 금색 |

### 파티클 프리셋 구조

```
ParticlePresets (Node2D - autoload 또는 DataLoader 관리):
├── hit_spark: GPUParticles2D 프리셋
│   ├── emission_shape: Point
│   ├── amount: 8
│   ├── lifetime: 0.3초
│   ├── initial_velocity_min/max: 50/150
│   └── texture: res://assets/particles/spark.png
├── death_dissolve: GPUParticles2D 프리셋
│   ├── emission_shape: Point
│   ├── amount: 20
│   ├── lifetime: 0.8초
│   ├── initial_velocity_min/max: 30/100
│   └── texture: res://assets/particles/dust.png
├── projectile_trail: GPUParticles2D 프리셋
│   ├── emission_shape: Point
│   ├── amount: 3
│   ├── lifetime: 0.15초
│   └── texture: res://assets/particles/trail.png
└── ... (其餘 이펙트)
```

### 완료 기준
- [ ] `assets/particles/` 폴더에 파티클 텍스처 생성/배치됨
- [ ] 6개 파티클 타입의 GPUParticles2D 프리셋 생성됨
- [ ] PoolManager로 파티클 노드 관리 가능

---

## 3.8.2 이펙트 적용 연동

### 작업 내용
- 각 시스템(데미지, 사망, 스킬, 드랍)에 파티클 이펙트 연결

### 연동 스펙

```
PlayerStats (수정):
├── take_damage(amount):
│   ├── ... 기존 로직 ...
│   └── ParticleSpawner.spawn("hit_spark", position)

EnemyAI (수정):
├── _on_died():
│   ├── ... 기존 로직 ...
│   └── ParticleSpawner.spawn("death_dissolve", position)

Projectile (수정):
├── _process(delta):
│   ├── ... 기존 이동 로직 ...
│   └── ParticleSpawner.spawn("projectile_trail", position)

SkillExecutor (수정):
├── apply_effect(effect_type, params, target):
│   ├── if effect_type == DAMAGE and params.has("element"):
│   │   ├── if params.element == "fire":
│   │   │   └── ParticleSpawner.spawn("skill_fireball", target.position)
│   ├── if effect_type == HEAL:
│   │   └── ParticleSpawner.spawn("skill_heal", target.position)

WaveManager (수정):
├── on_enemy_died():
│   ├── ... 기존 로직 ...
│   └── if enemy_data.exp_reward > 0:
│       └── ParticleSpawner.spawn("gold_drop", position)
```

### ParticleSpawner 헬퍼 클래스

```
class_name ParticleSpawner
extends Node

var particle_pool: ObjectPool

func spawn(effect_name: String, position: Vector2) -> void:
    var particle = particle_pool.acquire(effect_name)
    particle.position = position
    particle.emitting = true
    particle.one_shot = true
    # emitting이 끝나면 자동으로 pool로 반환

func _on_particle_finished(particle: GPUParticles2D) -> void:
    particle_pool.release(effect_name, particle)
```

### 완료 기준
- [ ] `particle_spawner.gd`가 생성됨 + PoolManager 연동 확인
- [ ] hit_spark: 피격 시 파티클 표시 확인
- [ ] death_dissolve: 사망 시 분해 이펙트 확인
- [ ] projectile_trail: 투사체 이동 중 꼬리 이펙트 확인
- [ ] skill_fireball/heal: 스킬 발사/힐 시 이펙트 확인
- [ ] gold_drop: 경험치 드랍 시 반짝이 이펙트 확인
- [ ] 모든 파티클이 PoolManager로 재사용됨 (메모리 누수 없음)

---

## Sub-Phase 3-8 완료 체크리스트

- [ ] 파티클 텍스처 생성/배치 완료 (`assets/particles/`)
- [ ] 6개 이펙트 타입의 GPUParticles2D 프리셋 생성 완료
- [ ] `particle_spawner.gd` 생성 + PoolManager 연동 완료
- [ ] hit_spark / death_dissolve / projectile_trail 적용 확인 완료
- [ ] skill_fireball / skill_heal / gold_drop 적용 확인 완료
- [ ] 파티클 재사용 (풀링) 확인 + 메모리 누수 없음 확인
