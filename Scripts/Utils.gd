extends Node

func play_if_not_playing(AnimPlayer: AnimationPlayer, animation: String) -> void:
    if not is_playing(AnimPlayer, animation):
        AnimPlayer.play(animation)

func is_playing(AnimPlayer: AnimationPlayer, animation: String) -> bool:
    return AnimPlayer.is_playing() and AnimPlayer.current_animation == animation

# This was implemented in 3.2 as RandomNumberGenerator.randfn. Better to use that instead
func gaussian(mean: float, deviation: float, return_float=false):
    var x1 := 0.0
    var x2 := 0.0
    var w := 0.0
    while true:
        x1 = rand_range(0, 2) - 1
        x2 = rand_range(0, 2) - 1
        w = x1*x1 + x2*x2
        if 0 < w && w < 1:
            break
    w = sqrt(-2 * log(w)/w)
    if return_float:
        return mean + deviation * x1 * w
    else:
        return floor(mean + deviation * x1 * w) as int
