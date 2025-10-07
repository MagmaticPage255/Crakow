extends Control

@onready var animation_player = $AnimationPlayer

func _ready():
	if is_instance_valid(animation_player):
		animation_player.play("RESET")
	else:
		push_warning("AnimationPlayer node not found in pause menu scene.")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func resume():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if is_instance_valid(animation_player):
		animation_player.play("RESET")
	else:
		push_warning("AnimationPlayer node not found during resume.")
	hide()

func pause():
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(animation_player):
		animation_player.play("blur")
	else:
		push_warning("AnimationPlayer node not found during pause.")
	show()

func testEsc():
	if Input.is_action_just_released("escape"):
		if not get_tree().paused:
			pause()
		else:
			resume()

func _on_resume_pressed() -> void:
	resume()

func _on_options_pressed() -> void:
	print("Attempting to load options menu")
	$Options.show()
	%PauseMenu.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _process(delta):
	testEsc()
