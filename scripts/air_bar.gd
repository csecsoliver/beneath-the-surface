extends Control

var air = 10

@onready var list = [
	$"1",$"2",$"3",$"4",$"5",$"6",$"7",$"8",$"9",$"10"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	display_bar()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func display_bar():
	var i = 0
	for e in list:
		if i == air: break
		e.visible = true
		i+=1
	for e in list:
		if i > 9: break
		e.visible = false
		i+=1


func _on_player_lose_air(new_air: Variant) -> void:
	air = new_air
	display_bar()
	pass # Replace with function body.
