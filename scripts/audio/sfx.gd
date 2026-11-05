extends Node

var _rotor: AudioStreamWAV
var _cannon: AudioStreamWAV
var _missile: AudioStreamWAV
var _explosion: AudioStreamWAV
var _click: AudioStreamWAV

func _ready() -> void:
	_rotor = _tone_noise(22050, 1.0, 22.0, 0.22, true)
	_cannon = _burst(18000, 0.06, 900.0, 0.55)
	_missile = _whoosh(22050, 0.55)
	_explosion = _noise_hit(18000, 0.45)
	_click = _burst(16000, 0.04, 420.0, 0.35)


func play_rotor(parent: Node, volume_db: float = -14.0) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = _rotor
	player.volume_db = volume_db
	player.unit_size = 18.0
	player.max_distance = 400.0
	player.autoplay = true
	parent.add_child(player)
	player.play()
	return player


func play_3d(parent: Node, kind: String, world_pos: Vector3, volume_db: float = 0.0) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = _stream_for(kind)
	player.volume_db = volume_db
	player.unit_size = 12.0
	player.max_distance = 350.0
	parent.add_child(player)
	player.global_position = world_pos
	player.finished.connect(player.queue_free)
	player.play()


func play_ui(kind: String = "click") -> void:
	var player := AudioStreamPlayer.new()
	player.stream = _click if kind == "click" else _stream_for(kind)
	player.volume_db = -8.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _stream_for(kind: String) -> AudioStreamWAV:
	match kind:
		"cannon":
			return _cannon
		"missile":
			return _missile
		"explosion":
			return _explosion
		_:
			return _click


func _tone_noise(rate: int, seconds: float, hz: float, amp: float, loop: bool) -> AudioStreamWAV:
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / float(rate)
		var v := sin(t * hz * TAU) * amp
		v += sin(t * hz * 2.0 * TAU) * amp * 0.4
		v += (randf() - 0.5) * amp * 0.55
		data[i] = _to_u8(v)
	return _wav(data, rate, loop)


func _burst(rate: int, seconds: float, hz: float, amp: float) -> AudioStreamWAV:
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var env := (1.0 - t) * (1.0 - t)
		var v := sin(float(i) / float(rate) * hz * TAU) * amp * env
		v += (randf() - 0.5) * amp * env * 0.7
		data[i] = _to_u8(v)
	return _wav(data, rate, false)


func _whoosh(rate: int, seconds: float) -> AudioStreamWAV:
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var env := sin(t * PI)
		var hz := lerpf(180.0, 70.0, t)
		var v := sin(float(i) / float(rate) * hz * TAU) * 0.28 * env
		v += (randf() - 0.5) * 0.35 * env
		data[i] = _to_u8(v)
	return _wav(data, rate, false)


func _noise_hit(rate: int, seconds: float) -> AudioStreamWAV:
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var env := exp(-t * 6.0)
		var v := (randf() - 0.5) * env + sin(float(i) / float(rate) * 55.0 * TAU) * 0.25 * env
		data[i] = _to_u8(v)
	return _wav(data, rate, false)


func _wav(data: PackedByteArray, rate: int, loop: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = rate
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = data.size()
	return stream


func _to_u8(v: float) -> int:
	return clampi(int(v * 127.0 + 128.0), 0, 255)
