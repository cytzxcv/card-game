class_name Card
extends Area2D

signal left_hand
signal back_hand
signal is_played

const FLY_HEIGHT: float = 400
const FREE_SPEED: float = 8
const DRAG_SPEED: float = 20
const PLAYED_HEIGHT: float = 700

var info: CardInfo
var hand_position: int
var default_position: Vector2
var target_position: Vector2

var free_move: bool = true
var being_dragged: bool = false
var will_be_played: bool = false
var have_been_played: bool = false

func _ready() -> void:
	target_position = default_position

func _process(_delta: float) -> void:
	_move()
	_check_dragging()
	_check_played()
	$CardName.text = info.name
	z_index = 10 if being_dragged else hand_position

func _check_dragging() -> void:
	if not being_dragged or have_been_played:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		target_position = get_global_mouse_position()
	elif will_be_played:
		have_been_played = true
		is_played.emit()
	else:
		being_dragged = false
		target_position = default_position
		back_hand.emit()

func _move() -> void:
	if not free_move or have_been_played:
		return

	var current_speed: float = DRAG_SPEED if being_dragged else FREE_SPEED
	position = position.lerp(target_position, 1.0 - exp(-current_speed * get_process_delta_time()))

	if target_position.distance_squared_to(position) <= 0.01:
		position = target_position

func _check_played():
	if have_been_played:
		return

	will_be_played = position.y < PLAYED_HEIGHT
	$Outline.visible = position.y < PLAYED_HEIGHT

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not have_been_played and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		being_dragged = true
		left_hand.emit()
