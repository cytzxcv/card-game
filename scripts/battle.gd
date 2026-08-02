extends Node2D

const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")

const DRAW_POSITION: Vector2 = Vector2(100, 950)
const DISCARD_POSITION: Vector2 = Vector2(1820, 950)

const HAND_MIDDLE: Vector2 = Vector2(960, 950)

var deck: Array[String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m"]
var draw_pile: Array[String] = []
var discard_pile: Array[String] = []

var card_distance: float = 200
var card_children: Array[Card] = []
var card_amount: int:
	get:
		return card_children.size()

func _ready() -> void:
	randomize()
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	for i in range(5):
		_draw_card()
		await get_tree().create_timer(0.1).timeout

func _draw_card() -> void:
	if card_amount >= 10 or (draw_pile.size() == 0 and discard_pile.size() == 0):
		return

	var card: Card = CARD_SCENE.instantiate()
	card.info = CardInfo.new(_get_card_name())
	card.position = DRAW_POSITION
	create_tween().tween_property(card, "modulate:a", 1, 0.2).set_trans(Tween.TRANS_QUAD)

	card.is_played.connect(_card_played.bind(card))
	card.left_hand.connect(_card_leaves_hand.bind(card))
	card.back_hand.connect(_card_returns_hand.bind(card))

	add_child(card)
	card_children.push_back(card)

	_update_card_positions()

func _get_card_name() -> String:
	if draw_pile.size() > 0:
		return draw_pile.pop_back()

	while discard_pile.size() > 0:
		draw_pile.push_back(discard_pile.pop_back())

	return draw_pile.pop_back()
	

func _card_played(card: Card) -> void:
	discard_pile.push_back(card.info.name)
	card.free_move = false
	var starting_pos: Vector2 = card.position

	var tween: Tween = create_tween()
	tween.tween_method(_discard_card_arc.bind(starting_pos, card), 0.0, 1.0, 0.5)

	await tween.finished
	card.queue_free()

func _discard_card_arc(t: float, starting_pos: Vector2, card: Card) -> void:
	card.position = (1 - t) * starting_pos + t * DISCARD_POSITION + Vector2(0, Card.FLY_HEIGHT * 4 * t * (t - 1))
	card.rotation = PI * t
	card.modulate.a = 1 - t * t

func _card_leaves_hand(card: Card):
	card_children.remove_at(card.hand_position)
	_update_card_positions()

func _card_returns_hand(card: Card):
	card_children.insert(card.hand_position, card)
	_update_card_positions()

func _update_card_positions():
	card_distance = 250 - 10 * card_amount

	for i in range(card_amount):
		var card: Card = card_children[i]
		card.hand_position = i

		var target_pos: Vector2 = _card_position(card.hand_position)
		card.default_position = target_pos
		card.target_position = target_pos

func _card_position(hand_pos: int) -> Vector2:
	var offset: float = (hand_pos - 0.5 * (card_amount - 1)) * card_distance
	return HAND_MIDDLE + Vector2(offset, 0)

func _process(_delta: float) -> void:
	$DrawPile.text = str(draw_pile.size())
	$DiscardPile.text = str(discard_pile.size())
