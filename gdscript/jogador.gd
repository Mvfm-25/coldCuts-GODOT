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
# A 'forca' substitui o antigo 'ataque': é a base do dano E o requisito que decide
# que armas o jogador consegue empunhar (ver equipa_arma()/forca_necessaria).
var forca: int = 0
var armadura: int = 0
var acuracia: int = 0
# Fôlego das palavras de poder: cada feitiço (ver falar()/magias) gasta mana;
# regenera devagar a cada turno e enche-se por inteiro a cada nível.
var mana: int = 0
var mana_maximo: int = 0

# --- Equilíbrio do dano por arma (ajusta estes valores à vontade) ---
# Força ACIMA do requisito da arma rende dano extra, mas a esse mesmo excedente
# corresponde uma perda de acurácia: empunhar uma arma leve com força a mais
# fá-la "passar dos limites" e o golpe sai menos preciso. Aqui está o balanço.
const BONUS_DANO_POR_EXCEDENTE := 0.5      # +1 de dano por cada 2 de força excedente
const PENALIDADE_ACC_POR_EXCEDENTE := 0.5  # -1 de acurácia por cada 2 de força excedente
const ACURACIA_MINIMA := 20                # nunca abaixo disto, por pior que seja a combinação

# A arma atualmente empunhada (objeto coldCuts.Arma) ou null (combate desarmado).
# As armas guardadas e não equipadas vivem em 'armas' (a tela de troca lê daqui).
# São objetos untyped, como 'alvo' em ataca() e 'item' no inventário: o Jogador
# só lê os campos (.dano, .alcance, .forca_necessaria...) sem conhecer a classe.
var arma_equipada = null
var armas: Array = []

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
# Feitiços já dominados, pelo nome em minúsculas (ver aprende_magia()). A sua
# definição (mana, alcance, efeito) vive em palavras.json e é resolvida pelo
# coldCuts.gd — o Jogador só sabe que os domina e quanto mana tem.
var magias_aprendidas: Array = []
# Turnos restantes preso no gelo (feitiço Congelar inimigo). > 0 = perde a vez.
var congelado: int = 0

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
			hp = 150; hp_maximo = 150; forca = 20; armadura = 0; acuracia = 80; xp_proximo_nivel = 100
			mana = 0; mana_maximo = 0
		"2", "Mago":
			classe = "Mago"
			hp = 100; hp_maximo = 100; forca = 15; armadura = 5; acuracia = 85; xp_proximo_nivel = 175
			mana = 40; mana_maximo = 40
		"3", "Cavaleiro":
			classe = "Cavaleiro"
			hp = 125; hp_maximo = 125; forca = 10; armadura = 10; acuracia = 90; xp_proximo_nivel = 150
			mana = 10; mana_maximo = 10
		"4", "Ladrão":
			classe = "Ladrão"
			hp = 110; hp_maximo = 110; forca = 12; armadura = 5; acuracia = 95; xp_proximo_nivel = 125
			mana = 15; mana_maximo = 15

	if _sprite:
		var tex_path: String = _sprites.get(classe, "")
		if tex_path != "" and ResourceLoader.exists(tex_path):
			_sprite.texture = load(tex_path)

	_log("Personagem: %s | Classe: %s | HP: %d | Força: %d | Armadura: %d | Mana: %d" % [nome, classe, hp, forca, armadura, mana])


# --- Armas: dano, acurácia e alcance efetivos ---
# Estes três derivam da força do Jogador combinada com a arma equipada. O Jogador
# pode calculá-los sozinho: a arma é estado próprio dele, não conhecimento do mapa.

# Dano de um golpe: força + dano da arma + bónus pelo excedente de força.
func dano_atual() -> int:
	if arma_equipada == null:
		return forca
	var excedente := maxi(0, forca - arma_equipada.forca_necessaria)
	return forca + arma_equipada.dano + int(excedente * BONUS_DANO_POR_EXCEDENTE)


# Acurácia efetiva: a base, penalizada pelo excedente de força sobre a arma.
# Quanto mais leve a arma para a tua força, mais o golpe perde precisão.
func acuracia_atual() -> int:
	if arma_equipada == null:
		return acuracia
	var excedente := maxi(0, forca - arma_equipada.forca_necessaria)
	return clampi(acuracia - int(excedente * PENALIDADE_ACC_POR_EXCEDENTE), ACURACIA_MINIMA, 100)


# Quantas casas o golpe alcança (1 = corpo-a-corpo). O jogo lê isto para varrer
# a direção do ataque até encontrar um alvo ou uma parede.
func alcance_arma() -> int:
	return arma_equipada.alcance if arma_equipada != null else 1


func verifica_acerto() -> bool:
	return randi_range(1, 100) <= acuracia_atual()


# Ataque direcional, espelhando coldCuts.py.
# O jogador NÃO conhece o mapa nem a lista de inimigos: o jogo resolve qual é o
# alvo (ou se há parede) na direção escolhida e passa o resultado pronto aqui.
#   alvo         : objeto de inimigo com .nome/.hp/.armadura, ou null se não houver
#   bateu_parede : true se a direção atingiu uma parede ou o limite do mapa
# Retorna true quando o inimigo é derrotado, para o jogo removê-lo do mapa.
func ataca(alvo, bateu_parede: bool = false) -> bool:
	var dano := dano_atual()
	if alvo == null:
		if bateu_parede:
			_log("Sua arma atingiu uma parede!")
			if randi_range(1, 100) >= 95:
				hp -= dano
				_log("Ela rebate e lhe atinge, causando %d de dano!" % dano)
		else:
			_log("Sua arma é usada para atingir o ar!")
		return false

	# A acurácia (já modificada pela arma equipada) decide se o golpe acerta.
	if not verifica_acerto():
		_log("%s ataca %s, mas o golpe passa ao lado!" % [nome, alvo.nome])
		return false

	var dano_restante := dano
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
		registra_abate(alvo.nome)
		return true
	return false


# Contabiliza um inimigo derrotado, seja por arma (ataca()) ou por feitiço
# (resolvido no coldCuts.gd). Concede XP e faz progredir o contador que
# desbloqueia palavras/magias (sinal 'progrediu').
func registra_abate(nome_alvo: String) -> void:
	_log("*** Você derrotou %s! ***" % nome_alvo)
	checa_nivel(50)
	inimigos_derrotados += 1
	progrediu.emit("inimigos_derrotados", inimigos_derrotados)


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


# --- Armas ---

# Verifica se o Jogador cumpre os requisitos da arma. Compara os atributos BASE
# (força e acurácia brutas), não os modificados pela arma: é a tua aptidão a empunhá-la.
func cumpre_requisitos(arma) -> bool:
	return forca >= arma.forca_necessaria and acuracia >= arma.precisao_necessaria


# Guarda uma arma apanhada. Se ainda não há nada equipado e ela serve, empunha-a logo.
func adiciona_arma(arma) -> void:
	armas.append(arma)
	dicionario.append([arma.nome, arma.glossario])
	_log("Arma '%s' adicionada ao arsenal!" % arma.nome)
	if arma_equipada == null and cumpre_requisitos(arma):
		equipa_arma(armas.size() - 1)


# Equipa a arma no índice dado da lista 'armas', devolvendo a antiga ao arsenal.
# Falha (e explica porquê) se a força ou a acurácia não chegarem para a empunhar.
func equipa_arma(indice: int) -> bool:
	if indice < 0 or indice >= armas.size():
		return false
	var arma = armas[indice]
	if forca < arma.forca_necessaria:
		_log("Força insuficiente para empunhar %s (precisa de %d, tens %d)." % [arma.nome, arma.forca_necessaria, forca])
		return false
	if acuracia < arma.precisao_necessaria:
		_log("Falta-te perícia para %s (precisa de %d de acurácia, tens %d)." % [arma.nome, arma.precisao_necessaria, acuracia])
		return false

	armas.remove_at(indice)
	if arma_equipada != null:
		armas.append(arma_equipada)
	arma_equipada = arma
	_log("Empunhas agora: %s." % arma.nome)
	return true


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
			"Bárbaro": hp += 15; hp_maximo += 15; forca += 5; armadura += 1
			"Mago":    hp += 5;  hp_maximo += 5;  forca += 7; armadura += 2; mana_maximo += 8
			"Cavaleiro": hp += 10; hp_maximo += 10; forca += 3; armadura += 5; mana_maximo += 2
			"Ladrão":  hp += 5;  hp_maximo += 5;  forca += 4; armadura += 3; mana_maximo += 3
		# Subir de nível restaura todo o fôlego das palavras.
		mana = mana_maximo
		_log("Nível: %d | HP: %d | Força: %d | Armadura: %d | Mana: %d" % [lvl, hp, forca, armadura, mana])
		nivel_subiu.emit(lvl)
	else:
		xp += adicao_xp
		_log("Você ganhou %dxp!" % adicao_xp)


func lida_morte(adversario_nome: String) -> void:
	_log("Você morreu! Sua aventura termina aqui, %s..." % nome)
	_log("%s se certificou disso!" % adversario_nome)
	_log("Você passou %d meses nas cavernas... Acumulou %d de conhecimento." % [lvl, xp])
	morreu.emit(adversario_nome)


# Regista a nota de bestiário de uma criatura no dicionário (chamado pelo
# coldCuts.gd ao avistá-la pela primeira vez). Fica depois pesquisável pelo nome
# da criatura, tal como os itens apanhados.
func aprende_bestiario(nome_criatura: String, glossario: String) -> void:
	if glossario.strip_edges().is_empty():
		return
	dicionario.append([nome_criatura, glossario])
	_log("Anotaste %s nas tuas margens." % nome_criatura)


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


# --- Magia: mana, feitiços aprendidos e os seus efeitos sobre o próprio Jogador ---
# Tal como nas palavras, o Jogador não conhece o mapa nem os inimigos: aprende a
# magia, gere o seu mana e sabe sofrer/curar-se. Quem resolve o alvo e a área de
# cada feitiço é o coldCuts.gd, a partir de palavras.json.

# Concede um feitiço (chamado pelo coldCuts.gd ao cruzar um limiar de progresso).
# A incantação entra no vocabulário (para a fala a reconhecer e o dicionário a
# revelar) e o feitiço fica disponível para lançar.
func aprende_magia(nome_magia: String, incantacao: String, glossario: String) -> void:
	var chave := nome_magia.strip_edges().to_lower()
	if chave.is_empty() or chave in magias_aprendidas:
		return
	magias_aprendidas.append(chave)
	# A incantação é a palavra a dizer: guarda-a no vocabulário e revela-a na consulta.
	lembra_palavra(incantacao, "Incantação de %s. %s" % [nome_magia, glossario])
	dicionario.append([nome_magia, "Incantação: «%s». %s" % [incantacao, glossario]])


func ja_aprendeu_magia(nome_magia: String) -> bool:
	return nome_magia.strip_edges().to_lower() in magias_aprendidas


# Gasta mana se houver o bastante; devolve false (sem gastar) caso contrário.
func gasta_mana(custo: int) -> bool:
	if mana < custo:
		return false
	mana -= custo
	return true


func recupera_mana(quantia: int) -> void:
	mana = mini(mana_maximo, mana + quantia)


# Cura o próprio Jogador (feitiço Curar). Devolve quanto HP foi de facto reposto.
func cura_se(quantia: int) -> int:
	var real := mini(quantia, hp_maximo - hp)
	hp += real
	_log("%s sente a carne fechar-se: +%d de HP! (HP: %d/%d)" % [nome, real, hp, hp_maximo])
	return real


# Sofre dano de um feitiço inimigo. Magia elemental ignora a armadura.
func sofre_dano_magico(dano: int, fonte_nome: String, elemento: String = "") -> void:
	var desc := (" %s" % elemento) if elemento != "" else ""
	hp -= dano
	_log("%s atinge %s com magia%s — %d de dano! (HP: %d)" % [fonte_nome, nome, desc, dano, hp])
	if hp <= 0:
		lida_morte(fonte_nome)


# Prende o Jogador no gelo (feitiço Congelar inimigo). Perderá 'turnos' vezes a vez.
func congela(turnos: int) -> void:
	congelado = maxi(congelado, turnos)
	_log("%s é tomado pelo gelo e não consegue agir por %d turno(s)!" % [nome, turnos])


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
