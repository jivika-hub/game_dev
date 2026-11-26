class_name AnomalyConsole
extends Interactable

## Horizon Outpost 09 Telemetry Array console.
## Launches the interactive Gravitational Anomaly Scientific Puzzle.


func _ready() -> void:
	super._ready()
	prompt_text = "Analyze Gravitational Anomaly"
	if Engine.is_editor_hint():
		return
	GameState.flag_changed.connect(_on_flag_changed)
	_sync_state()


func _on_flag_changed(flag_name: String, _value: Variant) -> void:
	if flag_name == "anomaly_decoded":
		_sync_state()


func _sync_state() -> void:
	if bool(GameState.get_flag("anomaly_decoded", false)):
		prompt_text = "Review Decoded Fold Coordinates (Complete)"


func _on_interact(_actor: Node3D) -> void:
	if bool(GameState.get_flag("anomaly_decoded", false)):
		GameState.notify("Gravitational fold vector already locked and uploaded to Aethelgard IV.")
		return
	GameState.request_puzzle()
