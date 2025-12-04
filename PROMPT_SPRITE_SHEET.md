# Prompt para Gerar Sprite Sheet de Monstro com 4 Direções

## Prompt Exato para IA de Geração de Imagens:

```
Crie um sprite sheet de um monstro zumbi andando em formato de grid 2x2, com 4 direções de movimento:
- Canto superior esquerdo: monstro virado para CIMA (frente, olhando para cima)
- Canto superior direito: monstro virado para DIREITA (perfil direito, olhando para direita)
- Canto inferior esquerdo: monstro virado para ESQUERDA (perfil esquerdo, olhando para esquerda)
- Canto inferior direito: monstro virado para BAIXO (costas, olhando para baixo)

Especificações técnicas:
- Tamanho total: 128x128 pixels (cada quadro 64x64 pixels)
- Estilo: pixel art, top-down/isométrico, cores escuras e sombrias
- Fundo transparente (PNG com alpha)
- O monstro deve estar na mesma posição relativa em cada quadro (centralizado)
- Animação de caminhada sutil (pernas ligeiramente diferentes entre os quadros)
- Formato: PNG com transparência
- Resolução: alta qualidade, adequada para jogo 2D
- Perspectiva: vista de cima (top-down) ou isométrica
- Cada direção deve ser claramente distinguível
```

## Versão Alternativa (Mais Detalhada):

```
Crie uma sprite sheet de monstro zumbi em formato grid 2x2 para jogo de defesa de torres. 
A imagem deve ter exatamente 128x128 pixels divididos em 4 quadros de 64x64 pixels cada.

Layout do grid:
┌─────────┬─────────┐
│  CIMA   │ DIREITA │
│  (↑)    │   (→)   │
├─────────┼─────────┤
│ ESQUERDA│  BAIXO  │
│   (←)   │   (↓)   │
└─────────┴─────────┘

Especificações:
- Estilo: pixel art, vista de cima (top-down)
- Cores: tons escuros, sombrios, adequados para zumbi
- Fundo: totalmente transparente (PNG com canal alpha)
- Cada quadro: 64x64 pixels
- O monstro deve estar centralizado em cada quadro
- Perspectiva consistente em todas as direções
- Detalhes visíveis: braços, pernas, cabeça, corpo
- Formato final: PNG 128x128 com transparência
```

## Formato do Sprite Sheet:

```
┌─────────┬─────────┐
│  CIMA   │ DIREITA │
│  (↑)    │   (→)   │
├─────────┼─────────┤
│ ESQUERDA│  BAIXO  │
│   (←)   │   (↓)   │
└─────────┴─────────┘
```

Cada quadro tem 64x64 pixels, totalizando 128x128 pixels.

## Como Usar no Godot:

1. Salve a imagem gerada como `enemy_zombie_directional.png` em `godot/assets/images/`
2. O código será modificado para usar `AtlasTexture` ou `ImageTexture` com região
3. A direção será calculada automaticamente baseada no movimento do inimigo

