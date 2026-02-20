-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 18 October 2014

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local max = max
local pairs = pairs
local strfind = strfind
local tonumber = tonumber

local CreateFrame = CreateFrame
local GetDifficultyColor = GetDifficultyColor or GetQuestDifficultyColor
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local RegisterUnitWatch = RegisterUnitWatch
local UnitAffectingCombat = UnitAffectingCombat
local UnitAura = UnitAura
local UnitClassification = UnitClassification
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitHealthMax = UnitHealthMax
local UnitIsAFK = UnitIsAFK
local UnitIsCharmed = UnitIsCharmed
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsVisible = UnitIsVisible
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitUsingVehicle = UnitUsingVehicle
local UnregisterUnitWatch = UnregisterUnitWatch

local UIParent = UIParent

-- Midnight "secret value" helpers (safe across versions)
local pcall = pcall
local canaccessvalue = canaccessvalue
local issecretvalue = issecretvalue

local function TPerl_TT_CanAccess(v)
	-- In Midnight/Retail, values may be "secret" and cannot be compared/indexed in tainted addon code.
	if (not IsRetail) then
		return v ~= nil
	end
	if (canaccessvalue) then
		local ok, res = pcall(canaccessvalue, v)
		return ok and res or false
	end
	if (issecretvalue) then
		local ok, res = pcall(issecretvalue, v)
		return ok and (not res) or true
	end
	return v ~= nil
end

local function TPerl_TT_SafeBool(v)
	if (not IsRetail) then
		return (v and true or false)
	end
	if (not TPerl_TT_CanAccess(v)) then
		return false
	end
	return (v and true or false)
end

local function TPerl_TT_GUIDEquals(a, b)
	if (not IsRetail) then
		return a == b
	end
	if (not TPerl_TT_CanAccess(a) or not TPerl_TT_CanAccess(b)) then
		return false
	end
	local ok, res = pcall(function() return a == b end)
	return ok and res or false
end

local function TPerl_TT_GUIDEqualsUnit(unit, guid)
	return TPerl_TT_GUIDEquals(UnitGUID(unit), guid)
end

local function TPerl_TT_GuidChanged(newGuid, oldGuid)
	if (not IsRetail) then
		return newGuid ~= oldGuid
	end
	if (TPerl_TT_CanAccess(newGuid) and TPerl_TT_CanAccess(oldGuid)) then
		local ok, res = pcall(function() return newGuid ~= oldGuid end)
		return ok and res or true
	end
	return true
end

--local feignDeath = GetSpellInfo and GetSpellInfo(5384) or (C_Spell.GetSpellInfo(5384) and C_Spell.GetSpellInfo(5384).name)

local conf
TPerl_RequestConfig(function(new)
	conf = new
	if TPerl_TargetTarget then
		TPerl_TargetTarget.conf = conf.targettarget
	end
	if TPerl_TargetTargetTarget then
		TPerl_TargetTargetTarget.conf = conf.targettargettarget
	end
	if TPerl_FocusTarget then
		TPerl_FocusTarget.conf = conf.focustarget
	end
	if TPerl_PetTarget then
		TPerl_PetTarget.conf = conf.pettarget
	end
end, "$Revision:  $")

local buffSetup

-- TPerl_TargetTarget_OnLoad
function TPerl_TargetTarget_OnLoad(self)
	self:RegisterForClicks("AnyUp")
	self:RegisterForDrag("LeftButton")
	TPerl_SetChildMembers(self)

	local events = {
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_POWER_FREQUENT",
		"UNIT_AURA",
		"UNIT_TARGET",
		"INCOMING_RESURRECT_CHANGED",
	}

	self.guid = 0

	-- Events
	self:RegisterEvent("RAID_TARGET_UPDATE")
	if (self == TPerl_TargetTarget) then
		self.parentid = "target"
		self.partyid = "targettarget"
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		for i, event in pairs(events) do
			self:RegisterUnitEvent(event, "target")
		end
		TPerl_Register_Prediction(self, conf.targettarget, function(guid)
				if TPerl_TT_GUIDEqualsUnit("targettarget", guid) then
				return "targettarget"
			end
		end, "target")
		self:SetScript("OnUpdate", TPerl_TargetTarget_OnUpdate)
	elseif (self == TPerl_FocusTarget) then
		self.parentid = "focus"
		self.partyid = "focustarget"
		if not IsVanillaClassic then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		end
		for i, event in pairs(events) do
			self:RegisterUnitEvent(event, "focus")
		end
		TPerl_Register_Prediction(self, conf.targettarget, function(guid)
				if TPerl_TT_GUIDEqualsUnit("focustarget", guid) then
				return "focustarget"
			end
		end, "focus")
		self:SetScript("OnUpdate", TPerl_TargetTarget_OnUpdate)
	elseif (self == TPerl_PetTarget) then
		self.parentid = "pet"
		self.partyid = "pettarget"
		for i, event in pairs(events) do
			self:RegisterUnitEvent(event, "pet")
		end
		TPerl_Register_Prediction(self, conf.targettarget, function(guid)
				if TPerl_TT_GUIDEqualsUnit("pettarget", guid) then
				return "pettarget"
			end
		end, "pet")
		self:SetScript("OnUpdate", TPerl_TargetTarget_OnUpdate)
	else
		self.parentid = "targettarget"
		self.partyid = "targettargettarget"
		for i, event in pairs(events) do
			self:RegisterUnitEvent(event, "target")
		end
		TPerl_Register_Prediction(self, conf.targettarget, function(guid)
				if TPerl_TT_GUIDEqualsUnit("targettargettarget", guid) then
				return "targettargettarget"
			end
		end, "targettarget")
		self:SetScript("OnUpdate", TPerl_TargetTargetTarget_OnUpdate)
	end

	TPerl_SecureUnitButton_OnLoad(self, self.partyid, TPerl_ShowGenericMenu)
	TPerl_SecureUnitButton_OnLoad(self.nameFrame, self.partyid, TPerl_ShowGenericMenu)

	--RegisterUnitWatch(self)

	local BuffOnUpdate, DebuffOnUpdate, BuffUpdateTooltip, DebuffUpdateTooltip
	BuffUpdateTooltip = TPerl_Unit_SetBuffTooltip
	DebuffUpdateTooltip = TPerl_Unit_SetDeBuffTooltip

	if buffSetup then
		self.buffSetup = buffSetup
	else
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
			debuffSizeMod = 0.2,
			debuffAnchor1 = function(self, b)
				b:SetPoint("TOPLEFT", 0, 0)
			end,
		}
		self.buffSetup.buffAnchor1 = self.buffSetup.debuffAnchor1
		buffSetup = self.buffSetup
	end

	self.targetname = ""
	self.lastUpdate = 0

	--TPerl_InitFadeFrame(self)
	TPerl_RegisterHighlight(self.highlight, 2)
	TPerl_RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.levelFrame})

	if TPerlDB then
		self.conf = TPerlDB[self.partyid]
	end

	TPerl_Highlight:Register(TPerl_TargetTarget_HighlightCallback, self)

	if self == TPerl_TargetTarget then
		TPerl_RegisterOptionChanger(TPerl_TargetTarget_Set_Bits, "TargetTarget", "TPerl_TargetTarget_Set_Bits")
	end

	if TPerl_TargetTarget and TPerl_FocusTarget and TPerl_PetTarget and TPerl_TargetTargetTarget then
		TPerl_TargetTarget_OnLoad = nil
	end
end

-- TPerl_TargetTarget_HighlightCallback
function TPerl_TargetTarget_HighlightCallback(self, updateGUID)
	local partyid = self.partyid
	if (TPerl_TT_GUIDEqualsUnit(partyid, updateGUID) and UnitIsFriend("player", partyid)) then
		-- Don't forward secret GUIDs into addon systems that may index/compare them.
		if (not IsRetail or TPerl_TT_CanAccess(updateGUID)) then
			TPerl_Highlight:SetHighlight(self, updateGUID)
		end
	end
end

-------------------------
-- The Update Function --
-------------------------
local function TPerl_TargetTarget_UpdatePVP(self)
	local partyid = self.partyid
	local pvp = self.conf.pvpIcon and ((UnitIsPVPFreeForAll(partyid) and "FFA") or (UnitIsPVP(partyid) and (UnitFactionGroup(partyid) ~= "Neutral") and UnitFactionGroup(partyid)))
	if pvp then
		self.nameFrame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		self.nameFrame.pvpIcon:Show()
	else
		self.nameFrame.pvpIcon:Hide()
	end
end

-- TPerl_TargetTarget_BuffPositions
local function TPerl_TargetTarget_BuffPositions(self)
	if (self.partyid and UnitCanAttack("player", self.partyid)) then
		TPerl_Unit_BuffPositions(self, self.buffFrame.debuff, self.buffFrame.buff, self.conf.debuffs.size, self.conf.buffs.size)
	else
		TPerl_Unit_BuffPositions(self, self.buffFrame.buff, self.buffFrame.debuff, self.conf.buffs.size, self.conf.debuffs.size)
	end
end

-- TPerl_TargetTarget_Buff_UpdateAll
local function TPerl_TargetTarget_Buff_UpdateAll(self)
	if self.conf.buffs.enable then
		self.buffFrame:Show()
	else
		self.buffFrame:Hide()
	end
	if self.conf.debuffs.enable then
		self.debuffFrame:Show()
	else
		self.debuffFrame:Hide()
	end
	if self.conf.buffs.enable or self.conf.debuffs.enable then
		--TPerl_Targets_BuffUpdate(self)
		TPerl_Unit_UpdateBuffs(self, nil, nil, self.conf.buffs.castable, self.conf.debuffs.curable)
		TPerl_TargetTarget_BuffPositions(self)
	end
end

-- TPerl_TargetTarget_RaidIconUpdate
local function TPerl_TargetTarget_RaidIconUpdate(self)
	local frameRaidIcon = self.nameFrame.raidIcon
	local frameNameFrame = self.nameFrame

	TPerl_Update_RaidIcon(frameRaidIcon, self.partyid)

	frameRaidIcon:ClearAllPoints()
	if conf.target.raidIconAlternate then
		frameRaidIcon:SetHeight(16)
		frameRaidIcon:SetWidth(16)
		frameRaidIcon:SetPoint("CENTER", frameNameFrame, "TOPRIGHT", -5, -4)
	else
		frameRaidIcon:SetHeight(32)
		frameRaidIcon:SetWidth(32)
		frameRaidIcon:SetPoint("CENTER", frameNameFrame, "CENTER", 0, 0)
	end
end

-- TPerl_TargetTarget_UpdateDisplay
function TPerl_TargetTarget_UpdateDisplay(self, force)
	local partyid = self.partyid
	if not partyid then
		self.targethp = 0
		self.targethpmax = 0
		self.targetmanatype = 0
		self.targetmana = 0
		self.targetmanamax = 0
		self.afk = false
		self.guid = nil
		return
	end
	--[[if not UnitExists(partyid) then
		self.targethp = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or TPerl_Unit_GetHealth(self))
		self.targetmana = UnitPower(partyid)
		self.guid = UnitGUID(partyid)
		self.afk = UnitIsAFK(partyid)
	end]]
	if self.conf.enable and UnitExists(self.parentid) and UnitIsConnected(partyid) then
		self.targetname = UnitName(partyid)
		if self.targetname then
			local t = GetTime()
			if not force and t < (self.lastUpdate + 0.3) then
				return
			end
			TPerl_Highlight:RemoveHighlight(self)
			self.lastUpdate = t

			TPerl_TargetTarget_UpdatePVP(self)

			-- Save these, so we know whether to update the frame later
			--self.targethp = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or TPerl_Unit_GetHealth(self))
			--self.targethpmax = UnitHealthMax(partyid)
			--self.targetmanatype = UnitPowerType(partyid)
			--self.targetmana = UnitPower(partyid)
			--self.targetmanamax = UnitPowerMax(partyid)
				--self.afk = UnitIsAFK(partyid) and conf.showAFK
				local g = UnitGUID(partyid)
				-- Don't store secret GUIDs; later comparisons in tainted execution would throw.
				self.guid = (not IsRetail or TPerl_TT_CanAccess(g)) and g or nil

			TPerl_SetUnitNameColor(self.nameFrame.text, partyid)

			if self.conf.level then
				local TargetTargetLevel = UnitLevel(partyid)
				local color = GetDifficultyColor(TargetTargetLevel)

				self.levelFrame.text:Show()
				self.levelFrame.skull:Hide()
				if TargetTargetLevel == -1 then
					if UnitClassification(partyid) == "worldboss" then
						TargetTargetLevel = "Boss"
					else
						self.levelFrame.text:Hide()
						self.levelFrame.skull:Show()
					end
				elseif (strfind(UnitClassification(partyid) or "", "elite")) then
					TargetTargetLevel = TargetTargetLevel.."+"
					self.levelFrame:SetWidth(33)
				else
					self.levelFrame:SetWidth(27)
				end

				self.levelFrame.text:SetText(TargetTargetLevel)

				if TargetTargetLevel == "Boss" then
					self.levelFrame:SetWidth(self.levelFrame.text:GetStringWidth() + 6)
					color = {r = 1, g = 0, b = 0}
				end

				self.levelFrame.text:SetTextColor(color.r, color.g, color.b)
			end

			-- Set name - Must do after level as the NameFrame can change size just above here.
			local TargetTargetname = self.targetname
			self.nameFrame.text:SetText(TargetTargetname)

			-- Set health
			TPerl_Target_UpdateHealth(self)

			-- Set mana
			if not self.statsFrame.greyMana then
				TPerl_Target_SetManaType(self)
			end
			TPerl_Target_SetMana(self)

			TPerl_TargetTarget_RaidIconUpdate(self)

			--TPerl_TargetTarget_BuffPositions(self)		-- Moved to option set to save garbage production
			TPerl_TargetTarget_Buff_UpdateAll(self)

			TPerl_UpdateSpellRange(self, partyid)
			TPerl_Highlight:SetHighlight(self, UnitGUID(partyid))
			return
		end
	end

	self.targetname = ""
	TPerl_Highlight:RemoveHighlight(self)
end

-- TPerl_TargetTarget_Update_Control
local function TPerl_TargetTarget_Update_Control(self)
	local partyid = self.partyid
	if UnitIsVisible(partyid) and UnitIsCharmed(partyid) and UnitIsPlayer(self.partyid) and (not IsClassic and not UnitUsingVehicle(partyid) or true) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- TPerl_TargetTarget_Update_Combat
local function TPerl_TargetTarget_Update_Combat(self)
	if UnitAffectingCombat(self.partyid) then
		self.nameFrame.combatIcon:Show()
	else
		self.nameFrame.combatIcon:Hide()
	end
end

-- TPerl_TargetTarget_OnUpdate
function TPerl_TargetTarget_OnUpdate(self, elapsed)
	local partyid = self.partyid

	local newGuid = UnitGUID(partyid)
	local newHP = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or TPerl_Unit_GetHealth(self))
	local newHPMax = UnitHealthMax(partyid)
	local newManaType = UnitPowerType(partyid)
	local newMana = UnitPower(partyid)
	local newManaMax = UnitPowerMax(partyid)
	local newAFK = UnitIsAFK(partyid)
 
	if not IsRetail then
		if (conf.showAFK and newAFK ~= self.afk) or (newHP ~= self.targethp) or (newHPMax ~= self.targethpmax) then
			TPerl_Target_UpdateHealth(self)
		end
	else
		local safeAFK = conf.showAFK and TPerl_TT_SafeBool(newAFK) or false
		if (conf.showAFK and safeAFK ~= self.afk) then
			self.afk = safeAFK
			TPerl_Target_UpdateHealth(self)
		end
		-- Register unit events once for the correct unit token (targettarget/focustarget/pettarget)
		if (not self._retailUnitEvents) then
			self:RegisterUnitEvent("UNIT_HEALTH", partyid)
			self:RegisterUnitEvent("UNIT_MAXHEALTH", partyid)
			self:RegisterUnitEvent("UNIT_POWER_UPDATE", partyid)
			self:RegisterUnitEvent("UNIT_MAXPOWER", partyid)
			self._retailUnitEvents = true
		end
	end

	if (newManaType ~= self.targetmanatype) then
		TPerl_Target_SetManaType(self)
		TPerl_Target_SetMana(self)
	end

	 if not IsRetail then
		if (newMana ~= self.targetmana) or (newManaMax ~= self.targetmanamax) then
			TPerl_Target_SetMana(self)
		end
	end

	--[[if conf.showFD then
		local _, class = UnitClass(partyid)
		if class == "HUNTER" then
			local feigning = UnitBuff(partyid, feignDeath)
			if feigning ~= self.feigning then
				self.feigning = feigning
				TPerl_Target_UpdateHealth(self)
			end
		end
	end--]]

	if (TPerl_TT_GuidChanged(newGuid, self.guid)) then
		TPerl_TargetTarget_UpdateDisplay(self)
	else
		self.time = elapsed + (self.time or 0)
		if self.time >= 0.5 then
			TPerl_TargetTarget_Update_Combat(self)
			TPerl_TargetTarget_Update_Control(self)
			TPerl_TargetTarget_UpdatePVP(self)
			if self.conf.buffs.enable or self.conf.debuffs.enable then
				TPerl_Unit_UpdateBuffs(self, nil, nil, self.conf.buffs.castable, self.conf.debuffs.curable)
				TPerl_TargetTarget_BuffPositions(self)
			end
			--TPerl_TargetTarget_Buff_UpdateAll(self)
			TPerl_SetUnitNameColor(self.nameFrame.text, partyid)
			TPerl_UpdateSpellRange(self, partyid)
			--TPerl_Highlight:SetHighlight(self, UnitGUID(partyid))
			self.time = 0
		end
	end
end

-- TPerl_TargetTargetTarget_OnUpdate
function TPerl_TargetTargetTarget_OnUpdate(self, elapsed)
	local partyid = self.partyid

	local newGuid = UnitGUID(partyid)
	local newHP = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or TPerl_Unit_GetHealth(self))
	local newManaType = UnitPowerType(partyid)
	local newMana = UnitPower(partyid)
	local newAFK = UnitIsAFK(partyid)

	local safeAFK = conf.showAFK and (IsRetail and TPerl_TT_SafeBool(newAFK) or (newAFK and true or false)) or false
	if (conf.showAFK and safeAFK ~= self.afk) or (newHP ~= self.targethp) then
		if (conf.showAFK) then
			self.afk = safeAFK
		end
		TPerl_Target_UpdateHealth(self)
	end

	if (newManaType ~= self.targetmanatype) then
		TPerl_Target_SetManaType(self)
		TPerl_Target_SetMana(self)
	end

	if (newMana ~= self.targetmana) then
		TPerl_Target_SetMana(self)
	end

	--[[if conf.showFD then
		local _, class = UnitClass(partyid)
		if class == "HUNTER" then
			local feigning = UnitBuff(partyid, feignDeath)
			if feigning ~= self.feigning then
				self.feigning = feigning
				TPerl_Target_UpdateHealth(self)
			end
		end
	end--]]

	if (TPerl_TT_GuidChanged(newGuid, self.guid)) then
		TPerl_TargetTarget_UpdateDisplay(self)
	else
		self.time = elapsed + (self.time or 0)
		if self.time >= 0.5 then
			TPerl_TargetTarget_Update_Combat(self)
			TPerl_TargetTarget_Update_Control(self)
			TPerl_TargetTarget_UpdatePVP(self)
			if self.conf.buffs.enable or self.conf.debuffs.enable then
				TPerl_Unit_UpdateBuffs(self, nil, nil, self.conf.buffs.castable, self.conf.debuffs.curable)
				TPerl_TargetTarget_BuffPositions(self)
			end
			--TPerl_TargetTarget_Buff_UpdateAll(self)
			TPerl_SetUnitNameColor(self.nameFrame.text, partyid)
			TPerl_UpdateSpellRange(self, partyid)
			--TPerl_Highlight:SetHighlight(self, UnitGUID(partyid))
			self.time = 0
		end
	end

	--[[if self == TPerl_TargetTargetTarget and newGuid ~= self.guid then
		TPerl_NoFadeBars(true)
		TPerl_TargetTarget_UpdateDisplay(self, true)
		TPerl_NoFadeBars()
		return
	end]]

	--TPerl_TargetTarget_OnUpdate(self, elapsed)
end

-------------------
-- Event Handler --
-------------------
function TPerl_TargetTarget_OnEvent(self, event, unitID, ...)
	if event == "RAID_TARGET_UPDATE" then
		TPerl_TargetTarget_RaidIconUpdate(self)
	elseif event == "PLAYER_TARGET_CHANGED" then
		TPerl_TargetTarget_UpdateDisplay(self, true)
	elseif event == "PLAYER_FOCUS_CHANGED" then
		TPerl_TargetTarget_UpdateDisplay(self, true)
	elseif event == "INCOMING_RESURRECT_CHANGED" then
		TPerl_Target_UpdateResurrectionStatus(self)
	elseif strfind(event, "^UNIT_") then
		if (unitID == "target") and (self == TPerl_TargetTarget or self == TPerl_TargetTargetTarget) then
			TPerl_NoFadeBars(true)
			TPerl_TargetTarget_UpdateDisplay(self, true)
			if TPerl_FocusTarget and TPerl_FocusTarget:IsShown() then
				TPerl_TargetTarget_UpdateDisplay(TPerl_FocusTarget, true)
			end
			TPerl_NoFadeBars()
		elseif unitID == "focus" and self == TPerl_FocusTarget then
			TPerl_NoFadeBars(true)
			TPerl_TargetTarget_UpdateDisplay(self, true)
			TPerl_NoFadeBars()
		elseif unitID == "pet" and self == TPerl_PetTarget then
			TPerl_NoFadeBars(true)
			TPerl_TargetTarget_UpdateDisplay(self, true)
			if TPerl_FocusTarget and TPerl_FocusTarget:IsShown() then
				TPerl_TargetTarget_UpdateDisplay(TPerl_FocusTarget, true)
			end
			TPerl_NoFadeBars()
		end
	elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
  TPerl_Target_UpdateHealth(self)
	elseif (event == "UNIT_MANA" or event == "UNIT_MAXMANA") then
  TPerl_Target_SetMana(self)
	end
end

-- TPerl_TargetTarget_Update
function TPerl_TargetTarget_Update(self)
	local offset = -3
	if self.conf.buffs.enable then
		if UnitExists("targettarget") then
			if TPerl_UnitBuff("targettarget", 1) then
				if (offset == -3) then
					offset = 0
				end
				offset = offset + 20
				local name
				if IsRetail and C_UnitAuras then
					local auraData = TPerl_SafeGetAuraDataByIndex("targettarget", 9, "HELPFUL")
					if auraData then
						name = auraData.name
						if name then
							offset = offset + 20
						end
					end
				else
					name = UnitAura("targettarget", 9, "HELPFUL")
					if name then
						offset = offset + 20
					end
				end
			end
			if TPerl_UnitDebuff("targettarget", 1) then
				if (offset == -3) then
					offset = 0
				end
				offset = offset + 24
			end
		end
	end
end

-- EnableDisable
local function EnableDisable(self)
	if self.conf.enable then
		if not self.virtual then
			RegisterUnitWatch(self)
		end
	else
		UnregisterUnitWatch(self)
		self:Hide()
	end
end

-- TPerl_TargetTarget_SetWidth
function TPerl_TargetTarget_SetWidth(self)

	self.conf.size.width = max(0, self.conf.size.width or 0)
	local bonus = self.conf.size.width

	if self.conf.percent then
		if (not InCombatLockdown()) then
			self:SetWidth(160 + bonus)
			self.nameFrame:SetWidth(160 + bonus)
			self.statsFrame:SetWidth(160 + bonus)
		end
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()
	else
		if (not InCombatLockdown()) then
			self:SetWidth(128 + bonus)
			self.nameFrame:SetWidth(128 + bonus)
			self.statsFrame:SetWidth(128 + bonus)
		end
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
	end

	self.conf.scale = self.conf.scale or 0.8
	if (not InCombatLockdown()) then
		self:SetScale(self.conf.scale)
	end

	TPerl_SavePosition(self, true)

	TPerl_StatsFrameSetup(self)
end

-- Set
local function Set(self)
	if self.conf.level then
		self.levelFrame:Show()
		self.levelFrame:SetWidth(27)
	else
		self.levelFrame:Hide()
	end

	if self.conf.mana then
		self.statsFrame.manaBar:Show()
		self.statsFrame:SetHeight(40)
	else
		self.statsFrame.manaBar:Hide()
		self.statsFrame:SetHeight(30)
	end

	if self.conf.values then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
	else
		self.statsFrame.healthBar.text:Hide()
		self.statsFrame.manaBar.text:Hide()
	end

	self.buffFrame:ClearAllPoints()
	if self.conf.buffs.above then
		self.buffFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 2, 0)
	else
		self.buffFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, 0)
	end
	self.buffOptMix = nil
	self.conf.buffs.size = tonumber(self.conf.buffs.size) or 20

	TPerl_SetBuffSize(self)

	TPerl_TargetTarget_SetWidth(self)

	TPerl_ProtectedCall(EnableDisable, self)

	if self:IsShown() then
		TPerl_TargetTarget_UpdateDisplay(self, true)
	end
end

-- TPerl_TargetTarget_Set_Bits
function TPerl_TargetTarget_Set_Bits()
 --print("Tperl_TargetTarget.lua:668")
	if not TPerl_TargetTarget then
		return
	end

	if conf.targettargettarget.enable then
		if not TPerl_TargetTargetTarget then
			local ttt = CreateFrame("Button", "TPerl_TargetTargetTarget", UIParent, "TPerl_TargetTarget_Template")
			ttt:ClearAllPoints()
			ttt:SetPoint("TOPLEFT", TPerl_TargetTarget.statsFrame, "TOPRIGHT", 5, 0)
		end
	end

	if conf.focustarget.enable then
		if not TPerl_FocusTarget then
			local ft = CreateFrame("Button", "TPerl_FocusTarget", UIParent, "TPerl_TargetTarget_Template")
			ft:ClearAllPoints()
			ft:SetPoint("TOPLEFT", TPerl_Focus.levelFrame, "TOPRIGHT", 5, 0)
		end
	end

	if conf.pettarget.enable and TPerl_Player_Pet then
		if not TPerl_PetTarget then
			local pt = CreateFrame("Button", "TPerl_PetTarget", TPerl_Player_Pet, "TPerl_TargetTarget_Template")
			pt:ClearAllPoints()
			pt:SetPoint("BOTTOMLEFT", TPerl_Player_Pet.statsFrame, "BOTTOMRIGHT", 5, 0)
		end
		if (not InCombatLockdown()) then
			TPerl_PetTarget:Show()
		end
	end

	Set(TPerl_TargetTarget)
	if TPerl_TargetTargetTarget then
		Set(TPerl_TargetTargetTarget)
	end
	if TPerl_FocusTarget then
		Set(TPerl_FocusTarget)
	end
	if TPerl_PetTarget then
		Set(TPerl_PetTarget)
	end
end
