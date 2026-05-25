# coldCuts-GODOT
Versão criada em Godot & GDScript do jogo criado em Python no repositório `cellularAutomata`.
[11-04-2026][mvfm] — última atualização: [23-05-2026]

---

# PDJ-2026/01
Esse projeto faz parte das entregas contínuas da disciplina **Projeto & Desenvolvimento de Jogos** da PUCRS.

---

## Estado atual do projeto

### Estrutura de arquivos relevantes
```
coldCuts-GODOT/
├── gdscript/
│   ├── cellularAutomata.gd   # Gerador de masmorras (autômato celular)
│   └── jogo.gd               # Loop principal do jogo (jogador + movimento)
├── scenes/
│   ├── lifeInEffect.tscn     # Cena do gerador de masmorras
│   ├── jogo.tscn             # Cena do jogo jogável
│   └── node.tscn             # Tile sprite (Sprite2D reutilizado por ambas as cenas)
├── dungeons/                 # Masmorras salvas em JSON (.dungeon)
├── assets/
│   └── player/
│       └── Funny_Little_Fella.png   # Sprite do jogador
└── project.godot
```

### `cellularAutomata.gd` — Gerador de Masmorras
Cena principal: **`lifeInEffect.tscn`**

Gera e visualiza masmorras via autômato celular. Contém três classes internas:
- **`Ameba`** — célula individual da grade (parede `"1"` ou chão `"0"`), com cálculo de vizinhos.
- **`Dungeon`** — grade completa com geração procedural (regras do autômato + mutação aleatória 25%) e nomeação procedural em português.
- **`DungeonIO`** — salva e carrega masmorras no formato JSON (`.dungeon`).

Funcionalidades da UI:
- Criar masmorra automaticamente (autômato celular, gerações configuráveis)
- Criar masmorra manualmente (click para pintar tiles)
- Carregar masmorra existente (FileDialog)
- Popup de info ao clicar com botão direito em qualquer tile

### `jogo.gd` — Jogo Jogável
Cena principal: **`jogo.tscn`**

Implementa o loop de jogo básico inspirado no `coldCuts.py` original. Ao iniciar:
1. Carrega uma masmorra aleatória dos arquivos `.dungeon` existentes.
2. Renderiza a grade de tiles (reutilizando `node.tscn` e as classes de `cellularAutomata.gd`).
3. Posiciona o jogador na primeira célula de chão aberta (≤ 3 vizinhos de parede).

**Controles de movimento** (8 direções):

| Tecla | Direção |
|---|---|
| W / ↑ | Cima |
| S / ↓ | Baixo |
| A / ← | Esquerda |
| D / → | Direita |
| Q / Numpad 7 | ↖ diagonal |
| E / Numpad 9 | ↗ diagonal |
| Z / Numpad 1 | ↙ diagonal |
| C / Numpad 3 | ↘ diagonal |

Colisão com paredes é verificada antes de cada movimento. Se a sprite `Funny_Little_Fella.png` não for encontrada, um placeholder azul é exibido.
