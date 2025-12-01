# 📊 Análise Completa de Balanceamento

## 🎯 Objetivo

Análise completa do balanceamento do jogo, considerando:
- ✅ Dano do Herói
- ✅ Dano de todas as torres
- ✅ HP do Boss e sua relação com a dificuldade das waves
- ✅ DPS (Damage Per Second) efetivo de todas as fontes de dano

---

## 📈 Valores Base das Fontes de Dano

### Herói (Hero)
- **Dano Base:** 0.8 por flecha
- **Cadência Base:** 1.0 segundo (1 tiro por segundo)
- **DPS Base:** 0.8 DPS
- **Alcance:** 9999 (quase infinito)
- **Perfuração Base:** 0 (pode ser melhorado)
- **Chance Crítica Base:** 0% (pode ser melhorado até 20%)
- **Multiplicador Crítico:** 2.0x (pode ser melhorado)

### Torre Normal
- **Dano Base:** 0.5 por projétil
- **Cadência Base:** 1.5 segundo (0.67 tiros/segundo)
- **DPS Base:** ~0.33 DPS
- **Alcance Base:** 260.0
- **Limite:** 8 torres
- **Custo:** 10 moedas

### Torre Sniper
- **Dano Base:** 8.0 por tiro
- **Cadência Base:** 15.0 segundo (0.067 tiros/segundo)
- **DPS Base:** ~0.53 DPS
- **Alcance Base:** 400.0
- **Perfuração Base:** 1
- **Limite:** 2 torres
- **Custo:** 70 moedas

### Torre AOE
- **Dano Base:** 2.0 por explosão
- **Cadência Base:** 2.0 segundo (0.5 tiros/segundo)
- **DPS Base:** 1.0 DPS (em área)
- **Raio AOE:** 60.0
- **Alcance Base:** 180.0
- **Limite:** 5 torres
- **Custo:** 30 moedas

### Torre Shock
- **Dano Base:** 1.5 por choque
- **Cadência Base:** 1.5 segundo (0.67 tiros/segundo)
- **DPS Base:** ~1.0 DPS (com chain)
- **Alcance Base:** 200.0
- **Chain Count:** 3 inimigos
- **Limite:** 4 torres
- **Custo:** 40 moedas

### Barracks (Soldados)
- **Dano Base:** 0.3 DPS por soldado
- **Taxa de Spawn:** 1 soldado a cada 3 segundos
- **Tempo de Hold:** 2.0 segundos
- **Limite:** 2 quartéis
- **Custo:** 20 moedas

### Minas
- **Dano Base:** 15.0 (one-shot, área)
- **Raio de Explosão:** 60.0
- **Limite:** 8 minas
- **Custo:** 10 moedas

---

## 🎮 Análise de HP e Escalação

### HP dos Inimigos Normais

**Fórmula:** `HP(wave) = ENEMY_BASE_HP * (WAVE_SCALE ^ (wave - 1))`

Onde:
- `ENEMY_BASE_HP = 3`
- `WAVE_SCALE = 1.06`

**Exemplos:**
- Wave 1: 3 HP
- Wave 10: 3 * (1.06^9) ≈ 5.1 HP
- Wave 25: 3 * (1.06^24) ≈ 12.9 HP
- Wave 50: 3 * (1.06^49) ≈ 57.8 HP
- Wave 100: 3 * (1.06^99) ≈ 466.3 HP

### HP do Boss

**Fórmula:** `BOSS_HP(wave) = BOSS_BASE_HP * (WAVE_SCALE ^ (wave - 1))`

Onde:
- `BOSS_BASE_HP = 35`
- `WAVE_SCALE = 1.06`

**Exemplos:**
- Wave 5 (primeiro boss): 35 * (1.06^4) ≈ 44.2 HP
- Wave 10: 35 * (1.06^9) ≈ 59.5 HP
- Wave 25: 35 * (1.06^24) ≈ 150.5 HP
- Wave 50: 35 * (1.06^49) ≈ 674.3 HP
- Wave 100: 35 * (1.06^99) ≈ 5441.8 HP

### Comparação: Boss vs Inimigos Normais

**Razão de HP (Boss / Normal):**
- Wave 5: 44.2 / 3.75 ≈ 11.8x mais HP
- Wave 10: 59.5 / 5.1 ≈ 11.7x mais HP
- Wave 25: 150.5 / 12.9 ≈ 11.7x mais HP
- Wave 50: 674.3 / 57.8 ≈ 11.7x mais HP
- Wave 100: 5441.8 / 466.3 ≈ 11.7x mais HP

**Conclusão:** O boss tem aproximadamente **11.7x mais HP** que um inimigo normal, mantendo-se constante ao longo das waves.

---

## ⚔️ Análise de DPS Disponível

### Cenário: Wave 25 (Exemplo)

**Inimigo Normal:** 12.9 HP
**Boss:** 150.5 HP

### DPS Total Disponível (com setup máximo teórico)

#### 1. Herói
- **DPS Base:** 0.8
- **Com upgrades máximos:** 
  - Dano: 0.8 + 30 = 30.8
  - Cadência: 1.0 - (20 * 0.05) = 0.0 (limitado a 0.1) = ~10 DPS máximo
  - **DPS Máximo:** ~30.8 DPS (sem críticos)

#### 2. Torres Normais (8 torres)
- **DPS Base Total:** 0.33 * 8 = 2.64 DPS
- **Com upgrades:** ~5-10 DPS (estimado)

#### 3. Torres Sniper (2 torres)
- **DPS Base Total:** 0.53 * 2 = 1.06 DPS
- **Foco em boss:** Muito efetivo contra boss

#### 4. Torres AOE (5 torres)
- **DPS Base Total:** 1.0 * 5 = 5.0 DPS
- **Efetivo contra grupos:** DPS real pode ser 2-3x maior com múltiplos alvos

#### 5. Torres Shock (4 torres)
- **DPS Base Total:** 1.0 * 4 = 4.0 DPS
- **Com chain:** Pode ser 2-3x maior com múltiplos alvos

#### 6. Barracks (2 quartéis)
- **DPS Estimado:** ~2-4 DPS (dependendo de quantos soldados estão ativos)

**DPS Total Estimado (Wave 25):** ~30-50 DPS (com upgrades)

### Tempo para Matar (Wave 25)

**Inimigo Normal (12.9 HP):**
- Com DPS de 30: 12.9 / 30 ≈ 0.43 segundos
- Com DPS de 50: 12.9 / 50 ≈ 0.26 segundos

**Boss (150.5 HP):**
- Com DPS de 30: 150.5 / 30 ≈ 5.0 segundos
- Com DPS de 50: 150.5 / 50 ≈ 3.0 segundos

---

## 🎯 Análise: HP do Boss

### Situação Atual

O boss tem **11.7x mais HP** que um inimigo normal. Em waves de boss (a cada 5 waves), aparecem **2 bosses**.

### Problema Identificado

1. **Dificuldade Concentrada:** O boss representa a maior parte do HP total da wave
2. **2 Bosses por Wave:** Dobra a dificuldade nas waves de boss
3. **Velocidade Reduzida:** Boss é 50% mais lento (BOSS_SPEED_MULTIPLIER = 0.5), mas ainda é muito resistente

### Análise Comparativa: Boss vs Wave Normal

**Wave 25 (exemplo):**
- **Inimigos Normais:** ~23 inimigos * 12.9 HP = 296.7 HP total
- **2 Bosses:** 2 * 150.5 = 301.0 HP total
- **Total da Wave:** ~597.7 HP
- **Boss representa:** 301.0 / 597.7 = **50.4% do HP total**

**Wave 50 (exemplo):**
- **Inimigos Normais:** ~48 inimigos * 57.8 HP = 2774.4 HP total
- **2 Bosses:** 2 * 674.3 = 1348.6 HP total
- **Total da Wave:** ~4123.0 HP
- **Boss representa:** 1348.6 / 4123.0 = **32.7% do HP total**

### Conclusão sobre HP do Boss

**O boss representa uma proporção significativa do HP total:**
- Waves iniciais (10-25): **~50% do HP total**
- Waves médias (25-50): **~33-50% do HP total**
- Waves altas (50+): **~20-30% do HP total**

**Problema:** Em waves iniciais e médias, o boss é a parte mais difícil da wave, o que pode criar uma dificuldade desbalanceada.

---

## 💡 Recomendações

### 1. Redução do HP do Boss

**Opção A: Redução Moderada (Recomendado)**
- **Reduzir BOSS_BASE_HP de 35 para 28** (~20% de redução)
- **Nova Razão:** Boss teria ~9.3x mais HP que inimigo normal
- **Impacto:** Boss ainda seria significativo, mas menos dominante

**Opção B: Redução Agressiva**
- **Reduzir BOSS_BASE_HP de 35 para 25** (~29% de redução)
- **Nova Razão:** Boss teria ~8.3x mais HP que inimigo normal
- **Impacto:** Boss seria mais gerenciável, mas pode perder o impacto

**Opção C: Manter Atual**
- **Manter BOSS_BASE_HP = 35**
- **Justificativa:** Boss deve ser desafiador, e a velocidade reduzida compensa

### 2. Balanceamento de Dano do Herói

**Situação Atual:**
- Herói tem DPS base de 0.8, mas pode ser melhorado significativamente com upgrades
- Com upgrades máximos, pode chegar a ~30 DPS

**Recomendação:**
- Manter como está - o herói é forte com upgrades, mas fraco no início (balanceado)

### 3. Balanceamento das Torres

**Torre Normal:**
- DPS baixo mas consistente - ✅ Balanceado

**Torre Sniper:**
- Alto dano, baixa cadência - ✅ Balanceado para focar boss

**Torre AOE:**
- DPS médio, efetiva contra grupos - ✅ Balanceado

**Torre Shock:**
- DPS médio, efetiva contra grupos - ✅ Balanceado

---

## 📋 Resumo e Decisões

### HP do Boss - Recomendação Final

**✅ RECOMENDAÇÃO: Redução Moderada**

**Mudança Proposta:**
```gdscript
# ANTES:
const BOSS_BASE_HP := 35

# DEPOIS:
const BOSS_BASE_HP := 28  # Redução de ~20%
```

**Impacto Esperado:**
- Wave 25: Boss HP reduz de 150.5 para 120.4 (-20%)
- Wave 50: Boss HP reduz de 674.3 para 539.4 (-20%)
- **Boss ainda será desafiador**, mas não dominará completamente a wave
- **Melhora o equilíbrio** entre dificuldade de boss e dificuldade de onda normal

**Justificativa:**
1. O boss já é 50% mais lento, então não precisa de HP tão alto
2. Em waves iniciais/médias, o boss representa ~50% do HP total (muito dominante)
3. Com 20% de redução, o boss ainda terá ~9.3x mais HP que inimigo normal (ainda significativo)
4. Melhora a experiência do jogador ao tornar a onda mais balanceada

### Balanceamento Geral

**Status:**
- ✅ Herói: Balanceado (fraco no início, forte com upgrades)
- ✅ Torres: Bem balanceadas entre si
- ⚠️ Boss HP: Muito alto (recomendado reduzir 20%)

---

**Data da Análise:** Análise completa considerando todas as fontes de dano
**Próximos Passos:** Aplicar redução de HP do boss se aprovado

