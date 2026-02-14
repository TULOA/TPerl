-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local TPerl_Player_Events = { }
local isOutOfControl
local playerClass, playerName
local conf, pconf
TPerl_RequestConfig(function(new)
	conf = new
	pconf = conf.player
	if (TPerl_Player) then
		TPerl_Player.conf = conf.player
	end
end, "$Revision:  $")

local perc1F = "%.1f"..PERCENT_SYMBOL
local percD = "%.0f"..PERCENT_SYMBOL

--[===[@debug@
local function d(...)
	ChatFrame1:AddMessage(format(...))
end
--@end-debug@]===]

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsTBCAnni = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local IsCataClassic = WOW_PROJECT_ID == WOW_PROJECT_CATA_CLASSIC
local IsMistsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

-- Upvalues
local ceil = ceil
local floor = floor
local format = format
local hooksecurefunc = hooksecurefunc
local max = max
local pairs = pairs
local pcall = pcall
local string = string

local CreateFrame = CreateFrame
local GetDifficultyColor = GetDifficultyColor or GetQuestDifficultyColor
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod
local GetNumGroupMembers = GetNumGroupMembers
local GetPVPTimer = GetPVPTimer
local GetRaidRosterInfo = GetRaidRosterInfo
local GetShapeshiftForm = GetShapeshiftForm
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local GetSpellInfo = GetSpellInfo
local GetXPExhaustion = GetXPExhaustion
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local IsPVPTimerRunning = IsPVPTimerRunning
local IsResting = IsResting
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitFactionGroup = UnitFactionGroup
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsAFK = UnitIsAFK
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGhost = UnitIsGhost
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitIsMercenary = UnitIsMercenary
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsUnit = UnitIsUnit
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitOnTaxi = UnitOnTaxi
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax

local CombatFeedback_Initialize = CombatFeedback_Initialize
local CombatFeedback_OnCombatEvent = CombatFeedback_OnCombatEvent
local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate

local TPerl_Player_InitDK
local TPerl_Player_InitDruid
local TPerl_Player_InitEvoker
local TPerl_Player_InitMage
local TPerl_Player_InitMonk
local TPerl_Player_InitPaladin
local TPerl_Player_InitPriest
local TPerl_Player_InitRogue
local TPerl_Player_InitWarlock

local TPerl_PlayerStatus_OnUpdate
local TPerl_Player_HighlightCallback

--local feignDeath = (C_Spell and C_Spell.GetSpellInfo(5384)) and C_Spell.GetSpellInfo(5384).name or GetSpellInfo(5384)
--local spiritOfRedemption = (C_Spell and C_Spell.GetSpellInfo(27827)) and C_Spell.GetSpellInfo(27827).name or GetSpellInfo(27827)


----------------------
-- Loading Function --
----------------------
function TPerl_Player_OnLoad(self)
	TPerl_SetChildMembers(self)
	self.partyid = "player"
	self.unit = self.partyid

	TPerl_BlizzFrameDisable(PlayerFrame)

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	self.portraitFrame:SetAttribute("*type1", "target")
	self.portraitFrame:SetAttribute("type2", "togglemenu")
	self.portraitFrame:SetAttribute("unit", self.partyid)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self.nameFrame:SetAttribute("unit", self.partyid)
	self.statsFrame:SetAttribute("*type1", "target")
	self.statsFrame:SetAttribute("type2", "togglemenu")
	self.statsFrame:SetAttribute("unit", self.partyid)
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
	self:SetAttribute("unit", self.partyid)

	self.state = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")

	--RegisterAttributeDriver(self.nameFrame, "unit", "[vehicleui] vehicle; player")
	RegisterAttributeDriver(self, "unit", "[vehicleui] vehicle; player")

	TPerl_RegisterClickCastFrame(self.portraitFrame)
	TPerl_RegisterClickCastFrame(self.nameFrame)
	TPerl_RegisterClickCastFrame(self.statsFrame)
	TPerl_RegisterClickCastFrame(self)

	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_ALIVE")

	if (HealBot_Options_EnablePlayerFrame) then
		HealBot_Options_EnablePlayerFrame = function() end
	end

	self:SetScript("OnUpdate", TPerl_Player_OnUpdate)
	self:SetScript("OnEvent", TPerl_Player_OnEvent)
	self:SetScript("OnShow", TPerl_Unit_UpdatePortrait)
	self.time = 0

	self.Power = 0
	self.nameFrame.pvp.time = 0

	--[[self.nameFrame.pvp:SetScript("OnUpdate", function(self, elapsed)
		self.time = self.time + elapsed
		if (self.time >= 0.2) then
			self.time = 0
			if (IsPVPTimerRunning()) then
				local timeLeft = GetPVPTimer()
				if (timeLeft > 0 and timeLeft < 300000) then -- 5 * 60 * 1000
					timeLeft = floor(timeLeft / 1000)
					self.timer:Show()
					self.timer:SetFormattedText("%d:%02d", timeLeft / 60, timeLeft % 60)
					return
				end
			end
			self.timer:Hide()
		end
	end)]]

	self.nameFrame.pvptimer:SetScript("OnUpdate", TPerl_Player_UpdatePVPTimerOnUpdate)

	local _, playerClass = UnitClass("player")
	TPerl_Player_InitDruid(self, playerClass)
	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		TPerl_Player_DruidBarUpdate(self)
	end
	TPerl_Player_InitDK(self, playerClass)
	TPerl_Player_InitEvoker(self, playerClass)
	TPerl_Player_InitMage(self, playerClass)
	TPerl_Player_InitMonk(self, playerClass)
	TPerl_Player_InitPaladin(self, playerClass)
	TPerl_Player_InitPriest(self, playerClass)
	TPerl_Player_InitRogue(self, playerClass)
	TPerl_Player_InitWarlock(self, playerClass)

	TPerl_RegisterHighlight(self.highlight, 3)

	local perlframes = {self.nameFrame, self.statsFrame, self.levelFrame, self.portraitFrame, self.groupFrame}
	self.FlashFrames = {self.portraitFrame, self.nameFrame,self.levelFrame, self.statsFrame}
	-- Only Add deathknight to the flash frame list
	-- This resolves an issue with the backdrop being added constantly to the other special frames.
	--[[local _, class = UnitClass("player")
	if (class == "DEATHKNIGHT") then
		table.insert(self.FlashFrames, self.runes)
		table.insert(perlframes, self.runes)
	end]]

	TPerl_RegisterPerlFrames(self, perlframes)--, self.runes

	TPerl_RegisterOptionChanger(TPerl_Player_Set_Bits, self, "TPerl_Player_Set_Bits")
	TPerl_Highlight:Register(TPerl_Player_HighlightCallback, self)
	--self.IgnoreHighlightStates = {AGGRO = true}

	if (TPerlDB) then
		self.conf = TPerlDB.player
	end

	TPerl_Player_OnLoad = nil
end

-- TPerl_Player_HighlightCallback(updateName)
function TPerl_Player_HighlightCallback(self, updateGUID)
	if (updateGUID == UnitGUID("player")) then
		TPerl_Highlight:SetHighlight(self, updateGUID)
	end
end

-- UpdateAssignedRoles
local function UpdateAssignedRoles(self)
	local unit = self.partyid
	local icon = self.nameFrame.roleIcon
	local isTank, isHealer, isDamage
	local inInstance, instanceType = IsInInstance()
	if (not IsVanillaClassic and instanceType == "party") then
		-- No point getting it otherwise, as they can be wrong. Usually the values you had
		-- from previous instance if you're running more than one with the same people

		-- According to http://forums.worldofwarcraft.com/thread.html?topicId=26560499864
		-- this is the new way to check for roles
		local role = UnitGroupRolesAssigned(unit)
		isTank = false
		isHealer = false
		isDamage = false
		if role == "TANK" then
			isTank = true
		elseif role == "HEALER" then
			isHealer = true
		elseif role == "DAMAGER" then
			isDamage = true
		end
	end

	-- role icons option check by playerlin
	if (conf and conf.xperlOldroleicons) then
		if isTank then
			icon:SetTexture("Interface\\GroupFrame\\UI-Group-MainTankIcon")
			icon:Show()
		elseif isHealer then
			icon:SetTexture("Interface\\AddOns\\TPerl\\Images\\TPerl_RoleHealer_old")
			icon:Show()
		elseif isDamage then
			icon:SetTexture("Interface\\GroupFrame\\UI-Group-MainAssistIcon")
			icon:Show()
		else
			icon:Hide()
		end
	else
		if isTank then
			icon:SetTexture("Interface\\AddOns\\TPerl\\Images\\TPerl_RoleTank")
			icon:Show()
		elseif isHealer then
			icon:SetTexture("Interface\\AddOns\\TPerl\\Images\\TPerl_RoleHealer")
			icon:Show()
		elseif isDamage then
			icon:SetTexture("Interface\\AddOns\\TPerl\\Images\\TPerl_RoleDamage")
			icon:Show()
		else
			icon:Hide()
		end
	end
end

-------------------------
-- The Update Function --
-------------------------

local function TPerl_Player_CombatFlash(self, elapsed, argNew, argGreen)
	if (TPerl_CombatFlashSet(self, elapsed, argNew, argGreen)) then
		TPerl_CombatFlashSetFrames(self)
	end
end

-- TPerl_Player_UpdateManaType
local function TPerl_Player_UpdateManaType(self)
	TPerl_SetManaBarType(self)
end

-- TPerl_Player_UpdateLeader()
local function TPerl_Player_UpdateLeader(self)
	local nf = self.nameFrame

	-- Loot Master
	local method, pindex, rindex, ml
	if (UnitInParty("party1") or UnitInRaid("player")) then
		method, pindex, rindex = GetLootMethod()

		if (method == "master") then
			if (rindex ~= nil) then
				ml = UnitIsUnit("raid"..rindex, "player")
			elseif (pindex and (pindex == 0)) then
				ml = true
			end
		end
	end

	if (ml) then
		nf.masterIcon:Show()
	else
		nf.masterIcon:Hide()
	end

	-- Leader
	if (UnitIsGroupLeader("player")) then
		nf.leaderIcon:Show()
	else
		nf.leaderIcon:Hide()
	end

	if (UnitIsGroupAssistant("player")) then
		nf.assistIcon:Show()
	else
		nf.assistIcon:Hide()
	end

	--UpdateAssignedRoles(self)

	if (pconf and pconf.partyNumber and IsInRaid()) then
		for i = 1, GetNumGroupMembers() do
			local _, _, subgroup = GetRaidRosterInfo(i)
			if (UnitIsUnit("raid"..i, "player")) then
				if (pconf.withName) then
					nf.group:SetFormattedText(TPERL_RAID_GROUPSHORT, subgroup)
					nf.group:Show()
					self.groupFrame:Hide()
					return
				else
					self.groupFrame.text:SetFormattedText(TPERL_RAID_GROUP, subgroup)
					self.groupFrame:Show()
					nf.group:Hide()
					return
				end
			end
		end
	end

	nf.group:Hide()
	self.groupFrame:Hide()
end

local function TPerl_Player_UpdateRaidTarget(self)
	TPerl_Update_RaidIcon(self.nameFrame.raidIcon, self.partyid)
end

-- TPerl_Player_UpdateCombat
local function TPerl_Player_UpdateCombat(self)
	local nf = self.nameFrame
	if (UnitAffectingCombat("player")) then
		nf.text:SetTextColor(1, 0, 0)
		nf.combatIcon:SetTexCoord(0.49, 1, 0, 0.49)
		nf.combatIcon:Show()
	else
		if (self.partyid ~= "player") then
			local c = conf.colour.reaction.none
			nf.text:SetTextColor(c.r, c.g, c.b, conf.transparency.text)
		else
			TPerl_ColourFriendlyUnit(nf.text, self.partyid)
		end

		if (IsResting()) then
			nf.combatIcon:SetTexCoord(0, 0.49, 0, 0.49)
			nf.combatIcon:Show()
		else
			nf.combatIcon:Hide()
		end
	end
end

-- TPerl_Player_UpdateName()
local function TPerl_Player_UpdateName(self)
	playerName = UnitName(self.partyid)
	self.nameFrame.text:SetText(playerName)
	TPerl_Player_UpdateCombat(self)
end

-- TPerl_Player_UpdateClass
local function TPerl_Player_UpdateClass(self)
	local _, class = UnitClass(self.partyid)
	playerClass = class
	playerName = UnitName(self.partyid)
	local l, r, t, b = TPerl_ClassPos(playerClass)
	self.classFrame.tex:SetTexCoord(l, r, t, b)

	if (pconf.classIcon) then
		self.classFrame:Show()
	else
		self.classFrame:Hide()
	end
end

-- There are two different functions to get faction info, used in retail/classic/era.
-- To maintain compatibility, we fake the original function if it's not there.
local GetWatchedFactionInfo
if _G.GetWatchedFactionInfo then
	GetWatchedFactionInfo = _G.GetWatchedFactionInfo
else
	GetWatchedFactionInfo = function()
		local data = C_Reputation.GetWatchedFactionData()
		if data then
			return data.name, data.reaction, data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding, data.factionID
		end
		return nil, nil, nil, nil, nil, nil -- documenting that there should be six returns.
	end
end

-- TPerl_Player_UpdateRep
local function TPerl_Player_UpdateRep(self)
	if (pconf and pconf.repBar) then
		local rb = self.statsFrame.repBar
		if (rb) then
			local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
			local color
			local perc

			--[[if not min or not max or not value then
				return
			end]]

			if max == 43000 then
				max = 42000
			end

			if (factionID == 1733 or factionID == 1736 or factionID == 1737 or factionID == 1738 or factionID == 1739 or factionID == 1740 or factionID == 1741) and min == 20000 and max == 21000 and value == 20000 then
				min = 21000
				value = 21000
			end

			if name then
				color = FACTION_BAR_COLORS[reaction]
				if min > 0 and max > 0 and value > 0 and min ~= max and min ~= value then
					value = value - min
					max = max - min
				end
				min = 0
				if value > 0 and max > 0 then
					perc = (value * 100) / max
				else
					perc = 100
				end
			else
				name = TPERL_LOC_NONEWATCHED
				value = 0
				max = 1
				min = 0
				color = FACTION_BAR_COLORS[4]
				perc = 0
			end

			rb:SetMinMaxValues(min, max)
			rb:SetValue(value)

			rb:SetStatusBarColor(color.r, color.g, color.b, 1)
			rb.bg:SetVertexColor(color.r, color.g, color.b, 0.25)

			if perc < 0 then
				perc = 0
			elseif perc > 100 then
				perc = 100
			end

			rb.tex:SetTexCoord(0, perc / 100, 0, 1)

			if max == 1 then
				rb.text:SetText(name)
			else
				rb.text:SetFormattedText("%d/%d", value, max)
			end

			if perc < 100 then
				rb.percent:SetFormattedText(perc1F, perc)
			else
				rb.percent:SetFormattedText(percD, perc)
			end
		end
	end
end

-- TPerl_Player_UpdateXP
local function TPerl_Player_UpdateXP(self)
	if (pconf.xpBar) then
		local xpBar = self.statsFrame.xpBar
		if (xpBar) then
			local restBar = self.statsFrame.xpRestBar
			local playerxp = UnitXP("player")
			local playerxpmax = UnitXPMax("player")
			local playerxprest = GetXPExhaustion() or 0
			xpBar:SetMinMaxValues(0, playerxpmax)
			restBar:SetMinMaxValues(0, playerxpmax)
			xpBar:SetValue(playerxp)

			local color
			local w = xpBar:GetRight() - xpBar:GetLeft()
			for mode = 1, 3 do
				local suffix
				if (playerxprest > 0) then
					if (mode == 1) then
						suffix = format(" +%d", playerxprest)
					elseif (mode == 2) then
						if (playerxprest >= 1000000) then
							suffix = format(" +%.1fM", playerxprest / 1000000)
						else
							suffix = format(" +%.1fk", playerxprest / 1000)
						end
					else
						if (playerxprest >= 1000000) then
							suffix = format(" +%dM", playerxprest / 1000000)
						else
							suffix = format(" +%dk", playerxprest / 1000)
						end
					end

					color = {r = 0.3, g = 0.3, b = 1}
				else
					color = {r = 0.6, g = 0, b = 0.6}
				end

				if (pconf.xpDeficit) then
					TPerl_SetValuedText(xpBar.text, playerxp - playerxpmax, playerxpmax, suffix)
				else
					TPerl_SetValuedText(xpBar.text, playerxp, playerxpmax, suffix)
				end
				if (xpBar.text:GetStringWidth() + 20 <= w) then
					break
				end
			end

			xpBar:SetStatusBarColor(color.r, color.g, color.b, 1)
			xpBar.bg:SetVertexColor(color.r, color.g, color.b, 0.25)
			local x = playerxp / playerxpmax
			if x > 1 then
				x = 1
			end
			xpBar.tex:SetTexCoord(0, x, 0, 1)

			restBar:SetValue(playerxp + playerxprest)
			restBar:SetStatusBarColor(color.r, color.g, color.b, 0.5)
			local y = (playerxp + playerxprest) / playerxpmax
			if y > 1 then
				y = 1
			end
			restBar.tex:SetTexCoord(0, y, 0, 1)
			restBar.bg:SetVertexColor(color.r, color.g, color.b, 0.25)
			xpBar.percent:SetFormattedText(percD, (playerxp * 100) / playerxpmax)
		end
	end
end

-- TPerl_Player_UpdatePVPTimer
function TPerl_Player_UpdatePVPTimerOnUpdate(self, elapsed)
	self.time = (self.time or 0) + elapsed
	if self.time >= 0.5 then
		local timeLeft = GetPVPTimer()

		if timeLeft > 0 then
			timeLeft = floor(timeLeft / 1000)
			self.text:SetFormattedText("%d:%02d", timeLeft / 60, timeLeft % 60)
		end

		self.time = 0
	end
end

-- TPerl_Player_UpdatePVPTimer
local function TPerl_Player_UpdatePVPTimer(self)
	if pconf.pvpIcon and IsPVPTimerRunning() then
		self.nameFrame.pvptimer:Show()
	else
		self.nameFrame.pvptimer:Hide()
		self.nameFrame.pvptimer.text:SetText("")
	end
end

-- TPerl_Player_UpdatePVP
local function TPerl_Player_UpdatePVP(self)
	-- PVP Status settings
	--local nf = self.nameFrame
	if (UnitAffectingCombat(self.partyid)) then
		self.nameFrame.text:SetTextColor(1, 0, 0)
	else
		TPerl_ColourFriendlyUnit(self.nameFrame.text, "player")
	end

	local pvpIcon = self.nameFrame.pvp

	local factionGroup, factionName = UnitFactionGroup("player")

	if pconf.pvpIcon and UnitIsPVPFreeForAll("player") then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		pvpIcon:Show()
	elseif pconf.pvpIcon and factionGroup and factionGroup ~= "Neutral" and UnitIsPVP("player") then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)

		if not IsClassic and UnitIsMercenary("player") then
			if factionGroup == "Horde" then
				pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
			elseif factionGroup == "Alliance" then
				pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
			end
		end

		pvpIcon:Show()
	else
		pvpIcon:Hide()
	end

	TPerl_Player_UpdatePVPTimer(self)

	--[[local pvp = pconf.pvpIcon and ((UnitIsPVPFreeForAll("player") and "FFA") or (UnitIsPVP("player") and (UnitFactionGroup("player") ~= "Neutral") and UnitFactionGroup("player")))
	if (pvp) then
		nf.pvp.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		nf.pvp:Show()
	else
		nf.pvp:Hide()
	end]]
end

-- CreateBar(self, name)
local function CreateBar(self, name)
	local f = CreateFrame("StatusBar", self.statsFrame:GetName()..name, self.statsFrame, "TPerlStatusBar")
	f:SetPoint("TOPLEFT", self.statsFrame.manaBar, "BOTTOMLEFT", 0, 0)
	f:SetHeight(10)
	self.statsFrame[name] = f
	f:SetWidth(112)
	return f
end

-- MakeDruidBar()
local function MakeDruidBar(self)
	local f = CreateBar(self, "druidBar")
	local c = conf.colour.bar.mana
	f:SetStatusBarColor(c.r, c.g, c.b)
	f.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
	MakeDruidBar = nil
end

-- TPerl_Player_DruidBarUpdate
function TPerl_Player_DruidBarUpdate(self)
	local druidBar = self.statsFrame.druidBar
	if (pconf.noDruidBar) then
		if (druidBar) then
			druidBar:Hide()
			TPerl_StatsFrameSetup(self, {self.statsFrame.xpBar, self.statsFrame.repBar})
			--[[if (TPerl_Player_Buffs_Position) then
				TPerl_Player_Buffs_Position(self)
			end]]
		end
		return
	elseif (not druidBar) then
		if (MakeDruidBar) then
			MakeDruidBar(self)
			druidBar = self.statsFrame.druidBar
		end
	end
	
	
	if IsRetail then
	 local maxMana = UnitPowerMax("player", 0)
		local currMana = UnitPower("player", 0)
		local currMana100 = UnitPowerPercent("player", Enum.PowerType.Mana, false, CurveConstants.ScaleTo100)
		druidBar:SetMinMaxValues(0, maxMana)
		druidBar:SetValue(currMana)
	 druidBar.text:SetFormattedText("%d/%d", currMana, maxMana)
		druidBar.percent:SetText(currMana100 .. "%")
	else
	 local maxMana = UnitPowerMax("player", 0)
		local currMana = UnitPower("player", 0)
	 if maxMana == 0 then
		 maxMana = nil
		end
		druidBar:SetMinMaxValues(0, maxMana or 1)
		druidBar:SetValue(currMana or 0)
	 druidBar.text:SetFormattedText("%d/%d", ceil(currMana or 0), maxMana or 1)
		druidBar.percent:SetFormattedText(percD, (currMana or 0) * 100 / (maxMana or 1))
	end
	

	--local druidBarExtra
	if ((playerClass == "DRUID" or playerClass == "PRIEST") and UnitPowerType(self.partyid) > 0) or (playerClass == "SHAMAN" and not IsClassic and GetSpecialization() == 1 and GetShapeshiftForm() == 0) then -- Shaman's UnitPowerType is buggy
		if (pconf.values) then
			druidBar.text:Show()
		else
			druidBar.text:Hide()
		end
		if (pconf.percent) then
			druidBar.percent:Show()
		else
			druidBar.percent:Hide()
		end
		druidBar:Show()
		--druidBar:SetHeight(10)
		--druidBarExtra = 1
	else
		--druidBar.percent:Hide()
		--druidBar.text:Hide()
		druidBar:Hide()
		--druidBar:SetHeight(1)
		--druidBarExtra = 0
	end

	--[[if druidBarExtra == 1 then
		ComboPointPlayerFrame:SetPoint("TOPLEFT", self.runes, "CENTER", -35, 18 - 5)
	else
		ComboPointPlayerFrame:SetPoint("TOPLEFT", self.runes, "CENTER", -35, 18)
	end]]

	-- Highlight update
	--[[if (druidBarExtra) then
		self.highlight:SetPoint("TOPLEFT", self.levelFrame, "TOPLEFT", 0, 0)
		self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
	else
		self.highlight:SetPoint("BOTTOMLEFT", self.classFrame, "BOTTOMLEFT", -2, -2)
		self.highlight:SetPoint("TOPRIGHT", self.nameFrame, "TOPRIGHT", 0, 0)
	end]]

	--[[local h = 40 + ((druidBarExtra + (pconf.repBar and 1 or 0) + (pconf.xpBar and 1 or 0)) * 10)
	if InCombatLockdown() then
		TPerl_ProtectedCall(TPerl_Player_DruidBarUpdate, self)
	else
		if (pconf.extendPortrait) then
			self.portraitFrame:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
		else
			self.portraitFrame:SetHeight(62)
		end
	end
	if (InCombatLockdown() and pconf.showRunes) then
		TPerl_ProtectedCall(TPerl_Player_DruidBarUpdate, self)
	else
		self.statsFrame:SetHeight(h)
	end]]

	TPerl_StatsFrameSetup(self, {druidBar, self.statsFrame.xpBar, self.statsFrame.repBar})
	--[[if (TPerl_Player_Buffs_Position) then
		TPerl_Player_Buffs_Position(self)
	end]]
end

-- TPerl_Player_UpdateMana
local function TPerl_Player_UpdateMana(self)
	local powerType = TPerl_GetDisplayedPowerType(self.partyid)
	local powerPercent
	local unitPower = UnitPower(self.partyid, powerType)
	local unitPowerMax = UnitPowerMax(self.partyid, powerType)

	self.statsFrame.manaBar:SetMinMaxValues(0, unitPowerMax)
	self.statsFrame.manaBar:SetValue(unitPower)

 if not IsRetail then
		-- Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
		if unitPower > 0 and unitPowerMax == 0 then -- We have current mana but max mana failed.
			unitPowerMax = unitPower -- Make max mana at least equal to current health
			powerPercent = 1 -- And percent 100% cause a number divided by itself is 1, duh.
		elseif unitPower == 0 and unitPowerMax == 0 then -- Probably doesn't use mana or is oom?
			powerPercent = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
		else
			powerPercent = unitPower / unitPowerMax -- Everything is dandy, so just do it right way.
		end
 	-- end division by 0 check
	else
	 --Retail code
		powerPercent = UnitPowerPercent(self.partyid)
		powerPercent100 = UnitPowerPercent(self.partyid, UnitPowerType(self.partyid), false, CurveConstants.ScaleTo100)
	end

	--self.statsFrame.manaBar.text:SetFormattedText("%d/%d", playermana, playermanamax)
	TPerl_SetValuedText(self.statsFrame.manaBar.text, unitPower, unitPowerMax)

	if (powerType >= 1 or UnitPowerMax(self.partyid, powerType) < 1) then
		self.statsFrame.manaBar.percent:SetText(unitPower)
	else
		if not IsRetail then
 		self.statsFrame.manaBar.percent:SetFormattedText(percD, powerPercent * 100)
		else
		 self.statsFrame.manaBar.percent:SetFormattedText(percD, powerPercent100)
		end
	end

 if not IsRetail then
	 self.statsFrame.manaBar.tex:SetTexCoord(0, max(0, (powerPercent)), 0, 1)
	else
	 self.statsFrame.manaBar.tex:SetTexCoord(0, powerPercent, 0, 1)
	end

	if (not self.statsFrame.greyMana) then
		if (pconf.values) then
			self.statsFrame.manaBar.text:Show()
		end
		if (pconf.percent) then
			self.statsFrame.manaBar.percent:Show()
		end
	end

	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		TPerl_Player_DruidBarUpdate(self)
	end
end

-- TPerl_Player_UpdateHealPrediction
local function TPerl_Player_UpdateHealPrediction(self)
	if pconf.healprediction then
		TPerl_SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

-- TPerl_Player_UpdateAbsorbPrediction
local function TPerl_Player_UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		TPerl_SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

-- TPerl_Player_UpdateHotsPrediction
local function TPerl_Player_UpdateHotsPrediction(self)
	if not (IsCataClassic or IsMistsClassic) then
		return
	end
	if pconf.hotPrediction then
		TPerl_SetExpectedHots(self)
	else
		self.statsFrame.expectedHots:Hide()
	end
end

local function TPerl_Player_UpdateResurrectionStatus(self)
	if UnitHasIncomingResurrection(self.partyid) then
		if pconf.portrait then
			self.portraitFrame.resurrect:Show()
		else
			self.statsFrame.resurrect:Show()
		end
	else
		if pconf.portrait then
			self.portraitFrame.resurrect:Hide()
		else
			self.statsFrame.resurrect:Hide()
		end
	end
end

-- TPerl_Player_UpdateHealth
local function TPerl_Player_UpdateHealth(self)
	local partyid = self.partyid
	local sf = self.statsFrame
	local hb = sf.healthBar
	local playerhealth, playerhealthmax
	if not IsRetail then
	 playerhealth, playerhealthmax = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid)), UnitHealthMax(partyid)
	else
	 playerhealth, playerhealthmax = UnitHealth(partyid), UnitHealthMax(partyid)
	end
 if IsRetail then
	 -- Only blizz can return the inverse since no math on hp values.
		local playerInverseHp = UnitHealthPercent(partyid, false, CurveConstants.Reverse)
	else
	 local playerInverseHp = 0 -- Not used in anything but retail.
	end

	self.afk = UnitIsAFK(partyid) and conf.showAFK == 1
	
	
 --print(partyid, playerhealth, playerhealthmax, playerInverseHp)
	TPerl_SetHealthBar(self, playerhealth, playerhealthmax, playerInverseHp)
	if not IsRetail then
		--Not implemented in retail yet.
		--FLAG: IMPLEMENTME
		TPerl_Player_UpdateAbsorbPrediction(self)
		TPerl_Player_UpdateHotsPrediction(self)
		TPerl_Player_UpdateHealPrediction(self)
		TPerl_Player_UpdateResurrectionStatus(self)
	end

	local greyMsg
	if not IsRetail then
		if (UnitIsDead(partyid)) then
			greyMsg = TPERL_LOC_DEAD
		elseif (UnitIsGhost(partyid)) then
			greyMsg = TPERL_LOC_GHOST
		elseif (UnitIsAFK("player") and conf.showAFK) then
			greyMsg = CHAT_MSG_AFK
		--elseif (conf.showFD and UnitBuff(partyid, feignDeath)) then
			--greyMsg = TPERL_LOC_FEIGNDEATHSHORT
		--elseif (UnitBuff(partyid, spiritOfRedemption)) then
			--greyMsg = TPERL_LOC_DEAD
		end
 else
	 if (UnitIsDead(partyid)) then
			greyMsg = TPERL_LOC_DEAD
		elseif (UnitIsGhost(partyid)) then
			greyMsg = TPERL_LOC_GHOST
		elseif (UnitIsAFK("player") and conf.showAFK) then
			greyMsg = CHAT_MSG_AFK
		elseif (conf.showFD and C_Spell.GetSpellInfo(5384) and
            C_UnitAuras.GetAuraDataBySpellName(partyid,C_Spell.GetSpellInfo(5384).name,"HELPFUL")) then
			greyMsg = TPERL_LOC_FEIGNDEATHSHORT
		elseif (C_Spell.GetSpellInfo(20711) and
            C_UnitAuras.GetAuraDataBySpellName(partyid,C_Spell.GetSpellInfo(20711).name,"HELPFUL")) then
			greyMsg = TPERL_LOC_DEAD
		end
	end
	
	if (greyMsg) then
		if (pconf.percent) then
			hb.percent:SetText(greyMsg)
			hb.percent:Show()
		else
			hb.text:SetText(greyMsg)
			hb.text:Show()
		end

		sf:SetGrey()
	else
		if (sf.greyMana) then
			if (not pconf.values) then
				hb.text:Hide()
			end

			sf.greyMana = nil
			TPerl_Player_UpdateManaType(self)
		end
	end

	TPerl_PlayerStatus_OnUpdate(self, playerhealth, playerhealthmax)
end

-- TPerl_Player_UpdateLevel
local function TPerl_Player_UpdateLevel(self)
	local color = GetDifficultyColor(UnitLevel(self.partyid))
	self.levelFrame.text:SetTextColor(color.r, color.g, color.b, conf.transparency.text)

	self.levelFrame.text:SetText(UnitLevel(self.partyid))
end


-- TPerl_PlayerStatus_OnUpdate
function TPerl_PlayerStatus_OnUpdate(self, val, max)
	if (pconf.fullScreen.enable) then
		local testLow = pconf.fullScreen.lowHP / 100
		local testHigh = pconf.fullScreen.highHP / 100

		if not IsRetail then
		 -- I will research but unless I can compare hp in some way or tell its LOW
			-- then we cant run this in Retail.
			if (val and max and val > 0 and max > 0) then
				local test = val / max

				if ( test <= testLow and not TPerl_LowHealthFrame.frameFlash and not UnitIsDeadOrGhost("player")) then
					TPerl_FrameFlash(TPerl_LowHealthFrame)
				elseif ( (test >= testHigh and TPerl_LowHealthFrame.frameFlash) or UnitIsDeadOrGhost("player") ) then
					TPerl_FrameFlashStop(TPerl_LowHealthFrame, "out")
				end
				return
			else
				if (not UnitOnTaxi("player")) then
					if (isOutOfControl and not TPerl_OutOfControlFrame.frameFlash and not UnitOnTaxi("player")) then
						TPerl_FrameFlash(TPerl_OutOfControlFrame)
					elseif (not isOutOfControl and TPerl_OutOfControlFrame.frameFlash) then
						TPerl_FrameFlashStop(TPerl_OutOfControlFrame, "out")
					end
					return
				end
			end
		end
	end

	if (TPerl_LowHealthFrame.frameFlash) then
		TPerl_FrameFlashStop(TPerl_LowHealthFrame)
	end
	if (TPerl_OutOfControlFrame.frameFlash) then
		TPerl_FrameFlashStop(TPerl_OutOfControlFrame)
	end
end

-- TPerl_Player_OnUpdate
function TPerl_Player_OnUpdate(self, elapsed)
	if pconf.hitIndicator and pconf.portrait then
		 CombatFeedback_OnUpdate(self, elapsed)
	end

	local partyid = self.partyid
	local newAFK = UnitIsAFK(partyid)

	if (conf.showAFK and newAFK ~= self.afk) then
		TPerl_Player_UpdateHealth(self)
	end

	if (self.PlayerFlash) then
		TPerl_Player_CombatFlash(self, elapsed, false)
	end

	--TPerl_Player_UpdateMana(self)

	--[[if (IsResting() and UnitLevel("player") < 85) then
		self.restingDelay = (self.restingDelay or 2) - elapsed
		if (self.restingDelay <= 0) then
			self.restingDelay = 2
			TPerl_Player_UpdateXP(self)
		end
	end]]--

	-- Attempt to fix "not-updating bug", suggested by Taylla @ Curse (why was this code in onupdate function twice? identicle code, twice)
	--[[if (self.updateAFK) then
		self.updateAFK = nil
		TPerl_Player_UpdateHealth(self)
	end]]--
end

-- TPerl_Player_UpdateBuffs
local function TPerl_Player_UpdateBuffs(self)
	-- TODO: create a highlight handler for the player too
	if (conf.highlightDebuffs.enable) then
		TPerl_CheckDebuffs(self, self.partyid)
	end

	if (playerClass == "DRUID") then
		TPerl_Player_UpdateMana(self)
	end

	if (pconf.fullScreen.enable) then
		if (isOutOfControl and not UnitOnTaxi("player")) then
			TPerl_PlayerStatus_OnUpdate(self)
		end
	end
end

-- TPerl_Player_UpdateDisplay
function TPerl_Player_UpdateDisplay(self)
	TPerl_Player_UpdateXP(self)
	TPerl_Player_UpdateRep(self)
	TPerl_Player_UpdateManaType(self)
	TPerl_Player_UpdateLevel(self)
	TPerl_Player_UpdateName(self)
	TPerl_Player_UpdateClass(self)
	TPerl_Player_UpdatePVP(self)
	TPerl_Player_UpdateCombat(self)
	TPerl_Player_UpdateLeader(self)
	TPerl_Player_UpdateRaidTarget(self)
	TPerl_Player_UpdateMana(self)
	TPerl_Player_UpdateHealth(self)
	TPerl_Player_UpdateBuffs(self)
	TPerl_Unit_UpdatePortrait(self)
end

-- EVENTS AND STUFF

-------------------
-- Event Handler --
-------------------
function TPerl_Player_OnEvent(self, event, unit, ...)
	if string.find(event, "^UNIT_") then
		if (unit == "player" or unit == "vehicle") then
			if event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_COMBAT" then
				TPerl_Player_Events[event](self, unit, ...)
			else
				TPerl_Player_Events[event](self, ...)
			end
		end
	else
		TPerl_Player_Events[event](self, event, unit, ...)
	end
end

function TPerl_Player_Events:PLAYER_ALIVE()
	TPerl_Player_UpdateDisplay(self)
end


-- PLAYER_ENTERING_WORLD
function TPerl_Player_Events:PLAYER_ENTERING_WORLD(event, initialLogin, reloadingUI)
	self.updateAFK = true

	if (not IsVanillaClassic and UnitHasVehicleUI("player")) then
		self.partyid = "vehicle"
		self.unit = self.partyid
		if self.runes and self.runes.child and self.runes.child.unit then
			self.runes.child.unit = self.partyid
		end
		self:SetAttribute("unit", "vehicle")
		if (TPerl_ArcaneBar_SetUnit) then
			TPerl_ArcaneBar_SetUnit(self.nameFrame, "vehicle")
		end
	else
		self.partyid = "player"
		self.unit = self.partyid
		if self.runes and self.runes.child and self.runes.child.unit then
			self.runes.child.unit = self.partyid
		end
		self:SetAttribute("unit", "player")
		if (TPerl_ArcaneBar_SetUnit) then
			TPerl_ArcaneBar_SetUnit(self.nameFrame, "player")
		end
	end

	if (initialLogin or reloadingUI) and not InCombatLockdown() then
		self.state:SetFrameRef("TPerlPlayer", self)
		self.state:SetFrameRef("TPerlPlayerPortrait", self.portraitFrame)
		self.state:SetFrameRef("TPerlPlayerStats", self.statsFrame)

		local class, classFileName, classID = UnitClass("player")

		self.state:SetAttribute("playerClass", classFileName)
		if not IsClassic then
			self.state:SetAttribute("playerSpec", GetSpecialization())
		end
		self.state:SetAttribute("extendedPortrait", pconf.extendPortrait)
		self.state:SetAttribute("druidBarOff", pconf.noDruidBar)
		self.state:SetAttribute("xpBar", pconf.xpBar)
		self.state:SetAttribute("repBar", pconf.repBar)
		self.state:SetAttribute("special", pconf.showRunes)
		self.state:SetAttribute("docked", pconf.dockRunes)

		self.state:Execute([[
			frame = self:GetFrameRef("TPerlPlayer")
			portrait = self:GetFrameRef("TPerlPlayerPortrait")
			stats = self:GetFrameRef("TPerlPlayerStats")
		]])

		self.state:SetAttribute("_onstate-petbattleupdate", [[
			if newstate == "inpetbattle" then
				frame:Hide()
			else
				local buffs = self:GetFrameRef("TPerlPlayerBuffs")

				local class = self:GetAttribute("playerClass")
				local spec = self:GetAttribute("playerSpec")
				local extend = self:GetAttribute("extendedPortrait")
				local bar = self:GetAttribute("druidBarOff")
				local xp = self:GetAttribute("xpBar")
				local rep = self:GetAttribute("repBar")
				local special = self:GetAttribute("spec")
				local docked = self:GetAttribute("docked")
				local above = self:GetAttribute("buffsAbove")

				local offset = 10 * ((bar and 0 or 1) + (xp and 1 or 0) + (rep and 1 or 0))
				local buffoffset = 13.5 * ((bar and 0 or 1) + (xp and 1 or 0) + (rep and 1 or 0))

				if class == "DRUID" then
					if spec == 1 then
						if newstate == 1 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						elseif newstate == 2 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0 - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
									end
								else
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									end
								end
							end
						elseif newstate == 3 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						elseif newstate == 4 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						else
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						end
					elseif spec == 2 or spec == 3 or spec == 4 then
						if newstate == 1 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						elseif newstate == 2 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0 - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
									end
								else
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									end
								end
							end
						elseif newstate == 3 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						else
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						end
					else
						if newstate == 1 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						elseif newstate == 2 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						elseif newstate == 3 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						elseif newstate == 4 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						else
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						end
					end
				elseif class == "PRIEST" then
					if spec == 1 or spec == 2 then
						if extend then
							frame:SetHeight(62 + offset)
							portrait:SetHeight(62 + offset)
						else
							frame:SetHeight(62)
							portrait:SetHeight(62)
						end
						if bar then
							stats:SetHeight(40 + offset)
						else
							stats:SetHeight(40 + offset - 10)
						end
						if not above and buffs then
							if extend then
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
							else
								if bar then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
								end
							end
						end
					elseif spec == 3 then
						if extend then
							frame:SetHeight(62 + offset)
							portrait:SetHeight(62 + offset)
						else
							frame:SetHeight(62)
							portrait:SetHeight(62)
						end
						stats:SetHeight(40 + offset)
						if not above and buffs then
							if extend then
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
							else
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
							end
						end
					end
				elseif class == "SHAMAN" then
					if spec == 1 then
						if newstate == 1 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						else
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						end
					elseif spec == 2 or spec == 3 then
						if extend then
							if bar then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62 + offset - 10)
								portrait:SetHeight(62 + offset - 10)
							end
						else
							frame:SetHeight(62)
							portrait:SetHeight(62)
						end
						if bar then
							stats:SetHeight(40 + offset)
						else
							stats:SetHeight(40 + offset - 10)
						end
						if not above and buffs then
							if extend then
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
							else
								if bar then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
								end
							end
						end
					end
				end

				frame:Show()
			end
		]])

		RegisterStateDriver(self.state, "petbattleupdate", "[petbattle] inpetbattle; [form:0] 0; [form:1] 1; [form:2] 2; [form:3] 3; [form:4] 4; none")
	end

	TPerl_Player_UpdateDisplay(self)

	--C_Timer.After(0.1, function() TPerl_Player_Set_Bits(self) end)
end

-- UNIT_COMBAT
function TPerl_Player_Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end

	if (pconf.hitIndicator and pconf.portrait) then
		CombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
	end

	if (action == "HEAL") then
		TPerl_Player_CombatFlash(self, 0, true, true)
	elseif (damage and damage > 0) then
		TPerl_Player_CombatFlash(self, 0, true)
	end
end

-- UNIT_PORTRAIT_UPDATE
function TPerl_Player_Events:UNIT_PORTRAIT_UPDATE()
	TPerl_Unit_UpdatePortrait(self, true)
end

-- VARIABLES_LOADED
function TPerl_Player_Events:VARIABLES_LOADED()

	self.doubleCheckAFK = 2 -- Check during 2nd UPDATE_FACTION, which are the last guarenteed events to come after logging in
	self:UnregisterEvent("VARIABLES_LOADED")

	local events = {
		"PLAYER_ENTERING_WORLD",
		"PARTY_LEADER_CHANGED",
		"PARTY_LOOT_METHOD_CHANGED",
		"GROUP_ROSTER_UPDATE",
		"PLAYER_UPDATE_RESTING",
		"PLAYER_REGEN_ENABLED",
		"PLAYER_REGEN_DISABLED",
		"PLAYER_ENTER_COMBAT",
		"PLAYER_LEAVE_COMBAT",
		"PLAYER_DEAD",
		"PLAYER_SPECIALIZATION_CHANGED",
		"UPDATE_FACTION",
		"UNIT_AURA",
		"PLAYER_CONTROL_LOST",
		"PLAYER_CONTROL_GAINED",
		"UNIT_COMBAT",
		"UNIT_POWER_FREQUENT",
		"UNIT_MAXPOWER",
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		"UNIT_LEVEL",
		"UNIT_DISPLAYPOWER",
		"UNIT_NAME_UPDATE",
		"UNIT_FACTION",
		"UNIT_PORTRAIT_UPDATE",
		"UNIT_FLAGS",
		"PLAYER_FLAGS_CHANGED",
		"UNIT_ENTERED_VEHICLE",
		"UNIT_EXITING_VEHICLE",
		--"UNIT_PET",
		"PLAYER_TALENT_UPDATE",
		"RAID_TARGET_UPDATE",
		"UPDATE_SHAPESHIFT_FORM",
		"UPDATE_EXHAUSTION",
		--"PET_BATTLE_OPENING_START",
		--"PET_BATTLE_CLOSE",
		"INCOMING_RESURRECT_CHANGED",
	}

	for i, event in pairs(events) do
		if string.find(event, "^UNIT_") or string.find(event, "^INCOMING") then
			if event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITING_VEHICLE" then
				if pcall(self.RegisterUnitEvent, self, event, "player") then
					self:RegisterUnitEvent(event, "player")
				end
			else
				if pcall(self.RegisterUnitEvent, self, event, "player", "vehicle") then
					self:RegisterUnitEvent(event, "player", "vehicle")
				end
			end
		else
			if pcall(self.RegisterEvent, self, event) then
				self:RegisterEvent(event)
			end
		end
	end

	--TPerl_Player_UpdateDisplay(self)

	TPerl_Player_Events.VARIABLES_LOADED = nil
end

--[[function TPerl_Player_Events:PET_BATTLE_OPENING_START()
	if (self) then
		self:Hide()
	end
end

function TPerl_Player_Events:PET_BATTLE_CLOSE()
	if (self) then
		self:Show()
	end
end]]

function TPerl_Player_Events:UPDATE_EXHAUSTION()
	TPerl_Player_UpdateXP(self)
end

-- PARTY_LOOT_METHOD_CHANGED
function TPerl_Player_Events:PARTY_LOOT_METHOD_CHANGED()
	TPerl_Player_UpdateLeader(self)
end

-- PARTY_LEADER_CHANGED
function TPerl_Player_Events:PARTY_LEADER_CHANGED()
	TPerl_Player_UpdateLeader(self)
end

-- GROUP_ROSTER_UPDATE
function TPerl_Player_Events:GROUP_ROSTER_UPDATE()
	TPerl_Player_UpdateLeader(self)
end

-- UNIT_HEALTH_FREQUENT
function TPerl_Player_Events:UNIT_HEALTH_FREQUENT()
	TPerl_Player_UpdateHealth(self)
end

-- UNIT_HEALTH
function TPerl_Player_Events:UNIT_HEALTH()
	TPerl_Player_UpdateHealth(self)
end

-- UNIT_MAXHEALTH
function TPerl_Player_Events:UNIT_MAXHEALTH()
	TPerl_Player_UpdateHealth(self)
end

-- PLAYER_DEAD
function TPerl_Player_Events:PLAYER_DEAD()
	TPerl_Player_UpdateHealth(self)
end

-- UNIT_POWER_FREQUENT
function TPerl_Player_Events:UNIT_POWER_FREQUENT()
	TPerl_Player_UpdateMana(self)
end

-- UNIT_MAXPOWER
function TPerl_Player_Events:UNIT_MAXPOWER()
	TPerl_Player_UpdateMana(self)
end

-- UNIT_DISPLAYPOWER
function TPerl_Player_Events:UNIT_DISPLAYPOWER()
	TPerl_Player_UpdateManaType(self)
	TPerl_Player_UpdateMana(self)
end

-- UNIT_NAME_UPDATE
function TPerl_Player_Events:UNIT_NAME_UPDATE()
	TPerl_Player_UpdateName(self)
end

-- UNIT_LEVEL
function TPerl_Player_Events:UNIT_LEVEL()
	TPerl_Player_UpdateLevel(self)
	TPerl_Player_UpdateXP(self)
end

-- PLAYER_XP_UPDATE
function TPerl_Player_Events:PLAYER_XP_UPDATE()
	TPerl_Player_UpdateXP(self)
end

-- UPDATE_FACTION
function TPerl_Player_Events:UPDATE_FACTION()
	TPerl_Player_UpdateRep(self)

	if (self.doubleCheckAFK) then
		if (conf and pconf) then
			self.doubleCheckAFK = self.doubleCheckAFK - 1
			if (self.doubleCheckAFK <= 0) then
				TPerl_Player_UpdateHealth(self)
				self.doubleCheckAFK = nil
			end
		end
	end
end

-- UNIT_FACTION
function TPerl_Player_Events:UNIT_FACTION()
	TPerl_Player_UpdateHealth(self)
	TPerl_Player_UpdatePVP(self)
	TPerl_Player_UpdateCombat(self)
end
TPerl_Player_Events.UNIT_FLAGS = TPerl_Player_Events.UNIT_FACTION

function TPerl_Player_Events:PLAYER_FLAGS_CHANGED()
	TPerl_Player_UpdateHealth(self)
	TPerl_Player_UpdatePVPTimer(self)
end

-- RAID_TARGET_UPDATE
function TPerl_Player_Events:RAID_TARGET_UPDATE()
	TPerl_Player_UpdateRaidTarget(TPerl_Player)
end

-- PLAYER_TALENT_UPDATE
function TPerl_Player_Events:PLAYER_TALENT_UPDATE()
	TPerl_Player_UpdateMana(self)

	if (playerClass == "MONK") then
		if (TPerl_Player_Buffs_Position) then
			TPerl_Player_Buffs_Position(self)
		end
	end
end

-- UPDATE_SHAPESHIFT_FORM
function TPerl_Player_Events:UPDATE_SHAPESHIFT_FORM()
	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		TPerl_Player_DruidBarUpdate(self)
	end

	--[[if playerClass ~= "DRUID" then
		return
	end

	TPerl_Unit_UpdatePortrait(self, true)]]
end

-- PLAYER_ENTER_COMBAT, PLAYER_LEAVE_COMBAT
function TPerl_Player_Events:PLAYER_ENTER_COMBAT()
	TPerl_Player_UpdateCombat(self)
end
TPerl_Player_Events.PLAYER_LEAVE_COMBAT = TPerl_Player_Events.PLAYER_ENTER_COMBAT

-- PLAYER_REGEN_ENABLED
function TPerl_Player_Events:PLAYER_REGEN_ENABLED()
	TPerl_Player_UpdateCombat(self)

	if (self:GetAttribute("unit") ~= self.partyid) then
		self:SetAttribute("unit", self.partyid)
		TPerl_Player_UpdateDisplay(self)
	end
end

-- PLAYER_REGEN_DISABLED
function TPerl_Player_Events:PLAYER_REGEN_DISABLED()
	TPerl_Player_UpdateCombat(self)
end

function TPerl_Player_Events:PLAYER_UPDATE_RESTING()
	TPerl_Player_UpdateCombat(self)
	TPerl_Player_UpdateXP(self)
end

function TPerl_Player_Events:PLAYER_SPECIALIZATION_CHANGED()
	if not InCombatLockdown() then
		if not IsClassic then
			self.state:SetAttribute("playerSpec", GetSpecialization())
		end
		TPerl_Player_Set_Bits(self)

		--[[if ((playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST")) then
			C_Timer.After(0.1, function() TPerl_Player_Set_Bits(self) end)
		end--]]
	end

	if TPerl_Player_Buffs_Position then
		TPerl_Player_Buffs_Position(TPerl_Player)
	end
end

function TPerl_Player_Events:UNIT_AURA()
	TPerl_Player_UpdateBuffs(self)

	--[[if conf.showFD then
		local _, class = UnitClass(self.partyid)
		if (class == "HUNTER") then
			local feigning = UnitBuff(self.partyid, feignDeath)
			if (feigning ~= self.feigning) then
				self.feigning = feigning
				TPerl_Player_UpdateHealth(self)
			end
		end
	end--]]
end

-- PLAYER_CONTROL_LOST
function TPerl_Player_Events:PLAYER_CONTROL_LOST()
	if pconf.fullScreen.enable and not UnitOnTaxi("player") then
		isOutOfControl = true
	end
end

-- PLAYER_CONTROL_GAINED
function TPerl_Player_Events:PLAYER_CONTROL_GAINED()
	isOutOfControl = nil
	if (pconf.fullScreen.enable) then
		TPerl_PlayerStatus_OnUpdate(self)
	end
end

-- UNIT_ENTERED_VEHICLE
function TPerl_Player_Events:UNIT_ENTERED_VEHICLE(showVehicle)
	if showVehicle then
		self.partyid = "vehicle"
		self.unit = self.partyid
		if pconf.showRunes and self.runes then
			if self.runes.child then
				self.runes.child.unit = self.partyid
				self.runes.child:Setup()
			end
			if self.runes.child2 then
				self.runes.child2:Hide()
			end
		end
		if TPerl_ArcaneBar_SetUnit then
			TPerl_ArcaneBar_SetUnit(self.nameFrame, "vehicle")
		end
		--[[if (not InCombatLockdown()) then
			self:SetAttribute("unit", "vehicle")
		end]]
		TPerl_Player_UpdateDisplay(self)
		--TPerl_SetUnitNameColor(self.nameFrame.text, self.partyid)
	end
end

-- UNIT_EXITING_VEHICLE
function TPerl_Player_Events:UNIT_EXITING_VEHICLE()
	if self.partyid ~= "player" then
		self.partyid = "player"
		self.unit = self.partyid
		if pconf.showRunes and self.runes then
			if self.runes.child then
				self.runes.child.unit = self.partyid
				self.runes.child:Setup()
			end
			if self.runes.child2 then
				local _, playerClass = UnitClass(self.partyid)
				if playerClass == self.runes.child2.requiredClass then
					if playerClass == "MONK" and GetSpecialization() == self.runes.child2.requiredSpec then
						self.runes.child2:Show()
					elseif playerClass == "DRUID" then
						EclipseBar_UpdateShown(EclipseBarFrame)
					elseif playerClass == "DEATHKNIGHT" or playerClass == "PALADIN" or playerClass == "WARLOCK" then
						self.runes.child2:Show()
					end
				end
			end
		end
		if TPerl_ArcaneBar_SetUnit then
			TPerl_ArcaneBar_SetUnit(self.nameFrame, "player")
		end
		--[[if (not InCombatLockdown()) then
			self:SetAttribute("unit", "player")
		end]]
		TPerl_Player_UpdateDisplay(self)
	end
end

-- UNIT_PET
--[[function TPerl_Player_Events:UNIT_PET()
	self.partyid = (not IsVanillaClassic and UnitHasVehicleUI("player")) and "pet" or "player"
	TPerl_Player_UpdateDisplay(self)
end--]]

function TPerl_Player_Events:UNIT_HEAL_PREDICTION(unit)
	if pconf.healprediction and unit == self.partyid then
		TPerl_SetExpectedHealth(self)
	end
	if not (IsCataClassic or IsMistsClassic) then
		return
	end
	if pconf.hotPrediction and unit == self.partyid then
		TPerl_SetExpectedHots(self)
	end
end

function TPerl_Player_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if (pconf.absorbs and unit == self.partyid) then
		TPerl_SetExpectedAbsorbs(self)
	end
end

function TPerl_Player_Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		TPerl_Player_UpdateResurrectionStatus(self)
	end
end

-- TPerl_Player_SetWidth
function TPerl_Player_SetWidth(self)
	pconf.size.width = max(0, pconf.size.width or 0)
	if (pconf.percent) then
		self.nameFrame:SetWidth(160 + pconf.size.width)
		self.statsFrame:SetWidth(160 + pconf.size.width)
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()

		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.percent:Show()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.percent:Show()
		end
	else
		self.nameFrame:SetWidth(128 + pconf.size.width)
		self.statsFrame:SetWidth(128 + pconf.size.width)
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.percent:Hide()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.percent:Hide()
		end
	end

	local h = 40 + ((((self.statsFrame.druidBar and self.statsFrame.druidBar:IsShown()) and 1 or 0) + (pconf.repBar and 1 or 0) + (pconf.xpBar and 1 or 0)) * 10)
	self.statsFrame:SetHeight(h)

	self:SetWidth(128 + (pconf.portrait and 1 or 0) * 62 + (pconf.percent and 1 or 0) * 32 + pconf.size.width)
	self:SetScale(pconf.scale)

	TPerl_StatsFrameSetup(self, {self.statsFrame.druidBar, self.statsFrame.xpBar, self.statsFrame.repBar})
	if (TPerl_Player_Buffs_Position) then
		TPerl_Player_Buffs_Position(self)
	end

	TPerl_Player_UpdateHealth(self)
	TPerl_Player_UpdateMana(self)
	TPerl_Player_UpdateXP(self)

	TPerl_SavePosition(self, true)
	TPerl_RestorePosition(self)
end

-- MakeXPBar
local function MakeXPBar(self)
	local f = CreateBar(self, "xpBar")
	local f2 = CreateBar(self, "xpRestBar")

	f2:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	f2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

	MakeXPBar = nil
end

-- TPerl_Player_SetTotems  |  MoveTotems   |   Movers
function TPerl_Player_SetTotems()
	if (pconf.totems and pconf.totems.enable) then
		TotemFrame:SetParent(TPerl_Player)
		TotemFrame:ClearAllPoints()
		TotemFrame:SetPoint("TOP", TPerl_Player, "BOTTOM", pconf.totems.offsetX, pconf.totems.offsetY + (TotemFrame:GetHeight()/2))
		TotemFrame:Show()
	else
		TotemFrame:SetParent(PlayerFrame)
		TotemFrame:ClearAllPoints()
		TotemFrame:Hide()
		if IsRetail then
			TotemFrame:SetPoint("TOPRIGHT", PlayerFrame, "BOTTOMRIGHT", 0, 20)
		else
			TotemFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 99, 38)
		end
	end
end

-- TPerl_Player_Set_Bits()
function TPerl_Player_Set_Bits(self)
 --print("TPerl_Player.lua:2082")
	if (TPerl_ArcaneBar_RegisterFrame and not self.nameFrame.castBar) then
		TPerl_ArcaneBar_RegisterFrame(self.nameFrame, (not IsVanillaClassic and UnitHasVehicleUI("player")) and "vehicle" or "player")
	end

	if not InCombatLockdown() then
		self.state:SetAttribute("extendedPortrait", pconf.extendPortrait)
		self.state:SetAttribute("druidBarOff", pconf.noDruidBar)
		self.state:SetAttribute("xpBar", pconf.xpBar)
		self.state:SetAttribute("repBar", pconf.repBar)
		self.state:SetAttribute("spec", pconf.showRunes)
		self.state:SetAttribute("specDock", pconf.dockRunes)
	end

	if (pconf.level) then
		self.levelFrame:Show()
	else
		self.levelFrame:Hide()
	end

	TPerl_Player_UpdateClass(self)

	if (pconf.repBar) then
		if (not self.statsFrame.repBar) then
			CreateBar(self, "repBar")
		end

		self.statsFrame.repBar:Show()
	else
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar:Hide()
		end
	end

	if (pconf.xpBar) then
		if (not self.statsFrame.xpBar) then
			MakeXPBar(self)
		end

		self.statsFrame.xpBar:Show()
		self.statsFrame.xpRestBar:Show()

		self:RegisterEvent("PLAYER_XP_UPDATE")
	else
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar:Hide()
			self.statsFrame.xpRestBar:Hide()
		end

		self:UnregisterEvent("PLAYER_XP_UPDATE")
	end

	if (pconf.values) then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
		if (self.statsFrame.druidBar) then
			self.statsFrame.druidBar.text:Show()
		end
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.text:Show()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.text:Show()
		end
	else
		self.statsFrame.healthBar.text:Hide()
		self.statsFrame.manaBar.text:Hide()
		if (self.statsFrame.druidBar) then
			self.statsFrame.druidBar.text:Hide()
		end
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.text:Hide()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.text:Hide()
		end
	end

	TPerl_Register_Prediction(self, pconf, function (guid)
		if guid == UnitGUID("player") then
			return "player"
		elseif guid == UnitGUID("vehicle") then
			return "vehicle"
		end
	end, "player", "vehicle")

	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		TPerl_Player_DruidBarUpdate(self)
	end

	if not InCombatLockdown() then
		if (pconf.portrait) then
			self.portraitFrame:Show()
			self.portraitFrame:SetWidth(62)
			self.statsFrame.resurrect:Hide()
		else
			self.portraitFrame:Hide()
			self.portraitFrame:SetWidth(3)
		end

		TPerl_Player_SetWidth(self)

		local h1 = self.nameFrame:GetHeight() + self.statsFrame:GetHeight() - 2
		local h2 = self.portraitFrame:GetHeight()
		TPerl_SwitchAnchor(self, "TOPLEFT")
		self:SetHeight(max(h1, h2))

		if (pconf.extendPortrait --[[or (self.runes and pconf.showRunes and pconf.dockRunes)]]) then
			local druidBarExtra
			if (UnitPowerType(self.partyid) > 0 and not pconf.noDruidBar) and ((playerClass == "DRUID") or (playerClass == "PRIEST") or (playerClass == "SHAMAN" and not IsClassic and GetSpecialization() == 1 and GetShapeshiftForm() == 0)) then
				druidBarExtra = 1
			else
				druidBarExtra = 0
			end

			self:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
			self.portraitFrame:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
		else
			self:SetHeight(62)
			self.portraitFrame:SetHeight(62)
		end
	end

	if (self.runes) then
		if (pconf.showRunes) then
			self.runes:Show()
		else
			self.runes:Hide()
		end
	end

	--[[self.highlight:ClearAllPoints()
	if (not pconf.level and not pconf.classIcon and (not TPerlConfigHelper or TPerlConfigHelper.ShowTargetCounters == 0)) then
		self.highlight:SetPoint("TOPLEFT", self.portraitFrame, "TOPLEFT", 0, 0)
	else
		self.highlight:SetPoint("TOPLEFT", self.levelFrame, "TOPLEFT", 0, 0)
	end
	self.highlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)]]

	if (playerClass == "SHAMAN" or playerClass == "DRUID" or playerClass == "MAGE" or playerClass == "MONK" or playerClass == "PRIEST" or playerClass == "WARRIOR" or playerClass == "WARLOCK" or playerClass == "PALADIN") then
		if (not pconf.totems) then
			pconf.totems = {
				enable = true,
				offsetX = 0,
				offsetY = 0
			}
		end
		
		if not pconf.SpecialPowerBars then
			pconf.SpecialPowerBars = {
				showDemonicFuryText = true,  -- default ON
			}
		elseif pconf.SpecialPowerBars.showDemonicFuryText == nil then
			-- If the section exists but the entry doesn’t, default it
			pconf.SpecialPowerBars.showDemonicFuryText = true
		end


		if (not IsVanillaClassic) and (not IsTBCAnni) then
			if (pconf.totems and pconf.totems.enable and not self.totemHooked) then
				local moving
				hooksecurefunc(TotemFrame, "SetPoint", function(self)
					if not pconf.totems.enable then
						return
					end
					if moving then
						return
					end
					moving = true
					self:SetMovable(true)
					self:ClearAllPoints()
					self:SetPoint("TOP", TPerl_Player, "BOTTOM", pconf.totems.offsetX, pconf.totems.offsetY)
					self:SetMovable(false)
					moving = nil
				end)
				local parenting
				hooksecurefunc(TotemFrame, "SetParent", function(self)
					if not pconf.totems.enable then
						return
					end
					if parenting then
						return
					end
					parenting = true
					self:SetMovable(true)
					self:SetParent(TPerl_Player)
					self:ClearAllPoints()
					self:SetPoint("TOP", TPerl_Player, "BOTTOM", pconf.totems.offsetX, pconf.totems.offsetY)
					self:SetMovable(false)
					parenting = nil
				end)
				self.totemHooked = true
				TPerl_Player_SetTotems()
			else
				TPerl_Player_SetTotems()
			end
		end
	end

	self:SetAlpha(conf.transparency.frame)

	self.buffOptMix = nil
	TPerl_Player_UpdateDisplay(self)

	if (TPerl_Player_BuffSetup) then
		if (self.buffFrame) then
			self.buffOptMix = nil
			TPerl_Player_BuffSetup(TPerl_Player)
		end
	end

	if (TPerl_Voice) then
		TPerl_Voice:Register(self)
	end

	--UpdateAssignedRoles(self)
end

local function MakeMoveable(frame)
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:RegisterForDrag("LeftButton")

	frame:SetScript("OnDragStart", function(self)
		if (not pconf.dockRunes) then
		 self:EnableMouse(true)
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		if (not pconf.dockRunes) then
			self:EnableMouse(false)
			self:StopMovingOrSizing()
			TPerl_SavePosition(self)
		end
	end)
end



-- TPerl_Player_InitDruid | Complete | Has Watcher
function TPerl_Player_InitDruid(self, playerClass)
    if playerClass ~= "DRUID" then
        return
    end
				
				if IsRetail then
								if TPerlSpecialPowerBarFrame then return end

								-- Movable container
								TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
								Mixin(TPerlSpecialPowerBarFrame, DruidComboPointBarMixin)
								TPerlSpecialPowerBarFrame:SetSize(200, 40)
								TPerlSpecialPowerBarFrame:SetPoint("CENTER", UIParent, "CENTER", pconf.comboX or 0, pconf.comboY or -120)
								TPerlSpecialPowerBarFrame.unit = "player"
								TPerlSpecialPowerBarFrame.powerType = Enum.PowerType.ComboPoints

								-- Provide the GetUnit method (expected by mixin)
								function TPerlSpecialPowerBarFrame:GetUnit()
												return self.unit or "player"
								end

								-- Dragging / saving position
								TPerlSpecialPowerBarFrame:SetMovable(true)
								TPerlSpecialPowerBarFrame:EnableMouse(not pconf.lockRunes)
								TPerlSpecialPowerBarFrame:RegisterForDrag("LeftButton")
								TPerlSpecialPowerBarFrame:SetScript("OnDragStart", function(self)
												if not pconf.lockRunes then self:StartMoving() end
								end)
								TPerlSpecialPowerBarFrame:SetScript("OnDragStop", function(self)
												self:StopMovingOrSizing()
												-- Save position if not docked
												if not (pconf and pconf.dockRunes) then
																local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
																TPerlSpecialPowerBarFramePos = {
																				point = point,
																				relativePoint = relativePoint,
																				x = xOfs,
																				y = yOfs,
																}
												end
								end)

								---------------------------------------------------
								-- Build buttons using Blizzard’s template
								---------------------------------------------------
								TPerlSpecialPowerBarFrame.classResourceButtonTable = {}
								local maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 5
								local spacing, size = 6, 28

								for i = 1, maxPoints do
												local button = CreateFrame("Frame", nil, TPerlSpecialPowerBarFrame, "DruidComboPointTemplate")
												Mixin(button, DruidComboPointMixin)
												button:SetSize(size, size)

												if i == 1 then
																button:SetPoint("LEFT", TPerlSpecialPowerBarFrame, "LEFT", 0, 0)
												else
																button:SetPoint("LEFT", TPerlSpecialPowerBarFrame.classResourceButtonTable[i-1], "RIGHT", spacing, 0)
												end

												button:Setup()
												TPerlSpecialPowerBarFrame.classResourceButtonTable[i] = button
								end

								---------------------------------------------------
								-- Visibility handler
								---------------------------------------------------
								function TPerlSpecialPowerBarFrame:UpdateVisibility()
												if self:ShouldShowBar() then
																self:Show()
												else
																self:Hide()
												end
								end

								---------------------------------------------------
								-- Event handling
								---------------------------------------------------
								TPerlSpecialPowerBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
								TPerlSpecialPowerBarFrame:RegisterEvent("UNIT_POWER_UPDATE")
								TPerlSpecialPowerBarFrame:RegisterEvent("UNIT_DISPLAYPOWER")
								TPerlSpecialPowerBarFrame:RegisterEvent("UNIT_MAXPOWER")
								TPerlSpecialPowerBarFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
								TPerlSpecialPowerBarFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
												if event == "UNIT_POWER_UPDATE" and (arg1 ~= "player" or arg2 ~= "COMBO_POINTS") then
																return
												elseif (event == "UNIT_DISPLAYPOWER" or event == "UNIT_MAXPOWER") and arg1 ~= "player" then
																return
												end

												self:UpdateVisibility()
												self:UpdatePower()
								end)

								-- Initial state
								TPerlSpecialPowerBarFrame:UpdateVisibility()
								TPerlSpecialPowerBarFrame:UpdatePower()

								return
				end

    ---------------------------------------------------
    -- Cata/Mists → Balance (Eclipse) Bar
    ---------------------------------------------------
    if (IsCataClassic or IsMistsClassic) then
        -- Always create self.runes for compatibility
        self.runes = CreateFrame("Frame", "TPerl_Runes", self)
        self.runes:SetPoint("TOPLEFT", self.portraitFrame, "BOTTOMLEFT", 0, 2)
        self.runes:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, -30)
        self.runes.unit = "player"

        local function UpdateBalanceBarVisibility()
            local spec = TPerl_GetMonkSpec()  -- returns 1/2/3 talent tree index
            if spec == 1 then                 -- Balance tree
                if not MovableBalanceBar or not MovableBalanceBar.Created then
                    MovableBalanceBar = CreateFrame("Frame", "MovableBalanceBar", UIParent)
																				MovableBalanceBar.unit = "player"
                    TPerl_BuildBalanceBar_Mists(MovableBalanceBar)
                    MovableBalanceBar.Created = true
                end
                MovableBalanceBar:Show()
            else
                if MovableBalanceBar then
                    MovableBalanceBar:Hide()
                end
            end
        end

        if not MovableDruidWatcher then
            MovableDruidWatcher = CreateFrame("Frame", "MovableDruidWatcher", UIParent)
            MovableDruidWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
            MovableDruidWatcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            MovableDruidWatcher:SetScript("OnEvent", function(_, _, arg1)
                if arg1 == "player" or not arg1 then
                    UpdateBalanceBarVisibility()
                end
            end)
        end

        -- Initial build
        UpdateBalanceBarVisibility()
    end
end

function TPerl_Player_InitRogue(self, playerClass) end

function TPerl_Player_InitWarlock()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then return end

    local function BuildWarlockBar()
        -- Clear any existing bar first
        if TPerlSpecialPowerBarFrame then
            TPerlSpecialPowerBarFrame:UnregisterAllEvents()
            TPerlSpecialPowerBarFrame:Hide()
            TPerlSpecialPowerBarFrame = nil
        end

        TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
	       TPerlSpecialPowerBarFrame.unit = "player"
								
        if IsRetail then
            -- Retail: all specs use unified shard builder
            TPerl_BuildWarlockSoulShardBar_Retail(TPerlSpecialPowerBarFrame)

        elseif IsMistsClassic then
            local spec = TPerl_GetWarlockSpec()

            if spec == 1 then
                -- Affliction → Soul Shards
                TPerl_BuildWarlockSoulShardBar_Mists(TPerlSpecialPowerBarFrame)


            elseif spec == 2 then
                -- Demonology → Demonic Fury bar
                TPerl_BuildWarlockDemonicFuryBar_Mists(TPerlSpecialPowerBarFrame)

      

            elseif spec == 3 then
                -- Destruction → Burning Embers
                TPerl_BuildWarlockBurningEmbersBar_Mists(TPerlSpecialPowerBarFrame)

            end
        end
    end

    -- Run immediately on init
    BuildWarlockBar()

    -- Watch for spec changes and rebuild
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    watcher:SetScript("OnEvent", function(_, _, arg1)
        if arg1 == "player" or not arg1 then
            BuildWarlockBar()
        end
    end)
end


-- TPerl_Player_InitPaladin | Complete | Has Watcher
function TPerl_Player_InitPaladin(self, playerClass)
    if playerClass ~= "PALADIN" then return end
    if not (IsMistsClassic or IsRetail) then return end

    ---------------------------------------------------
    -- Builder call wrapper
    ---------------------------------------------------
    local function UpdatePaladinBarVisibility()
        local spec = TPerl_GetMonkSpec()  
        -- MoP: 1 = Holy, 2 = Prot, 3 = Ret
        -- Retail: 65 Holy, 66 Prot, 70 Ret

        if IsMistsClassic then
            --if spec == 2 or spec == 3 then  -- Prot / Ret only in MoP
                if not TPerlSpecialPowerBarFrame or not TPerlSpecialPowerBarFrame.Created then
                    TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
																				TPerlSpecialPowerBarFrame.unit = "player"
                    TPerl_BuildPaladinHolyPowerBar_Mists(TPerlSpecialPowerBarFrame)
                    TPerlSpecialPowerBarFrame.Created = true
                end
                TPerlSpecialPowerBarFrame:Show()
            -- else
                -- if TPerlSpecialPowerBarFrame then
                    -- TPerlSpecialPowerBarFrame:Hide()
                -- end
            -- end

        elseif IsRetail then
            local specIndex = GetSpecialization()
            local specID = specIndex and GetSpecializationInfo(specIndex)

            --if specID == 66 or specID == 70 then  -- Prot and Ret only
												if not TPerlSpecialPowerBarFrame or not TPerlSpecialPowerBarFrame.Created then
																TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
																TPerlSpecialPowerBarFrame.unit = "player"
																TPerl_BuildPaladinHolyPowerBar_Retail(TPerlSpecialPowerBarFrame)
																TPerlSpecialPowerBarFrame.Created = true
												end
                TPerlSpecialPowerBarFrame:Show()
            --else
                -- if TPerlSpecialPowerBarFrame then
                    -- TPerlSpecialPowerBarFrame:Hide()
                -- end
            -- end
        end
    end

    ---------------------------------------------------
    -- Watcher to handle spec swaps / reloads
    ---------------------------------------------------
    if not MovablePaladinWatcher then
        MovablePaladinWatcher = CreateFrame("Frame", "MovablePaladinWatcher", UIParent)
        MovablePaladinWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
        MovablePaladinWatcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        MovablePaladinWatcher:SetScript("OnEvent", function(_, _, arg1)
            if arg1 == "player" or not arg1 then
                UpdatePaladinBarVisibility()
            end
        end)
    end

    ---------------------------------------------------
    -- Initial build
    ---------------------------------------------------
    UpdatePaladinBarVisibility()
end


--TPerl_Player_InitPriest | Complete | Has Watcher
function TPerl_Player_InitPriest(self, playerClass)
    if playerClass ~= "PRIEST" then return end

    if (IsMistsClassic or IsCataClassic) then
        if not TPerlSpecialPowerBarFrame then
            TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
												TPerlSpecialPowerBarFrame.unit = "player"
            TPerlSpecialPowerBarFrame:SetSize(160, 40)
            TPerl_BuildPriestShadowOrbBar_Mists(TPerlSpecialPowerBarFrame)
        end

        local function UpdateShadowOrbVisibility()
            local spec = TPerl_GetPriestSpec()
            if spec == 3 then -- Shadow in Classic
                TPerlSpecialPowerBarFrame:Show()
            else
                -- tear down
                TPerlSpecialPowerBarFrame:Hide()
                TPerlSpecialPowerBarFrame:UnregisterAllEvents()
            end
        end

        -- watcher frame, not the orbs themselves
        local watcher = CreateFrame("Frame")
        watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
        watcher:RegisterEvent("PLAYER_TALENT_UPDATE")
        watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") -- exists in Mists but not in Cata
        watcher:SetScript("OnEvent", function()
            UpdateShadowOrbVisibility()
        end)

        UpdateShadowOrbVisibility()
    end
end


-- TPerl_Player_InitMonk | Complete | Has Watcher
function TPerl_Player_InitMonk(self, playerClass)
    local _, class = UnitClass("player")
    if class ~= "MONK" then return end

    -- Bail out if we're not in Retail or Mists (Monks don't exist elsewhere)
    if not (IsRetail or IsMistsClassic) then
        return
    end

    ---------------------------------------------------
    -- Builder: Create / Clear bars depending on spec
    ---------------------------------------------------
    local function BuildMonkBars()
        local spec = TPerl_GetMonkSpec()
								--print(spec)
        -- Retail → 268 Brewmaster, 269 Windwalker, 270 Mistweaver
        -- Mists  → 1 Brewmaster, 2 WW, 3 MW

        if IsRetail then
            -- Harmony (Chi) → Windwalker only
            if spec == 269 or spec == 270 then
                if not TPerlSpecialPowerBarFrame or not TPerlSpecialPowerBarFrame.Created then
                    TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
																				TPerlSpecialPowerBarFrame.unit = "player"
																				TPerlSpecialPowerBarFrame:EnableMouse(not pconf.lockRunes)
                    TPerl_BuildMonkHarmonyBar(TPerlSpecialPowerBarFrame)
                    TPerlSpecialPowerBarFrame.Created = true
                end
            else
                if TPerlSpecialPowerBarFrame then
                    TPerlSpecialPowerBarFrame:UnregisterAllEvents()
                    TPerlSpecialPowerBarFrame:Hide()
                    TPerlSpecialPowerBarFrame = nil
                end
            end

            -- Stagger → Brewmaster only
            if spec == 268 then
                if not TPerlSpecialPowerBarFrame2 or not TPerlSpecialPowerBarFrame2.Created then
                    TPerlSpecialPowerBarFrame2 = CreateFrame("Frame", "TPerlSpecialPowerBarFrame2", UIParent)
																				TPerlSpecialPowerBarFrame2.unit = "player"
																				TPerlSpecialPowerBarFrame2:EnableMouse(not pconf.lockRunes)
                    TPerl_BuildMonkStaggerBar(TPerlSpecialPowerBarFrame2)
                    TPerlSpecialPowerBarFrame2.Created = true
                end
            else
                if TPerlSpecialPowerBarFrame2 then
                    TPerlSpecialPowerBarFrame2:UnregisterAllEvents()
                    TPerlSpecialPowerBarFrame2:Hide()
                    TPerlSpecialPowerBarFrame2 = nil
                end
            end

        elseif IsMistsClassic then
            -- Harmony (Chi) → all specs in MoP
            if not TPerlSpecialPowerBarFrame or not TPerlSpecialPowerBarFrame.Created then
                TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
																TPerlSpecialPowerBarFrame.unit = "player"
																TPerlSpecialPowerBarFrame:EnableMouse(not pconf.lockRunes)
                TPerl_BuildMonkHarmonyBar_Mists(TPerlSpecialPowerBarFrame)
                TPerlSpecialPowerBarFrame.Created = true
            end

            -- Stagger → Brewmaster tree only
            if spec == 1 then
                if not TPerlSpecialPowerBarFrame2 or not TPerlSpecialPowerBarFrame2.Created then
                    TPerlSpecialPowerBarFrame2 = CreateFrame("Frame", "TPerlSpecialPowerBarFrame2", UIParent)
																				TPerlSpecialPowerBarFrame2.unit = "player"
																				TPerlSpecialPowerBarFrame2:EnableMouse(not pconf.lockRunes)
                    TPerl_BuildMonkStaggerBar_Mists(TPerlSpecialPowerBarFrame2)
                    TPerlSpecialPowerBarFrame2.Created = true
                end
            else
                if TPerlSpecialPowerBarFrame2 then
                    TPerlSpecialPowerBarFrame2:UnregisterAllEvents()
                    TPerlSpecialPowerBarFrame2:Hide()
                    TPerlSpecialPowerBarFrame2 = nil
                end
            end
        end
    end

    ---------------------------------------------------
    -- Watcher: Spec changes / reloads
    ---------------------------------------------------
    if not MovableMonkWatcher then
        MovableMonkWatcher = CreateFrame("Frame", "MovableMonkWatcher", UIParent)
        MovableMonkWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
        MovableMonkWatcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        MovableMonkWatcher:SetScript("OnEvent", function(_, _, arg1)
            if arg1 == "player" or not arg1 then
                BuildMonkBars()
            end
        end)
    end

    ---------------------------------------------------
    -- Initial build
    ---------------------------------------------------
    BuildMonkBars()
end


--TPerl_Player_InitMage | Complete | Has Watcher
function TPerl_Player_InitMage(self, playerClass)
    if playerClass ~= "MAGE" then return end

    ---------------------------------------------------
    -- Function to (re)build the bar
    ---------------------------------------------------
    local function EnsureArcaneBar()
        if not TPerlSpecialPowerBarFrame then
            TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
            TPerlSpecialPowerBarFrame.unit = "player"
        end

        -- If already has UpdateCharges, we assume it’s built
        if not TPerlSpecialPowerBarFrame.UpdateCharges then
            if IsMistsClassic then
                TPerl_BuildMageArcaneChargesBar_Mists(TPerlSpecialPowerBarFrame)
            elseif IsRetail then
                TPerl_BuildMageArcaneChargesBar_Retail(TPerlSpecialPowerBarFrame)
            end
        end
    end

    ---------------------------------------------------
    -- Spec watcher
    ---------------------------------------------------
    local function UpdateArcaneChargesVisibility()
        local spec = TPerl_GetMonkSpec()
        local isArcane = (IsRetail and spec == 62) or (IsMistsClassic and spec == 1)

        if isArcane then
            EnsureArcaneBar()
            TPerlSpecialPowerBarFrame:Show()
            -- re-enable events if bar supports them
            if TPerlSpecialPowerBarFrame.UpdateCharges then
                TPerlSpecialPowerBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
                TPerlSpecialPowerBarFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
                TPerlSpecialPowerBarFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
            end
        elseif TPerlSpecialPowerBarFrame then
            TPerlSpecialPowerBarFrame:Hide()
            TPerlSpecialPowerBarFrame:UnregisterAllEvents()
        end
    end

    local ArcaneWatcher = CreateFrame("Frame")
    ArcaneWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    ArcaneWatcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ArcaneWatcher:SetScript("OnEvent", function(_, _, arg1)
        if arg1 == "player" or not arg1 then
            UpdateArcaneChargesVisibility()
        end
    end)

    -- Run once at init
    UpdateArcaneChargesVisibility()
end



--TPerl_Player_InitDK | Complete | Watcher not needed.
function TPerl_Player_InitDK(self, playerClass)
	if playerClass ~= "DEATHKNIGHT" then
		return
	end

	if not TPerlSpecialPowerBarFrame then
    TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
				TPerlSpecialPowerBarFrame.unit = "player"
    if IsRetail then
        TPerl_BuildDKRuneFrame(TPerlSpecialPowerBarFrame)
    elseif IsMistsClassic then
        TPerl_BuildDKRuneFrame_Mists(TPerlSpecialPowerBarFrame)
    end
	end
----------

end


--TPerl_Player_InitEvoker | Complete | Has Watcher
function TPerl_Player_InitEvoker(self, playerClass)
    if playerClass ~= "EVOKER" then
        return
    end

    if not TPerlSpecialPowerBarFrame then
        TPerlSpecialPowerBarFrame = CreateFrame("Frame", "TPerlSpecialPowerBarFrame", UIParent)
								TPerlSpecialPowerBarFrame.unit = "player"
        TPerlSpecialPowerBarFrame:SetMovable(true)
        TPerlSpecialPowerBarFrame:SetClampedToScreen(true)
        TPerlSpecialPowerBarFrame:SetSize(150, 30)
        TPerlSpecialPowerBarFrame:Show()

        TPerl_BuildEvokerEssenceBar_Retail(TPerlSpecialPowerBarFrame)
    end

    ---------------------------------------------------
    -- Spec / visibility watcher
    ---------------------------------------------------
    if not EvokerWatcher then
        EvokerWatcher = CreateFrame("Frame")
        EvokerWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
        EvokerWatcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

        local function UpdateEssenceVisibility()
            local specIndex = GetSpecialization()
            local specID = specIndex and GetSpecializationInfo(specIndex)
            -- All specs use Essence, so show always
            if playerClass == "EVOKER" then
                TPerlSpecialPowerBarFrame:Show()
            else
                TPerlSpecialPowerBarFrame:Hide()
            end
        end

        EvokerWatcher:SetScript("OnEvent", function(self, event, ...)
            UpdateEssenceVisibility()
        end)

        -- Run once at init
        UpdateEssenceVisibility()
    end
end




---------------------------------------------------
-- Monk Builder Code (Mists / Retail)
---------------------------------------------------
function TPerl_GetMonkSpec()
	if IsRetail then
  local specIndex = GetSpecialization()
		if specIndex then
 		return GetSpecializationInfo(specIndex)
			-- 268 = Brewmaster, 269 = Windwalker
		end 
	elseif IsMistsClassic then
  local specIndex = GetPrimaryTalentTree()
		return specIndex
		-- 1 = Brewmaster, 2 = Mistweaver, 3 = Windwalker
	end
 return nil
end

function TPerl_BuildMonkStaggerBar(frame)
    local BAR_WIDTH = 120
    local BAR_HEIGHT = 12

    frame:SetSize(BAR_WIDTH, BAR_HEIGHT)

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
				if pconf and pconf.dockRunes then
								local specIndex = GetSpecialization()
								local specID = specIndex and GetSpecializationInfo(specIndex)
								if specID == 268 then
												-- Brewmaster: dock Stagger bar to bottom right
												frame:SetPoint("TOPRIGHT", TPerl_Player, "BOTTOMRIGHT", 0, 0)
								else
												-- Hide if not Brewmaster
												frame:Hide()
												return
								end
								frame:EnableMouse(false)
				elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
								frame:SetPoint(
												TPerlSpecialPowerBarFramePos.point,
												UIParent,
												TPerlSpecialPowerBarFramePos.relativePoint,
												TPerlSpecialPowerBarFramePos.x,
												TPerlSpecialPowerBarFramePos.y
								)
								frame:EnableMouse(true)
				else
								frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
								TPerlSpecialPowerBarFramePos = {
												point = "CENTER", relativePoint = "CENTER", x = 0, y = -150,
								}
								frame:EnableMouse(true)
				end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Textured status bar
    ---------------------------------------------------
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetAllPoints(frame)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, UnitHealthMax("player"))
    bar:SetValue(0)
    bar:SetStatusBarColor(0.3, 1.0, 0.3) -- default green
    frame.bar = bar

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(0, 0, 0, 0.5)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    frame.text = text

    ---------------------------------------------------
    -- Update function
    ---------------------------------------------------
    function frame:Update()
								if select(2, UnitClass("player")) ~= "MONK" then
												self:Hide()
												return
								end

								local spec = TPerl_GetMonkSpec()
								if (IsRetail and spec ~= 268) or (IsMistsClassic and spec ~= 1) then
												self:Hide()
												return
								end

								local stagger = UnitStagger("player") or 0
								local maxHealth = UnitHealthMax("player") or 1

								bar:SetMinMaxValues(0, maxHealth)
								bar:SetValue(stagger)

								local percent = (stagger / maxHealth) * 100
								text:SetFormattedText("Stagger: %.1f%%", percent)

								if percent > 60 then
												bar:SetStatusBarColor(1.0, 0.3, 0.3) -- red
								elseif percent > 30 then
												bar:SetStatusBarColor(1.0, 0.9, 0.3) -- yellow
								else
												bar:SetStatusBarColor(0.3, 1.0, 0.3) -- green
								end

								self:Show()
				end


    ---------------------------------------------------
    -- Save position on drag stop
    ---------------------------------------------------
    frame:HookScript("OnDragStop", function(self)
        if not (pconf and pconf.dockRunes) then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Events
    ---------------------------------------------------
    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" then
            self:Update()
            C_Timer.After(0.1, function() self:Update() end)
        elseif event == "UNIT_AURA" and arg1 == "player" then
            self:Update()
        elseif event == "UNIT_MAXHEALTH" and arg1 == "player" then
            self:Update()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
            self:Update()
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

    frame:Update()
end

function TPerl_BuildMonkStaggerBar_Mists(frame)
    local BAR_WIDTH = 120
    local BAR_HEIGHT = 12

    frame:SetSize(BAR_WIDTH, BAR_HEIGHT)
    frame:SetFrameStrata("LOW")

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf and pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(true)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -150,
        }
        frame:EnableMouse(true)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging behavior
    ---------------------------------------------------
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        if not (pconf and pconf.lockRunes) and not (pconf and pconf.dockRunes) then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not (pconf and pconf.dockRunes) then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Textured status bar
    ---------------------------------------------------
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetAllPoints(frame)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, UnitHealthMax("player"))
    bar:SetValue(0)
    bar:SetStatusBarColor(0.3, 1.0, 0.3) -- default green
    frame.bar = bar

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(0, 0, 0, 0.5)
    bg:EnableMouse(false)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    frame.text = text

    ---------------------------------------------------
    -- Update function
    ---------------------------------------------------
    function frame:Update()
        if select(2, UnitClass("player")) ~= "MONK" then
            self:Hide()
            return
        end

        -- In Mists, only Brewmaster (tree 1) has Stagger
        local specIndex = GetPrimaryTalentTree()
        if specIndex ~= 1 then
            self:Hide()
            return
        end

        local stagger = UnitStagger("player") or 0
        local maxHealth = UnitHealthMax("player") or 1

        bar:SetMinMaxValues(0, maxHealth)
        bar:SetValue(stagger)

        local percent = (stagger / maxHealth) * 100
        text:SetFormattedText("Stagger: %.1f%%", percent)

        if percent > 60 then
            bar:SetStatusBarColor(1.0, 0.3, 0.3) -- red
        elseif percent > 30 then
            bar:SetStatusBarColor(1.0, 0.9, 0.3) -- yellow
        else
            bar:SetStatusBarColor(0.3, 1.0, 0.3) -- green
        end

        self:Show()
    end

    ---------------------------------------------------
    -- Events
    ---------------------------------------------------
    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" then
            self:Update()
            C_Timer.After(0.1, function() self:Update() end) -- delayed refresh
        elseif event == "UNIT_AURA" and arg1 == "player" then
            self:Update()
        elseif event == "UNIT_MAXHEALTH" and arg1 == "player" then
            self:Update()
        elseif event == "PLAYER_TALENT_UPDATE" then
            self:Update()
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")

    frame:Update()
end

function TPerl_BuildMonkHarmonyBar(frame)
    local ORB_SIZE = 20
    local ORB_SPACING = 3
    local MAX_ORBS = 6

    frame.orbs = {}

    ---------------------------------------------------
    -- Dynamic parent sizing
    ---------------------------------------------------
    local totalWidth = (ORB_SIZE * MAX_ORBS) + (ORB_SPACING * (MAX_ORBS - 1))
    frame:SetSize(totalWidth, ORB_SIZE)
    frame:SetFrameStrata("LOW")

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf and pconf.dockRunes then
        local specIndex = GetSpecialization()
        local specID = specIndex and GetSpecializationInfo(specIndex)
        if specID == 268 then
            -- Brewmaster: dock Harmony (Chi) bar bottom left
            frame:SetPoint("TOPLEFT", TPerl_Player, "BOTTOMLEFT", 0, 0)
        else
            -- Windwalker: dock bottom center
            frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        end
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -100,
        }
    end
				frame:EnableMouse(not pconf.lockRunes)
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging behavior
    ---------------------------------------------------
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        if not (pconf and pconf.lockRunes) and not (pconf and pconf.dockRunes) then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not (pconf and pconf.dockRunes) then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Orb creation
    ---------------------------------------------------
    local function CreateChiOrb(parent)
        local orb = CreateFrame("Frame", nil, parent)
        orb:SetSize(ORB_SIZE, ORB_SIZE)

        local bg = orb:CreateTexture(nil, "BACKGROUND")
        bg:SetAtlas("uf-chi-bg")
        bg:SetSize(ORB_SIZE, ORB_SIZE)
        bg:SetPoint("CENTER", 0, -2.5)
        orb.Chi_BG = bg

        local bgActive = orb:CreateTexture(nil, "ARTWORK")
        bgActive:SetAtlas("uf-chi-bg-active")
        bgActive:SetSize(ORB_SIZE - 2, ORB_SIZE - 2)
        bgActive:SetPoint("CENTER", 0, -2.5)
        bgActive:SetAlpha(0)
        orb.Chi_BG_Active = bgActive

        local icon = orb:CreateTexture(nil, "OVERLAY")
        icon:SetAtlas("uf-chi-icon")
        icon:SetSize(ORB_SIZE - 6, ORB_SIZE - 6)
        icon:SetPoint("CENTER")
        icon:SetAlpha(0)
        orb.Chi_Icon = icon

        function orb:SetActive(state)
            if self.active == state then return end
            self.active = state
            self.Chi_BG_Active:SetAlpha(state and 1 or 0)
            self.Chi_Icon:SetAlpha(state and 1 or 0)
        end

        return orb
    end

    for i = 1, MAX_ORBS do
        local orb = CreateChiOrb(frame)
        frame.orbs[i] = orb
        orb:SetPoint("LEFT", i == 1 and frame or frame.orbs[i-1],
            i == 1 and "LEFT" or "RIGHT", i == 1 and 0 or ORB_SPACING, 0)
    end

    ---------------------------------------------------
    -- Update function
    ---------------------------------------------------
    function frame:Update()
        if select(2, UnitClass("player")) ~= "MONK" then
            self:Hide()
            return
        end

        local specIndex = GetSpecialization()
        local specID = specIndex and GetSpecializationInfo(specIndex)
        if specID ~= 269 then -- Windwalker only
            self:Hide()
            return
        end

        local chi = UnitPower("player", Enum.PowerType.Chi)
        local maxChi = UnitPowerMax("player", Enum.PowerType.Chi)

        for i = 1, maxChi do
            self.orbs[i]:SetActive(i <= chi)
            self.orbs[i]:Show()
        end
        for i = maxChi+1, #self.orbs do
            self.orbs[i]:Hide()
        end

        self:Show()
    end

    ---------------------------------------------------
    -- Events
    ---------------------------------------------------
    frame:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "PLAYER_ENTERING_WORLD" then
            self:Update()
            C_Timer.After(0.1, function() self:Update() end)
            C_Timer.After(0.5, function() self:Update() end)
        elseif event == "UNIT_DISPLAYPOWER" then
            self:Update()
        elseif event == "UNIT_POWER_UPDATE" and arg1 == "player" and arg2 == "CHI" then
            self:Update()
        elseif event == "UNIT_MAXPOWER" and arg1 == "player" and arg2 == "CHI" then
            self:Update()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
            self:Update()
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

    frame:Update()
end

function TPerl_BuildMonkHarmonyBar_Mists(frame)
    frame:SetSize(136, 43)
    frame:SetFrameStrata("LOW")

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf and pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(true)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -100,
        }
        frame:EnableMouse(true)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end
				
				
				frame:SetMovable(true)
				frame:RegisterForDrag("LeftButton")

				frame:SetScript("OnDragStart", function(self)
								if not (pconf and pconf.lockRunes) then
												self:StartMoving()
								end
				end)

				frame:SetScript("OnDragStop", function(self)
								self:StopMovingOrSizing()
								-- Save position if not docked
								if not (pconf and pconf.dockRunes) then
												local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
												TPerlSpecialPowerBarFramePos = {
																point = point,
																relativePoint = relativePoint,
																x = xOfs,
																y = yOfs,
												}
								end
				end)


    ---------------------------------------------------
    -- Backgrounds (match Blizzard XML)
    ---------------------------------------------------
    local bgShadow = frame:CreateTexture(nil, "BACKGROUND")
    bgShadow:SetTexture("Interface\\PlayerFrame\\MonkUI")
    bgShadow:SetSize(136, 43)
    bgShadow:SetTexCoord(0.00390625, 0.53515625, 0.0078125, 0.34375)
    bgShadow:SetPoint("CENTER")

    local bg = frame:CreateTexture(nil, "BORDER")
    bg:SetTexture("Interface\\PlayerFrame\\MonkUI")
    bg:SetSize(136, 43)
    bg:SetTexCoord(0.00390625, 0.53515625, 0.359375, 0.6953125)
    bg:SetPoint("CENTER")

    ---------------------------------------------------
    -- Orb creation
    ---------------------------------------------------
    local function CreateLightOrb(parent)
        local orb = CreateFrame("Frame", nil, parent)
        orb:SetSize(18, 17)

        local orbOff = orb:CreateTexture(nil, "BACKGROUND")
        orbOff:SetTexture("Interface\\PlayerFrame\\MonkUI")
        orbOff:SetSize(21, 21)
        orbOff:SetTexCoord(0.09375, 0.17578125, 0.7109375, 0.875)
        orbOff:SetPoint("CENTER")

        local glow = orb:CreateTexture(nil, "ARTWORK")
        glow:SetTexture("Interface\\PlayerFrame\\MonkUI")
        glow:SetSize(21, 21)
        glow:SetTexCoord(0.00390625, 0.0859375, 0.7109375, 0.875)
        glow:SetPoint("CENTER")
        glow:SetAlpha(0)
        orb.glow = glow

        function orb:SetEnergy(active)
            if self.active == active then return end
            self.active = active
            glow:SetAlpha(active and 1 or 0)
        end

        return orb
    end

    frame.orbs = {}
    for i = 1, 5 do
        local orb = CreateLightOrb(frame)
        frame.orbs[i] = orb
        if i == 1 then
            orb:SetPoint("LEFT", frame, "CENTER", -43, 1)
        else
            orb:SetPoint("LEFT", frame.orbs[i-1], "RIGHT", 5, 0)
        end
        if i == 5 then orb:Hide() end
    end

    ---------------------------------------------------
    -- Update function
    ---------------------------------------------------
    function frame:Update()
        if select(2, UnitClass("player")) ~= "MONK" then
            self:Hide()
            return
        end

        local chi = UnitPower("player", Enum.PowerType.Chi)
        local maxChi = UnitPowerMax("player", Enum.PowerType.Chi)

        -- Adjust spacing + show/hide 5th orb
        if self.maxLight ~= maxChi then
            if maxChi == 4 then
                self.orbs[1]:SetPoint("LEFT", frame, "CENTER", -43, 1)
                for i = 2, 4 do
                    self.orbs[i]:SetPoint("LEFT", self.orbs[i-1], "RIGHT", 5, 0)
                end
                self.orbs[5]:Hide()
            else
                self.orbs[1]:SetPoint("LEFT", frame, "CENTER", -46, 1)
                for i = 2, 5 do
                    self.orbs[i]:SetPoint("LEFT", self.orbs[i-1], "RIGHT", 1, 0)
                end
                self.orbs[5]:Show()
            end
            self.maxLight = maxChi
        end

        for i = 1, maxChi do
            self.orbs[i]:SetEnergy(i <= chi)
        end

        self:Show()
    end

    ---------------------------------------------------
    -- Events
    ---------------------------------------------------
    frame:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "PLAYER_ENTERING_WORLD" then
            self:Update()
            C_Timer.After(0.1, function() self:Update() end)
        elseif event == "UNIT_POWER_FREQUENT" and arg1 == "player" and (arg2 == "CHI" or arg2 == "DARK_FORCE") then
            self:Update()
        elseif event == "UNIT_MAXPOWER" and arg1 == "player" then
            self:Update()
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")

    frame:Update()
end



---------------------------------------------------
-- Paladin Builder Code (Mists / Retail)
---------------------------------------------------
function TPerl_BuildPaladinHolyPowerBar_Retail(frame)
    local MAX_ORBS = 5

    frame.orbs = {}

    ---------------------------------------------------
    -- Parent sizing and strata
    ---------------------------------------------------
    frame:SetSize(150, 43)
    frame:SetFrameStrata("LOW")

    ---------------------------------------------------
    -- Background holder
    ---------------------------------------------------
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -5)
    bg:SetAtlas("uf-holypower-runeholder", true)
    bg:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.Background = bg

    local bgActive = frame:CreateTexture(nil, "BACKGROUND", nil, -3)
    bgActive:SetAtlas("uf-holypower-runeholder-active", true)
    bgActive:SetPoint("CENTER", frame, "CENTER", 0, 0)
    bgActive:SetAlpha(0)
    frame.BackgroundActive = bgActive

    local bgGlow = frame:CreateTexture(nil, "BACKGROUND", nil, -2)
    bgGlow:SetAtlas("uf-holypower-runeholder-glow", true)
    bgGlow:SetPoint("CENTER", frame, "CENTER", 0, 0)
    bgGlow:SetAlpha(0)
    frame.BackgroundGlow = bgGlow

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf and pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not (pconf and pconf.lockRunes))
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -120,
        }
        frame:EnableMouse(not (pconf and pconf.lockRunes))
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging behavior
    ---------------------------------------------------
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        if not (pconf and pconf.lockRunes) and not (pconf and pconf.dockRunes) then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not (pconf and pconf.dockRunes) then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Rune sizes and offsets (from Blizzard XML)
    ---------------------------------------------------
    local runeSizes = {
        {18, 18}, -- Rune1
        {20, 16}, -- Rune2
        {17, 15}, -- Rune3
        {15, 16}, -- Rune4
        {18, 16}, -- Rune5
    }

    local runeOffsets = {
        {18, -1},    -- Rune1
        {41.6, 0},   -- Rune2
        {68, 0.5},   -- Rune3
        {92, 0},     -- Rune4
        {112.2, -1}, -- Rune5
    }

    local function CreateHolyRune(parent, index)
        local sizeX, sizeY = unpack(runeSizes[index])
        local rune = CreateFrame("Frame", nil, parent)
        rune:SetSize(sizeX, sizeY)

        rune.Background = rune:CreateTexture(nil, "BACKGROUND")
        rune.Background:SetAtlas("uf-holypower-rune"..index, true)
        rune.Background:SetAllPoints()

        rune.ActiveTexture = rune:CreateTexture(nil, "OVERLAY")
        rune.ActiveTexture:SetAtlas("uf-holypower-rune"..index.."-active", true)
        rune.ActiveTexture:SetAllPoints()
        rune.ActiveTexture:SetAlpha(0)

        rune.Glow = rune:CreateTexture(nil, "OVERLAY")
        rune.Glow:SetAtlas("uf-holypower-rune"..index.."-glow", true)
        rune.Glow:SetAllPoints()
        rune.Glow:SetAlpha(0)

        function rune:SetActive(state)
            if self.activeState == state then return end
            self.activeState = state
            self.ActiveTexture:SetAlpha(state and 1 or 0)
            self.Glow:SetAlpha(state and 1 or 0)
        end

        return rune
    end

    for i = 1, MAX_ORBS do
        local rune = CreateHolyRune(frame, i)
        frame.orbs[i] = rune
        local x, y = unpack(runeOffsets[i])
        rune:SetPoint("LEFT", frame, "LEFT", x, y)
    end

    ---------------------------------------------------
    -- Update function (no spec filter now)
    ---------------------------------------------------
    function frame:Update()
        if select(2, UnitClass("player")) ~= "PALADIN" then
            self:Hide()
            return
        end

        local holy = UnitPower("player", Enum.PowerType.HolyPower)
        local maxHoly = UnitPowerMax("player", Enum.PowerType.HolyPower)

        for i = 1, maxHoly do
            self.orbs[i]:Show()
            self.orbs[i]:SetActive(i <= holy)
        end
        for i = maxHoly+1, MAX_ORBS do
            self.orbs[i]:Hide()
        end

        -- Background visuals
        if holy > 0 then
            self.BackgroundActive:SetAlpha(1)
            self.BackgroundGlow:SetAlpha(0.6)
        else
            self.BackgroundActive:SetAlpha(0)
            self.BackgroundGlow:SetAlpha(0)
        end

        self:Show()
    end

    ---------------------------------------------------
    -- Events
    ---------------------------------------------------
    frame:SetScript("OnEvent", function(self, event, arg1, arg2)
        if event == "PLAYER_ENTERING_WORLD" then
            self:Update()
            C_Timer.After(0.1, function() self:Update() end)
            C_Timer.After(0.5, function() self:Update() end)
        elseif event == "UNIT_POWER_UPDATE" and arg1 == "player" and arg2 == "HOLY_POWER" then
            self:Update()
        elseif event == "UNIT_MAXPOWER" and arg1 == "player" then
            self:Update()
        elseif event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player" then
            self:Update()
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")

    frame:Update()
end

function TPerl_BuildPaladinHolyPowerBar_Mists(frame)
    frame:SetSize(136, 39)
    frame:SetFrameStrata("LOW")

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 15)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -120,
        }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Ensure PaladinPowerBarFrame has correct unit
    ---------------------------------------------------
    if PaladinPowerBarFrame then
        PaladinPowerBarFrame.unit = "player"
    end

    ---------------------------------------------------
    -- Attach Blizzard's PaladinPowerBar (visuals) into container
    ---------------------------------------------------
    if PaladinPowerBar then
        PaladinPowerBar:ClearAllPoints()
        PaladinPowerBar:SetPoint("CENTER", frame, "CENTER", 0, 0)
        PaladinPowerBar:SetParent(frame)
        PaladinPowerBar:SetFrameStrata("LOW")
        PaladinPowerBar:EnableMouse(false)
    end

    ---------------------------------------------------
    -- Dragging behavior
    ---------------------------------------------------
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)
end



---------------------------------------------------
-- DK Builder Code (All)
---------------------------------------------------
function TPerl_BuildDKRuneFrame(frame)
    frame:SetFrameStrata("LOW")
    frame:SetSize(200, 40)

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -100,
        }
        frame:EnableMouse(not pconf.lockRunes)
    end

				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end
    ---------------------------------------------------
    -- Dragging behavior
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Create rune buttons
    ---------------------------------------------------
    frame.Runes = {}
    local spacing = 2
    for i = 1, 6 do
        local rune = CreateFrame("Frame", nil, frame, "RuneButtonIndividualTemplate")
        rune:SetSize(30, 30)

        if i == 1 then
            rune:SetPoint("LEFT", frame, "LEFT", 0, 0)
        else
            rune:SetPoint("LEFT", frame.Runes[i-1], "RIGHT", spacing, 0)
        end

        rune.runeIndex = i
        frame.Runes[i] = rune
    end

    ---------------------------------------------------
    -- Mixin RuneFrameMixin
    ---------------------------------------------------
    Mixin(frame, RuneFrameMixin)

    -- prevent crash since we handle rune spacing ourselves
    frame.Layout = function() end

    frame:OnLoad()
end

function TPerl_BuildDKRuneFrame_Mists(frame)
    frame:SetFrameStrata("LOW")
    frame:SetSize(200, 40)

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -100,
        }
        frame:EnableMouse(not pconf.lockRunes)
    end

				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end
    ---------------------------------------------------
    -- Dragging behavior
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Re-parent Blizzard’s RuneFrame (keep visuals)
    ---------------------------------------------------
    if RuneFrame then
        RuneFrame:ClearAllPoints()
        RuneFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        RuneFrame:SetParent(frame)
        RuneFrame:SetScale(1.0)
        RuneFrame:Show()

        -- Make sure cooldown numbers are visible
        for i = 1, 6 do
            local runeButton = RuneFrame.Runes and RuneFrame.Runes[i]
            if runeButton and runeButton.Cooldown then
                runeButton.Cooldown:SetHideCountdownNumbers(false)
                runeButton.Cooldown:SetDrawBling(false)
                runeButton.Cooldown:SetDrawEdge(false)
            end
												_G["Rune" .. i]:EnableMouse(false)
        end
    end
end

local function CreateRuneButton(parent, index)
    local rune = CreateFrame("Frame", nil, parent)
    rune:SetSize(24, 24)

    ---------------------------------------------------
    -- Textures (only the key parts; backgrounds hidden)
    ---------------------------------------------------
    rune.BG_Shadow   = rune:CreateTexture(nil, "BACKGROUND")
    rune.BG_Shadow:SetAtlas("UF-DKRunes-BGShadow", true)
    rune.BG_Shadow:SetPoint("CENTER", 0, -3)
    rune.BG_Shadow:SetAlpha(0) -- hidden background

    rune.BG_Inactive = rune:CreateTexture(nil, "BACKGROUND")
    rune.BG_Inactive:SetAtlas("UF-DKRunes-BGDis", true)
    rune.BG_Inactive:SetPoint("CENTER")
    rune.BG_Inactive:SetAlpha(0) -- hidden

    rune.BG_Active   = rune:CreateTexture(nil, "BACKGROUND")
    rune.BG_Active:SetAtlas("UF-DKRunes-BGActive", true)
    rune.BG_Active:SetPoint("CENTER")
    rune.BG_Active:SetAlpha(0) -- hidden

    rune.Rune_Inactive = rune:CreateTexture(nil, "ARTWORK")
    rune.Rune_Inactive:SetAtlas("UF-DKRunes-SkullDis", true)
    rune.Rune_Inactive:SetPoint("CENTER")

    rune.Rune_Active = rune:CreateTexture(nil, "ARTWORK")
    rune.Rune_Active:SetAtlas("UF-DKRunes-Blood-SkullActive", true)
    rune.Rune_Active:SetPoint("CENTER")

    rune.Glow = rune:CreateTexture(nil, "OVERLAY")
    rune.Glow:SetAtlas("UF-DKRunes-Blood-FilledGlwA", true)
    rune.Glow:SetPoint("CENTER")

    rune.Glow2 = rune:CreateTexture(nil, "OVERLAY")
    rune.Glow2:SetAtlas("UF-DKRunes-Blood-FilledGlwB", true)
    rune.Glow2:SetPoint("CENTER")

    ---------------------------------------------------
    -- Cooldown (with number timer visible)
    ---------------------------------------------------
    rune.Cooldown = CreateFrame("Cooldown", nil, rune, "CooldownFrameTemplate")
    rune.Cooldown:SetAllPoints(rune)
    rune.Cooldown:SetHideCountdownNumbers(false) -- show number timer
    rune.Cooldown:SetReverse(true)

    ---------------------------------------------------
    -- Apply RuneButtonMixin behavior
    ---------------------------------------------------
    Mixin(rune, RuneButtonMixin)
    rune.runeIndex = index
    rune:OnLoad()

    return rune
end



---------------------------------------------------
-- Warlock Builder Code (Mists / Retail)
---------------------------------------------------
function TPerl_GetWarlockSpec()
    if IsRetail then
        local specIndex = GetSpecialization()
        if specIndex then
            return GetSpecializationInfo(specIndex)
            -- Retail IDs:
            -- 265 = Affliction
            -- 266 = Demonology
            -- 267 = Destruction
												-- For now all the same: Soul Shards
        end
    elseif IsMistsClassic then
        local specIndex = GetPrimaryTalentTree()
        return specIndex
        -- Mists Classic tree indices:
        -- 1 = Affliction  - Soul Shards
        -- 2 = Demonology  - Demonic Fury
        -- 3 = Destruction - Demonic Fury
    end
    return nil
end

function TPerl_BuildWarlockSoulShardBar_Mists(frame)
    frame:SetFrameStrata("LOW")
    frame:SetSize(200, 40)

    ---------------------------------------------------
    -- Position handling
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -100 }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end
    end)

    ---------------------------------------------------
    -- Re-parent ShardBar
    ---------------------------------------------------
    if ShardBarFrame then
        ShardBarFrame:ClearAllPoints()
        ShardBarFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        ShardBarFrame:SetParent(frame)
        ShardBarFrame:SetScale(1.0)
        ShardBarFrame:EnableMouse(false)
        ShardBarFrame:Show()
    end

    ---------------------------------------------------
    -- Event forwarding
    ---------------------------------------------------
    local function ForceShardUpdate()
        if ShardBarFrame and ShardBarFrame.Update then
            ShardBarFrame:Update("SOUL_SHARDS", true)
        end
    end

    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")

    frame:SetScript("OnEvent", function(_, event, unit, powerType)
        if (event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER") and unit == "player" then
            if powerType == "SOUL_SHARDS" or event == "UNIT_MAXPOWER" then
                ForceShardUpdate()
            end
        elseif event == "PLAYER_ENTERING_WORLD" or event == "UNIT_DISPLAYPOWER" then
            ForceShardUpdate()
        end
    end)

    ForceShardUpdate()
end

function TPerl_BuildWarlockDemonicFuryBar_Mists(frame)
    frame:SetFrameStrata("LOW")
    frame:SetSize(200, 40)

    ---------------------------------------------------
    -- Restore or initialize position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOPLEFT", TPerl_PlayerstatsFrame, "BOTTOMLEFT", -60, 10) --TPerlSpecialPowerBarFrame:SetPoint("TOPLEFT", TPerl_PlayerstatsFrame, "BOTTOMLEFT", 0, -4)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -120,
        }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Re-parent Blizzard’s WarlockPowerFrame
    ---------------------------------------------------
    if WarlockPowerFrame then
        WarlockPowerFrame:ClearAllPoints()
        WarlockPowerFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        WarlockPowerFrame:SetParent(frame)
        WarlockPowerFrame:SetScale(1.0)
        WarlockPowerFrame:EnableMouse(false) -- click-through
        WarlockPowerFrame:SetFrameStrata("BACKGROUND")
        WarlockPowerFrame:Show()

        -- Force Demonic Fury text always visible
        if DemonicFuryBarFrame and DemonicFuryBarFrame.powerText then
            DemonicFuryBarFrame.powerText:Show()
            DemonicFuryBarFrame.showText = true
            DemonicFuryBarFrame.lockShow = 1
												DemonicFuryBarFrame:EnableMouse(false)
												DemonicFuryBarFrame:SetFrameStrata("BACKGROUND")
        end
    end

    ---------------------------------------------------
    -- Event forwarding for Demonic Fury
    ---------------------------------------------------
    local function ForceDemoUpdate()
        if DemonicFuryBarFrame and DemonicFuryBarFrame.Update then
            DemonicFuryBarFrame:Update("DEMONIC_FURY", true)
        end
    end

    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")

    frame:SetScript("OnEvent", function(_, event, unit, powerType)
        if (event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER") and unit == "player" then
            if powerType == "DEMONIC_FURY" or event == "UNIT_MAXPOWER" then
                ForceDemoUpdate()
            end
        elseif event == "PLAYER_ENTERING_WORLD"
            or event == "PLAYER_TALENT_UPDATE"
            or event == "UNIT_DISPLAYPOWER" then
            if WarlockPowerFrame and WarlockPowerFrame.SetUpCurrentPower then
                WarlockPowerFrame:SetUpCurrentPower(true)
            end
            ForceDemoUpdate()
        end
    end)

    -- Kick it once at creation
    ForceDemoUpdate()
end


function TPerl_BuildWarlockBurningEmbersBar_Mists(frame)
    frame:SetFrameStrata("LOW")
    frame:SetSize(200, 40)

    ---------------------------------------------------
    -- Position handling
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -100 }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end
    end)

    ---------------------------------------------------
    -- Re-parent Burning Embers bar
    ---------------------------------------------------
    if BurningEmbersBarFrame then
        BurningEmbersBarFrame:ClearAllPoints()
        BurningEmbersBarFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        BurningEmbersBarFrame:SetParent(frame)
        BurningEmbersBarFrame:SetScale(1.0)
        BurningEmbersBarFrame:EnableMouse(false)
        BurningEmbersBarFrame:Show()
    end

    ---------------------------------------------------
    -- Event forwarding
    ---------------------------------------------------
    local function ForceEmbersUpdate()
        if BurningEmbersBarFrame and BurningEmbersBarFrame.Update then
            BurningEmbersBarFrame:Update("BURNING_EMBERS", true)
        end
    end

    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")

    frame:SetScript("OnEvent", function(_, event, unit, powerType)
        if (event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER") and unit == "player" then
            if powerType == "BURNING_EMBERS" or event == "UNIT_MAXPOWER" then
                ForceEmbersUpdate()
            end
        elseif event == "PLAYER_ENTERING_WORLD" or event == "UNIT_DISPLAYPOWER" then
            ForceEmbersUpdate()
        end
    end)

    ForceEmbersUpdate()
end

function TPerl_BuildWarlockSoulShardBar_Retail(frame)
    local ORB_SIZE = 28
    local ORB_SPACING = 4
    local MAX_ORBS = 5

    frame:SetFrameStrata("LOW")
    frame:SetSize((ORB_SIZE * MAX_ORBS) + (ORB_SPACING * (MAX_ORBS - 1)), ORB_SIZE)

    ---------------------------------------------------
    -- Restore or initialize position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -100 }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end
    end)

    ---------------------------------------------------
    -- Spawn ShardTemplate orbs
    ---------------------------------------------------
    frame.orbs = {}
    for i = 1, MAX_ORBS do
        local orb = CreateFrame("Frame", nil, frame, "ShardTemplate")
        orb:SetSize(ORB_SIZE, ORB_SIZE)
        orb:SetPoint("LEFT", i == 1 and frame or frame.orbs[i-1],
            i == 1 and "LEFT" or "RIGHT", i == 1 and 0 or ORB_SPACING, 0)
        orb.layoutIndex = i -- used by WarlockShardMixin:Update
        frame.orbs[i] = orb
        orb:Setup()
    end

    ---------------------------------------------------
    -- Update function
    ---------------------------------------------------
    function frame:Update()
        if select(2, UnitClass("player")) ~= "WARLOCK" then
            self:Hide()
            return
        end

        local shards = UnitPower("player", Enum.PowerType.SoulShards, true)
        local mod = UnitPowerDisplayMod(Enum.PowerType.SoulShards)
        shards = (mod ~= 0) and (shards / mod) or 0
        if C_SpecializationInfo.GetSpecialization() ~= SPEC_WARLOCK_DESTRUCTION then
            shards = math.floor(shards)
        end
        local max = UnitPowerMax("player", Enum.PowerType.SoulShards)

        for i, orb in ipairs(self.orbs) do
            if i <= max then
                orb:Show()
                orb:Update(shards, shards >= max and UnitAffectingCombat("player"))
            else
                orb:Hide()
            end
        end
        self:Show()
    end

    ---------------------------------------------------
    -- Events
    ---------------------------------------------------
    frame:SetScript("OnEvent", function(self, event, unit, powerType)
        if event == "PLAYER_ENTERING_WORLD" or event == "UNIT_DISPLAYPOWER" then
            self:Update()
        elseif (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") and unit == "player" then
            if powerType == "SOUL_SHARDS" or event == "UNIT_MAXPOWER" then
                self:Update()
            end
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
            self:Update()
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")

    -- Kick once
    frame:Update()
end




---------------------------------------------------
-- Mage Arcane Charges Bar (Mists / Retail)
---------------------------------------------------
function TPerl_BuildMageArcaneChargesBar_Retail(frame)
    ---------------------------------------------------
    -- Blizzard mixin setup
    ---------------------------------------------------
    Mixin(frame, MagePowerBar)
    frame:SetSize(125, 30)
    frame.unit = "player"
    frame.powerType = Enum.PowerType.ArcaneCharges

    -- Needed for MagePowerBar:UpdatePower()
    function frame:GetUnit()
        return self.unit or "player"
    end

    ---------------------------------------------------
    -- Initial positioning
    ---------------------------------------------------
    frame:ClearAllPoints()

    if pconf.dockRunes then
        -- Docked under player frame
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)

    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        -- Restore from saved pos
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)

    else
        -- First-time default: visible under player
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -100,
        }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end
    end)

    ---------------------------------------------------
    -- Create Arcane Charge buttons
    ---------------------------------------------------
    frame.classResourceButtonTable = {}
    local maxCharges = UnitPowerMax("player", Enum.PowerType.ArcaneCharges) or 4
    local spacing, size = 8, 24

    for i = 1, maxCharges do
        local button = CreateFrame("Frame", nil, frame, "ArcaneChargeTemplate")
        Mixin(button, ArcaneChargeMixin)
        button:SetSize(size, size)

        if i == 1 then
            button:SetPoint("LEFT", frame, "LEFT", 0, 0)
        else
            button:SetPoint("LEFT", frame.classResourceButtonTable[i-1], "RIGHT", spacing, 0)
        end

        button:Setup()
        frame.classResourceButtonTable[i] = button
    end

    ---------------------------------------------------
    -- Wrapper for watcher calls
    ---------------------------------------------------
    function frame:UpdateCharges()
        if self.UpdatePower then
            self:UpdatePower() -- MagePowerBar:UpdatePower()
        end
    end

    ---------------------------------------------------
    -- Events to update power
    ---------------------------------------------------
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    frame:SetScript("OnEvent", function(self, event, arg1, arg2)
        if arg1 and arg1 ~= "player" then return end
        if event == "UNIT_POWER_UPDATE" and arg2 ~= "ARCANE_CHARGES" then return end
        self:UpdateCharges()
    end)

    -- Initial update
    frame:UpdateCharges()
end

function TPerl_BuildMageArcaneChargesBar_Mists(frame)
    frame:SetSize(128, 32)
    frame:SetFrameStrata("LOW")

    ---------------------------------------------------
    -- Position / Movability
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -100,
        }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point, relativePoint = relativePoint, x = xOfs, y = yOfs,
            }
        end
    end)

    ---------------------------------------------------
    -- Background bar
    ---------------------------------------------------
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetTexture("Interface\\AddOns\\TPerl_Player\\Textures\\Mage-ArcaneChargeBar.blp")
    frame.bg:SetSize(128, 16)
    frame.bg:SetPoint("CENTER", frame, "CENTER", 0, -8)

    ---------------------------------------------------
    -- Charge orbs
    ---------------------------------------------------
    local orbOffsets = {
        {8, -3},
        {35, -3},
        {62, -3},
        {89, -3},
    }

    frame.orbs = {}
    for i = 1, 4 do
        local orb = CreateFrame("Frame", nil, frame)
        orb:SetSize(32, 32)
        orb:SetPoint("LEFT", frame.bg, "LEFT", orbOffsets[i][1], orbOffsets[i][2])

        orb.base = orb:CreateTexture(nil, "BACKGROUND")
        orb.base:SetTexture("Interface\\AddOns\\TPerl_Player\\Textures\\Mage-ArcaneCharge.blp")
        orb.base:SetAllPoints()

        orb.spark = orb:CreateTexture(nil, "ARTWORK")
        orb.spark:SetTexture("Interface\\AddOns\\TPerl_Player\\Textures\\Mage-ArcaneCharge-Spark.blp")
        orb.spark:SetAllPoints()
        orb.spark:SetBlendMode("ADD")
        orb.spark:Hide()

        orb.smallSpark = orb:CreateTexture(nil, "ARTWORK")
        orb.smallSpark:SetTexture("Interface\\AddOns\\TPerl_Player\\Textures\\Mage-ArcaneCharge-SmallSpark.blp")
        orb.smallSpark:SetAllPoints()
        orb.smallSpark:SetBlendMode("ADD")
        orb.smallSpark:Hide()

        orb.glow = orb:CreateTexture(nil, "OVERLAY")
        orb.glow:SetTexture("Interface\\AddOns\\TPerl_Player\\Textures\\Mage-ArcaneCharge-CircleGlow.blp")
        orb.glow:SetAllPoints()
        orb.glow:SetBlendMode("ADD")
        orb.glow:Hide()

        orb.rune = orb:CreateTexture(nil, "OVERLAY")
        orb.rune:SetTexture("Interface\\AddOns\\TPerl_Player\\Textures\\Mage-ArcaneCharge-Rune.blp")
        orb.rune:SetAllPoints()
        orb.rune:SetBlendMode("ADD")
        orb.rune:Hide()

        orb.SetActive = function(self, active)
            if active then
                self.spark:Show()
                self.smallSpark:Show()
                self.glow:Show()
                self.rune:Show()
            else
                self.spark:Hide()
                self.smallSpark:Hide()
                self.glow:Hide()
                self.rune:Hide()
            end
        end

        orb:SetActive(false)
        frame.orbs[i] = orb
    end

    ---------------------------------------------------
    -- Timer above bar
    ---------------------------------------------------
    frame.timer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    frame.timer:SetPoint("BOTTOM", frame, "TOP", 0, -8) -- closer to bar
    frame.timer:Hide()

    ---------------------------------------------------
    -- Event handling for updating charges
    ---------------------------------------------------
    local ARCANE_CHARGE_SPELLID = 36032

    local function UpdateCharges()
        local charges, dur, expTime = 0, nil, nil

        -- Full debuff scan
        for i = 1, 40 do
            local name, _, count, _, duration, expires, _, _, _, spellID = UnitDebuff("player", i)
            if not name then break end
            if spellID == ARCANE_CHARGE_SPELLID then
                charges = count or 0
                dur = duration
                expTime = expires
                break
            end
        end

        for i, orb in ipairs(frame.orbs) do
            orb:SetActive(i <= charges)
        end

        if dur and expTime then
            frame.timer.expTime = expTime
            frame.timer:Show()
        else
            frame.timer:SetText("")
            frame.timer.expTime = nil
            frame.timer:Hide()
        end
    end

    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_ENTERING_WORLD" then
            UpdateCharges()
        elseif event == "UNIT_AURA" and unit == "player" then
            UpdateCharges()
        end
    end)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_AURA", "player")

    frame:SetScript("OnUpdate", function(self, elapsed)
        if self.timer and self.timer.expTime then
            local remain = self.timer.expTime - GetTime()
            if remain > 0 then
                self.timer:SetText(string.format("%.1fs", remain))
            else
                self.timer:SetText("")
                self.timer.expTime = nil
                self.timer:Hide()
            end
        end
    end)

    UpdateCharges()
end





---------------------------------------------------
-- Evoker Essence Bar (Retail)
---------------------------------------------------
function TPerl_BuildEvokerEssenceBar_Retail(frame)
    frame:SetFrameStrata("LOW")
    frame:SetSize(160, 30)

    ---------------------------------------------------
    -- Position restore/init
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -100 }
        frame:EnableMouse(not pconf.lockRunes)
    end
				
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
        end
    end)

    ---------------------------------------------------
    -- Essence Orbs
    ---------------------------------------------------
    frame.maxUsablePoints = UnitPowerMax("player", Enum.PowerType.Essence)
    frame.classResourceButtonTable = {}

    local spacing = 5
    for i = 1, frame.maxUsablePoints do
        local orb = CreateFrame("Frame", nil, frame, "EssencePointButtonTemplate")
        Mixin(orb, EssencePointButtonMixin)
        orb.layoutIndex = i
        orb:SetSize(24, 24)

        if i == 1 then
            orb:SetPoint("LEFT", frame, "LEFT", 0, 0)
        else
            orb:SetPoint("LEFT", frame.classResourceButtonTable[i-1], "RIGHT", spacing, 0)
        end

        orb:Hide()
        frame.classResourceButtonTable[i] = orb
    end

    ---------------------------------------------------
    -- Update logic
    ---------------------------------------------------
    local function UpdateEssence()
        local comboPoints = UnitPower("player", Enum.PowerType.Essence)
        local maxPoints = UnitPowerMax("player", Enum.PowerType.Essence)

        -- Reset if max changes (e.g. talents)
        if maxPoints ~= frame.maxUsablePoints then
            frame.maxUsablePoints = maxPoints
            -- TODO: rebuild orbs here if you want dynamic max change support
        end

        for i = 1, frame.maxUsablePoints do
            local orb = frame.classResourceButtonTable[i]
            if i <= comboPoints then
                orb:SetEssennceFull()
                orb:Show()
            elseif i == comboPoints + 1 then
                orb:AnimIn(1, 0)  -- filling animation
                orb:Show()
            else
                orb:AnimOut()
            end
        end
    end

    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_POWER_FREQUENT")
				frame:RegisterEvent("UNIT_MAXPOWER")
				frame:RegisterEvent("PLAYER_ENTERING_WORLD")

				frame:SetScript("OnEvent", function(self, event, arg1, arg2)
				    --print(event .. " | " .. arg1 .. " | " .. arg2)
								if (event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_POWER_FREQUENT") 
											and arg1 == "player" 
											and (arg2 == "ESSENCE" or arg2 == Enum.PowerType.Essence) then
												UpdateEssence()
								elseif event == "PLAYER_ENTERING_WORLD" then
												UpdateEssence()
								end
				end)

    UpdateEssence()
end




---------------------------------------------------
-- Priest Shadow Orbs Bar (Mists / Cata Classic)
---------------------------------------------------
function TPerl_GetPriestSpec()
    if IsRetail then
        local specIndex = GetSpecialization()
        if specIndex then
            return GetSpecializationInfo(specIndex) -- returns actual specID like 256, 257, 258
        end
    elseif IsMistsClassic or IsCataClassic then
        return GetPrimaryTalentTree() -- 1 = Disc, 2 = Holy, 3 = Shadow
    end
    return nil
end

function TPerl_BuildPriestShadowOrbBar_Mists(frame)
    ----------------------------------------------------------------
    -- Frame shell & placement
    ----------------------------------------------------------------
    frame:SetFrameStrata("LOW")
    frame:SetSize(160, 40)
    frame:ClearAllPoints()

    if pconf and pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 15, 10)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not (pconf and pconf.lockRunes))
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -100,
        }
        frame:EnableMouse(not (pconf and pconf.lockRunes))
    end

    if pconf and pconf.showRunes == false then
        frame:Hide()
    else
        frame:Show()
    end

    -- Dragging
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        if not (pconf and pconf.lockRunes) and not (pconf and pconf.dockRunes) then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not (pconf and pconf.dockRunes) then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)

    ----------------------------------------------------------------
    -- Constants / helpers
    ----------------------------------------------------------------
    local SHADOW_ORBS_POWER = _G.SPELL_POWER_SHADOW_ORBS
                           or (Enum and Enum.PowerType and Enum.PowerType.ShadowOrbs)
                           or 13
    local function GetOrbCount()
        if type(GetShadowOrbs) == "function" then
            return GetShadowOrbs() or 0
        end
        return (UnitPower("player", SHADOW_ORBS_POWER) or 0)
    end
    local function GetMaxOrbs()
        local maxp = UnitPowerMax and UnitPowerMax("player", SHADOW_ORBS_POWER) or nil
        local fall = _G.PRIEST_BAR_NUM_ORBS or 5
        if maxp and maxp > 0 then return maxp end
        return fall
    end

    ----------------------------------------------------------------
    -- Create orbs
    ----------------------------------------------------------------
    frame.orbs = {}
    local NUM_ORBS = GetMaxOrbs()
    local spacing = -5

    for i = 1, NUM_ORBS do
        local orb = CreateFrame("Frame", nil, frame, "ShadowOrbTemplate")
        if PriestBarOrbMixin then
            Mixin(orb, PriestBarOrbMixin)
        end
        orb.layoutIndex = i
        orb:SetSize(38, 37)

        if i == 1 then
            orb:SetPoint("LEFT", frame, "LEFT", 0, 0)
        else
            orb:SetPoint("LEFT", frame.orbs[i-1], "RIGHT", spacing, 0)
        end

        -- Track state
        orb.active = false
        frame.orbs[i] = orb
    end

    ----------------------------------------------------------------
    -- Animation helpers (Blizzard parity + safe fallbacks)
    ----------------------------------------------------------------
    local function EnsureAnimOutFinisher(orb)
        if orb and orb.animOut and not orb._animOutWired then
            orb.animOut:SetScript("OnFinished", function()
                if orb.orb then orb.orb:SetAlpha(0) end
                if orb.bg then orb.bg:SetAlpha(0.5) end
                if orb.highlight then orb.highlight:SetAlpha(0) end
                if orb.glow then orb.glow:SetAlpha(0) end
                orb.active = false
            end)
            orb._animOutWired = true
        end
    end

    local function ActivateOrb(orb)
        if not orb then return end
        if orb.SetActive then
            if not orb.active then orb:SetActive(true) end
            orb.active = true
            return
        end
        -- Fallback visuals
        if orb.animIn then
            if orb.animOut then orb.animOut:Stop() end
            orb.animIn:Stop()
            if orb.orb then orb.orb:SetAlpha(1) end
            if orb.bg then orb.bg:SetAlpha(1) end
            if orb.highlight then orb.highlight:SetAlpha(1) end
            if orb.glow then orb.glow:SetAlpha(1) end
            orb.animIn:Play()
        else
            if orb.orb then orb.orb:SetAlpha(1) end
            if orb.bg then orb.bg:SetAlpha(1) end
            if orb.highlight then orb.highlight:SetAlpha(1) end
            if orb.glow then orb.glow:SetAlpha(1) end
        end
        orb.active = true
    end

    local function DeactivateOrb(orb)
        if not orb then return end
        if orb.SetActive then
            if orb.active then orb:SetActive(false) end
            orb.active = false
            return
        end
        EnsureAnimOutFinisher(orb)
        if orb.animOut then
            if orb.animIn then orb.animIn:Stop() end
            orb.animOut:Stop()
            orb.animOut:Play()
        else
            -- No anims: immediate off
            if orb.orb then orb.orb:SetAlpha(0) end
            if orb.bg then orb.bg:SetAlpha(0.5) end
            if orb.highlight then orb.highlight:SetAlpha(0) end
            if orb.glow then orb.glow:SetAlpha(0) end
            orb.active = false
        end
    end

    local function HardClearAllOrbs()
        for i = 1, NUM_ORBS do
            local orb = frame.orbs[i]
            if orb then
                if orb.animIn then orb.animIn:Stop() end
                if orb.animOut then orb.animOut:Stop() end
                if orb.orb then orb.orb:SetAlpha(0) end
                if orb.bg then orb.bg:SetAlpha(0.5) end
                if orb.highlight then orb.highlight:SetAlpha(0) end
                if orb.glow then orb.glow:SetAlpha(0) end
                if orb.SetActive then orb:SetActive(false) end
                orb.active = false
            end
        end
    end

    for i = 1, NUM_ORBS do
        EnsureAnimOutFinisher(frame.orbs[i])
    end

    ----------------------------------------------------------------
    -- Update logic
    ----------------------------------------------------------------
    local lastCount = -1
    local function UpdateOrbs(force)
        local num = GetOrbCount()
        if num < 0 then num = 0 end

        if not force and num == lastCount then
            return
        end

        -- Gaining orbs: light from low to high
        if lastCount < num then
            for i = (lastCount + 1), num do
                ActivateOrb(frame.orbs[i])
            end
        end

        -- Losing orbs: extinguish from high to low (Blizzard feel)
        if lastCount > num then
            for i = lastCount, (num + 1), -1 do
                DeactivateOrb(frame.orbs[i])
            end
        end

        -- Special safety at zero to avoid a "ghost orb"
        if num == 0 then
            HardClearAllOrbs()
        end

        lastCount = num
    end

    ----------------------------------------------------------------
    -- Events
    ----------------------------------------------------------------
    frame:UnregisterAllEvents()
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_POWER_FREQUENT")
    frame:RegisterEvent("SPELLS_CHANGED")
    frame:RegisterEvent("PLAYER_TALENT_UPDATE")

    frame:SetScript("OnEvent", function(self, event, unit, powertoken)
        if event == "PLAYER_ENTERING_WORLD"
        or event == "SPELLS_CHANGED"
        or event == "PLAYER_TALENT_UPDATE" then
            UpdateOrbs(true)
            return
        end

        if event == "UNIT_DISPLAYPOWER" and unit == "player" then
            UpdateOrbs(true)
            return
        end

        if (event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT") and unit == "player" then
            -- Some clients don’t consistently pass "SHADOW_ORBS"; just update.
            UpdateOrbs(false)
            return
        end
    end)

    -- Initial paint
    UpdateOrbs(true)
end



---------------------------------------------------
-- Druid Balance Bar (Mists / Cata Classic)
---------------------------------------------------
function TPerl_BuildBalanceBar_Mists(frame)
    frame:SetFrameStrata("LOW")
    frame:SetSize(190, 30)

    ---------------------------------------------------
    -- Restore or initialize saved position
    ---------------------------------------------------
    frame:ClearAllPoints()
    if pconf.dockRunes then
        frame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
        frame:EnableMouse(false)
    elseif TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
        frame:SetPoint(
            TPerlSpecialPowerBarFramePos.point,
            UIParent,
            TPerlSpecialPowerBarFramePos.relativePoint,
            TPerlSpecialPowerBarFramePos.x,
            TPerlSpecialPowerBarFramePos.y
        )
        frame:EnableMouse(not pconf.lockRunes)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        TPerlSpecialPowerBarFramePos = {
            point = "CENTER", relativePoint = "CENTER", x = 0, y = -150,
        }
        frame:EnableMouse(not pconf.lockRunes)
    end

    ---------------------------------------------------
    -- Re-parent Blizzard’s EclipseBarFrame safely
    ---------------------------------------------------
    if EclipseBarFrame then

        EclipseBarFrame:ClearAllPoints()
        EclipseBarFrame:SetParent(frame)
        EclipseBarFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
        EclipseBarFrame:SetScale(1.0)
        EclipseBarFrame:Show()
        EclipseBarFrame:EnableMouse(false)
    end
				
				if not pconf.showRunes then
								frame:Hide()
				elseif pconf.showRunes then
								frame:Show()
				end

    ---------------------------------------------------
    -- Dragging behavior
    ---------------------------------------------------
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    frame:SetScript("OnDragStart", function(self)
        if not pconf.lockRunes and not pconf.dockRunes then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not pconf.dockRunes then
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            TPerlSpecialPowerBarFramePos = {
                point = point,
                relativePoint = relativePoint,
                x = xOfs,
                y = yOfs,
            }
        end
    end)
end
