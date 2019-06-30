extends Area2D

var powerup_amount = 100
var tween_time = 0.8
var fade_time = 1.2
var collected = false

func _ready() -> void:
    _on_Tween_tween_completed(null, "")

func _on_TimePowerup_body_entered(body: PhysicsBody2D) -> void:
    if body.is_in_group("Player") and not collected:
        collected = true
        Global.UI.get_node("C/TP").value += powerup_amount
        Global.UI.sigh_visual_effect()
        Global.current_score += 1

func _on_Tween_tween_completed(object: Object, key: NodePath) -> void:
    if not collected:
        $Tween.interpolate_property(self, "rotation", rotation, rotation + PI / 2, tween_time, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
        $Tween.start()
    else:
        $Tween.interpolate_property(self, "modulate", modulate, Color(1.0, 1.0, 1.0, 0.0), fade_time, Tween.TRANS_LINEAR, Tween.EASE_OUT)
        $Tween.start()
        yield($Tween, "tween_completed")
        queue_free()
