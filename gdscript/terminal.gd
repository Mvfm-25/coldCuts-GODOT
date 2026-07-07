extends CanvasLayer

const MAX_LINES := 20

# Verde do terminal, reutilizado em toda a HUD para manter a coerência visual.
const VERDE := Color(0.15, 0.9, 0.15)

var _lines : Array = []
var _label : RichTextLabel

# --- Sidebar do herói (barra lateral com HP/escudo, sprite, stats e inventário) ---
var _sidebar_panel : Panel
var _hp_fill : ColorRect
var _hp_label : Label
var _escudo_fill : ColorRect
var _escudo_label : Label
# Barras verticais de XP e Mana, ao lado das de HP/Escudo.
var _xp_fill : ColorRect
var _xp_bar : Panel
var _mana_fill : ColorRect
var _mana_bar : Panel
var _sprite_rect : TextureRect
var _nome_label : Label
var _classe_label : Label
var _nivel_label : Label
var _abates_label : Label
var _ouro_label : Label
var _btn_armas : Button
var _btn_itens : Button
var _inv_list : ItemList
# Últimas listas recebidas, para alternar entre armas/itens sem pedir dados de novo.
var _armas_cache : Array = []
var _itens_cache : Array = []
var _modo_inv : String = "armas"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	_build_binds_panel()
	_build_sidebar()

	var panel := Panel.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -310
	panel.offset_top    = -452
	panel.offset_right  = -10
	panel.offset_bottom = -60

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.04, 0.88)
	style.border_color = Color(0.15, 0.75, 0.15, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var header := Label.new()
	header.text = ">> terminal"
	header.position = Vector2(8, 4)
	header.add_theme_color_override("font_color", Color(0.15, 0.9, 0.15))
	header.add_theme_font_size_override("font_size", 12)
	panel.add_child(header)

	var sep := ColorRect.new()
	sep.color = Color(0.15, 0.75, 0.15, 0.4)
	sep.anchor_right  = 1.0
	sep.offset_top    = 22
	sep.offset_bottom = 23
	panel.add_child(sep)

	_label = RichTextLabel.new()
	_label.anchor_right  = 1.0
	_label.anchor_bottom = 1.0
	_label.offset_top    = 26
	_label.offset_left   = 6
	_label.offset_right  = -4
	_label.offset_bottom = -6
	_label.scroll_active    = true
	_label.scroll_following = true
	_label.bbcode_enabled   = false
	_label.add_theme_color_override("default_color", Color(0.15, 0.9, 0.15))
	_label.add_theme_font_size_override("normal_font_size", 11)
	panel.add_child(_label)


# Painel de binds, no topo da pilha, espelhando a linha de controles do coldCuts.py.
# Texto reformatado em linhas curtas (com autowrap) para caber na coluna estreita.
func _build_binds_panel() -> void:
	var panel := Panel.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -310
	panel.offset_top    = -566
	panel.offset_right  = -10
	panel.offset_bottom = -460

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.04, 0.88)
	style.border_color = Color(0.15, 0.75, 0.15, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var header := Label.new()
	header.text = ">> controles"
	header.position = Vector2(8, 4)
	header.add_theme_color_override("font_color", Color(0.15, 0.9, 0.15))
	header.add_theme_font_size_override("font_size", 12)
	panel.add_child(header)

	var binds := Label.new()
	binds.anchor_right = 1.0
	binds.offset_left  = 8
	binds.offset_top   = 24
	binds.offset_right = -8
	binds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binds.text = "Mover: setas / WSD / numpad   Diagonais: Q E Z C\nAtacar: A + direção   Inventário: I\nUsar: U   Trocar arma: T   Dicionário: G\nPortal: P   Falar: F"
	binds.add_theme_color_override("font_color", Color(0.15, 0.9, 0.15))
	binds.add_theme_font_size_override("font_size", 11)
	panel.add_child(binds)


func add_line(text: String) -> void:
	_lines.append(text)
	if _lines.size() > MAX_LINES:
		_lines = _lines.slice(_lines.size() - MAX_LINES)
	_label.text = "\n".join(_lines)


# --- Sidebar do herói ---
# Coluna à esquerda dos painéis do terminal. Mostra, de cima para baixo: barra de
# HP e de escudo, o sprite grande da classe, o nome/classe, os abates e o ouro, e
# por fim o inventário (alternável entre Armas e Itens). Os dados chegam do
# coldCuts.gd (dono do jogador) via set_sidebar_heroi()/set_sidebar_inventario().
func _build_sidebar() -> void:
	var panel := Panel.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -616
	panel.offset_top    = -566
	panel.offset_right  = -318
	panel.offset_bottom = -60

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.04, 0.88)
	style.border_color = Color(0.15, 0.75, 0.15, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	_sidebar_panel = panel
	# Só aparece quando uma aventura começa (ver mostra_sidebar()); fica oculta no menu.
	panel.hide()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_top", "margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header := _label_verde(">> herói", 12)
	vbox.add_child(header)

	var sep := ColorRect.new()
	sep.color = Color(0.15, 0.75, 0.15, 0.4)
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)

	# Bloco superior: à esquerda as barras horizontais de HP (vermelho) e escudo
	# (azul); à direita, as barras VERTICAIS de XP (dourado) e Mana (azul).
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 8)
	vbox.add_child(topo)

	var barras_hor := VBoxContainer.new()
	barras_hor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barras_hor.add_theme_constant_override("separation", 4)
	topo.add_child(barras_hor)

	_hp_label = _label_verde("HP  —", 11)
	barras_hor.add_child(_hp_label)
	var hp_bar := _cria_barra(14, Color(0.85, 0.2, 0.2))
	_hp_fill = hp_bar[1]
	barras_hor.add_child(hp_bar[0])

	_escudo_label = _label_verde("Escudo  —", 11)
	barras_hor.add_child(_escudo_label)
	var esc_bar := _cria_barra(10, Color(0.3, 0.6, 0.95))
	_escudo_fill = esc_bar[1]
	barras_hor.add_child(esc_bar[0])

	var verticais := HBoxContainer.new()
	verticais.add_theme_constant_override("separation", 6)
	verticais.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	topo.add_child(verticais)

	var xp_col := _cria_coluna_vertical("XP", Color(0.9, 0.75, 0.15), 58)
	_xp_bar  = xp_col["root"]
	_xp_fill = xp_col["fill"]
	verticais.add_child(xp_col["col"])

	var mana_col := _cria_coluna_vertical("Mn", Color(0.3, 0.55, 0.95), 58)
	_mana_bar  = mana_col["root"]
	_mana_fill = mana_col["fill"]
	verticais.add_child(mana_col["col"])

	# Sprite grande da classe escolhida (pixel-art: filtro nearest para não borrar).
	_sprite_rect = TextureRect.new()
	_sprite_rect.custom_minimum_size = Vector2(0, 110)
	_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_sprite_rect)

	_nome_label = _label_verde("—", 16)
	_nome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_nome_label)

	_classe_label = _label_verde("—", 12)
	_classe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_classe_label)

	_nivel_label = _label_verde("Nível —", 12)
	_nivel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_nivel_label)

	# Abates à esquerda, ouro à direita, na mesma linha.
	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_hbox)

	_abates_label = _label_verde("Abates: 0", 12)
	_abates_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_hbox.add_child(_abates_label)

	_ouro_label = _label_verde("Ouro: 0", 12)
	_ouro_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ouro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_hbox.add_child(_ouro_label)

	var sep2 := ColorRect.new()
	sep2.color = Color(0.15, 0.75, 0.15, 0.4)
	sep2.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep2)

	vbox.add_child(_label_verde("Inventário", 12))

	# Botões de alternância Armas / Itens (toggle: o ativo fica pressionado).
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 6)
	vbox.add_child(botoes)

	_btn_armas = _cria_botao_aba("Armas", "armas")
	botoes.add_child(_btn_armas)
	_btn_itens = _cria_botao_aba("Itens", "itens")
	botoes.add_child(_btn_itens)

	_inv_list = ItemList.new()
	_inv_list.focus_mode = Control.FOCUS_NONE
	_inv_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_list.add_theme_font_size_override("font_size", 11)
	_inv_list.add_theme_color_override("font_color", VERDE)
	vbox.add_child(_inv_list)

	_atualiza_abas()
	_refresh_inv_list()


# Mostra/esconde a sidebar do herói. O coldCuts.gd revela-a ao começar a aventura
# e volta a escondê-la ao regressar ao menu (morte do jogador).
func mostra_sidebar() -> void:
	if _sidebar_panel:
		_sidebar_panel.show()


func esconde_sidebar() -> void:
	if _sidebar_panel:
		_sidebar_panel.hide()


# Label verde padrão da HUD.
func _label_verde(txt: String, tam: int) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", VERDE)
	l.add_theme_font_size_override("font_size", tam)
	return l


# Botão-aba do inventário. focus_mode NONE para não roubar as setas do jogo.
func _cria_botao_aba(texto: String, modo: String) -> Button:
	var btn := Button.new()
	btn.text = texto
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func(): _mostra_inv(modo))
	return btn


# Cria uma barra (fundo + preenchimento). Devolve [root, fill]; a largura do
# preenchimento ajusta-se depois via _set_fill() mexendo no anchor_right.
func _cria_barra(altura: int, cor: Color) -> Array:
	var root := Panel.new()
	root.custom_minimum_size = Vector2(0, altura)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.13, 0.10, 0.95)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.15, 0.5, 0.15, 0.8)
	root.add_theme_stylebox_override("panel", bg)

	var fill := ColorRect.new()
	fill.color = cor
	fill.anchor_left   = 0.0
	fill.anchor_top    = 0.0
	fill.anchor_right  = 1.0
	fill.anchor_bottom = 1.0
	fill.offset_left   = 1
	fill.offset_top    = 1
	fill.offset_right  = -1
	fill.offset_bottom = -1
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fill)
	return [root, fill]


# Ajusta o preenchimento de uma barra horizontal à fração valor/máximo (0..1).
func _set_fill(fill: ColorRect, valor: int, maximo: int) -> void:
	if fill == null:
		return
	var ratio := 0.0
	if maximo > 0:
		ratio = clampf(float(valor) / float(maximo), 0.0, 1.0)
	fill.anchor_right = ratio


# Coluna de uma barra vertical (barra + legenda por baixo). Devolve os nós num
# dicionário: "col" (a coluna a inserir), "root" (a barra, p/ tooltip) e "fill".
func _cria_coluna_vertical(legenda: String, cor: Color, altura: int) -> Dictionary:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var bar := _cria_barra_vertical(16, altura, cor)
	col.add_child(bar[0])

	var cap := _label_verde(legenda, 10)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cap)

	return { "col": col, "root": bar[0], "fill": bar[1] }


# Cria uma barra vertical (fundo + preenchimento que cresce de baixo para cima).
# Devolve [root, fill]; a altura do preenchimento ajusta-se via _set_fill_vertical().
func _cria_barra_vertical(largura: int, altura: int, cor: Color) -> Array:
	var root := Panel.new()
	root.custom_minimum_size = Vector2(largura, altura)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.13, 0.10, 0.95)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.15, 0.5, 0.15, 0.8)
	root.add_theme_stylebox_override("panel", bg)

	var fill := ColorRect.new()
	fill.color = cor
	fill.anchor_left   = 0.0
	fill.anchor_right  = 1.0
	fill.anchor_top    = 1.0   # vazio: topo colado ao fundo (sobe conforme a fração)
	fill.anchor_bottom = 1.0
	fill.offset_left   = 1
	fill.offset_right  = -1
	fill.offset_top    = 1
	fill.offset_bottom = -1
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fill)
	return [root, fill]


# Ajusta uma barra vertical: o topo do preenchimento sobe conforme valor/máximo.
func _set_fill_vertical(fill: ColorRect, valor: int, maximo: int) -> void:
	if fill == null:
		return
	var ratio := 0.0
	if maximo > 0:
		ratio = clampf(float(valor) / float(maximo), 0.0, 1.0)
	fill.anchor_top = 1.0 - ratio


# Preenche o topo da sidebar (barras, sprite, nome/classe/nível, abates e ouro).
func set_sidebar_heroi(sprite_path: String, nome: String, classe: String, nivel: int,
		hp: int, hp_max: int, escudo: int, escudo_max: int,
		xp: int, xp_max: int, mana: int, mana_max: int, abates: int, ouro: int) -> void:
	if _sidebar_panel == null:
		return

	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		_sprite_rect.texture = load(sprite_path)

	_nome_label.text   = nome
	_classe_label.text = classe
	_nivel_label.text  = "Nível %d" % nivel
	_abates_label.text = "Abates: %d" % abates
	_ouro_label.text   = "Ouro: %d" % ouro

	_hp_label.text = "HP  %d / %d" % [hp, hp_max]
	_set_fill(_hp_fill, hp, hp_max)

	if escudo_max > 0:
		_escudo_label.text = "Escudo  %d / %d" % [escudo, escudo_max]
	else:
		_escudo_label.text = "Escudo  —"
	_set_fill(_escudo_fill, escudo, escudo_max)

	# Barras verticais: XP (rumo ao próximo nível) e Mana. Tooltip mostra os valores.
	_set_fill_vertical(_xp_fill, xp, xp_max)
	_xp_bar.tooltip_text = "XP: %d / %d" % [xp, xp_max]
	_set_fill_vertical(_mana_fill, mana, mana_max)
	_mana_bar.tooltip_text = ("Mana: %d / %d" % [mana, mana_max]) if mana_max > 0 else "Mana: —"


# Recebe as listas (já formatadas) de armas e itens e mostra a aba ativa.
func set_sidebar_inventario(armas: Array, itens: Array) -> void:
	_armas_cache = armas
	_itens_cache = itens
	_refresh_inv_list()


func _mostra_inv(modo: String) -> void:
	_modo_inv = modo
	_atualiza_abas()
	_refresh_inv_list()


func _atualiza_abas() -> void:
	if _btn_armas:
		_btn_armas.button_pressed = (_modo_inv == "armas")
	if _btn_itens:
		_btn_itens.button_pressed = (_modo_inv == "itens")


func _refresh_inv_list() -> void:
	if _inv_list == null:
		return
	_inv_list.clear()
	var origem : Array = _armas_cache if _modo_inv == "armas" else _itens_cache
	if origem.is_empty():
		var idx := _inv_list.add_item("(vazio)")
		_inv_list.set_item_selectable(idx, false)
	else:
		for linha in origem:
			_inv_list.add_item(str(linha))
