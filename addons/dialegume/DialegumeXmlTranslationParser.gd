@tool
extends EditorTranslationParserPlugin

var mappings = {
	"emotion": ["alt"],
	"character": ["title"],
	"state": ["alt"],
	"item": ["title"],
}

const USE_EXTRA_CONTEXT = true

func _parse_file(path, msgids, msgids_context_plural):
	var xml_parser = XMLParser.new()
	xml_parser.open(path)
	while xml_parser.read() == OK:
		var context = path + ":" + str(xml_parser.get_current_line())
		match xml_parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var type = xml_parser.get_node_name()
				print("element: ", type)
				var attributes = mappings.get(type, [])
				print("attributes: ", attributes)
				for attribute in attributes:
					var attr_val = xml_parser.get_named_attribute_value_safe(attribute)
					if len(attr_val) <= 0:
						continue
					print("Adding: ", attr_val)
					if USE_EXTRA_CONTEXT:
						msgids_context_plural.append([attr_val, context, ""])
					else:
						msgids.append(attr_val)
			XMLParser.NODE_TEXT:
				var text = xml_parser.get_node_data().strip_edges()
				if len(text) <= 0:
					continue
				print("text: ", text, len(text))
				print("Adding: ", text)
				if USE_EXTRA_CONTEXT:
					msgids_context_plural.append([text, context, ""])
				else:
					msgids.append(text)
	

func _get_recognized_extensions():
	return ["dlml", "dxml", "cxml", "ixml", "tldr-dxml", "tldr-cxml", "tldr-ixml"]
