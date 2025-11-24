# Sistema de Managers - Arquitetura Modular

Este documento descreve a nova arquitetura modular do jogo, onde a lógica foi separada em managers especializados.

## Estrutura de Managers

### EnemyManager
**Responsabilidades:**
- Gerenciar criação e atualização de inimigos
- Gerenciar efeitos de status (congelamento, fogo)
- Calcular caminhos para inimigos
- Encontrar posições de spawn válidas
- Remover inimigos mortos

**Métodos principais:**
- `create_enemy(col, row, is_boss)` - Cria um novo inimigo
- `update_enemy(enemy, dt)` - Atualiza movimento e status de um inimigo
- `find_spawn_position()` - Encontra posição válida para spawn
- `apply_status_effect(enemy_idx, type, duration, damage)` - Aplica efeito de status

### ResourceManager
**Responsabilidades:**
- Carregar todas as texturas do jogo
- Processar texturas (remover fundo branco)
- Gerenciar cache de recursos
- Emitir sinais de progresso de carregamento

**Métodos principais:**
- `load_all_textures()` - Carrega todas as texturas
- `get_texture(name)` - Retorna textura pelo nome
- `load_texture(path, process)` - Carrega uma textura específica

### EffectsManager
**Responsabilidades:**
- Gerenciar efeitos visuais (AOE, sniper, coleta de moedas)
- Atualizar partículas e animações
- Limpar efeitos expirados

**Métodos principais:**
- `create_aoe_effect(pos, radius, duration)` - Cria efeito de explosão AOE
- `create_sniper_effect(start, end, duration)` - Cria efeito de linha de tiro
- `create_coin_collect_effect(pos)` - Cria efeito de coleta de moeda
- `update_effects(delta)` - Atualiza todos os efeitos

### PlacementManager
**Responsabilidades:**
- Validar posições de colocação
- Verificar se pode colocar estruturas
- Gerenciar preview de colocação
- Verificar regras de colocação (caminhos, centro)

**Métodos principais:**
- `start_placing(type)` - Inicia modo de colocação
- `can_place_at(world_pos)` - Verifica se pode colocar na posição
- `place_structure(world_pos)` - Coloca estrutura na posição

### CombatManager
**Responsabilidades:**
- Verificar colisões de projéteis
- Aplicar dano a inimigos
- Gerenciar efeitos de área (AOE)
- Gerenciar tiros perfurantes (sniper)

**Métodos principais:**
- `check_projectile_collisions(projectiles, type)` - Verifica colisões
- `check_aoe_damage(pos, radius, damage)` - Aplica dano em área
- `check_sniper_line_damage(start, end, damage, pierce)` - Aplica dano em linha

### CoinManager
**Responsabilidades:**
- Gerenciar moedas dropadas
- Processar coleta de moedas
- Atualizar lifetime das moedas
- Criar efeitos de coleta

**Métodos principais:**
- `try_drop_coin(pos)` - Tenta dropar uma moeda
- `try_collect_coin(world_pos)` - Tenta coletar moeda na posição
- `update_coins(delta)` - Atualiza lifetime das moedas

### TowerManager
**Responsabilidades:**
- Gerenciar todas as torres (normal, slow, AOE, sniper, boost)
- Atualizar cooldowns e disparos
- Aplicar boosts de outras torres
- Emitir sinais de disparo

**Métodos principais:**
- `create_tower(pos, grid_x, grid_y, dir)` - Cria torre normal
- `create_slow_tower(...)` - Cria slow tower
- `create_aoe_tower(...)` - Cria AOE tower
- `create_sniper_tower(...)` - Cria sniper tower
- `create_boost_tower(...)` - Cria boost tower
- `update_towers(delta, enemies, boost_towers)` - Atualiza todas as torres

### StructureManager
**Responsabilidades:**
- Gerenciar estruturas (barracks, mines, walls, healing stations)
- Gerenciar soldados dos quartéis
- Atualizar estruturas e suas interações
- Processar destruição de estruturas

**Métodos principais:**
- `create_barracks(...)` - Cria quartel
- `create_mine(...)` - Cria mina
- `create_wall(...)` - Cria muralha
- `create_healing_station(...)` - Cria estação de cura
- `update_structures(delta, enemies, grid_manager, pathfinder)` - Atualiza todas as estruturas

### UIManager
**Responsabilidades:**
- Gerenciar toda a interface do usuário
- Gerenciar menus e overlays
- Atualizar informações na tela
- Gerenciar tela de carregamento

**Métodos principais:**
- `update_top_bar(wave, enemies, coins, hp)` - Atualiza barra superior
- `update_buy_menu(coins, counts, limits)` - Atualiza menu de compras
- `show_upgrade_overlay(options)` - Mostra overlay de upgrades
- `show_game_over(wave)` - Mostra tela de game over
- `create_loading_screen(canvas_layer)` - Cria tela de carregamento

## Benefícios da Nova Arquitetura

1. **Separação de Responsabilidades**: Cada manager tem uma responsabilidade clara
2. **Reutilização**: Managers podem ser reutilizados em outros projetos
3. **Testabilidade**: Cada manager pode ser testado independentemente
4. **Manutenibilidade**: Código mais fácil de entender e modificar
5. **Escalabilidade**: Fácil adicionar novos tipos de estruturas ou efeitos

## Como Usar

O `Game.gd` agora deve instanciar e usar esses managers em vez de ter toda a lógica diretamente. Exemplo:

```gdscript
var enemy_manager: EnemyManager
var resource_manager: ResourceManager
var effects_manager: EffectsManager
# ... etc

func _ready():
    enemy_manager = EnemyManager.new(grid_manager, pathfinder, wave_manager)
    resource_manager = ResourceManager.new()
    effects_manager = EffectsManager.new()
    # ...
```


