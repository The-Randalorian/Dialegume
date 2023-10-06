extends DialogXMLBase
class_name DialogBox

var pause_reading = false
var waiting = false
@export var max_lines = 2
@export var character_delay = 0.03
@export var character_count = 1
@export var read_delay = 1.0
@export var line_delay = 1.0
@export var delay_time = 1.0
var current_line = 0
var rate = 1.0

signal entered_dialog
signal exited_dialog
signal awaiting_input
signal running_dialog
@export_node_path var text_box_path: NodePath
@export_node_path var decision_box_path: NodePath
@export_node_path var character_area_path: NodePath
@export_node_path var blinker_path: NodePath
@export_node_path var nametag_path: NodePath

@onready var text_box = get_node_or_null(text_box_path)
@onready var decision_box = get_node_or_null(decision_box_path)
@onready var character_area = get_node_or_null(character_area_path)
@onready var blinker = get_node_or_null(blinker_path)
@onready var nametag = get_node_or_null(nametag_path)

var TextTimer: Timer
var ResizeTimer: Timer
var DelayTimer: Timer

var locations = {
	"character": {
		"left": [],
		"center": [],
		"right": [],
	},
	"item": {
		"left": [],
		"center": [],
		"right": [],
	},	
}

var characters = {}
var items = {}

signal dialog_trigger(event_name: String, target: String)
	
func _conversation_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_conversation_handler: ", tag)
	
func _enter_empty_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_enter_empty_handler: ", tag)
	var chr_data = tag.get("chr_data", null)
	if chr_data:
		var new_char = DialogCharacter.new()
		#print(locations)
		new_char.character_file = tag["chr_data"]
		var location_side = locations["character"][tag.get("side", "right")]
		var priority = min(int(tag.get("priority", "0")), len(location_side)-1)
		new_char.goto(location_side[priority], new_char.inverted, 0.0)
		add_child(new_char)
		characters[tag.get("chr_id", "UnnamedCharacter")] = new_char
	var itm_data = tag.get("itm_data", null)
	if itm_data:
		var new_item = DialogItem.new()
		#print(locations)
		new_item.item_file = tag["itm_data"]
		var location_side = locations["item"][tag.get("side", "right")]
		var priority = min(int(tag.get("priority", "0")), len(location_side)-1)
		new_item.goto(location_side[priority], 0.0)
		add_child(new_item)
		items[tag.get("itm_id", "UnnamedItem")] = new_item

func _enter_lazy_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_enter_lazy_handler: ", tag)
	for child in tag["_children"]:
		var xml_string = rebuild_xml(child)
		if child["_name"].to_lower() == "character":
			var new_char = DialogCharacter.new()
			#print(locations)
			new_char.character_string = xml_string
			var location_side = locations["character"][tag.get("side", "right")]
			var priority = min(int(tag.get("priority", "0")), len(location_side)-1)
			new_char.goto(location_side[priority], new_char.inverted, 0.0)
			add_child(new_char)
			characters[tag.get("chr_id", "UnnamedCharacter")] = new_char
		var itm_data = tag.get("itm_data", null)
		if child["_name"].to_lower() == "item":
			var new_item = DialogItem.new()
			#print(locations)
			new_item.item_file = xml_string
			var location_side = locations["item"][tag.get("side", "right")]
			var priority = min(int(tag.get("priority", "0")), len(location_side)-1)
			new_item.goto(location_side[priority], 0.0)
			add_child(new_item)
			items[tag.get("itm_id", "UnnamedItem")] = new_item

func _move_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_move_handler: ", tag)
	var chr = tag.get("chr_id", null)
	if chr:
		var charac = characters.get(chr, null)
		if charac:
			var location_side = locations["character"][tag.get("side", "right")]
			var priority = min(int(tag.get("priority", "0")), len(location_side)-1)
			var inv_str = tag.get("inverted", str(charac.inverted))
			var inv = (inv_str.to_lower().begins_with("t") or inv_str.to_lower().begins_with("y"))
			charac.goto(location_side[priority], inv)
	var itm = tag.get("itm_id", null)
	if itm:
		var item = items.get(itm, null)
		if item:
			var location_side = locations["item"][tag.get("side", "right")]
			var priority = min(int(tag.get("priority", "0")), len(location_side)-1)
			item.goto(location_side[priority])

func _exit_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_exit_handler: ", tag)
	var chr = tag.get("chr_id", null)
	if chr:
		var charac = characters.get(chr, null)
		if charac:
			charac.exit()
			characters.erase(chr)
	var itm = tag.get("itm_id", null)
	if itm:
		var item = items.get(itm, null)
		if item:
			item.exit()
			items.erase(itm)

func _block_skip_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_block_skip_handler: ", tag)
	block_skip = true

func _allow_skip_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_allow_skip_handler: ", tag)
	block_skip = false

func _delay_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_delay_handler: ", tag)
	pause_reading = true
	DelayTimer.start(float(tag.get("time", str(delay_time))))

func _activate_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_delay_handler: ", tag)
	var branch = tag.get("branch", "_")
	branch_overrides[branch] = true

func _deactivate_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_delay_handler: ", tag)
	var branch = tag.get("branch", "_")
	branch_overrides[branch] = false

func _skip_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_allow_skip_handler: ", tag)
	var bs = tag.get("block", null)
	if bs == null:
		bs = tag.get("allow", "false")
		block_skip = not (bs.to_lower().begins_with("t") or bs.to_lower().begins_with("y"))
	else:
		block_skip = bs.to_lower().begins_with("t") or bs.to_lower().begins_with("y")

func _text_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_text_handler: ", tag)
	var ht = tag.get("hide", null)
	var show_text = false
	if ht == null:
		ht = tag.get("show", "true")
		show_text = (ht.to_lower().begins_with("t") or ht.to_lower().begins_with("y"))
	else:
		show_text = not ht.to_lower().begins_with("t") or ht.to_lower().begins_with("y")
	nametag.visible = show_text
	_nv = show_text
	if not show_text:
		text_box.visible_characters = 0

func _line_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_line_handler: ", tag)
	if text_box: 
		text_box.clear()
		text_box.visible_characters = 0
	current_line = 0
	pause_reading = true
	var untranslated_text = tag["_data"]
	if text_box: text_box.append_text(tr(untranslated_text))
	var chr_id = tag.get("chr_id", null)
	var emotion = tag.get("emotion", null)
	if chr_id:
		nametag.visible = true
		_nv = true
		for character in characters.keys():
			if character == chr_id:
				var char = characters[character]
				char.talk(emotion)
				var inv = tag.get("inverted", str(char.inverted))
				char.set_inverted(inv.to_lower().begins_with("t") or inv.to_lower().begins_with("y"))
				nametag.text = tr(char.title)
				nametag.size = Vector2(0, 0)
			else:
				characters[character].listen()
	else:
		nametag.visible = false
		_nv = false
	var bs = "false"
	if block_skip:
		bs = tag.get("block_skip", "true")
	else:
		bs = tag.get("block_skip", "false")
	block_skip = bs.to_lower().begins_with("t") or bs.to_lower().begins_with("y")
	rate = float(tag.get("rate", tag.get("speed", "1.0")))
	next_character()

var current_decision = {}

func _decision_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_decision_handler: ", tag)
	decision_box.clear()
	var counter = 0
	var default = -1
	for branch in tag["_children"]:
		#print(branch)
		decision_box.add_item(branch["title"])
		if branch["_active_bool"]:
			if branch.get("default", false):
				decision_box.select(counter)
				default = counter 
		else:
			decision_box.set_item_disabled(counter, true)
			decision_box.set_item_selectable(counter, false)
		counter += 1
	current_decision = tag
	decision_box.visible = true
	waiting = true
	decision_box.grab_focus()
	decision_box.call_deferred("grab_focus")
	decision_box.grab_click_focus()
	decision_box.call_deferred("grab_click_focus")
	if default >= 0:
		decision_box.select(default)
	decision_box.ensure_current_is_visible()
	for character in characters.keys():
		characters[character].listen()
	pause_reading = true

var branch_overrides = {}

func _branch_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_branch_handler: ", tag)
	xml_parser.read()
	tag["_sequence_start"] = xml_parser.get_node_offset()
	tag["default"] = tag.get("default", "false")
	tag["default"] = tag["default"].to_lower() == "true"
	var inactive_str = tag.get("inactive", null)
	if inactive_str:
		tag["_active_bool"] = not (inactive_str.to_lower().begins_with("t") or inactive_str.to_lower().begins_with("y"))
	else:
		var active_str = tag.get("active", "true")
		tag["_active_bool"] = active_str.to_lower().begins_with("t") or active_str.to_lower().begins_with("y")
	var id = tag.get("id", null)
	if id:
		tag["_active_bool"] = branch_overrides.get(id, tag["_active_bool"])
	xml_parser.seek(tag["_offset"])
	tag_stack.pop_back()
	tag_stack.back()["_children"].append(tag)
	xml_parser.skip_section()

var jump_point = ""
var prev_node = 0

func _jump_seek_override(tag: Dictionary):
	if tag.get("id", "") == jump_point:
		#print("jump seek found ", tag["_name"], " with id ", tag.get("id", "[none]"))
		jump_point = ""
		#xml_parser.seek(tag["_offset"])
	else:
		#print("jump seek skipping ", tag["_name"], " with id ", tag.get("id", "[none]"))
		prev_node = xml_parser.get_node_offset()

func _jump_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_jump_handler: ", tag)
	
	# perform a search from front to back
	prev_node = 0
	jump_point = tag["point"]
	callback_override = _jump_seek_override
	load_xml(current_file)
	while len(jump_point) > 0:
		run_xml()
	
	# seek from front to back to the correct node, important to make sure the stack is correct
	callback_override = _null_handler
	load_xml(current_file)
	while xml_parser.get_node_offset() < prev_node:
		run_xml()
	
	prev_node = 0
	callback_override = null
	#run_to_pause()
	
func _conversation_done_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_dialog_done_handler: ", tag)
	visible = false
	for character in characters.values():
		character.exit()
	for item in items.values():
		item.exit()
	characters = {}
	items = {}
	branch_overrides = {}
	exited_dialog.emit()

func _trigger_handler(tag: Dictionary):
	if _PRINT_XML_HANDLER_STATEMENTS: print("_trigger_handler: ", tag)
	var event = tag.get("event", null)
	var target = tag.get("target", "all")
	if event:
		dialog_trigger.emit(event, target)

func _ready():
	TextTimer = Timer.new()
	TextTimer.one_shot = true
	TextTimer.timeout.connect(_on_text_timer_timeout)
	add_child(TextTimer)
	ResizeTimer = Timer.new()
	ResizeTimer.one_shot = true
	ResizeTimer.timeout.connect(_on_resize_timer_timeout)
	add_child(ResizeTimer)
	DelayTimer = Timer.new()
	DelayTimer.one_shot = true
	DelayTimer.timeout.connect(_on_delay_timer_timeout)
	add_child(DelayTimer)
	eager_tag_handlers = {
		"dialog": _conversation_handler,
		"conversation": _conversation_handler,
		"converse": _conversation_handler,
		"branch": _branch_handler,
		"_": _null_handler
	}
	lazy_tag_handlers = {
		"line": _line_handler,
		"narration": _line_handler,
		"decision": _decision_handler,
		"dialog": _conversation_done_handler,
		"conversation": _conversation_done_handler,
		"converse": _conversation_done_handler,
		"enter": _enter_lazy_handler,
		"_": _null_handler
	}
	empty_tag_handlers = {
		"jump": _jump_handler,
		"enter": _enter_empty_handler,
		"exit": _exit_handler,
		"move": _move_handler,
		"trigger": _trigger_handler,
		"skip": _skip_handler,
		"allow_skip": _allow_skip_handler,
		"block_skip": _block_skip_handler,
		"delay": _delay_handler,
		"text": _text_handler,
		"activate": _activate_handler,
		"deactivate": _deactivate_handler,
		"_": _null_handler
	}
	get_tree().get_root().connect('size_changed', _on_viewport_resized)
	visible = false

var _nv = false

func resize():
	if not text_box: return
	var s = text_box.get_size()
	queue_resize = s.y <= 1 or s.x <= 1
	
	if queue_resize:
		#print("queueing another resize, as the size was too small (due to sizes updating.) Size was ", s)
		return
	var max_font_size = round(s.y * 2)
	var min_font_size = 5
	var font = text_box.get_theme_font("normal_font")
	
	var test_text = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for i in range(1, max_lines):
		test_text += "\nABCDEFGHIJKLMNOPQRSTUVWXYZ"
		
	while min_font_size < max_font_size:
		var test_font_size = round((max_font_size + min_font_size) / 2.0)
		var render_size = font.get_multiline_string_size(
			test_text, 
			0,
			-1, 
			test_font_size)
		#print(min_font_size, ", ", test_font_size, ", ", max_font_size, ", ", render_size, ", ", s.y)
		if render_size.y >= s.y:
			max_font_size = test_font_size - 1
		else:
			min_font_size = test_font_size + 1
	
	text_box.add_theme_font_size_override("normal_font_size", max_font_size)
	decision_box.add_theme_font_size_override("font_size", max_font_size / 2)
	blinker.custom_minimum_size = Vector2(max_font_size, max_font_size)
	
	nametag.reset_size()
	nametag.label_settings.font_size = max_font_size / 2
	nametag.offset_top = max_font_size / -2
	nametag.reset_size()
	nametag.visible = _nv
	#text_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func load_dialog(dialog_file: String):
	visible = true
	
	load_xml(dialog_file)
	
	queue_resize = true
	
	run_to_pause()
	
	entered_dialog.emit()

func _process(_delta):
	if queue_resize:
		resize()

func reload_line():
	#var co = current_offset
	#if len(current_file) <= 0:
		#return
	#load_xml(current_file)
	#xml_parser.seek(co)
	
	resize()
	if text_box: 
		if text_box.visible_characters < text_box.get_total_character_count():
			text_box.visible_characters = 0
			current_line = 0
			next_character()
		nametag.reset_size()
	#run_to_pause()
	
func run_to_pause():
	if not visible:
		return
	while not pause_reading:
		if not visible:
			return
		if not run_xml():
			#print("rtp: ", pause_reading)
			#print("finished dialog!")
			break
		#print("rtp: ", pause_reading)
	#print("reading stopped or paused")
	pause_reading = false

func next_character(count = 0):
	nametag.size = Vector2(0, 0)
	if text_box:
		if text_box.visible_characters >= text_box.get_total_character_count():
			run_to_pause()
			return
		text_box.visible_characters += 1
		if text_box.visible_characters >= text_box.get_total_character_count():
			blink_wait()
			#TextTimer.start(line_delay)  # eventually the timer will not run, instead wait for input
		else:
			#print("--->",text_box.visible_characters, ", ", text_box.get_character_line(text_box.visible_characters), ", ", current_line)
			if text_box.get_parsed_text()[text_box.visible_characters] == " ":
				var save = text_box.visible_characters
				var c = text_box.visible_characters + 1
				var keep_testing = true
				while c < text_box.get_total_character_count():
					text_box.visible_characters = c
					#print("testing character ", c, ": ", text_box.get_parsed_text()[c], ", ", text_box.get_character_line(c-1), ", ", current_line + max_lines - 1)
					if text_box.get_parsed_text()[c] == " ":
						# we reached the end of the word, stop testing and allow it to display.
						#print("end of word")
						if text_box.get_character_line(c-1) > current_line + max_lines - 1:
							# we also reached the end of the line. back up and wait.
							text_box.visible_characters = save
							current_line += max_lines
							blink_wait()
							#print("also end of line")
							return
						break  
					if text_box.get_character_line(c-1) > current_line + max_lines - 1:
						# we reached the end of the line. back up and wait.
						text_box.visible_characters = save
						current_line += max_lines
						blink_wait()
						#print("end of line")
						return
					# this character didn't end the word or line, keep going.
					c += 1
				
				text_box.visible_characters = save
			
			if text_box.get_character_line(text_box.visible_characters-1) <= current_line + max_lines - 1:
				count += 1
				if count < character_count:
					next_character(count)
				else:
					TextTimer.start(character_delay / rate)
			else:
				text_box.visible_characters -= 1
				current_line += max_lines
				blink_wait()
				#TextTimer.start(read_delay)

var queue_resize = false
var block_skip = false

func _on_viewport_resized():
	TextTimer.stop()
	ResizeTimer.start()
	if text_box: 
		if text_box.visible_characters < text_box.get_total_character_count():
			text_box.visible_characters = 0
			current_line = 0
		nametag.label_settings.font_size = 1
		nametag.reset_size()
		nametag.visible = false

func _on_resize_timer_timeout():
	reload_line()

func _on_text_timer_timeout():
	#print("text timer")
	next_character()
	nametag.size = Vector2(0, 0)

func _on_delay_timer_timeout():
	run_to_pause()

var waiting_for_input = false

func continue_dialog():
	if not visible:
		return
	if waiting:
		decision_box.grab_focus()
		decision_box.ensure_current_is_visible()
		return
	if waiting_for_input:
		next_character()
		blink_stop()
	elif not block_skip:
		while not waiting_for_input:
			#print(text_box.visible_characters, ", ", text_box.get_character_line(text_box.visible_characters), ", ", current_line)
			#print(text_box.get_parsed_text().left(text_box.visible_characters), waiting_for_input)
			next_character()
		TextTimer.stop()
		#print("stop")

func blink_wait():
	waiting_for_input = true
	awaiting_input.emit()

func blink_stop():
	waiting_for_input = false
	running_dialog.emit()

func _on_item_list_item_activated(index):
	if not decision_box.is_item_selectable(index):
		print_debug("Item " + str(index) + " not available.")
		return
	#print("Action Triggered: ", index)
	xml_parser.seek(current_decision["_children"][index]["_sequence_start"])
	decision_box.visible = false
	waiting = false
	run_to_pause()


func _on_item_list_item_clicked(index, _at_position, _mouse_button_index):
	if not decision_box.is_item_selectable(index):
		print_debug("Item " + str(index) + " not available.")
		return
	#print("Action Triggered: ", index)
	xml_parser.seek(current_decision["_children"][index]["_sequence_start"])
	decision_box.visible = false
	waiting = false
	run_to_pause()

func add_dialog_location(location: DialogLocation):
	var order = min(location.priority, len(locations[location.type][location.side]))
	locations[location.type][location.side].insert(order, location)
