@tool
extends RichTextEffect
class_name RichTextButton

# Syntax: [button action=quit]* quit button[/button]

# Define the tag name.
var bbcode = "button"

func _process_custom_fx(char_fx):
	var layouts = {
		"PC": {
			"quit": {
				"color": Color(0.8, 0.2, 0.2),
				"replace_char": "B"
			},
			"attack": {
				"color": Color(0.6, 0.8, 1.0),
				"replace_char": "X"
			},
			"interact": {
				"color": Color(0.2, 0.8, 0.2),
				"replace_char": "A"
			}
		}
	}
	
	# Get parameters, or use the provided default value if missing.
	var button_type = char_fx.env.get("action", "quit")
	var button_options = layouts["PC"].get(button_type, "quit")
	
	char_fx.color = button_options["color"]
	
	#print("gl_ind ", char_fx.glyph_index)
	if char_fx.glyph_index == get_glyph(char_fx, "@"):  # because apparently * is 11 not 42
		char_fx.glyph_index = get_glyph(char_fx, button_options["replace_char"])
	return true

func get_glyph(char_fx, character):
	#WTF is this? Godot Devs plz fix. This is OBNOXIOUS.
	return TextServerManager.get_primary_interface().font_get_glyph_index(char_fx.font, 10, character.unicode_at(0), 0)
