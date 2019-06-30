extends KinematicBody2D

# There are two sprites for the top/bottom, because I want every
# PlatformerSheetSprite to be identical (to make corruption easier)
# Think of corrupting Big Mario in SMB1
onready var TopSprite = $PlatformerSheetSpriteTop
onready var BotSprite = $PlatformerSheetSpriteBottom

onready var AnimPlayer = $AnimationPlayer

# lets the player jump shortly after falling off a ledge
onready var CoyoteTimer = $CoyoteTimer
# autojumps if the player jumps too early
onready var JumpBufferTimer = $JumpBufferTimer
# short cooldown between jumps
onready var JumpCooldownTimer = $JumpCooldownTimer

# used for getting the floor normal
onready var FloorRayCast2D = $FloorRayCast2D

# Physics

# Based on the 2D Kinematic Character Demo
# https://github.com/godotengine/godot-demo-projects/issues/336
# That issue basically sums up how this differs from the demo

var gravity = 2200
var gravity_fall = 4600
var gravity_slope_multiplier := 30.0 # at 1.0: the gravity is 1x on a flat surface and 2x on a 90-degree angle
var walk_force = 5000
var run_walk_force = 8500
var walk_min_speed = 10.0 # not fun to corrupt, so it's left out
var walk_max_speed = 500
var run_walk_max_speed = 850
var stop_force = 5000
var run_stop_force = 8500
var jump_speed = 1000
var jump_min_speed = 700
export(float, EASE) var multijump_falloff := 2.0
var jumps := 5

# things that aren't fun to corrupt
var jumps_left := jumps
var prev_on_floor := false # this is used to subtract 1 jump when falling off a ledge
var waiting_for_coyote := false
const MAX_FLOOR_NORMAL = -0.75 # lets you walk/stand on slopes shallower than this

var velocity = Vector2(0,0)

const corrupt_targets = {
    gravity = {
        min = -10000,
        max = 10000,
        mean = 2200,
        deviation = 1100,
    },
    gravity_fall = {
        min = -10000,
        max = 10000,
        mean = 4600,
        deviation = 2300,
    },
    gravity_slope_multiplier = {
        min = -100.0,
        max = 100.0,
        mean = 30.0,
        deviation = 15.0,
    },
    walk_force = {
        min = 1000,
        max = 50000,
        mean = 5000,
        deviation = 2500,
    },
    run_walk_force = {
        min = 1000,
        max = 85000,
        mean = 8500,
        deviation = 4250,
    },
    walk_max_speed = {
        min = 100,
        max = 5000,
        mean = 500,
        deviation = 250,
    },
    run_walk_max_speed = {
        min = 100,
        max = 8500,
        mean = 850,
        deviation = 425,
    },
    stop_force = {
        min = 1000,
        max = 50000,
        mean = 5000,
        deviation = 2500,
    },
    run_stop_force = {
        min = 1000,
        max = 85000,
        mean = 8500,
        deviation = 4250,
    },
    jump_speed = {
        min = 100,
        max = 10000,
        mean = 1000,
        deviation = 500,
    },
    jump_min_speed = {
        min = 100,
        max = 10000,
        mean = 700,
        deviation = 350,
    },
    multijump_falloff = {
        min = 0.1,
        max = 10.0,
        mean = 2.0,
        deviation = 1.0,
    },
    jumps = {
        min = 1,
        max = 5,
        mean = 2,
        deviation = 1,
    },
}

func _on_CoyoteTimer_timeout() -> void:
    if waiting_for_coyote:
        jumps_left = max(0, jumps_left - 1) as int
        waiting_for_coyote = false

func _ready() -> void:
    Global.Player = self

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump") and not event.is_echo():
        JumpBufferTimer.start()

func _physics_process(delta: float) -> void:
    var force = Vector2()
    
    var walk_left_pressed = Input.is_action_pressed("move_left")
    var walk_right_pressed = Input.is_action_pressed("move_right")
    var crouch_pressed = Input.is_action_pressed("crouch")
    var run_pressed = Input.is_action_pressed("run")
    var jump_just_pressed = Input.is_action_just_pressed("jump")
    var jump_pressed = Input.is_action_pressed("jump")
    
    # angle of the surface below us
    var floor_normal = FloorRayCast2D.get_collision_normal()
    
    # adjusted based on whether run key is held
    var real_walk_force = walk_force if not run_pressed else run_walk_force
    var real_walk_max_speed = walk_max_speed if not run_pressed else run_walk_max_speed
    var real_stop_force = stop_force if not run_pressed else run_stop_force
    
    # adjusted based on whether rising/falling and if jump key is held
    if not is_on_floor() or (is_on_floor() and floor_normal.y > MAX_FLOOR_NORMAL):
        if velocity.y < 0 and not jump_pressed or velocity.y > 0:
            force.y += gravity_fall
        else:
            force.y += gravity
    
    if is_on_floor():
        # normal.y of -1: flat ground
        # normal.y of -.7: 45-degree angle
        # for example: on flat ground, force.y *= (2 - 1) -> force.y *= 1
        # on a 60 degree slope, force.y *= (2 - 0.44) -> force.y *= 1.66
        
        # did not implement this but: you should try multiplying the
        # player's velocity by this for tons of fun on ramps and slides!
        force.y *= max(0.75 + floor_normal.y, 0) * gravity_slope_multiplier + 1
    
    # apply a constant movement force in whatever direction is held
    if walk_left_pressed and velocity.x <= walk_min_speed and velocity.x > -real_walk_max_speed \
    or walk_right_pressed and velocity.x >= -walk_min_speed and velocity.x < real_walk_max_speed:
        if walk_left_pressed:
            force.x -= real_walk_force
        elif walk_right_pressed:
            force.x += real_walk_force
        if is_on_floor() and not AnimPlayer.current_animation == "jump":
            Utils.play_if_not_playing(AnimPlayer, "walk")
    else:
        velocity.x = clamp(abs(velocity.x) - real_stop_force * delta, 0, abs(velocity.x)) * sign(velocity.x)
    
    # this giant if-statement prevents idle from playing over the jump or falling animations
    if not (walk_left_pressed or walk_right_pressed) \
    and abs(velocity.x) < walk_min_speed \
    and is_on_floor() and not floor_normal.y > MAX_FLOOR_NORMAL \
    and not AnimPlayer.current_animation == "jump":
        Utils.play_if_not_playing(AnimPlayer, "idle")
    
    velocity += force * delta
    velocity = move_and_slide(velocity, Vector2.UP)
    
    if is_on_floor():
        CoyoteTimer.start()
        jumps_left = jumps
    
    var jump_input = jump_just_pressed or (jump_pressed and not JumpBufferTimer.is_stopped())
    var jump_valid = is_on_floor() or (not CoyoteTimer.is_stopped() and velocity.y > 0)
    
    # are we (sort of) on the ground? (accounting for coyote time)
    if jump_input and jump_valid:
        jump()
    # are we airborne with multijumps left?
    elif jump_just_pressed and jumps_left > 0 and JumpCooldownTimer.is_stopped():
        jump()
    
    if not is_on_floor() and velocity.y >= 0 and floor_normal.y > MAX_FLOOR_NORMAL:
        Utils.play_if_not_playing(AnimPlayer, "fall")
    
    if not is_on_floor() and prev_on_floor and velocity.y >= 0:
        waiting_for_coyote = true
    
    if waiting_for_coyote and jump_just_pressed:
        waiting_for_coyote = false
    
    prev_on_floor = is_on_floor()
    update_sprite_direction()

func update_sprite_direction() -> void:
    if velocity.x > 0 and (TopSprite.flip_h or BotSprite.flip_h):
        TopSprite.flip_h = false
        BotSprite.flip_h = false
    elif velocity.x < 0 and not (TopSprite.flip_h and BotSprite.flip_h):
        TopSprite.flip_h = true
        BotSprite.flip_h = true

func jump():
    var ratio_jumps_left = ease(jumps_left as float / jumps, multijump_falloff)
    if jumps > 1:
        # each multijump is less powerful than the last
        velocity.y = -lerp(jump_min_speed, jump_speed, ratio_jumps_left)
    else:
        velocity.y = -jump_speed
    if jumps_left < jumps:
        var multijump = Audio.effects.multijump.duplicate()
        multijump.pitch_scale = corrupt_targets.jump_speed.mean / lerp(jump_min_speed, jump_speed, ratio_jumps_left) as float
        Audio.play_effect(multijump)
    else:
        var jump = Audio.effects.jump.duplicate()
        jump.pitch_scale = corrupt_targets.jump_speed.mean / jump_speed as float
        Audio.play_effect(jump)
    Utils.play_if_not_playing(AnimPlayer, "jump")
    jumps_left = max(0, jumps_left - 1) as int
    JumpCooldownTimer.start()

