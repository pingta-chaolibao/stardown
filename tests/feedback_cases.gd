extends RefCounted
## Explicit mechanism sandboxes for visual review, never catalog levels.
static func room(id: String, title: String, width: int = 7, height: int = 5) -> Dictionary:
	var terrain: Array[String] = []
	for _y in height: terrain.append(".".repeat(width))
	return {"schema_version":1,"id":"feedback_"+id,"title":"视觉预览 · "+title,
		"source_note":"独立机制沙盘，仅供视觉统一确认，不是新增关卡。","is_temporary":true,
		"terrain":terrain,"player":[0,0],"hero_kind":"red","crates":[],"targets":[],"objective":"none"}

static func cases() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var d := room("chain","01 平滑移动与整链推动",8,4)
	d.erase("player"); d.erase("hero_kind")
	d["heroes"] = [{"id":"red","kind":"red","position":[0,1]},{"id":"blue","kind":"blue","position":[2,1]},{"id":"green","kind":"green","position":[6,3]}]
	d["active_hero"] = "red"; d["crates"] = [[1,1],[3,1]]
	result.append({"id":"chain","data":d,"path":"RR","caption":"英雄与水晶整列同步滑动；水晶轻微呼吸，始终锚定格子。"})
	d = room("pull","02 自动单拉水晶与火龙",7,4)
	d["player"] = [2,1]; d["hero_kind"] = "green"; d["crates"] = [[1,1]]
	d["monsters"] = [{"kind":"fire_dragon","position":[4,2],"facing":"right"}]
	result.append({"id":"pull","data":d,"path":"RDL","caption":"单拉与英雄同步；拉动火龙不改变朝向。"})
	d = room("swap","03 两端闪现与英雄选择",7,4)
	d.erase("player"); d.erase("hero_kind")
	d["heroes"] = [{"id":"blue","kind":"blue","position":[0,1]},{"id":"red","kind":"red","position":[5,1]},{"id":"green","kind":"green","position":[3,3]}]
	d["active_hero"] = "blue"; d["crates"] = [[3,1]]
	result.append({"id":"swap","data":d,"path":"RRCZ","caption":"交换只在两端闪现，不穿越中间格；C免费选择，撤销保留选择。"})
	d = room("energy","04 压力与能量开关")
	d["player"] = [1,3]
	d["energy_links"] = [{"id":"gate","plate":[1,2],"barriers":[[4,1],[4,2]],"pressure_sources":["hero","crystal"]}]
	result.append({"id":"energy","data":d,"path":"UDU","caption":"踩板后实体消散，虚线地面标记保留；离板后重新凝聚。"})
	d = room("fire","05 定向火焰与首目标",8,5)
	d["monsters"] = [{"kind":"fire_dragon","position":[0,2],"facing":"right"},{"kind":"goblin","position":[3,2]},{"kind":"goblin","position":[5,2]}]
	d["crates"] = [[6,2]]
	result.append({"id":"fire","data":d,"path":"RDDZ","caption":"每次喷火只到本步首目标；水晶挡火。死亡只能撤销。"})
	d = room("goblin","06 哥布林攻击与英雄死亡",6,4)
	d["player"] = [1,1]; d["monsters"] = [{"kind":"goblin","position":[3,1]}]
	result.append({"id":"goblin","data":d,"path":"RZ","caption":"四向相邻攻击与死亡残影；撤销立即恢复，不残留旧动画。"})
	d = room("mutual","07 同步攻击与怪物死亡")
	d["monsters"] = [{"kind":"fire_dragon","position":[3,2],"facing":"right"},{"kind":"fire_dragon","position":[5,2],"facing":"left"},{"kind":"goblin","position":[4,2]}]
	result.append({"id":"mutual","data":d,"path":"RZ","caption":"同时成立的攻击同步播放；火龙与哥布林同一步死亡。"})
	d = room("destruction","08 能量再现与毁晶")
	d.erase("player"); d.erase("hero_kind")
	d["heroes"] = [{"id":"red","kind":"red","position":[1,2]},{"id":"green","kind":"green","position":[4,1]},{"id":"blue","kind":"blue","position":[5,1]}]
	d["active_hero"] = "red"; d["crates"] = [[4,2]]
	d["monsters"] = [{"kind":"fire_dragon","position":[5,2],"facing":"up"}]
	d["energy_links"] = [{"id":"gate","plate":[1,2],"barriers":[[4,1],[4,2],[5,2]],"pressure_sources":["hero","crystal"]}]
	result.append({"id":"destruction","data":d,"path":"LZ","caption":"能量再现：英雄、火龙死亡，水晶碎裂；一撤销完整恢复。"})
	d = room("victory","09 受阻、撤销与胜利",5,4)
	d["player"] = [1,1]; d["terrain"][0] = ".#..."; d["objective"] = "player_on_exit"; d["exit"] = [2,1]; d["exit_color"] = "green"
	result.append({"id":"victory","data":d,"path":"URZR","caption":"受阻轻反馈不算行动；胜利光环与撤销提示可立即取消。"})
	return result
