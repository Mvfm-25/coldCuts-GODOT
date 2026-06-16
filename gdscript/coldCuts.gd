extends Node2D

const CA             = preload("res://gdscript/cellularAutomata.gd")
const TerminalScene  = preload("res://scenes/terminal.tscn")

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
var items : Array = []
var enemies_data : Array = []
var items_data : Array = []
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
	dialog_layer.layer = 9
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
	dialog_layer.layer = 9
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
	menu_layer.hide()
	_load_random_dungeon()
	if current_dungeon == null:
		return
	_draw_dungeon()
	_spawn_player()
	_create_jogador()
	_initialize_dungeon_for_game()
	dungeon_label.text = current_dungeon.name
	dungeon_label.show()
	_log("Aventura iniciada! Personagem: %s (%s)" % [player_name, player_class])


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

	files.shuffle()
	current_dungeon = CA.DungeonIO.load(files[0])
	_log("Masmorra carregada: " + (current_dungeon.name if current_dungeon else "ERRO"))


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


func _spawn_player() -> void:
	var start = _find_valid_start()
	player_x = start.x
	player_y = start.y

	if is_instance_valid(player_sprite):
		player_sprite.queue_free()
	player_sprite = Sprite2D.new()

	var tex = load("res://assets/player/Funny_Little_Fella.png") as Texture2D
	if tex:
		player_sprite.texture = tex
		var sf = float(tile_size) / maxf(float(tex.get_width()), float(tex.get_height()))
		player_sprite.scale = Vector2(sf, sf)
	else:
		push_warning("Sprite não encontrada: res://assets/player/Funny_Little_Fella.png")
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
			e.label.visible = visible.has(Vector2i(e.x, e.y))
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
	jogador_node.pediu_boss.connect(_on_pediu_boss)
	jogador_node.pediu_exterminatus.connect(_on_pediu_exterminatus)
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
	items.clear()

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


func _initialize_dungeon_for_game() -> void:
	_clear_entity_labels()
	_load_entities_data()
	_populate_enemies(20)
	_populate_items(10)
	_update_fov()
	_update_status_panel()


# --- Painel de status ---

# Reúne os stats atuais do jogador e envia-os ao painel ">> status" do terminal.
# O 'ouro' é o valor somado de todos os itens no inventário.
func _update_status_panel() -> void:
	if terminal == null or jogador_node == null:
		return

	var ouro := 0
	for entrada in jogador_node.inventario:
		ouro += entrada[1].valor

	# Linha da arma deixada reservada para o futuro sistema de troca de armas.
	var texto := "HP: %d / %d\n" % [jogador_node.hp, jogador_node.hp_maximo]
	texto += "Ataque: %d    Armadura: %d\n" % [jogador_node.ataque, jogador_node.armadura]
	texto += "Nível: %d    XP: %d / %d\n" % [jogador_node.lvl, jogador_node.xp, jogador_node.xp_proximo_nivel]
	texto += "Ouro: %d\n" % ouro
	texto += "[color=#5a7a5a]Arma: — (nenhuma)[/color]"

	terminal.set_status(texto)


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

	var tx := player_x + dir.x
	var ty := player_y + dir.y

	var alvo = null
	var bateu_parede := false

	if tx < 0 or tx >= current_dungeon.width or ty < 0 or ty >= current_dungeon.height:
		bateu_parede = true
	else:
		for e in enemies:
			if e.x == tx and e.y == ty:
				alvo = e
				break
		if alvo == null and current_dungeon.grid[tx][ty].state == "1":
			bateu_parede = true

	var derrotou : bool = jogador_node.ataca(alvo, bateu_parede)
	if derrotou and alvo != null:
		if is_instance_valid(alvo.label):
			entity_labels.erase(alvo.label)
			alvo.label.queue_free()
		enemies.erase(alvo)
		alvo.queue_free()

	# Atacar consome o turno do jogador: os adversários reagem a seguir.
	_process_enemy_turns()


func _try_move(new_x : int, new_y : int) -> void:
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

	# A posição dos inimigos mudou: reavaliar o que está visível.
	_update_fov()
	# Combate pode ter mudado HP/armadura do jogador.
	_update_status_panel()


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


# --- Masmorra de boss (invocada pela fala secreta do Jogador) ---

# Disparado pelo sinal pediu_boss do Jogador. O Jogador já validou a frase e a
# posse da chave; cabe ao jogo escolher e carregar uma masmorra de boss.
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

# Disparado pelo sinal pediu_exterminatus. Remove todos os inimigos do mapa —
# o Jogador não conhece a lista de inimigos, por isso a limpeza cabe ao jogo.
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
	dialog_layer.layer = 9
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


func _show_dictionary_dialog() -> void:
	if not jogador_node:
		return

	dialog_open = true

	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 9
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
	dialog_layer.layer = 9
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
	title.text = "Falar em voz alta"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var edit = LineEdit.new()
	edit.placeholder_text = "O que deseja dizer?"
	edit.max_length = 48
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
