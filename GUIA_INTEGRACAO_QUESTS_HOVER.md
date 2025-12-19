# 🎯 Guia de Integração: Sistema de Quests e Hover Effects

Este guia mostra como integrar o sistema de Quests (Diárias, Semanais e Mensais) e os Hover Effects nos botões.

## 📋 O que foi criado

1. **Constants.gd** - Adicionadas constantes para quests e hover effects
2. **QuestManager.gd** - Sistema completo de gerenciamento de quests
3. **ButtonHoverHelper.gd** - Helper para adicionar hover effects em botões

## 🔧 Integração no Game.gd

### Passo 1: Adicionar Imports e Variáveis

No início do arquivo `Game.gd`, adicione:

```gdscript
const QuestManager = preload("res://scripts/managers/QuestManager.gd")
const ButtonHoverHelper = preload("res://scripts/helpers/ButtonHoverHelper.gd")

# Na seção de variáveis, adicione:
var quest_manager: QuestManager
var quest_ui_panel: Panel = null
```

### Passo 2: Inicializar o QuestManager

Na função `_ready()` ou onde você inicializa os managers:

```gdscript
quest_manager = QuestManager.new()

# Verifica e atualiza quests periodicamente
check_quest_refresh()
```

### Passo 3: Aplicar Hover Effects nos Botões Existentes

Na função `_ready()` ou onde você cria a UI, adicione:

```gdscript
# Aplica hover effects em todos os botões
func setup_button_hover_effects():
    var buttons = [
        $CanvasLayer/HUD/TopBar/BtnKillAll,
        $CanvasLayer/HUD/TopBar/BtnBuyTower,
        $CanvasLayer/HUD/TopBar/BtnBuyBlock,
        $CanvasLayer/HUD/TopBar/BtnAutoBenefit
    ]
    
    ButtonHoverHelper.setup_multiple_buttons(buttons)
    
    # Para botões criados dinamicamente, aplique individualmente:
    # ButtonHoverHelper.setup_button_hover(meu_botao)
```

### Passo 4: Atualizar Progresso das Quests

Integre o tracking de quests nos eventos do jogo:

```gdscript
# Quando um inimigo morre:
func on_enemy_killed(is_boss: bool = false):
    if quest_manager:
        if is_boss:
            quest_manager.update_quest_progress(GameConstants.QuestType.KILL_BOSSES, 1)
        else:
            quest_manager.update_quest_progress(GameConstants.QuestType.KILL_ENEMIES, 1)

# Quando uma wave é completada:
func on_wave_completed():
    if quest_manager:
        quest_manager.update_quest_progress(GameConstants.QuestType.COMPLETE_WAVES, 1)
        
        # Verifica se foi wave perfeita (sem perder HP)
        if base_hp >= BASE_MAX_HP:
            quest_manager.update_quest_progress(GameConstants.QuestType.PERFECT_WAVES, 1)
        
        # Verifica se alcançou wave específica
        if wave_manager and wave_manager.wave >= 10:
            quest_manager.update_quest_progress(GameConstants.QuestType.REACH_WAVE, wave_manager.wave)

# Quando moedas são coletadas:
func on_coins_collected(amount: int):
    if quest_manager:
        quest_manager.update_quest_progress(GameConstants.QuestType.COLLECT_COINS, amount)

# Quando uma torre é construída:
func on_tower_built():
    if quest_manager:
        quest_manager.update_quest_progress(GameConstants.QuestType.BUILD_TOWERS, 1)

# Quando uma skill é usada:
func on_skill_used():
    if quest_manager:
        quest_manager.update_quest_progress(GameConstants.QuestType.USE_SKILLS, 1)

# Quando moedas são gastas:
func on_coins_spent(amount: int):
    if quest_manager:
        quest_manager.update_quest_progress(GameConstants.QuestType.SPEND_COINS, amount)

# Quando uma torre é upgradeada:
func on_tower_upgraded():
    if quest_manager:
        quest_manager.update_quest_progress(GameConstants.QuestType.UPGRADE_TOWERS, 1)
```

### Passo 5: Verificar Refresh de Quests

Adicione função para verificar refresh periódico:

```gdscript
func check_quest_refresh():
    """Verifica e atualiza quests se necessário"""
    if quest_manager:
        quest_manager.check_and_refresh_quests()
        
        # Verifica novamente após 1 hora (ajuste conforme necessário)
        await get_tree().create_timer(3600.0).timeout
        check_quest_refresh()
```

### Passo 6: Criar UI de Quests

Crie uma função para mostrar as quests ativas:

```gdscript
func create_quest_ui():
    """Cria UI para mostrar quests"""
    if not quest_manager:
        return
    
    # Cria painel de quests
    quest_ui_panel = Panel.new()
    quest_ui_panel.name = "QuestPanel"
    quest_ui_panel.custom_minimum_size = Vector2(300, 400)
    quest_ui_panel.position = Vector2(10, 60)  # Abaixo da top bar
    
    # Adiciona ao HUD
    var hud = $CanvasLayer/HUD
    hud.add_child(quest_ui_panel)
    
    # Título
    var title = Label.new()
    title.text = "Quests"
    title.add_theme_font_size_override("font_size", 20)
    title.position = Vector2(10, 10)
    quest_ui_panel.add_child(title)
    
    # Botão para abrir/fechar
    var toggle_button = Button.new()
    toggle_button.text = "Quests"
    toggle_button.position = Vector2(10, 50)
    toggle_button.pressed.connect(_toggle_quest_panel)
    ButtonHoverHelper.setup_button_hover(toggle_button)
    hud.add_child(toggle_button)
    
    update_quest_ui()

func _toggle_quest_panel():
    """Abre/fecha painel de quests"""
    if quest_ui_panel:
        quest_ui_panel.visible = not quest_ui_panel.visible

func update_quest_ui():
    """Atualiza UI das quests"""
    if not quest_manager or not quest_ui_panel:
        return
    
    # Limpa quests antigas (exceto título e botões)
    for child in quest_ui_panel.get_children():
        if child.name.begins_with("Quest"):
            child.queue_free()
    
    var y_offset = 50
    var all_quests = quest_manager.get_all_active_quests()
    
    # Quests Diárias
    var daily_label = Label.new()
    daily_label.name = "QuestDailyLabel"
    daily_label.text = "--- Diárias ---"
    daily_label.position = Vector2(10, y_offset)
    daily_label.add_theme_font_size_override("font_size", 16)
    quest_ui_panel.add_child(daily_label)
    y_offset += 30
    
    for quest in all_quests.daily:
        var quest_ui = create_quest_item(quest, y_offset)
        quest_ui_panel.add_child(quest_ui)
        y_offset += 80
    
    # Quests Semanais
    var weekly_label = Label.new()
    weekly_label.name = "QuestWeeklyLabel"
    weekly_label.text = "--- Semanais ---"
    weekly_label.position = Vector2(10, y_offset)
    weekly_label.add_theme_font_size_override("font_size", 16)
    quest_ui_panel.add_child(weekly_label)
    y_offset += 30
    
    for quest in all_quests.weekly:
        var quest_ui = create_quest_item(quest, y_offset)
        quest_ui_panel.add_child(quest_ui)
        y_offset += 80
    
    # Quests Mensais
    var monthly_label = Label.new()
    monthly_label.name = "QuestMonthlyLabel"
    monthly_label.text = "--- Mensais ---"
    monthly_label.position = Vector2(10, y_offset)
    monthly_label.add_theme_font_size_override("font_size", 16)
    quest_ui_panel.add_child(monthly_label)
    y_offset += 30
    
    for quest in all_quests.monthly:
        var quest_ui = create_quest_item(quest, y_offset)
        quest_ui_panel.add_child(quest_ui)
        y_offset += 80

func create_quest_item(quest: Dictionary, y_pos: float) -> Control:
    """Cria item de UI para uma quest"""
    var container = Panel.new()
    container.name = "QuestItem_%s" % quest.id
    container.custom_minimum_size = Vector2(280, 70)
    container.position = Vector2(10, y_pos)
    
    # Ícone
    var icon = Label.new()
    icon.text = quest.icon
    icon.position = Vector2(5, 5)
    icon.add_theme_font_size_override("font_size", 24)
    container.add_child(icon)
    
    # Nome e descrição
    var name_label = Label.new()
    name_label.text = quest.name
    name_label.position = Vector2(35, 5)
    name_label.add_theme_font_size_override("font_size", 14)
    container.add_child(name_label)
    
    var desc_label = Label.new()
    desc_label.text = quest.description
    desc_label.position = Vector2(35, 25)
    desc_label.add_theme_font_size_override("font_size", 12)
    container.add_child(desc_label)
    
    # Progresso
    var progress_label = Label.new()
    var progress_text = "%d / %d" % [quest.current, quest.target]
    progress_label.text = progress_text
    progress_label.position = Vector2(35, 45)
    progress_label.add_theme_font_size_override("font_size", 12)
    container.add_child(progress_label)
    
    # Barra de progresso
    var progress_bar = ProgressBar.new()
    progress_bar.min_value = 0
    progress_bar.max_value = quest.target
    progress_bar.value = quest.current
    progress_bar.position = Vector2(5, 60)
    progress_bar.custom_minimum_size = Vector2(270, 5)
    container.add_child(progress_bar)
    
    # Botão de reivindicar (se completada)
    if quest.status == QuestManager.QuestStatus.COMPLETED:
        var claim_button = Button.new()
        claim_button.text = "Reivindicar"
        claim_button.position = Vector2(180, 35)
        claim_button.custom_minimum_size = Vector2(90, 25)
        claim_button.pressed.connect(_claim_quest.bind(quest.id))
        ButtonHoverHelper.setup_button_hover(claim_button)
        container.add_child(claim_button)
    
    return container

func _claim_quest(quest_id: String):
    """Reivindica recompensa de uma quest"""
    if not quest_manager:
        return
    
    var result = quest_manager.claim_quest(quest_id)
    if result.success:
        # Dá recompensa
        hero.coins += result.reward
        total_coins_collected += result.reward
        
        # Atualiza UI
        update_quest_ui()
        
        # Mostra notificação
        show_notification("Quest completada! +%d moedas" % result.reward)
```

### Passo 7: Atualizar UI Periodicamente

No `_process()` ou `_physics_process()`, adicione:

```gdscript
func _process(delta):
    # ... código existente ...
    
    # Atualiza UI de quests periodicamente (a cada segundo)
    if Engine.get_process_frames() % 60 == 0:  # A cada 60 frames (~1 segundo)
        if quest_manager:
            quest_manager.check_and_refresh_quests()
            if quest_ui_panel and quest_ui_panel.visible:
                update_quest_ui()
```

## 🎨 Melhorias Visuais Sugeridas

1. **Ícones de Quest**: Use sprites ao invés de emojis
2. **Animações**: Animações quando quest é completada
3. **Sons**: Sons ao completar/reivindicar quests
4. **Notificações**: Notificações quando quests são atualizadas
5. **Cores**: Cores diferentes para cada tipo de quest

## ⚙️ Balanceamento

Ajuste as constantes em `Constants.gd` conforme necessário:

- `QUEST_DAILY_COUNT`: Número de quests diárias (padrão: 3)
- `QUEST_WEEKLY_COUNT`: Número de quests semanais (padrão: 2)
- `QUEST_MONTHLY_COUNT`: Número de quests mensais (padrão: 1)
- `QUEST_REWARD_DAILY_COINS`: Recompensa diária (padrão: 50)
- `QUEST_REWARD_WEEKLY_COINS`: Recompensa semanal (padrão: 200)
- `QUEST_REWARD_MONTHLY_COINS`: Recompensa mensal (padrão: 1000)

## 📝 Exemplo Completo de Integração

```gdscript
# No Game.gd

# 1. Adicionar imports
const QuestManager = preload("res://scripts/managers/QuestManager.gd")
const ButtonHoverHelper = preload("res://scripts/helpers/ButtonHoverHelper.gd")

# 2. Adicionar variável
var quest_manager: QuestManager
var quest_ui_panel: Panel = null

# 3. Inicializar
func _ready():
    quest_manager = QuestManager.new()
    setup_button_hover_effects()
    create_quest_ui()
    check_quest_refresh()

# 4. Aplicar hover effects
func setup_button_hover_effects():
    var buttons = [
        $CanvasLayer/HUD/TopBar/BtnKillAll,
        $CanvasLayer/HUD/TopBar/BtnBuyTower,
        $CanvasLayer/HUD/TopBar/BtnBuyBlock
    ]
    ButtonHoverHelper.setup_multiple_buttons(buttons)

# 5. Atualizar progresso (exemplo)
func on_enemy_killed(is_boss: bool):
    if quest_manager:
        if is_boss:
            quest_manager.update_quest_progress(GameConstants.QuestType.KILL_BOSSES, 1)
        else:
            quest_manager.update_quest_progress(GameConstants.QuestType.KILL_ENEMIES, 1)
```

## ✅ Próximos Passos

1. Integre o código acima no `Game.gd`
2. Teste o sistema de quests
3. Ajuste os valores de balanceamento
4. Adicione efeitos visuais e sonoros
5. Teste com diferentes cenários

## 🎮 Dicas

- O sistema de quests aumenta o engajamento do jogador
- Hover effects tornam a UI mais responsiva e agradável
- Teste os valores de recompensa para balancear a economia do jogo
- Considere adicionar quests especiais em eventos

