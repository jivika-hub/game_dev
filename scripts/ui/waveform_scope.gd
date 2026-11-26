class_name WaveformScope
extends Control

## Real-time scientific dual-wave gravitational oscilloscope.
## Renders the anomalous target wave (cyan) and player-tuned carrier wave (amber/emerald).

var target_freq: float = 2.6
var target_phase: float = 1.4
var target_amp: float = 0.72

var player_freq: float = 1.6
var player_phase: float = 0.4
var player_amp: float = 0.50

var coherence: float = 0.0
var _scroll: float = 0.0


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_scroll += delta * 2.1
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 10.0 or h <= 10.0:
		return

	# Dark telemetry backdrop
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.06, 0.09, 1.0), true)

	# Scientific coordinate grid
	var grid_col := Color(0.12, 0.28, 0.34, 0.42)
	var step_x: float = w / 12.0
	var step_y: float = h / 6.0
	for i in range(1, 12):
		draw_line(Vector2(i * step_x, 0.0), Vector2(i * step_x, h), grid_col, 1.0)
	for j in range(1, 6):
		draw_line(Vector2(0.0, j * step_y), Vector2(w, j * step_y), grid_col, 1.0)

	# Center baseline
	var mid_y: float = h * 0.5
	draw_line(Vector2(0.0, mid_y), Vector2(w, mid_y), Color(0.24, 0.52, 0.60, 0.65), 1.5)

	var samples: int = 160
	var target_pts := PackedVector2Array()
	var player_pts := PackedVector2Array()
	target_pts.resize(samples)
	player_pts.resize(samples)

	var max_amp_px: float = h * 0.36
	for i in range(samples):
		var u: float = float(i) / float(samples - 1)
		var px: float = u * w
		var env: float = sin(u * PI)
		env = 0.35 + 0.65 * env

		var ty: float = (
			target_amp * sin(u * target_freq * TAU + target_phase + _scroll)
			+ 0.16 * target_amp * sin(u * target_freq * 2.0 * TAU - _scroll * 1.3)
		) * env
		var py: float = (
			player_amp * sin(u * player_freq * TAU + player_phase + _scroll)
			+ 0.16 * player_amp * sin(u * player_freq * 2.0 * TAU - _scroll * 1.3)
		) * env

		target_pts[i] = Vector2(px, mid_y - ty * max_amp_px)
		player_pts[i] = Vector2(px, mid_y - py * max_amp_px)

	# Draw anomalous target signal (outer glow + crisp cyan core)
	draw_polyline(target_pts, Color(0.20, 0.78, 0.96, 0.32), 6.0, true)
	draw_polyline(target_pts, Color(0.45, 0.92, 1.0, 0.95), 2.4, true)

	# Draw player carrier wave (amber shifting to luminous emerald-gold at lock coherence)
	var locked_blend: float = clampf((coherence - 0.80) / 0.14, 0.0, 1.0)
	var p_col := Color(0.98, 0.68, 0.28).lerp(Color(0.36, 0.98, 0.68), locked_blend)
	draw_polyline(player_pts, Color(p_col.r, p_col.g, p_col.b, 0.30), 6.0, true)
	draw_polyline(player_pts, p_col, 2.6, true)

	# Border outline
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.32, 0.68, 0.78, 0.75), false, 2.0)
