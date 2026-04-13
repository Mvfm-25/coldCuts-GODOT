
extends Node2D

@export var node_scene : PackedScene
var dimensions : int = 50
var node_width : int = 15
var node_matrix = []

class Ameba:
	var rng = RandomNumberGenerator.new()
	var state : String
	var neighbors: int
	var name : String
	var x : int
	var y : int

	# Construtor
	func _init() -> void:
		state = str(rng.randi_range(0, 1))
		neighbors = 0

		if state == "1":
			name = "Wall"
		else :
			name = "Floor"

	# Calcula a quantidade de vizinhos vivos, nas oito direções imediatas.
	func calculate_neighbors(dungeon : Array) -> int:
		# Reseta contador a cada chamada
		neighbors = 0
		
		# Verifica os 8 vizinhos imediatos
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				# Ignora a própria célula
				if dx == 0 and dy == 0:
					continue
				
				var nx = x + dx
				var ny = y + dy
				
				# Verifica se o vizinho está dentro dos limites da matriz
				if 0 <= nx and nx < dungeon.size() and 0 <= ny and ny < dungeon[0].size():
					if dungeon[nx][ny].state == "1":
						neighbors += 1
		
		return neighbors

	# Atualização do estado da célula. Vai ficar mais complicado daqui a pouco, mas só preciso pensar em paredes e caminhos por enquanto.
	func update_state(newState : String) -> void :
		print("Atualizando estado de ", name, " para ", newState)
		print("Posição: (", x, ", ", y, ")")
		state = newState

		if state == "1":
			name = "Wall"
		else :
			name = "Floor"


class Dungeon:
	var rng = RandomNumberGenerator.new()

	# Dungeons sempre vão ser NxN por simplicidade.
	var width : int
	var height : int
	var grid : Array
	var name : String

	func set_width(new_width : int) -> void:
		width = new_width

	func set_height(new_height : int) -> void:
		height = new_height

	func generate_name() -> void:
		var p = ["Masmorra", "Caverna", "Abismo", "Calabouço", "Covil", "Tumba"]
		var m = ["Sombria", "Sombrio", "Perdida", "Perdido", "Esquecida", "Esquecido", "Maldita", "Maldito"]
		var f = ["Dos Mortos", "Dos Condenados", "Das Almas", "Do Senhor", "Da Desgraça", "Da Perdição"]
		
		var nome = p.pick_random() + " " + m.pick_random() + " " + f.pick_random()
		name = nome

	func generate_grid(generations : int) -> Array :
		grid = []
		print("Gerando novo nome...")
		generate_name()
		print("Nome gerado : " + name)

		# Primeira passagem, estado inicial aleatório. Puro barulho.
		for i in range(width):
			var row = []
			for j in range(height):
				var ameba = Ameba.new()
				ameba.x = i
				ameba.y = j
				print("Célula criada! x : ", ameba.x, ", y : ", ameba.y)
				row.append(ameba)
			grid.append(row)

		# Passagens de evolução de estado, passando geração por geração a implementação de regras & mutação.
		for g in range(generations) :
			game_rules()
		print("Masmorra gerada!")
		return grid
		

	# Regras de jogo. Se um nó tiver mais que 4 vizinhos vivos, ele morre. 
	# Nele também uso a mutação. 25% de chance de inversão de estado.
	func game_rules() -> void :
		# Primeira passagem, calculo os vizinhos de cada nó.
		var changes : int = 0
		
		#Debug
		print("game_rules() foi chamado!")

		for i in range(width):
			for j in range(height):
				var node = grid[i][j]
				node.calculate_neighbors(grid)

		# Segunda passagem, aplico as regras de jogo e mutação.
		for i in range(width):
			for j in range(height):
				var ameba = grid[i][j]
				if ameba.neighbors > 4:
					ameba.update_state("0")
					print("Célula (", ameba.x, ", ", ameba.y, ") morreu por superpopulação.")
					changes +=1
				if(ameba.mutate_ameba(ameba)):
					print("Célula (", ameba.x, ", ", ameba.y, ") sofreu mutação.")
					changes +=1
		print("Geração finalizada. ", changes, " mudanças aplicadas.")


	func mutate_ameba(ameba : Ameba) -> bool:
		var roll_dice : int = rng.randi_range(0, 100)
		if roll_dice < 25 :
			ameba.update_state("1") if ameba.state == "0" else ameba.update_state("0")
			return true
		else :
			return false


func _ready() -> void:
	var masmorra = Dungeon.new()
	
	masmorra.set_height(20)
	masmorra.set_width(20)
	
	masmorra.generate_grid(5)
	print("Nome da masmorra : " + masmorra.name)
	pass
	


# Função chamda todo frame. Delta é o tempo intermediário entre cada frame
func _process_(delta: float) -> void:
	pass
