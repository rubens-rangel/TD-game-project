# 🎯 Exemplo de Implementação: Sistema de Combos

Este documento mostra como integrar o `ComboManager` no jogo.

## 📋 O que foi criado

1. **Constants.gd** - Adicionadas constantes para o sistema de combo
2. **ComboManager.gd** - Manager completo para gerenciar combos

## 🔧 Como Integrar no Game.gd

### Passo 1: Adicionar o ComboManager

No início do arquivo `Game.gd`, adicione:

```gdscript
const ComboManager = preload("res://scripts/managers/ComboManager.gd")

# Na seção de variáveis, adicione:
var combo_manager: ComboManager
```

### Passo 2: Inicializar o ComboManager

Na função `_ready()` ou onde você inicializa os managers:

```gdscript
combo_manager = ComboManager.new()
```

### Passo 3: Atualizar o Combo no Loop Principal

Na função `_process(delta)` ou `_physics_process(delta)`, adicione:

```gdscript
# Atualiza o timer do combo
if combo_manager:
    var combo_lost = combo_manager.update(delta)
    if combo_lost:
        # Opcional: Mostrar notificação de combo perdido
        show_combo_lost_notification()
```

### Passo 4: Registrar Kills no Combo

Onde você processa a morte de inimigos (provavelmente na função que dá recompensas), adicione:

```gdscript
# Quando um inimigo morre, antes de dar a recompensa:
if combo_manager:
    var combo_info = combo_manager.add_kill()
    
    # Aplica multiplicador à recompensa base
    var base_reward = get_enemy_reward()  # ou get_boss_reward() para bosses
    var final_reward = combo_manager.apply_reward_multiplier(base_reward)
    
    # Adiciona bônus de combo
    final_reward += combo_info.coin_bonus
    
    # Bônus extra em marcos (10, 20, 30, etc)
    if combo_info.is_milestone:
        final_reward += combo_info.milestone_bonus
        show_milestone_notification(combo_info.combo)
    
    # Dá a recompensa final
    hero.coins += final_reward
    total_coins_collected += final_reward
    
    # Mostra feedback visual do combo
    if combo_info.combo >= GameConstants.COMBO_MIN_KILLS:
        show_combo_notification(combo_info.combo, combo_info.multiplier)
```

### Passo 5: Mostrar Combo na UI

Adicione um elemento visual na UI para mostrar o combo atual:

```gdscript
# Variável para o label de combo
var combo_label: Label = null

# Na função que cria a UI, adicione:
func create_combo_ui():
    combo_label = Label.new()
    combo_label.name = "ComboLabel"
    combo_label.add_theme_color_override("font_color", GameConstants.COLOR_UI_GOLD)
    combo_label.add_theme_font_size_override("font_size", 24)
    combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    combo_label.visible = false
    # Adicione ao HUD
    # Exemplo: hud.add_child(combo_label)

# Na função de atualização da UI (_process ou similar):
func update_combo_ui():
    if combo_manager and combo_label:
        var combo_info = combo_manager.get_combo_info()
        if combo_info.is_active:
            combo_label.text = combo_manager.get_combo_text()
            combo_label.visible = true
            # Opcional: Animação de pulo/zoom quando combo aumenta
        else:
            combo_label.visible = false
```

### Passo 6: Notificações Visuais (Opcional)

Crie funções para mostrar notificações de combo:

```gdscript
func show_combo_notification(combo: int, multiplier: float):
    """Mostra notificação quando combo aumenta"""
    # Exemplo: Criar label flutuante
    var notification = Label.new()
    notification.text = "COMBO x%d (x%.1f)" % [combo, multiplier]
    notification.add_theme_color_override("font_color", Color.YELLOW)
    notification.add_theme_font_size_override("font_size", 32)
    # Posicionar no centro da tela ou próximo ao combo_label
    # Adicionar animação de fade out
    # Remover após alguns segundos

func show_milestone_notification(combo: int):
    """Mostra notificação especial em marcos (10, 20, 30, etc)"""
    var notification = Label.new()
    notification.text = "MARCO! COMBO x%d!" % combo
    notification.add_theme_color_override("font_color", Color.GOLD)
    notification.add_theme_font_size_override("font_size", 40)
    # Animação especial (pulando, brilhando, etc)
```

### Passo 7: Resetar Combo Entre Waves (Opcional)

Se quiser resetar o combo entre waves:

```gdscript
# Quando uma wave termina:
if combo_manager:
    combo_manager.reset_combo()
```

## 🎨 Melhorias Visuais Sugeridas

1. **Barra de Progresso do Timer**: Mostrar quanto tempo resta antes de perder o combo
2. **Efeitos de Partículas**: Partículas brilhantes quando combo aumenta
3. **Sons**: Som especial quando combo atinge marcos
4. **Animação de Números**: Números que "pulam" quando combo aumenta
5. **Cores Dinâmicas**: Cores que mudam conforme o combo aumenta (verde → amarelo → laranja → vermelho)

## ⚙️ Balanceamento

Ajuste as constantes em `Constants.gd` conforme necessário:

- `COMBO_TIMEOUT`: Tempo para perder combo (padrão: 3.0s)
- `COMBO_MIN_KILLS`: Mínimo para ativar (padrão: 3)
- `COMBO_MULTIPLIER_PER_KILL`: Aumento por kill (padrão: 0.1 = 10%)
- `COMBO_MAX_MULTIPLIER`: Cap máximo (padrão: 5.0 = 500%)
- `COMBO_COIN_BONUS_PER_KILL`: Moedas extras por kill (padrão: 1)
- `COMBO_MILESTONE_BONUS`: Bônus em marcos (padrão: 10)

## 📝 Exemplo Completo de Integração

```gdscript
# No Game.gd

# 1. Adicionar import
const ComboManager = preload("res://scripts/managers/ComboManager.gd")

# 2. Adicionar variável
var combo_manager: ComboManager

# 3. Inicializar
func _ready():
    combo_manager = ComboManager.new()
    # ... resto da inicialização

# 4. Atualizar no loop
func _process(delta):
    if combo_manager:
        combo_manager.update(delta)
    update_combo_ui()

# 5. Registrar kill (exemplo onde inimigo morre)
func on_enemy_killed(enemy_pos: Vector2, is_boss: bool = false):
    if combo_manager:
        var combo_info = combo_manager.add_kill()
        var base_reward = get_boss_reward() if is_boss else get_enemy_reward()
        var final_reward = combo_manager.apply_reward_multiplier(base_reward)
        final_reward += combo_info.coin_bonus
        
        if combo_info.is_milestone:
            final_reward += combo_info.milestone_bonus
            show_milestone_notification(combo_info.combo)
        
        hero.coins += final_reward
        
        if combo_info.combo >= GameConstants.COMBO_MIN_KILLS:
            show_combo_notification(combo_info.combo, combo_info.multiplier)
```

## ✅ Próximos Passos

1. Integre o código acima no `Game.gd`
2. Teste o sistema de combos
3. Ajuste os valores de balanceamento conforme necessário
4. Adicione efeitos visuais e sonoros
5. Teste com diferentes cenários de jogo

## 🎮 Dicas

- Comece com valores conservadores e ajuste baseado no feedback
- Teste em diferentes waves para garantir que o balanceamento funciona
- Considere adicionar achievements relacionados a combos (ex: "Alcance combo de 50")
- O sistema de combo torna o jogo mais dinâmico e recompensa jogadores habilidosos!



