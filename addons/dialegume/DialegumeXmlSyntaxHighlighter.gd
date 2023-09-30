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
		"tag": {"color": editor_settings.get_setting("text_editor/theme/highlighting/base_type_color")},
		"tag.quote": {"color": editor_settings.get_setting("text_editor/theme/highlighting/string_color")},
		"tag.attr": {"color": editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")},
		"error": {"color": editor_settings.get_setting("text_editor/theme/highlighting/brace_mismatch_color")},
		"tag.comment": {"color": editor_settings.get_setting("text_editor/theme/highlighting/comment_color")},
	}
	update_cache()

func _get_line_syntax_highlighting(line_number: int):
	var line = get_text_edit().get_line(line_number)
	if len(_styles) < 6:
		if not editor_settings.settings_changed.is_connected(setup_styles):
			editor_settings.settings_changed.connect(setup_styles)
		setup_styles()
	var highlights = {}
	var in_comment = false
	var in_tag = false
	var in_quote = false
	for char_num in range(len(line)):
		var character = line[char_num]
		if in_comment:
			if line.substr(char_num, 3) == "-->":
				highlights[char_num + 3] = _styles[""]
				in_tag = false
				in_quote = false
				in_comment = false
		elif in_tag:
			if character == ">":
				if in_quote:
					if line[max(char_num - 1, 0)] == "/":
						highlights[char_num - 1] = _styles["error"]
					else:
						highlights[char_num] = _styles["error"]
				else:
					highlights[char_num] = _styles["tag"]
					highlights[char_num + 1] = _styles[""]
				in_tag = false
				in_quote = false
				in_comment = false
			elif character == "\"":
				if in_quote:
					highlights[char_num + 1] = _styles["tag"]
				else:
					highlights[char_num] = _styles["tag.quote"]
				in_quote = not in_quote
			elif character == " ":
				if in_quote:
					pass
				else:
					highlights[char_num] = _styles["tag.attr"]
			elif character == "/" and not in_quote:
				highlights[char_num] = _styles["tag"]
		else:
			if character == "<":
				if line.substr(char_num, 4) == "<!--":
					in_comment = true
					in_tag = false
					in_quote = false
					highlights[char_num] = _styles["tag.comment"]
					continue
				highlights[char_num] = _styles["tag"]
				in_tag = true
				in_quote = false
	return highlights
