extends Node2D

#--- Notes ---
# Hello, greetings to whoever is reading this. This is merely a prototype and there's a lot of things to implement to. 
# UNDO is still built-in, not manually coded to see how the game works. So, as arrays.
# Note written by: Sharksnow-123 (Briar)

# --- SETTINGS ---
const MAX_GUESSES := 6
var word_list_day1 = ["APPLE", "ROBOT", "SNAKE"]
var word_list_day2 = ["WATERFALL", "NOTEBOOK", "PYTHON"]
var word_list_day3 = ["ASTRONOMY", "COMPUTER", "VOLCANO"]

# --- STATE ---
var chosen_word := ""
var hidden_letters := []            # renamed from hidden
var guessed_letters := []
var wrong_guesses := 0
var undo_stack := []
var current_day := 1
const MAX_DAYS := 3
var last_round_result : String = ""   # "win" or "lose"



# --- UI ---
@onready var word_label = $WordLabel
@onready var guessed_label = $GuessedLetters
@onready var letters = $Letters
@onready var undo_button = $UndoButton
@onready var lose_panel = $LosePanel
@onready var title_label = $LosePanel/Title
@onready var continue_button = $LosePanel/ContinueButton
@onready var return_button = $LosePanel/ReturnMain
@onready var day_frame = $DayFrame
@onready var dialogue_panel = $DialoguePanel
@onready var dialogue_label = $DialoguePanel/DialogueText

#RECENTLY ADDED
var dialogue_list = [ "Butcher: Hey!!! are u tired now?",
	"Butcher: Wakie wakie little roachie", "Butcher: Ehhhh, come on lets play more!!"]
var dialogue_index = 0;

const DIALOGUE_INTERVAL := 5.0
const DIALOGUE_SHOWTIME := 3.0


const TYPE_SPEED := 0.05
var _typing := 	false
var _type_char_index := 0
var _current_text := ""
var _type_timer := Timer.new()


func _ready():
	randomize()
	connect_buttons()
	start_game()
	dialogue_label.visible = false
	
	
	_type_timer.wait_time = TYPE_SPEED
	_type_timer.one_shot = false
	_type_timer.connect("timeout", Callable(self, "_typewriter_step"))
	add_child(_type_timer)
	
	_start_dialogue_loop()

 #------------------------
 #Dialogue Test
 #------------------------

func _start_dialogue_loop():
	var dialogue_timer = Timer.new()
	dialogue_timer.wait_time = DIALOGUE_INTERVAL
	dialogue_timer.one_shot = false
	dialogue_timer.autostart = true
	dialogue_timer.connect("timeout", Callable(self, "_on_dialogue_timer_timeout"))
	add_child(dialogue_timer)


func _on_dialogue_timer_timeout():
	#dialogue_label.text = dialogue_list[dialogue_index]
	#dialogue_label.visible = true
	#
	#var hide_timer = Timer.new()
	#hide_timer.wait_time = DIALOGUE_SHOWTIME
	#hide_timer.one_shot = true
	#hide_timer.connect("timeout", Callable(self, "_hide_dialogue"))
	#add_child(hide_timer)
	#hide_timer.start()
	
	show_dialogue(dialogue_list[dialogue_index])
	dialogue_index = (dialogue_index + 1) % dialogue_list.size()
	

func show_dialogue(text: String):
	dialogue_label.visible = true
	_current_text = text
	dialogue_label.text = ""
	_type_char_index = 0
	_typing = true
	_type_timer.start()
	
	var hide_timer = Timer.new()
	hide_timer.wait_time = TYPE_SPEED * text.length() + DIALOGUE_SHOWTIME
	hide_timer.one_shot = true
	hide_timer.connect("timeout", Callable(self, "_hide_dialogue"))
	add_child(hide_timer)
	hide_timer.start()
	

func _typewriter_step():
	if _type_char_index < _current_text.length():
		dialogue_label.text += _current_text[_type_char_index]
		_type_char_index += 1
	
	else:
		_typing = false
		_type_timer.stop()
	
	


func _hide_dialogue():
	dialogue_label.visible = false





# ------------------------
# START GAME
# ------------------------
func start_game():
	wrong_guesses = 0
	guessed_letters.clear()
	undo_stack.clear()

	chosen_word = _get_word_for_day()
	hidden_letters.clear()
	for c in chosen_word:
		hidden_letters.append("_")

	update_ui()
	_update_day_display()
	lose_panel.visible = false

	print("[Game] Day %d - New word length: %d" % [current_day, chosen_word.length()])
	print("[Game] Guesses allowed:", MAX_GUESSES)

func _get_word_for_day() -> String:
	match current_day:
		1: return word_list_day1[randi() % word_list_day1.size()]
		2: return word_list_day2[randi() % word_list_day2.size()]
		_: return word_list_day3[randi() % word_list_day3.size()]

# ------------------------
# CONNECT BUTTONS
# ------------------------
func connect_buttons():
	if letters == null:
		push_error("Letters node not found!")
		return

	for btn in letters.get_children():
		if btn is Button:
			var b = btn
			b.pressed.connect(func(): handle_letter(b.text))

	undo_button.pressed.connect(undo)
	continue_button.pressed.connect(_on_continue_pressed)
	return_button.pressed.connect(returnMain_pressed)

# ------------------------
# UPDATE DISPLAY
# ------------------------
func update_ui():
	word_label.text = " ".join(hidden_letters)
	guessed_label.text = "Guessed: " + ", ".join(guessed_letters)

func _update_day_display():
	if day_frame is Label:
		day_frame.text = "Day: " + str(current_day) + " / " + str(MAX_DAYS)

# ------------------------
# HANDLE LETTER
# ------------------------
func handle_letter(letter):
	letter = letter.to_upper()
	if letter in guessed_letters:
		return

	save_state()

	guessed_letters.append(letter)
	update_ui()

	var correct := false
	for i in range(chosen_word.length()):
		if chosen_word[i] == letter:
			hidden_letters[i] = letter
			correct = true

	update_ui()

	if correct and "_" not in hidden_letters:
		show_end("YOU WIN!")
	elif not correct:
		wrong_guesses += 1
		print("[GUESS] Wrong guesses:", wrong_guesses, " / ", MAX_GUESSES)
		if wrong_guesses >= MAX_GUESSES:
			show_end("YOU LOSE!")

# ------------------------
# UNDO
# ------------------------
func save_state():
	undo_stack.append({
		"hidden_letters": hidden_letters.duplicate(),
		"guessed": guessed_letters.duplicate(),
		"wrong": wrong_guesses
	})

func undo():
	if undo_stack.is_empty():
		print("[UNDO] No more undo")
		return
	var state = undo_stack.pop_back()
	hidden_letters = state.hidden_letters
	guessed_letters = state.guessed
	wrong_guesses = state.wrong
	update_ui()

# ------------------------
# SHOW END
# ------------------------
func show_end(text):
	if text == "YOU LOSE!":
		title_label.text = text + "\nThe word was: " + chosen_word
		last_round_result = "lose"
	else:
		title_label.text = text
		last_round_result = "win"

	lose_panel.visible = true

# ------------------------
# CONTINUE / NEXT DAY
# ------------------------
func _on_continue_pressed():
	if last_round_result == "win":
		if current_day < MAX_DAYS:
			current_day += 1
			start_game()
		else:
			await get_tree().create_timer(0.8).timeout
			get_tree().change_scene_to_file("res://EndScene1.tscn")
	elif last_round_result == "lose":
		current_day = 1
		get_tree().change_scene_to_file("res://DeathScene.tscn")
	last_round_result = ""


# ------------------------
# RETURN TO MAIN
# ------------------------
func returnMain_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


#-----------------------------------
# OPTIONS PANEL
#----------------------------------
func option_pressed():
	var option_scene = load("res://Option_Panel.tscn").instantiate()
	option_scene.previous_scene = get_tree().current_scene
	get_tree().root.add_child(option_scene)
	hide()
