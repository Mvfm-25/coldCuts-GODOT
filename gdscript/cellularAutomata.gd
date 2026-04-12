extends Node2D

@export var node_scene : PackedScene
var dimensions : int = 50
var node_width : int = 15
var node_matrix = []

class cell:
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
	func _calculate_neighbors(dungeon : Array) -> int:
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
	func _update_state(newState : String) -> void :
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

	func _set_width(new_width : int) -> void:
		width = new_width

	func _set_height(new_height : int) -> void:
		height = new_height

	func _generate_name() -> void:
		var p = ["Masmorra", "Caverna", "Abismo", "Calabouço", "Covil", "Tumba"]
		var m = ["Sombria", "Sombrio", "Perdida", "Perdido", "Esquecida", "Esquecido", "Maldita", "Maldito"]
		var f = ["Dos Mortos", "Dos Condenados", "Das Almas", "Do Senhor", "Da Desgraça", "Da Perdição"]
		
		var nome = p.pick_random() + " " + m.pick_random() + " " + f.pick_random()
		name = nome

	func _generate_grid(generations : int) -> Array :
		grid = []

		# Primeira passagem, estado inicial aleatório. Puro barulho.
		for i in range(width):
			var row = []
			for j in range(height):
				var node = cell.new()
				node.x = i
				node.y = j
				row.append(node)
			grid.append(row)

		# Passagens de evolução de estado, passando geração por geração a implementação de regras & mutação.
		for g in range(generations) :
			_game_rules()
		return grid
		

	# Regras de jogo. Se um nó tiver mais que 4 vizinhos vivos, ele morre. 
	# Nele também uso a mutação. 25% de chance de inversão de estado.
	func _game_rules() -> void :
		# Primeira passagem, calculo os vizinhos de cada nó.
		var changes : int = 0

		for i in range(width):
			for j in range(height):
				var node = grid[i][j]
				node._calculate_neighbors(grid)

		# Segunda passagem, aplico as regras de jogo e mutação.
		for i in range(width):
			for j in range(height):
				var node = grid[i][j]
				if node.neighbors > 4:
					node._update_state("0")
					print("Célula (", node.x, ", ", node.y, ") morreu por superpopulação.")
					changes +=1
				if(node._mutate_node(node)):
					print("Célula (", node.x, ", ", node.y, ") sofreu mutação.")
					changes +=1
		print("Geração finalizada. ", changes, " mudanças aplicadas.")


	func _mutate_node(node : cell) -> bool:
		var roll_dice : int = rng.randi_range(0, 100)
		if roll_dice < 25 :
			node._update_state("1") if node.state == "0" else node._update_state("0")
			return true
		else :
			return false


func _ready() -> void:

	pass
	


# Função chamda todo frame. Delta é o tempo intermediário entre cada frame
func _process(delta: float) -> void:
	pass
