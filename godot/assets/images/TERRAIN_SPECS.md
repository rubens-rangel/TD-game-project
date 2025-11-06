# Especificações para Texturas de Terreno

## Imagens Necessárias

Você precisa gerar **2 imagens** para o terreno do jogo:

### 1. Textura do Caminho (`path.png`)
- **O que é**: Textura para o chão onde os inimigos caminham (áreas abertas do labirinto)
- **Tamanho recomendado**: 28x28 pixels (ou múltiplos: 56x56, 84x84, 112x112)
- **Formato**: PNG
- **Características**:
  - Deve ser **tileable** (seamless) - pode ser repetida sem costuras visíveis
  - Estilo: terra, grama, pedra, ou combinação
  - Cores: tons terrosos, verdes, ou marrons
  - Deve parecer um caminho/estrada onde personagens podem andar

### 2. Textura da Barreira/Cerca (`wall.png`)
- **O que é**: Textura para as paredes/barreiras do labirinto (obstáculos)
- **Tamanho recomendado**: 28x28 pixels (ou múltiplos: 56x56, 84x84, 112x112)
- **Formato**: PNG
- **Características**:
  - Deve ser **tileable** (seamless) - pode ser repetida sem costuras visíveis
  - Estilo: pedra, madeira, cerca, muro, ou barreira
  - Cores: tons escuros, cinzas, marrons, ou pedra
  - Deve parecer uma barreira sólida que bloqueia o caminho

## Tamanhos do Grid

- **Tamanho de cada tile**: 28x28 pixels
- **Grid total**: 33x33 tiles
- **Tamanho total do mapa**: 924x924 pixels

## Prompts para IA

### Para `path.png` (Caminho):
```
"Generate a top-down tileable ground texture for a tower defense game. 
Path/road texture, 28x28 pixels (or 56x56 for better quality), 
pixel art style, seamless/tileable, earthy ground with dirt and grass patches, 
suitable for characters to walk on, medieval fantasy style, 
warm earth tones, brown and green colors."
```

### Para `wall.png` (Barreira/Cerca):
```
"Generate a top-down tileable wall texture for a tower defense game. 
Barrier/fence/wall texture, 28x28 pixels (or 56x56 for better quality), 
pixel art style, seamless/tileable, stone wall or wooden fence, 
medieval fantasy style, dark gray or brown colors, 
solid barrier that blocks movement."
```

## Como Adicionar

1. Gere as duas imagens usando IA
2. Salve como:
   - `godot/assets/images/path.png` (caminho)
   - `godot/assets/images/wall.png` (barreira)
3. O Godot importará automaticamente
4. As texturas serão aplicadas automaticamente no jogo

## Dicas

- **Qualidade**: Use 56x56 ou 84x84 pixels para melhor qualidade visual
- **Tileable**: Certifique-se de que as bordas da imagem se conectam perfeitamente
- **Contraste**: Faça as barreiras visualmente distintas dos caminhos
- **Estilo**: Mantenha um estilo consistente entre as duas texturas
- **Cores**: Use paletas complementares mas distintas

## Fallback

Se as imagens não forem encontradas, o jogo usará cores sólidas:
- Caminho: Cinza escuro (Color(0.18,0.19,0.23))
- Barreira: Cinza médio (Color(0.29,0.32,0.40))

