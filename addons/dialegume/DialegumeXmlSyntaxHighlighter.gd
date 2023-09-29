@tool
extends EditorSyntaxHighlighter

func _get_name():
	return "Dialegume XML Syntax Highlighter"

func _get_supported_languages():
	PackedStringArray([
		"Dialegume Dialog XML",
		"Dialegume Character XML",
		"Dialegume Item XML"
	])

static var editor_settings: EditorSettings

var _styles = {}

func setup_styles():
	_styles = {
		"": {"color": Color(1, 1, 1)},
		"tag": {"color": editor_settings.get_setting("text_editor/theme/highlighting/keyword_color")},
		"tag.quote": {"color": editor_settings.get_setting("text_editor/theme/highlighting/string_color")},
		"tag.attr": {"color": editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")},
	}
	update_cache()

func _get_line_syntax_highlighting(line_number: int):
	var line = get_text_edit().get_line(line_number)
	if len(_styles) < 4:
		editor_settings.settings_changed.connect(setup_styles)
		setup_styles()
	var highlights = {}
	var in_tag = false
	var in_quote = false
	for char_num in range(len(line)):
		var character = line[char_num]
		if in_tag:
			if character == ">":
				highlights[char_num] = _styles["tag"]
				highlights[char_num + 1] = _styles[""]
				in_tag = false
				in_quote = false
			elif character == "\"":
				if in_quote:
					highlights[char_num + 1] = _styles["tag"]
				else:
					highlights[char_num] = _styles["tag.quote"]
				in_quote = not in_quote
			elif character == " ":
				highlights[char_num] = _styles["tag.attr"]
			elif character == "/" and not in_quote:
				highlights[char_num] = _styles["tag"]
		else:
			if character == "<":
				highlights[char_num] = _styles["tag"]
				in_tag = true
				in_quote = false
	return highlights
