extends Control

@onready var gold_label: Label = $HBoxContainer/GoldContainer/GoldLabel
@onready var year_label: Label = $HBoxContainer/YearLabel
@onready var turn_label: Label = $HBoxContainer/TurnLabel

var gold: int = 0
var year: int = 1700
var turn: int = 1

func _ready():
	update_ui()

func update_ui():
	if gold_label:
		gold_label.text = "Gold: %d" % gold
	if year_label:
		year_label.text = "Year: %d" % year
	if turn_label:
		turn_label.text = "Turn: %d" % turn

func set_gold(amount: int):
	gold = amount
	update_ui()

func add_gold(amount: int):
	gold += amount
	update_ui()

func set_year(new_year: int):
	year = new_year
	update_ui()

func set_turn(new_turn: int):
	turn = new_turn
	update_ui()

func next_turn():
	turn += 1
	year += 1 # Increment year by 1 each turn for now
	add_gold(10) # Give some gold per turn
	update_ui()

