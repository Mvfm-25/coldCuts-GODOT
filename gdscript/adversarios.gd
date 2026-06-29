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
# Nota de bestiário (ver adversarios.json). O jogo regista-a no dicionário do
# Jogador quando este avista a criatura, para consulta pela tecla G.
var glossario: String = ""

var hp: int = 0
var hp_maximo: int = 0
var ataque: int = 0
var armadura: int = 0
var acuracia: int = 0

# Magia (só alguns adversários a têm — ver adversarios.json). Como o resto da IA,
# o Adversario apenas DECIDE lançar uma magia (decide_magia); é o coldCuts.gd que
# conhece o mapa e resolve o efeito (alvo, área, corpos a reerguer).
var mana: int = 0
var mana_maximo: int = 0
var magias: Array = []
# Frases de provocação ditas em combate (ver provoca()).
var insultos: Array = []
# Turnos restantes preso no gelo (feitiço Congelar do jogador). > 0 = perde a vez.
var congelado: int = 0

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
	mana = int(data.get("mana", 0))
	mana_maximo = mana
	magias = data.get("magias", [])
	insultos = data.get("insultos", [])
	glossario = str(data.get("glossario", ""))
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
	# De vez em quando, a criatura cospe uma provocação antes de golpear.
	if randi_range(1, 100) <= 30:
		var dito := provoca()
		if dito != "":
			_log("%s: \"%s\"" % [nome, dito])

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


# --- Magia e provocações ---

# Devolve uma provocação aleatória (ou "" se a criatura não tiver nenhuma).
func provoca() -> String:
	if insultos.is_empty():
		return ""
	return str(insultos[randi_range(0, insultos.size() - 1)])


func gasta_mana(custo: int) -> bool:
	if mana < custo:
		return false
	mana -= custo
	return true


func recupera_mana(quantia: int) -> void:
	mana = mini(mana_maximo, mana + quantia)


# Cura as próprias feridas (feitiço Curar do lado inimigo).
func cura_se(quantia: int) -> void:
	var real := mini(quantia, hp_maximo - hp)
	hp += real
	_log("%s recompõe a própria carne: +%d de HP! (HP: %d/%d)" % [nome, real, hp, hp_maximo])


# Decide se quer lançar uma magia neste turno e qual. Como o resto da IA, só
# declara a INTENÇÃO: devolve a magia escolhida (um Dictionary do adversarios.json)
# ou {} para nada lançar. É o coldCuts.gd que conhece o mapa e resolve o efeito —
# alvo, área, corpos a reerguer, etc. 'distancia_ao_jogador' é a distância de
# Chebyshev que o jogo já calculou.
func decide_magia(distancia_ao_jogador: int) -> Dictionary:
	if magias.is_empty() or congelado > 0:
		return {}
	# Só lança parte das vezes, para o corpo-a-corpo continuar a contar.
	if randf() > 0.6:
		return {}

	# Magias que consegue pagar agora.
	var possiveis: Array = []
	for m in magias:
		if int(m.get("custo_mana", 0)) <= mana:
			possiveis.append(m)
	if possiveis.is_empty():
		return {}

	# Ferido? Tenta curar-se primeiro.
	if hp < hp_maximo / 2:
		for m in possiveis:
			if str(m.get("tipo", "")) == "cura":
				return m

	# Jogador ao alcance? Prefere uma magia ofensiva.
	for m in possiveis:
		var tipo := str(m.get("tipo", ""))
		if (tipo == "dano" or tipo == "area_dano" or tipo == "congelar") \
				and distancia_ao_jogador >= 1 and distancia_ao_jogador <= int(m.get("alcance", 0)):
			return m

	# Caso contrário, talvez erguer um servo tombado (o jogo confirma se há corpos).
	for m in possiveis:
		if str(m.get("tipo", "")) == "reviver":
			return m

	return {}
