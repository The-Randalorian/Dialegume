@tool
extends EditorPlugin

var translation_parser
var syntax_highlighter

func _enter_tree():
	# Initialization of the plugin goes here.
	translation_parser = load("res://addons/dialegume/DialegumeXmlTranslationParser.gd").new()
	add_translation_parser_plugin(translation_parser)
	
	syntax_highlighter = load("res://addons/dialegume/DialegumeXmlSyntaxHighlighter.gd").new()
	syntax_highlighter.editor_settings = get_editor_interface().get_editor_settings()
	get_editor_interface().get_script_editor().register_syntax_highlighter(syntax_highlighter)


func _exit_tree():
	# Clean-up of the plugin goes here.
	
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(syntax_highlighter)
	
	remove_translation_parser_plugin(translation_parser)
