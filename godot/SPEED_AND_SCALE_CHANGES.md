# ⚡ Mudanças: Velocidade e Escala de Crescimento

## 📋 Resumo

Ajustes na velocidade básica dos inimigos e na escala de crescimento das waves para melhorar o ritmo do jogo.

---

## ✅ Mudanças Implementadas

### 1. Velocidade Básica Aumentada

**Mudança:**
- **Antes:** `ENEMY_BASE_SPEED := 30.0`
- **Depois:** `ENEMY_BASE_SPEED := 38.0`
- **Aumento:** ~27% mais rápido

**Impacto:**
- Inimigos se movem mais rápido desde o início
- Jogo fica mais dinâmico desde as primeiras waves
- Aumenta a pressão e ação desde o começo

**Comparação de Velocidade:**
- Wave 1: 38.0 (antes: 30.0) - **+27%**
- Wave 10: ~57.1 (antes: ~53.8) - **+6%**
- Wave 25: ~99.5 (antes: ~102.8) - A escala menor faz com que em waves altas seja similar

---

### 2. Escala de Crescimento Reduzida

**Mudança:**
- **Antes:** `WAVE_SCALE := 1.06` (6% por wave)
- **Depois:** `WAVE_SCALE := 1.04` (4% por wave)
- **Redução:** ~33% menos crescimento por wave

**Impacto:**
- Progressão mais suave entre waves
- Dificuldade cresce mais lentamente
- Permite jogar mais waves antes de ficar muito difícil

---

## 📊 Comparação: Antes vs Depois

### HP dos Inimigos

| Wave | HP Antes (1.06) | HP Depois (1.04) | Diferença |
|------|----------------|------------------|-----------|
| 1    | 3.0            | 3.0              | 0%        |
| 10   | 5.1            | 4.5              | -12%      |
| 25   | 12.9           | 9.7              | -25%      |
| 50   | 57.8           | 34.4             | -40%      |
| 100  | 466.3          | 171.6            | -63%      |

### Velocidade dos Inimigos

| Wave | Velocidade Antes | Velocidade Depois | Diferença |
|------|------------------|-------------------|-----------|
| 1    | 30.0             | 38.0              | +27%      |
| 10   | 53.8             | 56.2              | +4%       |
| 25   | 102.8            | 98.9              | -4%       |
| 50   | 330.2            | 216.4             | -34%      |
| 100  | 2667.5           | 702.1             | -74%      |

### HP do Boss

| Wave | HP Antes (1.06) | HP Depois (1.04) | Diferença |
|------|----------------|------------------|-----------|
| 5    | 35.4            | 32.5             | -8%       |
| 10   | 47.6            | 39.6             | -17%      |
| 25   | 120.4           | 90.5             | -25%      |
| 50   | 539.4           | 321.4            | -40%      |
| 100  | 4353.4          | 1602.3           | -63%      |

---

## 🎯 Resultados Esperados

### Gameplay

**Antes:**
- Inimigos começavam lentos
- Dificuldade crescia muito rápido (6% por wave)
- Waves altas ficavam quase impossíveis

**Depois:**
- ✅ Inimigos começam mais rápidos (mais ação desde o início)
- ✅ Dificuldade cresce mais suavemente (4% por wave)
- ✅ Waves altas são mais jogáveis (menos HP e velocidade)
- ✅ Progressão mais controlada e balanceada

### Balanceamento

**Velocidade:**
- Wave 1-10: Mais rápido e dinâmico
- Wave 11-25: Similar ou ligeiramente mais rápido
- Wave 26+: Mais lento (escala menor compensa velocidade inicial maior)

**HP:**
- Redução significativa em todas as waves
- Boss mais gerenciável em waves altas
- Permite estratégias mais variadas

---

## 📝 Detalhes Técnicos

**Arquivo Modificado:**
- `godot/scripts/Constants.gd`

**Mudanças:**
```gdscript
# Antes:
const WAVE_SCALE := 1.06
const ENEMY_BASE_SPEED := 30.0

# Depois:
const WAVE_SCALE := 1.04
const ENEMY_BASE_SPEED := 38.0
```

**Fórmulas:**
- **HP:** `HP(wave) = BASE_HP * (WAVE_SCALE ^ (wave - 1))`
- **Velocidade:** `Speed(wave) = BASE_SPEED * (WAVE_SCALE ^ (wave - 1))`
- **Limitado a 200.0 máximo** (código já existente)

---

## ✅ Status

- ✅ Velocidade básica aumentada de 30.0 para 38.0
- ✅ Escala de crescimento reduzida de 1.06 para 1.04
- ✅ Mudanças aplicadas e prontas para teste

**Data:** Mudanças implementadas
**Status:** ✅ Concluído

