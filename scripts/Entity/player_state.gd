class_name PlayerState

var name: String = ""
var team_id: int = 0
var is_active: bool = false
var item_notes: Array[String] = []
var score: int = 0
var health: int = 100
var defense: int = 100
var waitingGroup: Array[Card_Base] = []
var hand_cards: Array[Card_Base] = []
var showing_cards: Array[Card_Base] = []
var can_combo: bool = false
