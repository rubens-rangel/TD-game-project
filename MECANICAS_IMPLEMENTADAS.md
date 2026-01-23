# Mecânicas Implementadas - Defesa do Labirinto

Este documento lista todas as mecânicas implementadas no jogo, incluindo probabilidades, efeitos visuais e descrições detalhadas.

---

## 1. TALISMÃS

### Descrição
Talismãs são itens equipáveis que fornecem bônus permanentes para torres, base e outras mecânicas do jogo. Eles podem ser encontrados aleatoriamente quando inimigos são derrotados ou vendidos por esmeraldas.

### Tipos de Talismãs

#### 1.1. Talismã de Dano (TOWER_DAMAGE)
- **Efeito**: Aumenta o dano de todas as torres
- **Valores por Raridade**:
  - Comum: +4% a +6%
  - Incomum: +6% a +9% (1.5x comum)
  - Raro: +9% a +13.5% (1.5x incomum)
  - Épico: +13.5% a +20% (1.5x raro)
  - Lendário: +20% a +30% (1.5x épico)

#### 1.2. Talismã de Dano Crítico (TOWER_CRIT_DAMAGE)
- **Efeito**: Aumenta o dano de crítico das torres
- **Valores por Raridade**: Metade dos valores do Talismã de Dano (2-15%)

#### 1.3. Talismã de Cadência (TOWER_FIRE_RATE)
- **Efeito**: Aumenta a cadência (fire rate) de todas as torres
- **Valores por Raridade**: Mesmos valores do Talismã de Dano

#### 1.4. Talismã de Vida (BASE_HP)
- **Efeito**: Aumenta o HP máximo da base
- **Valores por Raridade**: Valores base multiplicados por 20 (80-600 HP)

#### 1.5. Talismã de Dano da Base (BASE_DAMAGE)
- **Efeito**: Aumenta o dano da base
- **Valores por Raridade**: Mesmos valores do Talismã de Dano

#### 1.6. Talismã de Fortuna (COIN_DROP)
- **Efeito**: Aumenta a chance de drop de moedas
- **Valores por Raridade**: Mesmos valores do Talismã de Dano

#### 1.7. Talismã de Lentidão (ENEMY_SLOW)
- **Efeito**: Reduz a velocidade de todos os inimigos
- **Valores por Raridade**: Mesmos valores do Talismã de Dano

#### 1.8. Talismã de Crítico (CRITICAL_CHANCE)
- **Efeito**: Aumenta a chance de crítico
- **Valores por Raridade**: Mesmos valores do Talismã de Dano

### Probabilidade de Drop
- **Chance Base**: 0.5% (TALISMAN_DROP_CHANCE = 0.005)
- **Tempo de Vida**: 60 segundos no chão antes de desaparecer
- **Raio de Coleta**: 25 pixels

### Sistema de Venda
Talismãs podem ser vendidos por esmeraldas, com valores baseados na raridade:
- **Comum**: 1 esmeralda
- **Incomum**: 2 esmeraldas
- **Raro**: 5 esmeraldas
- **Épico**: 10 esmeraldas
- **Lendário**: 25 esmeraldas

---

## 2. EVENTOS CLIMÁTICOS

### Descrição
O clima muda periodicamente, afetando torres, inimigos e visibilidade. Cada clima dura 3 waves e muda a cada 5 waves.

### Intervalo de Mudança
- **Intervalo**: A cada 5 waves (WEATHER_CHANGE_INTERVAL = 5)
- **Duração**: 3 waves (WEATHER_DURATION_WAVES = 3)
- **Probabilidade de Cada Tipo**: Equiprovável (1/7 ≈ 14.3% cada)

### Tipos de Clima

#### 2.1. 🌫️ NÉVOA (FOG)
- **Efeitos Mecânicos**:
  - Alcance das torres: -20%
- **Efeitos Visuais**:
  - Nuvens cinzas espalhadas pelo labirinto
  - Opacidade variável por nuvem (0.3-0.6)
  - Múltiplos círculos sobrepostos para efeito 3D
- **Probabilidade**: 1/7 (≈14.3%)

#### 2.2. 🌙 NOITE (NIGHT)
- **Efeitos Mecânicos**:
  - Alcance das torres: -30%
  - Velocidade dos inimigos: +10%
  - Visibilidade dos monstros: -40% (opacidade reduzida a 60%)
- **Efeitos Visuais**:
  - Overlay escuro azulado sobre o labirinto (60% opacidade)
  - Cor: `Color(0.05, 0.05, 0.15, 0.6)`
  - Monstros ficam por baixo do overlay (mais difíceis de ver)
  - Monstros com cor escurecida e opacidade reduzida
- **Probabilidade**: 1/7 (≈14.3%)

#### 2.3. 🌧️ CHUVA (RAIN)
- **Efeitos Mecânicos**:
  - Dano das torres: -15%
  - Alcance das torres: -10%
- **Efeitos Visuais**:
  - Partículas de chuva animadas (linhas verticais)
  - 80 partículas simultâneas
  - Cor azul claro (`Color(0.6, 0.8, 1.0, 0.7)`)
  - Linhas com leve brilho
- **Probabilidade**: 1/7 (≈14.3%)

#### 2.4. ☀️ CALOR (HEAT)
- **Efeitos Mecânicos**:
  - Velocidade dos inimigos: +25%
  - HP dos inimigos: +15%
- **Efeitos Visuais**: Nenhum efeito visual específico
- **Probabilidade**: 1/7 (≈14.3%)

#### 2.5. ⛈️ TEMPESTADE (STORM)
- **Efeitos Mecânicos**:
  - Dano das torres: -20%
  - Alcance das torres: -15%
  - Velocidade dos inimigos: +10%
  - Precisão das torres: -10%
- **Efeitos Visuais**: Combinação de chuva e vento (sem implementação específica de raios)
- **Probabilidade**: 1/7 (≈14.3%)

#### 2.6. 💨 VENTO (WIND)
- **Efeitos Mecânicos**:
  - Precisão das torres: -15%
- **Efeitos Visuais**: Nenhum efeito visual específico
- **Probabilidade**: 1/7 (≈14.3%)

#### 2.7. ❄️ NEVE (SNOW)
- **Efeitos Mecânicos**:
  - Velocidade de todos: -15% (inimigos e projéteis)
- **Efeitos Visuais**:
  - 150 partículas de neve (flocos)
  - Cada floco: círculo branco com 3 linhas cruzadas
  - Rotação dinâmica
  - Reposicionamento quando saem do labirinto
- **Probabilidade**: 1/7 (≈14.3%)

### Sistema de Alertas
- **Duração do Alerta**: 2 segundos
- **Posição**: Topo do labirinto (centro horizontal, offset 60px do topo)
- **Opacidade**: 0.85 (leve transparência)
- **Tamanho da Fonte**: 32px

---

## 3. WAVES ESPECIAIS

### Descrição
A cada 10 waves, uma wave especial aparece com modificadores únicos. Cada tipo tem efeitos diferentes nos inimigos e recompensas.

### Intervalo
- **Intervalo**: A cada 10 waves (SPECIAL_WAVE_INTERVAL = 10)
- **Duração**: 1 wave apenas
- **Probabilidade de Cada Tipo**: Equiprovável (1/6 ≈ 16.7% cada)

### Tipos de Waves Especiais

#### 3.1. 🌙 HORDA NOTURNA (NIGHT_HORDE)
- **Efeitos Mecânicos**:
  - Quantidade de inimigos: 2x
  - Multiplicador de moedas: 1.5x
- **Efeitos Visuais**:
  - Alerta especial no centro da tela
  - Duração: 2 segundos (1s visível + 1s fade out)
- **Probabilidade**: 1/6 (≈16.7%)

#### 3.2. 💰 MOEDAS DUPLAS (DOUBLE_COINS)
- **Efeitos Mecânicos**:
  - Todos os inimigos dão 2x moedas
  - Multiplicador de moedas: 2.0x
- **Efeitos Visuais**: Alerta especial
- **Probabilidade**: 1/6 (≈16.7%)

#### 3.3. ⚡ VELOCIDADE MÁXIMA (MAX_SPEED)
- **Efeitos Mecânicos**:
  - Inimigos: +50% velocidade
  - Multiplicador de moedas: 2.0x
- **Efeitos Visuais**: Alerta especial
- **Probabilidade**: 1/6 (≈16.7%)

#### 3.4. 🛡️ BOSS RUSH
- **Efeitos Mecânicos**:
  - Apenas bosses spawnam (4 bosses)
  - Nenhum inimigo normal
  - Multiplicador de moedas: 3.0x
- **Efeitos Visuais**: Alerta especial
- **Probabilidade**: 1/6 (≈16.7%)

#### 3.5. 🎯 WAVE PERFEITA (PERFECT_WAVE)
- **Efeitos Mecânicos**:
  - Bônus especial: 5 esmeraldas se completar sem perder HP da base
  - Multiplicador de moedas: 1.0x (normal)
- **Efeitos Visuais**: Alerta especial
- **Probabilidade**: 1/6 (≈16.7%)

#### 3.6. 🔥 ONDA DO INFERNO (HELL_WAVE)
- **Efeitos Mecânicos**:
  - Inimigos com HP baixo mas velocidade alta
  - Multiplicador de moedas: 1.5x
- **Efeitos Visuais**: Alerta especial
- **Probabilidade**: 1/6 (≈16.7%)

### Sistema de Alertas
- **Duração Total**: 2 segundos
- **Fade Out Inicia**: Após 1 segundo
- **Posição**: Centro da tela
- **Cor**: Amarelo dourado (`Color(1.0, 0.8, 0.2, 1.0)`)
- **Outline**: Preto com 90% opacidade

---

## 4. PERKS (MELHORIAS PERMANENTES)

Perks são melhorias compradas com pontos de achievements e persistem entre sessões.

### Categorias

#### 4.1. STARTING (Início do Jogo)

##### Moedas Iniciais +50
- **Descrição**: Comece cada partida com 50 moedas extras
- **Custo**: 50 pontos
- **Níveis Máximos**: 5
- **Efeito**: +50 moedas por nível
- **Ícone**: 💰

##### Moedas Iniciais +100
- **Descrição**: Comece cada partida com 100 moedas extras
- **Custo**: 100 pontos
- **Níveis Máximos**: 1
- **Requisito**: Moedas Iniciais +50 nível 5
- **Efeito**: +100 moedas
- **Ícone**: 💎

##### Vida Extra
- **Descrição**: Base começa com +20 HP
- **Custo**: 75 pontos
- **Níveis Máximos**: 3
- **Efeito**: +20 HP por nível (até +60 HP)
- **Ícone**: ❤️

#### 4.2. ECONOMY (Economia)

##### Sorte do Tesouro
- **Descrição**: +2.5% de chance de inimigos droparem moedas por nível
- **Custo**: 80 pontos
- **Níveis Máximos**: 4
- **Efeito**: +2.5% por nível (até +10%)
- **Ícone**: 🍀

##### Moedas Valiosas
- **Descrição**: Moedas valem +2 a +5
- **Custo**: 100 pontos
- **Níveis Máximos**: 3
- **Efeito**: +2 por nível
- **Ícone**: 💵

##### Desconto de Construção
- **Descrição**: -10% no custo de todas as torres
- **Custo**: 150 pontos
- **Níveis Máximos**: 2
- **Efeito**: -10% por nível (até -20%)
- **Ícone**: 🏗️

##### Magnetismo de Moedas e Itens
- **Descrição**: Coleta moedas e itens automaticamente ao passar o mouse sobre eles
- **Custo**: 300 pontos
- **Níveis Máximos**: 1
- **Efeito**: Coleta automática ativada
- **Ícone**: 🧲

#### 4.3. COMBAT (Combate)

##### Herói Forte
- **Descrição**: +10% de dano do herói
- **Custo**: 100 pontos
- **Níveis Máximos**: 5
- **Efeito**: +10% por nível (até +50%)
- **Ícone**: ⚔️

##### Herói Rápido
- **Descrição**: +10% de velocidade de tiro do herói
- **Custo**: 100 pontos
- **Níveis Máximos**: 5
- **Efeito**: +10% por nível (até +50%)
- **Ícone**: 🎯

##### Torres Poderosas
- **Descrição**: +5% de dano de todas as torres
- **Custo**: 120 pontos
- **Níveis Máximos**: 4
- **Efeito**: +5% por nível (até +20%)
- **Ícone**: 🏰

#### 4.4. DEFENSE (Defesa)

##### Muros Reforçados
- **Descrição**: +20% de HP dos muros
- **Custo**: 90 pontos
- **Níveis Máximos**: 3
- **Efeito**: +20% por nível (até +60%)
- **Ícone**: 🧱

##### Alcance Estendido
- **Descrição**: +10% de alcance de todas as torres
- **Custo**: 150 pontos
- **Níveis Máximos**: 3
- **Efeito**: +10% por nível (até +30%)
- **Ícone**: 📡

##### Regeneração da Base
- **Descrição**: Base regenera 1 HP por minuto
- **Custo**: 200 pontos
- **Níveis Máximos**: 1
- **Efeito**: 1 HP/minuto
- **Ícone**: 💚

---

## 5. PRESTÍGIO (Prestige Shop)

O sistema de prestígio permite comprar melhorias permanentes usando esmeraldas (moeda de sessão) e diamantes (moeda persistente).

### Moeda: Esmeraldas (💎)
- **Valor em Moedas**: 100 moedas por esmeralda (EMERALD_VALUE_IN_COINS = 100)
- **Tipo**: Sessão (reseta ao fechar o jogo)
- **Ícone**: 💎 (pedra verde)
- **Como Obter**:
  - Drop aleatório a partir da wave 50 (4% de chance)
  - Boss especial a cada 25 waves (20 esmeraldas garantidas)
  - Vender talismãs

### Moeda: Diamantes (💠)
- **Tipo**: Persistente (mantém entre sessões)
- **Como Obter**:
  - Drop aleatório a partir da wave 150 (0.1% de chance)
  - Wave 150: 1 diamante garantido

### Melhorias com Esmeraldas

#### Moedas Iniciais (+20 por nível)
- **Custo**: 2 esmeraldas por nível
- **Níveis Máximos**: 5
- **Efeito Total**: +100 moedas iniciais

#### Chance de Drop de Moedas (+5% por nível)
- **Custo**: 3 esmeraldas por nível
- **Níveis Máximos**: 3
- **Efeito Total**: +15% chance de drop

#### Dano do Herói (+10% por nível)
- **Custo**: 5 esmeraldas por nível
- **Níveis Máximos**: 3
- **Efeito Total**: +30% dano

#### Velocidade de Tiro do Herói (+10% por nível)
- **Custo**: 4 esmeraldas por nível
- **Níveis Máximos**: 3
- **Efeito Total**: +30% velocidade

#### HP da Base (+10 por nível)
- **Custo**: 3 esmeraldas por nível
- **Níveis Máximos**: 5
- **Efeito Total**: +50 HP

#### Torre Especial (Desbloqueio)
- **Custo**: 10 esmeraldas
- **Efeito**: Desbloqueia torre especial

### Melhorias com Diamantes

#### Reset de Prestígio
- **Custo**: 5 diamantes
- **Efeito**: Permite resetar progresso com bônus acumulado

#### Modo Especial
- **Custo**: 1 diamante
- **Efeito**: Desbloqueia modo especial

#### Upgrade Permanente de Todas as Torres
- **Custo**: 2 diamantes
- **Efeito**: Melhora permanente de todas as torres

#### Multiplicador de Recompensas (+10% por nível)
- **Custo**: 3 diamantes por nível
- **Efeito**: +10% por nível

#### Torre Lendária
- **Custo**: 5 diamantes
- **Efeito**: Desbloqueia torre lendária

#### Boost de HP da Base (+20 por nível)
- **Custo**: 8 diamantes por nível
- **Efeito**: +20 HP por nível

#### Boost de Dano do Herói (+15% por nível)
- **Custo**: 10 diamantes por nível
- **Efeito**: +15% por nível

#### Boost de Chance de Drop de Moedas (+3% por nível)
- **Custo**: 12 diamantes por nível
- **Efeito**: +3% por nível

#### Boost de Moedas Iniciais (+50 por nível)
- **Custo**: 15 diamantes por nível
- **Efeito**: +50 moedas por nível

---

## 6. OUTRAS MECÂNICAS

### Sistema de Upgrade de Torres
- Todas as torres podem ser melhoradas com moedas ou esmeraldas
- Upgrades com esmeraldas são mais poderosos
- Custo de esmeraldas escala: `base_cost * (1.2 ^ level)`

### Sistema de Muralhas
- Muralhas podem ser construídas para bloquear inimigos
- Inimigos param e atacam muralhas ao invés de recalcular caminho
- Muralhas podem ser melhoradas individualmente
- Sistema de reparo disponível

### Sistema de Minas
- Minas explodem quando inimigos se aproximam
- Upgrade global de dano e raio de explosão disponível
- Aplicado a todas as minas ativas

### Sistema de Castelo (Hero Home)
- 4 níveis de upgrade disponíveis
- Benefícios acumulativos por nível
- Custo escalonado por nível

### Sistema de Cura
- Estações de cura regeneram HP da base
- Respeita o HP máximo (incluindo todos os bônus)

---

## RESUMO DE PROBABILIDADES

### Talismãs
- **Chance de Drop**: 0.5% por inimigo morto
- **Raridade**: Distribuição igual (20% cada)

### Eventos Climáticos
- **Mudança**: A cada 5 waves
- **Duração**: 3 waves
- **Probabilidade de Cada Tipo**: 1/7 (≈14.3%)

### Waves Especiais
- **Intervalo**: A cada 10 waves
- **Probabilidade de Cada Tipo**: 1/6 (≈16.7%)

### Esmeraldas
- **Drop Chance**: 4% a partir da wave 50
- **Boss Especial**: 20 esmeraldas a cada 25 waves

### Diamantes
- **Drop Chance**: 0.1% a partir da wave 150
- **Wave 150**: 1 diamante garantido

---

---

## 7. REVISÃO DO SISTEMA DE TORRES

### Torres Básicas
- **Update**: Aplicam boost de rate de boost towers e skill de velocidade
- **Fire Rate Mínimo**: 0.4s (TOWER_MIN_FIRE_RATE)
- **Aplicam**: Multiplicadores de clima (dano e alcance), boost towers, skills

### Torres AOE
- **Update**: Mesmo sistema das básicas
- **Fire Rate Mínimo**: 1.8s (AOE_MIN_FIRE_RATE)
- **Projéteis**: Bolas pretas que explodem em área

### Torres Sniper
- **Update**: Mesmo sistema das básicas
- **Fire Rate Mínimo**: 1.5s (SNIPER_MIN_FIRE_RATE)
- **Pierce**: Atravessa múltiplos inimigos em linha

### Torres Shock
- **Update**: Mesmo sistema das básicas
- **Fire Rate Mínimo**: 0.8s (SHOCK_MIN_FIRE_RATE)
- **Chain**: Efeito de corrente elétrica entre inimigos próximos

### Torres Slow
- **Update**: Aplicam slow continuamente enquanto inimigos estão no alcance
- **Sem cooldown**: Efeito permanente enquanto dentro do alcance
- **Slow Máximo**: 50%

### Torres Boost
- **Update**: Não precisam de update (efeito passivo)
- **Efeito**: Aumentam dano e cadência de torres próximas

---

*Documento atualizado em: 2024*
