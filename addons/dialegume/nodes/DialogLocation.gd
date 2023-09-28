extends Control
class_name DialogLocation

@export var side = "left"
@export var priority = 0
@export var layout_to = "right"
@export var type = "character"
@export var facing = Vector2(1.0, 1.0)
@export_node_path var dialog_box_path: NodePath

@onready var dialog_box = get_node_or_null(dialog_box_path)

func _ready():
	dialog_box.add_dialog_location(self)
