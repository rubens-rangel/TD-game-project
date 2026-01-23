# Migração de `_draw()` para Sprite2D com Pooling

## 📊 Comparação: `_draw()` vs Sprite2D

### `_draw()` (Atual - CPU)
- ❌ Executado na **CPU** (muito mais lento)
- ❌ Chamado **a cada frame** para cada objeto
- ❌ Não pode ser otimizado pela GPU
- ❌ Limita FPS em waves grandes
- ✅ Simples de implementar
- ✅ Bom para poucos objetos

### Sprite2D (Proposto - GPU)
- ✅ Executado na **GPU** (muito mais rápido)
- ✅ Batch rendering automático
- ✅ Otimizações automáticas do Godot
- ✅ Suporta centenas/milhares de sprites
- ⚠️ Requer gerenciamento de nodes
- ⚠️ Precisa de pooling para performance

## 🎯 Vantagens da Migração

1. **Performance**: 10-100x mais rápido para muitos sprites
2. **Escalabilidade**: Suporta muito mais inimigos na tela
3. **GPU**: Usa hardware gráfico ao invés de CPU
4. **Batch Rendering**: Godot agrupa sprites automaticamente

## 📝 Como Funciona

### 1. Sistema de Pooling
```gdscript
# Ao invés de criar/destruir sprites:
var sprite = Sprite2D.new()  # ❌ Lento
add_child(sprite)
# ... usar ...
sprite.queue_free()  # ❌ Lento

# Usamos pooling:
var sprite = sprite_manager.get_enemy_sprite()  # ✅ Rápido (reutiliza)
# ... usar ...
sprite_manager.return_enemy_sprite(sprite)  # ✅ Rápido (retorna ao pool)
```

### 2. Atualização de Sprites
```gdscript
# No _process() ou _physics_process():
func _update_enemy_sprites():
    for e in enemies:
        if e["hp"] <= 0:
            sprite_manager.remove_enemy_sprite(e["idx"])
            continue
        
        # Atualizar posição e visual
        sprite_manager.update_enemy_sprite(
            e["idx"],
            e,
            get_enemy_texture(e),
            get_enemy_size(e),
            get_enemy_modulate(e),
            get_lod_level(e),
            e.get("is_boss", false)
        )
```

### 3. Remoção do `_draw()` para Inimigos
```gdscript
# ANTES (_draw()):
func _draw():
    for e in enemies:
        draw_texture_rect(...)  # ❌ CPU, lento
        draw_circle(...)  # ❌ CPU, lento
        draw_rect(...)  # ❌ CPU, lento

# DEPOIS (Sprite2D):
func _draw():
    # Apenas desenhar grid, torres, etc.
    # Inimigos são gerenciados por SpriteManager
    pass  # ✅ Sprites são renderizados automaticamente pela GPU
```

## 🔄 Plano de Migração (Incremental)

### Fase 1: Inimigos (Maior Impacto)
- ✅ Criar `SpriteManager`
- ✅ Migrar renderização de inimigos
- ✅ Manter lógica de jogo intacta
- **Impacto**: 70-80% do ganho de performance

### Fase 2: Projéteis
- Migrar arrows e tower_bullets
- **Impacto**: 10-15% adicional

### Fase 3: Efeitos Visuais
- Migrar damage_numbers, death_animations
- **Impacto**: 5-10% adicional

### Fase 4: Torres e Estruturas
- Migrar torres, walls, etc.
- **Impacto**: 5% adicional

## ⚠️ Considerações

### O que NÃO muda (Jogabilidade 100% igual)
- ✅ Lógica de movimento
- ✅ Cálculos de dano
- ✅ Pathfinding
- ✅ Colisões
- ✅ Sistema de waves
- ✅ Todas as mecânicas de jogo

### O que muda (Apenas Visual)
- ✅ Renderização usa GPU ao invés de CPU
- ✅ Sprites são nodes ao invés de draw calls
- ✅ Melhor performance em waves grandes

## 🚀 Implementação

1. **Adicionar SpriteManager ao Game.gd**:
```gdscript
const SpriteManager = preload("res://scripts/managers/SpriteManager.gd")
var sprite_manager: SpriteManager

func _ready():
    sprite_manager = SpriteManager.new(self)
```

2. **Atualizar inimigos no _process()**:
```gdscript
func _process(delta):
    # Atualizar sprites dos inimigos
    _update_enemy_sprites()
```

3. **Remover código de _draw() para inimigos**:
```gdscript
func _draw():
    # ... desenhar grid, torres, etc ...
    # NÃO desenhar inimigos aqui (SpriteManager cuida disso)
```

## 📈 Resultado Esperado

- **FPS**: De 2-4 FPS para 30-60 FPS em waves grandes
- **Inimigos**: Suporta 200+ inimigos simultâneos
- **CPU**: Redução de 80-90% no uso de CPU
- **GPU**: Uso moderado (muito mais eficiente)

## 🎮 Teste

Para testar a migração:
1. Implementar SpriteManager
2. Migrar apenas inimigos primeiro
3. Testar em waves grandes
4. Comparar FPS antes/depois
5. Se funcionar bem, migrar projéteis e efeitos
