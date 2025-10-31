# Tower Defence (Godot 4)

Como rodar
- Instale Godot 4.x (recomendado 4.2+).
- No Godot, abra a pasta `godot/` deste repositório (onde está `project.godot`).
- Execute a cena principal (F5). A main scene já está configurada.

Controles
- Clique com o mouse: atira na posição do cursor.
- Fim da wave: aparece overlay com 3 benefícios; clique em um benefício e depois em "Resume" para iniciar a próxima wave.
- Botão "Kill All" no HUD: elimina todos os inimigos (apenas para testes).

O que está implementado
- Grid 30x30 desenhado no canvas.
- Base no centro, labirinto concêntrico com aberturas.
- Inimigos com caminho até o centro (BFS em grid) e escala de HP/quantidade.
- Herói no centro, tiro por clique, upgrades por wave (dano, cadência, perfuração).
- HUD com informações principais e overlay de upgrades com botão Resume.

Estrutura
- `scenes/Main.tscn`: cena principal (HUD, overlay, etc.)
- `scripts/Game.gd`: lógica do jogo (grid, inimigos, tiros, waves, upgrades)

Próximos passos
- Substituir BFS por `AStarGrid2D` ou `NavigationServer2D`.
- Trocar desenho procedural por `TileMap` e sprites.
- Efeitos, partículas, sons e assets dedicados (Kenney, etc.).

Assets (opcionais)
- Coloque imagens em `res://assets/images/` com estes nomes para ativar sprites:
  - `grass.png` (tile de grama), `tent.png` (base)
  - `hero.png`, `enemy_zombie.png`, `enemy_humanoid.png`, `enemy_robot.png`
- Se as imagens não existirem, o jogo usa desenhos vetoriais simples como fallback.
