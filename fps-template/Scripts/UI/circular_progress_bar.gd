class_name CircularProgressBar
extends Control
## A basic circular (radial) progress bar drawn with a plain white ring.
## Set `progress` (0.0 - 1.0) to fill the ring clockwise from the top.

@export_range(0.0, 1.0, 0.001) var progress: float = 0.75:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

## Thickness of the ring in pixels.
@export_range(1.0, 64.0, 0.5) var ring_thickness: float = 10.0:
	set(value):
		ring_thickness = maxf(value, 1.0)
		queue_redraw()

## Colour of the filled portion.
@export var fill_color: Color = Color(1, 1, 1, 1):
	set(value):
		fill_color = value
		queue_redraw()

## Colour of the empty track behind the fill.
@export var track_color: Color = Color(1, 1, 1, 0.15):
	set(value):
		track_color = value
		queue_redraw()

## Where the fill starts, in degrees (-90 is the top).
@export var start_angle_deg: float = -90.0:
	set(value):
		start_angle_deg = value
		queue_redraw()

@export var clockwise: bool = true:
	set(value):
		clockwise = value
		queue_redraw()


func set_progress(value: float) -> void:
	progress = value


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - ring_thickness * 0.5
	if radius <= 0.0:
		return

	var point_count: int = maxi(48, int(radius))

	# Empty track.
	if track_color.a > 0.0:
		draw_arc(center, radius, 0.0, TAU, point_count, track_color, ring_thickness, true)

	# Filled portion.
	if progress <= 0.0:
		return
	var sweep: float = TAU * progress
	var from_angle: float = deg_to_rad(start_angle_deg)
	var to_angle: float = from_angle + (sweep if clockwise else -sweep)
	draw_arc(
		center,
		radius,
		from_angle,
		to_angle,
		maxi(3, int(point_count * progress)),
		fill_color,
		ring_thickness,
		true
	)