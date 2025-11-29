# 📊 Análise de Balanceamento - Escala de Crescimento

## 📋 Índice
1. [Sistema de Waves](#sistema-de-waves)
2. [Escala de Crescimento dos Monstros](#escala-de-crescimento-dos-monstros)
3. [Taxas de Disparo das Torres](#taxas-de-disparo-das-torres)
4. [Sistema de Upgrades](#sistema-de-upgrades)
5. [Análise de Progressão](#análise-de-progressão)
6. [Recomendações](#recomendações)

---

## 🌊 Sistema de Waves

### Fórmulas Base

**Wave Factor (Multiplicador de Wave)**
```
wave_factor(w) = WAVE_SCALE^(w-1)
onde WAVE_SCALE = 1.08
```

**Cálculo de Inimigos por Wave**
```
base = 6
plus_each = max(0, wave - 1)
bonus_five = 3 * floor((wave - 1) / 5)
total_enemies = base + plus_each + bonus_five
```

**Spawn Rate (Taxa de Spawn)**
```
spawn_rate = max(0.12, 0.5 - wave * 0.02)
```

**Ondas de Boss**
- A cada 5 ondas (wave % 5 == 0)
- Spawn de 2 bosses por onda de boss

---

## 👹 Escala de Crescimento dos Monstros

### Valores Base (Constants.gd)

```gdscript
ENEMY_BASE_HP := 2
BOSS_BASE_HP := 50
ENEMY_BASE_SPEED := 30.0
BOSS_SPEED_MULTIPLIER := 0.5
```

### Fórmulas de Escala

**HP de Inimigo Normal**
```
HP(w) = ENEMY_BASE_HP * wave_factor(w)
HP(w) = 2 * (1.08^(w-1))
```

**HP de Boss**
```
BOSS_HP(w) = BOSS_BASE_HP * wave_factor(w)
BOSS_HP(w) = 50 * (1.08^(w-1))
```

**Velocidade de Inimigo Normal**
```
SPEED(w) = ENEMY_BASE_SPEED * wave_factor(w)
SPEED(w) = 30.0 * (1.08^(w-1))
Limite máximo: 200.0 px/s
```

**Velocidade de Boss**
```
BOSS_SPEED(w) = ENEMY_BASE_SPEED * wave_factor(w) * BOSS_SPEED_MULTIPLIER
BOSS_SPEED(w) = 30.0 * (1.08^(w-1)) * 0.5
BOSS_SPEED(w) = 15.0 * (1.08^(w-1))
Limite máximo: 200.0 px/s
```

### Tabela de Crescimento - Waves 1 a 100

| Wave | Wave Factor | Inimigo HP | Boss HP | Inimigo Speed | Boss Speed | Total Inimigos |
|------|-------------|------------|---------|---------------|------------|----------------|
| 1    | 1.000       | 2          | 50      | 30.0          | 15.0       | 6              |
| 5    | 1.360       | 3          | 68      | 40.8          | 20.4       | 12             |
| 10   | 1.999       | 4          | 100     | 60.0          | 30.0       | 21             |
| 15   | 2.937       | 6          | 147     | 88.1          | 44.1       | 30             |
| 20   | 4.315       | 9          | 216     | 129.5         | 64.7       | 39             |
| 25   | 6.341       | 13         | 317     | 190.2         | 95.1       | 48             |
| 30   | 9.317       | 19         | 466     | 279.5         | 139.8      | 57             |
| 35   | 13.691      | 27         | 685     | 410.7         | 205.4      | 66             |
| 40   | 20.115      | 40         | 1006    | 603.5*        | 301.7*     | 75             |
| 50   | 43.459      | 87         | 2173    | 200.0*        | 200.0*     | 93             |
| 60   | 93.843      | 188        | 4692    | 200.0*        | 200.0*     | 111            |
| 70   | 202.647     | 405        | 10132   | 200.0*        | 200.0*     | 129            |
| 80   | 437.463     | 875        | 21873   | 200.0*        | 200.0*     | 147            |
| 90   | 944.736     | 1889       | 47237   | 200.0*        | 200.0*     | 165            |
| 100  | 2039.576    | 4079       | 101979  | 200.0*        | 200.0*     | 183            |

\* Velocidade limitada ao máximo de 200.0 px/s

### Análise de Crescimento

**Taxa de Crescimento Exponencial**
- O sistema usa crescimento exponencial com base 1.08
- A cada wave, monstros ficam **8% mais fortes**
- Após 10 waves, monstros têm ~2x HP/velocidade
- Após 25 waves, monstros têm ~6.3x HP/velocidade
- Após 50 waves, monstros têm ~43.5x HP/velocidade

**Ponto Crítico de Velocidade**
- Wave ~37: Inimigos normais atingem 200 px/s
- Wave ~38: Bosses atingem 200 px/s
- Após isso, apenas HP continua crescendo

**Dificuldade Efetiva (HP Total por Wave)**

Para ondas normais:
```
TOTAL_HP(w) = (total_enemies - bosses) * HP(w) + bosses * BOSS_HP(w)
```

Para ondas de boss (wave % 5 == 0):
```
TOTAL_HP(w) = (total_enemies - 2) * HP(w) + 2 * BOSS_HP(w)
```

---

## 🏹 Taxas de Disparo das Torres

### Valores Base por Tipo de Torre

| Torre | Fire Rate Base | Range Base | Damage Base | Observações |
|-------|----------------|------------|-------------|-------------|
| **Tower (Normal)** | 1.5s | 260.0 | 0.5 | Direções múltiplas |
| **Sniper** | 20.0s | 400.0 | 5.0 | Tiro único, alta precisão |
| **AOE** | 2.0s | 180.0 | 2.0 | Dano em área (raio 60) |
| **Shock** | 1.5s | 200.0 | 1.5 | Corrente elétrica (3 alvos) |
| **Slow** | 0.5s | 200.0 | - | Slow 50%, duração 1.0s |
| **Barracks** | 3.0s | - | 0.3 | Spawn de soldados |
| **Hero** | 0.8s | 9999.0 | 1.0 | Tiro manual |

### Sistema de Upgrade de Fire Rate

**Torre Normal**
```
Custo: 8 moedas por upgrade
Redução: -0.05s por upgrade
Mínimo: 0.1s
Máximo teórico: ~28 upgrades (de 1.5s para 0.1s)
```

**Sniper Tower**
```
Custo: 12 moedas por upgrade
Redução: -0.5s por upgrade
Mínimo: 1.0s
Máximo teórico: 38 upgrades (de 20.0s para 1.0s)
```

**AOE Tower**
```
Custo: 12 moedas por upgrade
Redução: -0.3s por upgrade
Mínimo: 0.5s
Máximo teórico: 5 upgrades (de 2.0s para 0.5s)
```

**Shock Tower**
```
Custo: 12 moedas por upgrade
Redução: -0.2s por upgrade
Mínimo: 0.5s
Máximo teórico: 5 upgrades (de 1.5s para 0.5s)
```

**Slow Tower**
```
Custo: 12 moedas por upgrade
Redução: -0.1s por upgrade
Mínimo: 0.2s
Máximo teórico: 3 upgrades (de 0.5s para 0.2s)
```

**Hero (Global Upgrade)**
```
Custo: Gratuito (escolha após wave)
Redução: -0.05s por upgrade
Mínimo: 0.1s
Máximo: 20 upgrades (de 0.8s para 0.1s teórico)
```

### DPS (Dano por Segundo) Teórico

**Torre Normal (base)**
```
DPS = damage / fire_rate
DPS = 0.5 / 1.5 = 0.333 DPS
```

**Torre Normal (maximizada - 0.1s)**
```
DPS = 0.5 / 0.1 = 5.0 DPS
Aumento: 15x
```

**Sniper (base)**
```
DPS = 5.0 / 20.0 = 0.25 DPS
```

**Sniper (maximizado - 1.0s)**
```
DPS = 5.0 / 1.0 = 5.0 DPS
Aumento: 20x
```

**AOE (base)**
```
DPS = 2.0 / 2.0 = 1.0 DPS (por inimigo na área)
```

**AOE (maximizado - 0.5s)**
```
DPS = 2.0 / 0.5 = 4.0 DPS (por inimigo na área)
Aumento: 4x
```

---

## ⬆️ Sistema de Upgrades

### Upgrades de Torre Normal

| Upgrade | Custo Fixo | Efeito | Máximo |
|---------|------------|--------|--------|
| Alcance | 8 | +60 | Ilimitado |
| Cadência | 8 | -0.05s | Até 0.1s |
| +4 Direções | 12 | +4 direções | 1x (até 4) |
| Dano | 10 | +0.5 | Ilimitado |
| Congelamento | 25 | Freeze | 1x |
| Fogo | 25 | Fire DOT | 1x |

### Upgrades de Outras Torres

| Torre | Upgrade | Custo | Efeito | Máximo |
|-------|---------|-------|--------|--------|
| **Sniper** | Dano | 35 | +? | ? |
| **Sniper** | Cadência | 12 | -0.5s | Até 1.0s |
| **AOE** | Dano | 15 | +? | ? |
| **AOE** | Cadência | 12 | -0.3s | Até 0.5s |
| **AOE** | Área | 20 | +? | ? |
| **Shock** | Dano | 15 | +? | ? |
| **Shock** | Cadência | 12 | -0.2s | Até 0.5s |
| **Shock** | Cadeia | 20 | +? | ? |
| **Slow** | Alcance | 15 | +? | ? |
| **Slow** | Quantidade | 20 | +? | ? |
| **Slow** | Duração | 18 | +? | ? |
| **Slow** | Cadência | 12 | -0.1s | Até 0.2s |
| **Barracks** | Dano | 15 | +? | ? |
| **Barracks** | Hold Time | 12 | +? | ? |
| **Barracks** | Spawn Rate | 20 | +? | ? |
| **Barracks** | Projectile Speed | 18 | +? | ? |
| **Boost** | Alcance | 15 | +? | ? |
| **Boost** | Dano Boost | 20 | +? | ? |
| **Boost** | Rate Boost | 18 | +? | ? |

### Upgrades Globais do Herói

| Upgrade | Custo | Efeito | Máximo |
|---------|-------|--------|--------|
| Dano | Gratuito | +1 por nível | 30 níveis |
| Velocidade | Gratuito | -0.05s por nível | 20 níveis |
| Perfuração | Gratuito | +1 por nível | 3 níveis |
| Crítico | Gratuito | +2% por nível | 8 níveis (16%) |

**Fire Rate do Herói**
```
Base: 0.8s
Após 20 upgrades: 0.8 - (20 * 0.05) = 0.8 - 1.0 = -0.2s
Mas há limite mínimo de 0.1s
Efetivamente: 0.8 - (14 * 0.05) = 0.1s
Máximo efetivo: 14 upgrades
```

### Problema Identificado: Custos Fixos

**Observação Crítica:**
- Todos os upgrades têm custos **FIXOS** que não escalam com o nível
- Isso significa que upgrades ficam relativamente mais baratos conforme o jogo progride
- Um upgrade de 8 moedas é trivial em wave 50+ quando o jogador tem centenas de moedas

---

## 📈 Análise de Progressão

### Recompensas por Wave

**Recompensa por Inimigo Normal**
```
REWARD = NORMAL_REWARD = 2 moedas
```

**Recompensa por Boss**
```
BOSS_REWARD = NORMAL_REWARD * BOSS_REWARD_MULTIPLIER
BOSS_REWARD = 2 * 20 = 40 moedas
```

**Total de Moedas por Wave (Normal)**
```
MOEDAS(w) = (total_enemies - bosses) * 2 + bosses * 40
```

**Total de Moedas por Wave (Boss - wave % 5 == 0)**
```
MOEDAS(w) = (total_enemies - 2) * 2 + 2 * 40
MOEDAS(w) = (total_enemies - 2) * 2 + 80
```

### Projeção de Moedas Acumuladas

| Wave | Inimigos | Moedas (Normal) | Moedas (Boss) | Acumulado (Estimado) |
|------|----------|-----------------|---------------|----------------------|
| 1    | 6        | 12              | -             | 12                   |
| 5    | 12       | -               | 84            | ~150                 |
| 10   | 21       | 42              | -             | ~350                 |
| 15   | 30       | 60              | -             | ~600                 |
| 20   | 39       | 78              | -             | ~900                 |
| 25   | 48       | -               | 176           | ~1400                |
| 50   | 93       | -               | 346           | ~4500                |
| 100  | 183      | -               | 646           | ~15000               |

*Estimativas considerando apenas recompensas de kills, sem drops aleatórios*

### Razão Dificuldade vs. Recursos

**Wave 1:**
- HP Total: 6 * 2 = 12 HP
- Moedas: 12
- Razão: 1 moeda por HP

**Wave 10:**
- HP Total: 21 * 4 ≈ 84 HP
- Moedas: 42
- Razão: 0.5 moedas por HP

**Wave 25:**
- HP Total: 48 * 13 + 2 * 317 ≈ 1378 HP
- Moedas: ~176
- Razão: 0.13 moedas por HP

**Wave 50:**
- HP Total: 91 * 87 + 2 * 2173 ≈ 11795 HP
- Moedas: ~346
- Razão: 0.03 moedas por HP

**Análise:**
- A dificuldade escala exponencialmente (wave_factor)
- Os recursos escalam linearmente (mais inimigos)
- **Gap crescente**: A cada wave, a dificuldade aumenta 8%, mas os recursos aumentam muito menos

---

## ⚠️ Problemas Identificados

### 1. Escala de Dificuldade vs. Recursos

**Problema:**
- Monstros escalam exponencialmente (1.08^n)
- Recursos escalam linearmente (base + wave - 1)
- Gap crescente após wave ~20

**Evidência:**
- Wave 10: 0.5 moedas/HP
- Wave 50: 0.03 moedas/HP
- Wave 100: 0.008 moedas/HP (estimado)

### 2. Upgrades com Custo Fixo

**Problema:**
- Upgrades não escalam em custo
- Ficam progressivamente mais baratos
- Permitem "economia de escala" ilimitada

**Exemplo:**
- Wave 1: Upgrade de 8 moedas = 66% da receita da wave
- Wave 50: Upgrade de 8 moedas = 2% da receita da wave

### 3. Limite de Velocidade

**Problema:**
- Velocidade atinge cap de 200 px/s em wave ~37
- Apenas HP continua crescendo após isso
- Cria desequilíbrio: monstros lentos mas tanques

### 4. Fire Rate de Upgrades Não Escala com Dificuldade

**Problema:**
- Melhorias de fire rate são absolutas (-0.05s)
- Não compensam crescimento exponencial de HP
- Torre maximizada tem DPS fixo enquanto HP do inimigo cresce infinitamente

---

## ✅ Recomendações

### 1. Sistema de Escala de Recursos

**Solução: Escala Exponencial de Recompensas**
```gdscript
REWARD_SCALE = 1.05  # Crescimento mais lento que dificuldade
ENEMY_REWARD(w) = NORMAL_REWARD * (REWARD_SCALE^(w-1))
BOSS_REWARD(w) = ENEMY_REWARD(w) * BOSS_REWARD_MULTIPLIER
```

**Alternativa: Recompensa Baseada em HP**
```gdscript
ENEMY_REWARD = floor(ENEMY_BASE_HP * wave_factor(w) * 0.1)
BOSS_REWARD = floor(BOSS_BASE_HP * wave_factor(w) * 0.1)
```

### 2. Sistema de Upgrades com Custo Progressivo

**Solução: Custo Exponencial**
```gdscript
UPGRADE_COST(base_cost, level) = base_cost * (1.15^level)
```

**Exemplo:**
- Upgrade de Cadência nível 1: 8 moedas
- Upgrade de Cadência nível 2: 9.2 moedas
- Upgrade de Cadência nível 5: 16.1 moedas
- Upgrade de Cadência nível 10: 32.4 moedas

### 3. Ajuste do Wave Factor

**Solução: Reduzir Escala**
```gdscript
WAVE_SCALE = 1.05  # Ao invés de 1.08
# Ou usar escala híbrida
WAVE_SCALE_HP = 1.06
WAVE_SCALE_SPEED = 1.04  # Velocidade cresce mais devagar
```

### 4. Sistema de Upgrades Relativos

**Solução: Upgrades Percentuais**
```gdscript
# Fire Rate reduz percentualmente
fire_rate_reduction = 0.08  # 8% mais rápido por upgrade
new_fire_rate = current_fire_rate * (1 - fire_rate_reduction)
```

### 5. Bonus de Wave

**Solução: Recompensa Fixa por Wave**
```gdscript
WAVE_COMPLETION_BONUS = 10 + (wave * 2)
# Wave 1: +12 moedas
# Wave 10: +30 moedas
# Wave 50: +110 moedas
```

### 6. Escala de Fire Rate Baseada em Wave

**Solução: Fire Rate Dinâmico**
```gdscript
# Torres podem ter fire rate que escala com upgrades de forma mais agressiva
# Ou fire rate base que melhora automaticamente com waves (menos recomendado)
```

---

## 📊 Tabelas Comparativas

### Comparação: Sistema Atual vs. Recomendado

| Wave | HP Atual | HP Recomendado (1.05) | Diferença % |
|------|----------|----------------------|-------------|
| 10   | 4        | 3                    | -25%        |
| 25   | 13       | 7                    | -46%        |
| 50   | 87       | 21                   | -76%        |
| 100  | 4079     | 130                  | -97%        |

### DPS Necessário vs. DPS Disponível

**Cenário: Wave 50, 93 inimigos, 10 torres maximizadas**

**HP Total a Drenar:**
```
91 * 87 + 2 * 2173 = 7917 + 4346 = 12263 HP
```

**DPS de 10 Torres Normais Maximizadas:**
```
10 * 5.0 = 50 DPS
```

**Tempo para Matar (assumindo 100% uptime):**
```
12263 / 50 = 245 segundos = 4 minutos
```

**Mas com spawn rate de 0.12s:**
- Inimigos spawnam continuamente
- Alguns chegam à base
- **Problema:** DPS não acompanha HP crescente

---

## 🎯 Conclusões

1. **Escala Exponencial é Agressiva Demais**
   - Wave 50+ tornam-se quase impossíveis sem upgrades massivos
   - Gap entre recursos e dificuldade cresce exponencialmente

2. **Upgrades Fixos São Problema a Longo Prazo**
   - Economia de escala ilimitada
   - Upgrades ficam trivialmente baratos

3. **Fire Rate Tem Limites Físicos**
   - Não pode compensar HP exponencial indefinidamente
   - Precisa de sistema de upgrades mais inteligente

4. **Velocidade Tem Cap**
   - Após wave 37, apenas HP cresce
   - Cria desequilíbrio mecânico

### Próximos Passos Recomendados

1. ✅ Implementar escala de recompensas
2. ✅ Implementar custos progressivos de upgrades
3. ✅ Ajustar WAVE_SCALE para valor mais conservador
4. ✅ Adicionar bonus de completion de wave
5. ✅ Considerar sistema de upgrades percentuais
6. ✅ Implementar cap de dificuldade ou modo endless separado

---

**Documento gerado em:** Análise completa do sistema de balanceamento
**Baseado em:** Constants.gd, WaveManager.gd, Game.gd, EnemyManager.gd


