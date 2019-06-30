extends Node

# I haven't touched audio before, so this is probably very sloppy

const EFFECT_VOLUME = 0

const effects = {
    tick = {
        source = preload("res://praise freesound/160052__jorickhoofd__metal-short-tick.wav"),
        bus = "Clock",
        volume_db = EFFECT_VOLUME - 2,
        pitch_scale = 1.0,
        random_pitch = true,
        random_pitch_amount = 1.01,
    },
    jump = {
        source = preload("res://praise freesound/386645__jalastram__sfx-jump-17.wav"),
        bus = "Effect",
        volume_db = EFFECT_VOLUME,
        pitch_scale = 1.0,
        random_pitch = false,
        random_pitch_amount = 1.0,
    },
    multijump = {
        source = preload("res://praise freesound/386642__jalastram__sfx-jump-12.wav"),
        bus = "Effect",
        volume_db = EFFECT_VOLUME,
        pitch_scale = 1.0,
        random_pitch = false,
        random_pitch_amount = 1.0,
    },
    sigh = {
        source = preload("res://praise freesound/389998__morganveilleux__male-long-sigh-close.wav"),
        bus = "Effect",
        volume_db = EFFECT_VOLUME + 2,
        pitch_scale = 1.0,
        random_pitch = false,
        random_pitch_amount = 1.0,
    },
    died = {
        source = preload("res://praise freesound/317485__doty21__long-glitch-4.wav"),
        bus = "Effect",
        volume_db = EFFECT_VOLUME,
        pitch_scale = 1.0,
        random_pitch = false,
        random_pitch_amount = 1.0
    }
}

const music = {
    cottages = preload("res://praise kevin macleod/cottages.ogg"),
    farm = preload("res://praise kevin macleod/farm.ogg"),
    manor = preload("res://praise kevin macleod/manor.ogg"),
    northern_glade = preload("res://praise kevin macleod/northern_glade.ogg"),
}

# this is ugly but works for crossfading music
# a much better method should be used instead
var MusicPlayerCottages = AudioStreamPlayer.new()
var MusicPlayerFarm = AudioStreamPlayer.new()
var MusicPlayerManor = AudioStreamPlayer.new()
var MusicPlayerNorthernGlade = AudioStreamPlayer.new()
var MusicPlayers = [MusicPlayerCottages, MusicPlayerFarm, MusicPlayerManor, MusicPlayerNorthernGlade]

var MusicTween = Tween.new()

var current_song: AudioStreamPlayer
var fade_time = 5.0

#const MIN_MUSIC_LENGTH = 234 - 10
const MUSIC_VOLUME = 0

func _ready() -> void:
    for MusicPlayer in MusicPlayers:
        MusicPlayer.autoplay = true
        MusicPlayer.bus = "Music"
        MusicPlayer.volume_db = MUSIC_VOLUME
        add_child(MusicPlayer)
    MusicPlayerCottages.stream = music.cottages
    MusicPlayerFarm.stream = music.farm
    MusicPlayerManor.stream = music.manor
    MusicPlayerNorthernGlade.stream = music.northern_glade
    MusicPlayerCottages.play()
    current_song = MusicPlayerCottages
    add_child(MusicTween)

func play_effect(effect: Dictionary) -> void:
    var effect_player = AudioStreamPlayer.new()
    var stream
    if effect.random_pitch:
        stream = AudioStreamRandomPitch.new()
        stream.audio_stream = effect.source
        stream.random_pitch = effect.random_pitch_amount
    else:
        stream = effect.source
    effect_player.stream = stream
    effect_player.volume_db = effect.volume_db
    effect_player.bus = effect.bus
    effect_player.pitch_scale = effect.pitch_scale
    add_child(effect_player)
    effect_player.play()
    effect_player.connect("finished", effect_player, "queue_free")

func change_music(NewMusicPlayer: AudioStreamPlayer) -> void:
    for MusicPlayer in MusicPlayers:
        if MusicPlayer == NewMusicPlayer:
            pass
            # unfortunately had to comment out this crossfade effect
            # couldn't get it to work before the deadline
            # but the beats should be synced on 3/4 of the songs so it should sound clean
            #MusicTween.interpolate_property(MusicPlayer, "volume_db", \
            #MusicPlayer.volume_db, MUSIC_VOLUME, fade_time, Tween.TRANS_SINE, Tween.EASE_OUT)
        else:
            pass
            #MusicTween.interpolate_property(MusicPlayer, "volume_db", \
            #MusicPlayer.volume_db, -60, fade_time, Tween.TRANS_SINE, Tween.EASE_OUT)
            MusicPlayer.stop()
        MusicTween.interpolate_property(MusicPlayer, "pitch_scale", \
        current_song.pitch_scale, 1, fade_time / 2, Tween.TRANS_SINE, Tween.EASE_IN)
    MusicTween.start()
    var p = current_song.get_playback_position()
    current_song.stop()
    NewMusicPlayer.play(p if p < 300 else 0)
    current_song = NewMusicPlayer
    yield(get_tree().create_timer(fade_time), "timeout")
    
