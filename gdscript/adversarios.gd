extends Node2D
class_name Adversario

# Inimigo do jogo. Espelha a estrutura do Jogador: guarda os próprios stats,
# faz a sua própria matemática de combate e roteia texto pelo sinal 'logged'.
#
# Tal como o Jogador, o Adversario NÃO conhece o layout do mapa nem as outras
# entidades. Ele apenas DECIDE a direção para onde quer andar (decide_direcao);
# é o jogo (coldCuts.gd) que valida se esse passo é possível — paredes, limites
# do mapa e tiles ocupados — exatamente como faz com o movimento do jogador.

var x: int = 0
var y: int = 0
var tile_size: int = 16

var nome: String = ""
var sprite_char: String = "?"

var hp: int = 0
var hp_maximo: int = 0
var ataque: int = 0
var armadura: int = 0
var acuracia: int = 0

# A quantos tiles o adversário deteta o jogador e começa a persegui-lo.
# Fora deste alcance, fica parado (não vagueia).
var alcance_visao: int = 8

# Nullable: o Label visual é gerido pelo jogo (como o Sprite2D do Jogador),
# que só atribui esta referência depois de o criar.
var label: Label = null

# Roteamento de texto: qualquer print() do adversário passa por aqui.
# coldCuts.gd conecta este sinal ao seu _log() para exibir no terminal in-game.
signal logged(text: String)


func _log(text: String) -> void:
	print(text)
	logged.emit(text)


# Inicializa a partir de uma entrada do adversarios.json.
func cria_adversario(data: Dictionary, _x: int, _y: int) -> void:
	nome = data["nome"]
	sprite_char = data["sprite"]
	hp = int(data["hp"])
	hp_maximo = hp
	ataque = int(data["ataque"])
	armadura = int(data["armadura"])
	acuracia = randi_range(25, 90)
	x = _x
	y = _y


func verifica_acerto() -> bool:
	return randi_range(1, 100) <= acuracia


# Distância de Chebyshev (8 direções), a mesma métrica do movimento do jogador.
func distancia_para(alvo_x: int, alvo_y: int) -> int:
	return maxi(abs(alvo_x - x), abs(alvo_y - y))


# Está a um único passo do alvo (incluindo diagonais)? Então pode atacar.
func esta_adjacente(alvo_x: int, alvo_y: int) -> bool:
	return distancia_para(alvo_x, alvo_y) == 1


# Decide a direção (Vector2i de -1..1 em cada eixo) rumo ao alvo.
# Devolve Vector2i.ZERO se o alvo estiver fora do alcance de visão.
# O jogo é que decide se o passo é válido; aqui só há a "intenção".
func decide_direcao(alvo_x: int, alvo_y: int) -> Vector2i:
	if distancia_para(alvo_x, alvo_y) > alcance_visao:
		return Vector2i.ZERO
	return Vector2i(signi(alvo_x - x), signi(alvo_y - y))


# Aplica de facto o movimento já validado pelo jogo e reposiciona o Label.
func move_para(novo_x: int, novo_y: int) -> void:
	x = novo_x
	y = novo_y
	if is_instance_valid(label):
		label.position = Vector2(x * tile_size, y * tile_size)


# Ataca o jogador. Espelha a lógica de Jogador.ataca: a precisão decide o
# acerto e a armadura do alvo absorve (e desgasta-se) antes do dano ao HP.
# Mutar os campos do jogador aqui é coerente com o estilo do projeto, em que o
# atacante resolve a matemática sobre o defensor.
func ataca(jogador) -> void:
	if not verifica_acerto():
		_log("%s avança sobre %s, mas erra o golpe!" % [nome, jogador.nome])
		return

	var dano_restante := ataque
	if jogador.armadura > 0:
		var dano_absorvido := mini(dano_restante, jogador.armadura)
		jogador.armadura -= dano_absorvido
		dano_restante -= dano_absorvido
		_log("%s atacou %s! Armadura absorveu %d de dano! (Armadura: %d)" % [nome, jogador.nome, dano_absorvido, jogador.armadura])

	if dano_restante > 0:
		jogador.hp -= dano_restante
		_log("%s causou %d de dano em %s! (HP: %d)" % [nome, dano_restante, jogador.nome, jogador.hp])
	else:
		_log("A armadura de %s resistiu completamente!" % jogador.nome)

	if jogador.hp <= 0:
		jogador.lida_morte(nome)
