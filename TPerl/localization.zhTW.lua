-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

-- Thanks 星塵、Player Lin for translations

if (GetLocale() == "zhTW") then
	TPerl_ProductName	= "|cFFD00000TPerl|r 單位框架"
	TPerl_Description	= TPerl_ProductName.." 作者 "..TPerl_Author

	TPerl_LongDescription	= "全新外觀的玩家單位狀態框架模組，包括玩家、寵物、隊伍、專注(focus)、團隊、目標以及目標的目標等。"

	TPERL_MINIMAP_HELP1	= "|c00FFFFFF左鍵點擊|r 開啟設定視窗 (以及 |c0000FF00解鎖框架|r)"
	TPERL_MINIMAP_HELP2	= "|c00FFFFFF右鍵拖動|r 移動此圖標"
	TPERL_MINIMAP_HELP3	= "\r團隊成員: |c00FFFF80%d|r\r隊伍成員: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4	= "\r你是此 隊伍/團隊 的隊長"
	TPERL_MINIMAP_HELP5	= "|c00FFFFFFAlt|r 顯示 TPerl 記憶體用量"
	TPERL_MINIMAP_HELP6	= "|c00FFFFFF+Shift|r 顯示 TPerl 記憶體使用明細"

	TPERL_MINIMENU_OPTIONS	= "功能設定"
	TPERL_MINIMENU_ASSIST	= "顯示協助框架"
	TPERL_MINIMENU_CASTMON	= "顯示施法監視"
	TPERL_MINIMENU_RAIDAD	= "顯示團隊幫手"
	TPERL_MINIMENU_ITEMCHK	= "顯示物品確認"
	TPERL_MINIMENU_RAIDBUFF = "團隊 Buffs"
	TPERL_MINIMENU_ROSTERTEXT="名單文字"
	TPERL_MINIMENU_RAIDSORT = "團隊排序"
	TPERL_MINIMENU_RAIDSORT_GROUP = "依據隊伍排序"
	TPERL_MINIMENU_RAIDSORT_CLASS = "依據職業排序"

	TPERL_TYPE_NOT_SPECIFIED = "未指定"
	TPERL_TYPE_PET		= PET			-- "Pet"
	TPERL_TYPE_BOSS		= "首領"
	TPERL_TYPE_RAREPLUS	= "稀有精英+"
	TPERL_TYPE_ELITE	= "精英"
	TPERL_TYPE_RARE		= "稀有"

	-- Zones
	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "毒蛇神殿洞穴"
	TPERL_LOC_ZONE_BLACK_TEMPLE = "黑暗神廟"
	TPERL_LOC_ZONE_HYJAL_SUMMIT = "海加爾山"
	TPERL_LOC_ZONE_KARAZHAN = "卡拉贊"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU = "太陽之井高地"
	TPERL_LOC_ZONE_NAXXRAMAS = "納克薩瑪斯"
	TPERL_LOC_ZONE_OBSIDIAN_SANCTUM = "黑曜聖所"
	TPERL_LOC_ZONE_EYE_OF_ETERNITY = "永恆之眼"
	TPERL_LOC_ZONE_ULDUAR = "奧杜亞"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "十字軍試煉"
	TPERL_LOC_ZONE_ICECROWN_CITADEL = "冰冠城塞"
	TPERL_LOC_ZONE_RUBY_SANCTUM = "晶紅聖所"

	-- Status
	TPERL_LOC_DEAD		= DEAD			-- "Dead"
	TPERL_LOC_GHOST		= "靈魂"
	TPERL_LOC_FEIGNDEATH	= "假死"
	TPERL_LOC_OFFLINE	= PLAYER_OFFLINE	-- "Offline"
	TPERL_LOC_RESURRECTED	= "復活"
	TPERL_LOC_SS_AVAILABLE	= "靈魂保存"
	TPERL_LOC_UPDATING	= "更新中"
	TPERL_LOC_ACCEPTEDRES	= "已接受"		-- Res accepted
	TPERL_RAID_GROUP	= "小隊 %d"
	TPERL_RAID_GROUPSHORT	= "%d隊"

	TPERL_LOC_NONEWATCHED	= "無監看"

	TPERL_LOC_STATUSTIP	= "狀態提示："		-- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "持續治療",
		AGGRO = "敵方目標",
		MISSING = "你職業的 buff 被遺漏",
		HEAL = "已受治療",
		SHIELD = "已上盾"
	}

	TPERL_OK			= "確定"
	TPERL_CANCEL		= "取消"


	TPERL_LOC_LARGENUMTAG		= "萬"
	TPERL_LOC_HUGENUMTAG		= "億"
	TPERL_LOC_VERYHUGENUMTAG	= "兆"

	BINDING_HEADER_TPERL = "TPerl 快捷鍵設定"
	BINDING_NAME_TPERL_TOGGLERAID = "開/關團隊視窗"
	BINDING_NAME_TPERL_TOGGLERAIDSORT = "切換團隊排序方式為 職業/隊伍"
	BINDING_NAME_TPERL_TOGGLERAIDPETS = "切換是否使用團隊寵物"
	BINDING_NAME_TPERL_TOGGLEOPTIONS = "開/關設定視窗"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE = "切換 增益/減益/無"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE = "切換顯示可施加/解除的增益/減益效果"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR = "顯示 Teamspeak 監看圖標"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER = "切換距離偵測開啟/關閉"

	TPERL_KEY_NOTICE_RAID_BUFFANY = "顯示所有 增益/減益效果"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST = "只有 可施加/可解除 的增益/減益效果顯示"
	TPERL_KEY_NOTICE_RAID_BUFFS = "顯示團隊的 增益效果"
	TPERL_KEY_NOTICE_RAID_DEBUFFS = "顯示團隊的 減益效果"
	TPERL_KEY_NOTICE_RAID_NOBUFFS = "不顯示團隊的 增益效果"

	TPERL_DRAGHINT1		= "|c00FFFFFF點擊|r 調整視窗比例"
	TPERL_DRAGHINT2		= "|c00FFFFFFShift+點擊|r 重置視窗尺寸"

	-- Usage
	TPerlUsageNameList	= {TPerl = "核心", TPerl_Player = "玩家", TPerl_PlayerPet = "寵物", TPerl_Target = "目標", TPerl_TargetTarget = "目標的目標", TPerl_Party = "隊友", TPerl_PartyPet = "隊友寵物", TPerl_RaidFrames = "團隊框架", TPerl_RaidHelper = "團隊助手", TPerl_RaidAdmin = "團隊紀錄", TPerl_TeamSpeak = "TS 監視", TPerl_RaidMonitor = "團隊監視", TPerl_RaidPets = "團隊寵物", TPerl_ArcaneBar = "施法條", TPerl_PlayerBuffs = "玩家 Buffs"}
	TPERL_USAGE_MEMMAX	= "UI 記憶體用量: %d"
	TPERL_USAGE_MODULES	= "模組: "
	TPERL_USAGE_NEWVERSION	= "*新版本"
	TPERL_USAGE_AVAILABLE	= "已有新版本 %s |c00FFFFFF%s|r 可以下載使用"

	TPERL_CMD_HELP		= "|c00FFFF80使用: |c00FFFFFF/xperl menu | lock | unlock | config list | config delete <realm> <name>"
	TPERL_CANNOT_DELETE_CURRENT	= "無法刪除您的個人設定"
	TPERL_CONFIG_DELETED		= "刪除 %s/%s 的個人設定"
	TPERL_CANNOT_FIND_DELETE_TARGET	= "找不到 (%s/%s) 設定來刪除"
	TPERL_CANNOT_DELETE_BADARGS	= "請給予正確的伺服器名稱以及玩家名稱"
	TPERL_CONFIG_LIST		= "設定清單："
	TPERL_CONFIG_CURRENT		= " (目前)"

	TPERL_RAID_TOOLTIP_WITHBUFF	= "有此 buff 的：(%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF	= "沒有此 buff 的：(%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s 的 %s 將要在 %s 後消失。"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED = "检测到新版本："
end
