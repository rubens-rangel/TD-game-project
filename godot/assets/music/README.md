# Músicas de Fundo

## Arquivos de Música

Coloque os arquivos de música nesta pasta:

### Menu
- `menu_music.ogg` ou `menu_music.mp3` - Música de fundo do menu principal

### Jogo
- `game_music.ogg` ou `game_music.mp3` - Música de fundo durante o jogo

## Formatos Suportados

O jogo suporta os seguintes formatos de áudio:
- **OGG Vorbis** (recomendado) - Melhor compressão e qualidade
- **MP3** - Formato alternativo

## Recomendações

- **Tamanho**: Mantenha os arquivos de música em tamanho razoável (2-5 MB por música)
- **Loop**: As músicas devem ser configuradas para fazer loop automaticamente
- **Volume**: O volume padrão está configurado em -5.0 dB (ajustável no código)
- **Duração**: Músicas de 1-3 minutos funcionam bem para loops

## Como Adicionar

1. Coloque o arquivo de música nesta pasta
2. Nomeie conforme indicado acima (`menu_music.ogg` ou `game_music.ogg`)
3. O Godot importará automaticamente o arquivo
4. A música começará a tocar automaticamente quando a cena for carregada

## Ajustar Volume

Para ajustar o volume da música, edite os scripts:
- `scripts/Menu.gd` - Volume da música do menu
- `scripts/Game.gd` - Volume da música do jogo

Ou ajuste diretamente no `MusicPlayer` nas cenas:
- `scenes/Menu.tscn`
- `scenes/Main.tscn`

