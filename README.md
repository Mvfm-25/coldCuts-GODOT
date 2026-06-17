# coldCuts-GODOT
Versão criada em Godot & GDScript do jogo originalmente escrito em Python no repositório `cellularAutomata`.
[11-04-2026][mvfm] — última atualização: [17-06-2026]

---

# PDJ-2026/01
Esse projeto faz parte das entregas contínuas da disciplina **Projeto & Desenvolvimento de Jogos** da PUCRS.

---

## Visão geral

`coldCuts-GODOT` é um *roguelike* de masmorras em vista de cima, com estética de terminal,
onde o jogador explora cavernas geradas proceduralmente, enfrenta inimigos, recolhe itens e
descobre palavras mágicas que selam pactos para invocar masmorras de boss.

O projeto reúne duas frentes que partilham o mesmo gerador de masmorras:
1. **Gerador de masmorras** (autômato celular) — cria, edita e guarda mapas.
2. **Jogo jogável** — carrega esses mapas e roda o loop completo de roguelike.

### Princípio de arquitetura

As entidades (Jogador e Adversário) **não conhecem o mapa** nem as outras entidades.
Cada uma apenas guarda os próprios atributos, resolve a sua própria matemática de combate e
declara *intenções* (mover numa direção, atacar, falar uma frase). É o `coldCuts.gd` — o dono
do estado do jogo — que valida tudo contra o layout do mapa, a lista de inimigos e os pactos.
Essa divisão é deliberada e mantida em todo o código.

---

## Estado atual do projeto

### Estrutura de arquivos relevantes
```
coldCuts-GODOT/
├── gdscript/
│   ├── cellularAutomata.gd    # Gerador de masmorras (autômato celular) + I/O
│   ├── coldCuts.gd            # Loop principal do jogo (orquestrador / dono do estado)
│   ├── jogador.gd             # Entidade Jogador (stats, combate, inventário, palavras)
│   ├── adversarios.gd         # Entidade Adversário (IA de perseguição + combate)
│   └── terminal.gd            # HUD: painéis de status, controles e terminal in-game
├── scenes/
│   ├── coldCuts.tscn          # Cena principal — o jogo jogável (main scene)
│   ├── dungeonGenerator.tscn  # Cena do gerador de masmorras
│   ├── jogador.tscn           # Cena da entidade Jogador
│   ├── terminal.tscn          # Cena da HUD/terminal
│   └── node.tscn              # Tile sprite (Sprite2D reutilizado pelas cenas)
├── entidades/
│   ├── adversarios.json       # Catálogo de inimigos (stats)
│   ├── items.json             # Catálogo de itens
│   └── palavras.json          # Enigma, palavras mágicas e pactos
├── dungeons/                  # Masmorras salvas em JSON (.dungeon), incluindo as de boss
├── assets/
│   ├── player/                # Sprites do jogador
│   └── sprites/               # Sprites de inimigos
├── lifeInEffect.tscn          # Legado: experimento inicial de familiarização com a engine
└── project.godot              # Main scene: scenes/coldCuts.tscn
```

---

### `cellularAutomata.gd` — Gerador de Masmorras
Cena: **`scenes/dungeonGenerator.tscn`**

Gera e visualiza masmorras via autômato celular. Contém três classes internas:
- **`Ameba`** — célula individual da grade (parede `"1"` ou chão `"0"`), com cálculo de vizinhos.
- **`Dungeon`** — grade completa com geração procedural (regras do autômato + mutação aleatória 25%),
  nomeação procedural em português e marcação de masmorras de boss (`is_boss`).
- **`DungeonIO`** — salva e carrega masmorras no formato JSON (`.dungeon`).

Funcionalidades da UI:
- Criar masmorra automaticamente (autômato celular, gerações configuráveis)
- Criar masmorra manualmente (clique para pintar tiles)
- Carregar masmorra existente (FileDialog)
- Popup de info ao clicar com botão direito em qualquer tile

---

### `coldCuts.gd` — Jogo Jogável
Cena principal: **`scenes/coldCuts.tscn`**

Orquestrador do jogo e dono de todo o estado. Ao iniciar, mostra um menu para criar o personagem
(nome + uma de quatro classes) e então:
1. Carrega uma masmorra aleatória (não-boss) dos arquivos `.dungeon` existentes.
2. Renderiza a grade de tiles e povoa o mapa com inimigos e itens a partir dos catálogos JSON.
3. Posiciona o jogador numa célula de chão aberta e garante a presença de uma Chave no mapa.

**Sistemas implementados:**

- **Quatro classes jogáveis** — Bárbaro, Mago, Cavaleiro e Ladrão, cada uma com HP, ataque,
  armadura, acurácia e curva de XP próprios.
- **Campo de visão / fog of war** — *recursive shadowcasting* em 8 octantes com raio de luz à
  volta do jogador; o resto do mapa permanece escuro.
- **Combate direcional** — `A` + direção, espelhando o `coldCuts.py` original. A armadura absorve
  e desgasta-se antes do dano ao HP; precisão decide o acerto.
- **Inimigos com IA** (`adversarios.gd`) — perseguem o jogador dentro do alcance de visão (distância
  de Chebyshev) e atacam quando adjacentes. Como o jogador, só declaram intenção de movimento; o
  jogo valida o passo.
- **Inventário e itens** — Poção de Vida (cura), Moeda de Ouro, Chave, Pergaminho (XP + progresso)
  e Ruby. Itens usáveis têm efeitos próprios.
- **Portal secreto** — gasta uma Chave para abrir uma passagem.
- **Progressão e nível** — derrotar inimigos e ler pergaminhos concede XP e sobe de nível, melhorando
  os atributos conforme a classe.
- **HUD em estilo terminal** (`terminal.gd`) — três painéis: status do jogador, lista de controles e
  um log de mensagens (faux-terminal) com as últimas ações.

---

### Palavras mágicas, pactos e bosses

Definidos em `entidades/palavras.json` e validados pelo `coldCuts.gd`.

- O jogador **ganha** palavras mágicas ao cruzar limiares de progresso (ex.: derrotar 5 inimigos,
  ler 5 pergaminhos). Descobrir uma frase não basta — é preciso ter conquistado cada palavra.
- Falar (`F`) uma frase que case com um **pacto** dispara o seu efeito. O pacto atual,
  `aye mak sicur`, **invoca uma masmorra de boss** ao custo de uma Chave do inventário.
- O **dicionário** (`G`) permite consultar o glossário das palavras já lembradas.

**Frases de debug** (reconhecidas diretamente, sem pacto):
- `1701 exterminatus` — extermina todos os inimigos do mapa.
- `2553 codex` — concede Pergaminhos ao inventário do jogador.

---

### Controles

| Ação | Tecla |
|---|---|
| Mover (cardeais) | Setas / W S A D / Numpad 8 2 4 6 |
| Mover (diagonais) | Q E Z C / Numpad 7 9 1 3 |
| Atacar | `A` + direção |
| Inventário | `I` |
| Usar item | `U` |
| Dicionário | `G` |
| Portal | `P` |
| Falar | `F` |

Colisão com paredes e limites do mapa é verificada antes de cada movimento.
