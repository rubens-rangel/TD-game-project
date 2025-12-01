# 🧱💰 Mudanças: Custo Acumulativo de Muralhas e Fire Rate da Sniper Tower

## 📋 Resumo

Implementação de custo acumulativo para muralhas e redução do fire_rate da sniper tower para melhor balanceamento.

---

## ✅ Mudanças Implementadas

### 1. Custo Acumulativo de Muralhas

**Problema Anterior:**
- Todas as muralhas custavam o mesmo valor fixo: 50 moedas
- Não havia incentivo estratégico para economizar muralhas

**Solução Implementada:**
- Custo acumulativo baseado no número de muralhas já construídas
- Primeira muralha: **100 moedas**
- Segunda muralha: **300 moedas** (3x mais cara)
- Terceira muralha: **600 moedas** (2x mais cara que a anterior)
- Quarta muralha: **1000 moedas** (última disponível)

**Escala de Custo:**
| Muralha | Custo | Incremento |
|---------|-------|------------|
| 1ª      | 100   | Base       |
| 2ª      | 300   | +200 (3x)  |
| 3ª      | 600   | +300 (2x)  |
| 4ª      | 1000  | +400       |

**Implementação Técnica:**
- Nova função `get_wall_cost()` em `Game.gd` que calcula o custo baseado em `walls.size()`
- Função `_update_tower_shop_ui()` atualizada para mostrar custo dinâmico
- Verificações de custo atualizadas em `_on_buy_wall()` e `_try_place_wall()`

**Impacto:**
- ✅ Incentiva estratégia: jogador pensa mais antes de construir muralhas
- ✅ Economia: primeira muralha é barata, mas as seguintes custam mais
- ✅ Balanceamento: evita spam de muralhas no início do jogo

---

### 2. Redução do Fire Rate da Sniper Tower

**Problema Anterior:**
- Fire rate muito lento: **15.0 segundos**
- Não havia boa correlação com o dano alto (8.0)
- DPS muito baixo comparado a outras torres

**Análise de DPS (Dano por Segundo):**
- **Antes (fire_rate = 15.0s):**
  - DPS = 8.0 / 15.0 = **0.53 DPS**
  
- **Comparação com outras torres:**
  - Torre Normal (dano 0.5, fire_rate 1.5s): 0.33 DPS
  - AOE Tower (dano 2.0, fire_rate 2.0s): 1.0 DPS
  - Shock Tower (dano 1.5, fire_rate 1.5s): 1.0 DPS
  - Sniper Tower (dano 8.0, fire_rate 15.0s): 0.53 DPS ❌ (muito baixo)

**Solução Implementada:**
- Fire rate reduzido de **15.0s para 8.0s**
- Mantém o alto dano único (8.0), mas dispara mais frequentemente

**Novo DPS:**
- **Depois (fire_rate = 8.0s):**
  - DPS = 8.0 / 8.0 = **1.0 DPS** ✅
  - Agora está igual ao AOE e Shock Tower

**Comparação de Fire Rates:**
| Torre        | Dano | Fire Rate | DPS    |
|--------------|------|-----------|--------|
| Torre Normal | 0.5  | 1.5s      | 0.33   |
| AOE Tower    | 2.0  | 2.0s      | 1.0    |
| Shock Tower  | 1.5  | 1.5s      | 1.0    |
| Sniper Tower | 8.0  | **8.0s**  | **1.0** ✅ |

**Impacto:**
- ✅ Melhor correlação entre dano e fire rate
- ✅ DPS balanceado com outras torres de alta performance
- ✅ Sniper Tower mais útil e viável no jogo
- ✅ Mantém identidade única (dano alto, mas disparo menos frequente que torres normais)

---

## 📝 Detalhes Técnicos

### Arquivos Modificados:

**`godot/scripts/Game.gd`:**
1. **Nova função `get_wall_cost()`:**
   ```gdscript
   func get_wall_cost() -> int:
       var current_wall_count = walls.size()
       match current_wall_count:
           0: return 100  # Primeira
           1: return 300  # Segunda
           2: return 600  # Terceira
           3: return 1000 # Quarta
           _: return 1000
   ```

2. **Atualizações em:**
   - `_on_buy_wall()`: usa `get_wall_cost()` para verificar custo
   - `_try_place_wall()`: usa `get_wall_cost()` para deduzir moedas
   - `_update_tower_shop_ui()`: atualiza custo dinamicamente no shop
   - Tooltip de muralha: mostra custo atualizado

3. **Fire rate da Sniper Tower:**
   - Alterado de `15.0` para `8.0` segundos na criação da torre

---

## 🎯 Resultados Esperados

### Gameplay

**Muralhas:**
- ✅ Jogador precisa planejar melhor o uso de muralhas
- ✅ Primeira muralha acessível, mas as seguintes são caras
- ✅ Evita spam de muralhas no início do jogo
- ✅ Estratégia mais importante na colocação de muralhas

**Sniper Tower:**
- ✅ DPS balanceado com outras torres de alto desempenho
- ✅ Mais viável para uso estratégico
- ✅ Melhor correlação entre dano e fire rate
- ✅ Mantém identidade única (dano alto, cadência média)

---

## ✅ Status

- ✅ Custo acumulativo de muralhas implementado
- ✅ Fire rate da sniper tower reduzido de 15s para 8s
- ✅ UI atualizada para mostrar custo dinâmico
- ✅ Todas as verificações de custo atualizadas
- ✅ Mudanças testadas e prontas para uso

**Data:** Mudanças implementadas
**Status:** ✅ Concluído

