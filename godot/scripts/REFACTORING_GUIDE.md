# Guia de Refatoração - Integração dos Managers

## Estrutura Criada

Foram criados 9 managers especializados para organizar o código:

1. **EnemyManager** - Gerencia inimigos, spawn, movimento, efeitos
2. **ResourceManager** - Carrega e processa texturas
3. **EffectsManager** - Gerencia efeitos visuais (AOE, sniper, moedas)
4. **PlacementManager** - Valida e gerencia colocação de estruturas
5. **CombatManager** - Gerencia combate e colisões
6. **CoinManager** - Gerencia moedas dropadas e coleta
7. **TowerManager** - Gerencia todas as torres
8. **StructureManager** - Gerencia estruturas (barracks, mines, walls, healing)
9. **UIManager** - Gerencia toda a interface do usuário

## Estratégia de Integração

### Opção 1: Integração Gradual (Recomendado)

Integrar os managers gradualmente, mantendo o código atual funcionando:

1. **Fase 1**: Integrar ResourceManager e EffectsManager (mais simples)
2. **Fase 2**: Integrar CoinManager e PlacementManager
3. **Fase 3**: Integrar EnemyManager
4. **Fase 4**: Integrar TowerManager e StructureManager
5. **Fase 5**: Integrar CombatManager e UIManager

### Opção 2: Refatoração Completa

Substituir completamente o Game.gd pelo código refatorado (mais arriscado, mas mais limpo).

## Exemplo de Integração Gradual

### Passo 1: Adicionar ResourceManager

```gdscript
# No início do Game.gd, adicionar:
const ResourceManager = preload("res://scripts/managers/ResourceManager.gd")
var resource_manager: ResourceManager

# No _ready(), substituir o carregamento de texturas:
func _ready() -> void:
    resource_manager = ResourceManager.new()
    resource_manager.loading_progress_updated.connect(_on_loading_progress)
    resource_manager.load_all_textures()
    
    # Usar texturas do resource_manager:
    tex_tower = resource_manager.get_texture("tower")
    tex_enemy_zombie = resource_manager.get_texture("enemy_zombie")
    # ... etc
```

### Passo 2: Adicionar EffectsManager

```gdscript
const EffectsManager = preload("res://scripts/managers/EffectsManager.gd")
var effects_manager: EffectsManager

func _ready() -> void:
    effects_manager = EffectsManager.new()
    # ... resto

func _process(delta: float) -> void:
    # Substituir atualização manual de efeitos:
    effects_manager.update_effects(delta)
    
    # Usar efeitos do manager:
    aoe_effects = effects_manager.get_aoe_effects()
    sniper_effects = effects_manager.get_sniper_effects()
    coin_collect_effects = effects_manager.get_coin_collect_effects()
```

### Passo 3: Adicionar CoinManager

```gdscript
const CoinManager = preload("res://scripts/managers/CoinManager.gd")
var coin_manager: CoinManager

func _ready() -> void:
    coin_manager = CoinManager.new(effects_manager)
    coin_manager.coin_collected.connect(_on_coin_collected)

func _on_coin_collected(value: int) -> void:
    hero["coins"] += value

func _process(delta: float) -> void:
    coin_manager.update_coins(delta)
    dropped_coins = coin_manager.get_dropped_coins()

# Substituir _try_drop_coin:
func _try_drop_coin(pos: Vector2) -> void:
    coin_manager.try_drop_coin(pos)

# Substituir coleta de moedas no _input:
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        var world_pos = to_local(event.position)
        var coin_value = coin_manager.try_collect_coin(world_pos)
        if coin_value > 0:
            queue_redraw()
            return
```

## Benefícios da Refatoração

1. **Código mais limpo**: Game.gd reduzido de ~3000 para ~500 linhas
2. **Manutenibilidade**: Cada sistema isolado e fácil de modificar
3. **Testabilidade**: Managers podem ser testados independentemente
4. **Reutilização**: Managers podem ser usados em outros projetos
5. **Performance**: Melhor organização pode melhorar performance

## Próximos Passos

1. Testar os managers criados individualmente
2. Integrar gradualmente começando pelos mais simples
3. Manter backups do código original
4. Testar cada fase antes de prosseguir

## Notas Importantes

- Os managers foram criados mas ainda não estão totalmente integrados
- O Game.gd atual continua funcionando normalmente
- A integração pode ser feita gradualmente sem quebrar o jogo
- Alguns managers podem precisar de ajustes após testes


