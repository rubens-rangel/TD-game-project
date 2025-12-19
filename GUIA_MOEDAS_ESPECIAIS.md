# 💎 Guia de Integração: Sistema de Moedas Especiais

## ✅ O que foi implementado

### 1. **SpecialCurrencyManager.gd**
- Gerencia Esmeraldas e Diamantes
- Sistema de save/load automático
- Estatísticas de ganhos/gastos
- Funções para verificar drops em waves altas

### 2. **PrestigeShop.gd**
- Loja de melhorias permanentes
- Compras com Esmeraldas e Diamantes
- Sistema de níveis e desbloqueios
- Save/load automático

### 3. **QuestManager.gd** (Modificado)
- Agora retorna moedas especiais como recompensa:
  - Semanais: 1 Esmeralda
  - Mensais: 3 Esmeraldas + 1 Diamante

### 4. **Constants.gd** (Atualizado)
- Todas as constantes de moedas especiais
- Custos de melhorias
- Taxas de drop

### 5. **Game.gd** (Integrado)
- Inicialização dos managers
- Drops de moedas especiais em waves altas
- Aplicação de bônus de prestígio

## 🔧 Como Funciona

### Drops de Moedas Especiais

**Esmeraldas:**
- Wave 100+: 1% de chance por kill
- Boss a cada 25 waves: 1 Esmeralda garantida

**Diamantes:**
- Wave 150+: 0.5% de chance por kill

### Recompensas de Quests

**Diárias:** 50 moedas (sem mudança)
**Semanais:** 100 moedas + 1 Esmeralda
**Mensais:** 500 moedas + 3 Esmeraldas + 1 Diamante

## 📝 Próximos Passos (Ainda Pendentes)

### 1. Integrar Recompensas de Quests no Menu
O Menu.gd precisa dar as moedas especiais quando quests são reivindicadas. Como o Menu não tem acesso direto ao Game, você pode:

**Opção A:** Usar singleton/autoload
```gdscript
# Criar autoload SpecialCurrencyManager no project.godot
# Então no Menu.gd:
SpecialCurrencyManager.add_emeralds(result.reward_emeralds, "quest")
SpecialCurrencyManager.add_diamonds(result.reward_diamonds, "quest")
```

**Opção B:** Salvar em arquivo temporário
```gdscript
# No Menu.gd, salvar recompensas em arquivo
# No Game.gd, carregar e aplicar ao iniciar
```

### 2. Criar UI para Moedas Especiais
Adicionar no HUD do Game.gd:
```gdscript
# Mostrar: "Moedas: 1500 | 💚 Esmeraldas: 5 | 💎 Diamantes: 2"
```

### 3. Criar Loja de Prestígio
Criar UI para comprar melhorias permanentes com moedas especiais.

### 4. Aplicar Bônus de Prestígio
Os bônus já são aplicados no `_apply_prestige_bonuses()`, mas você pode querer:
- Mostrar notificações quando bônus são aplicados
- Adicionar mais tipos de bônus
- Integrar com sistema de prestígio/reset

## 🎮 Melhorias Disponíveis

### Com Esmeraldas:
- **Moedas Iniciais**: +20 por nível (máx 5) - 2 Esmeraldas/nível
- **Chance de Drop**: +5% por nível (máx 3) - 3 Esmeraldas/nível
- **Dano do Herói**: +10% por nível (máx 3) - 5 Esmeraldas/nível
- **Velocidade de Tiro**: +10% por nível (máx 3) - 4 Esmeraldas/nível
- **HP da Base**: +10 por nível (máx 5) - 3 Esmeraldas/nível
- **Torre Especial**: Desbloquear - 10 Esmeraldas

### Com Diamantes:
- **Reset de Prestígio**: 5 Diamantes
- **Upgrade Todas Torres**: 3 Diamantes
- **Modo Especial**: 2 Diamantes cada
- **Multiplicador de Recompensas**: +10% por nível - 10 Diamantes/nível
- **Torre Lendária**: 15 Diamantes

## ⚙️ Balanceamento

Valores podem ser ajustados em `Constants.gd`:
- `EMERALD_DROP_CHANCE`: Chance de drop (padrão: 1%)
- `DIAMOND_DROP_CHANCE`: Chance de drop (padrão: 0.5%)
- `QUEST_REWARD_WEEKLY_EMERALDS`: Esmeraldas semanais (padrão: 1)
- `QUEST_REWARD_MONTHLY_EMERALDS`: Esmeraldas mensais (padrão: 3)
- `QUEST_REWARD_MONTHLY_DIAMONDS`: Diamantes mensais (padrão: 1)

## 📊 Arquivos Criados/Modificados

✅ **Criados:**
- `godot/scripts/managers/SpecialCurrencyManager.gd`
- `godot/scripts/managers/PrestigeShop.gd`

✅ **Modificados:**
- `godot/scripts/Constants.gd` - Constantes adicionadas
- `godot/scripts/managers/QuestManager.gd` - Recompensas atualizadas
- `godot/scripts/Game.gd` - Integração de drops e bônus
- `godot/scripts/Menu.gd` - UI de quests atualizada (parcial)

## 🎯 Status

- ✅ Sistema de moedas especiais criado
- ✅ Sistema de prestígio criado
- ✅ Drops em waves altas implementados
- ✅ Bônus de prestígio aplicados
- ⏳ UI de moedas especiais no HUD (pendente)
- ⏳ Loja de prestígio (pendente)
- ⏳ Integração completa de recompensas de quests (pendente)

---

**Pronto para uso!** O sistema básico está funcionando. Falta apenas criar a UI e integrar completamente as recompensas de quests.

