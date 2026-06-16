extends Node2D
class_name Jogador

# Frase secreta que invoca uma masmorra de boss (ver falar()).
const FRASE_BOSS := "aye mak sicur"
# Frase de debug que extermina todos os inimigos do mapa (ver falar()).
const FRASE_EXTERMINATUS := "1701 exterminatus"

var _sprites: Dictionary = {
	"Bárbaro":   "res://assets/player/barbaro.png",
	"Mago":      "res://assets/player/mago.png",
	"Cavaleiro": "res://assets/player/cavaleiro.png",
	"Ladrão":    "res://assets/player/ladrao.png",
}

var x: int = 0
var y: int = 0
var tile_size: int = 16

var nome: String = ""
var sprite_char: String = "@"
var classe: String = ""

var lvl: int = 1
var xp: int = 0
var xp_proximo_nivel: int = 0

var hp: int = 0
var hp_maximo: int = 0
var ataque: int = 0
var armadura: int = 0
var acuracia: int = 0

var inventario: Array = []
var ultimo_item_inserido: int = 0
var dicionario: Array = []

# Roteamento de texto: qualquer print() do jogador passa por aqui.
# coldCuts.gd conecta este sinal ao seu _log() para exibir no terminal in-game.
signal logged(text: String)

signal morreu(adversario_nome: String)
signal nivel_subiu(novo_nivel: int)
signal pediu_portal
signal pediu_boss
signal pediu_exterminatus

# Nullable: coldCuts gerencia o Sprite2D diretamente; só é atribuído se o nó existir.
var _sprite: Sprite2D = null


func _ready() -> void:
	if has_node("Sprite2D"):
		_sprite = $Sprite2D


func _log(text: String) -> void:
	print(text)
	logged.emit(text)


func cria_personagem(nome_jogador: String, escolha_classe: String) -> void:
	nome = nome_jogador
	match escolha_classe:
		"1", "Bárbaro":
			classe = "Bárbaro"
			hp = 150; hp_maximo = 150; ataque = 20; armadura = 0; acuracia = 80; xp_proximo_nivel = 100
		"2", "Mago":
			classe = "Mago"
			hp = 100; hp_maximo = 100; ataque = 15; armadura = 5; acuracia = 85; xp_proximo_nivel = 175
		"3", "Cavaleiro":
			classe = "Cavaleiro"
			hp = 125; hp_maximo = 125; ataque = 10; armadura = 10; acuracia = 90; xp_proximo_nivel = 150
		"4", "Ladrão":
			classe = "Ladrão"
			hp = 110; hp_maximo = 110; ataque = 12; armadura = 5; acuracia = 95; xp_proximo_nivel = 125

	if _sprite:
		var tex_path: String = _sprites.get(classe, "")
		if tex_path != "" and ResourceLoader.exists(tex_path):
			_sprite.texture = load(tex_path)

	_log("Personagem: %s | Classe: %s | HP: %d | Ataque: %d | Armadura: %d" % [nome, classe, hp, ataque, armadura])


func verifica_acerto() -> bool:
	return randi_range(1, 100) <= acuracia


# Ataque direcional, espelhando coldCuts.py.
# O jogador NÃO conhece o mapa nem a lista de inimigos: o jogo resolve qual é o
# alvo (ou se há parede) na direção escolhida e passa o resultado pronto aqui.
#   alvo         : objeto de inimigo com .nome/.hp/.armadura, ou null se não houver
#   bateu_parede : true se a direção atingiu uma parede ou o limite do mapa
# Retorna true quando o inimigo é derrotado, para o jogo removê-lo do mapa.
func ataca(alvo, bateu_parede: bool = false) -> bool:
	if alvo == null:
		if bateu_parede:
			_log("Sua arma atingiu uma parede!")
			if randi_range(1, 100) >= 95:
				hp -= ataque
				_log("Ela rebate e lhe atinge, causando %d de dano!" % ataque)
		else:
			_log("Sua arma é usada para atingir o ar!")
		return false

	var dano_restante := ataque
	if alvo.armadura > 0:
		var dano_absorvido := mini(dano_restante, alvo.armadura)
		alvo.armadura -= dano_absorvido
		dano_restante -= dano_absorvido
		_log("%s atacou %s! Armadura absorveu %d de dano! (Armadura: %d)" % [nome, alvo.nome, dano_absorvido, alvo.armadura])
	if dano_restante > 0:
		alvo.hp -= dano_restante
		_log("%s causou %d de dano em %s! (HP: %d)" % [nome, dano_restante, alvo.nome, alvo.hp])
	else:
		_log("A armadura de %s resistiu completamente!" % alvo.nome)

	if alvo.hp <= 0:
		_log("*** Você derrotou %s! ***" % alvo.nome)
		checa_nivel(50)
		return true
	return false


func checa_inventario() -> void:
	if not inventario.is_empty():
		_log("Itens no inventário:")
		for entrada in inventario:
			_log("  %d - %s (Valor: %d)" % [entrada[0], entrada[1].nome, entrada[1].valor])
	else:
		_log("Inventário vazio!")


func adiciona_item_inventario(item) -> void:
	inventario.append([ultimo_item_inserido, item])
	ultimo_item_inserido += 1
	dicionario.append([item.nome, item.glossario])
	_log("Item '%s' adicionado ao inventário!" % item.nome)


func usa_item(id: int, _dungeon = null) -> bool:
	for i in range(inventario.size()):
		if inventario[i][0] == id:
			var item = inventario[i][1]
			if item.usavel:
				_log("Usando item: %s" % item.nome)
				match item.sprite_char:
					"V":
						var cura_real := mini(50, hp_maximo - hp)
						hp += cura_real
						_log("Você recuperou %d de HP! (HP: %d/%d)" % [cura_real, hp, hp_maximo])
						inventario.remove_at(i)
						return true
					"C":
						_log("Você sente que um caminho novo se abriu...")
						inventario.remove_at(i)
						pediu_portal.emit()
						return true
					"P":
						_log("Você lê o pergaminho e ganha sabedoria!")
						xp += 20
						inventario.remove_at(i)
						return true
				inventario.remove_at(i)
				return true
			else:
				_log("O item '%s' não pode ser usado." % item.nome)
				return false
	_log("Nenhum item com ID %d encontrado." % id)
	return false


func checa_nivel(adicao_xp: int) -> void:
	if (xp + adicao_xp) >= xp_proximo_nivel:
		lvl += 1
		xp = (xp + adicao_xp) - xp_proximo_nivel
		xp_proximo_nivel = int(xp_proximo_nivel * 1.50)
		_log("Parabéns! Você subiu de nível!")
		match classe:
			"Bárbaro": hp += 15; hp_maximo += 15; ataque += 5; armadura += 1
			"Mago":    hp += 5;  hp_maximo += 5;  ataque += 7; armadura += 2
			"Cavaleiro": hp += 10; hp_maximo += 10; ataque += 3; armadura += 5
			"Ladrão":  hp += 5;  hp_maximo += 5;  ataque += 4; armadura += 3
		_log("Nível: %d | HP: %d | Ataque: %d | Armadura: %d" % [lvl, hp, ataque, armadura])
		nivel_subiu.emit(lvl)
	else:
		xp += adicao_xp
		_log("Você ganhou %dxp!" % adicao_xp)


func lida_morte(adversario_nome: String) -> void:
	_log("Você morreu! Sua aventura termina aqui, %s..." % nome)
	_log("%s se certificou disso!" % adversario_nome)
	_log("Você passou %d meses nas cavernas... Acumulou %d de conhecimento." % [lvl, xp])
	morreu.emit(adversario_nome)


func abre_dicionario(pesquisa: String) -> void:
	_log("Você alcança por suas anotações...")
	_log("Procurando por '%s'..." % pesquisa)
	for entrada in dicionario:
		if pesquisa.to_lower() in entrada[0].to_lower():
			_log("%s --- %s" % [entrada[0], entrada[1]])
			return
	_log("Palavra '%s' não está em seu vocabulário..." % pesquisa)


# O jogador entoa uma frase em voz alta. Frases reconhecidas disparam sinais
# para o jogo agir; o Jogador não conhece o mapa nem a lista de inimigos, só
# dispara o sinal — resolver o efeito é trabalho do coldCuts.gd.
func falar(frase: String) -> void:
	var dito := frase.strip_edges()
	if dito.is_empty():
		return
	_log("Você entoa: \"%s\"" % dito)

	match dito.to_lower():
		FRASE_BOSS:
			# Invoca uma masmorra de boss, à custa de uma chave do inventário.
			if not _consome_chave():
				_log("As palavras ressoam com poder, mas falta-lhe uma chave para selar o pacto.")
				return
			_log("A chave se desfaz em pó enquanto as palavras rasgam o véu da realidade!")
			_log("Um covil de boss o reclama...")
			pediu_boss.emit()
		FRASE_EXTERMINATUS:
			# Comando de debug: extermina todos os inimigos do mapa.
			_log("EXTERMINATUS! Uma luz purificadora varre a masmorra.")
			pediu_exterminatus.emit()
		_:
			_log("As palavras se perdem no eco da masmorra...")


# Procura uma chave (sprite "C") no inventário; se houver, gasta-a (como usa_item)
# e devolve true. Mantém o uso de itens uniforme: a chave é consumida ao falar.
func _consome_chave() -> bool:
	for i in range(inventario.size()):
		if inventario[i][1].sprite_char == "C":
			inventario.remove_at(i)
			return true
	return false


func _tile_pixel_pos(gx: int, gy: int) -> Vector2:
	return Vector2(gx * tile_size + tile_size * 0.5, gy * tile_size + tile_size * 0.5)
