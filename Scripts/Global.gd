extends Node

signal screen_size_changed

const MainMenu = preload("res://Scenes/MainMenu.tscn")

const PlayerStatChangeNotification = preload("res://Scenes/PlayerStatChangeNotification.tscn")

const spritesheet_platformer_normal = preload("res://praise kenney/platformer-pack-redux-360-assets/spritesheet_complete.png")
const spritesheet_platformer_lossy = preload("res://praise kenney/platformer-pack-redux-360-assets/spritesheet_complete_lossy.png")
const spritesheet_platformer_corrupt = preload("res://praise kenney/platformer-pack-redux-360-assets/spritesheet_complete_corrupted.png")

var screen_size = OS.get_window_size()
var Player: KinematicBody2D
var UI: CanvasLayer
var died := false

var high_score_level_1 := 0
var high_score_level_2 := 0
var high_score_level_3 := 0
var high_score_level_4 := 0
var current_level = 0

var current_score = 0

func _ready():
    randomize()

func _process(delta: float) -> void:
    if OS.get_window_size() != screen_size:
        screen_size = OS.get_window_size()
        emit_signal("screen_size_changed")
