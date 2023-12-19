extends Node2D

# How much force the spring applies to the player
@export var SpringStrength : int
@export var PushRight : bool

signal Horizontal_Spring_Bounce

func _on_area_2d_body_entered(body):
	if(PushRight):
		body.Set_Velocity(Vector2(SpringStrength, -5), true)
	else:
		body.Set_Velocity(Vector2(-SpringStrength, (body.Get_Velocity().x) * .5), true)
