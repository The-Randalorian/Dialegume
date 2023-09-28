extends Control

func _input(event):
	if event.is_action_pressed("dialog_continue"):
		$DialogBox.continue_dialog()
