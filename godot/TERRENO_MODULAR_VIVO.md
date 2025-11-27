# 🌍 Sistema de Terreno Modular Vivo - Especificação de Implementação

## 📋 Visão Geral

O **Terreno Modular Vivo** transforma tiles do mapa em biomas interativos que afetam gameplay, criando camadas estratégicas adicionais. Jogadores podem "cultivar" tiles com biomas específicos, e eventos climáticos temporários alteram suas propriedades.

---

## 🏗️ Arquitetura do Sistema

### 1. Estrutura de Dados de Biomas

#### 1.1 Enum/Tipo de Bioma
```gdscript
enum BiomeType {
    NONE = 0,           # Terreno neutro (padrão)
    SWAMP = 1,          # Pântano - desacelera inimigos
    VOLCANO = 2,        # Vulcão - amplifica dano de fogo
    FOREST = 3,         # Floresta - regenera torres lentamente
    ICE = 4,            # Gelo - aumenta slow, reduz velocidade de torres
    DESERT = 5,         # Deserto - aumenta velocidade, reduz defesa
    CRYSTAL = 6,        # Cristal - amplifica dano mágico/elétrico
    TOXIC = 7,          # Tóxico - causa dano contínuo em inimigos
    HOLY = 8            # Sagrado - cura torres, reduz dano de inimigos sombrios
}
```

#### 1.2 Classe BiomeData
```gdscript
class_name BiomeData
extends RefCounted

var biome_type: BiomeType = BiomeType.NONE
var level: int = 1  # Nível do bioma (1-3, afeta intensidade)
var growth_progress: float = 0.0  # Progresso de crescimento (0.0-1.0)
var is_active: bool = true  # Se o bioma está ativo ou suprimido por evento
var owner_id: int = -1  # ID do jogador que cultivou (para multiplayer futuro)

# Modificadores base (antes de eventos climáticos)
var enemy_speed_modifier: float = 1.0  # Multiplicador de velocidade de inimigos
var enemy_damage_modifier: float = 1.0  # Multiplicador de dano recebido por inimigos
var tower_damage_modifier: float = 1.0  # Multiplicador de dano de torres
var tower_speed_modifier: float = 1.0  # Multiplicador de velocidade de ataque
var tower_range_modifier: float = 1.0  # Multiplicador de alcance
var special_effects: Dictionary = {}  # Efeitos especiais (ex: "fire_boost", "slow_aura")
```

#### 1.3 Grid de Biomas
```gdscript
# Em GridManager.gd ou novo BiomeManager.gd
var biome_grid: Array = []  # Array 2D: biome_grid[row][col] = BiomeData
```

---

## 🎮 Mecânicas de Cultivo

### 2.1 Sistema de Cultivo de Tiles

#### 2.1.1 Requisitos
- **Custo**: Cada bioma tem um custo em moedas (ex: 50-200 moedas)
- **Tempo de Crescimento**: Biomas levam tempo para crescer (5-15 segundos)
- **Restrições**: 
  - Não pode cultivar em tiles de caminho (onde inimigos andam)
  - Não pode cultivar em tiles já ocupados por estruturas
  - Alguns biomas requerem tiles adjacentes específicos

#### 2.1.2 Processo de Cultivo
```gdscript
func cultivate_biome(grid_x: int, grid_y: int, biome_type: BiomeType, cost: int) -> bool:
    # 1. Verificar se pode cultivar
    if not can_cultivate_biome(grid_x, grid_y, biome_type):
        return false
    
    # 2. Verificar recursos
    if hero["coins"] < cost:
        return false
    
    # 3. Criar bioma
    var biome = BiomeData.new()
    biome.biome_type = biome_type
    biome.level = 1
    biome.growth_progress = 0.0
    biome.is_active = true
    
    # 4. Aplicar modificadores base
    _apply_biome_modifiers(biome)
    
    # 5. Adicionar ao grid
    biome_grid[grid_y][grid_x] = biome
    
    # 6. Deduzir custo
    hero["coins"] -= cost
    
    # 7. Iniciar animação de crescimento
    _start_biome_growth_animation(grid_x, grid_y, biome_type)
    
    return true
```

### 2.2 Níveis de Bioma

Biomas podem ser **upgradados** para aumentar seus efeitos:

- **Nível 1**: Efeito básico (50% da intensidade máxima)
- **Nível 2**: Efeito médio (75% da intensidade máxima) - Custo: 100 moedas
- **Nível 3**: Efeito máximo (100% da intensidade) - Custo: 200 moedas

```gdscript
func upgrade_biome(grid_x: int, grid_y: int) -> bool:
    var biome = biome_grid[grid_y][grid_x]
    if biome == null or biome.level >= 3:
        return false
    
    var upgrade_cost = 100 * biome.level  # 100 para nível 2, 200 para nível 3
    if hero["coins"] < upgrade_cost:
        return false
    
    biome.level += 1
    _apply_biome_modifiers(biome)  # Recalcular modificadores
    hero["coins"] -= upgrade_cost
    return true
```

---

## 🌦️ Sistema de Eventos Climáticos

### 3.1 Tipos de Eventos

```gdscript
enum WeatherEvent {
    NONE = 0,
    RAIN = 1,           # Chuva - amplifica pântano, reduz vulcão
    DROUGHT = 2,        # Seca - amplifica deserto/vulcão, reduz pântano
    SNOW = 3,           # Neve - amplifica gelo, reduz velocidade geral
    STORM = 4,          # Tempestade - amplifica cristal/elétrico
    FOG = 5,            # Névoa - reduz alcance de torres
    SUNNY = 6           # Sol - amplifica floresta, reduz tóxico
}
```

### 3.2 Efeitos dos Eventos nos Biomas

| Evento | Pântano | Vulcão | Floresta | Gelo | Deserto | Cristal | Tóxico | Sagrado |
|--------|---------|--------|----------|------|---------|---------|--------|---------|
| **Chuva** | +50% efeito | -30% efeito | +25% efeito | +20% efeito | -20% efeito | +10% efeito | +30% efeito | +15% efeito |
| **Seca** | -40% efeito | +50% efeito | -30% efeito | -20% efeito | +40% efeito | +20% efeito | +25% efeito | -10% efeito |
| **Neve** | +20% efeito | -40% efeito | -10% efeito | +60% efeito | -30% efeito | +15% efeito | -20% efeito | +10% efeito |
| **Tempestade** | +10% efeito | +15% efeito | -20% efeito | +10% efeito | -15% efeito | +80% efeito | +40% efeito | -30% efeito |
| **Névoa** | +30% efeito | -20% efeito | -15% efeito | +10% efeito | -10% efeito | -10% efeito | +20% efeito | -20% efeito |
| **Sol** | -30% efeito | +20% efeito | +50% efeito | -40% efeito | +30% efeito | -10% efeito | -30% efeito | +40% efeito |

### 3.3 Implementação de Eventos

```gdscript
var current_weather: WeatherEvent = WeatherEvent.NONE
var weather_duration: float = 0.0
var weather_timer: float = 0.0

func start_weather_event(weather: WeatherEvent, duration: float = 30.0):
    current_weather = weather
    weather_duration = duration
    weather_timer = duration
    
    # Aplicar modificadores de clima a todos os biomas
    _apply_weather_modifiers()
    
    # Efeitos visuais
    _show_weather_effects(weather)
    
    # Notificação ao jogador
    _show_weather_notification(weather)

func _apply_weather_modifiers():
    for row in range(biome_grid.size()):
        for col in range(biome_grid[row].size()):
            var biome = biome_grid[row][col]
            if biome != null:
                _apply_weather_to_biome(biome)
```

---

## ⚡ Efeitos dos Biomas no Gameplay

### 4.1 Efeitos em Inimigos

```gdscript
func get_enemy_modifiers_at_position(pos: Vector2) -> Dictionary:
    var grid_pos = world_to_grid(pos)
    var biome = biome_grid[grid_pos.y][grid_pos.x]
    
    if biome == null or not biome.is_active:
        return {"speed": 1.0, "damage_taken": 1.0}
    
    var modifiers = {
        "speed": biome.enemy_speed_modifier,
        "damage_taken": biome.enemy_damage_modifier
    }
    
    # Aplicar efeitos especiais
    if biome.special_effects.has("slow_aura"):
        modifiers["slow_amount"] = biome.special_effects["slow_aura"]
    if biome.special_effects.has("poison_damage"):
        modifiers["poison_dps"] = biome.special_effects["poison_damage"]
    
    return modifiers
```

### 4.2 Efeitos em Torres

```gdscript
func get_tower_modifiers_at_position(pos: Vector2) -> Dictionary:
    var grid_pos = world_to_grid(pos)
    var biome = biome_grid[grid_pos.y][grid_pos.x]
    
    if biome == null or not biome.is_active:
        return {"damage": 1.0, "speed": 1.0, "range": 1.0}
    
    var modifiers = {
        "damage": biome.tower_damage_modifier,
        "speed": biome.tower_speed_modifier,
        "range": biome.tower_range_modifier
    }
    
    # Efeitos especiais
    if biome.special_effects.has("fire_boost"):
        modifiers["fire_damage_multiplier"] = biome.special_effects["fire_boost"]
    if biome.special_effects.has("regeneration"):
        modifiers["hp_regen_per_second"] = biome.special_effects["regeneration"]
    
    return modifiers
```

### 4.3 Aplicação dos Modificadores

```gdscript
# Em _update_enemies() ou similar
func apply_biome_effects_to_enemy(enemy: Dictionary):
    var modifiers = get_enemy_modifiers_at_position(enemy["pos"])
    
    # Aplicar modificador de velocidade
    enemy["base_speed"] *= modifiers.get("speed", 1.0)
    
    # Aplicar dano contínuo (ex: tóxico)
    if modifiers.has("poison_dps"):
        enemy["hp"] -= modifiers["poison_dps"] * delta

# Em _tower_fire_cross() ou similar
func apply_biome_effects_to_tower(tower: Dictionary):
    var modifiers = get_tower_modifiers_at_position(tower.pos)
    
    # Aplicar modificadores
    tower.damage *= modifiers.get("damage", 1.0)
    tower.fire_rate /= modifiers.get("speed", 1.0)  # Dividir porque menor = mais rápido
    tower.range *= modifiers.get("range", 1.0)
```

---

## 🎨 Visual e Feedback

### 5.1 Texturas e Cores por Bioma

```gdscript
var biome_textures: Dictionary = {
    BiomeType.SWAMP: preload("res://assets/biomes/swamp.png"),
    BiomeType.VOLCANO: preload("res://assets/biomes/volcano.png"),
    BiomeType.FOREST: preload("res://assets/biomes/forest.png"),
    BiomeType.ICE: preload("res://assets/biomes/ice.png"),
    BiomeType.DESERT: preload("res://assets/biomes/desert.png"),
    BiomeType.CRYSTAL: preload("res://assets/biomes/crystal.png"),
    BiomeType.TOXIC: preload("res://assets/biomes/toxic.png"),
    BiomeType.HOLY: preload("res://assets/biomes/holy.png")
}

var biome_colors: Dictionary = {
    BiomeType.SWAMP: Color(0.2, 0.4, 0.3, 0.6),
    BiomeType.VOLCANO: Color(0.6, 0.2, 0.1, 0.6),
    BiomeType.FOREST: Color(0.1, 0.5, 0.2, 0.6),
    BiomeType.ICE: Color(0.7, 0.9, 1.0, 0.6),
    BiomeType.DESERT: Color(0.9, 0.8, 0.5, 0.6),
    BiomeType.CRYSTAL: Color(0.5, 0.3, 0.9, 0.6),
    BiomeType.TOXIC: Color(0.4, 0.8, 0.2, 0.6),
    BiomeType.HOLY: Color(1.0, 1.0, 0.7, 0.6)
}
```

### 5.2 Renderização no _draw()

```gdscript
func _draw() -> void:
    # ... código existente ...
    
    # Desenhar biomas
    for row in range(biome_grid.size()):
        for col in range(biome_grid[row].size()):
            var biome = biome_grid[row][col]
            if biome != null and biome.is_active:
                var tile_x = float(col * GameConstants.TILE_SIZE)
                var tile_y = float(row * GameConstants.TILE_SIZE)
                var tile_rect = Rect2(tile_x, tile_y, GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
                
                # Desenhar textura ou cor do bioma
                var alpha = 0.3 + (biome.level * 0.1)  # Mais opaco em níveis maiores
                var color = biome_colors[biome.biome_type]
                color.a = alpha
                
                if biome_textures.has(biome.biome_type):
                    draw_texture_rect(biome_textures[biome.biome_type], tile_rect, false, color)
                else:
                    draw_rect(tile_rect, color)
                
                # Indicador de nível (pequeno número ou ícone)
                if biome.level > 1:
                    draw_string(font, Vector2(tile_x + 2, tile_y + 12), str(biome.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
```

### 5.3 Efeitos Visuais de Eventos Climáticos

```gdscript
func _draw_weather_effects():
    if current_weather == WeatherEvent.NONE:
        return
    
    match current_weather:
        WeatherEvent.RAIN:
            # Desenhar partículas de chuva
            _draw_rain_particles()
        WeatherEvent.SNOW:
            # Desenhar flocos de neve
            _draw_snow_particles()
        WeatherEvent.STORM:
            # Desenhar raios e relâmpagos
            _draw_lightning_effects()
        WeatherEvent.FOG:
            # Overlay de névoa
            draw_rect(Rect2(0, 0, map_width, map_height), Color(0.5, 0.5, 0.6, 0.3))
```

---

## 🛠️ Integração com Código Existente

### 6.1 Modificações Necessárias

#### 6.1.1 GridManager.gd
```gdscript
# Adicionar:
var biome_grid: Array = []
var biome_manager: BiomeManager

func _init():
    # ... código existente ...
    biome_manager = BiomeManager.new()
    _init_biome_grid()

func _init_biome_grid():
    biome_grid = []
    for r in range(GameConstants.GRID_ROWS):
        biome_grid.append([])
        for c in range(GameConstants.GRID_COLS):
            biome_grid[r].append(null)  # null = sem bioma
```

#### 6.1.2 Game.gd
```gdscript
# Adicionar variáveis:
var placing_biome: bool = false
var selected_biome_type: BiomeType = BiomeType.NONE
var biome_shop_panel: Panel

# Adicionar função de cultivo:
func _on_cultivate_biome(biome_type: BiomeType, cost: int):
    placing_biome = true
    selected_biome_type = biome_type

# Modificar funções existentes para aplicar modificadores de bioma
```

### 6.2 Novo Arquivo: BiomeManager.gd

```gdscript
extends RefCounted
class_name BiomeManager

var grid_manager: GridManager
var current_weather: WeatherEvent = WeatherEvent.NONE
var weather_timer: float = 0.0

func _init(gm: GridManager):
    grid_manager = gm

func cultivate_biome(grid_x: int, grid_y: int, biome_type: BiomeType, cost: int) -> bool:
    # Implementação completa aqui
    pass

func get_biome_at(world_pos: Vector2) -> BiomeData:
    var grid_pos = grid_manager.world_to_grid(world_pos)
    if grid_pos.y >= 0 and grid_pos.y < grid_manager.biome_grid.size():
        if grid_pos.x >= 0 and grid_pos.x < grid_manager.biome_grid[grid_pos.y].size():
            return grid_manager.biome_grid[grid_pos.y][grid_pos.x]
    return null

func apply_weather_event(weather: WeatherEvent, duration: float):
    # Implementação completa aqui
    pass
```

---

## 📊 Tabela de Efeitos por Bioma

### Pântano (Swamp)
- **Inimigos**: -30% velocidade, -10% defesa
- **Torres**: +10% alcance (torres de água/gelo)
- **Custo**: 75 moedas
- **Upgrade**: Aumenta slow para -50% velocidade

### Vulcão (Volcano)
- **Inimigos**: +50% dano de fogo recebido
- **Torres**: +25% dano de fogo, +15% velocidade de ataque
- **Custo**: 100 moedas
- **Upgrade**: Aumenta bônus de fogo para +75%

### Floresta (Forest)
- **Inimigos**: -5% velocidade (vegetação densa)
- **Torres**: +2 HP/segundo regeneração, +10% alcance
- **Custo**: 80 moedas
- **Upgrade**: Aumenta regeneração para +5 HP/segundo

### Gelo (Ice)
- **Inimigos**: -20% velocidade, +25% dano de gelo recebido
- **Torres**: +30% dano de gelo, -10% velocidade de ataque
- **Custo**: 90 moedas
- **Upgrade**: Aumenta slow para -35% velocidade

### Deserto (Desert)
- **Inimigos**: +15% velocidade, -20% defesa
- **Torres**: +20% velocidade de ataque, -10% alcance
- **Custo**: 70 moedas
- **Upgrade**: Aumenta velocidade para +25%

### Cristal (Crystal)
- **Inimigos**: +40% dano mágico/elétrico recebido
- **Torres**: +35% dano mágico/elétrico, +15% alcance
- **Custo**: 150 moedas
- **Upgrade**: Aumenta bônus para +60%

### Tóxico (Toxic)
- **Inimigos**: 5 DPS de veneno, -15% velocidade
- **Torres**: +20% dano de veneno
- **Custo**: 120 moedas
- **Upgrade**: Aumenta DPS para 10

### Sagrado (Holy)
- **Inimigos**: -30% dano de inimigos sombrios
- **Torres**: +3 HP/segundo regeneração, +15% dano contra sombrios
- **Custo**: 200 moedas
- **Upgrade**: Aumenta regeneração para +6 HP/segundo

---

## 🎯 Fluxo de Jogo

1. **Entre Waves**: Jogador pode cultivar biomas em tiles disponíveis
2. **Durante Wave**: Biomas aplicam efeitos automaticamente
3. **Evento Climático**: Sistema anuncia evento e aplica modificadores
4. **Estratégia**: Jogador pode reposicionar torres para aproveitar novos biomas ou eventos

---

## 🚀 Implementação em Fases

### Fase 1: Base (MVP)
- [ ] Sistema de grid de biomas
- [ ] 3 biomas básicos (Pântano, Vulcão, Floresta)
- [ ] Cultivo básico
- [ ] Aplicação de modificadores simples

### Fase 2: Expansão
- [ ] Todos os 8 biomas
- [ ] Sistema de níveis
- [ ] Eventos climáticos básicos (3 tipos)

### Fase 3: Polimento
- [ ] Todos os eventos climáticos
- [ ] Efeitos visuais completos
- [ ] UI de cultivo
- [ ] Tooltips e feedback

---

## 💡 Considerações de Design

1. **Balanceamento**: Biomas não devem ser muito poderosos, apenas oferecer vantagens estratégicas
2. **Custo vs Benefício**: Biomas caros devem ter efeitos significativos
3. **Variedade**: Cada bioma deve ter nicho único, não apenas "melhor em tudo"
4. **Feedback Visual**: Jogador deve sempre saber quais tiles têm biomas e seus efeitos
5. **Flexibilidade**: Sistema deve permitir remoção/transformação de biomas (com custo)

---

**Nota**: Este sistema adiciona profundidade estratégica significativa ao jogo, incentivando planejamento de longo prazo e adaptação a eventos climáticos dinâmicos.



