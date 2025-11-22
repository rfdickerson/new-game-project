extends Panel

## Panel that displays information about the watermill invention

@onready var watermill_image: TextureRect = $VBoxContainer/WatermillImage
@onready var title_label: RichTextLabel = $VBoxContainer/TitleLabel
@onready var description_label: RichTextLabel = $VBoxContainer/DescriptionLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

var is_visible: bool = false

func _ready():
	# Set up the panel
	visible = false
	# Make sure this panel processes input even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()

func _setup_ui():
	# Set title text (bold)
	if title_label:
		title_label.text = "[b]The Watermill[/b]"
	
	# Set description text with historical information (using BBCode for formatting)
	if description_label:
		description_label.text = """[color=black]The watermill is one of humanity's earliest mechanical inventions, harnessing the energy of flowing water to perform tasks such as grinding grain into flour.

[font_size=24][b]Ancient Origins[/b][/font_size]
The earliest recorded use of watermills dates to the 3rd century BC in ancient Greece. The Greek engineer Philo of Byzantium described a water-driven wheel in his technical treatises. By the 1st century BC, the Romans had adopted and refined this technology, utilizing watermills extensively across their empire.

[font_size=24][b]Ancient China[/b][/font_size]
In parallel, ancient China developed watermill technology independently. By 30 AD, water-powered trip hammers were in use for tasks like dehusking grain and smelting iron.

[font_size=24][b]Medieval Europe[/b][/font_size]
During the Middle Ages, watermills became widespread across Europe. By the time of the Domesday Book in 1086, England alone recorded over 5,000 watermills. These mills were crucial for agricultural economies, providing efficient means to process grain and other materials.

The evolution of the watermill reflects humanity's ingenuity in harnessing natural forces for practical purposes, laying the groundwork for subsequent technological advancements in energy and machinery.[/color]"""
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

func toggle():
	"""Toggle the visibility of the panel"""
	if is_visible:
		hide_panel()
	else:
		show_panel()

func show_panel():
	"""Show the panel"""
	is_visible = true
	visible = true
	# Pause the game when panel is open
	get_tree().paused = true

func hide_panel():
	"""Hide the panel"""
	is_visible = false
	visible = false
	# Unpause the game when panel is closed
	get_tree().paused = false

func _on_close_button_pressed():
	hide_panel()

func _input(event):
	# Handle F key to toggle panel (always, so it can open/close)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			toggle()
			get_viewport().set_input_as_handled()
		# Allow closing with Escape key when visible
		elif event.keycode == KEY_ESCAPE and is_visible:
			hide_panel()
			get_viewport().set_input_as_handled()

