extends CharacterBody2D

# How much vertical force is applied to the player when they jump
@export var JumpPower = 1450
	# Variables checking if player can jump and if they are currently jumping
# If the player is currently trying to jump
var JumpInput = false

# If the player character is in coyote time
var CoyoteTime = false

# If the player can activate coyote time, resets when landing
# This is to prevent the timer reseting when in the air and not just leaving the ground
var CanCoyoteTime

# If the player is still holding the jump button after a jump has started
# Variable automatically goes back to false when player starts falling
var HoldingJumpInput = false

# The max speed the player can fall
@export var MaxFallSpeed = 2500

	# Variables dealing with player gravity
# Player gravity while falling
@export var FallingGravity = 4500

# Player gravity while rising (usually from jumping)
@export var RisingGravity = 2500

# Player gravity while at the peak of a jump
@export var PeekGravity = 1750

# How low the player's y velocity needs to be to count as the peek of a jump
@export var PeekRange = 250

	# Horizontal movement variables
# The fastest the player can move with just the movment keys
@export var SoftSpeedCap = 1200
# The fastest the player can move in general
@export var HardSpeedCap = 6000

# The ammount of acceleration the player has when moving normaly
@export var NormalAcceleration = 350

# The ammount of acceleration the player has when turning around
@export var TuringAcceleration = 400

# The ammount of acceleration the player has when in the air
@export var AirAcceleration = 85

# The ammount of deceleration the player has when stopping normally
@export var NormalDeceleration = 290

# The ammount of deceleration the player has when in the air
@export var AirDeceleration = 10

# The ammount of deceleration the player going past the soft speed cap and is on the floor
@export var HighSpeedDeceleration = 40

# Set to true if the player is at the peek of their jump, used when calculating air momentum
var PeekOfJump : bool

# How much Horizontal force that is applied to the player every physics update
var CurHorizontalVelocity : float

# How much Vertical force that is applied to the plaet every physics update
var CurVerticalVelocity : float

	# Variables for ledge forgiveness
# How much to nudge the player every frame if they just barely didn't make a jump
# or hit their head on a ceiling while moving fast
@export var VerticalNudge = 7

# How much to nudge the player every frame if they hit their head on the coner of
# a ceiling
@export var HorizontalNudge = 7

# Skip the vertical speed reset when landing on the ground for one physics update
# used for springs so the ground doesn't cancel them out
var SkipGroundReset

func _physics_process(delta):
	
	# Detect if player is on the ground to reset the coyote timer and vertical velocity
	if is_on_floor():
		if (SkipGroundReset):
			SkipGroundReset = false
		else:
			CurVerticalVelocity = 0
		CoyoteTime = false
		$Timers/CoyoteTimer.stop()
		CanCoyoteTime = true
	
	# Add the gravity and set the coyote timer
	if not is_on_floor():
		# Set coyote timer
		if (CanCoyoteTime):
			$Timers/CoyoteTimer.start()
			CoyoteTime = true
			CanCoyoteTime = false
			
		# check if the player is at the peek of a jump
		if (CurVerticalVelocity < PeekRange and CurVerticalVelocity > -PeekRange):
			# apply peek jump gravity
			CurVerticalVelocity += PeekGravity * delta
			PeekOfJump = true
		else:
			PeekOfJump = false
			# check if the player is rising or falling
			if (CurVerticalVelocity > 0):
				# Check to see if the player is under the max fall speed or not
				if (CurVerticalVelocity < MaxFallSpeed):
					# apply falling gravity
					HoldingJumpInput = false
					CurVerticalVelocity += FallingGravity * delta
				else:
					# Set the player's y velocity equal to their max fall speed
					HoldingJumpInput = false
					CurVerticalVelocity = MaxFallSpeed
			if (CurVerticalVelocity < 0):
				# apply rising gravity
				CurVerticalVelocity += RisingGravity * delta

	# Detect if the player is trying to jump and enable the jump buffer timer
	if Input.is_action_just_pressed("jump"):
		JumpInput = true
		$Timers/JumpBufferTimer.start()
	
	# Detect if the player has let go of the jump button while rising up
	if Input.is_action_just_released("jump"):
		if (HoldingJumpInput):
			CurVerticalVelocity = CurVerticalVelocity / 2
		HoldingJumpInput = false

	# Start jump
	if (JumpInput == true and (is_on_floor() or CoyoteTime)):
		# Check if trying to pass through a platform
		if (is_on_floor() and Input.is_action_pressed("down") and get_last_slide_collision() and get_last_slide_collision().get_collider().get_collision_layer() == 2):
			set_collision_mask_value(2, false)
			$Timers/PassThroughTimer.start()
		else:
			CurVerticalVelocity = -JumpPower
			JumpInput = false
			HoldingJumpInput = true
		
		# Stop the coyote timer
		$Timers/CoyoteTimer.stop()
		CoyoteTime = false
		CanCoyoteTime = false

	# Get player's horizontal input
	var direction = Input.get_axis("left", "right")
	if !direction:
		#velocity.x = direction * 500
		direction = 0
		#velocity.x = move_toward(velocity.x, 0, 500)
	
	# Makes sure that the player is both inputing a direction and is not over the soft speed cap
	# before applying acceleration of decceleration acordingly
	if (abs(CurHorizontalVelocity) <= SoftSpeedCap and direction):
		
		# Apply normal movement acceleration if the player is on the ground
		if(is_on_floor()):
		# Checks if the player is trying to turn around and if the turing acceleration would be more
		# than the normal acceleration or not
			if (direction != sign(CurHorizontalVelocity) and TuringAcceleration * (abs(CurHorizontalVelocity) / SoftSpeedCap) > NormalAcceleration):
				# Applies Truning Acceleration
				CurHorizontalVelocity += (TuringAcceleration * (abs(CurHorizontalVelocity) / SoftSpeedCap)) * direction
			else:
				# Cecks if the player is near the soft cap or not
				if (sign(CurHorizontalVelocity) == direction and (abs(CurHorizontalVelocity) / SoftSpeedCap) >.75 and (abs(CurHorizontalVelocity) / SoftSpeedCap) < 1.1):
					# If the player is near the soft speed cap then set the player's current velocity equal to the
					# soft speed cap
					CurHorizontalVelocity = SoftSpeedCap * direction
				else:
					# Apply normal acceleration
					CurHorizontalVelocity += NormalAcceleration * direction
		else:
			# Cecks if the player is near the soft cap or not
				if (sign(CurHorizontalVelocity) == direction and(abs(CurHorizontalVelocity) / SoftSpeedCap) >.75 and (abs(CurHorizontalVelocity) / SoftSpeedCap) < 1.1):
					# If the player is near the soft speed cap then set the player's current velocity equal to the
					# soft speed cap
					CurHorizontalVelocity = SoftSpeedCap * direction
				else:
					# Checks if the player is at the peek of a jump
					if(PeekOfJump):
						# apply 200% of the air acceleration to give more controle at the peek
						CurHorizontalVelocity += (AirAcceleration * 2) * direction
					else:
						# Apply air acceleration
						CurHorizontalVelocity += AirAcceleration * direction
	else:
		# Check to see if the player is close to stopping or not
		if (CurHorizontalVelocity < 10 and CurHorizontalVelocity > -10):
			# Set player's velocity to 0 if they are close to stopping
			CurHorizontalVelocity = 0
		else:
			# Check if the player is moving below or slightly above the Soft speed cap
			if (abs(CurHorizontalVelocity) / SoftSpeedCap >= 1.1):
				# Check and see if the player is over the hard speed cap or not
				if (abs(CurHorizontalVelocity) > HardSpeedCap):
					# Set the velocity equal to the hard speed cap
					CurHorizontalVelocity = HardSpeedCap * sign(CurHorizontalVelocity)
					# Apply High Speed Deceleration
					CurHorizontalVelocity -= HighSpeedDeceleration * sign(CurHorizontalVelocity)
				else:
					# Check to see if the player is in the air or not
					if(is_on_floor()):
						# Apply normal deceleration
						CurHorizontalVelocity -= HighSpeedDeceleration * sign(CurHorizontalVelocity)
					else:
						# Apply air deceleration
						CurHorizontalVelocity -= AirDeceleration * sign(CurHorizontalVelocity)
			else:
				# Check to see if the player is in the air or not
				if (is_on_floor()):
					# Apply normal Deceleration while within soft speed cap
					CurHorizontalVelocity -= (NormalDeceleration * sign(CurHorizontalVelocity)) * (abs(CurHorizontalVelocity) / SoftSpeedCap)
				else:
					# Apply air Deceleration while within soft speed cap
					CurHorizontalVelocity -= (AirAcceleration * sign(CurHorizontalVelocity)) * (abs(CurHorizontalVelocity) / SoftSpeedCap)
			
	
	if (Input.is_action_just_pressed("Space")):
		if (Input.is_action_pressed("up")):
			HoldingJumpInput = false
			CurVerticalVelocity -= 2000
		else: if (Input.is_action_pressed("down")):
			CurHorizontalVelocity = 0
			CurVerticalVelocity = 0
		else:
			CurHorizontalVelocity += 10000 * direction
	
	
	if(Input.is_action_just_pressed("Rest")):
		global_transform.origin = Vector2.ZERO
	
	
	var EnableCollision = true
	
	# checks to see if the player and against a Ceiling is in the air
	if (!is_on_floor() and is_on_ceiling()):
		# Checks if the player is going at lest 25% of your jumpforce worth of velocity up
		if(CurVerticalVelocity <= JumpPower * .75 and !$LeftWallRay.is_colliding()):
			# Check to see if the player is rubbing against a ledge
			if ($CeilingRayFarLeft.is_colliding() and !$CeilingRayLeft.is_colliding()):
				# Disable the player's collsion
				set_collision_mask_value(1, false)
				EnableCollision = false
				# Nudge the player right by "HorizontalNudge" ammount of units
				global_transform.origin += Vector2(HorizontalNudge, 0) 
			else:if (!$CeilingRayRight.is_colliding() and $CeilingRayFarRight.is_colliding()):
				# Disable the player's collsion
				set_collision_mask_value(1, false)
				EnableCollision = false
				# Nudge the player left by "HorizontalNudge" ammount of units
				global_transform.origin -= Vector2(HorizontalNudge, 0) 
			else: if (CurVerticalVelocity < 0):
				CurVerticalVelocity = 0
	
	# checks to see if the player is in the air, over 30% of their soft speed cap, 
	# and against a left wall 
	if(!is_on_floor() and $LeftWallRay.is_colliding() and sign(CurHorizontalVelocity) == -1 and abs(CurHorizontalVelocity) * (abs(CurHorizontalVelocity) / SoftSpeedCap) >= .3):
		# Check to see if the player is rubbing against a ledge
		if ($LedgeForgivenessRayBottom.is_colliding() and !$LedgeForgivenessRayTop.is_colliding()):
			# Disable the player's collsion
			set_collision_mask_value(1, false)
			EnableCollision = false
			# Nudge the player up by "VerticalNudge" ammount of units
			global_transform.origin -= Vector2(0, VerticalNudge) 
		# If the player is not on a ledge check to see if the player is rubbing against a corner
		else: if ($CornerForgivenessRayTop.is_colliding() and !$CornerForgivenessRayBottom.is_colliding()):
			# Disable the player's collsion
			set_collision_mask_value(1, false)
			EnableCollision = false
			# Set the player's vertical velocity to 0 so they don't get stuck to the ceiling
			if(CurVerticalVelocity < 0):
				CurVerticalVelocity = 0
			# Nudge the player down by "VerticalNudge" ammount of units
			global_transform.origin += Vector2(0, VerticalNudge) 
		else:
			# If the player is not on a corner or lege stop their horizontal velocity because
			# they hit a wall
			CurHorizontalVelocity = 0
	# checks to see if the player is in the air, over 30% of their soft speed cap, 
	# and against a right wall 
	else:if(!is_on_floor() and $RightWallRay.is_colliding() and sign(CurHorizontalVelocity) == 1 and abs(CurHorizontalVelocity) * (abs(CurHorizontalVelocity) / SoftSpeedCap) > .3):
			# Check to see if the player is rubbing against a ledge
		if ($LedgeForgivenessRayBottom.is_colliding() and !$LedgeForgivenessRayTop.is_colliding()):
			# Disable the player's collsion
			set_collision_mask_value(1, false)
			EnableCollision = false
			# Nudge the player up by "VerticalNudge" ammount of units
			global_transform.origin -= Vector2(0, VerticalNudge) 
		# If the player is not on a ledge check to see if the player is rubbing against a corner
		else: if ($CornerForgivenessRayTop.is_colliding() and !$CornerForgivenessRayBottom.is_colliding()):
			# Disable the player's collsion
			set_collision_mask_value(1, false)
			EnableCollision = false
			# Set the player's vertical velocity to 0 so they don't get stuck to the ceiling
			if(CurVerticalVelocity < 0):
				CurVerticalVelocity = 0
			# Nudge the player down by "VerticalNudge" * 2 ammount of units
			global_transform.origin += Vector2(0, VerticalNudge * 2) 
		else:
			# If the player is not on a corner or lege stop their horizontal velocity because
			# they hit a wall
			CurHorizontalVelocity = 0
	
	if(EnableCollision):
		# Enables the player's collision again
		set_collision_mask_value(1, true)
	
	velocity = Vector2(CurHorizontalVelocity, CurVerticalVelocity)
	
	move_and_slide()

# Reset buffer jump
func buffer_timer_timeout():
	JumpInput = false

# Disable CoyoteTime
func coyote_timer_timeout():
	CoyoteTime = false

# Reinable one way platforms
func _on_pass_through_timer_timeout():
	set_collision_mask_value(2, true)

# Apply a force
func Apply_Force(AppliedForce : Vector2, CancelJump : bool):
	# Cancel the player's jump
	if(CancelJump): 
		HoldingJumpInput = false
		CoyoteTime = false
		JumpInput = false
	
	# Tell the player to ignore if they touched the ground or not for one frame
	# otherwise applying vertical force to the player doesn't work sometimes
	# because the player tried to reset their vertical momentum when on the ground
	SkipGroundReset = true
	
	# Add the applied force variable to the player's current velocity
	CurHorizontalVelocity += AppliedForce.x
	CurVerticalVelocity += AppliedForce.y

func Set_Velocity(VelocitySet : Vector2, CancelJump : bool):
	# Cancel the player's jump
	if(CancelJump): 
		HoldingJumpInput = false
		CoyoteTime = false
		JumpInput = false
	
	# Tell the player to ignore if they touched the ground or not for one frame
	# otherwise applying vertical force to the player doesn't work sometimes
	# because the player tried to reset their vertical momentum when on the ground
	SkipGroundReset = true
	
	# Add the applied force variable to the player's current velocity
	CurHorizontalVelocity = VelocitySet.x
	CurVerticalVelocity = VelocitySet.y

func Get_Velocity():
	return Vector2(CurHorizontalVelocity, CurVerticalVelocity)



