class_name MissileCatalog
extends RefCounted

const IDS: PackedStringArray = ["hellfire", "spike", "hydra", "apkws"]


static func spec(id: String) -> Dictionary:
	match id:
		"spike":
			return {
				"id": "spike",
				"title": "SPIKE-LR",
				"short": "SPIKE",
				"kind": "SINGLE",
				"blurb": "Light lock-on missile. Drops a SAM or a radar. A tank survives unless you follow with the gun.",
				"count": 1,
				"damage": 75.0,
				"range": 900.0,
				"speed": 190.0,
				"accel": 80.0,
				"launch_speed": 45.0,
				"guided": true,
				"spread_deg": 0.0,
				"scale": 0.78,
			}
		"hydra":
			return {
				"id": "hydra",
				"title": "HYDRA 70",
				"short": "HYDRA",
				"kind": "CLUSTER",
				"blurb": "Unguided seven-rocket pod. Each trigger fires one rocket, with a little spread. Use it close.",
				"count": 7,
				"damage": 26.0,
				"range": 480.0,
				"speed": 250.0,
				"accel": 150.0,
				"launch_speed": 80.0,
				"guided": false,
				"spread_deg": 2.2,
				"shot_cd": 0.12,
				"scale": 0.48,
			}
		"apkws":
			return {
				"id": "apkws",
				"title": "APKWS",
				"short": "APKWS",
				"kind": "CLUSTER",
				"blurb": "Four guided rockets. Each trigger fires one. They home on a lock, but each warhead is light.",
				"count": 4,
				"damage": 32.0,
				"range": 750.0,
				"speed": 230.0,
				"accel": 120.0,
				"launch_speed": 60.0,
				"guided": true,
				"spread_deg": 2.0,
				"shot_cd": 0.16,
				"scale": 0.55,
			}
		_:
			return {
				"id": "hellfire",
				"title": "AGM-114 HELLFIRE",
				"short": "HELLFIRE",
				"kind": "SINGLE",
				"blurb": "Heavy anti-tank missile. One round on the rail. Longest reach, and a hit kills armor outright.",
				"count": 1,
				"damage": 140.0,
				"range": 1500.0,
				"speed": 210.0,
				"accel": 70.0,
				"launch_speed": 36.0,
				"guided": true,
				"spread_deg": 0.0,
				"scale": 1.12,
			}


static func clamp_id(id: String) -> String:
	if id in IDS:
		return id
	return "hellfire"


static func default_for(heli_id: String) -> Array:
	var slots := int(HeliCatalog.spec(heli_id)["missile_slots"])
	var pattern: Array
	match HeliCatalog.clamp_id(heli_id):
		"defender":
			pattern = ["hydra", "hydra"]
		"bell222":
			pattern = ["spike", "apkws", "spike"]
		_:
			pattern = ["hellfire", "hellfire", "hellfire", "hellfire"]
	var out: Array = []
	for i in slots:
		out.append(pattern[i % pattern.size()])
	return out


static func summary(id: String) -> String:
	var data := spec(id)
	var guide := "LOCK" if bool(data["guided"]) else "UNGUIDED"
	return "%s  ·  %d RD  ·  PWR %d  ·  %d M  ·  %s" % [
		str(data["kind"]),
		int(data["count"]),
		int(data["damage"]),
		int(data["range"]),
		guide,
	]
