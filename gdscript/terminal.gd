extends CanvasLayer

const MAX_LINES := 20

var _lines : Array = []
var _label : RichTextLabel
var _status_label : RichTextLabel


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	_build_status_panel()
	_build_binds_panel()

	var panel := Panel.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -410
	panel.offset_top    = -320
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


# Painel de status do jogador, no topo da pilha (acima dos controles).
# O texto é preenchido pelo coldCuts.gd via set_status().
func _build_status_panel() -> void:
	var panel := Panel.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -410
	panel.offset_top    = -566
	panel.offset_right  = -10
	panel.offset_bottom = -410

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.04, 0.88)
	style.border_color = Color(0.15, 0.75, 0.15, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var header := Label.new()
	header.text = ">> status"
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

	_status_label = RichTextLabel.new()
	_status_label.anchor_right  = 1.0
	_status_label.anchor_bottom = 1.0
	_status_label.offset_top    = 26
	_status_label.offset_left   = 8
	_status_label.offset_right  = -4
	_status_label.offset_bottom = -6
	_status_label.scroll_active  = false
	_status_label.bbcode_enabled = true
	_status_label.add_theme_color_override("default_color", Color(0.15, 0.9, 0.15))
	_status_label.add_theme_font_size_override("normal_font_size", 11)
	_status_label.text = "Sem personagem."
	panel.add_child(_status_label)


# Atualiza o conteúdo do painel de status. Recebe o texto já formatado
# (bbcode permitido) do coldCuts.gd, que é o dono dos dados do jogador.
func set_status(texto: String) -> void:
	if _status_label:
		_status_label.text = texto


# Painel de binds logo acima do terminal, espelhando a linha de controles do coldCuts.py.
func _build_binds_panel() -> void:
	var panel := Panel.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -410
	panel.offset_top    = -406
	panel.offset_right  = -10
	panel.offset_bottom = -326

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
	binds.position = Vector2(8, 24)
	binds.text = "Mover: setas / W S D / numpad    Diagonais: Q E Z C\nAtacar: A + direção    Inventário: I    Usar item: U    Trocar arma: T\nDicionário: G    Portal: P    Falar: F"
	binds.add_theme_color_override("font_color", Color(0.15, 0.9, 0.15))
	binds.add_theme_font_size_override("font_size", 11)
	panel.add_child(binds)


func add_line(text: String) -> void:
	_lines.append(text)
	if _lines.size() > MAX_LINES:
		_lines = _lines.slice(_lines.size() - MAX_LINES)
	_label.text = "\n".join(_lines)
