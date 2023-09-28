@tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	var translation_parser = load("res://addons/dialegume/DialegumeXmlTranslationParser.gd").new()
	add_translation_parser_plugin(translation_parser)


func _exit_tree():
	# Clean-up of the plugin goes here.
	pass
