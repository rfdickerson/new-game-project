extends Panel

@onready var city_name_label: Label = $VBoxContainer/CityInfoContainer/CityNameLabel
@onready var population_label: Label = $VBoxContainer/CityInfoContainer/PopulationLabel
@onready var food_label: Label = $VBoxContainer/CityInfoContainer/FoodLabel
@onready var production_label: Label = $VBoxContainer/CityInfoContainer/ProductionLabel
@onready var gold_income_label: Label = $VBoxContainer/CityInfoContainer/GoldIncomeLabel
@onready var next_turn_button: Button = $VBoxContainer/NextTurnButton

var game_ui: Control = null

var city_name: String = "Alexandria"
var population: int = 1000
var food: int = 50
var production: int = 25
var gold_income: int = 15

func _ready():
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_pressed)
	update_ui()

func update_ui():
	if city_name_label:
		city_name_label.text = city_name
	if population_label:
		population_label.text = "Population: %d" % population
	if food_label:
		food_label.text = "Food: %d" % food
	if production_label:
		production_label.text = "Production: %d/turn" % production
	if gold_income_label:
		gold_income_label.text = "Gold Income: +%d/turn" % gold_income

func set_game_ui(ui: Control):
	game_ui = ui

func set_city_name(city_name_value: String):
	city_name = city_name_value
	update_ui()

func set_population(pop: int):
	population = pop
	update_ui()

func set_food(f: int):
	food = f
	update_ui()

func set_production(prod: int):
	production = prod
	update_ui()

func set_gold_income(income: int):
	gold_income = income
	update_ui()

func _on_next_turn_pressed():
	if game_ui:
		game_ui.next_turn()

