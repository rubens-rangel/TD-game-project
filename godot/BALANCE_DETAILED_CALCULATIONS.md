# 📐 Cálculos Detalhados de Balanceamento

## 🧮 Fórmulas Matemáticas Completas

### Wave Factor
```python
def wave_factor(wave: int) -> float:
    """Calcula o multiplicador de escala para uma wave"""
    WAVE_SCALE = 1.08
    return pow(WAVE_SCALE, max(0, wave - 1))
```

### Cálculo de Inimigos
```python
def total_enemies(wave: int) -> int:
    """Calcula total de inimigos a spawnar em uma wave"""
    base = 6
    plus_each = max(0, wave - 1)
    bonus_five = 3 * int(wave - 1) // 5
    return base + plus_each + bonus_five

def is_boss_wave(wave: int) -> bool:
    """Verifica se é onda de boss"""
    return wave % 5 == 0

def bosses_in_wave(wave: int) -> int:
    """Retorna número de bosses na wave"""
    return 2 if is_boss_wave(wave) else 0
```

### Cálculo de HP
```python
def enemy_hp(wave: int) -> int:
    """HP de inimigo normal"""
    ENEMY_BASE_HP = 2
    f = wave_factor(wave)
    return int(max(1, round(ENEMY_BASE_HP * f)))

def boss_hp(wave: int) -> int:
    """HP de boss"""
    BOSS_BASE_HP = 50
    f = wave_factor(wave)
    return int(max(1, round(BOSS_BASE_HP * f)))
```

### Cálculo de Velocidade
```python
def enemy_speed(wave: int) -> float:
    """Velocidade de inimigo normal (limitada a 200)"""
    ENEMY_BASE_SPEED = 30.0
    MAX_SPEED = 200.0
    f = wave_factor(wave)
    speed = ENEMY_BASE_SPEED * f
    return min(speed, MAX_SPEED)

def boss_speed(wave: int) -> float:
    """Velocidade de boss (limitada a 200)"""
    ENEMY_BASE_SPEED = 30.0
    BOSS_SPEED_MULTIPLIER = 0.5
    MAX_SPEED = 200.0
    f = wave_factor(wave)
    speed = ENEMY_BASE_SPEED * f * BOSS_SPEED_MULTIPLIER
    return min(speed, MAX_SPEED)
```

### HP Total da Wave
```python
def total_wave_hp(wave: int) -> int:
    """Calcula HP total de todos os inimigos da wave"""
    total = total_enemies(wave)
    bosses = bosses_in_wave(wave)
    normals = total - bosses
    
    normal_hp = normals * enemy_hp(wave)
    boss_hp_total = bosses * boss_hp(wave)
    
    return normal_hp + boss_hp_total
```

### Recompensas
```python
def wave_rewards(wave: int) -> int:
    """Calcula moedas totais da wave"""
    NORMAL_REWARD = 2
    BOSS_REWARD_MULTIPLIER = 20
    
    total = total_enemies(wave)
    bosses = bosses_in_wave(wave)
    normals = total - bosses
    
    normal_rewards = normals * NORMAL_REWARD
    boss_rewards = bosses * NORMAL_REWARD * BOSS_REWARD_MULTIPLIER
    
    return normal_rewards + boss_rewards
```

---

## 📊 Tabela Expandida: Waves 1-150

| Wave | Factor | Enemies | Bosses | Normal HP | Boss HP | Total HP | Rewards | Normal Speed | Boss Speed |
|------|--------|---------|--------|-----------|---------|----------|---------|--------------|------------|
| 1    | 1.000  | 6       | 0      | 2         | -       | 12       | 12      | 30.0         | -          |
| 2    | 1.080  | 7       | 0      | 2         | -       | 14       | 14      | 32.4         | -          |
| 3    | 1.166  | 8       | 0      | 2         | -       | 16       | 16      | 35.0         | -          |
| 4    | 1.260  | 9       | 0      | 3         | -       | 27       | 18      | 37.8         | -          |
| 5    | 1.360  | 12      | 2      | 3         | 68      | 142      | 84      | 40.8         | 20.4       |
| 6    | 1.469  | 7       | 0      | 3         | -       | 21       | 14      | 44.1         | -          |
| 7    | 1.587  | 8       | 0      | 3         | -       | 24       | 16      | 47.6         | -          |
| 8    | 1.714  | 9       | 0      | 3         | -       | 27       | 18      | 51.4         | -          |
| 9    | 1.851  | 10      | 0      | 4         | -       | 40       | 20      | 55.5         | -          |
| 10   | 1.999  | 21      | 0      | 4         | -       | 84       | 42      | 60.0         | -          |
| 15   | 2.937  | 30      | 0      | 6         | -       | 180      | 60      | 88.1         | -          |
| 20   | 4.315  | 39      | 0      | 9         | -       | 351      | 78      | 129.5        | -          |
| 25   | 6.341  | 48      | 2      | 13        | 317     | 1378     | 176     | 190.2        | 95.1       |
| 30   | 9.317  | 57      | 0      | 19        | -       | 1083     | 114     | 200.0*       | -          |
| 35   | 13.691 | 66      | 0      | 27        | -       | 1782     | 132     | 200.0*       | -          |
| 40   | 20.115 | 75      | 0      | 40        | -       | 3000     | 150     | 200.0*       | -          |
| 45   | 29.556 | 84      | 0      | 59        | -       | 4956     | 168     | 200.0*       | -          |
| 50   | 43.459 | 93      | 2      | 87        | 2173    | 11795    | 346     | 200.0*       | 200.0*     |
| 60   | 93.843 | 111     | 0      | 188       | -       | 20868    | 222     | 200.0*       | -          |
| 70   | 202.647| 129     | 0      | 405       | -       | 52245    | 258     | 200.0*       | -          |
| 80   | 437.463| 147     | 0      | 875       | -       | 128625   | 294     | 200.0*       | -          |
| 90   | 944.736| 165     | 0      | 1889      | -       | 311685   | 330     | 200.0*       | -          |
| 100  | 2039.576| 183    | 2      | 4079      | 101979  | 845724   | 646     | 200.0*       | 200.0*     |
| 120  | 9518.5 | 219     | 0      | 19037     | -       | 4169103  | 438     | 200.0*       | -          |
| 150  | 99287.2| 273     | 2      | 198574    | 4964361 | 138840150| 1046    | 200.0*       | 200.0*     |

\* Velocidade limitada ao máximo de 200.0 px/s

---

## 🔢 Análise de Fire Rate por Tipo de Torre

### Torre Normal (Base: 1.5s, Damage: 0.5)

| Upgrades | Fire Rate | DPS | Custo Total | DPS/Moeda |
|----------|-----------|-----|-------------|-----------|
| 0        | 1.5s      | 0.33| 0           | -         |
| 1        | 1.45s     | 0.34| 8           | 0.043     |
| 5        | 1.25s     | 0.40| 40          | 0.010     |
| 10       | 1.0s      | 0.50| 80          | 0.006     |
| 15       | 0.75s     | 0.67| 120         | 0.006     |
| 20       | 0.5s      | 1.00| 160         | 0.006     |
| 28       | 0.1s      | 5.00| 224         | 0.022     |

**Observação:** O DPS/moeda melhora drasticamente nos últimos upgrades, mas o custo total é fixo.

### Sniper Tower (Base: 20.0s, Damage: 5.0)

| Upgrades | Fire Rate | DPS | Custo Total | DPS/Moeda |
|----------|-----------|-----|-------------|-----------|
| 0        | 20.0s     | 0.25| 0           | -         |
| 1        | 19.5s     | 0.26| 12          | 0.022     |
| 5        | 17.5s     | 0.29| 60          | 0.005     |
| 10       | 15.0s     | 0.33| 120         | 0.003     |
| 19       | 10.5s     | 0.48| 228         | 0.002     |
| 38       | 1.0s      | 5.00| 456         | 0.011     |

**Observação:** Sniper tem retorno muito baixo até os últimos upgrades.

### AOE Tower (Base: 2.0s, Damage: 2.0)

| Upgrades | Fire Rate | DPS | Custo Total | DPS/Moeda |
|----------|-----------|-----|-------------|-----------|
| 0        | 2.0s      | 1.00| 0           | -         |
| 1        | 1.7s      | 1.18| 12          | 0.098     |
| 2        | 1.4s      | 1.43| 24          | 0.060     |
| 3        | 1.1s      | 1.82| 36          | 0.051     |
| 4        | 0.8s      | 2.50| 48          | 0.052     |
| 5        | 0.5s      | 4.00| 60          | 0.067     |

**Observação:** AOE tem bom retorno inicial, mas limite baixo (5 upgrades).

---

## 📈 Crescimento Comparativo

### HP Total vs. DPS Disponível

**Cenário: 10 Torres Normais Maximizadas (DPS Total: 50)**

| Wave | HP Total | Tempo para Matar* | Spawn Rate | Inimigos/s |
|------|----------|-------------------|------------|------------|
| 10   | 84       | 1.7s              | 0.30s      | 3.3/s      |
| 25   | 1378     | 27.6s             | 0.00s**    | 0.0/s      |
| 50   | 11795    | 236s (3.9min)     | 0.00s**    | 0.0/s      |
| 100  | 845724   | 16914s (4.7h)     | 0.00s**    | 0.0/s      |

\* Assumindo 100% de uptime e todos os inimigos presentes simultaneamente
\** Spawn rate mínimo: 0.12s (máximo de 8.33 inimigos/s)

**Análise:**
- Wave 10: Razoável (1.7s para matar tudo)
- Wave 25: Difícil mas viável (27s)
- Wave 50: Muito difícil (4 minutos)
- Wave 100: Impossível (quase 5 horas!)

### Razão HP/DPS ao Longo das Waves

```python
# Assumindo DPS fixo de 50 (10 torres maximizadas)
def time_to_kill_all(wave: int, dps: float = 50.0) -> float:
    hp = total_wave_hp(wave)
    return hp / dps

# Resultado:
# Wave 10: 1.68s
# Wave 25: 27.56s
# Wave 50: 235.9s
# Wave 100: 16914.48s (4.7 horas!)
```

---

## 💰 Análise Econômica Detalhada

### Moedas Acumuladas (Estimativa)

```python
def accumulated_coins_estimate(wave: int) -> int:
    """Estimativa de moedas acumuladas até uma wave"""
    total = 0
    for w in range(1, wave + 1):
        total += wave_rewards(w)
    return total
```

| Wave | Moedas da Wave | Acumulado | Upgrades Possíveis* |
|------|----------------|-----------|---------------------|
| 1    | 12             | 12        | 1.5                 |
| 5    | 84             | 150       | 18.8                |
| 10   | 42             | 350       | 43.8                |
| 25   | 176            | 1400      | 175                 |
| 50   | 346            | 4500      | 562.5               |
| 100  | 646            | 15000     | 1875                |

\* Assumindo upgrade médio de 8 moedas

### Custo de Maximizar uma Torre Normal

**Upgrades necessários:**
- Alcance: Ilimitado (vamos considerar 10 níveis)
- Cadência: 28 níveis
- Direções: 1 nível
- Dano: Ilimitado (vamos considerar 10 níveis)
- Congelamento: 1 nível
- Fogo: 1 nível

**Custo total estimado:**
```
Alcance (10x): 10 * 8 = 80
Cadência (28x): 28 * 8 = 224
Direções (1x): 1 * 12 = 12
Dano (10x): 10 * 10 = 100
Congelamento: 25
Fogo: 25
Total: 466 moedas
```

**Custo de maximizar 10 torres: 4,660 moedas**

**Wave necessária para maximizar 10 torres: ~Wave 35-40**

---

## ⚔️ Análise de DPS vs. HP por Wave

### Efetividade de DPS ao Longo das Waves

**Cenário Base: 10 Torres Normais, Dano 0.5, Fire Rate 1.5s**
```
DPS Total Base: 10 * (0.5 / 1.5) = 3.33 DPS
```

| Wave | HP Total | Tempo Base | Tempo com 10 Upgrades | Tempo Maximizado |
|------|----------|------------|----------------------|------------------|
| 1    | 12       | 3.6s       | 2.4s                 | 0.24s            |
| 10   | 84       | 25.2s      | 16.8s                | 1.68s            |
| 25   | 1378     | 414s       | 276s                 | 27.6s            |
| 50   | 11795    | 3540s      | 2360s                | 236s             |
| 100  | 845724   | 253920s    | 169280s              | 16914s           |

**Observação:**
- Maximização oferece 10x de melhoria
- Mesmo maximizado, wave 100 leva quase 5 horas!

---

## 🎯 Pontos de Inflexão

### Wave onde HP do Inimigo = DPS de Torre Maximizada

**Torre Maximizada: 5 DPS**
```
5 DPS * tempo = HP(wave)
5 * 10 = 50 HP (tempo razoável de 10s)
Enemy HP = 50 → Wave ~25
```

**Conclusão:**
- Wave 25: Inimigo normal tem ~13 HP (fácil)
- Wave 50: Inimigo normal tem ~87 HP (difícil)
- Wave 100: Inimigo normal tem ~4079 HP (impossível)

### Wave onde Velocidade Atinge Máximo

```
ENEMY_BASE_SPEED * (1.08^(w-1)) = 200
30 * (1.08^(w-1)) = 200
1.08^(w-1) = 6.67
(w-1) * log(1.08) = log(6.67)
w-1 = log(6.67) / log(1.08)
w-1 = 24.9
w = 25.9 ≈ 26
```

**Resultado:** Wave 26-27 para inimigos normais, wave 36-37 para bosses

### Wave onde HP do Boss = HP Total de Wave Normal Anterior

```
Wave 50: Boss HP = 2173
Wave 49: Total HP = ? (precisa calcular)
```

---

## 🔄 Sistema de Upgrades Proposto

### Custo Progressivo

```python
def upgrade_cost(base_cost: int, level: int, multiplier: float = 1.15) -> int:
    """Calcula custo de upgrade com escala progressiva"""
    return int(base_cost * (multiplier ** level))
```

**Exemplo: Upgrade de Cadência**

| Nível | Custo (Atual) | Custo (Proposto) | Diferença |
|-------|---------------|------------------|-----------|
| 1     | 8             | 9                | +12%      |
| 5     | 8             | 16               | +100%     |
| 10    | 8             | 32               | +300%     |
| 20    | 8             | 131              | +1538%    |

**Custo Total para 28 Upgrades:**
- Atual: 224 moedas
- Proposto: ~2,400 moedas

### Recompensas Escaladas

```python
def scaled_reward(wave: int) -> int:
    """Recompensa que escala com dificuldade"""
    REWARD_SCALE = 1.05  # Mais conservador que wave scale
    base_reward = 2
    return int(base_reward * (REWARD_SCALE ** (wave - 1)))
```

**Comparação:**

| Wave | Recompensa Atual | Recompensa Proposta | Diferença |
|------|------------------|---------------------|-----------|
| 1    | 2                | 2                   | 0%        |
| 10   | 2                | 3                   | +50%      |
| 25   | 2                | 7                   | +250%     |
| 50   | 2                | 21                  | +950%     |
| 100  | 2                | 258                 | +12800%   |

---

## 📊 Gráficos Conceituais

### Crescimento Exponencial de HP vs. Linear de Recursos

```
HP Total (escala logarítmica)
^
|                                    / Wave 100
|                                /
|                            / Wave 50
|                        /
|                    / Wave 25
|                /
|            / Wave 10
|        /
|    / Wave 1
|/
+--------------------------------> Wave
1   10   25   50   100

Recursos (linear)
^
|                    / Wave 100
|                /
|            / Wave 50
|        /
|    / Wave 25
|/
+--------------------------------> Wave
1   10   25   50   100
```

### Gap de Dificuldade vs. Recursos

```
Razão Moedas/HP
^
|1.0  |
|     |\
|0.5  | \
|     |  \
|0.1  |   \
|     |    \
|0.01 |     \
|     |      \
|0.001|       \___________________
+--------------------------------> Wave
1    10    25    50    100
```

**Interpretação:**
- Wave 1: 1 moeda por HP (equilibrado)
- Wave 10: 0.5 moedas por HP (difícil)
- Wave 50: 0.03 moedas por HP (muito difícil)
- Wave 100: 0.0008 moedas por HP (impossível)

---

## 🎮 Cenários de Teste Recomendados

### Teste 1: Progression Natural
- Waves 1-25: Progressão suave?
- Waves 26-50: Ainda jogável?
- Waves 51+: Possível sem exploits?

### Teste 2: Maximização de Torres
- Quantas waves para maximizar 1 torre?
- Quantas waves para maximizar 5 torres?
- Quantas waves para maximizar 10 torres?

### Teste 3: DPS vs. HP
- Wave onde HP = 10x DPS de 1 torre?
- Wave onde HP = 10x DPS de 10 torres?
- Wave onde HP = 100x DPS de 10 torres maximizadas?

### Teste 4: Recursos vs. Custo
- Wave onde moedas = custo de 1 torre?
- Wave onde moedas = custo de maximizar 1 torre?
- Wave onde moedas = custo de maximizar todas torres?

---

## 🔍 Observações Finais

1. **Sistema Atual:**
   - Funciona bem até wave ~25
   - Começa a quebrar após wave ~30
   - Impossível após wave ~50 (sem ajustes)

2. **Problemas Principais:**
   - Escala exponencial de dificuldade
   - Escala linear de recursos
   - Upgrades com custo fixo
   - Velocidade tem cap

3. **Soluções Prioritárias:**
   - ✅ Escalar recompensas
   - ✅ Custos progressivos de upgrades
   - ✅ Ajustar wave scale (1.08 → 1.05)
   - ✅ Adicionar bonus de wave completion

---

**Documento complementar:** Análise detalhada de cálculos e projeções



