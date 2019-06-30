extends Node2D

onready var cc1 = $CanvasLayer/CenterContainer
onready var cc2 = $CanvasLayer/CenterContainer2
onready var ss = $CanvasLayer/SelectScreen
onready var tween = $CanvasLayer/Tween
onready var ttween = $CanvasLayer/TitleTween

onready var label1 = $CanvasLayer/SelectScreen/CenterContainer/VBoxContainer/Level1Button/Level1Label
onready var label2 = $CanvasLayer/SelectScreen/CenterContainer/VBoxContainer/Level2Button/Level2Label
onready var label3 = $CanvasLayer/SelectScreen/CenterContainer/VBoxContainer/Level3Button/Level3Label
onready var label4 = $CanvasLayer/SelectScreen/CenterContainer/VBoxContainer/Level4Button2/Level4Label

const Level1 = preload("res://Scenes/Level1.tscn")
const Level2 = preload("res://Scenes/Level2.tscn")
const Level3 = preload("res://Scenes/Level3.tscn")
const Level4 = preload("res://Scenes/Level4.tscn")

# very hasty solution, each level should have its own max score calculated automatically!
const MAX_SCORE = 9

var shake_amount = 40
var shake_time1 = 0.3
var shake_time2 = 0.3
var shake_time3 = 0.3

func _ready() -> void:
    _on_MusicHSlider_value_changed($CanvasLayer/SettingsButton/PC/VBC/MusicVolume/MusicHSlider.value)
    _on_ClockHSlider_value_changed($CanvasLayer/SettingsButton/PC/VBC/ClockVolume/ClockHSlider.value)
    _on_SFXHSlider_value_changed($CanvasLayer/SettingsButton/PC/VBC/SFXVolume/SFXHSlider.value)
    $CanvasLayer/SettingsButton/PC.visible = false
    cc1.visible = true
    cc2.visible = true
    ss.visible = false
    if Global.died:
        var text = $CanvasLayer/CenterContainer/TextureRect
        var shadow = $CanvasLayer/CenterContainer/TextureRect3
        for thing in [text, shadow]:
            ttween.interpolate_property(thing, "margin_left", thing.margin_left, \
            thing.margin_left - shake_amount, shake_time1, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
            ttween.interpolate_property(thing, "margin_left", thing.margin_left - shake_amount, \
            thing.margin_left + shake_amount * 2, shake_time2, Tween.TRANS_ELASTIC, Tween.EASE_IN_OUT, shake_time1)
            ttween.interpolate_property(thing, "margin_left", thing.margin_left + shake_amount * 2, \
            thing.margin_left, shake_time3, Tween.TRANS_ELASTIC, Tween.EASE_OUT, shake_time1 + shake_time2)
        ttween.start()
        Global.died = false
    
    # update the high score labels
    for s in ['1', '2', '3', '4']:
        var score = Global.get("high_score_level_" + s)
        get("label" + s).text = "High Score: " + (":(" if score <= 0 else ((score as String) if score != MAX_SCORE else ":)"))

func _on_SettingsButton_pressed() -> void:
    $CanvasLayer/SettingsButton/PC.visible = not $CanvasLayer/SettingsButton/PC.visible

# these signals are very ugly
# they could probably be replaced with some for-loops and a clever use of connect in _ready

var max_volume = 0
var min_volume = -48

var idxMusic = AudioServer.get_bus_index("Music")
var idxClock = AudioServer.get_bus_index("Clock")
var idxEffect = AudioServer.get_bus_index("Effect")

func _on_MusicCheckButton_toggled(button_pressed: bool) -> void:
    AudioServer.set_bus_mute(idxMusic, not button_pressed)
func _on_ClockCheckButton_toggled(button_pressed: bool) -> void:
    AudioServer.set_bus_mute(idxClock, not button_pressed)
func _on_SFXCheckButton_toggled(button_pressed: bool) -> void:
    AudioServer.set_bus_mute(idxEffect, not button_pressed)

func _on_MusicHSlider_value_changed(value: float) -> void:
    var ratio = value / 100
    AudioServer.set_bus_volume_db(idxMusic, lerp(min_volume, max_volume, ratio))
func _on_ClockHSlider_value_changed(value: float) -> void:
    var ratio = value / 100
    AudioServer.set_bus_volume_db(idxClock, lerp(min_volume, max_volume, ratio))
func _on_SFXHSlider_value_changed(value: float) -> void:
    var ratio = value / 100
    AudioServer.set_bus_volume_db(idxEffect, lerp(min_volume, max_volume, ratio))


var menu_up = true
var menu_tween_time = 2.0

# start button, conveniently and clearly named "Button" because of time shortage
func _on_Button_pressed() -> void:
    menu_up = not menu_up
    $CanvasLayer/CenterContainer2/Button.disabled = not menu_up
    tween.interpolate_property(cc2, "margin_bottom", cc2.margin_bottom, -cc2.margin_bottom * 4, \
    menu_tween_time, Tween.TRANS_EXPO, Tween.EASE_OUT)
    tween.interpolate_property(cc1, "margin_top", cc1.margin_top, -cc1.margin_top, \
    menu_tween_time, Tween.TRANS_SINE, Tween.EASE_IN, menu_tween_time / 2)
    for cc in [cc1, cc2]:
        tween.interpolate_property(cc, "modulate", Color(1,1,1,1), Color(1,1,1,0), \
        menu_tween_time, Tween.TRANS_EXPO, Tween.EASE_IN)
    tween.interpolate_property(ss, "modulate", Color(1,1,1,0), Color(1,1,1,1), \
    menu_tween_time, Tween.TRANS_EXPO, Tween.EASE_OUT, menu_tween_time * 1.5)
    ss.visible = true
    ss.modulate = Color(1,1,1,0)
    tween.start()

# more ugly signals
# Connect() provides a great way to avoid all this code,
# but I'm just throwing this together for the jam
# this is a really good place to _stop_ taking inspiration
func _on_Level1Button_pressed() -> void:
    Audio.change_music(Audio.MusicPlayerCottages)
    Global.current_level = 1
    get_tree().change_scene_to(Level1)
func _on_Level2Button_pressed() -> void:
    Audio.change_music(Audio.MusicPlayerFarm)
    Global.current_level = 2
    get_tree().change_scene_to(Level2)
func _on_Level3Button_pressed() -> void:
    Audio.change_music(Audio.MusicPlayerNorthernGlade)
    Global.current_level = 3
    get_tree().change_scene_to(Level3)
func _on_Level4Button2_pressed() -> void:
    Audio.change_music(Audio.MusicPlayerManor)
    Global.current_level = 4
    get_tree().change_scene_to(Level4)
