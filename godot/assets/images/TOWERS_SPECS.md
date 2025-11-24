# Especificações para Imagens de Torres e Estruturas

## Imagens Necessárias

Você precisa gerar **9 imagens** para as torres e estruturas do jogo:

### 1. Base/Tenda (`tent.png`)
- **O que é**: A base principal no centro do mapa
- **Tamanho recomendado**: 56x56 pixels ou maior (será escalado)
- **Formato**: PNG com transparência
- **Características**: Tenda, acampamento, ou fortaleza central

### 2. Torre Normal (`tower.png`)
- **O que é**: Torre básica de defesa
- **Tamanho recomendado**: 56x56 pixels (2x2 tiles = 56x56px)
- **Formato**: PNG com transparência
- **Características**: Torre de pedra, madeira, ou metal, estilo medieval/fantasia

### 3. Slow Tower (`slow_tower.png`)
- **O que é**: Torre que reduz velocidade dos inimigos
- **Tamanho recomendado**: 56x56 pixels
- **Formato**: PNG com transparência
- **Características**: Torre com aparência de gelo/frio, ou mágica azul

### 4. AOE Tower (`aoe_tower.png`)
- **O que é**: Torre de dano em área
- **Tamanho recomendado**: 56x56 pixels
- **Formato**: PNG com transparência
- **Características**: Torre com aparência de explosão/fogo, ou canhão

### 5. Sniper Tower (`sniper_tower.png`)
- **O que é**: Torre de longo alcance e alta precisão
- **Tamanho recomendado**: 56x56 pixels
- **Formato**: PNG com transparência
- **Características**: Torre alta, escura, com aparência de precisão/sniper

### 6. Boost Tower (`boost_tower.png`)
- **O que é**: Torre que aumenta dano e cadência de outras torres
- **Tamanho recomendado**: 56x56 pixels
- **Formato**: PNG com transparência
- **Características**: Torre com aparência mágica/energética, amarela/dourada

### 7. Quartel (`barracks.png`)
- **O que é**: Estrutura que gera soldados
- **Tamanho recomendado**: 56x56 pixels
- **Formato**: PNG com transparência
- **Características**: Caserna, quartel, ou acampamento de soldados

### 8. Mina (`mine.png`)
- **O que é**: Armadilha que explode quando inimigos passam
- **Tamanho recomendado**: 28x28 pixels (1x1 tile)
- **Formato**: PNG com transparência
- **Características**: Mina, bomba, ou armadilha pequena

### 9. Muralha (`wall_structure.png`)
- **O que é**: Barreira defensiva que pode ser danificada
- **Tamanho recomendado**: 28x28 pixels (1x1 tile)
- **Formato**: PNG com transparência
- **Características**: Parede, muro, ou barreira defensiva

### 10. Estação de Cura (`healing_station.png`)
- **O que é**: Estrutura que cura a base no final das waves
- **Tamanho recomendado**: 56x56 pixels
- **Formato**: PNG com transparência
- **Características**: Altar, fonte de cura, ou estrutura mágica verde

## Tamanhos de Referência

- **TILE_SIZE**: 28 pixels
- **Torres 2x2**: 56x56 pixels (TOWER_SIZE_GRID = 2)
- **Estruturas 1x1**: 28x28 pixels (WALL_SIZE_GRID = 1)
- **Base**: Será escalada para ~80% do tamanho da base (7 tiles)

## Prompts para IA

### Para `tent.png` (Base):
```
"Generate a top-down view of a tent or camp base for a tower defense game. 
Central base structure, 56x56 pixels, pixel art style, 
medieval fantasy style, warm colors, brown and beige, 
suitable as the main base to defend."
```

### Para `tower.png` (Torre Normal):
```
"Generate a top-down view of a defensive tower for a tower defense game. 
Stone or wooden tower, 56x56 pixels, pixel art style, 
medieval fantasy style, gray or brown colors, 
simple defensive structure."
```

### Para `slow_tower.png` (Slow Tower):
```
"Generate a top-down view of an ice or magic tower for a tower defense game. 
Slow/freeze tower, 56x56 pixels, pixel art style, 
medieval fantasy style, blue and white colors, 
ice crystals or magical effects visible."
```

### Para `aoe_tower.png` (AOE Tower):
```
"Generate a top-down view of an explosive or cannon tower for a tower defense game. 
Area damage tower, 56x56 pixels, pixel art style, 
medieval fantasy style, orange and red colors, 
explosive or cannon appearance."
```

### Para `sniper_tower.png` (Sniper Tower):
```
"Generate a top-down view of a sniper or precision tower for a tower defense game. 
Long range tower, 56x56 pixels, pixel art style, 
medieval fantasy style, dark gray or black colors, 
tall and precise appearance."
```

### Para `boost_tower.png` (Boost Tower):
```
"Generate a top-down view of a magical or energy tower for a tower defense game. 
Support/boost tower, 56x56 pixels, pixel art style, 
medieval fantasy style, yellow or gold colors, 
magical energy or aura visible."
```

### Para `barracks.png` (Quartel):
```
"Generate a top-down view of a barracks or military camp for a tower defense game. 
Soldier spawn building, 56x56 pixels, pixel art style, 
medieval fantasy style, brown and gray colors, 
military structure appearance."
```

### Para `mine.png` (Mina):
```
"Generate a top-down view of a mine or trap for a tower defense game. 
Explosive trap, 28x28 pixels, pixel art style, 
medieval fantasy style, red and black colors, 
small explosive device."
```

### Para `wall_structure.png` (Muralha):
```
"Generate a top-down view of a defensive wall for a tower defense game. 
Defensive barrier, 28x28 pixels, pixel art style, 
medieval fantasy style, gray or brown colors, 
stone or wooden wall, tileable."
```

### Para `healing_station.png` (Estação de Cura):
```
"Generate a top-down view of a healing altar or fountain for a tower defense game. 
Healing structure, 56x56 pixels, pixel art style, 
medieval fantasy style, green and white colors, 
magical healing appearance."
```

## Como Adicionar

1. Gere as imagens usando IA com os prompts acima
2. Salve na pasta `godot/assets/images/` com os nomes exatos:
   - `tent.png`
   - `tower.png`
   - `slow_tower.png`
   - `aoe_tower.png`
   - `sniper_tower.png`
   - `boost_tower.png`
   - `barracks.png`
   - `mine.png`
   - `wall_structure.png`
   - `healing_station.png`
3. O Godot importará automaticamente
4. As texturas serão aplicadas automaticamente no jogo

## Fallback

Se as imagens não forem encontradas, o jogo usará desenhos coloridos (retângulos e círculos) como antes.





