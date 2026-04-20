## Global event bus for decoupled communication between systems.
## Access via the EventBus autoload singleton.
extends Node

# Combat events
signal player_damaged(victim_id: int, attacker_id: int, damage: float, weapon_name: String)
signal player_died(victim_id: int, killer_id: int, weapon_name: String)
signal player_respawned(player_id: int, position: Vector2)

# Weapon events
signal weapon_fired(player_id: int, weapon_name: String)
signal weapon_picked_up(player_id: int, weapon_name: String)
signal weapon_reloaded(player_id: int, weapon_name: String)

# Pickup events
signal health_picked_up(player_id: int, heal_amount: float)
signal pickup_spawned(pickup_type: String, position: Vector2)
signal pickup_collected(pickup_type: String, position: Vector2)

# Match events
signal match_started(mode: String, map_name: String)
signal match_ended(results: Dictionary)
signal score_updated(player_id: int, kills: int, deaths: int)

# UI events
signal kill_feed_entry(killer_name: String, victim_name: String, weapon_name: String)
signal notification_requested(text: String, duration: float)
