-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if (GetLocale() == "zhCN") then
	TPerl_LongDescription	= "全新外观的玩家状态框，包括玩家、宠物、队伍、团队、目标、目标的目标、焦点、团队"

	TPERL_MINIMAP_HELP1	= "|c00FFFFFF左键点击|r打开选项（并解锁框体）"
	TPERL_MINIMAP_HELP2	= "|c00FFFFFF右键点击|r拖动图标"
	TPERL_MINIMAP_HELP3	= "\r团队成员: |c00FFFF80%d|r\r小队成员: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4	= "\r你是此 队伍/团队 队长"
	TPERL_MINIMAP_HELP5	= "|c00FFFFFFAlt|r  TPerl 内存占用"
	TPERL_MINIMAP_HELP6	= "|c00FFFFFF+Shift|r  TPerl 启用以来的内存占用"

	TPERL_MINIMENU_OPTIONS	= "选项"
	TPERL_MINIMENU_ASSIST	= "显示助手窗口"
	TPERL_MINIMENU_CASTMON	= "显示施法监控窗口"
	TPERL_MINIMENU_RAIDAD	= "显示团队管理窗口"
	TPERL_MINIMENU_ITEMCHK	= "显示物品检查窗口"
	TPERL_MINIMENU_RAIDBUFF = "团队Buff"
	TPERL_MINIMENU_ROSTERTEXT="名单文字"
	TPERL_MINIMENU_RAIDSORT = "分组设置"
	TPERL_MINIMENU_RAIDSORT_GROUP = "按照队伍"
	TPERL_MINIMENU_RAIDSORT_CLASS = "按照职业"

	TPERL_TYPE_NOT_SPECIFIED	= "未指定"
	TPERL_TYPE_PET		= PET		--"宠物"
	TPERL_TYPE_BOSS		= "首领"
	TPERL_TYPE_RAREPLUS	= "银英"
	TPERL_TYPE_ELITE	= "精英"
	TPERL_TYPE_RARE		= "稀有"

	-- Zones
	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "毒蛇神殿"
	TPERL_LOC_ZONE_BLACK_TEMPLE = "黑暗神殿"
	TPERL_LOC_ZONE_HYJAL_SUMMIT = "海加尔峰"
	TPERL_LOC_ZONE_KARAZHAN = "卡拉赞"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU = "太阳之井高地"
	TPERL_LOC_ZONE_ULDUAR = "奥杜尔"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "十字军的试炼"
	TPERL_LOC_ZONE_ICECROWN_CITADEL = "冰冠堡垒"
	TPERL_LOC_ZONE_RUBY_SANCTUM = "红玉圣殿"

	-- Status
	TPERL_LOC_DEAD		= DEAD		--"死亡"
	TPERL_LOC_GHOST		= "幽灵"
	TPERL_LOC_FEIGNDEATH	= "假死"
	TPERL_LOC_OFFLINE	= PLAYER_OFFLINE	--"离线"
	TPERL_LOC_RESURRECTED	= "已被复活"
	TPERL_LOC_SS_AVAILABLE	= "灵魂已保存"
	TPERL_LOC_UPDATING	= "更新中"
	TPERL_LOC_ACCEPTEDRES	= "已接受"
	TPERL_RAID_GROUP		= "小队 %d"
	TPERL_RAID_GROUPSHORT	= "%d 队"

	TPERL_LOC_NONEWATCHED	= "无监控"

	TPERL_LOC_STATUSTIP	= "状态提示: "		-- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "持续治疗",
		AGGRO = "你仇恨过高了",
		MISSING = "你的职业 buff 消失",
		HEAL = "正被治疗",
		SHIELD = "盾"
	}

	TPERL_OK			= "确定"
	TPERL_CANCEL		= "取消"

	TPERL_LOC_LARGENUMTAG		= "万"
	TPERL_LOC_HUGENUMTAG		= "亿"
	TPERL_LOC_VERYHUGENUMTAG	= "兆"

	BINDING_HEADER_TPERL = "TPerl 快捷键"
	BINDING_NAME_TPERL_TOGGLERAID = "切换团队窗口"
	BINDING_NAME_TPERL_TOGGLERAIDSORT = "切换团队排列方式"
	BINDING_NAME_TPERL_TOGGLERAIDPETS = "切换团队宠物窗口"
	BINDING_NAME_TPERL_TOGGLEOPTIONS = "切换选项窗"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE = "切换增益/减益/无"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE = "切换显示可施加/解除的增益/减益魔法"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR = "显示 Teamspeak 监控图标"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER = "切换距离侦测"

	TPERL_KEY_NOTICE_RAID_BUFFANY = "显示所有的增益/减益魔法"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST = "只显示可施放/解除的的增益/减益魔法"
	TPERL_KEY_NOTICE_RAID_BUFFS = "显示团队增益魔法"
	TPERL_KEY_NOTICE_RAID_DEBUFFS = "显示团队减益魔法"
	TPERL_KEY_NOTICE_RAID_NOBUFFS = "不显示团队增益/减益魔法"

	TPERL_DRAGHINT1		= "|c00FFFFFF点击|r 改变窗口比例"
	TPERL_DRAGHINT2		= "|c00FFFFFFShift+单击|r 改变窗口大小"

	-- Usage
	TPerlUsageNameList = {TPerl = "主体文件", TPerl_Player = "玩家", TPerl_PlayerPet = "玩家宠物", TPerl_Target = "目标", TPerl_TargetTarget = "目标的目标", TPerl_Party = "队伍", TPerl_PartyPet = "队友宠物", TPerl_RaidFrames = "团队框", TPerl_RaidHelper = "团队助手", TPerl_RaidAdmin = "团队管理", TPerl_TeamSpeak = "TS监视", TPerl_RaidMonitor = "团队监控", TPerl_RaidPets = "团队宠物", TPerl_ArcaneBar = "施法条", TPerl_PlayerBuffs = "玩家增益", TPerl_GrimReaper = "死神之收割"}
	TPERL_USAGE_MEMMAX	= "UI Mem Max: %d"
	TPERL_USAGE_MODULES	= "模块: "
	TPERL_USAGE_NEWVERSION	= "*新版本"
	TPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r 可下载使用"

	TPERL_CMD_HELP		= "|c00FFFF80Usage: |c00FFFFFF/xperl menu | lock | unlock | config list | config delete <realm> <name>"
	TPERL_CANNOT_DELETE_CURRENT = "无法删除当前配置"
	TPERL_CONFIG_DELETED		= "删除配置信息: %s/%s"
	TPERL_CANNOT_FIND_DELETE_TARGET = "找不到要删除的配置信息: (%s/%s)"
	TPERL_CANNOT_DELETE_BADARGS = "请输入服务器以及玩家名"
	TPERL_CONFIG_LIST		= "配置列表:"
	TPERL_CONFIG_CURRENT		= " (当前)"

	TPERL_RAID_TOOLTIP_WITHBUFF	= "有该buff的成员： (%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF	= "无该buff的成员： (%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s的%s将在%s后过期"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED = "檢測到新版本："
end
