extends Node2D

const CA             = preload("res://gdscript/cellularAutomata.gd")
const TerminalScene  = preload("res://scenes/terminal.tscn")

# Separador escrito no terminal ao fim de cada turno, para dividir a leitura.
const SEP_TURNO : String = "===== // ====="

# Raio de luz (em tiles) à volta do jogador para o fog of war / FOV.
const LIGHT_RADIUS : int = 6
# Cor de um tile fora da luz (escuro total, sem memória do mapa).
const FOG_COLOR : Color = Color(0.0, 0.0, 0.0)

# Tabela de multiplicadores dos 8 octantes para o recursive shadowcasting.
# Linhas: xx, xy, yx, yy.
const FOV_MULT : Array = [
	[ 1,  0,  0, -1, -1,  0,  0,  1],
	[ 0,  1, -1,  0,  0, -1,  1,  0],
	[ 0,  1,  1,  0,  0, -1, -1,  0],
	[ 1,  0,  0,  1, -1,  0,  0, -1],
]

@export var node_scene : PackedScene

var current_dungeon
var tile_size : int
var node_matrix : Array = []

var player_x : int = 0
var player_y : int = 0
var player_sprite : Sprite2D

var hud_layer : CanvasLayer
var dungeon_label : Label
var menu_layer : CanvasLayer
var overlay_layer : CanvasLayer

var player_name : String = ""
var player_class : String = ""

var terminal = null

var enemies : Array = []
# Corpos de inimigos tombados, guardados para o feitiço Reviver do Necromante.
# Cada entrada: { "dados": Dictionary (linha do adversarios.json), "x": int, "y": int }.
var corpos : Array = []
# Nomes de criaturas cuja nota de bestiário já foi registada no dicionário do
# Jogador (uma vez por aventura). Evita anotar a mesma criatura a cada avistamento.
var bestiario_conhecido : Array = []
var items : Array = []
var armas_mapa : Array = []
var enemies_data : Array = []
var items_data : Array = []
var armas_data : Array = []
# Conteúdo de entidades/palavras.json: enigma, palavras mágicas e pactos.
var palavras_data : Dictionary = {}
var entity_labels : Array = []
var jogador_node : Jogador = null

# Quando true, a próxima tecla de direção é interpretada como direção de ataque
# (mecânica 'a' + dir do coldCuts.py), em vez de mover.
var awaiting_attack_dir : bool = false

# Portal secreto aberto pela chave. (-1, -1) = não há portal neste mapa.
var portal_pos : Vector2i = Vector2i(-1, -1)
var portal_label : Label = null

# Bloqueia o input do jogo (mover/atacar) enquanto um diálogo modal está aberto.
var dialog_open : bool = false

# True depois de o jogador morrer: congela o input do jogo até voltar ao menu.
var game_over : bool = false

# Pico de armadura alcançado nesta aventura, usado como "máximo" da barra de
# escudo da sidebar (a armadura do jogador desgasta-se em combate e sobe ao nível).
var armadura_maxima : int = 0


class Item:
	var nome : String
	var sprite_char : String
	var valor : int
	var usavel : bool
	var glossario : String
	var x : int
	var y : int
	var label : Label

	func _init(_nome: String, _sprite: String, _valor: int, _usavel: bool, _glossario: String, _x: int, _y: int) -> void:
		nome = _nome
		sprite_char = _sprite
		valor = _valor
		usavel = _usavel
		glossario = _glossario
		x = _x
		y = _y


# Arma empunhável. O Jogador guarda referências destas (arma_equipada e a lista
# 'armas'), mas é o jogo que as constrói a partir de entidades/armas.json e que
# resolve o alvo dentro do alcance (o Jogador continua sem conhecer o mapa).
class Arma:
	var nome : String
	var sprite_char : String
	var tipo : String                # espada | adaga | lanca | arco
	var dano : int
	var alcance : int                # casas que o golpe atinge (1 = corpo-a-corpo)
	var forca_necessaria : int
	var precisao_necessaria : int
	var valor : int
	var glossario : String
	var x : int
	var y : int
	var label : Label

	func _init(_nome: String, _sprite: String, _tipo: String, _dano: int, _alcance: int,
			_forca: int, _precisao: int, _valor: int, _glossario: String, _x: int, _y: int) -> void:
		nome = _nome
		sprite_char = _sprite
		tipo = _tipo
		dano = _dano
		alcance = _alcance
		forca_necessaria = _forca
		precisao_necessaria = _precisao
		valor = _valor
		glossario = _glossario
		x = _x
		y = _y


func _ready() -> void:
	terminal = TerminalScene.instantiate()
	add_child(terminal)
	_create_hud()
	_create_main_menu()


func _log(text: String) -> void:
	print(text)
	if terminal:
		terminal.add_line(text)


func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)

	dungeon_label = Label.new()
	dungeon_label.position = Vector2(900, 8)
	dungeon_label.add_theme_font_size_override("font_size", 16)
	dungeon_label.hide()
	hud_layer.add_child(dungeon_label)


func _create_main_menu() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 5
	add_child(overlay_layer)

	menu_layer = CanvasLayer.new()
	menu_layer.layer = 8
	add_child(menu_layer)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(320, 230)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -160
	panel.offset_top    = -115
	panel.offset_right  =  160
	panel.offset_bottom =  115
	menu_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "coldCuts"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Um Roguelike de Masmorras"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var btn_new = Button.new()
	btn_new.text = "Nova Aventura"
	btn_new.custom_minimum_size = Vector2(0, 44)
	btn_new.pressed.connect(_show_name_dialog)
	vbox.add_child(btn_new)

	var btn_quit = Button.new()
	btn_quit.text = "Sair"
	btn_quit.custom_minimum_size = Vector2(0, 36)
	btn_quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(btn_quit)


func _show_name_dialog() -> void:
	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 11   # acima do Terminal (layer 10), p/ cobrir a sidebar
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(310, 190)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -155
	panel.offset_top    =  -95
	panel.offset_right  =  155
	panel.offset_bottom =   95
	dialog_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Como será chamado, aventureiro?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	var name_edit = LineEdit.new()
	name_edit.placeholder_text = "Nome do personagem"
	name_edit.max_length = 24
	vbox.add_child(name_edit)

	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(fill)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var btn_back = Button.new()
	btn_back.text = "Voltar"
	btn_back.pressed.connect(func(): dialog_layer.queue_free())
	hbox.add_child(btn_back)

	var btn_ok = Button.new()
	btn_ok.text = "Próximo"
	btn_ok.pressed.connect(func():
		var n = name_edit.text.strip_edges()
		if n.is_empty():
			return
		player_name = n
		dialog_layer.queue_free()
		_show_class_dialog()
	)
	hbox.add_child(btn_ok)

	name_edit.text_submitted.connect(func(_t: String):
		var n = name_edit.text.strip_edges()
		if not n.is_empty():
			player_name = n
			dialog_layer.queue_free()
			_show_class_dialog()
	)
	name_edit.grab_focus()


func _show_class_dialog() -> void:
	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 11   # acima do Terminal (layer 10), p/ cobrir a sidebar
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(360, 340)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -180
	panel.offset_top    = -170
	panel.offset_right  =  180
	panel.offset_bottom =  170
	dialog_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Escolha sua classe, %s:" % player_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var classes : Array = [
		["Bárbaro",   "HP: 150  |  Ataque: 20  |  Arm: 0   |  Precisão: 80%"],
		["Mago",      "HP: 100  |  Ataque: 15  |  Arm: 5   |  Precisão: 85%"],
		["Cavaleiro", "HP: 125  |  Ataque: 10  |  Arm: 10  |  Precisão: 90%"],
		["Ladrão",    "HP: 110  |  Ataque: 12  |  Arm: 5   |  Precisão: 95%"],
	]

	for c in classes:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.text = "%s\n%s" % [c[0], c[1]]
		var cls_name : String = c[0]
		btn.pressed.connect(func():
			player_class = cls_name
			dialog_layer.queue_free()
			_start_game()
		)
		vbox.add_child(btn)

	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(fill)

	var btn_back = Button.new()
	btn_back.text = "Voltar"
	btn_back.pressed.connect(func():
		dialog_layer.queue_free()
		_show_name_dialog()
	)
	vbox.add_child(btn_back)


func _start_game() -> void:
	game_over = false
	# Nova aventura: recomeça o pico de armadura da barra de escudo.
	armadura_maxima = 0
	# Nova aventura, novo dicionário (o Jogador é recriado): esquecer o bestiário.
	bestiario_conhecido.clear()
	menu_layer.hide()
	_load_random_dungeon()
	if current_dungeon == null:
		return
	_draw_dungeon()
	_spawn_player()
	_create_jogador()
	_initialize_dungeon_for_game()
	_equipa_arma_inicial()
	dungeon_label.text = current_dungeon.name
	dungeon_label.show()
	_log("Aventura iniciada! Personagem: %s (%s)" % [player_name, player_class])
	_inicia_palavras_magicas()


func _load_random_dungeon() -> void:
	var dir = DirAccess.open("res://dungeons/")
	if not dir:
		push_error("Diretório res://dungeons/ não encontrado.")
		return

	var files : Array[String] = []
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".dungeon"):
			files.append("res://dungeons/" + fname)
		fname = dir.get_next()
	dir.list_dir_end()

	if files.is_empty():
		push_error("Nenhum arquivo .dungeon encontrado em res://dungeons/")
		return

	# Masmorras de boss só se alcançam por um pacto (ver _on_pediu_boss): nem o
	# início, nem o portal da chave podem cair numa delas. Pega na primeira
	# masmorra normal de uma ordem aleatória.
	files.shuffle()
	current_dungeon = null
	for path in files:
		var d = CA.DungeonIO.load(path)
		if d != null and not d.is_boss:
			current_dungeon = d
			break

	if current_dungeon == null:
		push_error("Nenhuma masmorra normal (não-boss) encontrada em res://dungeons/")
		return
	_log("Masmorra carregada: " + current_dungeon.name)


func _draw_dungeon() -> void:
	for col in node_matrix:
		for tile in col:
			tile.queue_free()
	node_matrix.clear()

	var vp = get_viewport().get_visible_rect().size
	tile_size = max(6, min(int(vp.x / current_dungeon.width), int(vp.y / current_dungeon.height)))

	for _i in range(current_dungeon.width):
		node_matrix.append([])

	for row in current_dungeon.grid:
		for ameba in row:
			var tile : Sprite2D = node_scene.instantiate()
			tile.position = Vector2(
				ameba.x * tile_size + tile_size * 0.5,
				ameba.y * tile_size + tile_size * 0.5
			)
			tile.scale = Vector2(float(tile_size) / 128.0, float(tile_size) / 128.0)
			tile.modulate = Color(0.25, 0.22, 0.20) if ameba.state == "1" else Color(0.65, 0.58, 0.44)
			add_child(tile)
			node_matrix[ameba.x].append(tile)


func _find_valid_start() -> Vector2i:
	for x in current_dungeon.width:
		for y in current_dungeon.height:
			var ameba = current_dungeon.grid[x][y]
			if ameba.state == "0" and ameba.calculate_neighbors(current_dungeon.grid) <= 3:
				return Vector2i(x, y)
	for x in current_dungeon.width:
		for y in current_dungeon.height:
			if current_dungeon.grid[x][y].state == "0":
				return Vector2i(x, y)
	return Vector2i(0, 0)


# Sprite de cada classe. O Ladrão ainda não tem sprite próprio, por isso usa
# o sprite base do Chipps (ChippsBase.png). Qualquer classe sem entrada aqui
# recai também no sprite base (ver _sprite_da_classe).
const SPRITE_CLASSE := {
	"Bárbaro":   "res://assets/sprites/ChippsBarbaro.png",
	"Mago":      "res://assets/sprites/ChippsMago.png",
	"Cavaleiro": "res://assets/sprites/ChippsCavaleiro.png",
	"Ladrão":    "res://assets/sprites/ChippsBase.png",
}
const SPRITE_BASE := "res://assets/sprites/ChippsBase.png"


# Caminho da sprite adequada à classe escolhida pelo jogador.
func _sprite_da_classe() -> String:
	return SPRITE_CLASSE.get(player_class, SPRITE_BASE)


func _spawn_player() -> void:
	var start = _find_valid_start()
	player_x = start.x
	player_y = start.y

	if is_instance_valid(player_sprite):
		player_sprite.queue_free()
	player_sprite = Sprite2D.new()

	var sprite_path := _sprite_da_classe()
	var tex = load(sprite_path) as Texture2D
	if tex:
		player_sprite.texture = tex
		var sf = float(tile_size) / maxf(float(tex.get_width()), float(tex.get_height()))
		player_sprite.scale = Vector2(sf, sf)
	else:
		push_warning("Sprite não encontrada: " + sprite_path)
		var img = Image.create(8, 8, false, Image.FORMAT_RGB8)
		img.fill(Color(0.2, 0.6, 1.0))
		player_sprite.texture = ImageTexture.create_from_image(img)
		player_sprite.scale = Vector2(float(tile_size) / 8.0, float(tile_size) / 8.0)

	player_sprite.position = _tile_pixel_pos(player_x, player_y)
	player_sprite.z_index = 2
	add_child(player_sprite)


func _tile_pixel_pos(gx : int, gy : int) -> Vector2:
	return Vector2(gx * tile_size + tile_size * 0.5, gy * tile_size + tile_size * 0.5)


# Cor de um tile quando está iluminado — mesma convenção de _draw_dungeon().
func _tile_base_color(x : int, y : int) -> Color:
	return Color(0.25, 0.22, 0.20) if current_dungeon.grid[x][y].state == "1" else Color(0.65, 0.58, 0.44)


# --- Fog of war / campo de visão (FOV) ---

func _is_opaque(x : int, y : int) -> bool:
	# Fora dos limites conta como parede (bloqueia a luz).
	if x < 0 or x >= current_dungeon.width or y < 0 or y >= current_dungeon.height:
		return true
	return current_dungeon.grid[x][y].state == "1"


# Recursive shadowcasting (Björn Bergström). Varre um octante a partir do
# jogador, registando em 'visible' os tiles que a luz atinge sem ser bloqueada.
func _cast_light(cx : int, cy : int, row : int, start : float, end : float,
				 xx : int, xy : int, yx : int, yy : int, visible : Dictionary) -> void:
	if start < end:
		return

	var new_start := 0.0
	for j in range(row, LIGHT_RADIUS + 1):
		var dx := -j - 1
		var dy := -j
		var blocked := false
		while dx <= 0:
			dx += 1
			var mx := cx + dx * xx + dy * xy
			var my := cy + dx * yx + dy * yy
			var l_slope := (dx - 0.5) / (dy + 0.5)
			var r_slope := (dx + 0.5) / (dy - 0.5)

			if start < r_slope:
				continue
			elif end > l_slope:
				break

			# Dentro do raio (círculo) => o tile é iluminado.
			if dx * dx + dy * dy <= LIGHT_RADIUS * LIGHT_RADIUS:
				visible[Vector2i(mx, my)] = true

			if blocked:
				if _is_opaque(mx, my):
					new_start = r_slope
					continue
				else:
					blocked = false
					start = new_start
			else:
				if _is_opaque(mx, my) and j < LIGHT_RADIUS:
					# Encontrou parede: continua a varrer, mas recursivamente
					# para a faixa que ainda fica visível antes da sombra.
					blocked = true
					_cast_light(cx, cy, j + 1, start, l_slope, xx, xy, yx, yy, visible)
					new_start = r_slope
		if blocked:
			break


func _compute_fov() -> Dictionary:
	var visible := {}
	# O próprio jogador (fonte de luz) vê sempre o seu tile.
	visible[Vector2i(player_x, player_y)] = true
	for oct in range(8):
		_cast_light(player_x, player_y, 1, 1.0, 0.0,
			FOV_MULT[0][oct], FOV_MULT[1][oct], FOV_MULT[2][oct], FOV_MULT[3][oct], visible)
	return visible


# Recalcula a iluminação e aplica-a aos tiles e às entidades.
# Sem memória: tudo fora da luz fica escuro e as entidades escondem-se.
func _update_fov() -> void:
	if current_dungeon == null or node_matrix.is_empty():
		return

	var visible := _compute_fov()

	for x in range(current_dungeon.width):
		for y in range(current_dungeon.height):
			var tile : Sprite2D = node_matrix[x][y]
			tile.modulate = _tile_base_color(x, y) if visible.has(Vector2i(x, y)) else FOG_COLOR

	for e in enemies:
		if is_instance_valid(e.label):
			var a_vista : bool = visible.has(Vector2i(e.x, e.y))
			e.label.visible = a_vista
			# Primeira vez que a criatura entra na luz: o Jogador anota-a no bestiário.
			if a_vista and jogador_node != null and not bestiario_conhecido.has(e.nome):
				bestiario_conhecido.append(e.nome)
				jogador_node.aprende_bestiario(e.nome, e.glossario)
	for it in items:
		if is_instance_valid(it.label):
			it.label.visible = visible.has(Vector2i(it.x, it.y))
	if is_instance_valid(portal_label):
		portal_label.visible = visible.has(portal_pos)


func _create_jogador() -> void:
	if jogador_node:
		jogador_node.queue_free()
	jogador_node = Jogador.new()
	jogador_node.tile_size = tile_size
	add_child(jogador_node)
	jogador_node.logged.connect(_log)
	jogador_node.pediu_portal.connect(_on_pediu_portal)
	jogador_node.disse.connect(_on_jogador_disse)
	jogador_node.progrediu.connect(_on_jogador_progrediu)
	jogador_node.morreu.connect(_on_jogador_morreu)
	jogador_node.cria_personagem(player_name, player_class)


# --- Carregamento de entidades ---

func _load_entities_data() -> void:
	var file = FileAccess.open("res://entidades/adversarios.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			enemies_data = parsed
		file.close()
	else:
		push_warning("Não foi possível abrir res://entidades/adversarios.json")

	file = FileAccess.open("res://entidades/items.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			items_data = parsed
		file.close()
	else:
		push_warning("Não foi possível abrir res://entidades/items.json")

	file = FileAccess.open("res://entidades/armas.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			armas_data = parsed
		file.close()
	else:
		push_warning("Não foi possível abrir res://entidades/armas.json")

	file = FileAccess.open("res://entidades/palavras.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			palavras_data = parsed
		file.close()
	else:
		push_warning("Não foi possível abrir res://entidades/palavras.json")


func _clear_entity_labels() -> void:
	for lbl in entity_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	entity_labels.clear()
	# Os adversários são nós na árvore (Adversario): libertá-los também.
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	corpos.clear()
	items.clear()
	armas_mapa.clear()

	if is_instance_valid(portal_label):
		portal_label.queue_free()
	portal_label = null
	portal_pos = Vector2i(-1, -1)


func _spawn_entity_label(char: String, x: int, y: int, color: Color, track: bool = true) -> Label:
	var lbl = Label.new()
	lbl.text = char
	lbl.position = Vector2(x * tile_size, y * tile_size)
	lbl.custom_minimum_size = Vector2(tile_size, tile_size)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", max(8, tile_size - 2))
	lbl.modulate = color
	lbl.z_index = 1
	add_child(lbl)
	if track:
		entity_labels.append(lbl)
	return lbl


# --- População de inimigos ---

func _populate_enemies(count: int) -> void:
	if enemies_data.is_empty():
		return

	var placed := 0
	var attempts := 0
	var max_attempts := count * 10

	while placed < count and attempts < max_attempts:
		attempts += 1
		var x := randi_range(0, current_dungeon.width - 1)
		var y := randi_range(0, current_dungeon.height - 1)

		if current_dungeon.grid[x][y].state != "0":
			continue
		if x == player_x and y == player_y:
			continue

		var occupied := false
		for e in enemies:
			if e.x == x and e.y == y:
				occupied = true
				break
		if occupied:
			continue

		var data : Dictionary = enemies_data[randi_range(0, enemies_data.size() - 1)]
		var enemy := Adversario.new()
		enemy.tile_size = tile_size
		add_child(enemy)
		enemy.logged.connect(_log)
		enemy.cria_adversario(data, x, y)
		enemy.label = _spawn_entity_label(enemy.sprite_char, x, y, Color(1.0, 0.3, 0.3))
		enemies.append(enemy)
		placed += 1

	_log("Inimigos inseridos: %d" % placed)


# --- População de itens ---

func _guarantee_key() -> void:
	var attempts := 0
	while attempts < 100:
		attempts += 1
		var x := randi_range(0, current_dungeon.width - 1)
		var y := randi_range(0, current_dungeon.height - 1)

		if current_dungeon.grid[x][y].state != "0":
			continue
		if x == player_x and y == player_y:
			continue

		var occupied := false
		for it in items:
			if it.x == x and it.y == y:
				occupied = true
				break
		if occupied:
			continue

		var key := Item.new("Chave", "C", 25, true,
							"Poucos conhecem deste item, outros iriam preferir não o conhecer...", x, y)
		key.label = _spawn_entity_label("C", x, y, Color(1.0, 0.9, 0.1))
		items.append(key)
		return


func _populate_items(count: int) -> void:
	if items_data.is_empty():
		return

	_guarantee_key()

	var placed := 0
	var attempts := 0
	var max_attempts := count * 10

	while placed < count and attempts < max_attempts:
		attempts += 1
		var x := randi_range(0, current_dungeon.width - 1)
		var y := randi_range(0, current_dungeon.height - 1)

		if current_dungeon.grid[x][y].state != "0":
			continue
		if x == player_x and y == player_y:
			continue

		var occupied := false
		for it in items:
			if it.x == x and it.y == y:
				occupied = true
				break
		for e in enemies:
			if e.x == x and e.y == y:
				occupied = true
				break
		if occupied:
			continue

		var data : Dictionary = items_data[randi_range(0, items_data.size() - 1)]
		var new_item := Item.new(data["nome"], data["sprite"], int(data["valor"]),
								 bool(data["usavel"]), data["glossario"], x, y)
		new_item.label = _spawn_entity_label(new_item.sprite_char, x, y, Color(1.0, 0.85, 0.2))
		items.append(new_item)
		placed += 1

	_log("Itens colocados: %d" % placed)


# Espalha algumas armas pelo chão da masmorra, para o jogador encontrar e trocar.
# Mesma lógica de colocação de _populate_items, mas para o array armas_mapa.
func _populate_armas(count: int) -> void:
	if armas_data.is_empty():
		return

	var placed := 0
	var attempts := 0
	var max_attempts := count * 10

	while placed < count and attempts < max_attempts:
		attempts += 1
		var x := randi_range(0, current_dungeon.width - 1)
		var y := randi_range(0, current_dungeon.height - 1)

		if current_dungeon.grid[x][y].state != "0":
			continue
		if x == player_x and y == player_y:
			continue

		var occupied := false
		for it in items:
			if it.x == x and it.y == y:
				occupied = true
				break
		if not occupied:
			for a in armas_mapa:
				if a.x == x and a.y == y:
					occupied = true
					break
		if not occupied:
			for e in enemies:
				if e.x == x and e.y == y:
					occupied = true
					break
		if occupied:
			continue

		var data : Dictionary = armas_data[randi_range(0, armas_data.size() - 1)]
		var nova := _constroi_arma(data, x, y)
		nova.label = _spawn_entity_label(nova.sprite_char, x, y, Color(0.4, 0.8, 1.0))
		armas_mapa.append(nova)
		placed += 1

	_log("Armas espalhadas: %d" % placed)


# Constrói um objeto Arma a partir de uma linha de armas.json.
func _constroi_arma(data: Dictionary, x: int, y: int) -> Arma:
	return Arma.new(
		str(data["nome"]), str(data["sprite"]), str(data["tipo"]),
		int(data["dano"]), int(data["alcance"]),
		int(data["forca_necessaria"]), int(data["precisao_necessaria"]),
		int(data["valor"]), str(data["glossario"]), x, y)


# Procura no armas.json (já carregado) o dado bruto de uma arma pelo nome.
func _arma_data_por_nome(nome: String) -> Dictionary:
	for data in armas_data:
		if data is Dictionary and str(data.get("nome", "")) == nome:
			return data
	return {}


# Arma com que cada classe começa a aventura (ver _equipa_arma_inicial).
const ARMA_INICIAL := {
	"Bárbaro": "Lança Longa",
	"Mago": "Arco Curto",
	"Cavaleiro": "Espada Curta",
	"Ladrão": "Adaga",
}


# Entrega ao Jogador a arma inicial da sua classe (chamado uma vez, ao começar o
# jogo). O jogo constrói a Arma a partir do JSON; o Jogador só a recebe e equipa.
func _equipa_arma_inicial() -> void:
	if jogador_node == null:
		return
	var nome_arma : String = ARMA_INICIAL.get(jogador_node.classe, "Espada Curta")
	var data := _arma_data_por_nome(nome_arma)
	if data.is_empty():
		return
	jogador_node.adiciona_arma(_constroi_arma(data, -1, -1))


func _initialize_dungeon_for_game() -> void:
	_clear_entity_labels()
	_load_entities_data()
	_populate_enemies(20)
	_populate_items(10)
	_populate_armas(3)
	_update_fov()
	_update_status_panel()


# --- Painel de status ---

# Ponto único de refresh da HUD após cada ação do jogador. O antigo painel
# ">> status" foi removido (a sidebar do herói cobre a mesma informação), pelo
# que isto agora apenas reencaminha para _update_sidebar(). Mantém-se o nome por
# ser chamado em vários pontos (movimento, combate, magia, diálogos).
func _update_status_panel() -> void:
	_update_sidebar()


# Alimenta a sidebar do herói (terminal.gd) com o estado atual do jogador: barras
# de HP/escudo, sprite grande da classe, nome/classe, abates, ouro e o inventário
# (armas empunhada + arsenal, e itens). Chamado sempre que o status é atualizado.
func _update_sidebar() -> void:
	if terminal == null or jogador_node == null:
		return

	# Uma aventura está a decorrer: garante que a sidebar está visível.
	terminal.mostra_sidebar()

	# A armadura cai em combate mas nunca sobe sozinha: o pico serve de "cheio".
	armadura_maxima = maxi(armadura_maxima, jogador_node.armadura)

	var ouro := 0
	for entrada in jogador_node.inventario:
		ouro += entrada[1].valor

	terminal.set_sidebar_heroi(
		_sprite_da_classe(), jogador_node.nome, jogador_node.classe, jogador_node.lvl,
		jogador_node.hp, jogador_node.hp_maximo,
		jogador_node.armadura, armadura_maxima,
		jogador_node.xp, jogador_node.xp_proximo_nivel,
		jogador_node.mana, jogador_node.mana_maximo,
		jogador_node.inimigos_derrotados, ouro)

	# Armas: a equipada primeiro (marcada com [E]), depois o resto do arsenal.
	var armas_txt : Array = []
	if jogador_node.arma_equipada != null:
		armas_txt.append("[E] %s  (dano %d, alc %d)" % [
			jogador_node.arma_equipada.nome, jogador_node.arma_equipada.dano,
			jogador_node.arma_equipada.alcance])
	for a in jogador_node.armas:
		armas_txt.append("%s  (dano %d, alc %d)" % [a.nome, a.dano, a.alcance])

	var itens_txt : Array = []
	for entrada in jogador_node.inventario:
		itens_txt.append("%s  (valor %d)" % [entrada[1].nome, entrada[1].valor])

	terminal.set_sidebar_inventario(armas_txt, itens_txt)


# --- Input e movimento ---

func _dir_from_keycode(keycode : int) -> Vector2i:
	match keycode:
		KEY_W, KEY_UP, KEY_KP_8:    return Vector2i( 0, -1)
		KEY_S, KEY_DOWN, KEY_KP_2:  return Vector2i( 0,  1)
		KEY_LEFT, KEY_KP_4:         return Vector2i(-1,  0)
		KEY_D, KEY_RIGHT, KEY_KP_6: return Vector2i( 1,  0)
		KEY_Q, KEY_KP_7:            return Vector2i(-1, -1)
		KEY_E, KEY_KP_9:            return Vector2i( 1, -1)
		KEY_Z, KEY_KP_1:            return Vector2i(-1,  1)
		KEY_C, KEY_KP_3:            return Vector2i( 1,  1)
	return Vector2i.ZERO


func _input(event : InputEvent) -> void:
	if current_dungeon == null:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	# Depois da morte, o jogo não aceita mais ações até voltar ao menu.
	if game_over:
		return
	# Enquanto um diálogo modal está aberto, o jogo ignora teclas de jogo
	# (os Controls do diálogo continuam recebendo o input normalmente).
	if dialog_open:
		return

	# Modo de ataque: a tecla anterior foi 'A'; esta define a direção do golpe.
	if awaiting_attack_dir:
		awaiting_attack_dir = false
		var attack_dir := _dir_from_keycode(event.keycode)
		if attack_dir == Vector2i.ZERO:
			_log("Ataque cancelado.")
			return
		_do_attack(attack_dir)
		return

	match event.keycode:
		KEY_I:
			if jogador_node:
				jogador_node.checa_inventario()
			return
		KEY_A:
			# Inicia 'a' + direção (ataque direcional, como no coldCuts.py).
			awaiting_attack_dir = true
			_log("Escolha uma direção para atacar...")
			return
		KEY_U:
			# Usar item do inventário.
			_show_use_item_dialog()
			return
		KEY_T:
			# Trocar a arma equipada (arsenal do jogador).
			_show_weapon_dialog()
			return
		KEY_P:
			# Entrar no portal secreto (se houver um adjacente).
			_try_enter_portal()
			return
		KEY_G:
			# Consultar o dicionário de palavras conhecidas.
			_show_dictionary_dialog()
			return
		KEY_F:
			# Falar em voz alta (pode invocar uma masmorra de boss).
			_show_speak_dialog()
			return

	var dir := _dir_from_keycode(event.keycode)
	if dir == Vector2i.ZERO:
		return

	_try_move(player_x + dir.x, player_y + dir.y)


# O jogo resolve o alvo (mapa + lista de inimigos é responsabilidade dele) e
# delega o combate ao Jogador, que não conhece o layout nem o array de inimigos.
func _do_attack(dir : Vector2i) -> void:
	if not jogador_node:
		return
	if _jogador_perde_turno_se_congelado():
		return

	# A arma equipada decide quantas casas o golpe varre na direção escolhida.
	# Para o primeiro inimigo na linha (ou para na primeira parede).
	var alcance := jogador_node.alcance_arma()
	var alvo = null
	var bateu_parede := false

	for passo in range(1, alcance + 1):
		var tx := player_x + dir.x * passo
		var ty := player_y + dir.y * passo

		if tx < 0 or tx >= current_dungeon.width or ty < 0 or ty >= current_dungeon.height:
			bateu_parede = true
			break

		var achou := false
		for e in enemies:
			if e.x == tx and e.y == ty:
				alvo = e
				achou = true
				break
		if achou:
			break

		# Parede interrompe o golpe ou o projétil. Só conta como "rebate na parede"
		# se for corpo-a-corpo (primeiro passo); à distância, a flecha apenas para.
		if current_dungeon.grid[tx][ty].state == "1":
			if passo == 1:
				bateu_parede = true
			break

	var derrotou : bool = jogador_node.ataca(alvo, bateu_parede)
	if derrotou and alvo != null:
		_regista_corpo(alvo)
		if is_instance_valid(alvo.label):
			entity_labels.erase(alvo.label)
			alvo.label.queue_free()
		enemies.erase(alvo)
		alvo.queue_free()

	# Atacar consome o turno do jogador: os adversários reagem a seguir.
	# (_process_enemy_turns escreve o separador de fim de turno no terminal.)
	_process_enemy_turns()


func _try_move(new_x : int, new_y : int) -> void:
	if _jogador_perde_turno_se_congelado():
		return
	if new_x < 0 or new_x >= current_dungeon.width:
		return
	if new_y < 0 or new_y >= current_dungeon.height:
		return
	if current_dungeon.grid[new_x][new_y].state == "1":
		return

	# Inimigos bloqueiam o passo: para atacar, use 'a' + direção.
	for e in enemies:
		if e.x == new_x and e.y == new_y:
			_log("%s bloqueia o caminho! Use 'a' + direção para atacar." % e.nome)
			return

	# Coleta item se houver na posição destino
	for i in range(items.size()):
		if items[i].x == new_x and items[i].y == new_y:
			var collected : Item = items[i]
			if is_instance_valid(collected.label):
				entity_labels.erase(collected.label)
				collected.label.queue_free()
			items.remove_at(i)
			if jogador_node:
				jogador_node.adiciona_item_inventario(collected)
			else:
				_log("Item coletado: %s (Valor: %d)" % [collected.nome, collected.valor])
			break

	# Apanha arma se houver na posição destino
	for i in range(armas_mapa.size()):
		if armas_mapa[i].x == new_x and armas_mapa[i].y == new_y:
			var arma_apanhada : Arma = armas_mapa[i]
			if is_instance_valid(arma_apanhada.label):
				entity_labels.erase(arma_apanhada.label)
				arma_apanhada.label.queue_free()
			armas_mapa.remove_at(i)
			if jogador_node:
				jogador_node.adiciona_arma(arma_apanhada)
			else:
				_log("Arma encontrada: %s" % arma_apanhada.nome)
			break

	player_x = new_x
	player_y = new_y
	player_sprite.position = _tile_pixel_pos(player_x, player_y)
	_update_fov()

	# Mover gasta o turno do jogador: agora os adversários jogam.
	_process_enemy_turns()
	


# --- Turno dos adversários ---

# Disparado depois de cada ação do jogador (mover ou atacar). Cada adversário,
# pela ordem da lista, ataca se estiver adjacente ao jogador ou dá um passo na
# sua direção. Tal como em _try_move, o jogo é que valida o passo (paredes,
# limites e tiles ocupados); o Adversario só indica a direção que deseja.
func _process_enemy_turns() -> void:
	if jogador_node == null or game_over:
		return

	# Cópia: a lista pode mudar caso um adversário seja removido durante o turno.
	# 'e' é tipado como Adversario para o compilador inferir os tipos de retorno
	# (decide_direcao -> Vector2i, e.x/e.y -> int) nas linhas abaixo.
	for e : Adversario in enemies.duplicate():
		if not is_instance_valid(e):
			continue

		# Preso no gelo (feitiço Congelar do jogador): perde a vez.
		if e.congelado > 0:
			e.congelado -= 1
			continue

		# Antes de agir fisicamente, decide se lança uma magia (se a tiver).
		var dist := maxi(abs(e.x - player_x), abs(e.y - player_y))
		var magia := e.decide_magia(dist)
		if not magia.is_empty():
			_resolve_magia_inimigo(e, magia)
			if game_over:
				return
			continue

		if e.esta_adjacente(player_x, player_y):
			e.ataca(jogador_node)
			if game_over:
				return
			continue

		var dir := e.decide_direcao(player_x, player_y)
		if dir == Vector2i.ZERO:
			continue

		# Tenta o passo diagonal; se estiver bloqueado, tenta deslizar por um
		# dos eixos para não encravar nos cantos das paredes.
		for tentativa : Vector2i in [dir, Vector2i(dir.x, 0), Vector2i(0, dir.y)]:
			if tentativa == Vector2i.ZERO:
				continue
			var nx := e.x + tentativa.x
			var ny := e.y + tentativa.y
			if _tile_livre_para_inimigo(nx, ny, e):
				e.move_para(nx, ny)
				break

	# Fim do turno: todos recuperam um pouco do fôlego das palavras.
	for e in enemies:
		if is_instance_valid(e):
			e.recupera_mana(1)
	jogador_node.recupera_mana(1)

	# A posição dos inimigos mudou: reavaliar o que está visível.
	_update_fov()
	# Combate pode ter mudado HP/armadura do jogador.
	_update_status_panel()

	# Fecha o turno com um separador no terminal, dividindo-o do próximo.
	_log(SEP_TURNO)


func _tile_livre_para_inimigo(nx : int, ny : int, mover) -> bool:
	if nx < 0 or nx >= current_dungeon.width:
		return false
	if ny < 0 or ny >= current_dungeon.height:
		return false
	if current_dungeon.grid[nx][ny].state == "1":
		return false
	if nx == player_x and ny == player_y:
		return false
	for e in enemies:
		if e == mover:
			continue
		if e.x == nx and e.y == ny:
			return false
	return true


func _on_jogador_morreu(_adversario_nome : String) -> void:
	game_over = true
	awaiting_attack_dir = false
	_log("--- FIM DE JOGO ---")
	# Volta ao menu: esconde a sidebar do herói (a aventura acabou).
	if terminal:
		terminal.esconde_sidebar()
	# Revela o mapa inteiro e volta a mostrar o menu principal.
	for col in node_matrix:
		for tile in col:
			tile.modulate = Color(0.4, 0.4, 0.4)
	menu_layer.show()


# --- Portal secreto ---

# Disparado pelo sinal pediu_portal do Jogador (ao usar a chave). Criar o portal
# é trabalho do jogo, pois envolve o layout do mapa.
func _on_pediu_portal() -> void:
	if portal_pos != Vector2i(-1, -1):
		_log("Você já abriu um portal nesta masmorra!")
		return

	var attempts := 0
	while attempts < 200:
		attempts += 1
		var x := randi_range(0, current_dungeon.width - 1)
		var y := randi_range(0, current_dungeon.height - 1)

		if current_dungeon.grid[x][y].state != "0":
			continue
		if x == player_x and y == player_y:
			continue

		var occupied := false
		for e in enemies:
			if e.x == x and e.y == y:
				occupied = true
				break
		if not occupied:
			for it in items:
				if it.x == x and it.y == y:
					occupied = true
					break
		if occupied:
			continue

		portal_pos = Vector2i(x, y)
		portal_label = _spawn_entity_label("8", x, y, Color(0.2, 0.95, 0.95), false)
		_update_fov()
		_log("Um portal secreto se abriu em algum lugar da masmorra...")
		return

	_log("O portal não conseguiu se formar... não há espaço livre.")


func _try_enter_portal() -> void:
	if portal_pos == Vector2i(-1, -1):
		_log("Não há portal aberto. Use uma chave para abrir um.")
		return

	# Precisa estar a até 1 tile do portal (8 vizinhos ou em cima dele).
	if abs(player_x - portal_pos.x) <= 1 and abs(player_y - portal_pos.y) <= 1:
		_log("Você entrou no portal secreto!")
		_log("Você é puxado para outra dimensão...")
		if jogador_node:
			jogador_node.checa_nivel(75)
		_enter_new_dungeon()
	else:
		_log("Não há portal próximo! Procure pelo portal secreto.")


# Carrega uma nova masmorra mantendo o mesmo Jogador (stats, nível e inventário).
func _enter_new_dungeon() -> void:
	_load_random_dungeon()
	if current_dungeon == null:
		return
	_draw_dungeon()
	_spawn_player()
	_initialize_dungeon_for_game()
	dungeon_label.text = current_dungeon.name


# --- Palavras mágicas e pactos (ver entidades/palavras.json) ---

# No início de uma nova aventura: a voz misteriosa entoa o enigma e o Jogador
# já se lembra das palavras marcadas como "inicial".
func _inicia_palavras_magicas() -> void:
	if palavras_data.is_empty() or jogador_node == null:
		return

	if palavras_data.has("enigma"):
		_log(str(palavras_data["enigma"]))

	for p in palavras_data.get("palavras", []):
		if bool(p.get("inicial", false)):
			jogador_node.lembra_palavra(str(p["palavra"]), str(p.get("glossario", "")))
			if p.has("voz"):
				_log(str(p["voz"]))


# Disparado quando um contador de progresso do Jogador muda. Concede qualquer
# palavra cujo limiar de desbloqueio tenha sido agora atingido e deixa a voz
# misteriosa narrar o feito, ligando a ação à palavra.
func _on_jogador_progrediu(tipo: String, valor: int) -> void:
	for p in palavras_data.get("palavras", []):
		if not p.has("desbloqueio"):
			continue
		var d : Dictionary = p["desbloqueio"]
		if str(d.get("tipo", "")) != tipo:
			continue
		if jogador_node.ja_lembra(str(p["palavra"])):
			continue
		if valor >= int(d.get("quantidade", 0)):
			jogador_node.lembra_palavra(str(p["palavra"]), str(p.get("glossario", "")))
			if p.has("voz"):
				_log(str(p["voz"]))

	# O mesmo progresso também desbloqueia feitiços (ver "magias" em palavras.json).
	for m in palavras_data.get("magias", []):
		if not m.has("desbloqueio"):
			continue
		var dm : Dictionary = m["desbloqueio"]
		if str(dm.get("tipo", "")) != tipo:
			continue
		if jogador_node.ja_aprendeu_magia(str(m["nome"])):
			continue
		if valor >= int(dm.get("quantidade", 0)):
			jogador_node.aprende_magia(str(m["nome"]), str(m.get("incantacao", "")), str(m.get("glossario", "")))
			if m.has("voz"):
				_log(str(m["voz"]))


# Disparado pelo sinal 'disse' do Jogador. O jogo valida a frase contra os
# pactos de palavras.json: exige que TODAS as palavras já tenham sido lembradas
# (descobrir a frase não basta — é preciso tê-la ganho) e resolve o efeito.
func _on_jogador_disse(frase: String) -> void:
	var dito := frase.strip_edges().to_lower()
	if dito.is_empty():
		return

	# Comando de debug: extermina todos os inimigos do mapa.
	if dito == "1701 exterminatus":
		_log("EXTERMINATUS! Uma luz purificadora varre a masmorra.")
		_on_pediu_exterminatus()
		return

	# Comando de debug: concede Pergaminhos ao inventário do jogador.
	if dito == "2553 codex":
		_log("CODEX! Um códice ancestral se materializa em suas mãos.")
		_on_pediu_codex()
		return

	# Uma incantação de feitiço? (ver "magias" em palavras.json)
	var magia = _encontra_magia_jogador(dito)
	if magia != null:
		_lanca_magia_jogador(magia)
		return

	var pacto = _encontra_pacto(dito)
	if pacto == null:
		_log("As palavras se perdem no eco da masmorra...")
		return

	if not _pacto_todo_lembrado(pacto):
		_log("As palavras tropeçam em sua língua — uma delas ainda lhe é estranha...")
		return

	match str(pacto.get("efeito", "")):
		"invoca_boss":
			# Invoca uma masmorra de boss, à custa de uma chave do inventário.
			if not jogador_node.consome_chave():
				_log("As palavras ressoam com poder, mas falta-lhe uma chave para selar o pacto.")
				return
			_log("A chave se desfaz em pó enquanto as palavras rasgam o véu da realidade!")
			_log("Um covil de boss o reclama...")
			_on_pediu_boss()
		_:
			_log("As palavras se perdem no eco da masmorra...")


# Devolve o pacto cuja frase casa exatamente com o que foi dito, ou null.
func _encontra_pacto(dito: String):
	for pacto in palavras_data.get("pactos", []):
		if str(pacto.get("frase", "")).strip_edges().to_lower() == dito:
			return pacto
	return null


# True se o Jogador já se lembra de cada palavra que compõe a frase do pacto.
func _pacto_todo_lembrado(pacto) -> bool:
	for palavra in str(pacto.get("frase", "")).split(" ", false):
		if not jogador_node.ja_lembra(palavra):
			return false
	return true


# --- Magia: resolução dos feitiços (jogador e inimigos) ---
# As definições vivem nos JSON (palavras.json para o jogador, adversarios.json
# para os inimigos). As entidades só declaram a intenção e gerem o seu mana; é
# AQUI que se conhece o mapa e se resolvem alvos, áreas e corpos.

# Descrição curta do efeito de um feitiço, para a referência do diálogo de falar.
func _magia_descricao_curta(m: Dictionary) -> String:
	match str(m.get("tipo", "")):
		"dano":      return "relâmpago no inimigo mais próximo"
		"cura":      return "fecha as tuas próprias feridas"
		"congelar":  return "rouba um turno ao inimigo mais próximo"
		"area_dano": return "fere todos os inimigos em redor"
	return "efeito desconhecido"


# Procura nas magias do jogador (palavras.json) a que casa com a incantação dita.
func _encontra_magia_jogador(dito: String):
	for m in palavras_data.get("magias", []):
		if str(m.get("incantacao", "")).strip_edges().to_lower() == dito:
			return m
	return null


# Lança um feitiço do jogador. Valida que ele o domina e tem mana; resolve o
# alvo/área a partir do mapa; aplica o efeito e gasta o turno (os inimigos reagem).
func _lanca_magia_jogador(magia: Dictionary) -> void:
	var nome_magia := str(magia.get("nome", "magia"))

	if not jogador_node.ja_aprendeu_magia(nome_magia):
		_log("A palavra forma-se na tua boca, mas falta-lhe poder — ainda não dominas '%s'." % nome_magia)
		return
	if _jogador_perde_turno_se_congelado():
		return

	var custo := int(magia.get("custo_mana", 0))
	if jogador_node.mana < custo:
		_log("As sílabas esvaem-se: falta-te mana para %s (precisa de %d, tens %d)." % [nome_magia, custo, jogador_node.mana])
		return

	var tipo := str(magia.get("tipo", ""))
	var alcance := int(magia.get("alcance", 0))

	match tipo:
		"cura":
			jogador_node.gasta_mana(custo)
			jogador_node.cura_se(int(magia.get("cura", 0)))
		"dano", "congelar":
			var alvo = _inimigo_mais_proximo(alcance)
			if alvo == null:
				_log("O feitiço busca um alvo e não o encontra ao alcance.")
				return
			jogador_node.gasta_mana(custo)
			if tipo == "dano":
				_log("Um raio parte de %s e fende %s!" % [jogador_node.nome, alvo.nome])
				_aplica_dano_magico_inimigo(alvo, int(magia.get("dano", 0)))
			else:
				_log("O gelo prende %s no lugar!" % alvo.nome)
				alvo.congelado = maxi(alvo.congelado, int(magia.get("duracao", 1)))
		"area_dano":
			var atingidos := _inimigos_no_raio(alcance)
			if atingidos.is_empty():
				_log("O granizo cai sobre pedra vazia — nenhum inimigo por perto.")
				return
			jogador_node.gasta_mana(custo)
			_log("Granizo desaba à volta de %s, ferindo %d inimigo(s)!" % [jogador_node.nome, atingidos.size()])
			for alvo in atingidos:
				_aplica_dano_magico_inimigo(alvo, int(magia.get("dano", 0)))
		_:
			_log("As palavras ressoam, mas o feitiço escapa-te.")
			return

	# Lançar um feitiço gasta o turno: os adversários reagem a seguir.
	_update_status_panel()
	_process_enemy_turns()


# Inimigo vivo mais próximo do jogador, dentro do alcance (Chebyshev). Null se nenhum.
func _inimigo_mais_proximo(alcance: int):
	var melhor = null
	var melhor_dist := 1 << 30
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d := maxi(abs(e.x - player_x), abs(e.y - player_y))
		if d <= alcance and d < melhor_dist:
			melhor_dist = d
			melhor = e
	return melhor


# Todos os inimigos vivos dentro de 'raio' tiles do jogador (área do Chuva de Gelo).
func _inimigos_no_raio(raio: int) -> Array:
	var lista: Array = []
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if maxi(abs(e.x - player_x), abs(e.y - player_y)) <= raio:
			lista.append(e)
	return lista


# Aplica dano mágico (ignora armadura) a um inimigo e remove-o se cair. Espelha a
# remoção de _do_attack e credita o abate ao jogador (XP + progresso).
func _aplica_dano_magico_inimigo(alvo, dano: int) -> void:
	alvo.hp -= dano
	_log("%d de dano mágico em %s! (HP: %d)" % [dano, alvo.nome, alvo.hp])
	if alvo.hp <= 0:
		jogador_node.registra_abate(alvo.nome)
		_regista_corpo(alvo)
		if is_instance_valid(alvo.label):
			entity_labels.erase(alvo.label)
			alvo.label.queue_free()
		enemies.erase(alvo)
		alvo.queue_free()


# Resolve uma magia lançada por um adversário (escolhida em Adversario.decide_magia).
func _resolve_magia_inimigo(e, magia: Dictionary) -> void:
	var custo := int(magia.get("custo_mana", 0))
	if not e.gasta_mana(custo):
		return

	var tipo := str(magia.get("tipo", ""))
	var nome_magia := str(magia.get("nome", "magia"))
	_log("%s entoa %s!" % [e.nome, nome_magia])

	match tipo:
		"dano":
			jogador_node.sofre_dano_magico(int(magia.get("dano", 0)), e.nome, "(raio)")
		"area_dano":
			jogador_node.sofre_dano_magico(int(magia.get("dano", 0)), e.nome, "(gelo)")
		"congelar":
			jogador_node.congela(int(magia.get("duracao", 1)))
		"cura":
			e.cura_se(int(magia.get("cura", 0)))
		"reviver":
			_reanima_servo(e, int(magia.get("alcance", 3)))
		_:
			_log("A magia de %s dissipa-se sem efeito." % e.nome)


# Ergue um corpo tombado perto do conjurador (feitiço Reviver do Necromante),
# com metade da vida. Fizz se não houver corpos no alcance ou casas livres.
func _reanima_servo(necro, alcance: int) -> void:
	var idx := -1
	for i in range(corpos.size()):
		var c = corpos[i]
		var cx := int(c["x"])
		var cy := int(c["y"])
		if maxi(abs(cx - necro.x), abs(cy - necro.y)) <= alcance and _tile_livre_para_inimigo(cx, cy, null):
			idx = i
			break
	if idx == -1:
		_log("O chamado de %s não encontra ossos para erguer." % necro.nome)
		return

	var corpo = corpos[idx]
	corpos.remove_at(idx)
	var data : Dictionary = corpo["dados"]
	var rx := int(corpo["x"])
	var ry := int(corpo["y"])

	var enemy := Adversario.new()
	enemy.tile_size = tile_size
	add_child(enemy)
	enemy.logged.connect(_log)
	enemy.cria_adversario(data, rx, ry)
	enemy.hp = maxi(1, enemy.hp_maximo / 2)   # ergue-se com metade da vida
	enemy.label = _spawn_entity_label(enemy.sprite_char, rx, ry, Color(0.7, 0.3, 0.9))
	enemies.append(enemy)
	_update_fov()
	_log("%s ergue %s dentre os mortos!" % [necro.nome, enemy.nome])


# Guarda o corpo de um inimigo tombado (dados originais + posição), para que um
# Necromante o possa reerguer mais tarde.
func _regista_corpo(adv) -> void:
	var dados := _enemy_data_por_nome(adv.nome)
	if dados.is_empty():
		return
	corpos.append({ "dados": dados, "x": adv.x, "y": adv.y })


# Procura no adversarios.json (já carregado) o dado bruto de um inimigo pelo nome.
func _enemy_data_por_nome(nome: String) -> Dictionary:
	for data in enemies_data:
		if data is Dictionary and str(data.get("nome", "")) == nome:
			return data
	return {}


# Se o jogador está congelado, consome um turno (sem agir) e devolve true. Os
# inimigos jogam mesmo assim. Usado nos pontos de ação do jogador (mover/atacar/falar).
func _jogador_perde_turno_se_congelado() -> bool:
	if jogador_node == null or jogador_node.congelado <= 0:
		return false
	jogador_node.congelado -= 1
	_log("%s está preso no gelo e perde o turno!" % jogador_node.nome)
	_process_enemy_turns()
	return true


# --- Masmorra de boss ---

# Carrega uma masmorra de boss escolhida ao acaso. Chamado quando um pacto de
# invocação é selado com sucesso em _on_jogador_disse().
func _on_pediu_boss() -> void:
	var boss_path := _pick_random_boss_dungeon()
	if boss_path == "":
		_log("...mas nenhum covil de boss responde ao chamado.")
		return

	current_dungeon = CA.DungeonIO.load(boss_path)
	if current_dungeon == null:
		return
	_draw_dungeon()
	_spawn_player()
	_initialize_dungeon_for_game()
	dungeon_label.text = current_dungeon.name
	_log("Você desperta numa arena de boss: %s" % current_dungeon.name)


# Procura em res://dungeons/ todas as masmorras marcadas como boss e devolve
# o caminho de uma escolhida ao acaso (ou "" se não houver nenhuma).
func _pick_random_boss_dungeon() -> String:
	var dir = DirAccess.open("res://dungeons/")
	if not dir:
		push_error("Diretório res://dungeons/ não encontrado.")
		return ""

	var boss_files : Array[String] = []
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".dungeon"):
			var path : String = "res://dungeons/" + fname
			var d = CA.DungeonIO.load(path)
			if d != null and d.is_boss:
				boss_files.append(path)
		fname = dir.get_next()
	dir.list_dir_end()

	if boss_files.is_empty():
		return ""
	boss_files.shuffle()
	return boss_files[0]


# --- Exterminatus (debug: invocado pela fala secreta do Jogador) ---

# Remove todos os inimigos do mapa. Chamado por _on_jogador_disse() ao reconhecer
# a frase de debug — o Jogador não conhece a lista de inimigos, a limpeza é do jogo.
func _on_pediu_exterminatus() -> void:
	var count := enemies.size()
	for e in enemies:
		if is_instance_valid(e.label):
			entity_labels.erase(e.label)
			e.label.queue_free()
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	_log("Exterminatus concluído: %d inimigo(s) reduzido(s) a cinzas." % count)


# --- Codex (debug: invocado pela fala secreta do Jogador) ---

# Concede Pergaminhos diretamente ao inventário do jogador. Chamado por
# _on_jogador_disse() ao reconhecer a frase de debug — o jogo monta os itens
# (a partir de items.json) e os entrega ao Jogador, que apenas os guarda.
func _on_pediu_codex() -> void:
	if not jogador_node:
		return

	var quantidade := 5
	var dados := _item_data_por_nome("Pergaminho")
	for i in range(quantidade):
		var pergaminho : Item
		if dados.is_empty():
			pergaminho = Item.new("Pergaminho", "P", 15, true,
				"Conhecimento de monges de inúmeros monastérios são colecionadaos neste códice.", -1, -1)
		else:
			pergaminho = Item.new(dados["nome"], dados["sprite"], int(dados["valor"]),
				bool(dados["usavel"]), dados["glossario"], -1, -1)
		jogador_node.adiciona_item_inventario(pergaminho)

	_log("Codex concluído: %d Pergaminho(s) adicionado(s) ao inventário." % quantidade)


# Procura no items.json (já carregado) o dado bruto de um item pelo nome.
# Devolve um Dictionary vazio se não existir.
func _item_data_por_nome(nome: String) -> Dictionary:
	for data in items_data:
		if data is Dictionary and str(data.get("nome", "")) == nome:
			return data
	return {}


# --- Diálogos modais ---

func _close_dialog(layer : CanvasLayer) -> void:
	dialog_open = false
	layer.queue_free()


func _show_use_item_dialog() -> void:
	if not jogador_node:
		return
	if jogador_node.inventario.is_empty():
		_log("Inventário vazio! Não há itens para usar.")
		return

	dialog_open = true

	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 11   # acima do Terminal (layer 10), p/ cobrir a sidebar
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -180
	panel.offset_top    = -190
	panel.offset_right  =  180
	panel.offset_bottom =  190
	dialog_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Usar qual item?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	for entrada in jogador_node.inventario:
		var item_id : int = entrada[0]
		var item = entrada[1]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var marca : String = "" if item.usavel else "  [não usável]"
		btn.text = "%s (Valor: %d)%s" % [item.nome, item.valor, marca]
		btn.pressed.connect(func():
			_close_dialog(dialog_layer)
			jogador_node.usa_item(item_id)
			_update_status_panel()
		)
		list.add_child(btn)

	var btn_close = Button.new()
	btn_close.text = "Fechar"
	btn_close.pressed.connect(func(): _close_dialog(dialog_layer))
	vbox.add_child(btn_close)


# Resumo dos atributos de uma arma, partilhado pelos dois lados da tela de troca.
func _arma_stats_texto(arma) -> String:
	return "%s  [%s]\nDano: %d    Alcance: %d\nForça req.: %d    Precisão req.: %d\nValor: %d" % [
		arma.nome, arma.tipo, arma.dano, arma.alcance,
		arma.forca_necessaria, arma.precisao_necessaria, arma.valor]


# Tela de troca de arma: à esquerda os stats da arma equipada (com dano/acurácia
# já efetivos para a força atual), à direita o arsenal guardado. Clicar numa arma
# do arsenal empunha-a (devolvendo a anterior). Armas cujos requisitos não cumpres
# aparecem desativadas.
func _show_weapon_dialog() -> void:
	if not jogador_node:
		return
	if jogador_node.arma_equipada == null and jogador_node.armas.is_empty():
		_log("Não tens nenhuma arma para empunhar ou trocar.")
		return

	dialog_open = true

	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 11   # acima do Terminal (layer 10), p/ cobrir a sidebar
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -260
	panel.offset_top    = -200
	panel.offset_right  =  260
	panel.offset_bottom =  200
	dialog_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title = Label.new()
	title.text = "Arsenal — trocar de arma"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	root.add_child(title)

	var colunas = HBoxContainer.new()
	colunas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colunas.add_theme_constant_override("separation", 16)
	root.add_child(colunas)

	# --- Coluna esquerda: arma equipada ---
	var esq = VBoxContainer.new()
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esq.add_theme_constant_override("separation", 6)
	colunas.add_child(esq)

	var esq_titulo = Label.new()
	esq_titulo.text = "Equipada"
	esq_titulo.add_theme_font_size_override("font_size", 14)
	esq.add_child(esq_titulo)

	var equipada = Label.new()
	equipada.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if jogador_node.arma_equipada != null:
		equipada.text = "%s\n\nDano efetivo: %d\nAcurácia efetiva: %d" % [
			_arma_stats_texto(jogador_node.arma_equipada),
			jogador_node.dano_atual(), jogador_node.acuracia_atual()]
	else:
		equipada.text = "Desarmado.\n\nDano (só força): %d" % jogador_node.dano_atual()
	esq.add_child(equipada)

	# --- Coluna direita: armas no arsenal ---
	var dir = VBoxContainer.new()
	dir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dir.add_theme_constant_override("separation", 6)
	colunas.add_child(dir)

	var dir_titulo = Label.new()
	dir_titulo.text = "No arsenal (clica para empunhar)"
	dir_titulo.add_theme_font_size_override("font_size", 14)
	dir.add_child(dir_titulo)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dir.add_child(scroll)

	var lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	scroll.add_child(lista)

	if jogador_node.armas.is_empty():
		var vazio = Label.new()
		vazio.text = "(arsenal vazio)"
		lista.add_child(vazio)
	else:
		for indice in range(jogador_node.armas.size()):
			var arma = jogador_node.armas[indice]
			var apto : bool = jogador_node.cumpre_requisitos(arma)
			var marca : String = "" if apto else "   ✗ requisitos"
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 54)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.disabled = not apto
			btn.text = "%s (dano %d, alc %d)\nForça req. %d / Precisão req. %d%s" % [
				arma.nome, arma.dano, arma.alcance,
				arma.forca_necessaria, arma.precisao_necessaria, marca]
			var idx := indice
			btn.pressed.connect(func():
				_close_dialog(dialog_layer)
				jogador_node.equipa_arma(idx)
				_update_status_panel()
				_show_weapon_dialog()
			)
			lista.add_child(btn)

	var btn_fechar = Button.new()
	btn_fechar.text = "Fechar"
	btn_fechar.pressed.connect(func(): _close_dialog(dialog_layer))
	root.add_child(btn_fechar)


func _show_dictionary_dialog() -> void:
	if not jogador_node:
		return

	dialog_open = true

	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 11   # acima do Terminal (layer 10), p/ cobrir a sidebar
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -170
	panel.offset_top    =  -95
	panel.offset_right  =  170
	panel.offset_bottom =   95
	dialog_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Consultar dicionário"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var edit = LineEdit.new()
	edit.placeholder_text = "Palavra a consultar"
	edit.max_length = 32
	vbox.add_child(edit)

	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(fill)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var btn_close = Button.new()
	btn_close.text = "Fechar"
	btn_close.pressed.connect(func(): _close_dialog(dialog_layer))
	hbox.add_child(btn_close)

	var btn_ok = Button.new()
	btn_ok.text = "Procurar"
	btn_ok.pressed.connect(func():
		var q = edit.text.strip_edges()
		_close_dialog(dialog_layer)
		if not q.is_empty():
			jogador_node.abre_dicionario(q)
	)
	hbox.add_child(btn_ok)

	edit.text_submitted.connect(func(_t: String):
		var q = edit.text.strip_edges()
		_close_dialog(dialog_layer)
		if not q.is_empty():
			jogador_node.abre_dicionario(q)
	)
	edit.grab_focus()


func _show_speak_dialog() -> void:
	if not jogador_node:
		return

	dialog_open = true

	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 11   # acima do Terminal (layer 10), p/ cobrir a sidebar
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -190
	panel.offset_top    = -200
	panel.offset_right  =  190
	panel.offset_bottom =  200
	dialog_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "Falar em voz alta"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var edit = LineEdit.new()
	edit.placeholder_text = "O que deseja dizer?"
	edit.max_length = 48
	vbox.add_child(edit)

	# Atalho: clicar numa palavra de poder preenche a caixa com a sua incantação;
	# o jogador confirma na mesma com "Falar" (tudo continua a passar pela fala).
	var sep = HSeparator.new()
	vbox.add_child(sep)

	var ref_titulo = Label.new()
	ref_titulo.text = "Palavras de poder (clica para preencher)"
	ref_titulo.add_theme_font_size_override("font_size", 13)
	vbox.add_child(ref_titulo)

	var lista_magias = VBoxContainer.new()
	lista_magias.add_theme_constant_override("separation", 6)
	vbox.add_child(lista_magias)

	for m in palavras_data.get("magias", []):
		var inc : String = str(m.get("incantacao", ""))
		var nome_magia : String = str(m.get("nome", ""))
		var custo : int = int(m.get("custo_mana", 0))
		var aprendida : bool = jogador_node.ja_aprendeu_magia(nome_magia)
		var btn_magia = Button.new()
		btn_magia.custom_minimum_size = Vector2(0, 44)
		btn_magia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_magia.disabled = not aprendida
		if aprendida:
			btn_magia.text = "«%s» — %s   (%d mana)\n%s" % [inc, nome_magia, custo, _magia_descricao_curta(m)]
			btn_magia.pressed.connect(func():
				edit.text = inc
				edit.caret_column = inc.length()
				edit.grab_focus()
			)
		else:
			btn_magia.text = "«%s» — ???" % inc
		lista_magias.add_child(btn_magia)

	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(fill)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var btn_close = Button.new()
	btn_close.text = "Fechar"
	btn_close.pressed.connect(func(): _close_dialog(dialog_layer))
	hbox.add_child(btn_close)

	var btn_ok = Button.new()
	btn_ok.text = "Falar"
	btn_ok.pressed.connect(func():
		var q = edit.text
		_close_dialog(dialog_layer)
		jogador_node.falar(q)
	)
	hbox.add_child(btn_ok)

	edit.text_submitted.connect(func(_t: String):
		var q = edit.text
		_close_dialog(dialog_layer)
		jogador_node.falar(q)
	)
	edit.grab_focus()
