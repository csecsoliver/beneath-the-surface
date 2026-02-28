
extends Area2D

@onready var player = get_tree().current_scene.get_node("Player")
@onready var particle = get_tree().current_scene.get_node("BubbleParticle")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for i in get_overlapping_bodies():
		if i.has_meta("player"):
			i.add_air(5)
			queue_free()
		if i.has_meta("trident"):
			particle.global_position = self.global_position
			particle.emitting = true
			player.add_air(3)
			self.queue_free()
