## Tunable difficulty settings for bot AI.
class_name DifficultyProfile
extends Resource

@export var profile_name: String = "Medium"
@export var reaction_time_sec: float = 0.25
@export var aim_noise_deg: float = 8.0
@export var aggression: float = 0.5
@export var retreat_health_threshold: float = 0.3
@export var detection_range: float = 600.0
