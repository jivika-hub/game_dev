class_name MemoryItem
extends Interactable

## Inspectable environmental storytelling prop (family photo, child's drawing,
## letter, soil core, or manifest). Opens the cinematic memory viewer in HUD.

@export var memory_id: String = ""


func _ready() -> void:
	super._ready()
	interact_sfx = "ui_chime"
	if memory_id != "" and StoryData.MEMORIES.has(memory_id):
		if prompt_text == "Examine":
			prompt_text = "Inspect: " + str(StoryData.MEMORIES[memory_id].get("title", "Memory"))


func _on_interact(_actor: Node3D) -> void:
	if memory_id == "":
		return
	GameState.discover_memory(memory_id)
