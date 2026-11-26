class_name SignalPuzzleUI
extends CanvasLayer

## Interactive scientific Gravitational Anomaly Decoding Puzzle.
## Align 3 progressive non-Keplerian harmonics (Frequency, Phase, Amplitude)
## to match the anomalous deep-space fold signature and unlock Aethelgard IV launch coordinates.

signal puzzle_solved()
signal puzzle_cancelled()

const STAGES: Array[Dictionary] = [
	{
		"name": "HARMONIC 1 / 3 — SUB-SPATIAL CARRIER",
		"target_freq": 2.6,
		"target_phase": 1.4,
		"target_amp": 0.72,
		"start_freq": 1.5,
		"start_phase": 4.2,
		"start_amp": 0.44,
		"note": "Initial carrier locked. Signal exhibits non-Keplerian standing symmetry beyond Saturn."
	},
	{
		"name": "HARMONIC 2 / 3 — GRAVITATIONAL LENSING PHASE",
		"target_freq": 4.1,
		"target_phase": 3.85,
		"target_amp": 0.86,
		"start_freq": 2.8,
		"start_phase": 0.9,
		"start_amp": 0.52,
		"note": "Lensing curvature matched. This isn't a natural gravity well—it is an engineered fold."
	},
	{
		"name": "HARMONIC 3 / 3 — PARADOX FOLD LATTICE",
		"target_freq": 5.2,
		"target_phase": 5.1,
		"target_amp": 0.62,
		"start_freq": 3.5,
		"start_phase": 2.2,
		"start_amp": 0.92,
		"note": "All three harmonics synchronized! Fold doorway vector uploaded to Aethelgard IV."
	}
]

const LOCK_THRESHOLD: float = 0.92

@onready var overlay: ColorRect = $Overlay
@onready var stage_label: Label = $Overlay/Center/Panel/Margin/VBox/StageLabel
@onready var scope: WaveformScope = $Overlay/Center/Panel/Margin/VBox/WaveformScope
@onready var coherence_label: Label = $Overlay/Center/Panel/Margin/VBox/CoherenceRow/CoherenceLabel
@onready var coherence_bar: ProgressBar = $Overlay/Center/Panel/Margin/VBox/CoherenceRow/CoherenceBar
@onready var diagnostic_label: Label = $Overlay/Center/Panel/Margin/VBox/DiagnosticLabel

@onready var freq_slider: HSlider = $Overlay/Center/Panel/Margin/VBox/FreqRow/FreqSlider
@onready var freq_val_label: Label = $Overlay/Center/Panel/Margin/VBox/FreqRow/FreqVal
@onready var phase_slider: HSlider = $Overlay/Center/Panel/Margin/VBox/PhaseRow/PhaseSlider
@onready var phase_val_label: Label = $Overlay/Center/Panel/Margin/VBox/PhaseRow/PhaseVal
@onready var amp_slider: HSlider = $Overlay/Center/Panel/Margin/VBox/AmpRow/AmpSlider
@onready var amp_val_label: Label = $Overlay/Center/Panel/Margin/VBox/AmpRow/AmpVal

@onready var log_label: Label = $Overlay/Center/Panel/Margin/VBox/LogLabel
@onready var lock_btn: Button = $Overlay/Center/Panel/Margin/VBox/ButtonRow/LockBtn
@onready var close_btn: Button = $Overlay/Center/Panel/Margin/VBox/ButtonRow/CloseBtn

var _stage_idx: int = 0
var _coherence: float = 0.0
var _solving_transition: bool = false


func _ready() -> void:
	layer = 30
	overlay.visible = false

	freq_slider.value_changed.connect(_on_sliders_changed)
	phase_slider.value_changed.connect(_on_sliders_changed)
	amp_slider.value_changed.connect(_on_sliders_changed)
	lock_btn.pressed.connect(_on_lock_pressed)
	close_btn.pressed.connect(_on_close_pressed)

	GameState.puzzle_requested.connect(open_puzzle)


func _unhandled_input(event: InputEvent) -> void:
	if not overlay.visible:
		return
	if event.is_action_pressed("pause"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func open_puzzle() -> void:
	if bool(GameState.get_flag("anomaly_decoded", false)):
		return
	_stage_idx = 0
	_solving_transition = false
	log_label.text = "Align the amber carrier wave with the cyan gravitational anomaly until Coherence exceeds 92%."
	_load_stage(0)
	overlay.visible = true
	GameState.set_mode(GameState.Mode.PUZZLE)
	AudioManager.play_sfx("ui_chime", -7.0)


func _load_stage(idx: int) -> void:
	_stage_idx = idx
	var st: Dictionary = STAGES[idx]
	stage_label.text = str(st["name"])

	scope.target_freq = float(st["target_freq"])
	scope.target_phase = float(st["target_phase"])
	scope.target_amp = float(st["target_amp"])

	freq_slider.set_value_no_signal(float(st["start_freq"]))
	phase_slider.set_value_no_signal(float(st["start_phase"]))
	amp_slider.set_value_no_signal(float(st["start_amp"]))

	_recompute_coherence()


func _on_sliders_changed(_val: float) -> void:
	_recompute_coherence()


func _recompute_coherence() -> void:
	var pf: float = float(freq_slider.value)
	var pp: float = float(phase_slider.value)
	var pa: float = float(amp_slider.value)

	scope.player_freq = pf
	scope.player_phase = pp
	scope.player_amp = pa

	freq_val_label.text = "%.2f Hz" % pf
	phase_val_label.text = "%.2f rad" % pp
	amp_val_label.text = "%.2f g-u" % pa

	var df: float = absf(pf - scope.target_freq) / 2.6
	var raw_dp: float = absf(pp - scope.target_phase)
	var wrap_dp: float = minf(raw_dp, TAU - raw_dp)
	var dp: float = wrap_dp / PI
	var da: float = absf(pa - scope.target_amp) / 0.55

	var err: float = df * 0.42 + dp * 0.36 + da * 0.22
	_coherence = clampf(1.0 - err, 0.0, 1.0)
	scope.coherence = _coherence

	var pct: float = _coherence * 100.0
	coherence_label.text = "COHERENCE: %.1f%%" % pct
	coherence_bar.value = pct

	var ready_to_lock: bool = (_coherence >= LOCK_THRESHOLD and not _solving_transition)
	lock_btn.disabled = not ready_to_lock
	lock_btn.text = "LOCK HARMONIC [READY]" if ready_to_lock else "ALIGN SIGNAL (>= 92%)"

	# Helpful scientific diagnostics so players get crisp feedback
	var hints: Array[String] = []
	if absf(pf - scope.target_freq) > 0.22:
		hints.append("Frequency " + ("too LOW" if pf < scope.target_freq else "too HIGH"))
	else:
		hints.append("Frequency ALIGNED")

	if wrap_dp > 0.35:
		hints.append("Phase OFF-AXIS")
	else:
		hints.append("Phase ALIGNED")

	if absf(pa - scope.target_amp) > 0.08:
		hints.append("Amplitude " + ("too LOW" if pa < scope.target_amp else "too HIGH"))
	else:
		hints.append("Amplitude ALIGNED")

	diagnostic_label.text = "INTERFEROMETER READOUT:  " + "  |  ".join(hints)


func _on_lock_pressed() -> void:
	if _coherence < LOCK_THRESHOLD or _solving_transition:
		return
	_solving_transition = true
	lock_btn.disabled = true
	AudioManager.play_sfx("puzzle_lock", -4.0)

	var st: Dictionary = STAGES[_stage_idx]
	log_label.text = str(st["note"])

	await get_tree().create_timer(1.15).timeout

	if _stage_idx + 1 < STAGES.size():
		_solving_transition = false
		_load_stage(_stage_idx + 1)
	else:
		# All 3 harmonics decoded!
		overlay.visible = false
		_solving_transition = false
		GameState.set_flag("anomaly_decoded", true)
		GameState.set_mode(GameState.Mode.EXPLORING)
		puzzle_solved.emit()


func _on_close_pressed() -> void:
	if _solving_transition:
		return
	AudioManager.play_sfx("interact_click", -8.0)
	overlay.visible = false
	GameState.set_mode(GameState.Mode.EXPLORING)
	puzzle_cancelled.emit()
