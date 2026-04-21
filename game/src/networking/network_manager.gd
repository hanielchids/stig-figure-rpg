## Manages multiplayer connections — hosting, joining, disconnecting.
## Access via the NetworkManager autoload singleton.
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_succeeded()
signal connection_failed()
signal server_disconnected()

const DEFAULT_PORT: int = 9876
const MAX_PLAYERS: int = 8

var peer: ENetMultiplayerPeer = null
var is_host: bool = false
var is_online: bool = false
var connected_peers: Array[int] = []


func host_game(port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		push_error("Failed to create server: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	is_host = true
	is_online = true

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[Network] Hosting on port %d (peer_id: %d)" % [port, multiplayer.get_unique_id()])
	return OK


func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		push_error("Failed to create client: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	is_host = false
	is_online = true

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	print("[Network] Connecting to %s:%d" % [address, port])
	return OK


func disconnect_game() -> void:
	if peer:
		multiplayer.multiplayer_peer = null
		peer = null
	is_host = false
	is_online = false
	connected_peers.clear()
	print("[Network] Disconnected")


func is_server() -> bool:
	return is_online and multiplayer.is_server()


func get_my_id() -> int:
	if is_online:
		return multiplayer.get_unique_id()
	return 1  # Single-player default


func _on_peer_connected(id: int) -> void:
	connected_peers.append(id)
	player_connected.emit(id)
	print("[Network] Peer connected: %d (total: %d)" % [id, connected_peers.size()])


func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	player_disconnected.emit(id)
	print("[Network] Peer disconnected: %d (total: %d)" % [id, connected_peers.size()])


func _on_connected_to_server() -> void:
	print("[Network] Connected to server (my id: %d)" % multiplayer.get_unique_id())
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	push_warning("[Network] Connection failed")
	disconnect_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	push_warning("[Network] Server disconnected")
	disconnect_game()
	server_disconnected.emit()
