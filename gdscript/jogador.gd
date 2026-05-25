extends Node2D
class_name Jogador

# Opção 1: troca de textura por classe. Adicione os arquivos em assets/player/.
var _sprites: Dictionary = {
	"Bárbaro":   "res://assets/player/barbaro.png",
	"Mago":      "res://assets/player/mago.png",
	"Cavaleiro": "res://assets/player/cavaleiro.png",
	"Ladrão":    "res://assets/player/ladrao.png",
}

# Posição na grade
var x: int = 0
var y: int = 0
var tile_size: int = 16  # Deve ser definido pela cena principal antes de movimenta()

# Identidade
var nome: String = ""
var sprite_char: String = "@"
var classe: String = ""

# Progressão
var lvl: int = 1
var xp: int = 0
var xp_proximo_nivel: int = 0

# Stats
var hp: int = 0
var hp_maximo: int = 0
var ataque: int = 0
var armadura: int = 0
var acuracia: int = 0

# Inventário
var inventario: Array = []
var ultimo_item_inserido: int = 0
var dicionario: Array = []

# Sinais emitidos no lugar dos input() e sys.exit() do Python
signal morreu(adversario_nome: String)
signal nivel_subiu(novo_nivel: int)
signal pediu_portal   # item "C" usado — cena principal cria o portal
signal entrou_portal  # jogador pisou em portal "8" — cena principal carrega nova masmorra

@onready var _sprite: Sprite2D = $Sprite2D


# Chamado pela cena de criação de personagem com nome e escolha de classe.
# Substitui criaPersonagem() que usava input() no Python.
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

	var tex_path: String = _sprites.get(classe, "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		_sprite.texture = load(tex_path)

	print("Personagem: %s | Classe: %s | HP: %d | Ataque: %d | Armadura: %d" % [nome, classe, hp, ataque, armadura])


# Busca uma célula de chão com poucos vizinhos e ao menos um vizinho livre.
func encontra_posicao_inicial(dungeon) -> bool:
	for i in dungeon.width:
		for j in dungeon.height:
			var ameba = dungeon.grid[i][j]
			if ameba.state == "0" and ameba.calculate_neighbors(dungeon.grid) <= 3:
				var tem_caminho := false
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var int nx := i + dx
						var int ny := j + dy
						if nx >= 0 and nx < dungeon.width and ny >= 0 and ny < dungeon.height:
							if dungeon.grid[nx][ny].state == "0":
								tem_caminho = true
								break
					if tem_caminho:
						break
				if tem_caminho:
					x = i
					y = j
					return true
	return false


func verifica_acerto() -> bool:
	return randi_range(1, 100) <= acuracia


# Direcao segue convenção do numpad: "7"=↖ "8"=↑ "9"=↗ "4"=← "6"=→ "1"=↙ "2"=↓ "3"=↘
# Requer dungeon.adversarios (Array) — deve ser adicionado à classe Dungeon.
func ataca(dungeon, direcao: String) -> void:
	var alvo_x := x
	var alvo_y := y
	match direcao:
		"7": alvo_x = x - 1; alvo_y = y - 1
		"8": alvo_x = x - 1; alvo_y = y
		"9": alvo_x = x - 1; alvo_y = y + 1
		"4": alvo_x = x;     alvo_y = y - 1
		"6": alvo_x = x;     alvo_y = y + 1
		"1": alvo_x = x + 1; alvo_y = y - 1
		"2": alvo_x = x + 1; alvo_y = y
		"3": alvo_x = x + 1; alvo_y = y + 1
		_:
			print("Direção inválida!")
			return

	var inimigo_alvo = null
	for adv in dungeon.adversarios:
		if adv.x == alvo_x and adv.y == alvo_y:
			inimigo_alvo = adv
			break

	if inimigo_alvo:
		var dano_restante := ataque
		if inimigo_alvo.armadura > 0:
			var dano_absorvido := mini(dano_restante, inimigo_alvo.armadura)
			inimigo_alvo.armadura -= dano_absorvido
			dano_restante -= dano_absorvido
			print("%s atacou %s! Armadura absorveu %d de dano! (Armadura: %d)" % [nome, inimigo_alvo.nome, dano_absorvido, inimigo_alvo.armadura])
		if dano_restante > 0:
			inimigo_alvo.hp -= dano_restante
			print("%s atacou %s! %d de dano! (HP: %d)" % [nome, inimigo_alvo.nome, dano_restante, inimigo_alvo.hp])
		else:
			print("A armadura de %s resistiu completamente!" % inimigo_alvo.nome)

		if inimigo_alvo.hp <= 0:
			print("*** Você derrotou %s! ***" % inimigo_alvo.nome)
			dungeon.adversarios.erase(inimigo_alvo)
			dungeon.grid[alvo_x][alvo_y].state = "0"
			checa_nivel(50)
	else:
		if alvo_x >= 0 and alvo_x < dungeon.width and alvo_y >= 0 and alvo_y < dungeon.height:
			if dungeon.grid[alvo_x][alvo_y].state == "1":
				print("Sua arma atingiu uma parede!")
				if randi_range(1, 100) >= 95:
					hp -= ataque
					print("Ela rebate e lhe atinge, causando %d de dano!" % ataque)
			else:
				print("Sua arma é usada para atingir o ar!")


func checa_colisao(dungeon, novo_x: int, novo_y: int) -> bool:
	if novo_x < 0 or novo_x >= dungeon.width or novo_y < 0 or novo_y >= dungeon.height:
		return false
	if dungeon.grid[novo_x][novo_y].state == "1":
		return false
	return true


# Requer dungeon.colecionaveis (Array) — deve ser adicionado à classe Dungeon.
func movimenta(dungeon, direcao: String) -> bool:
	var velho_x := x
	var velho_y := y
	var novo_x := x
	var novo_y := y

	match direcao:
		"7": novo_x = x - 1; novo_y = y - 1
		"8": novo_x = x - 1; novo_y = y
		"9": novo_x = x - 1; novo_y = y + 1
		"4": novo_x = x;     novo_y = y - 1
		"6": novo_x = x;     novo_y = y + 1
		"1": novo_x = x + 1; novo_y = y - 1
		"2": novo_x = x + 1; novo_y = y
		"3": novo_x = x + 1; novo_y = y + 1
		_:   return false

	if not checa_colisao(dungeon, novo_x, novo_y):
		return false

	var item_coletado = null
	for i in range(dungeon.colecionaveis.size()):
		if dungeon.colecionaveis[i].x == novo_x and dungeon.colecionaveis[i].y == novo_y:
			item_coletado = dungeon.colecionaveis.pop_at(i)
			break

	dungeon.grid[velho_x][velho_y].state = "0"
	x = novo_x
	y = novo_y
	dungeon.grid[x][y].state = sprite_char
	position = _tile_pixel_pos(x, y)

	if item_coletado:
		adiciona_item_inventario(item_coletado)

	return true


func checa_inventario() -> void:
	if not inventario.is_empty():
		print("Itens no inventário:")
		for entrada in inventario:
			print("%d - %s (Valor: %d)" % [entrada[0], entrada[1].nome, entrada[1].valor])
		print()
	else:
		print("Inventário vazio!")


func adiciona_item_inventario(item) -> void:
	inventario.append([ultimo_item_inserido, item])
	ultimo_item_inserido += 1
	dicionario.append([item.nome, item.glossario])
	print("Item '%s' adicionado ao inventário!" % item.nome)


# dungeon é opcional — só necessário para o item "C" (chave/portal).
func usa_item(id: int, dungeon = null) -> bool:
	for i in range(inventario.size()):
		if inventario[i][0] == id:
			var item = inventario[i][1]
			if item.usavel:
				print("Usando item: %s" % item.nome)
				match item.sprite:
					"V":
						var cura_real := mini(50, hp_maximo - hp)
						hp += cura_real
						print("Você recuperou %d de HP! (HP: %d/%d)" % [cura_real, hp, hp_maximo])
						inventario.remove_at(i)
						return true
					"C":
						print("Você sente que um caminho novo se abriu...")
						inventario.remove_at(i)
						emit_signal("pediu_portal")
						return true
					"P":
						print("Você lê o pergaminho e ganha sabedoria!")
						xp += 20
						inventario.remove_at(i)
						return true
				inventario.remove_at(i)
				return true
			else:
				print("O item '%s' não pode ser usado." % item.nome)
				return false
	print("Nenhum item com ID %d encontrado." % id)
	return false


func entra_portal(dungeon) -> bool:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < dungeon.width and ny >= 0 and ny < dungeon.height:
				if dungeon.grid[nx][ny].state == "8":
					print("Você entrou no portal secreto!")
					print("Você é puxado para outra dimensão...")
					checa_nivel(75)
					emit_signal("entrou_portal")
					return true
	print("Não há portal próximo! Procure por um portal secreto.")
	return false


func checa_nivel(adicao_xp: int) -> void:
	if (xp + adicao_xp) >= xp_proximo_nivel:
		lvl += 1
		xp = (xp + adicao_xp) - xp_proximo_nivel
		xp_proximo_nivel = int(xp_proximo_nivel * 1.50)
		print("Parabéns! Você subiu de nível!")
		match classe:
			"Bárbaro":
				hp += 15; hp_maximo += 15; ataque += 5; armadura += 1
			"Mago":
				hp += 5;  hp_maximo += 5;  ataque += 7; armadura += 2
			"Cavaleiro":
				hp += 10; hp_maximo += 10; ataque += 3; armadura += 5
			"Ladrão":
				hp += 5;  hp_maximo += 5;  ataque += 4; armadura += 3
		print("Nível: %d | HP: %d | Ataque: %d | Armadura: %d" % [lvl, hp, ataque, armadura])
		emit_signal("nivel_subiu", lvl)
	else:
		xp += adicao_xp
		print("Você ganhou %dxp!" % adicao_xp)


# adversario_nome substitui o objeto adversario — a cena principal passa apenas o nome.
func lida_morte(adversario_nome: String) -> void:
	print("Você morreu! Sua aventura termina aqui, %s..." % nome)
	print("%s se certificou disso!" % adversario_nome)
	print("Você passou %d meses nas cavernas... Acumulou %d de conhecimento." % [lvl, xp])
	emit_signal("morreu", adversario_nome)


# Ameba.name retorna "Wall" ou "Floor" — enriqueça a Ameba com nomes customizados para expandir isso.
func olhar(dungeon, direcao: String) -> void:
	var dx := 0
	var dy := 0
	match direcao:
		"7": dx = -1; dy = -1
		"8": dx = -1; dy =  0
		"9": dx = -1; dy =  1
		"4": dx =  0; dy = -1
		"6": dx =  0; dy =  1
		"1": dx =  1; dy = -1
		"2": dx =  1; dy =  0
		"3": dx =  1; dy =  1
		_:
			print("Direção inválida!")
			return

	var olho_x := x + dx
	var olho_y := y + dy

	if not (olho_x >= 0 and olho_x < dungeon.width and olho_y >= 0 and olho_y < dungeon.height):
		print("Você olha além dos limites do mapa...")
		return

	print("Você enxerga um(a): %s..." % dungeon.grid[olho_x][olho_y].name)


# pesquisa substitui o input() do Python — deve ser passado pela UI.
func abre_dicionario(pesquisa: String) -> void:
	print("Você alcança por suas anotações...")
	print("Procurando por '%s'..." % pesquisa)
	for entrada in dicionario:
		if pesquisa.to_lower() in entrada[0].to_lower():
			print("%s --- %s" % [entrada[0], entrada[1]])
			return
	print("Palavra '%s' não está em seu vocabulário..." % pesquisa)


func _tile_pixel_pos(gx: int, gy: int) -> Vector2:
	return Vector2(gx * tile_size + tile_size * 0.5, gy * tile_size + tile_size * 0.5)
