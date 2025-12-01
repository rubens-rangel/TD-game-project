# ✅ Mudanças: Resetar Melhorias Persistentes (Perks)

## 📋 Resumo

Foi implementado o sistema para resetar melhorias persistentes (perks), com botão na UI e diálogo de confirmação.

---

## ✅ Mudanças Implementadas

### 1. Removido: Resetar Achievements do Menu Admin

**O que foi feito:**
- ❌ Removida a opção "Resetar Achievements" do menu Admin
- ❌ Removida a função `_reset_achievements()` relacionada ao admin

**Arquivos Modificados:**
- `godot/scripts/Game.gd` - Removida opção do menu admin

---

### 2. Adicionado: Resetar Perks (Melhorias Persistentes)

**O que foi feito:**
- ✅ Adicionada função `reset_all_perks()` no `PerkManager`
- ✅ Criado botão "Resetar Melhorias" na UI (HUD)
- ✅ Criado diálogo de confirmação antes de resetar
- ✅ Botão permite ao usuário escolher se quer resetar ou não

**Funcionalidades:**
1. **Botão na UI:** Botão "Resetar Melhorias" no HUD (TopBar)
2. **Diálogo de Confirmação:** Confirmação antes de resetar
3. **Reset Completo:** Reseta todos os perks comprados com pontos de achievements

---

## 🎮 Como Usar

### Resetar Melhorias Persistentes

1. **Localizar o botão:**
   - No HUD (barra superior), procure o botão "Resetar Melhorias"
   - Está posicionado após outros botões (posição X=1120)

2. **Clicar no botão:**
   - Clique em "Resetar Melhorias"
   - Um diálogo de confirmação aparecerá

3. **Confirmar:**
   - Leia o aviso no diálogo
   - Escolha:
     - **"Sim, Resetar"** - Reseta todas as melhorias persistentes
     - **"Cancelar"** - Cancela a operação

4. **Resultado:**
   - Todas as melhorias persistentes (perks) serão resetadas
   - Os pontos de achievements gastos NÃO são recuperados
   - A ação não pode ser desfeita

---

## 📝 Detalhes Técnicos

### Funções Adicionadas

**PerkManager.gd:**
```gdscript
func reset_all_perks() -> void:
    # Reseta todos os perks para nível 0
    # Salva no arquivo
```

**Game.gd:**
```gdscript
func _create_reset_perks_button(tb: Panel) -> void:
    # Cria botão e diálogo de confirmação
    
func _on_reset_perks_button_pressed() -> void:
    # Mostra diálogo de confirmação
    
func _on_reset_perks_confirmed() -> void:
    # Reseta perks e atualiza efeitos
```

### Localização do Botão

- **Posição:** X=1120, Y=8 (na TopBar)
- **Tamanho:** 140x28 pixels
- **Estilo:** Botão vermelho (destrutivo) para indicar ação permanente

### Diálogo de Confirmação

- **Título:** "Resetar Melhorias Persistentes"
- **Mensagem:** Avisa sobre ação permanente e não reversível
- **Botões:**
  - "Sim, Resetar" (confirma)
  - "Cancelar" (cancela)

---

## 🔄 Diferenças: Achievements vs Perks

### Achievements (Não resetáveis)
- ✅ Desbloqueios permanentes
- ✅ Progresso de conquistas
- ✅ Pontos de achievements
- ❌ **NÃO há reset** (permanente)

### Perks (Resetáveis)
- ✅ Melhorias persistentes compradas
- ✅ Compradas com pontos de achievements
- ✅ **PODEM ser resetadas** (novo botão)

---

## ⚠️ Avisos Importantes

1. **Ação Permanente:**
   - Resetar perks não pode ser desfeito
   - Todos os perks voltam ao nível 0
   - Os pontos gastos NÃO são recuperados

2. **Confirmação Necessária:**
   - Sempre pede confirmação antes de resetar
   - Leia o diálogo com atenção

3. **Efeitos Imediatos:**
   - Os efeitos dos perks são removidos imediatamente
   - O jogo atualiza os efeitos após o reset

---

## 📊 Status

- ✅ Função de reset implementada
- ✅ Botão na UI criado
- ✅ Diálogo de confirmação funcionando
- ✅ Opção de resetar achievements removida do admin
- ✅ Tudo testado e funcionando

---

**Data:** Implementação concluída
**Status:** ✅ Pronto para uso

