-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 18 October 2014

TPerl_SetModuleRevision("$Revision:  $")

-- TPerl_SlashHandler
local function TPerl_SlashHandler(msg)
	local args = { }
	for value in string.gmatch(msg, "[^ ]+") do
		tinsert(args, string.lower(value))
	end
	if (args[1] == "") then
		TPerl_Toggle()
		return
	end
	print(args[1])
	if (args[1] == "zimport") then
	 --Manually import ZPerl Settings.
		TPerl_Import()
	end
	if (args[1] == nil or args[1] == TPERL_CMD_MENU or args[1] == TPERL_CMD_OPTIONS) then
		TPerl_Toggle()
	elseif (args[1] == TPERL_CMD_LOCK) then
		TPerlLocked = 1
		if (TPerl_RaidTitles) then
			TPerl_RaidTitles()
			if (TPerl_RaidPets_Titles) then
				TPerl_RaidPets_Titles()
			end
		end
	elseif (args[1] == TPERL_CMD_UNLOCK) then
		TPerlLocked = 0
		if (TPerl_RaidTitles) then
			TPerl_RaidTitles()
			if (TPerl_RaidPets_Titles) then
				TPerl_RaidPets_Titles()
			end
		end
	elseif (args[1] == TPERL_CMD_CONFIG) then
		if (args[2] == TPERL_CMD_LIST) then
			local current
			TPerl_Notice(TPERL_CONFIG_LIST)
			for realmName, realmList in pairs(TPerlConfigNew) do
				if (type(realmList) == "table" and realmName ~= "global" and realmName ~= "savedPositions") then
					for playerName, realmSettings in pairs(realmList) do
						if (strlower(realmName) == strlower(GetRealmName()) and strlower(playerName) == strlower(UnitName("player"))) then
							current = TPERL_CONFIG_CURRENT
						else
							current = ""
						end
						DEFAULT_CHAT_FRAME:AddMessage(format("|c00FFFF80%s - %s%s", realmName, playerName, current))
					end
				end
			end
		elseif (args[2] == TPERL_CMD_DELETE) then
			if (args[3] and args[4]) then
				local me = GetRealmName().."/"..UnitName("player")
				if (strlower(args[3]) ~= strlower(GetRealmName()) and strlower(args[4]) ~= strlower(UnitName("player"))) then
					for realmName, realmList in pairs(TPerlConfigNew) do
						if (strlower(realmName) == strlower(args[3]) and type(realmList) == "table" and realmName ~= "global" and realmName ~= "savedPositions") then
							for playerName, realmSettings in pairs(realmList) do
								if (strlower(playerName) == strlower(args[4])) then
									TPerlConfigNew[realmName][playerName] = nil
									TPerl_Notice(TPERL_CONFIG_DELETED, realmName, playerName)
									return
								end
							end
						end
					end
					TPerl_Notice(TPERL_CANNOT_FIND_DELETE_TARGET, args[3], args[4])
				else
					TPerl_Notice(TPERL_CANNOT_DELETE_CURRENT)
				end
			else
				TPerl_Notice(TPERL_CANNOT_DELETE_BADARGS)
			end
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(TPERL_CMD_HELP)
	end
end

SlashCmdList["TPerl"] = TPerl_SlashHandler
SLASH_TPerl1 = "/tperl"
SLASH_TPerl2 = "/tp"
