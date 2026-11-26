extends Node

## MissionManager autoload managing active chapter objectives,
## objective progression history, and 3D world waypoints.

signal mission_started(mission_id: String, title: String, objective: String, hint: String)
signal mission_completed(mission_id: String)
signal waypoint_updated(world_position: Vector3, label: String, visible: bool)

var active_mission_id: String = ""
var active_title: String = ""
var active_objective: String = ""
var active_hint: String = ""
var completed_missions: Array[String] = []

var waypoint_position: Vector3 = Vector3.ZERO
var waypoint_label: String = ""
var waypoint_visible: bool = false


func reset_missions() -> void:
	active_mission_id = ""
	active_title = ""
	active_objective = ""
	active_hint = ""
	completed_missions.clear()
	clear_waypoint()


func start_mission(mission_id: String, target_pos: Vector3 = Vector3.ZERO, target_label: String = "", show_waypoint: bool = false) -> void:
	if active_mission_id != "" and active_mission_id != mission_id:
		if not completed_missions.has(active_mission_id):
			completed_missions.append(active_mission_id)
			mission_completed.emit(active_mission_id)

	active_mission_id = mission_id
	var info: Dictionary = StoryData.MISSIONS.get(mission_id, {})
	active_title = str(info.get("title", "OBJECTIVE"))
	active_objective = str(info.get("objective", mission_id))
	active_hint = str(info.get("hint", ""))

	mission_started.emit(active_mission_id, active_title, active_objective, active_hint)
	if show_waypoint:
		set_waypoint(target_pos, target_label)
	else:
		clear_waypoint()


func complete_active_mission() -> void:
	if active_mission_id == "":
		return
	var finished_id: String = active_mission_id
	if not completed_missions.has(finished_id):
		completed_missions.append(finished_id)
	active_mission_id = ""
	clear_waypoint()
	mission_completed.emit(finished_id)


func set_waypoint(world_position: Vector3, label: String = "") -> void:
	waypoint_position = world_position
	waypoint_label = label
	waypoint_visible = true
	waypoint_updated.emit(waypoint_position, waypoint_label, true)


func clear_waypoint() -> void:
	waypoint_visible = false
	waypoint_label = ""
	waypoint_updated.emit(Vector3.ZERO, "", false)


func is_mission_completed(mission_id: String) -> bool:
	return completed_missions.has(mission_id)


func serialize() -> Dictionary:
	return {
		"active_mission_id": active_mission_id,
		"completed_missions": completed_missions.duplicate()
	}


func deserialize(data: Dictionary) -> void:
	reset_missions()
	var comp: Variant = data.get("completed_missions", [])
	if typeof(comp) == TYPE_ARRAY:
		for item in comp:
			completed_missions.append(str(item))
	var active_id: String = str(data.get("active_mission_id", ""))
	if active_id != "":
		active_mission_id = active_id
		var info: Dictionary = StoryData.MISSIONS.get(active_id, {})
		active_title = str(info.get("title", "OBJECTIVE"))
		active_objective = str(info.get("objective", active_id))
		active_hint = str(info.get("hint", ""))
