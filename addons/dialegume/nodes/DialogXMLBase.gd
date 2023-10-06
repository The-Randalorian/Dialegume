extends Control

class_name DialogXMLBase

var xml_parser: XMLParser
var tag_stack = []

var eager_tag_handlers = {
	"_": _null_handler
}
var lazy_tag_handlers = {
	"_": _null_handler
}
var empty_tag_handlers = {
	"_": _null_handler
}

const _PRINT_XML_HANDLER_STATEMENTS = false

var callback_override = null

func build_tag():
	var tag = {
		"_name": xml_parser.get_node_name(),
		"_offset": xml_parser.get_node_offset(),
		"_children": [],
		"_is_empty": xml_parser.is_empty(),
		"_stack": []
	}
	for i in range(xml_parser.get_attribute_count()):
		tag[xml_parser.get_attribute_name(i)] = xml_parser.get_attribute_value(i)
	return tag

var current_file = ""
var current_offset = 0

func load_xml(xml_file: String):
	current_file = xml_file
	current_offset = 0
	xml_parser = XMLParser.new()
	xml_parser.open(xml_file)
	tag_stack = []
	run_xml(true)

func load_xml_immediate(xml_string: String):
	current_file = ""
	current_offset = 0
	xml_parser = XMLParser.new()
	xml_parser.open_buffer(xml_string.to_utf8_buffer())
	tag_stack = []
	run_xml(true)

func rebuild_xml(tag: Dictionary):
	var attr = ""
	for attribute in tag.keys():
		if attribute[0] == "_":
			continue
		attr += " " + attribute + "=\"" + tag[attribute] + "\""
		
	var str = "<" + tag["_name"] + attr
	if tag["_is_empty"]:
		return str + "/>"
	str += ">"
	for item in tag["_stack"]:
		if item is String:
			str += item
		elif item is Dictionary:
			str += rebuild_xml(item)
	str += "</" + tag["_name"] + ">"
	return str
	
	

func run_xml(force_read = false):
	if len(tag_stack) <= 0 and not force_read:
		return  # stop immediately if there are no more tags in the tag stack
	xml_parser.read()
	match xml_parser.get_node_type():
		XMLParser.NODE_ELEMENT:
			current_offset = xml_parser.get_node_offset()
			if xml_parser.is_empty():
				var tag = build_tag()
				tag_stack.back()["_children"].append(tag)
				tag_stack.back()["_stack"].append(tag)
				if callback_override:
					callback_override.call(tag)
				else:
					empty_tag_handlers.get(tag["_name"], empty_tag_handlers["_"]).call(tag)
			else:
				var tag = build_tag()
				tag_stack.append(tag)
				if callback_override:
					callback_override.call(tag)
				else:
					eager_tag_handlers.get(tag["_name"], eager_tag_handlers["_"]).call(tag)
		XMLParser.NODE_ELEMENT_END:
			var tag = tag_stack.pop_back()
			if len(tag_stack) > 0:
				tag_stack.back()["_children"].append(tag)
				tag_stack.back()["_stack"].append(tag)
			if callback_override:
				callback_override.call(tag)
			else:
				lazy_tag_handlers.get(tag["_name"], lazy_tag_handlers["_"]).call(tag)
		XMLParser.NODE_TEXT:
			var tag = tag_stack.back()
			tag["_data"] = xml_parser.get_node_data()
			tag["_stack"].append(xml_parser.get_node_data())
		_:
			pass # ignore all other node types
	return len(tag_stack) > 0

func _null_handler(_tag: Dictionary):
	#print("_null_handler: ", tag, ", Override Me!")
	pass
