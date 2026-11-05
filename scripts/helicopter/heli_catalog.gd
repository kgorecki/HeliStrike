class_name HeliCatalog
extends RefCounted

const IDS: PackedStringArray = ["apache", "defender", "bell222"]


static func spec(id: String) -> Dictionary:
	match id:
		"defender":
			return {
				"id": "defender",
				"title": "AH-6 LITTLE BIRD",
				"role": "LIGHT ATTACK",
				"blurb": "Night-stalker scout. Tiny, vicious, and hard to hit if you keep it moving.",
				"ordnance": "M134 minigun  ·  2 pylons",
				"cannon_max": 800,
				"missile_slots": 2,
				"cannon_cd": 0.05,
				"missile_cd": 0.85,
				"max_thrust": 18.6,
				"max_speed": 76.0,
				"hover": 0.58,
				"hull": 70.0,
				"pitch_rate": 1.38,
				"roll_rate": 1.62,
				"yaw_rate": 1.85,
				"rotor_spin": 36.0,
				"preview_y": 0.2,
			}
		"bell222":
			return {
				"id": "bell222",
				"title": "BELL 222",
				"role": "ARMED UTILITY",
				"blurb": "Twin-engine executive airframe pressed into gunship duty. Fast in a straight line.",
				"ordnance": "Chin 20mm  ·  3 pylons",
				"cannon_max": 320,
				"missile_slots": 3,
				"cannon_cd": 0.11,
				"missile_cd": 1.0,
				"max_thrust": 17.4,
				"max_speed": 92.0,
				"hover": 0.60,
				"hull": 85.0,
				"pitch_rate": 1.08,
				"roll_rate": 1.22,
				"yaw_rate": 1.42,
				"rotor_spin": 22.0,
				"preview_y": 0.25,
			}
		_:
			return {
				"id": "apache",
				"title": "AH-64E APACHE",
				"role": "HEAVY ATTACK",
				"blurb": "Tandem cockpit tank-killer. Best standoff punch and the toughest airframe.",
				"ordnance": "M230 30mm  ·  4 pylons",
				"cannon_max": 450,
				"missile_slots": 4,
				"cannon_cd": 0.09,
				"missile_cd": 1.15,
				"max_thrust": 16.8,
				"max_speed": 82.0,
				"hover": 0.62,
				"hull": 100.0,
				"pitch_rate": 0.95,
				"roll_rate": 1.15,
				"yaw_rate": 1.35,
				"rotor_spin": 28.0,
				"preview_y": 0.45,
			}


static func clamp_id(id: String) -> String:
	if id in IDS:
		return id
	return "apache"


static func apply(heli: Helicopter, id: String) -> Dictionary:
	var data := spec(clamp_id(id))
	heli.heli_id = str(data["id"])
	heli.hover_collective = float(data["hover"])
	heli.max_thrust = float(data["max_thrust"])
	heli.max_speed = float(data["max_speed"])
	heli.pitch_rate = float(data["pitch_rate"])
	heli.roll_rate = float(data["roll_rate"])
	heli.yaw_rate = float(data["yaw_rate"])
	heli.cannon_max = int(data["cannon_max"])
	heli.missile_max = int(data["missile_slots"])
	heli.cannon_interval = float(data["cannon_cd"])
	heli.missile_interval = float(data["missile_cd"])
	heli.rotor_spin_rate = float(data["rotor_spin"])
	heli.hull = float(data["hull"])
	heli.cannon_ammo = heli.cannon_max
	return data
