extends KinematicBody2D
#Variables
var power = 0
var speedX = 0
var speedY = 0
var velocity = Vector2(0,0)
var facingDirection = 0
var movementDirection = 0
var playerSprite 
var MAXJUMPCOUNT = 1
var jumpcount = 0
var deltaTime = 0
var landed 
var incincible = false
var inviTimer = 0
var invicibleTime = 0
#Constants
const MAXIMUMSPEED = 300
const MOVMULTI = 800
const JUMPFORCE = 350
const GRAVITY = 800
const bricksParticle_scene = preload("res://resources/scenes/BricksParticleScene.tscn")
const powerUp_scene = preload("res://resources/scenes/PowerUpScene.tscn")
const powerUpBrick_scene = preload("res://resources/scenes/PowerUpBoxScene.tscn")

func _animatePlayer():
	if(playerSprite.get_frame()>=3):
		playerSprite.set_frame(0)
	if(playerSprite.get_frame()<3):
		playerSprite.set_frame(playerSprite.get_frame()+1)
	deltaTime = 0 
	pass

func _ready():
	set_process(true)
	playerSprite = get_node("Sprite")
	pass
	
func _process(delta):
	if(incincible):
		inviTimer = inviTimer+delta
		invicibleTime = invicibleTime + delta
		if(invicibleTime>1):
			incincible=false
			get_node("Sprite").set_opacity(1) 
		if(inviTimer> 0.05):
			if(get_node("Sprite").get_opacity() == 1):
				get_node("Sprite").set_opacity(0)
			else:
				get_node("Sprite").set_opacity(1)
			inviTimer = 0
	if(Input.is_action_pressed("move_jump") and jumpcount<MAXJUMPCOUNT):
		speedY = -JUMPFORCE
		jumpcount+=1
		playerSprite.set_frame(5)
		landed = false
	if(Input.is_action_pressed("move_left")):
		facingDirection = -1
		playerSprite.set_flip_h(true)
		deltaTime = deltaTime + delta
		if(deltaTime > 0.1):
			if(landed):
				_animatePlayer()
	elif(Input.is_action_pressed("move_right")):
		facingDirection = 1
		playerSprite.set_flip_h(false)
		deltaTime = deltaTime + delta
		if(deltaTime > 0.1):
			if(landed):
				_animatePlayer()
	else: 
		facingDirection = 0
		if(landed):
			playerSprite.set_frame(4)
		
	if(velocity.x ==0 and landed):
		playerSprite.set_frame(0)
	
	if(facingDirection!=0):
		speedX += MOVMULTI * delta
		movementDirection = facingDirection
	else: speedX -= MOVMULTI * 2 * delta
	speedX = clamp( speedX, 0, MAXIMUMSPEED)
	speedY += GRAVITY * delta
	velocity.x = speedX * delta * movementDirection
	velocity.y = speedY * delta
	var moveRemainder = move(velocity)
	if is_colliding():
		var normal = get_collision_normal()
		var object = get_collider()
		var objectParent = object.get_parent()
		if(normal == Vector2(0,1)):
			if(objectParent.is_in_group("Bricks")):
				if (power>0):
					objectParent.queue_free()
					var particleEffect = bricksParticle_scene.instance()
					particleEffect.get_node(".").set_emitting(true)
					particleEffect.set_pos(get_pos()-Vector2(0,20))
					get_tree().get_root().add_child(particleEffect)
			elif(objectParent.is_in_group("PowerUpBrick")):
				#Create the power up Brick
				var powerUpBrick = powerUpBrick_scene.instance()
				powerUpBrick.set_pos(objectParent.get_node("Sprite").get_global_pos())
				objectParent.queue_free()
				get_tree().get_root().add_child(powerUpBrick)
				#Create the actual powerup
				var powerUp = powerUp_scene.instance()
				powerUp.set_pos(get_pos()-Vector2(0,50))
				get_tree().get_root().add_child(powerUp)
				
		var finalMov = normal.slide(moveRemainder)
		if(normal == Vector2(1,0) or normal == Vector2(-1,0)):
			speedX = 0
		else :
			speedY = 0
		speedY = 0
		move(finalMov)
		if (normal == Vector2(0, -1)):
			jumpcount=0
			if(!landed):
				playerSprite.set_frame(0)
				landed = true
				
	var area = get_node("Area2D").get_overlapping_bodies()
	if(area.size() !=0):
		for body in area:
			if(body.is_in_group("PowerUp")):
				power+=1
				body.queue_free()
				get_node("Sprite").set_modulate(Color("#5b6dff"))
			if(body.is_in_group("Pits")):
				get_tree().reload_current_scene()
			if(body.is_in_group("Enemy")):
				if(body.get_pos().y > get_pos().y):
					body.get_node("CollisionShape2D").set_trigger(true)
				elif(!incincible):
					power-=1					
					incincible = true
					if(power==0):
						get_node("Sprite").set_modulate(Color("#ffffff"))
					if(power<0):
						get_tree().reload_current_scene()	
	pass
