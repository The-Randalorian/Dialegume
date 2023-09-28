extends DialogXMLBase
class_name DialogCharacter

@export var character_file = ""
var talking_color = Color(1.0, 1.0, 1.0)
var listening_color = Color(0.5, 0.5, 0.5)
var title = ""

var textures = {}

var texture_rect
var inverted = false

func _ready():
	get_tree().get_root().connect('size_changed', _on_viewport_resized)
	eager_tag_handlers = {
		"character": _character_handler,
		"_": _null_handler
	}
	lazy_tag_handlers = {
		"_": _null_handler
	}
	empty_tag_handlers = {
		"emotion": _emotion_handler,
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
	texture_rect.modulate = Color(listening_color, 0.0)
	add_child(texture_rect)
	
	load_xml(character_file)
	while run_xml():
		pass#print("running character xml...")
	set_emotion("default")
	rescale()
	redraw(0.0)
	listen()

func _character_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_character_handler: ", tag)
	title = tag.get("title", "Unnamed Character")

func _emotion_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_emotion_handler: ", tag)
	var tex = load(tag["image"])
	textures[tag.get("name", "UnnamedEmotion")] = {
		"texture": tex,
		"scale": float(tag.get("scale", "1.0")) * Vector2(1.0, 1.0),
		"alt": tag.get("alt", "")
		}

func set_emotion(texture_name: String):
	var texture_data = textures.get(texture_name, textures.get("default", textures.keys()[0]))
	texture_rect.texture = texture_data["texture"]
	texture_rect.scale = texture_data["scale"]
	texture_rect.size = texture_data["texture"].get_size()
	texture_rect.set_meta("alt", texture_data["alt"])
	redraw(0.0)
	#rescale()
	#redraw()

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
	
	
	texture_rect.flip_h = (facing.x < 0) != inverted

var facing = Vector2(1.0, 1.0)
var tracker: DialogLocation

func goto(location: DialogLocation, inv: bool, time = 0.5):
	#print(self, " moving from ", tracker, " to ", location, " in ", time)
	set_inverted(inv)
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

func set_inverted(inv: bool):
	inverted = inv
	if tracker: texture_rect.flip_h = (tracker.facing.x < 0) != inverted

var talking_tween: Tween

func talk(emotion = null):
	if emotion:
		set_emotion(emotion)
	if talking_tween:
		talking_tween.kill()
	talking_tween = get_tree().create_tween()
	talking_tween.tween_property(texture_rect, "modulate", talking_color, 0.25)
	z_index = tracker.priority + 10

func listen():
	if talking_tween:
		talking_tween.kill()
	talking_tween = get_tree().create_tween()
	talking_tween.tween_property(texture_rect, "modulate", listening_color, 0.25)
	z_index = tracker.priority

func exit():
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(texture_rect, "modulate", Color(texture_rect.modulate, 0.0), 0.25)
	tween.tween_callback(queue_free)
