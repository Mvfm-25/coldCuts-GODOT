extends Node2D

const CA = preload("res://gdscript/cellularAutomata.gd")

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


func _ready() -> void:
	_create_hud()
	_create_main_menu()


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
	menu_layer.hide()
	_load_random_dungeon()
	if current_dungeon == null:
		return
	_draw_dungeon()
	_spawn_player()
	dungeon_label.text = current_dungeon.name
	dungeon_label.show()
	print("Aventura iniciada! Personagem: %s (%s)" % [player_name, player_class])


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
	print("Masmorra carregada: ", current_dungeon.name if current_dungeon else "ERRO")


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
	player_sprite.z_index = 1
	add_child(player_sprite)


func _tile_pixel_pos(gx : int, gy : int) -> Vector2:
	return Vector2(gx * tile_size + tile_size * 0.5, gy * tile_size + tile_size * 0.5)


func _input(event : InputEvent) -> void:
	if current_dungeon == null:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var dx := 0
	var dy := 0

	match event.keycode:
		KEY_W, KEY_UP:     dy = -1
		KEY_S, KEY_DOWN:   dy =  1
		KEY_A, KEY_LEFT:   dx = -1
		KEY_D, KEY_RIGHT:  dx =  1
		KEY_Q:             dx = -1; dy = -1
		KEY_E:             dx =  1; dy = -1
		KEY_Z:             dx = -1; dy =  1
		KEY_C:             dx =  1; dy =  1
		KEY_KP_7:          dx = -1; dy = -1
		KEY_KP_8:          dy = -1
		KEY_KP_9:          dx =  1; dy = -1
		KEY_KP_4:          dx = -1
		KEY_KP_6:          dx =  1
		KEY_KP_1:          dx = -1; dy =  1
		KEY_KP_2:          dy =  1
		KEY_KP_3:          dx =  1; dy =  1

	if dx == 0 and dy == 0:
		return

	_try_move(player_x + dx, player_y + dy)


func _try_move(new_x : int, new_y : int) -> void:
	if new_x < 0 or new_x >= current_dungeon.width:
		return
	if new_y < 0 or new_y >= current_dungeon.height:
		return
	if current_dungeon.grid[new_x][new_y].state == "1":
		return

	player_x = new_x
	player_y = new_y
	player_sprite.position = _tile_pixel_pos(player_x, player_y)
