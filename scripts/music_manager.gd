
extends Node

var music_player: AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	var music = load("res://sounds/New Super Mario Bros. 2 - Underwater ♪ [duRDiRKjwgc].mp3")
	music_player.stream = music
	music_player.autoplay = false
	
func play_music():
	if not music_player.playing:
		music_player.play()

func stop_music():
	music_player.stop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
