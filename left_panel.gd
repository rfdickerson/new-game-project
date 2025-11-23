extends Panel

@onready var city_name_label: Label = $VBoxContainer/CityInfoContainer/CityNameLabel
@onready var population_value: Label = $VBoxContainer/CityInfoContainer/PopulationContainer/PopulationValue
@onready var food_value: Label = $VBoxContainer/CityInfoContainer/FoodContainer/FoodValue
@onready var production_value: Label = $VBoxContainer/CityInfoContainer/ProductionContainer/ProductionValue
@onready var gold_income_value: Label = $VBoxContainer/CityInfoContainer/GoldIncomeContainer/GoldIncomeValue
@onready var next_turn_button: Button = $VBoxContainer/NextTurnButton

var game_ui: Control = null

var city_name: String = "Nassau"
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
	if population_value:
		population_value.text = "%d" % population
	if food_value:
		food_value.text = "%d" % food
	if production_value:
		production_value.text = "%d/turn" % production
	if gold_income_value:
		gold_income_value.text = "+%d/turn" % gold_income

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
