extends Node2D

@export var node_scene : PackedScene
var dimensions : int = 50
var node_matrix : Array = []

var current_dungeon : Dungeon
var popup_layer : CanvasLayer
var popup_panel : Panel
var popup_label : Label

var menu_layer : CanvasLayer
var overlay_layer : CanvasLayer
var status_label : Label
var dungeon_name_label : Label
var is_generating : bool = false
var is_manual_editing : bool = false


class Ameba:
	var rng = RandomNumberGenerator.new()
	var state : String
	var neighbors : int
	var name : String
	var x : int
	var y : int

	func _init() -> void:
		state = str(rng.randi_range(0, 1))
		neighbors = 0
		name = "Wall" if state == "1" else "Floor"

	func calculate_neighbors(dungeon : Array) -> int:
		neighbors = 0
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx = x + dx
				var ny = y + dy
				if 0 <= nx and nx < dungeon.size() and 0 <= ny and ny < dungeon[0].size():
					if dungeon[nx][ny].state == "1":
						neighbors += 1
		return neighbors

	func update_state(new_state : String) -> void:
		state = new_state
		name = "Wall" if state == "1" else "Floor"


class Dungeon:
	var rng = RandomNumberGenerator.new()
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
		name = p.pick_random() + " " + m.pick_random() + " " + f.pick_random()

	# Inicializa o grid com todas as células como paredes, para edição manual.
	func init_empty_grid() -> void:
		grid = []
		paths = 0
		walls = 0
		generate_name()
		for i in range(width):
			var row = []
			for j in range(height):
				var ameba = Ameba.new()
				ameba.update_state("1")
				ameba.x = i
				ameba.y = j
				walls += 1
				row.append(ameba)
			grid.append(row)

	# Inicializa o grid com estado aleatório, sem evoluir gerações.
	func init_grid() -> void:
		grid = []
		paths = 0
		walls = 0
		generate_name()
		for i in range(width):
			var row = []
			for j in range(height):
				var ameba = Ameba.new()
				ameba.x = i
				ameba.y = j
				if ameba.state == "1":
					walls += 1
				else:
					paths += 1
				row.append(ameba)
			grid.append(row)

	func generate_grid(generations : int) -> Array:
		init_grid()
		for g in range(generations):
			print("Gen : ", g)
			game_rules()
			print_dungeon()
			print("Caminhos : ", paths, " | Paredes : ", walls, "\n")
		print("Masmorra gerada!")
		return grid

	func game_rules() -> void:
		var changes : int = 0
		for i in range(width):
			for j in range(height):
				grid[i][j].calculate_neighbors(grid)
		for i in range(width):
			for j in range(height):
				var ameba = grid[i][j]
				if ameba.neighbors > 4 and ameba.state == "1":
					ameba.update_state("0")
					changes += 1
					paths += 1
					walls -= 1
				if mutate_ameba(ameba):
					changes += 1
					if ameba.state == "1":
						paths -= 1
						walls += 1
					else:
						paths += 1
						walls -= 1
		print("Geração finalizada. ", changes, " mudanças aplicadas.")

	func mutate_ameba(ameba : Ameba) -> bool:
		if rng.randi_range(0, 99) < 25:
			ameba.update_state("1") if ameba.state == "0" else ameba.update_state("0")
			return true
		return false

	func print_dungeon() -> void:
		for i in range(width):
			var row_str : String = ""
			for j in range(height):
				row_str += grid[i][j].state + " "
			print(row_str)


class DungeonIO:
	static func _get_save_path(dungeon : Dungeon) -> String:
		var sanitized = dungeon.name.to_lower().replace(" ", "_")
		return "res://dungeons/" + sanitized + ".dungeon"

	static func save(dungeon : Dungeon) -> void:
		var data = {
			"name": dungeon.name,
			"width": dungeon.width,
			"height": dungeon.height,
			"grid": []
		}
		for row in dungeon.grid:
			var row_data := []
			for ameba in row:
				row_data.append(ameba.state)
			data["grid"].append(row_data)

		var path = _get_save_path(dungeon)
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(data, "\t"))
			file.close()
			print("Masmorra salva em: " + path)
		else:
			push_error("Não foi possível salvar em: " + path)

	static func load(path : String) -> Dungeon:
		var file := FileAccess.open(path, FileAccess.READ)
		if not file:
			push_error("Não foi possível abrir: " + path)
			return null
		var parsed : Variant = JSON.parse_string(file.get_as_text())
		file.close()

		var dungeon := Dungeon.new()
		dungeon.name = parsed["name"]
		dungeon.width = parsed["width"]
		dungeon.height = parsed["height"]
		dungeon.grid = []
		dungeon.walls = 0
		dungeon.paths = 0

		# grid[x][y] — mesma convenção de generate_grid
		for x in dungeon.width:
			var row := []
			for y in dungeon.height:
				var ameba := Ameba.new()
				ameba.x = x
				ameba.y = y
				ameba.update_state(parsed["grid"][x][y])
				row.append(ameba)
			dungeon.grid.append(row)

		for row in dungeon.grid:
			for ameba in row:
				if ameba.state == "1": dungeon.walls += 1
				else: dungeon.paths += 1

		return dungeon


## Funções do Node2D ##

func _calculate_tile_size(width : int, height : int) -> int:
	var vp = get_viewport().get_visible_rect().size
	var tile_w = int(vp.x / width)
	var tile_h = int(vp.y / height)
	return max(6, min(tile_w, tile_h))


func _draw_dungeon(dungeon : Dungeon) -> void:
	for col in node_matrix:
		for tile in col:
			tile.queue_free()
	node_matrix.clear()

	var tile_size = _calculate_tile_size(dungeon.width, dungeon.height)
	dimensions = tile_size

	for _i in range(dungeon.width):
		node_matrix.append([])

	for row in dungeon.grid:
		for ameba in row:
			var tile : Sprite2D = node_scene.instantiate()
			tile.position = Vector2(ameba.x * tile_size, ameba.y * tile_size)
			tile.scale = Vector2(float(tile_size) / 128.0, float(tile_size) / 128.0)
			tile.modulate = Color(0.25, 0.22, 0.20) if ameba.state == "1" else Color(0.65, 0.58, 0.44)
			add_child(tile)
			node_matrix[ameba.x].append(tile)


func _create_popup() -> void:
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 10
	add_child(popup_layer)

	popup_panel = Panel.new()
	popup_panel.custom_minimum_size = Vector2(250, 100)
	popup_panel.hide()
	popup_layer.add_child(popup_panel)

	popup_label = Label.new()
	popup_label.position = Vector2(8, 8)
	popup_panel.add_child(popup_label)


func _create_main_menu() -> void:
	# Overlay: labels e botão de voltar — sempre visível quando dungeon está ativa
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 5
	add_child(overlay_layer)

	dungeon_name_label = Label.new()
	dungeon_name_label.position = Vector2(10, 8)
	dungeon_name_label.add_theme_font_size_override("font_size", 16)
	dungeon_name_label.hide()
	overlay_layer.add_child(dungeon_name_label)

	status_label = Label.new()
	status_label.position = Vector2(10, 32)
	status_label.hide()
	overlay_layer.add_child(status_label)

	# Menu principal
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 8
	add_child(menu_layer)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(320, 250)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left  = -160
	panel.offset_top   = -125
	panel.offset_right = 160
	panel.offset_bottom = 125
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
	subtitle.text = "Gerador de Masmorras"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var btn_create = Button.new()
	btn_create.text = "Criar Masmorra"
	btn_create.custom_minimum_size = Vector2(0, 44)
	btn_create.pressed.connect(_show_create_dialog)
	vbox.add_child(btn_create)

	var btn_load = Button.new()
	btn_load.text = "Carregar Masmorra"
	btn_load.custom_minimum_size = Vector2(0, 44)
	btn_load.pressed.connect(_show_load_dialog)
	vbox.add_child(btn_load)


func _show_create_dialog() -> void:
	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 9
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 250)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left  = -150
	panel.offset_top   = -125
	panel.offset_right = 150
	panel.offset_bottom = 125
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
	title.text = "Criar Masmorra"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Escolha o modo de criação:"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var btn_auto = Button.new()
	btn_auto.text = "Criação Automática"
	btn_auto.custom_minimum_size = Vector2(0, 44)
	btn_auto.pressed.connect(func():
		dialog_layer.queue_free()
		_show_auto_config_dialog()
	)
	vbox.add_child(btn_auto)

	var btn_manual = Button.new()
	btn_manual.text = "Criação Manual"
	btn_manual.custom_minimum_size = Vector2(0, 44)
	btn_manual.pressed.connect(func():
		dialog_layer.queue_free()
		_show_manual_config_dialog()
	)
	vbox.add_child(btn_manual)

	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(fill)

	var btn_cancel = Button.new()
	btn_cancel.text = "Cancelar"
	btn_cancel.pressed.connect(func(): dialog_layer.queue_free())
	vbox.add_child(btn_cancel)


func _show_auto_config_dialog() -> void:
	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 9
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left  = -140
	panel.offset_top   = -150
	panel.offset_right = 140
	panel.offset_bottom = 150
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
	title.text = "Criação Automática"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var spin_w = _make_spin_row(vbox, "Largura:",  5, 80, 20)
	var spin_h = _make_spin_row(vbox, "Altura:",   5, 80, 20)
	var spin_g = _make_spin_row(vbox, "Gerações:", 1, 20,  5)

	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(fill)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var btn_cancel = Button.new()
	btn_cancel.text = "Voltar"
	btn_cancel.pressed.connect(func():
		dialog_layer.queue_free()
		_show_create_dialog()
	)
	hbox.add_child(btn_cancel)

	var btn_ok = Button.new()
	btn_ok.text = "Gerar"
	btn_ok.pressed.connect(func():
		var w = int(spin_w.value)
		var h = int(spin_h.value)
		var g = int(spin_g.value)
		dialog_layer.queue_free()
		menu_layer.hide()
		_start_generation(w, h, g)
	)
	hbox.add_child(btn_ok)


func _show_manual_config_dialog() -> void:
	var dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 9
	add_child(dialog_layer)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.add_child(bg)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(280, 260)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left  = -140
	panel.offset_top   = -130
	panel.offset_right = 140
	panel.offset_bottom = 130
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
	title.text = "Criação Manual"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var hint = Label.new()
	hint.text = "Clique nos tiles para alternar\nentre parede e caminho."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	var spin_w = _make_spin_row(vbox, "Largura:", 5, 80, 20)
	var spin_h = _make_spin_row(vbox, "Altura:",  5, 80, 20)

	var fill = Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(fill)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var btn_cancel = Button.new()
	btn_cancel.text = "Voltar"
	btn_cancel.pressed.connect(func():
		dialog_layer.queue_free()
		_show_create_dialog()
	)
	hbox.add_child(btn_cancel)

	var btn_ok = Button.new()
	btn_ok.text = "Desenhar"
	btn_ok.pressed.connect(func():
		var w = int(spin_w.value)
		var h = int(spin_h.value)
		dialog_layer.queue_free()
		menu_layer.hide()
		_start_manual_edit(w, h)
	)
	hbox.add_child(btn_ok)


func _start_manual_edit(width : int, height : int) -> void:
	var dungeon = Dungeon.new()
	dungeon.set_width(width)
	dungeon.set_height(height)
	dungeon.init_empty_grid()
	current_dungeon = dungeon
	is_manual_editing = true

	dungeon_name_label.text = dungeon.name
	dungeon_name_label.show()
	_update_dungeon_status()
	status_label.show()
	_draw_dungeon(dungeon)
	_show_manual_buttons()


func _update_dungeon_status() -> void:
	if current_dungeon == null:
		return
	status_label.text = "%dx%d  |  Paredes: %d  |  Caminhos: %d" % [
		current_dungeon.width, current_dungeon.height,
		current_dungeon.walls, current_dungeon.paths
	]


func _show_manual_buttons() -> void:
	var cleanup = func():
		is_manual_editing = false
		dungeon_name_label.hide()
		status_label.hide()
		popup_panel.hide()
		current_dungeon = null
		for col in node_matrix:
			for tile in col:
				tile.queue_free()
		node_matrix.clear()
		for child in overlay_layer.get_children():
			if child is Button:
				child.queue_free()
		menu_layer.show()

	var btn_save = Button.new()
	btn_save.text = "Salvar Masmorra"
	btn_save.custom_minimum_size = Vector2(160, 36)
	btn_save.position = Vector2(10, 58)
	btn_save.pressed.connect(func():
		DungeonIO.save(current_dungeon)
		cleanup.call()
	)
	overlay_layer.add_child(btn_save)

	var btn_discard = Button.new()
	btn_discard.text = "Descartar e Voltar"
	btn_discard.custom_minimum_size = Vector2(160, 36)
	btn_discard.position = Vector2(10, 100)
	btn_discard.pressed.connect(cleanup)
	overlay_layer.add_child(btn_discard)


func _make_spin_row(parent : Node, label_text : String, min_val : float, max_val : float, default_val : float) -> SpinBox:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(lbl)

	var spin = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.value = default_val
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spin)
	return spin


func _show_load_dialog() -> void:
	var dialog = FileDialog.new()
	dialog.title = "Carregar Masmorra"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_RESOURCES
	dialog.add_filter("*.dungeon", "Masmorras")
	dialog.current_dir = "res://dungeons"
	dialog.file_selected.connect(func(path : String):
		dialog.queue_free()
		_on_dungeon_loaded(path)
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2(700, 500))


func _on_dungeon_loaded(path : String) -> void:
	var dungeon = DungeonIO.load(path)
	if dungeon == null:
		return
	current_dungeon = dungeon
	menu_layer.hide()
	_draw_dungeon(dungeon)
	dungeon_name_label.text = dungeon.name
	dungeon_name_label.show()
	status_label.text = "%dx%d  |  Paredes: %d  |  Caminhos: %d" % [
		dungeon.width, dungeon.height, dungeon.walls, dungeon.paths
	]
	status_label.show()
	_show_back_button()


func _start_generation(width : int, height : int, generations : int) -> void:
	if is_generating:
		return
	is_generating = true

	var dungeon = Dungeon.new()
	dungeon.set_width(width)
	dungeon.set_height(height)
	dungeon.init_grid()
	current_dungeon = dungeon

	dungeon_name_label.text = dungeon.name
	dungeon_name_label.show()
	status_label.text = "Geração: 0 / %d" % generations
	status_label.show()
	_draw_dungeon(dungeon)

	for g in range(generations):
		await get_tree().create_timer(0.4).timeout
		dungeon.game_rules()
		_draw_dungeon(dungeon)
		status_label.text = "Geração: %d / %d" % [g + 1, generations]

	DungeonIO.save(dungeon)
	status_label.text = "Concluído!  %dx%d  |  Paredes: %d  |  Caminhos: %d" % [
		dungeon.width, dungeon.height, dungeon.walls, dungeon.paths
	]
	is_generating = false
	_show_back_button()


func _show_back_button() -> void:
	var btn = Button.new()
	btn.text = "Voltar ao Menu"
	btn.custom_minimum_size = Vector2(160, 36)
	btn.position = Vector2(10, 58)
	btn.pressed.connect(func():
		btn.queue_free()
		dungeon_name_label.hide()
		status_label.hide()
		popup_panel.hide()
		current_dungeon = null
		for col in node_matrix:
			for tile in col:
				tile.queue_free()
		node_matrix.clear()
		menu_layer.show()
	)
	overlay_layer.add_child(btn)


func _input(event : InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if current_dungeon == null or is_generating:
		return

	var grid_x := int(event.position.x / dimensions)
	var grid_y := int(event.position.y / dimensions)
	var in_bounds = grid_x >= 0 and grid_x < current_dungeon.width and \
					grid_y >= 0 and grid_y < current_dungeon.height

	if event.button_index == MOUSE_BUTTON_LEFT:
		popup_panel.hide()
		if is_manual_editing and in_bounds:
			var ameba : Ameba = current_dungeon.grid[grid_x][grid_y]
			var new_state = "0" if ameba.state == "1" else "1"
			ameba.update_state(new_state)
			node_matrix[grid_x][grid_y].modulate = \
				Color(0.25, 0.22, 0.20) if new_state == "1" else Color(0.65, 0.58, 0.44)
			if new_state == "1":
				current_dungeon.walls += 1
				current_dungeon.paths -= 1
			else:
				current_dungeon.walls -= 1
				current_dungeon.paths += 1
			_update_dungeon_status()

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if in_bounds:
			var ameba : Ameba = current_dungeon.grid[grid_x][grid_y]
			popup_label.text = "X: %d  Y: %d\nEstado: %s\nVizinhos vivos: %d" % [
				ameba.x, ameba.y, ameba.name,
				ameba.calculate_neighbors(current_dungeon.grid)
			]
			popup_panel.position = event.position + Vector2(10, 10)
			popup_panel.show()
		else:
			popup_panel.hide()


func _ready() -> void:
	_create_popup()
	_create_main_menu()
