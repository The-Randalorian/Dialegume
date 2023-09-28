@tool
extends RichTextEffect
class_name RichTextImportant

# Syntax: [important type=KeyItem]Lightsaber[/important]

# Define the tag name.
var bbcode = "important"

func _process_custom_fx(char_fx):
	var colors = {
		"KeyItem": Color("#7CB9E8"),
		"Good": Color("#4DFF4D"),
		"Evil": Color("#FF4D4D"),
	}
	
	# Get parameters, or use the provided default value if missing.
	var color_name = char_fx.env.get("type", "KeyItem")
	
	char_fx.color = colors[color_name]
	return true
