extends CanvasLayer

const MAX_LINES := 20

var _lines : Array = []
var _label : RichTextLabel


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var panel := Panel.new()
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -410
	panel.offset_top    = -270
	panel.offset_right  = -10
	panel.offset_bottom = -10

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


func add_line(text: String) -> void:
	_lines.append(text)
	if _lines.size() > MAX_LINES:
		_lines = _lines.slice(_lines.size() - MAX_LINES)
	_label.text = "\n".join(_lines)
