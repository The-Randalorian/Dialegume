extends DialogXMLBase
class_name DialogItem

@export var item_file = ""
@export var item_string = ""
#var talking_color = Color(1.0, 1.0, 1.0)
#var listening_color = Color(0.5, 0.5, 0.5)
var title = ""

var texture_rect

func _ready():
	get_tree().get_root().connect('size_changed', _on_viewport_resized)
	eager_tag_handlers = {
		"item": _item_handler,
		"_": _null_handler
	}
	lazy_tag_handlers = {
		"_": _null_handler
	}
	empty_tag_handlers = {
		"state": _state_handler,
		"_": _null_handler
	}
	#get_tree().get_root().connect('size_changed', _on_viewport_resized)
	texture_rect = TextureRect.new()
	texture_rect.set_meta("alt", "")
	#texture_rect.layout_mode = LayoutMode.LAYOUT_MODE_ANCHORS
	#texture_rect.anchor_bottom = 0.0
	#texture_rect.anchor_left = 0.0
	#texture_rect.anchor_top = 1.0
	#texture_rect.anchor_right = 1.0
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(texture_rect)
	
	if len(item_file) > 0:
		load_xml(item_file)
	else:
		load_xml_immediate(item_string)
	while run_xml():
		pass#print("running character xml...")
	rescale()
	redraw(0.0)

func _item_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_item_handler: ", tag)
	title = tag.get("title", "Unnamed Item")

func _state_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_item_handler: ", tag)
	texture_rect.texture = load(tag["image"])
	texture_rect.scale = float(tag.get("scale", "1.0")) * Vector2(1.0, 1.0)
	texture_rect.set_meta("alt", tag.get("alt", ""))

var tween: Tween

func redraw(time = 0.5):
	#print("tween time ", time)
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.parallel().tween_property(self, "position", tracker.position, time).set_trans(Tween.TRANS_SINE)
	
	facing = tracker.facing
	var new_offset = texture_rect.texture.get_size() * texture_rect.scale * Vector2(0, -1.0) * facing
	new_offset += texture_rect.texture.get_size() * texture_rect.scale * Vector2(1.0, 0.0) * (facing / 2 + Vector2(-0.5, 0.0))
	

	tween.parallel().tween_property(texture_rect, "position", new_offset, time).set_trans(Tween.TRANS_SINE)
	
	tween.parallel().tween_property(texture_rect, "modulate", Color(texture_rect.modulate, 1.0), 0.25)
	
	z_index = tracker.priority + 30
	#texture_rect.flip_h = facing.x < 0

var facing = Vector2(1.0, 1.0)
var tracker: DialogLocation

func goto(location: DialogLocation, time = 0.5):
	#print(self, " moving from ", tracker, " to ", location, " in ", time)
	tracker = location
	if texture_rect:
		redraw(time)

func rescale():
	scale = (get_viewport_rect().size.y / ProjectSettings.get_setting("display/window/size/viewport_height", 720)) * Vector2(1.0, 1.0)

func _on_viewport_resized():
	if tracker:
		position = tracker.position
		facing = tracker.facing
		rescale()
	#else:
		#print('not tracking')

#var talking_tween: Tween

#func talk():
#	if talking_tween:
#		talking_tween.kill()
#	talking_tween = get_tree().create_tween()
#	talking_tween.tween_property(texture_rect, "modulate", talking_color, 0.25)
#	z_index = tracker.priority + 10
#
#func listen():
#	if talking_tween:
#		talking_tween.kill()
#	talking_tween = get_tree().create_tween()
#	talking_tween.tween_property(texture_rect, "modulate", listening_color, 0.25)
#	z_index = tracker.priority

func exit():
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(texture_rect, "modulate", Color(texture_rect.modulate, 0.0), 0.25)
	tween.tween_callback(queue_free)
