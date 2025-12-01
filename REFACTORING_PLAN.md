# Plano de Refatoração - Game.gd

## Objetivo
Modularizar o código do Game.gd (8609 linhas) aplicando boas práticas:
- Separar responsabilidades em classes/modules
- Mover constantes para Constants.gd
- Reutilizar métodos
- Facilitar manutenibilidade
- **Sem quebrar a lógica do jogo**

## Estrutura Proposta

### 1. ✅ Constants.gd - Expandido
- Todas as constantes hardcoded (cores, tamanhos, valores mágicos)
- **Status**: Em progresso

### 2. ✅ RewardCalculator.gd - Criado
- Cálculos de recompensas (inimigos, bosses, waves)
- Cálculos de custos (upgrades, torres, muralhas)
- **Status**: Criado

### 3. ✅ UIManager.gd - Criado (estrutura básica)
- Gerenciamento de toda UI (menus, HUD, skills, DPS)
- Criação e atualização de elementos UI
- Tooltips e overlays
- **Status**: Estrutura básica criada, pode ser expandido

### 4. ✅ TowerSystemManager.gd - Criado
- Lógica de todas as torres (normal, sniper, AOE, shock, slow, boost)
- Updates, disparos, targeting
- Upgrades de torres
- **Status**: Criado e pronto para integração

### 5. ✅ PlacementManager.gd - Criado
- Lógica de colocação de estruturas
- Validação de posições
- Drag and drop
- **Status**: Criado e pronto para integração

### 6. ✅ HeroManager.gd - Criado
- Lógica do herói
- Upgrades do herói
- Hero home upgrades
- **Status**: Criado e pronto para integração

### 7. ✅ VisualEffectsManager.gd - Criado
- Efeitos visuais (animações, partículas)
- Damage numbers
- Death animations
- Coin collect effects
- **Status**: Criado e pronto para integração

### 8. ✅ SkillsManager.gd - Criado
- Gerenciamento de skills
- Cooldowns
- Ativação de skills
- **Status**: Criado e pronto para integração

## Progresso

1. ✅ Adicionar constantes ao Constants.gd
2. ✅ Criar RewardCalculator
3. ✅ Integrar RewardCalculator no Game.gd
4. ✅ Criar UIHelper (métodos reutilizáveis de UI)
5. ✅ Criar UIManager (estrutura básica criada)
6. ⏳ Expandir UIManager com mais funcionalidades
7. ✅ Criar TowerSystemManager
8. ✅ Criar PlacementManager
9. ✅ Criar HeroManager
10. ✅ Criar VisualEffectsManager
11. ✅ Criar SkillsManager
12. ⏳ Refatorar Game.gd para usar os novos managers (opcional - integração gradual)
13. ⏳ Testar tudo para garantir que nada quebrou

## Arquivos Criados

- ✅ `godot/scripts/managers/RewardCalculator.gd` - Cálculos de recompensas (INTEGRADO)
- ✅ `godot/scripts/helpers/UIHelper.gd` - Métodos reutilizáveis de UI
- ✅ `godot/scripts/managers/UIManager.gd` - Gerenciamento de UI (estrutura básica)
- ✅ `godot/scripts/managers/HeroManager.gd` - Lógica do herói e upgrades
- ✅ `godot/scripts/managers/VisualEffectsManager.gd` - Efeitos visuais (animações, partículas)
- ✅ `godot/scripts/managers/SkillsManager.gd` - Sistema de skills
- ✅ `godot/scripts/managers/PlacementManager.gd` - Colocação de estruturas
- ✅ `godot/scripts/managers/TowerSystemManager.gd` - Lógica de todas as torres
- ✅ `godot/scripts/Constants.gd` - Expandido com novas constantes

## Resumo do Progresso

### ✅ Completado (8/8) - TODOS OS MANAGERS CRIADOS!
1. Constants.gd expandido
2. RewardCalculator criado e integrado
3. UIHelper criado
4. UIManager criado (estrutura básica)
5. HeroManager criado
6. VisualEffectsManager criado
7. SkillsManager criado
8. PlacementManager criado
9. TowerSystemManager criado

### ⏳ Próxima Fase: Integração
1. Integrar managers no Game.gd de forma incremental
2. Testar cada integração
3. Expandir funcionalidades conforme necessário

## Notas Importantes

- Refatoração incremental: fazer uma classe por vez e testar
- Manter compatibilidade: Game.gd deve continuar funcionando
- Não alterar lógica: apenas reorganizar código
- Documentar mudanças importantes

