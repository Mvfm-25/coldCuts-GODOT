extends Node2D
class_name Jogador

# As palavras mágicas e os pactos vivem em entidades/palavras.json e são
# validados pelo coldCuts.gd: o Jogador apenas reporta o que diz (ver falar())
# e quais palavras já se lembra (ver lembra_palavra()).

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

# Progresso que desbloqueia palavras mágicas (ver palavras.json). O Jogador só
# conta os próprios feitos; é o coldCuts.gd que decide que palavra cada feito
# concede e a entrega via lembra_palavra().
var inimigos_derrotados: int = 0
var pergaminhos_lidos: int = 0
# Palavras mágicas já lembradas, em minúsculas (ver ja_lembra()/lembra_palavra()).
var palavras_lembradas: Array = []

# Roteamento de texto: qualquer print() do jogador passa por aqui.
# coldCuts.gd conecta este sinal ao seu _log() para exibir no terminal in-game.
signal logged(text: String)

signal morreu(adversario_nome: String)
signal nivel_subiu(novo_nivel: int)
signal pediu_portal
# O jogador entoou uma frase; cabe ao coldCuts.gd validá-la contra os pactos.
signal disse(frase: String)
# Um contador de progresso mudou (tipo + novo valor); o jogo verifica se isso
# desbloqueia alguma palavra mágica.
signal progrediu(tipo: String, valor: int)

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
		inimigos_derrotados += 1
		progrediu.emit("inimigos_derrotados", inimigos_derrotados)
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
						pergaminhos_lidos += 1
						progrediu.emit("pergaminhos_lidos", pergaminhos_lidos)
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


# Concede uma palavra mágica ao Jogador (chamado pelo coldCuts.gd ao cruzar um
# limiar de progresso). Também entra no dicionário, para a consulta (tecla G).
func lembra_palavra(palavra: String, glossario: String) -> void:
	var chave := palavra.strip_edges().to_lower()
	if chave.is_empty() or chave in palavras_lembradas:
		return
	palavras_lembradas.append(chave)
	dicionario.append([palavra, glossario])


func ja_lembra(palavra: String) -> bool:
	return palavra.strip_edges().to_lower() in palavras_lembradas


# O jogador entoa uma frase em voz alta. O Jogador não conhece o mapa, os
# inimigos nem os pactos: apenas reporta o que disse via o sinal 'disse', e o
# coldCuts.gd valida-o contra palavras.json e resolve o efeito.
func falar(frase: String) -> void:
	var dito := frase.strip_edges()
	if dito.is_empty():
		return
	_log("Você entoa: \"%s\"" % dito)
	disse.emit(dito)


# Procura uma chave (sprite "C") no inventário; se houver, gasta-a (como usa_item)
# e devolve true. Chamado pelo jogo ao selar um pacto que exige uma chave.
func consome_chave() -> bool:
	for i in range(inventario.size()):
		if inventario[i][1].sprite_char == "C":
			inventario.remove_at(i)
			return true
	return false


func _tile_pixel_pos(gx: int, gy: int) -> Vector2:
	return Vector2(gx * tile_size + tile_size * 0.5, gy * tile_size + tile_size * 0.5)
