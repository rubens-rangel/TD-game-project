# Especificações para Sprites de Monstros

## Sprites Necessários

Você precisa criar **3 sprites** para os diferentes tipos de monstros baseados na wave:

### 1. Zumbi (`enemy_zombie.png`)
- **Usado em**: Waves 1-5
- **Tamanho recomendado**: 32x32 pixels ou maior (será escalado)
- **Formato**: PNG com transparência
- **Características**: Zumbi, criatura morta-viva, estilo medieval/fantasia

### 2. Humanoide (`enemy_humanoid.png`)
- **Usado em**: Waves 6-10
- **Tamanho recomendado**: 32x32 pixels ou maior (será escalado)
- **Formato**: PNG com transparência
- **Características**: Humanoide, guerreiro, ou criatura humanóide

### 3. Robô (`enemy_robot.png`)
- **Usado em**: Waves 11+
- **Tamanho recomendado**: 32x32 pixels ou maior (será escalado)
- **Formato**: PNG com transparência
- **Características**: Robô, máquina, ou criatura mecânica

## Funcionalidades Implementadas

### Tamanhos
- **Monstros normais**: 1.2x o tamanho de um tile (33.6x33.6 pixels)
- **Bosses**: 1.5x o tamanho de um tile (42x42 pixels)
- Os sprites serão escalados automaticamente mantendo proporção

### Efeitos Visuais
- **Congelado**: Tint azul claro aplicado automaticamente
- **Em chamas**: Tint laranja aplicado automaticamente
- **Boss**: Borda roxa ao redor do sprite

### Processamento Automático
- Fundo branco será removido automaticamente (threshold: 0.85)
- Transparência preservada
- Sprites serão processados ao carregar o jogo

## Prompts para IA

### Para `enemy_zombie.png`:
```
"Generate a top-down view sprite of a zombie for a tower defense game. 
Walking zombie, 32x32 pixels, pixel art style, 
medieval fantasy style, undead creature, 
greenish or grayish colors, simple but recognizable zombie features."
```

### Para `enemy_humanoid.png`:
```
"Generate a top-down view sprite of a humanoid warrior for a tower defense game. 
Humanoid enemy, 32x32 pixels, pixel art style, 
medieval fantasy style, warrior or creature, 
brown or gray colors, human-like but menacing."
```

### Para `enemy_robot.png`:
```
"Generate a top-down view sprite of a robot for a tower defense game. 
Mechanical robot enemy, 32x32 pixels, pixel art style, 
sci-fi or fantasy style, metallic colors (gray, silver, blue), 
robotic features visible from top-down view."
```

## Como Adicionar

1. Gere as imagens usando IA com os prompts acima
2. Salve na pasta `godot/assets/images/` com os nomes exatos:
   - `enemy_zombie.png`
   - `enemy_humanoid.png`
   - `enemy_robot.png`
3. O Godot importará automaticamente
4. Os sprites serão processados automaticamente (fundo branco removido)
5. Os monstros aparecerão com sprites nas waves corretas

## Fallback

Se as imagens não forem encontradas, o jogo usará círculos coloridos como antes:
- Vermelho para monstros normais
- Roxo para bosses
- Azul quando congelados
- Laranja quando em chamas

## Notas

- Os sprites serão exibidos com 1.2x o tamanho de um tile (aproximadamente 34x34 pixels)
- Bosses terão sprites 1.5x maiores (aproximadamente 42x42 pixels)
- O sistema remove automaticamente fundos brancos/quase brancos
- Efeitos visuais (congelamento, fogo) são aplicados via tinting automático





