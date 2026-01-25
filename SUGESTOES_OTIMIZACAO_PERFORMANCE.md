# Sugestões de Otimização de Performance

## Problemas Identificados

### 1. **Detecção de Inimigos pelas Torres (O(n×m))**
**Problema:** Cada torre verifica TODOS os inimigos a cada frame para encontrar alvos.
- Se há 20 torres e 100 inimigos = 2000 verificações por frame
- Cada verificação calcula `distance_to()` que é custoso

**Solução:**
- **Spatial Hash/Grid System**: Dividir o mapa em células e indexar inimigos por célula
- **QuadTree**: Estrutura de dados espacial para queries rápidas
- **Cache de targets**: Torres só procuram novos alvos a cada 0.1-0.2s, não todo frame
- **Early exit**: Parar de procurar quando encontrar um alvo válido

### 2. **Colisões de Projéteis (O(n×m))**
**Problema:** Cada projétil verifica TODOS os inimigos para colisão.
- Se há 50 projéteis e 100 inimigos = 5000 verificações por frame

**Solução:**
- **Spatial Hash para projéteis**: Indexar projéteis também
- **Broad phase + Narrow phase**: Primeiro verificar células próximas, depois colisão precisa
- **Limitar verificação**: Projéteis só verificam inimigos em células adjacentes

### 3. **Atualização de Inimigos**
**Problema:** Todos os inimigos são atualizados a cada frame, mesmo os fora da tela.

**Solução:**
- **Time Slicing**: Atualizar apenas N inimigos por frame (ex: 50 por frame)
- **LOD para lógica**: Inimigos distantes atualizam menos frequentemente
- **Batch updates**: Processar em lotes usando ThreadManager

### 4. **Pathfinding**
**Problema:** Pathfinding pode ser recalculado frequentemente.

**Solução:**
- **Cache de paths**: Reutilizar paths similares
- **Pathfinding assíncrono**: Já existe ThreadManager, usar mais
- **Simplificar paths**: Inimigos distantes usam paths mais simples

### 5. **Renderização (_draw())**
**Problema:** _draw() é chamado a cada frame e desenha tudo.

**Solução:**
- **Usar SpriteManager**: Já existe, mas não está sendo usado completamente
- **Occlusion culling**: Não desenhar objetos atrás de outros
- **LOD visual**: Menos detalhes para objetos distantes
- **Instancing**: Desenhar múltiplos sprites similares de uma vez

### 6. **Estruturas de Dados**
**Problema:** Arrays lineares para tudo = busca O(n).

**Solução:**
- **Dictionaries com índices**: Para acesso O(1)
- **Spatial structures**: Para queries espaciais rápidas

---

## Implementações Prioritárias (Ordem de Impacto)

### 🔴 **PRIORIDADE ALTA - Implementar Primeiro**

#### 1. **Spatial Hash System para Detecção de Inimigos**
**Impacto:** Reduz de O(n×m) para O(n+m) - **GANHO MASSIVO**

```gdscript
# Criar SpatialHashManager.gd
class_name SpatialHashManager

var cell_size: float = 100.0  # Tamanho da célula
var grid: Dictionary = {}  # {cell_key: [enemy_indices]}

func add_enemy(enemy_pos: Vector2, enemy_idx: int):
    var key = _get_cell_key(enemy_pos)
    if not grid.has(key):
        grid[key] = []
    grid[key].append(enemy_idx)

func get_enemies_in_range(center: Vector2, range: float) -> Array:
    # Retorna apenas inimigos em células próximas
    var nearby_cells = _get_nearby_cells(center, range)
    var result = []
    for cell_key in nearby_cells:
        if grid.has(cell_key):
            result.append_array(grid[cell_key])
    return result
```

**Uso nas torres:**
```gdscript
# Ao invés de:
for i in range(enemies.size()):
    var dist = tower_pos.distance_to(enemies[i]["pos"])

# Usar:
var nearby_enemies = spatial_hash.get_enemies_in_range(tower_pos, tower.range)
for enemy_idx in nearby_enemies:
    var dist = tower_pos.distance_to(enemies[enemy_idx]["pos"])
```

#### 2. **Cache de Targets para Torres**
**Impacto:** Reduz verificações de inimigos em 80-90%

```gdscript
# Adicionar ao TowerSystemManager:
var tower_target_cache: Dictionary = {}  # {tower_id: {target_idx: int, last_check: float}}
const TARGET_CACHE_DURATION = 0.15  # Verificar a cada 150ms

func find_closest_enemy_cached(tower_id: String, tower_pos: Vector2, range: float) -> int:
    var cache = tower_target_cache.get(tower_id, {})
    var now = Time.get_ticks_msec() / 1000.0
    
    # Se cache é recente e target ainda é válido, reusar
    if cache.has("target_idx") and (now - cache.get("last_check", 0.0)) < TARGET_CACHE_DURATION:
        var target_idx = cache.target_idx
        if target_idx >= 0 and target_idx < enemies.size():
            var enemy = enemies[target_idx]
            if enemy["hp"] > 0 and not enemy.get("reached", false):
                var dist = tower_pos.distance_to(enemy["pos"])
                if dist <= range:
                    return target_idx  # Cache válido!
    
    # Cache expirado ou inválido, procurar novo target
    var new_target = find_closest_enemy_in_range(tower_pos, range)
    tower_target_cache[tower_id] = {
        "target_idx": new_target,
        "last_check": now
    }
    return new_target
```

#### 3. **Time Slicing para Atualização de Inimigos**
**Impacto:** Limita processamento por frame

```gdscript
# Em Game.gd _process():
var enemies_per_frame = 50  # Atualizar 50 por frame
var enemy_update_index = get_meta("enemy_update_index", 0)

var start_idx = enemy_update_index
var end_idx = min(start_idx + enemies_per_frame, enemies.size())

for i in range(start_idx, end_idx):
    if i < enemies.size():
        var e = enemies[i]
        if not culling_manager or culling_manager.should_update_logic(e["pos"], camera_pos):
            _enemy_update(e, delta)

enemy_update_index = end_idx
if enemy_update_index >= enemies.size():
    enemy_update_index = 0

set_meta("enemy_update_index", enemy_update_index)
```

#### 4. **Otimizar Colisões de Projéteis**
**Impacto:** Reduz verificações de colisão drasticamente

```gdscript
# Usar spatial hash também para projéteis
# Ou limitar verificação a inimigos próximos

func _handle_collisions_optimized() -> void:
    # Agrupar projéteis por célula espacial
    var projectile_cells: Dictionary = {}
    
    for a in arrows:
        if a["life"] <= 0.0:
            continue
        var cell_key = _get_cell_key(a["pos"])
        if not projectile_cells.has(cell_key):
            projectile_cells[cell_key] = []
        projectile_cells[cell_key].append(a)
    
    # Verificar colisões apenas em células com projéteis
    for cell_key in projectile_cells.keys():
        var cell_projectiles = projectile_cells[cell_key]
        var cell_enemies = spatial_hash.get_enemies_in_cell(cell_key)
        
        for a in cell_projectiles:
            for enemy_idx in cell_enemies:
                var e = enemies[enemy_idx]
                # ... verificar colisão ...
```

### 🟡 **PRIORIDADE MÉDIA**

#### 5. **LOD para Lógica de Inimigos**
```gdscript
# Inimigos distantes atualizam menos frequentemente
func _enemy_update_with_lod(e: Dictionary, dt: float, lod_level: int) -> void:
    var update_rate = culling_manager.get_update_rate_for_lod(lod_level)
    if randf() > update_rate:
        return  # Pular este frame
    
    _enemy_update(e, dt * (1.0 / update_rate))
```

#### 6. **Simplificar Pathfinding**
```gdscript
# Para inimigos distantes, usar path mais simples
# Ou recalcular path menos frequentemente
```

#### 7. **Usar SpriteManager Completamente**
```gdscript
# Migrar de _draw() para SpriteManager
# Muito mais performático (GPU vs CPU)
```

### 🟢 **PRIORIDADE BAIXA - Melhorias Incrementais**

#### 8. **Otimizar Estruturas de Dados**
- Usar Dictionary para acesso rápido por ID
- Cache de cálculos frequentes

#### 9. **Reduzir Allocações**
- Reutilizar arrays e objetos
- Object pooling (já existe parcialmente)

#### 10. **Otimizar Cálculos Matemáticos**
- Cache de `distance_to()` quando possível
- Usar `distance_squared_to()` ao invés de `distance_to()` (evita sqrt)

---

## Implementação Rápida (Quick Wins)

### 1. **Adicionar Spatial Hash (30 minutos)**
Criar `SpatialHashManager.gd` e integrar nas torres.

### 2. **Cache de Targets (15 minutos)**
Adicionar cache simples no `TowerSystemManager`.

### 3. **Time Slicing (10 minutos)**
Limitar atualizações de inimigos por frame.

### 4. **Otimizar Colisões (20 minutos)**
Usar spatial hash para colisões também.

**Total estimado: ~1.5 horas para ganhos significativos de performance**

---

## Métricas Esperadas

Com essas otimizações:
- **100 inimigos + 20 torres**: De ~30 FPS para ~60 FPS
- **200 inimigos + 30 torres**: De ~15 FPS para ~45 FPS
- **500 inimigos + 50 torres**: De ~5 FPS para ~30 FPS

---

## Notas Adicionais

- **Testar incrementalmente**: Implementar uma otimização por vez e medir impacto
- **Profiling**: Usar Godot Profiler para identificar gargalos específicos
- **Balanceamento**: Algumas otimizações podem afetar gameplay (ex: LOD muito agressivo)
