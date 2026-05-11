
extends Node2D

@export var node_scene : PackedScene
var dimensions : int = 50
var node_width : int = 15
var node_matrix = []

# Pra fazer pop-upzinho
var current_dungeon : Dungeon                                                                                                     
var popup_layer : CanvasLayer
var popup_panel : Panel                                                                                                           
var popup_label : Label


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
		#print("Ameba atual : (", x,", ", y, ")")
		#print("Viizinhos vivos encontrados : ", neighbors)
		return neighbors

	# Atualização do estado da célula. Vai ficar mais complicado daqui a pouco, mas só preciso pensar em paredes e caminhos por enquanto.
	func update_state(newState : String) -> void :
		#print("Atualizando estado de ", name, " para ", newState)
		#print("Posição: (", x, ", ", y, ")")
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
	var paths : int
	var walls : int
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
		paths = 0
		walls = 0
		print("Gerando novo nome...")
		generate_name()
		#print("Nome gerado : " + name)

		# Primeira passagem, estado inicial aleatório. Puro barulho.
		for i in range(width):
			var row = []
			for j in range(height):
				var ameba = Ameba.new()
				ameba.x = i
				ameba.y = j

				# Contagem que pode ajudar depois.
				if(ameba.state == "1"):
					walls += 1
				else :
					paths += 1

				row.append(ameba)
			grid.append(row)

		# Passagens de evolução de estado, passando geração por geração a implementação de regras & mutação.
		for g in range(generations) :
			print("Gen : ", g)
			game_rules()
			print_dungeon()
			print("Caminhos : ", paths, " | Paredes : ", walls)
			print()
		print("Masmorra gerada!")
		return grid
		

	# Regras de jogo. Se um nó tiver mais que 4 vizinhos vivos, ele morre. 
	# Nele também uso a mutação. 25% de chance de inversão de estado.
	func game_rules() -> void :
		# Primeira passagem, calculo os vizinhos de cada nó.
		var changes : int = 0

		for i in range(width):
			for j in range(height):
				var node = grid[i][j]
				node.calculate_neighbors(grid)

		# Segunda passagem, aplico as regras de jogo e mutação.
		for i in range(width):
			for j in range(height):
				var ameba = grid[i][j]
				if ameba.neighbors > 4 and ameba.state == "1":
					ameba.update_state("0")
					#print("Célula (", ameba.x, ", ", ameba.y, ") morreu por superpopulação.")
					changes +=1
					paths += 1
					walls -= 1
				if(mutate_ameba(ameba)):
					#print("Célula (", ameba.x, ", ", ameba.y, ") sofreu mutação.")
					changes +=1

					# Atualização da contagem de paredes e caminhos.
					if ameba.state == "1":
						paths -= 1
						walls += 1
					else :
						paths += 1
						walls -= 1
		print("Geração finalizada. ", changes, " mudanças aplicadas.")


	func mutate_ameba(ameba : Ameba) -> bool:
		# randi_range é inclusive.
		var roll_dice : int = rng.randi_range(0, 99)
		if roll_dice < 25 :
			ameba.update_state("1") if ameba.state == "0" else ameba.update_state("0")
			return true
		else :
			return false
			
	# Função para impressão da Masmorra. Outra passagem.		
	func print_dungeon() -> void :
		for i in range(width):
			var row_str : String = ""
			for j in range(height):
				row_str += grid[i][j].state + " "
			print(row_str)
			
			
# Classe para salvar e carregar masmorras.
class DungeonIO :
	
	# Verifica número mais recente
	static func check() -> String :
		var file := FileAccess.open("./dungeons/tracker.json", FileAccess.READ)
		var parsed : Variant = JSON.parse_string(file.get_as_text())
		file.close()
		
		var last = parsed["last"]
		print(last)
		
		return last
	
	# Salva
	static func save(dungeon : Dungeon) -> void:
		var data = {
			"name": dungeon.name,
			"width" : dungeon.width,
			"height" : dungeon.height,
			"grid" : []
		}
		
		for row in dungeon.grid:
			var row_data := []
			for ameba in row : 
				row_data.append(ameba.state)
			data["grid"].append(row_data)
			
		var file := FileAccess.open(check(), FileAccess.WRITE)
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		
		print( "last : " + check() )
		
	# Carrega
	static func load(path : String) -> Dungeon :
		var file := FileAccess.open(path, FileAccess.READ)
		var parsed : Variant = JSON.parse_string(file.get_as_text())
		file.close()
		
		# Pega atributos
		var dungeon := Dungeon.new()
		dungeon.name = parsed["name"]
		dungeon.width = parsed["width"]
		dungeon.height = parsed["height"]
		dungeon.grid = []
		dungeon.walls = 0
		dungeon.paths = 0
		
		# Ameba por ameba
		for y in dungeon.height : 
			var row := []
			for x in dungeon.width :
				var ameba := Ameba.new()
				ameba.x = x
				ameba.y = y
				ameba.update_state(parsed["grid"][x][y])
				row.append(ameba)
			dungeon.grid.append(row)
			
		# Re-contagem paredes / caminhos
		for row in dungeon.grid :
			for ameba in row :
				if ameba.state == "1" : dungeon.walls += 1
				else : dungeon.paths += 1
				
		return dungeon 
			
## Separação de classes. ##			

func _draw_dungeon(dungeon : Dungeon) -> void :
	# Limpa o que foi desenhado antes
	for tile in node_matrix:
		tile.queue_free()
	node_matrix.clear()
	
	for row in dungeon.grid:
		for ameba in row:
			var tile : Sprite2D = node_scene.instantiate()

			# Posicionamento do .svg de acordo com sua escala.
			tile.position = Vector2(ameba.x * dimensions, ameba.y * dimensions)
			
			# Pintando de cores diferentesa as paredes dos caminhos.
			if ameba.state == "1":
				tile.modulate = Color(0.25, 0.22, 0.20)
			else :
				tile.modulate = Color(0.65, 0.58, 0.44)
			add_child(tile)
			node_matrix.append(tile)

# Desenha o pop-up na tela para interação do usuário
func _create_popup() -> void : 
	popup_layer = CanvasLayer.new()
	add_child(popup_layer)
																																	
	popup_panel = Panel.new()
	popup_panel.custom_minimum_size = Vector2(250, 120)                                                                            
	popup_panel.hide()
	popup_layer.add_child(popup_panel)

	popup_label = Label.new()                                                                                                     
	popup_label.position = Vector2(8, 8)
	popup_panel.add_child(popup_label)     

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		var grid_x := int(event.position.x / dimensions)
		var grid_y := int(event.position.y / dimensions)

		if current_dungeon and \
		   grid_x >= 0 and grid_x < current_dungeon.width and \
		   grid_y >= 0 and grid_y < current_dungeon.height:
			var ameba : Ameba = current_dungeon.grid[grid_x][grid_y]
			popup_label.text = "X: %d\nY: %d\nState: %s\nIt is surrounded by %d walls" % [ameba.x, ameba.y, ameba.name, ameba.calculate_neighbors(current_dungeon.grid)]
			popup_panel.position = event.position + Vector2(10, 10)
			popup_panel.show()
		else:
			popup_panel.hide()

	elif event.button_index == MOUSE_BUTTON_LEFT:
		popup_panel.hide()

func _ready() -> void:
	var masmorra = Dungeon.new()
	masmorra.set_height(20)
	masmorra.set_width(20)                                                                                                        
	masmorra.generate_grid(5)
	DungeonIO.save(masmorra)
	
	current_dungeon = masmorra  # <-- store it
	_create_popup()             # <-- build the popup                                                                             
	_draw_dungeon(masmorra)  

# Função chamda todo frame. Delta é o tempo intermediário entre cada frame
func _process_(delta: float) -> void:
	pass
