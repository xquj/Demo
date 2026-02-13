class_name MatchState

var selected_group: Array[Card_Base] = []
var discard_group: Array[Card_Base] = []
var players: Array[PlayerEntity] = []
var player_activity: PlayerEntity = null
var local_player: PlayerEntity = null
var current_play_turn: int = 0
var round: int = 0
var game_progress: int = 1
var detailed_card: Card_Base = null
var current_state: int = 0
var selected_card: Card_Base = null
