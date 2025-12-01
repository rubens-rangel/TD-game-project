# 🔧 Proposta de Implementação - Balanceamento

## 📋 Mudanças Propostas

Este documento detalha as mudanças específicas recomendadas para melhorar o balanceamento do jogo.

---

## 1️⃣ Escalar Recompensas de Moedas

### Problema
Recompensas fixas (2 moedas) não acompanham crescimento exponencial de dificuldade.

### Solução
Implementar escala de recompensas baseada em wave.

### Código Proposto

**Constants.gd:**
```gdscript
# Coin rewards scaling
const REWARD_SCALE := 1.05  # Crescimento mais lento que wave scale
const NORMAL_REWARD_BASE := 2
const BOSS_REWARD_MULTIPLIER := 20
```

**Game.gd ou WaveManager.gd:**
```gdscript
func get_enemy_reward() -> int:
    """Calcula recompensa de inimigo normal baseada na wave atual"""
    var scale = pow(GameConstants.REWARD_SCALE, max(0, wave_manager.wave - 1))
    return int(GameConstants.NORMAL_REWARD_BASE * scale)

func get_boss_reward() -> int:
    """Calcula recompensa de boss baseada na wave atual"""
    return get_enemy_reward() * GameConstants.BOSS_REWARD_MULTIPLIER
```

### Impacto

| Wave | Recompensa Antiga | Recompensa Nova | Diferença |
|------|-------------------|-----------------|-----------|
| 1    | 2                 | 2               | 0%        |
| 10   | 2                 | 3               | +50%      |
| 25   | 2                 | 7               | +250%     |
| 50   | 2                 | 21              | +950%     |
| 100  | 2                 | 258             | +12,800%  |

### Localização no Código
- **Onde:** Onde recompensas são dadas ao matar inimigos
- **Arquivo:** `Game.gd` ou `EnemyManager.gd`
- **Buscar:** `NORMAL_REWARD`, `BOSS_REWARD_MULTIPLIER`, `hero["coins"] +=`

---

## 2️⃣ Custos Progressivos de Upgrades

### Problema
Upgrades com custo fixo ficam trivialmente baratos em waves altas.

### Solução
Implementar custo exponencial baseado no nível do upgrade.

### Código Proposto

**Constants.gd:**
```gdscript
# Upgrade cost scaling
const UPGRADE_COST_MULTIPLIER := 1.15  # 15% de aumento por nível
```

**Game.gd - Nova função:**
```gdscript
func get_upgrade_cost(base_cost: int, current_level: int) -> int:
    """Calcula custo de upgrade com escala progressiva"""
    return int(base_cost * pow(GameConstants.UPGRADE_COST_MULTIPLIER, current_level))
```

### Modificações Necessárias

**Torre Normal - Alcance:**
```gdscript
# ANTES:
var cost = GameConstants.TOWER_RANGE_COST

# DEPOIS:
var level = t.levels.get("RANGE", 0)
var cost = get_upgrade_cost(GameConstants.TOWER_RANGE_COST, level)
```

**Torre Normal - Cadência:**
```gdscript
# ANTES:
var cost = GameConstants.TOWER_RATE_COST

# DEPOIS:
var level = t.levels.get("RATE", 0)
var cost = get_upgrade_cost(GameConstants.TOWER_RATE_COST, level)
```

### Impacto

| Nível | Custo Antigo | Custo Novo | Diferença |
|-------|--------------|------------|-----------|
| 1     | 8            | 9          | +12%      |
| 5     | 8            | 16         | +100%     |
| 10    | 8            | 32         | +300%     |
| 20    | 8            | 131        | +1,538%   |

### Localização no Código
- **Onde:** Todas as funções de upgrade de torres
- **Arquivos:** `Game.gd`
- **Buscar:** `TOWER_RANGE_COST`, `TOWER_RATE_COST`, `TOWER_DMG_COST`, etc.

---

## 3️⃣ Ajustar Wave Scale

### Problema
Wave scale de 1.08 é muito agressivo, tornando waves altas impossíveis.

### Solução
Reduzir wave scale para valor mais conservador.

### Código Proposto

**Constants.gd:**
```gdscript
# ANTES:
const WAVE_SCALE := 1.08

# DEPOIS (Opção 1 - Mais Conservador):
const WAVE_SCALE := 1.05

# DEPOIS (Opção 2 - Híbrido):
const WAVE_SCALE_HP := 1.06      # HP cresce 6%
const WAVE_SCALE_SPEED := 1.04   # Velocidade cresce 4%
```

**WaveManager.gd:**
```gdscript
# Se usar opção híbrida:
func wave_factor_hp() -> float:
    return pow(GameConstants.WAVE_SCALE_HP, max(0, wave - 1))

func wave_factor_speed() -> float:
    return pow(GameConstants.WAVE_SCALE_SPEED, max(0, wave - 1))
```

**EnemyManager.gd ou Game.gd:**
```gdscript
# HP usa wave_factor_hp()
var f_hp = wave_manager.wave_factor_hp()
var hp = int(max(1, round(GameConstants.ENEMY_BASE_HP * f_hp)))

# Speed usa wave_factor_speed()
var f_speed = wave_manager.wave_factor_speed()
var speed = GameConstants.ENEMY_BASE_SPEED * f_speed
```

### Impacto

| Wave | HP Antigo (1.08) | HP Novo (1.05) | Diferença |
|------|------------------|----------------|-----------|
| 10   | 4                | 3              | -25%      |
| 25   | 13               | 7              | -46%      |
| 50   | 87               | 21             | -76%      |
| 100  | 4,079            | 130            | -97%      |

### Localização no Código
- **Onde:** `Constants.gd` linha 95
- **Onde:** `WaveManager.gd` linha 25

---

## 4️⃣ Bonus de Completion de Wave

### Problema
Falta recompensa adicional por completar wave, especialmente em waves altas.

### Solução
Adicionar bonus fixo que escala com wave.

### Código Proposto

**Constants.gd:**
```gdscript
# Wave completion bonus
const WAVE_COMPLETION_BONUS_BASE := 10
const WAVE_COMPLETION_BONUS_PER_WAVE := 2
```

**Game.gd - Após completar wave:**
```gdscript
func _on_wave_completed():
    var bonus = GameConstants.WAVE_COMPLETION_BONUS_BASE + (wave_manager.wave * GameConstants.WAVE_COMPLETION_BONUS_PER_WAVE)
    hero["coins"] += bonus
    _track_coin_collected(bonus)
    # Mostrar mensagem de bonus
```

### Impacto

| Wave | Bonus |
|------|-------|
| 1    | +12   |
| 10   | +30   |
| 25   | +60   |
| 50   | +110  |
| 100  | +210  |

### Localização no Código
- **Onde:** Função que detecta fim de wave
- **Arquivo:** `Game.gd`
- **Buscar:** `wave_ended`, `enemies.is_empty()`, fim de wave

---

## 5️⃣ Sistema de Upgrades Percentuais (Opcional)

### Problema
Upgrades absolutos não escalam bem a longo prazo.

### Solução
Implementar upgrades percentuais para fire rate.

### Código Proposto

**Constants.gd:**
```gdscript
# Percentual upgrade values
const FIRE_RATE_REDUCTION_PERCENT := 0.08  # 8% mais rápido por upgrade
```

**Game.gd:**
```gdscript
# ANTES (absoluto):
t.fire_rate = max(0.1, t.fire_rate - 0.05)

# DEPOIS (percentual):
var reduction = t.fire_rate * GameConstants.FIRE_RATE_REDUCTION_PERCENT
t.fire_rate = max(0.1, t.fire_rate - reduction)
```

### Impacto
- Melhorias mais consistentes
- Melhor escalonamento a longo prazo
- Evita chegar muito rápido ao mínimo

---

## 📝 Checklist de Implementação

### Fase 1: Análise (✅ Completo)
- [x] Documentar sistema atual
- [x] Identificar problemas
- [x] Criar propostas de solução

### Fase 2: Implementação Básica
- [ ] Implementar escala de recompensas (#1)
- [ ] Implementar custos progressivos (#2)
- [ ] Testar mudanças básicas

### Fase 3: Ajustes de Dificuldade
- [ ] Ajustar wave scale (#3)
- [ ] Implementar bonus de completion (#4)
- [ ] Testar balanceamento

### Fase 4: Melhorias Opcionais
- [ ] Implementar upgrades percentuais (#5)
- [ ] Ajustes finos baseados em teste
- [ ] Documentar mudanças

---

## 🧪 Testes Recomendados

### Teste 1: Progression Natural
1. Jogar waves 1-25
2. Anotar dificuldade percebida
3. Verificar se recursos são suficientes
4. Verificar se upgrades são acessíveis mas não triviais

### Teste 2: Waves Médias
1. Jogar waves 26-50
2. Verificar se ainda são viáveis
3. Verificar se recursos acompanham dificuldade
4. Verificar se upgrades são necessários

### Teste 3: Waves Altas
1. Jogar waves 51-75
2. Verificar se são possíveis
3. Verificar balanceamento final
4. Verificar se há necessidade de ajustes

---

## 📊 Comparação Antes/Depois

### Cenário: Wave 50

**ANTES:**
- HP Total: 11,795
- Recompensa Total: ~346 moedas
- Custo de Upgrade: 8 moedas (fixo)
- DPS Necessário: ~50 DPS
- Tempo para Matar: 3.9 minutos

**DEPOIS (com todas mudanças):**
- HP Total: ~2,940 (com wave scale 1.05)
- Recompensa Total: ~2,100 moedas (com escala)
- Custo de Upgrade: 16-32 moedas (progressivo)
- DPS Necessário: ~12 DPS
- Tempo para Matar: 4 minutos (mas mais jogável)

### Análise
- HP reduzido em 75%
- Recursos aumentados em 506%
- Upgrades mais caros mas acessíveis
- Dificuldade mais balanceada

---

## 🔄 Plano de Rollback

Caso as mudanças causem problemas:

1. **Recompensas:** Manter escalonamento mas reduzir multiplicador (1.05 → 1.03)
2. **Custos:** Reduzir multiplicador (1.15 → 1.10)
3. **Wave Scale:** Ajustar gradualmente (1.08 → 1.06 → 1.05)
4. **Bonus:** Reduzir valores base

---

## 📚 Referências

- `BALANCE_ANALYSIS.md` - Análise completa
- `BALANCE_DETAILED_CALCULATIONS.md` - Cálculos detalhados
- `BALANCE_SUMMARY.md` - Resumo executivo

---

**Proposta criada em:** Baseada na análise completa do sistema
**Status:** ✅ Pronta para implementação



