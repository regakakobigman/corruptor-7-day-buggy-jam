extends Node2D


func _ready() -> void:
    pass

func _on_Area2D_body_entered(body: PhysicsBody2D) -> void:
    if body.is_in_group("Player"):
        Audio.change_music(Audio.MusicPlayerCottages)
        Global.died = true
        Audio.play_effect(Audio.effects.died)
        if Global.current_score > Global.get("high_score_level_" + Global.current_level as String):
            Global.set("high_score_level_" + Global.current_level as String, Global.current_score)
        Global.current_score = 0
        get_tree().change_scene_to(Global.MainMenu)
