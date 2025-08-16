extends Node

var music_player: AudioStreamPlayer
const music = preload("res://audio/metalcore.mp3")
# https://soundcloud.com/anttu-janhunen/dark_dust_dispatcher

func _ready():
	# Créer le lecteur audio
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	# Charger ta musique
	music_player.stream = music

	# Configuration
	music_player.autoplay = true

	music_player.volume_db = -15

	# Démarrer la musique
	music_player.play()

# Fonctions utiles
func stop_music():
	music_player.stop()

func play_music():
	music_player.play()

func pause_music():
	music_player.stream_paused = true

func resume_music():
	music_player.stream_paused = false

func set_volume(volume: float):
	music_player.volume_db = volume
