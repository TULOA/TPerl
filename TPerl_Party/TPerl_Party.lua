-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local TPerl_Party_Events = { }
--local checkRaidNextUpdate
local PartyFrames = { }
local startupDone
local conf, pconf
TPerl_RequestConfig(function(new)
	conf = new
	pconf = new.party
	for k, v in pairs(PartyFrames) do
		v.conf = pconf
	end
end, "$Revision:  $")

local percD = "%d"..PERCENT_SYMBOL

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsTBCAnni = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local IsCataClassic = WOW_PROJECT_ID == WOW_PROJECT_CATA_CLASSIC
local IsMistsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local ceil = ceil
local floor = floor
local format = format
local max = max
local pairs = pairs
local pcall = pcall
local strfind = strfind
local strmatch = strmatch
local tonumber = tonumber
local type = type
local wipe = wipe

local CheckInteractDistance = CheckInteractDistance
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local RegisterUnitWatch = RegisterUnitWatch
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInRange = UnitInRange
local UnitIsAFK = UnitIsAFK
local UnitIsCharmed = UnitIsCharmed
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsDND = UnitIsDND
local UnitIsGhost = UnitIsGhost
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitIsMercenary = UnitIsMercenary
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitName = UnitName
local UnitPhaseReason = UnitPhaseReason
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnregisterUnitWatch = UnregisterUnitWatch

local CombatFeedback_Initialize = CombatFeedback_Initialize
local CombatFeedback_OnCombatEvent = CombatFeedback_OnCombatEvent
local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate

local partyHeader
local partyAnchor


local TPerl_Party_HighlightCallback

--local feignDeath = (C_Spell and C_Spell.GetSpellInfo(5384)) and C_Spell.GetSpellInfo(5384).name or GetSpellInfo(5384)
--local spiritOfRedemption = (C_Spell and C_Spell.GetSpellInfo(27827)) and C_Spell.GetSpellInfo(27827).name or GetSpellInfo(27827)

----------------------
-- Loading Function --
----------------------
function TPerl_Party_Events_OnLoad(self)
	local events = {
		"PLAYER_ENTERING_WORLD",
		"PLAYER_TARGET_CHANGED",
		"PLAYER_LOGIN",
		"PLAYER_FLAGS_CHANGED",
		"GROUP_ROSTER_UPDATE",
		"UNIT_CONNECTION",
		"UNIT_PHASE",
		"UNIT_COMBAT",
		"UNIT_FACTION",
		"UNIT_FLAGS",
		"UNIT_AURA",
		"UNIT_PORTRAIT_UPDATE",
		"UNIT_TARGET",
		"UNIT_HEAL_PREDICTION",
		"UNIT_ABSORB_AMOUNT_CHANGED",
		"UNIT_POWER_FREQUENT",
		"UNIT_MAXPOWER",
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		"UNIT_LEVEL",
		"UNIT_DISPLAYPOWER",
		"UNIT_NAME_UPDATE",
		"UNIT_THREAT_LIST_UPDATE",
		"RAID_TARGET_UPDATE",
		"READY_CHECK",
		"READY_CHECK_CONFIRM",
		"READY_CHECK_FINISHED",
		"PARTY_LOOT_METHOD_CHANGED",
		--"PET_BATTLE_OPENING_START",
		--"PET_BATTLE_CLOSE",
		"INCOMING_RESURRECT_CHANGED",
	}
	for i, event in pairs(events) do
		if pcall(self.RegisterEvent, self, event) then
			self:RegisterEvent(event)
		end
	end

	--partyHeader:UnregisterEvent("UNIT_NAME_UPDATE") -- IMPORTANT! Fix for WoW 2.1 UNIT_NAME_UPDATE lockup issues

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE") -- IMPORTANT! Stops raid framerate lagging when members join/leave/zone

	if IsRetail or IsTBCAnni then
		TPerl_BlizzFrameDisable(PartyFrame)
	else
		for i = 1, 4 do
			TPerl_BlizzFrameDisable(_G["PartyMemberFrame"..i])
		end
	end

	self:SetScript("OnEvent", TPerl_Party_OnEvent)
	TPerl_RegisterOptionChanger(TPerl_Party_Set_Bits)
	TPerl_Highlight:Register(TPerl_Party_HighlightCallback, self)

	TPerl_Party_Set_Bits()

	--TPerl_Party_Events_OnLoad = nil
end

-- TPerl_Party_HighlightCallback
function TPerl_Party_HighlightCallback(self, updateGUID)
	if not updateGUID then
		return
	end

	local f = TPerl_Party_GetUnitFrameByGUID(updateGUID)
	if (f) then
		TPerl_Highlight:SetHighlight(f, updateGUID)
	end
end

-- SetFrameArray
local function SetFrameArray(self, value)
	for k, v in pairs(PartyFrames) do
		if (v == self) then
			PartyFrames[k] = nil
			if (TPerl_Party_Pet_ClearFrame) then
				local petid
				if k == "player" then
					petid = "pet"
				else
					petid = "partypet"..strmatch(k, "^party(%d)")
				end
				TPerl_Party_Pet_ClearFrame(petid)
			end
		end
	end

	self.partyid = value
	if (value) then
		self.targetid = value.."target"
		PartyFrames[value] = self
		if (TPerl_Party_Pet_SetFrame) then
			local petid
			if value == "player" then
				petid = "pet"
			else
				petid = "partypet"..strmatch(value, "^party(%d)")
			end
			TPerl_Party_Pet_SetFrame(self:GetID(), petid, value)
		end
	end
end

-- onAttrChanged
local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value and value ~= "party0") then
			SetFrameArray(self, value)
			if (self.partyid ~= value or self.lastName ~= UnitName(value) or self.lastGUID ~= UnitGUID(value)) then
				if (conf) then
					TPerl_Party_UpdateDisplay(self, true)
				end
				--[[if (TPerl_ArcaneBar_RegisterFrame) then
					TPerl_ArcaneBar_RegisterFrame(self.nameFrame, value)
				end]]
			end
		else
			SetFrameArray(self)
		end
	end
end

-- TPerl_Party_OnLoad
function TPerl_Party_OnLoad(self)
	TPerl_SetChildMembers(self)
	self.targetFrame.statsFrame = self.targetFrame.healthBar -- So the healthbar fades as part of pseudo statsFrame

	partyHeader = TPerl_Party_SecureHeader
	partyAnchor = TPerl_Party_Anchor

	local id = strmatch(self:GetName(), ".+(%d)")
	self:SetID(tonumber(id))
	--_G["TPerl_party"..self:GetID()] = self

	if (self:GetID() > 1) then
		self.buffSetup = TPerl_party1.buffSetup
	else
		local BuffOnUpdate, DebuffOnUpdate, BuffUpdateTooltip, DebuffUpdateTooltip
		BuffUpdateTooltip = TPerl_Unit_SetBuffTooltip
		DebuffUpdateTooltip = TPerl_Unit_SetDebuffTooltip

		self.buffSetup = {
			buffScripts = {
				OnEnter = TPerl_Unit_SetBuffTooltip,
				OnUpdate = BuffOnUpdate,
				OnLeave = TPerl_PlayerTipHide,
			},
			debuffScripts = {
				OnEnter = TPerl_Unit_SetDeBuffTooltip,
				OnUpdate = DebuffOnUpdate,
				OnLeave = TPerl_PlayerTipHide,
			},
			updateTooltipBuff = BuffUpdateTooltip,
			updateTooltipDebuff = DebuffUpdateTooltip,
			debuffParent = true,
			debuffSizeMod = 0.4,
			debuffAnchor1 = function(self, b)
				if (pconf.flip) then
					b:SetPoint("RIGHT", self.statsFrame, "LEFT", 0, 0)
				else
					b:SetPoint("LEFT", self.statsFrame, "RIGHT", 0, 0)
				end
			end,
			buffAnchor1 = function(self, b)
				if (pconf.flip) then
					b:SetPoint("TOPRIGHT", self.buffFrame, "TOPRIGHT", 0, 0)
				else
					b:SetPoint("TOPLEFT", self.buffFrame, "TOPLEFT", 0, 0)
				end
			end,
		}
	end

	partyHeader:SetAttribute("showPlayer", pconf.showPlayer)
	partyHeader:SetAttribute("child"..self:GetID(), self)
	if partyHeader:GetAttribute("showPlayer") then
		if self:GetID() == 1 then
			self.partyid = "player"
		else
			self.partyid = "party"..(self:GetID() - 1)
		end
	else
		self.partyid = "party"..self:GetID()
	end
	PartyFrames[self.partyid] = self

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	self.hitIndicator.text:SetPoint("CENTER", self.portraitFrame, "CENTER", 0, 0)

	self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")

	TPerl_RegisterClickCastFrame(self.nameFrame)
	TPerl_RegisterClickCastFrame(self)

	self.time = 0
	self.flagsCheck = 0

	TPerl_RegisterHighlight(self.highlight, 3)
	TPerl_RegisterHighlight(self.targetFrame, 3)
	TPerl_RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.portraitFrame, self.levelFrame, self.targetFrame})

	self.FlashFrames = {self.nameFrame, self.levelFrame, self.statsFrame, self.portraitFrame}

	self:SetScript("OnUpdate", TPerl_Party_OnUpdate)
	self:SetScript("OnAttributeChanged", onAttrChanged)
	self:SetScript("OnShow", TPerl_Party_UpdateDisplay) -- TPerl_Unit_UpdatePortrait)

	self.targetFrame:SetScript("OnUpdate", TPerl_Party_Target_OnUpdate)

	if (TPerl_ArcaneBar_RegisterFrame) then
		if self.partyid == "player" then
			TPerl_ArcaneBar_RegisterFrame(self.nameFrame, "party"..self.partyid)
		else
			TPerl_ArcaneBar_RegisterFrame(self.nameFrame, self.partyid)
		end
	end

	if (TPerlDB) then
		self.conf = TPerlDB.party
	end

	TPerl_Party_Set_Bits1(self)

	--[[if (TPerl_party1 and TPerl_party2 and TPerl_party3 and TPerl_party4) then
		TPerl_Party_OnLoad = nil
	end]]
end

-- ShowHideValues
local function ShowHideValues(self)
	if (pconf.values) then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
	else
		if (not self.hideValues) then
			self.statsFrame.healthBar.text:Hide()
			self.statsFrame.manaBar.text:Hide()
		end
	end
end

-- TPerl_Party_UpdateHealPrediction
local function TPerl_Party_UpdateHealPrediction(self)
	if pconf.healprediction then
		TPerl_SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

-- TPerl_Party_UpdateAbsorbPrediction
local function TPerl_Party_UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		TPerl_SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end
-- TPerl_Party_UpdateHotsPrediction
local function TPerl_Party_UpdateHotsPrediction(self)
	if not (IsCataClassic or IsMistsClassic) then
		return
	end
	if pconf.hotPrediction then
		TPerl_SetExpectedHots(self)
	else
		self.statsFrame.expectedHots:Hide()
	end
end

local function TPerl_Party_UpdateResurrectionStatus(self)
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

-- TPerl_Party_UpdateHealth
local function TPerl_Party_UpdateHealth(self)
	if (not self.conf) then
		return
	end
	local partyid = self.partyid
	local Partyhealth, Partyhealthmax = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid)), UnitHealthMax(partyid)
	local reason

	--[[if (self.feigning and not UnitBuff(partyid, feignDeath)) then
		self.feigning = nil
	end]]

	TPerl_SetHealthBar(self, Partyhealth, Partyhealthmax)

	TPerl_Party_UpdateAbsorbPrediction(self)
	TPerl_Party_UpdateHealPrediction(self)
	TPerl_Party_UpdateHotsPrediction(self)
	TPerl_Party_UpdateResurrectionStatus(self)

	if (not UnitIsConnected(partyid)) then
		reason = TPERL_LOC_OFFLINE
	else
		--[[if (UnitBuff(partyid, feignDeath) and conf.showFD) then
			reason = TPERL_LOC_FEIGNDEATH
		else--]]if (self.afk and conf.showAFK) then
			reason = CHAT_MSG_AFK
		elseif (UnitIsDead(partyid)) then
			reason = TPERL_LOC_DEAD
		elseif (UnitIsGhost(partyid)) then
			reason = TPERL_LOC_GHOST
		elseif ((Partyhealth == 1) and (Partyhealthmax == 1)) then
			reason = TPERL_LOC_UPDATING
		--[[elseif (UnitBuff(partyid, spiritOfRedemption)) then
			reason = TPERL_LOC_DEAD--]]
		end
	end

	ShowHideValues(self)
	if (reason) then
		if (pconf.percent) then
			local old = self.statsFrame.healthBar.percent:GetText()
			self.statsFrame.healthBar.percent:SetText(reason)

			if (self.statsFrame.healthBar.percent:GetStringWidth() > (self.statsFrame:GetWidth() - self.statsFrame.healthBar:GetWidth() - 8)) then
				self.statsFrame.healthBar.percent:SetText(old)
				self.statsFrame.healthBar.text:SetText(reason)
				self.statsFrame.healthBar.text:Show()
			else
				self.statsFrame.healthBar.percent:Show()
			end
		else
			self.statsFrame.healthBar.text:SetText(reason)
			self.statsFrame.healthBar.text:Show()
		end

		self.statsFrame:SetGrey()
	else
		if (self.statsFrame.greyMana) then
			self.statsFrame.greyMana = nil
			TPerl_SetManaBarType(self)
		end
	end
end

-- TPerl_Party_UpdatePlayerFlags(self)
local function TPerl_Party_UpdatePlayerFlags(self)
	local change
	if (UnitIsAFK(self.partyid) and conf.showAFK) then
		if (not self.afk) then
			change = true
			self.afk = GetTime()
			self.dnd = nil
		end
	elseif (UnitIsDND(self.partyid)) then
		if (self.afk) then
			change = true
			self.afk = nil
		end
	else
		if (self.afk or self.dnd) then
			self.afk, self.dnd = nil, nil
			change = true
		end
	end

	if (change) then
		TPerl_Party_UpdateHealth(self)
	end
end

--------------------
-- Buff Functions --
--------------------

-- TPerl_Party_SetDebuffLocation
function TPerl_Party_SetDebuffLocation(self)
	local debuff1 = self.buffFrame.debuff and self.buffFrame.debuff[1]
	if (debuff1) then
		debuff1:ClearAllPoints()

		if (pconf.debuffs.below) then
			local buff1 = self.buffFrame.buff and self.buffFrame.buff[1]
			if (not buff1) then
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", self.buffFrame, "TOPRIGHT", 0, -20)
				else
					debuff1:SetPoint("TOPLEFT", self.buffFrame, "TOPLEFT", 0, -20)
				end
			else
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", buff1, "BOTTOMRIGHT", 0, -2)
				else
					debuff1:SetPoint("TOPLEFT", buff1, "BOTTOMLEFT", 0, -2)
				end
			end
		else
			if (self.petFrame and self.petFrame:IsShown()) then
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", self.petFrame.nameFrame, "TOPLEFT", 0, -4)
				else
					debuff1:SetPoint("TOPLEFT", self.petFrame.nameFrame, "TOPRIGHT", 0, -4)
				end
			else
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", self.statsFrame, "TOPLEFT", 0, -4)
				else
					debuff1:SetPoint("TOPLEFT", self.statsFrame, "TOPRIGHT", 0, -4)
				end
			end

			if (pconf.debuffs.halfSize) then
				local buffWidth = debuff1:GetWidth() * debuff1:GetScale()
				local selfWidth = self:GetWidth() * self:GetScale()
				local maxDebuffWidth = floor(selfWidth / buffWidth)
				local prev
				if (self.perlDebuffs > maxDebuffWidth) then
					self.debuffFrame:SetScale(0.5)

					local Anchor, aHalf, aPrev, x
					if (pconf.flip) then
						Anchor = "TOPRIGHT"
						aHalf = "BOTTOMRIGHT"
						aPrev = "TOPLEFT"
						x = -2
					else
						Anchor = "TOPLEFT"
						aHalf = "BOTTOMLEFT"
						aPrev = "TOPRIGHT"
						x = 0
					end

					local halfPoint = ceil(self.perlBuffs / 2)
					for k, v in pairs(self.buffFrame.debuff) do
						if (prev) then
							v:ClearAllPoints()
							if (k == halfPoint) then
								v:SetPoint(Anchor, debuff1, aHalf, x, 0)
							else
								v:SetPoint(Anchor, prev, aPrev, x, 0)
							end
						end
						prev = v
					end
				else
					self.debuffFrame:SetScale(1)

					local Anchor, aPrev, x
					if (pconf.flip) then
						Anchor = "TOPRIGHT"
						aPrev = "TOPLEFT"
						x = -2
					else
						Anchor = "TOPLEFT"
						aPrev = "TOPRIGHT"
						x = 0
					end

					local prev
					for k, v in pairs(self.buffFrame.debuff) do
						if (prev) then
							v:ClearAllPoints()
							v:SetPoint(Anchor, prev, aPrev, x, 0)
						end
						prev = v
					end
				end
			else
				local Anchor, aPrev, x
				if (pconf.flip) then
					Anchor = "TOPRIGHT"
					aPrev = "TOPLEFT"
					x = -2
				else
					Anchor = "TOPLEFT"
					aPrev = "TOPRIGHT"
					x = 0
				end

				local prev
				for k, v in pairs(self.buffFrame.debuff) do
					if (prev) then
						v:ClearAllPoints()
						v:SetPoint(Anchor, prev, aPrev, x, 0)
					end
					prev = v
				end

				self.debuffFrame:SetScale(1)
			end
		end
	end
end

-- TPerl_Party_BuffPositions
local function TPerl_Party_BuffPositions(self)
	if (self.conf) then
		if (pconf.debuffs.below) then
			if (pconf.buffs.wrap) then
				TPerl_Unit_BuffPositions(self, self.buffFrame.buff, self.buffFrame.debuff, self.conf.buffs.size, self.conf.debuffs.size)
			end
		else
			-- Debuffs handled seperately by legacy code, so just do buffs
			if (pconf.buffs.wrap) then
				TPerl_Unit_BuffPositions(self, self.buffFrame.buff, nil, self.conf.buffs.size)
			end
			if pconf.debuffs.enable then
				TPerl_Party_SetDebuffLocation(self)
			end
		end
	end
end

-- TPerl_Party_Buff_UpdateAll
local function TPerl_Party_Buff_UpdateAll(self)
	--[[if not self:IsVisible() then
		return
	end]]
	if (self.conf) then
		if (not pconf.buffs.enable and not pconf.debuffs.enable) then
			self.buffFrame:Hide()
			self.debuffFrame:Hide()
		else
			TPerl_Unit_UpdateBuffs(self, nil, nil, pconf.buffs.castable, pconf.debuffs.curable)
			TPerl_Party_BuffPositions(self)
		end

		--[[if conf.showFD then
			local _, class = UnitClass(self.partyid)
			if (class == "HUNTER") then
				local feigning = UnitBuff(self.partyid, feignDeath)
				if (feigning ~= self.feigning) then
					self.feigning = feigning
					TPerl_Party_UpdateHealth(self)
				end
			end
		end--]]

		if (conf.highlightDebuffs.enable) then
			TPerl_CheckDebuffs(self, self.partyid)
		end
	end
end

-------------------------
-- The Update Function --
-------------------------
local function TPerl_Party_CombatFlash(self, elapsed, argNew, argGreen)
	if (TPerl_CombatFlashSet(self, elapsed, argNew, argGreen)) then
		TPerl_CombatFlashSetFrames(self)
	end
end

-- TPerl_Party_UpdateName
local function TPerl_Party_UpdateName(self)
	local partyid = self.partyid
	local Partyname = UnitName(partyid)
	self.lastName = Partyname
	self.lastGUID = UnitGUID(partyid)
	if (Partyname) then
		local fontPath = TPerl_GetFont()
		local fontScale = TPerl_GetFontScale()
		self.nameFrame.text:SetFont(fontPath, 12 * fontScale, "")
		self.nameFrame.text:SetText(Partyname)

		if (self.nameFrame.text:GetStringWidth() > self.nameFrame:GetWidth() - 4) then
			self.nameFrame.text:SetFont(fontPath, 10 * fontScale, "")
		end

		TPerl_ColourFriendlyUnit(self.nameFrame.text, partyid)
	end
end

-- UpdateAssignedRoles
local function UpdateAssignedRoles(self)
	local unit = self.partyid
	local icon = self.nameFrame.roleIcon
	local isTank, isHealer, isDamage
	local inInstance, instanceType = IsInInstance()
	if not IsVanillaClassic and instanceType == "party" then
		-- No point getting it otherwise, as they can be wrong. Usually the values you had
		-- from previous instance if you're running more than one with the same people

		-- According to http://forums.worldofwarcraft.com/thread.html?topicId=26560499864
		-- this is the new way to check for roles
		-- Port this from TPerl_Player.lua by PlayerLin
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

	icon:ClearAllPoints()
	if (self.nameFrame.masterIcon:IsShown()) then
		icon:SetPoint("LEFT", self.nameFrame.masterIcon, "RIGHT")
	elseif (self.nameFrame.leaderIcon:IsShown()) then
		icon:SetPoint("LEFT", self.nameFrame.leaderIcon, "RIGHT")
	else
		icon:SetPoint("TOPLEFT", 10, 5)
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

-- UpdateAllAssignedRoles
local function UpdateAllAssignedRoles()
	for unit, frame in pairs(PartyFrames) do
		if (frame:IsShown()) then
			UpdateAssignedRoles(frame)
		end
	end
end

-- UpdatePhaseIndicators
local function UpdatePhasingDisplays(self)
	local unit = self.partyid
	local inPhase = not IsClassic and UnitPhaseReason(unit)

	if ( not inPhase or not UnitExists(unit) or not UnitIsConnected(unit)) then
		self.phasingIcon:Hide()
	else
		self.phasingIcon:Show()
	end
end

-- TPerl_Party_UpdateLeader
local function TPerl_Party_UpdateLeader(self)
	local partyid = self.partyid
	if (UnitIsGroupLeader(partyid)) then
		self.nameFrame.leaderIcon:Show()
	else
		self.nameFrame.leaderIcon:Hide()
	end

	local lootMethod, lootMaster, raidLootMaster = GetLootMethod()

	if (lootMethod == "master" and lootMaster) then
		if (partyid == "party"..lootMaster) then
			self.nameFrame.masterIcon:Show()
		else
			self.nameFrame.masterIcon:Hide()
		end
	end
	-- Removed the call to UpdateAllAssignedRoles because UpdateLeader() is called by UpdateDisplay()
	-- and UpdateDisplay() already call the UpdateAssignedRoles() function
end

-- TPerl_Party_UpdatePVP
local function TPerl_Party_UpdatePVP(self)
	local partyid = self.partyid

	local pvpIcon = self.nameFrame.pvpIcon

	local factionGroup, factionName = UnitFactionGroup(partyid)

	if pconf.pvpIcon and UnitIsPVPFreeForAll(partyid) then
		pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		pvpIcon:Show()
	elseif pconf.pvpIcon and factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(partyid) then
		pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)

		if not IsClassic and UnitIsMercenary(partyid) then
			if factionGroup == "Horde" then
				pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
			elseif factionGroup == "Alliance" then
				pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
			end
		end

		pvpIcon:Show()
	else
		pvpIcon:Hide()
	end

	--[[local pvp = pconf.pvpIcon and ((UnitIsPVPFreeForAll(self.partyid) and "FFA") or (UnitIsPVP(self.partyid) and (UnitFactionGroup(self.partyid) ~= "Neutral") and UnitFactionGroup(self.partyid)))
	if (pvp) then
		self.nameFrame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		self.nameFrame.pvpIcon:Show()
	else
		self.nameFrame.pvpIcon:Hide()
	end]]
end

-- TPerl_Party_UpdateCombat
local function TPerl_Party_UpdateCombat(self)
	local partyid = self.partyid
	if UnitIsVisible(partyid) then
		if (UnitAffectingCombat(partyid)) then
			self.nameFrame.combatIcon:Show()
		else
			self.nameFrame.combatIcon:Hide()
		end

		if UnitIsCharmed(partyid) and UnitIsPlayer(partyid) and (not IsClassic and (self.ownerid and not UnitUsingVehicle(self.ownerid)) or true) then
			self.nameFrame.warningIcon:Show()
		else
			self.nameFrame.warningIcon:Hide()
		end
	else
		self.nameFrame.combatIcon:Hide()
		self.nameFrame.warningIcon:Hide()
	end
end

-- TPerl_Party_UpdateClass
local function TPerl_Party_UpdateClass(self)
	local partyid = self.partyid
	if (UnitIsPlayer(partyid)) then
		local _, class = UnitClass(partyid)
		local l, r, t, b = TPerl_ClassPos(class)
		self.classFrame.tex:SetTexCoord(l, r, t, b)
	end

	if (pconf.classIcon) then
		self.classFrame:Show()
	else
		self.classFrame:Hide()
	end
end

-- TPerl_Party_UpdateMana
local function TPerl_Party_UpdateMana(self)
	local partyid = self.partyid
	if (self.afk and not UnitIsAFK(partyid)) then
		TPerl_Party_UpdatePlayerFlags(self)
	end

	local powerType = TPerl_GetDisplayedPowerType(partyid)
	local unitPower = UnitPower(partyid, powerType)
	local unitPowerMax = UnitPowerMax(partyid, powerType)

	-- Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
	local powerPercent
	if unitPower > 0 and unitPowerMax == 0 then -- We have current mana but max mana failed.
		unitPowerMax = unitPower -- Make max mana at least equal to current health
		powerPercent = 1 -- And percent 100% cause a number divided by itself is 1, duh.
	elseif unitPower == 0 and unitPowerMax == 0 then -- Probably doesn't use mana or is oom?
		powerPercent = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
	else
		powerPercent = unitPower / unitPowerMax -- Everything is dandy, so just do it right way.
	end
	-- end division by 0 check

	--[[if (Partymanamax == 1 and Partymana > Partymanamax) then
		Partymanamax = Partymana
	end--]]

	self.statsFrame.manaBar:SetMinMaxValues(0, unitPowerMax)
	self.statsFrame.manaBar:SetValue(unitPower)

	if powerType >= 1 then
		-- For rage/energy/etc, just show the value
		self.statsFrame.manaBar.percent:SetText(unitPower)
		self.statsFrame.manaBar.text:SetFormattedText("%d/%d", unitPower, unitPowerMax)
	elseif pconf.percent then
		-- For mana, use inline percentage when percent option is enabled
		local showPercent = 100 * powerPercent
		if showPercent < 10 then
			self.statsFrame.manaBar.text:SetFormattedText("%d/%d (%.1f%%)", unitPower, unitPowerMax, showPercent)
		else
			self.statsFrame.manaBar.text:SetFormattedText("%d/%d (%d%%)", unitPower, unitPowerMax, showPercent)
		end
		-- Hide separate percent element
		self.statsFrame.manaBar.percent:SetText("")
	else
		-- Percent option disabled, show traditional layout
		self.statsFrame.manaBar.text:SetFormattedText("%d/%d", unitPower, unitPowerMax)
		self.statsFrame.manaBar.percent:SetFormattedText(percD, 100 * powerPercent)
	end

	--[[if (pconf.values) then
		self.statsFrame.manaBar.text:Show()
	else
		self.statsFrame.manaBar.text:Hide()
	end]]

	if (not UnitIsConnected(partyid)) then
		self.statsFrame.healthBar.text:SetText(TPERL_LOC_OFFLINE)
		if (not self.statsFrame.greyMana) then
			self.statsFrame:SetGrey()
		end
	end
end

-- TPerl_Party_UpdateRange
local function TPerl_Party_Update_Range(self, overrideUnit)
	local partyid = overrideUnit or self.partyid
	if not partyid then
		return
	end
	if not pconf.range30yard then
		self.nameFrame.rangeIcon:Hide()
		return
	end
	local inRange = false
	if IsCataClassic or IsMistsClassic then
		inRange = CheckInteractDistance(partyid, 4)
	else
		local range, checkedRange = UnitInRange(partyid)
		if not checkedRange then
			inRange = true
		end
	end
	if not UnitIsConnected(partyid) or inRange then
		self.nameFrame.rangeIcon:Hide()
	else
		self.nameFrame.rangeIcon:Show()
		self.nameFrame.rangeIcon:SetAlpha(1)
	end
	--[[if (UnitInVehicle(self.partyid) and pconf.range30yard) then -- Not sure if this is proper way to do it, so this pretty much forces anyone in a vehicle to show out of range.
		self.nameFrame.rangeIcon:Show()
		self.nameFrame.rangeIcon:SetAlpha(1)
	end]]
end

-- TPerl_Party_SingleGroup
function TPerl_Party_SingleGroup()
	local num = GetNumGroupMembers()
	if (num > 5) then
		return
	end
	for i = 1, num do
		local _, _, subgroup = GetRaidRosterInfo(i)
		if (subgroup > 1) then
			return
		end
	end
	return true
end

-- CheckRaid
local function CheckRaid()
	if (InCombatLockdown()) then
		TPerl_OutOfCombatQueue[CheckRaid] = false
		return
	else
		if not pconf.enable then
			if partyHeader:IsShown() then
				partyHeader:Hide()
			end
			return
		end
		partyAnchor:StopMovingOrSizing()

		local singleGroup = TPerl_Party_SingleGroup()

		if (not pconf or ((pconf.inRaid and IsInRaid()) or (pconf.smallRaid and singleGroup) or (GetNumGroupMembers() > 0 and not IsInRaid()))) then -- or GetNumGroupMembers() > 0
			if not IsClassic then
				if not C_PetBattles.IsInBattle() then
					if (not partyHeader:IsShown()) then
						partyHeader:Show()
					end
				else
					if (partyHeader:IsShown()) then
						partyHeader:Hide()
					end
				end
			else
				if (not partyHeader:IsShown()) then
					partyHeader:Show()
				end
			end
		else
			if (partyHeader:IsShown()) then
				partyHeader:Hide()
			end
		end
	end
end

-- TPerl_Party_TargetUpdateHealPrediction
local function TPerl_Party_TargetUpdateHealPrediction(self)
	if pconf.healprediction then
		TPerl_SetExpectedHealth(self)
	else
		self.expectedHealth:Hide()
	end
end

-- TPerl_Party_TargetUpdateAbsorbPrediction
local function TPerl_Party_TargetUpdateAbsorbPrediction(self)
	if pconf.absorbs then
		TPerl_SetExpectedAbsorbs(self)
	else
		self.expectedAbsorbs:Hide()
	end
end

-- TPerl_Party_TargetUpdateHealth
local function TPerl_Party_TargetUpdateHealth(self)
	local tf = self.targetFrame
	local targetid = self.targetid
	local hp, hpMax, heal, absorb = UnitIsGhost(targetid) and 1 or (UnitIsDead(targetid) and 0 or UnitHealth(targetid)), UnitHealthMax(targetid), not IsVanillaClassic and UnitGetIncomingHeals(targetid), not IsClassic and UnitGetTotalAbsorbs(targetid)
	tf.lastHP, tf.lastHPMax, tf.lastHeal, tf.lastAbsorb = hp, hpMax, heal, absorb
	tf.lastUpdate = GetTime()

	--tf.healthBar:SetMinMaxValues(0, hpMax)
	--tf.healthBar:SetValue(hp)
	-- Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
	local percent
	if UnitIsDeadOrGhost(targetid) then -- Probably dead target
		percent = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
	elseif hp > 0 and hpMax == 0 then -- We have current ho but max hp failed.
		hpMax = hp -- Make max hp at least equal to current health
		percent = 1 -- And percent 100% cause a number divided by itself is 1, duh.
	else
		if hpMax > 0 then
			percent = hp / hpMax--Everything is dandy, so just do it right way.
		end
	end
	--tf.healthBar:SetAlpha(1)
	-- end division by 0 check
	if (hpMax > 0) then
		tf.healthBar.text:SetFormattedText(percD, 100 * percent)	-- TPerl_Percent[floor(100 * hp / hpMax)])
		tf.healthBar:SetMinMaxValues(0, hpMax)
		tf.healthBar:SetValue(hp)
	end
	tf.healthBar.text:Show()

	TPerl_Party_TargetUpdateAbsorbPrediction(self.targetFrame)
	TPerl_Party_TargetUpdateHealPrediction(self.targetFrame)

	if (UnitIsDeadOrGhost(targetid)) then
		tf.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
		tf.healthBar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
		if (UnitIsDead(targetid)) then
			tf.healthBar.text:SetText(TPERL_LOC_DEAD)
		else
			tf.healthBar.text:SetText(TPERL_LOC_GHOST)
		end
	else
		--TPerl_ColourHealthBar(self.targetFrame, hp / hpMax, targetid)
		if hpMax > 0 then
			TPerl_SetSmoothBarColor(self.targetFrame.healthBar, percent)
		end
	end

	if (UnitAffectingCombat(targetid)) then
		tf.combatIcon:SetTexCoord(0.49, 1.0, 0.0, 0.49)
		tf.combatIcon:Show()
	else
		tf.combatIcon:Hide()
	end

	local pvp = pconf.pvpIcon and ((UnitIsPVPFreeForAll(targetid) and "FFA") or (UnitIsPVP(targetid) and (UnitFactionGroup(targetid) ~= "Neutral") and UnitFactionGroup(targetid)))
	if (pvp) then
		tf.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		tf.pvpIcon:Show()
	else
		tf.pvpIcon:Hide()
	end
end

-- TPerl_Party_TargetRaidIcon
local function TPerl_Party_TargetRaidIcon(self)
	local partyid = self.partyid
	TPerl_Update_RaidIcon(self.targetFrame.raidIcon, partyid.."target")
	TPerl_Update_RaidIcon(self.nameFrame.raidIcon, partyid)
end

-- TPerl_Party_UpdateTarget
local function TPerl_Party_UpdateTarget(self)
	if (pconf.target.enable) then
		local targetid = self.targetid
		local partyid = self.partyid
		if (targetid and UnitIsConnected(partyid) and UnitExists(partyid) and UnitIsVisible(partyid)) then
			local targetname = UnitName(targetid)
			if (targetname and targetname ~= UNKNOWNOBJECT) then
				--self.targetFrame:SetAlpha(1)
				self.targetFrame.text:SetText(targetname)
				TPerl_SetUnitNameColor(self.targetFrame.text, targetid)
				TPerl_Party_TargetUpdateHealth(self)
				TPerl_Party_TargetRaidIcon(self)
			end
		end
	end
end

-- TPerl_Party_OnUpdate
function TPerl_Party_OnUpdate(self, elapsed)
	local partyid = self.partyid
	if not partyid then
		return
	end

	if pconf.hitIndicator and pconf.portrait then
		CombatFeedback_OnUpdate(self, elapsed)
	end

	if (self.PlayerFlash) then
		TPerl_Party_CombatFlash(self, elapsed, false)
	end

	--self.time = self.time + elapsed
	--if (self.time >= 0.2) then
		--self.time = 0
		local targetid = self.targetid

		self.flagsCheck = self.flagsCheck + 1
		if (self.flagsCheck > 25) then
			TPerl_Party_UpdatePlayerFlags(self)
			self.flagsCheck = 0
		end

		if (pconf.target.large and self.targetFrame:IsShown()) then
			local hp, hpMax, heal, absorb = UnitIsGhost(targetid) and 1 or (UnitIsDead(targetid) and 0 or UnitHealth(targetid)), UnitHealthMax(targetid), not IsVanillaClassic and UnitGetIncomingHeals(targetid), not IsClassic and UnitGetTotalAbsorbs(targetid)
			if (hp ~= self.targetFrame.lastHP or hpMax ~= self.targetFrame.lastHPMax or heal ~= self.targetFrame.lastHeal or absorb ~= self.targetFrame.lastAbsorb or GetTime() > self.targetFrame.lastUpdate + 5000) then
				TPerl_Party_TargetUpdateHealth(self)
			end
		end

		self.time = self.time + elapsed
		if (self.time >= 0.2) then
			if pconf.range30yard then
				TPerl_Party_Update_Range(self, partyid)
			end

			if conf.rangeFinder.enabled then
				TPerl_UpdateSpellRange(self, partyid)
				TPerl_UpdateSpellRange(self.targetFrame, targetid)
			end

			self.time = 0
		end

		--[=[if (checkRaidNextUpdate) then
			checkRaidNextUpdate = checkRaidNextUpdate - 1
			if (checkRaidNextUpdate <= 0) then
				checkRaidNextUpdate = nil
				CheckRaid()

				-- Due to a bug in the API (WoW 2.0.1), GetPartyLeaderIndex() can often claim
				-- that party1 is the leader, even when they're not. So, we do a delayed check
				-- after a party change
				--[[for i, frame in pairs(PartyFrames) do
					if (frame.partyid) then
						TPerl_Party_UpdateLeader(frame)
					end
				end]] -- Do we really need this now?
			end
		end]=]
	--end
end

-- TPerl_Party_Target_OnUpdate
function TPerl_Party_Target_OnUpdate(self, elapsed)
	self.time = elapsed + (self.time or 0)
	if (self.time >= 0.2) then
		TPerl_Party_UpdateTarget(self:GetParent())
		self.time = 0
	end
end

-- TPerl_Party_UpdateDisplayAll
function TPerl_Party_UpdateDisplayAll()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			TPerl_Party_UpdateDisplay(frame)
		end
	end
end

-- TPerl_Party_UpdateDisplay
function TPerl_Party_UpdateDisplay(self, less)
	local partyid = self.partyid
	if not partyid then
		return
	end
	if not UnitExists(partyid) then
		return
	end

	self.afk, self.dnd = nil, nil
	TPerl_Party_UpdateName(self)
	TPerl_Party_TargetRaidIcon(self)
	TPerl_Party_UpdateLeader(self)
	TPerl_Party_UpdateClass(self)
	UpdateAssignedRoles(self)
	UpdatePhasingDisplays(self)

	if (not less) then
		TPerl_SetManaBarType(self)
		TPerl_Party_UpdateMana(self)
		TPerl_Party_UpdateHealth(self)
		TPerl_Unit_UpdateLevel(self)
	end

	TPerl_Party_UpdatePlayerFlags(self)
	TPerl_Party_UpdateCombat(self)
	TPerl_Party_UpdatePVP(self)
	TPerl_Unit_UpdatePortrait(self)
	TPerl_Party_Buff_UpdateAll(self)
	TPerl_Party_UpdateTarget(self)
	TPerl_Unit_UpdateReadyState(self)

	if pconf.range30yard then
		TPerl_Party_Update_Range(self)
	else
		self.nameFrame.rangeIcon:Hide()
	end
	TPerl_UpdateSpellRange(self, partyid)
end

-------------------
-- Event Handler --
-------------------
function TPerl_Party_OnEvent(self, event, unit, ...)
	if (strfind(event, "^UNIT_") and event ~= "UNIT_THREAT_LIST_UPDATE") then
		local frame = PartyFrames[unit]
		if frame then
			if event == "UNIT_CONNECTION" or event == "UNIT_PHASE" or event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_COMBAT" then
				if not UnitIsUnit(frame.partyid, unit) then
					return
				end

				TPerl_Party_Events[event](frame, unit, ...)
			else
				if not UnitIsUnit(frame.partyid, unit) then
					return
				end

				TPerl_Party_Events[event](frame, ...)
			end
		end
	else
		TPerl_Party_Events[event](self, unit, ...)
	end
end

-- PARTY_LEADER_CHANGED
-- fix by Sontix this portion of code was never called becuse the even PARTY_LEDAER_CHANGED is not registered
-- because Xperl rearrange the party members order to keep always on top the leader, UpdateDisplay() was need
-- to not mess-up party frame
-- (in that function the Leader Icon is updated, so there's no need to listen to this event)
-- function TPerl_Party_Events:PARTY_LEADER_CHANGED()
--	for i,frame in pairs(PartyFrames) do
--		if (frame.partyid) then
-- 			TPerl_Party_UpdateLeader(frame)
-- 		end
-- 	end
-- end

function TPerl_Party_Events:PARTY_LOOT_METHOD_CHANGED()
	local lootMethod, pindex,rindex = GetLootMethod()

	if (lootMethod == "master") then
		for i, frame in pairs(PartyFrames) do
			if (frame.partyid) then

				if (rindex == nil) then
					if (frame.partyid == "party"..pindex) then
						frame.nameFrame.masterIcon:Show()
					else
						frame.nameFrame.masterIcon:Hide()
					end
				else
					--If we are also in a raid group
					if (UnitIsUnit("raid"..rindex,frame.partyid)) then
						frame.nameFrame.masterIcon:Show()
					else
						frame.nameFrame.masterIcon:Hide()
					end
				end
			end
		end
	end
end

--[[function TPerl_Party_Events:PET_BATTLE_OPENING_START()
	CheckRaid()
end

function TPerl_Party_Events:PET_BATTLE_CLOSE()
	CheckRaid()
end]]

-- RAID_TARGET_UPDATE
function TPerl_Party_Events:RAID_TARGET_UPDATE()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			TPerl_Party_TargetRaidIcon(frame)
		end
	end
end

-- READY_CHECK
function TPerl_Party_Events:READY_CHECK()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			TPerl_Unit_UpdateReadyState(frame)
		end
	end
end

TPerl_Party_Events.READY_CHECK_CONFIRM = TPerl_Party_Events.READY_CHECK
TPerl_Party_Events.READY_CHECK_FINISHED = TPerl_Party_Events.READY_CHECK

-- UNIT_COMBAT
function TPerl_Party_Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end

	if (pconf.hitIndicator and pconf.portrait) then
		CombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
	end

	TPerl_Party_UpdateCombat(self)
	if (action == "HEAL") then
		TPerl_Party_CombatFlash(self, 0, true, true)
	elseif (damage and damage > 0) then
		TPerl_Party_CombatFlash(self, 0, true)
	end
end

-- UNIT_MAXHEALTH
function TPerl_Party_Events:UNIT_MAXHEALTH()
	TPerl_Party_UpdateHealth(self)
	TPerl_Unit_UpdateLevel(self) -- Level not available until we've received maxhealth
	TPerl_Party_UpdateClass(self)
end

-- UNIT_HEALTH_FREQUENT
function TPerl_Party_Events:UNIT_HEALTH_FREQUENT()
	TPerl_Party_UpdateHealth(self)
end

-- UNIT_HEALTH
function TPerl_Party_Events:UNIT_HEALTH()
	TPerl_Party_UpdateHealth(self)
end

-- UNIT_CONNECTION
function TPerl_Party_Events:UNIT_CONNECTION(unit, online)
	if (unit == self.partyid) then
		TPerl_Party_UpdateDisplay(self)
	end
end

-- UNIT_PHASE
function TPerl_Party_Events:UNIT_PHASE(unit)
	if (unit == self.partyid) then
		TPerl_Party_UpdateDisplay(self)
	end
end

local function updatePartyThreat(immediate)
	for unitid, frame in pairs(PartyFrames) do
		if (frame:IsShown()) then
			TPerl_Unit_ThreatStatus(frame, nil, immediate)
		end
	end
end

function TPerl_Party_Events:UNIT_THREAT_LIST_UPDATE(unit)
	if (unit == "target") then
		updatePartyThreat()
	end
end

function TPerl_Party_Events:PLAYER_TARGET_CHANGED()
	if partyHeader:GetAttribute("showPlayer") then
		local f = PartyFrames["player"]
		if f then
			--TPerl_Party_UpdateDisplay(f)
			TPerl_Party_UpdateTarget(f)
			TPerl_UpdateSpellRange(f.targetFrame, "target")
		end
	end
	updatePartyThreat(true)
end

-- PLAYER_ENTERING_WORLD
function TPerl_Party_Events:PLAYER_ENTERING_WORLD()
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE") -- Re-do, in case

	if (not startupDone) then
		startupDone = true
		TPerl_ProtectedCall(TPerl_Party_SetInitialAttributes)
		CheckRaid()
	end

	TPerl_Party_UpdateDisplayAll()
end

-- TPerl_Party_GetUnitFrameByUnit
function TPerl_Party_GetUnitFrameByUnit(unitid)
	return PartyFrames[unitid]
end

local rosterGuids = { }
-- TPerl_Party_GetUnitFrameByGUID
function TPerl_Party_GetUnitFrameByGUID(guid)
	local unitid = rosterGuids and rosterGuids[guid]
	if (unitid) then
		return PartyFrames[unitid]
	end
end

local function BuildGuidMap()
	if (GetNumSubgroupMembers() > 0) then
		--rosterGuids = TPerl_GetReusableTable()
		wipe(rosterGuids)
		if partyHeader:GetAttribute("showPlayer") then
			local guid = UnitGUID("player")
			if (guid) then
				rosterGuids[guid] = "player"
			end
		end
		for i = 1, GetNumSubgroupMembers() do
			local guid = UnitGUID("party"..i)
			if (guid) then
				rosterGuids[guid] = "party"..i
			end
		end
	else
		--rosterGuids = TPerl_FreeTable(rosterGuids)
		rosterGuids = { }
	end
end

function TPerl_Party_Events:GROUP_ROSTER_UPDATE()
	BuildGuidMap()
	--checkRaidNextUpdate = 3
	CheckRaid()
	TPerl_SetHighlights()
	TPerl_Party_UpdateDisplayAll()
end

TPerl_Party_Events.PLAYER_LOGIN = TPerl_Party_Events.GROUP_ROSTER_UPDATE

-- UNIT_PORTRAIT_UPDATE
function TPerl_Party_Events:UNIT_PORTRAIT_UPDATE()
	TPerl_Unit_UpdatePortrait(self, true)
end

-- UNIT_POWER_FREQUENT / UNIT_MAXPOWER
function TPerl_Party_Events:UNIT_POWER_FREQUENT()
	TPerl_Party_UpdateMana(self)
end

TPerl_Party_Events.UNIT_MAXPOWER = TPerl_Party_Events.UNIT_POWER_FREQUENT

-- UNIT_DISPLAYPOWER
function TPerl_Party_Events:UNIT_DISPLAYPOWER()
	TPerl_SetManaBarType(self)
	TPerl_Party_UpdateMana(self)
end

-- PLAYER_FLAGS_CHANGED()
function TPerl_Party_Events:PLAYER_FLAGS_CHANGED(unit)
	local f = PartyFrames[unit]
	if (f) then
		TPerl_Party_UpdatePlayerFlags(f)
	end
end

function TPerl_Party_Events:INCOMING_RESURRECT_CHANGED(unit)
	local f = PartyFrames[unit]
	if (f) then
		TPerl_Party_UpdateResurrectionStatus(f)
	end
end


-- UNIT_NAME_UPDATE
function TPerl_Party_Events:UNIT_NAME_UPDATE()
	TPerl_Party_UpdateName(self)
	TPerl_Party_UpdateHealth(self) -- Flags, class etc. not available until the first UNIT_NAME_UPDATE
	TPerl_Party_UpdateClass(self)
end

-- UNIT_LEVEL
function TPerl_Party_Events:UNIT_LEVEL()
	TPerl_Unit_UpdateLevel(self)
end

-- UNIT_AURA
function TPerl_Party_Events:UNIT_AURA()
	TPerl_Party_Buff_UpdateAll(self)
end

-- UNIT_FACTION
function TPerl_Party_Events:UNIT_FACTION(unit)
	TPerl_Party_UpdateName(self)
	TPerl_Party_UpdateCombat(self)
	TPerl_Party_UpdatePVP(self)
	TPerl_Unit_ThreatStatus(self)
end

TPerl_Party_Events.UNIT_FLAGS = TPerl_Party_Events.UNIT_FACTION

function TPerl_Party_Events:UNIT_TARGET()
	TPerl_Party_UpdateTarget(self)
	updatePartyThreat(true)
end

function TPerl_Party_Events:UNIT_HEAL_PREDICTION(unit)
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

function TPerl_Party_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if (pconf.absorbs and unit == self.partyid) then
		TPerl_SetExpectedAbsorbs(self)
	end
end

---- Moving stuff ----
-- TPerl_Party_GetGap
function TPerl_Party_GetGap()
	--return floor(floor((TPerl_party1:GetBottom() - TPerl_party2:GetTop() + 0.01) * 100) / 100)
	return pconf.spacing
end

-- TPerl_Party_SetGap
function TPerl_Party_SetGap(newGap)
	if (type(newGap) ~= "number") then
		return
	end
	pconf.spacing = newGap
	TPerl_Party_SetMainAttributes()
	TPerl_Party_Virtual(true)
end

-- CalcWidth
local function CalcWidth(self)
	--return TPerl_party1Highlight:GetWidth()

	local w = self.statsFrame:GetWidth() or 0

	if (pconf and pconf.portrait) then
		w = w + (self.portraitFrame:GetWidth() or 0) - 2

		--[[if (pconf.level or pconf.classIcon) then
			w = w + (self.levelFrame:GetWidth() or 0) - 2
		end]]
	else
		w = w + (self.levelFrame:GetWidth() or 0) - 2
	end

	return w
end

-- CalcHeight
local function CalcHeight(self)
	--return TPerl_party1Highlight:GetHeight()

	if (pconf and pconf.portrait) then
		return self.portraitFrame:GetHeight() + 1
	end

	local h = self.statsFrame:GetHeight()

	if (pconf and pconf.name) then
		h = h + self.nameFrame:GetHeight() - 2
	end

	return h
end

-- TPerl_Party_SetWidth
function TPerl_Party_SetWidth(self)

	pconf.size.width = max(0, pconf.size.width or 0)

	-- Remove percent width expansion since we use inline percentages
	local width = 122	-- Same width regardless of percent setting
	self.statsFrame:SetWidth(width + pconf.size.width)
	self:SetWidth(CalcWidth(self))

	self.nameFrame:SetWidth(122 + (pconf.size.width / 2))

	-- Hide separate percent elements (using inline percentages now)
	self.statsFrame.healthBar.percent:Hide()
	self.statsFrame.manaBar.percent:Hide()

	TPerl_StatsFrameSetup(self)
end

-- TPerl_Party_Set_Bits
function TPerl_Party_Set_Bits1(self)
	if (InCombatLockdown()) then
		TPerl_OutOfCombatQueue[TPerl_Party_Set_Bits1] = self
		return
	end

	self.portraitFrame:ClearAllPoints()
	self.nameFrame:ClearAllPoints()
	self.levelFrame:ClearAllPoints()
	self.statsFrame:ClearAllPoints()
	self.classFrame:ClearAllPoints()
	self.levelFrame.text:ClearAllPoints()
	self.highlight:ClearAllPoints()

	if (not pconf.portrait) then
		self.portraitFrame:Hide()

		self.levelFrame:SetWidth(30)
		self.levelFrame:SetHeight(41)

		if (pconf.flip) then
			self.nameFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			self.levelFrame:SetPoint("TOPRIGHT", self.nameFrame, "BOTTOMRIGHT", 0, 3)
			self.statsFrame:SetPoint("TOPRIGHT", self.levelFrame, "TOPLEFT", 2, 0)

			self.levelFrame.text:SetPoint("BOTTOM", self.levelFrame, "BOTTOM", 0, 4)
			self.classFrame:SetPoint("TOPRIGHT", self.levelFrame, "TOPRIGHT", -5, -5)

			self.buffFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -2, 0)

			self.highlight:SetPoint("TOPRIGHT", self.nameFrame, "TOPRIGHT", 0, 0)
			self.highlight:SetPoint("BOTTOMLEFT", self.statsFrame, "BOTTOMLEFT", 0, 0)
		else
			self.nameFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.levelFrame:SetPoint("TOPLEFT", self.nameFrame, "BOTTOMLEFT", 0, 3)
			self.statsFrame:SetPoint("TOPLEFT", self.levelFrame, "TOPRIGHT", -2, 0)

			self.levelFrame.text:SetPoint("BOTTOM", self.levelFrame, "BOTTOM", 0, 4)
			self.classFrame:SetPoint("TOPLEFT", self.levelFrame, "TOPLEFT", 5, -5)

			self.buffFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, 0)

			self.highlight:SetPoint("TOPLEFT", self.nameFrame, "TOPLEFT", 0, 0)
			self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
		end
	else
		self.portraitFrame:Show()
		self.statsFrame.resurrect:Hide()

		self.levelFrame:SetWidth(27)
		self.levelFrame:SetHeight(22)

		if (pconf.flip) then
			self.portraitFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			self.levelFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, 0)
			self.nameFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPLEFT", 2, 0)
			self.statsFrame:SetPoint("TOPRIGHT", self.nameFrame, "BOTTOMRIGHT", 0, 3)

			self.levelFrame.text:SetPoint("CENTER", 0, 0)
			self.classFrame:SetPoint("BOTTOMLEFT", self.portraitFrame, "BOTTOMRIGHT", 0, 3)

			self.buffFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -2, 0)

			self.highlight:SetPoint("TOPRIGHT", self.portraitFrame, "TOPRIGHT", 0, 0)
			self.highlight:SetPoint("BOTTOMLEFT", self.statsFrame, "BOTTOMLEFT", 0, 0)
		else
			self.portraitFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.levelFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPLEFT", 2, 0)
			self.nameFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, 0)
			self.statsFrame:SetPoint("TOPLEFT", self.nameFrame, "BOTTOMLEFT", 0, 3)

			self.levelFrame.text:SetPoint("CENTER", 0, 0)
			self.classFrame:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMLEFT", 0, 3)

			self.buffFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, 0)

			self.highlight:SetPoint("TOPLEFT", self.portraitFrame, "TOPLEFT", 0, 0)
			self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
		end
	end

	if (pconf.level) then
		self.levelFrame.text:Show()
		self.levelFrame:Show()

		if (pconf.portrait) then
			self.levelFrame:SetWidth(27)
		else
			self.levelFrame:SetWidth(30)
		end
	else
		self.levelFrame.text:Hide()
		self.levelFrame:Hide()
	end

	if (pconf.classIcon) then
		self.classFrame:Show()
		--self.levelFrame:Show()

		if (pconf.portrait) then
			self.levelFrame:SetWidth(27)
		else
			self.levelFrame:SetWidth(30)
		end
	else
		self.classFrame:Hide()

		if (not pconf.level) then
			self.levelFrame:SetWidth(2)
			--self.levelFrame:Hide()
		end
	end

	ShowHideValues(self)

	-- Hide separate percent elements (using inline percentages now)
	self.statsFrame.healthBar.percent:Hide()
	self.statsFrame.manaBar.percent:Hide()

	local height = ((pconf.name or 0) * 22) + 2 -- 24 when enabled, 2 when disabled

	self.targetFrame:ClearAllPoints()
	self.nameFrame:SetHeight(height)

	if (pconf.name) then
		self.nameFrame:Show()
		if (pconf.flip) then
			self.targetFrame:SetPoint("BOTTOMRIGHT", self.nameFrame, "BOTTOMLEFT", 2, 0)
		else
			self.targetFrame:SetPoint("BOTTOMLEFT", self.nameFrame, "BOTTOMRIGHT", -2, 0)
		end
	else
		self.nameFrame:Hide()
		if (pconf.flip) then
			self.targetFrame:SetPoint("TOPRIGHT", self.statsFrame, "BOTTOMRIGHT", 2, 0)
		else
			self.targetFrame:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", -2, 0)
		end
	end

	if (pconf.target.large) then
		self.targetFrame.healthBar.text:SetTextColor(1, 1, 1)
		self.targetFrame:SetHeight(28)
		self.targetFrame.healthBar:Show()
	else
		self.targetFrame:SetHeight(20)
		self.targetFrame.healthBar:Hide()
	end

	self.targetFrame:SetWidth(pconf.target.size)

	pconf.buffs.size = tonumber(pconf.buffs.size) or 20
	TPerl_SetBuffSize(self)

	local function SetAllBuffs(self, buffs, debuff)
		local prevAnchor
		if (pconf.flip) then
			prevAnchor = "TOPRIGHT"
		else
			prevAnchor = "TOPLEFT"
		end
		if (buffs) then
			local prev = self
			for k,v in pairs(buffs) do
				v:ClearAllPoints()
				if (pconf.flip) then
					v:SetPoint("TOPRIGHT", prev, prevAnchor, -(1 + debuff), 0)
				else
					v:SetPoint("TOPLEFT", prev, prevAnchor, 1 + debuff, 0)
				end
				prev = v
				if (pconf.flip) then
					prevAnchor = "TOPLEFT"
				else
					prevAnchor = "TOPRIGHT"
				end
			end
		end
	end

	if (not pconf.debuffs.halfSize) then
		self.debuffFrame:SetScale(1)
	end
	SetAllBuffs(self.debuffFrame, self.buffFrame.debuff, 1)
	SetAllBuffs(self.buffFrame, self.buffFrame.buff, 0)

	self.buffOptMix = nil
	self.debuffFrame:SetScale(1)
	TPerl_Party_BuffPositions(self)

	TPerl_Party_SetWidth(self)

	if (pconf.target.enable) then
		RegisterUnitWatch(self.targetFrame)
	else
		UnregisterUnitWatch(self.targetFrame)
		self.targetFrame:Hide()
	end

	if (self:IsShown()) then
		TPerl_Party_UpdateDisplay(self)
	end

	--TPerl_SetTextTransparencyFrame(self)

	--[[if (conf.ShowPartyPets == 1 and TPerl_PartyPetFrames) then
		if (not self.petFrame) then
			self.petFrame = CreateFrame("Button", "TPerl_partypet"..self:GetID(), self, "TPerl_Party_Pet_FrameTemplate")
	end]]

	self.petFrame = _G["TPerl_partypet"..self:GetID()]
	if (self.petFrame) then
		self.petFrame:ClearAllPoints()
		if (pconf.flip) then
			self.petFrame:SetPoint("TOPRIGHT", self.statsFrame, "TOPLEFT", 2, 0)
		else
			self.petFrame:SetPoint("TOPLEFT", self.statsFrame, "TOPRIGHT", -2, 0)
		end
	end

	if (TPerl_Voice) then
		TPerl_Voice:Register(self, true)
	end
end

-- TPerl_Party_SetInitialAttributes()
function TPerl_Party_SetInitialAttributes()

	--[[partyHeader.initialConfigFunction = function(self)
		-- This is the only place we're allowed to set attributes whilst in combat

		self:SetAttribute("*type1", "target")
		self:SetAttribute("type2", "menu")
		self.menu = TPerl_ShowGenericMenu
		TPerl_RegisterClickCastFrame(self)

		-- Does AllowAttributeChange work for children?
		self.nameFrame:SetAttribute("useparent-unit", true)
		self.nameFrame:SetAttribute("*type1", "target")
		self.nameFrame:SetAttribute("type2", "menu")
		self.nameFrame.menu = TPerl_ShowGenericMenu
		TPerl_RegisterClickCastFrame(self.nameFrame)

		--self:SetAttribute("initial-height", CalcHeight())
		--self:SetAttribute("initial-width", CalcWidth())
	end--]]

	-- Fix Secure Header taint in combat
	--[[local maxColumns = partyHeader:GetAttribute("maxColumns") or 1
	local unitsPerColumn = partyHeader:GetAttribute("unitsPerColumn") or 5
	local startingIndex = partyHeader:GetAttribute("startingIndex") or 1
	local maxUnits = maxColumns * unitsPerColumn

	partyHeader:Show()
	partyHeader:SetAttribute("startingIndex", - maxUnits + 1)
	partyHeader:SetAttribute("startingIndex", startingIndex)--]]

	partyHeader:Hide()

	TPerl_Party_SetMainAttributes()
	CheckRaid()
end

-- TPerl_Party_SetMainAttributes
function TPerl_Party_SetMainAttributes()
	partyAnchor:StopMovingOrSizing()

	partyHeader:ClearAllPoints()
	if (pconf.anchor == "TOP") then
		partyHeader:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", 0)
		partyHeader:SetAttribute("yOffset", -pconf.spacing)
	elseif (pconf.anchor == "LEFT") then
		partyHeader:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", pconf.spacing)
		partyHeader:SetAttribute("yOffset", 0)
	elseif (pconf.anchor == "BOTTOM") then
		partyHeader:SetPoint("BOTTOMLEFT", partyAnchor, "BOTTOMLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", 0)
		partyHeader:SetAttribute("yOffset", pconf.spacing)
	elseif (pconf.anchor == "RIGHT") then
		partyHeader:SetPoint("BOTTOMRIGHT", partyAnchor, "BOTTOMRIGHT", 0, 0)
		partyHeader:SetAttribute("xOffset", -pconf.spacing)
		partyHeader:SetAttribute("yOffset", 0)
	end

	partyHeader:SetAttribute("point", pconf.anchor or "TOP")
end

-- TPerl_Party_Virtual
function TPerl_Party_Virtual(on)
	local virtual = TPerl_Party_AnchorVirtual
	if (on) then
		local w = CalcWidth(TPerl_party1)
		local h = CalcHeight(TPerl_party1)

		virtual:ClearAllPoints()
		if (pconf.anchor == "TOP") then
			virtual:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
			virtual:SetHeight((h * 4) + (pconf.spacing * 3))
			virtual:SetWidth(w)
		elseif (pconf.anchor == "LEFT") then
			virtual:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
			virtual:SetHeight(h)
			virtual:SetWidth(w * 4 + (pconf.spacing * 3))
		elseif (pconf.anchor == "BOTTOM") then
			virtual:SetPoint("BOTTOMLEFT", partyAnchor, "BOTTOMLEFT", 0, 0)
			virtual:SetHeight((h * 4) + (pconf.spacing * 3))
			virtual:SetWidth(w)
		elseif (pconf.anchor == "RIGHT") then
			virtual:SetPoint("TOPRIGHT", partyAnchor, "TOPRIGHT", 0, 0)
			virtual:SetHeight(h)
			virtual:SetWidth(w * 4 + (pconf.spacing * 3))
		end
		virtual:OnBackdropLoaded()
		virtual:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
		virtual:SetBackdropBorderColor(conf.colour.border.r, conf.colour.border.g, conf.colour.border.b, 1)
		virtual:Lower()
		if pconf.enable then
			virtual:Show()
		else
			virtual:Hide()
		end
	else
		if TPerlLocked == 0 then
			if pconf.enable then
				virtual:Show()
			else
				virtual:Hide()
			end
		else
			virtual:Hide()
		end
	end
end

-- TPerl_Party_Set_Bits
function TPerl_Party_Set_Bits()
	if (InCombatLockdown()) then
		TPerl_OutOfCombatQueue[TPerl_Party_Set_Bits] = false
		return
	end

	partyAnchor:SetScale(pconf.scale)
	TPerl_SavePosition(partyAnchor, true)

	TPerl_Party_SecureHeader:SetAttribute("showPlayer", pconf.showPlayer)

	TPerl_Party_SecureState:SetAttribute("partyEnabled", pconf.enable)
	TPerl_Party_SecureState:SetAttribute("partyInRaid", pconf.inRaid)
	TPerl_Party_SecureState:SetAttribute("partySmallRaid", pconf.smallRaid)

	if (TPerlDB) then
		conf = TPerlDB
		pconf = TPerlDB.party
		for k, v in pairs(PartyFrames) do
			v.conf = pconf
			TPerl_Party_Set_Bits1(v)
		end
	end

	TPerl_Party_SetInitialAttributes()
	TPerl_Register_Prediction(TPerl_Party_Events_Frame, pconf, function(guid)
		local frame = TPerl_Party_GetUnitFrameByGUID(guid)
		if frame then
			return frame.partyid
		end
	end)

	if (TPerl_Party_AnchorVirtual:IsShown()) then
		TPerl_Party_Virtual(true)
	else
		TPerl_Party_Virtual()
	end
	UpdateAllAssignedRoles()
end
