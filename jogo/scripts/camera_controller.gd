extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.5
@export var pan_speed: float = 800.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_IN:
				zoom = clamp(zoom + Vector2(zoom_speed, zoom_speed), Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
			elif event.button_index == MOUSE_BUTTON_WHEEL_OUT:
				zoom = clamp(zoom - Vector2(zoom_speed, zoom_speed), Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("w"):
		input_dir.y -= 1
	
	if input_dir != Vector2.ZERO:
		position += input_dir.normalized() * pan_speed * delta / zoom.x
