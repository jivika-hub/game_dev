class_name DaughterNPC
extends StaticBody3D

## Maya Vance — Dr. Elias Vance's 10-year-old daughter.
## Gently tracks Elias when nearby and initiates story-controlled departure dialogue.

signal conversation_completed()

@onready var visuals: CharacterVisuals = $VisualRoot
@onready var interactable: Interactable = $InteractArea

var _player_ref: Node3D = null


func _ready() -> void:
	add_to_group("npcs")
	interactable.prompt_text = "Speak with Maya"
	interactable.interacted.connect(_on_interacted)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)


func _process(delta: float) -> void:
	if visuals != null:
		visuals.update_locomotion(delta, 0.0, 3.0)

	if _player_ref == null or not is_instance_valid(_player_ref):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player_ref = players[0] as Node3D

	if _player_ref != null and is_instance_valid(_player_ref):
		var dist: float = global_position.distance_to(_player_ref.global_position)
		if dist < 6.5:
			var to_player: Vector3 = _player_ref.global_position - global_position
			to_player.y = 0.0
			if to_player.length() > 0.2:
				var desired_yaw: float = atan2(-to_player.x, -to_player.z)
				visuals.rotation.y = lerp_angle(visuals.rotation.y, desired_yaw, clampf(delta * 3.5, 0.0, 1.0))
			visuals.look_toward_world_point(_player_ref.global_position + Vector3(0.0, 1.55, 0.0), delta)


func _on_interacted(_actor: Node3D) -> void:
	if bool(GameState.get_flag("talked_to_maya", false)):
		DialogueManager.start_dialogue("maya_followup")
	else:
		DialogueManager.start_dialogue("maya_goodbye")


func _on_dialogue_finished(dialogue_id: String) -> void:
	if dialogue_id == "maya_goodbye":
		GameState.set_flag("talked_to_maya", true)
		interactable.prompt_text = "Speak with Maya again"
		conversation_completed.emit()
