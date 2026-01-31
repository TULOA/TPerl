-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local conf
TPerl_RequestConfig(function(new)
	conf = new
end, "$Revision:  $")

local TPerl_Usage = { }

local _G = _G
local collectgarbage = collectgarbage
local floor = floor
local format = format
local pairs = pairs
local print = print
local string = string
local strsplit = strsplit
local table = table
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring

local Ambiguate = Ambiguate
local GetLocale = GetLocale
local GetTime = GetTime
local IsAddOnLoaded = IsAddOnLoaded
local IsAltKeyDown = IsAltKeyDown
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsShiftKeyDown = IsShiftKeyDown
local SendAddonMessage = SendAddonMessage
local UnitFactionGroup = UnitFactionGroup
local UnitInParty = UnitInParty
local UnitIsConnected = UnitIsConnected
local UnitIsFriend = UnitIsFriend
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitName = UnitName

local UNKNOWN = UNKNOWN

local mod = CreateFrame("Frame", BackdropTemplateMixin and "BackdropTemplate")
--mod:RegisterEvent("CHAT_MSG_ADDON")
--mod:RegisterEvent("GROUP_ROSTER_UPDATE")

--RegisterAddonMessagePrefix("TPerl")

local function modOnEvent(self, event, ...)
	local f = mod[event]
	if (f) then
		f(mod, ...)
	end
end

--mod:SetScript("OnEvent", modOnEvent)

--[[GameTooltip:HookScript("OnTooltipSetUnit", function(self)
	local name, unitid = self:GetUnit()
	if (not unitid) then
		unitid = "mouseover"
	end
	mod:TooltipInfo(self, unitid)
end)]]

local function UnitFullName(unit)
	local n, s = UnitName(unit)
	if (s and s ~= "") then
		return n.."-"..s
	end
	return n
end

-- TooltipInfo
function mod:TooltipInfo(tooltip, unitid)
	if (unitid and conf and conf.tooltip.xperlInfo and UnitIsPlayer(unitid) and UnitIsFriend(unitid, "player")) then
		local xpUsage = TPerl_GetUsage(UnitFullName(unitid), unitid)
		if (xpUsage) then
			local xp

			if (xpUsage.addon) then
				if xpUsage.addon == 0 then
					xp = "|cFFD00000TPerl|r "..(xpUsage.version or TPerl_VersionNumber)
				else
					xp = "|cFFD00000TPerl|r "..(xpUsage.version or TPerl_VersionNumber)
				end
			else
				xp = "|cFFD00000TPerl|r "..(xpUsage.version or TPerl_VersionNumber)
			end

			if (xpUsage.revision) then
				local r = "r"..xpUsage.revision
				xp = format("%s |cFF%s%s", xp, r == TPerl_GetRevision() and "80FF80" or "FF8080", r)
				xp = xp.."|r"
			elseif (UnitIsUnit("player", unitid)) then
				xp = xp.." |cFF80FF80"..TPerl_GetRevision().."|r"
			end

			if (xpUsage.locale) then
				xp = xp.."|cFF87CEFA".." "..xpUsage.locale.."|r"
			elseif (UnitIsUnit("player", unitid)) then
				xp = xp.."|cFF87CEFA".." "..GetLocale().."|r"
			end

			if (xpUsage.mods and IsShiftKeyDown()) then
				local modList = self:DecodeModuleList(xpUsage.mods)
				if (modList) then
					xp = xp.."|cFFFFFFFF"..":\n".."|r".."|cFF909090"..modList.."|r"
				end
			end

			if (xpUsage.gc and IsAltKeyDown()) then
				xp = xp.."\n|cFFFFFFFF"..format(TPERL_USAGE_MEMMAX, xpUsage.gc).."|r"
			end

			GameTooltip:AddLine(xp, 1, 1, 1, 1)
			GameTooltip:Show()
		end
	end
end

-- CheckForNewerVersion
function mod:CheckForNewerVersion(ver)
	if (not string.find(string.lower(ver), "beta")) then
		if (ver > TPerl_VersionNumber) then
			if (not self.notifiedVersion or self.notifiedVersion < ver) then
				self.notifiedVersion = ver
				print(format(TPERL_USAGE_AVAILABLE, TPerl_ProductName, ver))
			end
			return true
		end
	end
end

-- ProcessTPerlMessage
function mod:ProcessTPerlMessage(sender, msg, channel)
	sender = Ambiguate(sender, "none")
	local myUsage = TPerl_Usage[sender]

	if (string.sub(msg, 1, 4) == "VER ") then
		if (not myUsage) then
			myUsage = { }
			TPerl_Usage[sender] = myUsage
		end

		myUsage.old = nil
		local ver = string.sub(msg, 5)

		if (ver == TPerl_VersionNumber) then
			myUsage.version = nil
		else
			myUsage.version = ver
			self:CheckForNewerVersion(ver)
		end

		if (channel ~= "WHISPER" and sender and sender ~= UnitName("player")) then
			self:SendModules("WHISPER", sender)
		end
	elseif (string.sub(msg, 1, 4) == "MOD ") then
		if (myUsage) then
			local temp = string.match(string.sub(msg, 5), "(%d)")
			if (temp) then
				myUsage.addon = tonumber(temp)
			end
		end
	elseif (string.sub(msg, 1, 4) == "REV ") then
		if (myUsage) then
			local temp = string.match(string.sub(msg, 5), "(%d+)")
			if (temp) then
				myUsage.revision = tonumber(temp)
			end
		end
	elseif (string.sub(msg, 1, 7) == "MAXVER ") then
		local ver = string.sub(msg, 8)
		if (ver >= TPerl_VersionNumber) then
			self:CheckForNewerVersion(ver)
		end
	elseif (msg == "S") then
		if (channel == "WHISPER") then
			-- Version only sent, so ask for rest
			SendAddonMessage("TPerl", "ASK", channel, sender)
		end
	elseif (msg == "ASK") then
		if (channel == "WHISPER") then
			-- Details asked for
			self:SendModules("WHISPER", sender)
		end
	elseif (string.sub(msg, 1, 4) == "MOD ") then
		if (myUsage) then
			myUsage.mods = string.sub(msg, 5)
		end
	elseif (string.sub(msg, 1, 4) == "LOC ") then
		if (myUsage) then
			local loc = string.sub(msg, 5)
			myUsage.locale = loc
		end
	elseif (string.sub(msg, 1, 3) == "GC ") then
		if (myUsage) then
			myUsage.gc = tonumber(string.sub(msg, 4))
		end
	end
end

-- GROUP_ROSTER_UPDATE
function mod:GROUP_ROSTER_UPDATE()
	if (IsInRaid()) then
		if (not self.inRaid) then
			self.inRaid = true
			self:SendModules()
		end
	else
		self.inRaid = nil
	end

	if (UnitInParty("player")) then
		if (not self.inParty and not self.inRaid) then
			self.inParty = true
			self:SendModules("PARTY") -- Let other TPerl users know which version we're running
		end
	else
		self.inParty = nil
	end
end

-- CHAT_MSG_ADDON
function mod:CHAT_MSG_ADDON(prefix, msg, channel, sender)
	if (prefix == "TPerl") then
		self:ParseCTRA(sender, msg, channel)
	end
end

-- TPerl_ParseCTRA
function mod:ParseCTRA(sender, msg, channel)
	local arr = {strsplit("#", msg)}
	for i, subMsg in pairs(arr) do
		self:ProcessTPerlMessage(sender, subMsg, channel)
	end
end

local xpModList = {
	"TPerl",
	"TPerl_Player",
	"TPerl_PlayerPet",
	"TPerl_Target",
	"TPerl_TargetTarget",
	"TPerl_Party",
	"TPerl_PartyPet",
	"TPerl_RaidFrames",
	"TPerl_RaidHelper",
	"TPerl_RaidAdmin",
	"TPerl_TeamSpeak",
	"TPerl_RaidMonitor",
	"TPerl_RaidPets",
	"TPerl_ArcaneBar",
	"TPerl_PlayerBuffs",
	"TPerl_GrimReaper"
}

-- TPerl_SendModules
mod.throttle = { }
function mod:SendModules(chan, target)
	if (not chan) then
		if (IsInRaid()) then
			local inInstance, instanceType = IsInInstance()
			if (instanceType == "pvp") then
				chan = "INSTANCE_CHAT"
			else
				chan = "RAID"
			end
		elseif (UnitInParty("player")) then
			chan = "PARTY"
		end
	end

	if (chan) then
		if (chan == "PARTY" or chan == "RAID") then
			-- Cope with WoW 3.2 bug which says party members exist, when in BGs in fake raid
			local inInstance, instanceType = IsInInstance()
			if (instanceType == "arena" or instanceType == "pvp") then
				return
			end
		end

		if (chan == "WHISPER") then
			local t = self.throttle[target]
			if (t and GetTime() < t + 15) then
				return
			end
			self.throttle[target] = GetTime()
		end

		local packet = self:MakePacket(chan == "WHISPER")
		SendAddonMessage("TPerl", packet, chan, target)
	end
end

-- MakePacket
function mod:MakePacket(response, versionOnly)
	local resp
	if (response) then
		resp = "R#S#"
	else
		resp = ""
	end

	local addon
	if C_AddOns.IsAddOnLoaded("TPerl") then
		addon = 1
	else
		addon = 0
	end

	if (versionOnly) then
		return format("%sVER %s#MOD %s#REV %s", resp, TPerl_VersionNumber, addon, TPerl_GetRevision())
	else
		local modules = ""
		for k, v in pairs(xpModList) do
			local loaded
			if C_AddOns.IsAddOnLoaded(v) then
				loaded = 1
			else
				loaded = 0
			end
			modules = modules..(tostring(loaded))
		end
		local gc = floor(collectgarbage("count"))

		local s = format("%sVER %s#MOD %d#REV %s#GC %d#LOC %s#MOD %s", resp, TPerl_VersionNumber, addon, TPerl_GetRevision(), gc, GetLocale(), modules)
		if (self.notifiedVersion and self.notifiedVersion > TPerl_VersionNumber) then
			s = format("%s#MAXVER %s", s, self.notifiedVersion)
		end
		return s
	end
end

-- TPerl_DecodeModuleList
function mod:DecodeModuleList(modList)
	local ret = { }
	for k, v in pairs(xpModList) do
		if (string.sub(modList, k, k) == "1") then
			if (TPerlUsageNameList[v]) then
				tinsert(ret, TPerlUsageNameList[v])
			else
				tinsert(ret, v)
			end
		end
	end
	local tmp = table.concat(ret, ", ")
	return tmp
end

-- TPerl_GetUsage
function TPerl_GetUsage(unitName, unitID)
	local ver = TPerl_Usage[unitName]
	if (not ver) then
		if (unitID and unitName ~= UNKNOWN and (UnitIsPlayer(unitID) and UnitFactionGroup("player") == UnitFactionGroup(unitID) and UnitIsConnected(unitID))) then
			if (not mod.directQueries) then
				mod.directQueries = {}
			end
			if (not mod.directQueries[unitName]) then
				mod.directQueries[unitName] = true
				SendAddonMessage("TPerl", mod:MakePacket(nil, true), "WHISPER", unitName)
			end
		end
	end
	return ver
end
