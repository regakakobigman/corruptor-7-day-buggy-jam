extends Node

"""
This is the corruptor.

If you haven't seen video game corruptions, look them up. They're a ton of fun
Real corruption involves editing memory addresses either randomly or according
to a set of specific rules, like piping one addresses value to another.

Unfortunately that's a little too extreme for an actual, playable game, so
instead this project uses the 'corruptor': a director of all things chaotic.

Many nodes are in the 'corruptable' group and expose some common variables
detailing how they should be corrupted. For instance, the player could get a
triple jump, but they can barely accelerate. There are visual effects related
to corruption, too. Shaders could probably make everything really fun, but I
didn't have time for that.
"""

var tile_move_amount = 30
var tile_rotate_amount = 10
var tile_scale_amount = 0.2

func _ready() -> void:
    pass

func corrupt_everything() -> void:
    for corruptable in get_tree().get_nodes_in_group("Corruptable"):
        corrupt(corruptable)

func corrupt_something() -> void:
    var corruptables = get_tree().get_nodes_in_group("Corruptable")
    corrupt(corruptables[randi() % corruptables.size()])

func corrupt(corruptable: Object) -> void:
    if "corrupt_targets" in corruptable:
        corrupt_everything_on_object(corruptable)
    elif corruptable.is_in_group("CorruptableSheetSprite"):
        corrupt_sheet_sprite(corruptable)
    elif corruptable.is_in_group("CorruptableTile"):
        corrupt_tile(corruptable)

func corrupt_everything_on_object(corruptable: Object) -> void:
    assert corruptable
    assert "corrupt_targets" in corruptable
    var targets = corruptable.corrupt_targets
    for property in targets.keys():
        var stats = targets[property]
        var value = corrupt_value(stats)
        corruptable.set(property, value)

func corrupt_something_on_object(corruptable: Object) -> void:
    assert corruptable
    assert "corrupt_targets" in corruptable
    var targets = corruptable.corrupt_targets
    var property = targets.keys()[randi() % targets.size()]
    var stats = targets[property]
    var value = corrupt_value(stats)
    
    # if the player's stats changed, give the player a visual notification
    if corruptable.is_in_group("Player") and corruptable.get(property) != value:
        var prev_value = corruptable.get(property)
        var modifier = "++" if value > prev_value else "--"
        var string = property.capitalize().replace(" ", "") + modifier
        var StatNotif = Global.PlayerStatChangeNotification.instance()
        StatNotif.get_node("Label").text = string
        Global.Player.add_child(StatNotif)
    corruptable.set(property, value)

func corrupt_sheet_sprite(corruptable: Sprite) -> void:
    corruptable.frame = randi() % (corruptable.hframes * corruptable.vframes)
    match randi() % 3:
        0: corruptable.texture = Global.spritesheet_platformer_normal
        1: corruptable.texture = Global.spritesheet_platformer_lossy
        2: corruptable.texture = Global.spritesheet_platformer_corrupt

func corrupt_tile(corruptable: KinematicBody2D) -> void:
    corruptable.position += Vector2((2 * randf() - 1) * tile_move_amount, (2 * randf() - 0.5) * tile_move_amount)
    corruptable.rotation += (2 * randf() - 1) * deg2rad(tile_rotate_amount)
    corruptable.scale.x += (2 * randf() - 1) * tile_scale_amount
    corruptable.scale.y += (2 * randf() - 1) * tile_scale_amount
    corruptable.scale.x = clamp(corruptable.scale.x, 0.1, 5.0)
    corruptable.scale.y = clamp(corruptable.scale.y, 0.1, 5.0)

func corrupt_value(stats: Dictionary):
    return clamp(Utils.gaussian(stats.mean, stats.deviation, stats.mean is float), stats.min, stats.max)
