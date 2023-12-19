extends Node2D

# How much force the spring applies to the player
@export var SpringStrength : int

signal Vertical_Spring_Bounce

func _on_area_2d_body_entered(body):
	if(!(body.Get_Velocity().y < 0)):
		body.Set_Velocity(Vector2(body.Get_Velocity().x,-SpringStrength), true)
