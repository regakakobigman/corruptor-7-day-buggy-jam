extends CanvasLayer

# trying abbreviated control names for this project

# this TextureProgress is really ugly, could probably be improved
# update: by "improved" i mean "removed". the clock does it all now
onready var TP = $C/TP

onready var CC = $CC
onready var CCTween = $CC/CCTween

onready var Back = $C/C/Back
onready var Clock = $C/C/Clock
onready var Handle = $C/C/Handle
onready var HandleTween = $C/C/HandleTween
onready var BackTween = $C/C/BackTween

# on timeout, corruptions happen
onready var CorruptTimer = $CorruptTimer

# short cooldown between bonus corruptions at max corrupt meter
onready var BonusCorruptTimer = $BonusCorruptTimer

var bar_deplete_linear = 3
var bar_deplete_ratio_mult = 15

var back_growing = true
var back_min_size = 0.52
var back_min_size_boost = 0.03
var back_max_size = 0.55
var back_max_size_boost = 0.03

var corrupt_timer_base_cooldown = 0.5
var corrupt_timer_corrupting_everything = false

var bonus_corruptions = 5
var bonus_corruptions_left = bonus_corruptions
var bonus_corruptions_cooldown = 0.016

var tick_max_volume = -0
var tick_min_volume = -6

func _ready() -> void:
    Global.UI = self
    $Button.connect("pressed", self, "thing")
    Global.connect("screen_size_changed", self, "update_progress_size")
    update_progress_size()

func update_progress_size() -> void:
    #TP.texture_under.height = Global.screen_size.y
    #TP.texture_progress.height = Global.screen_size.y
    
    var s1 = $CC/C/Sprite
    var s2 = $CC/C/Control/Sprite2
    s1.texture.width = Global.screen_size.x
    s2.texture.width = Global.screen_size.y
    s1.region_rect = Rect2(0, 0, Global.screen_size.x, Global.screen_size.y)
    s2.region_rect = Rect2(0, 0, Global.screen_size.y, Global.screen_size.x)

func _process(delta: float) -> void:
    var ratio_left = TP.value / 100
    # crazy formula that could probably be replaced with a single ease()
    TP.value -= (bar_deplete_ratio_mult * ratio_left + bar_deplete_linear) * delta * ease(ratio_left * 0.9 + 0.1, 0.1)

func thing():
    Corruptor.corrupt_something()
    var text = ""
    var p = get_tree().get_root().get_node("Game/Player")
    for key in p.corrupt_targets.keys():
        text += "%s: %s\n" % [key.capitalize(), p.get(key) as String]
    $RichTextLabel.text = text

func _on_CorruptTimer_timeout() -> void:
    Corruptor.corrupt_something_on_object(Global.Player)
    var corruptable_tiles = get_tree().get_nodes_in_group("CorruptableTile")
    var corruptable_sheet_sprites = get_tree().get_nodes_in_group("CorruptableSheetSprite")
    if corrupt_timer_corrupting_everything:
        bonus_corruptions_left = bonus_corruptions
        BonusCorruptTimer.wait_time = bonus_corruptions_cooldown
        BonusCorruptTimer.start()
        for i in 10:
            Corruptor.corrupt_tile(corruptable_tiles[randi() % corruptable_tiles.size()])
        for i in 3:
            Corruptor.corrupt_sheet_sprite(corruptable_sheet_sprites[randi() % corruptable_sheet_sprites.size()])
    else:
        Corruptor.corrupt_something()
        for i in 3:
            Corruptor.corrupt_tile(corruptable_tiles[randi() % corruptable_tiles.size()])
        for i in 1:
            Corruptor.corrupt_sheet_sprite(corruptable_sheet_sprites[randi() % corruptable_sheet_sprites.size()])
    
    var ratio_left = TP.value / 100
    var cooldown_bonus: float
    if ratio_left == 0:
        cooldown_bonus = 0
    elif ratio_left < 0.15:
        cooldown_bonus = 0.15
    elif ratio_left < 0.35:
        cooldown_bonus = 0.35
    elif ratio_left < 0.55:
        cooldown_bonus = 0.55
    else:
        cooldown_bonus = 0.85
    
    CorruptTimer.wait_time = corrupt_timer_base_cooldown + cooldown_bonus
    
    # clock hand's tween time won't go out of sync this way
    var tween_time = CorruptTimer.wait_time
    
    # animate the clock hand
    HandleTween.interpolate_property(Handle, \
                                     "rotation", \
                                     Handle.rotation, \
                                     Handle.rotation + PI * 1/6, \
                                     tween_time, \
                                     Tween.TRANS_ELASTIC, \
                                     Tween.EASE_OUT)
    HandleTween.start()
    
    # animate the thing behind the clock
    back_growing = true
    start_back_tween()
    
    # play ticking noise (with more effects the lower the more corruption there is)
    var tick = Audio.effects.tick.duplicate()
    tick.volume_db = lerp(tick_max_volume, tick_min_volume, ratio_left)
    var reverb = AudioServer.get_bus_effect(AudioServer.get_bus_index("Clock"), 0)
    reverb.wet = ease(1 - ratio_left, 5.0) * 0.5
    for MusicPlayer in Audio.MusicPlayers:
        MusicPlayer.pitch_scale = (1 - ratio_left) + 1
    Audio.play_effect(tick)
    
    corrupt_timer_corrupting_everything = ratio_left == 0

func _on_BonusCorruptTimer_timeout() -> void:
    if bonus_corruptions_left > 0:
        bonus_corruptions_left -= 1
        Corruptor.corrupt_something()
        BonusCorruptTimer.start()


func start_back_tween() -> void:
    var tween_time = CorruptTimer.wait_time
    var ratio_left = TP.value / 100
    
    var back_adjusted_min_size = back_min_size + back_min_size_boost * (1 - ease(ratio_left, 0.2))
    var back_adjusted_max_size = back_max_size + back_max_size_boost * (1 - ease(ratio_left, 0.2))
    
    back_adjusted_min_size = Vector2(back_adjusted_min_size, back_adjusted_min_size)
    back_adjusted_max_size = Vector2(back_adjusted_max_size, back_adjusted_max_size)
    
    # using TRANS_ELASTIC and EASE_IN is very buggy, but hey, it fits the theme
    # TRANS_SINE and EASE_IN_OUT looks smoother though
    BackTween.interpolate_property(Back, \
                                   "scale", \
                                   back_adjusted_min_size if back_growing else back_adjusted_max_size, \
                                   back_adjusted_max_size if back_growing else back_adjusted_min_size, \
                                   tween_time / 3.0, \
                                   Tween.TRANS_ELASTIC, \
                                   Tween.EASE_IN)
    BackTween.start()

func _on_BackTween_tween_completed(object: Object, key: NodePath) -> void:
    if back_growing:
        back_growing = false
        start_back_tween()


# i basically gave up on code cleanliness at this point in the jam
# as you can see
var cctween_fade = 0.25
var cctween_fadein = 0.5
var cctween_fadeout = 0.7

func sigh_visual_effect() -> void:
    CCTween.interpolate_property(CC, "modulate", CC.modulate, \
    Color(1,1,1,cctween_fade), cctween_fadein, Tween.TRANS_SINE, Tween.EASE_OUT)
    Audio.play_effect(Audio.effects.sigh)
    CCTween.start()
    yield(CCTween, "tween_completed")
    CCTween.interpolate_property(CC, "modulate", CC.modulate, \
    Color(1,1,1,0), cctween_fadeout, Tween.TRANS_SINE, Tween.EASE_IN)
    
