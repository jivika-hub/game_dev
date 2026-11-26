class_name LaunchTerminal
extends Interactable

## Launch Control Terminal overlooking Aethelgard IV.
## Unlocks after decoding the gravitational anomaly; triggers Chapter 1's launch cutscene.

signal launch_requested()


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		prompt_text = "Launch Terminal [LOCKED — Decode Anomaly First]"
		return
	GameState.flag_changed.connect(_on_flag_changed)
	_refresh_prompt()


func _on_flag_changed(flag_name: String, _value: Variant) -> void:
	if flag_name == "anomaly_decoded":
		_refresh_prompt()


func _refresh_prompt() -> void:
	if bool(GameState.get_flag("anomaly_decoded", false)):
		prompt_text = "Board & Launch Aethelgard IV"
	else:
		prompt_text = "Launch Terminal [LOCKED — Decode Anomaly First]"


func _on_interact(_actor: Node3D) -> void:
	if not bool(GameState.get_flag("anomaly_decoded", false)):
		GameState.notify("Navigation core locked: decode the gravitational anomaly at the Telemetry Array first.")
		return
	if bool(GameState.get_flag("launch_started", false)):
		return
	GameState.set_flag("launch_started", true)
	interaction_enabled = false
	launch_requested.emit()
