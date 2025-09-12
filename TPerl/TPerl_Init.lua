-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local init_done, gradient, conf, doneOptions
local errorCount = 0
TPerl_RequestConfig(function(new)
	conf = new
end, "$Revision:  $")

local _, _, _, clientRevision = GetBuildInfo()

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsCataClassic = WOW_PROJECT_ID == WOW_PROJECT_CATA_CLASSIC
local IsMistsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local _G = _G
local format = format
local geterrorhandler = geterrorhandler
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local max = max
local min = min
local pairs = pairs
local pcall = pcall
local sort = sort
local tinsert = tinsert
local tonumber = tonumber
local type = type
local unpack = unpack

local CreateColor = CreateColor
local CreateFrame = CreateFrame
local DisableAddOn = DisableAddOn
local GetAddOnInfo = GetAddOnInfo
local GetAddOnMetadata = GetAddOnMetadata
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsInRaid = IsInRaid
local UnitAura = UnitAura
local UnitClass = UnitClass
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitName = UnitName

local classOrder
if IsRetail then
	classOrder = {"WARRIOR", "DEATHKNIGHT", "ROGUE", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "PRIEST", "MAGE", "WARLOCK", "MONK", "DEMONHUNTER", "EVOKER"}
elseif IsCataClassic then
	classOrder = {"WARRIOR", "DEATHKNIGHT", "ROGUE", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "PRIEST", "MAGE", "WARLOCK"}
elseif IsMistsClassic then
	classOrder = {"WARRIOR", "DEATHKNIGHT", "ROGUE", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "PRIEST", "MAGE", "WARLOCK", "MONK"}
else
	classOrder = {"WARRIOR", "ROGUE", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "PRIEST", "MAGE", "WARLOCK"}
end

-- SetTexCreateColor
local highlightPositions = {
	{0, 0.25, 0, 0.5},
	{0.25, 0.75, 0, 0.5},
	{0, 1, 0.5, 1},
	{0.75, 1, 0, 0.5}
}

local function SetTex(self, num)
	local p = highlightPositions[num]
	if ((self.GetFrameType or self.GetObjectType)(self) == "Button") then
		if (conf.highlightSelection == 1) then
			self:SetHighlightTexture("Interface\\Addons\\TPerl\\Images\\TPerl_Highlight", "ADD")
			local tex = self:GetHighlightTexture()
			tex:SetTexCoord(unpack(p))
			tex:SetVertexColor(0.86, 0.82, 0.41)
		else
			self:SetHighlightTexture("")
		end

	elseif ((self.GetFrameType or self.GetObjectType)(self) == "Frame") then
		if (self.tex) then
			self.tex:SetTexture("Interface\\Addons\\TPerl\\Images\\TPerl_Highlight", "ADD")
			self.tex:SetTexCoord(unpack(p))
			self.tex:SetVertexColor(0.86, 0.82, 0.41)
			if TPerl_Highlight then
				TPerl_Highlight:SetHighlight(self:GetParent())
			end
		end
	end
end

-- RegisterHighlight
local HighlightFrames = { }
function TPerl_RegisterHighlight(frame, ratio)
	HighlightFrames[frame] = ratio
	if (init_done) then
		SetTex(frame, ratio)
	end
end

-- TPerl_SetHighlights
function TPerl_SetHighlights()
	for k, v in pairs(HighlightFrames) do
		SetTex(k, v)
	end
end

-- TPerl_MakeGradient(self)
function TPerl_DoGradient(self, force)
	if ((force or (conf and conf.colour.gradient.enable)) and not self.tfade) then
		if (gradient) then
			if (not self.gradient) then
				local w = self:GetWidth()
				if (w and w > 10) then
					self.gradient = self:CreateTexture(nil, "ARTWORK")
					self.gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
					self.gradient:SetBlendMode("ADD")

					local bd = self:GetBackdrop()

					if (bd) then
						self.gradient:SetPoint("TOPLEFT", bd.insets.left, -bd.insets.top)
						self.gradient:SetPoint("BOTTOMRIGHT", -bd.insets.right, bd.insets.bottom)
					else
						self.gradient:SetAllPoints()
					end
				end
			end
			if (self.gradient) then
				local orient, r, g, b, a, r2, g2, b2, a2 = unpack(gradient)
				self.gradient:SetGradient(orient, CreateColor(r, g, b, a), CreateColor(r2, g2, b2, a2))
				self.gradient:Show()
			end
			return true
		end
	else
		if (self.gradient) then
			self.gradient:Hide()
		end
	end
end

-- SetupUnitFrame
local function SetupUnitFrame(self)
	self:OnBackdropLoaded()
	self:SetBackdropBorderColor(conf.colour.border.r, conf.colour.border.g, conf.colour.border.b, conf.colour.border.a)
	self:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
	TPerl_DoGradient(self)
end

-- SetupUnitFrameList
local function SetupUnitFrameList(frame, subList)

	if (conf.colour.gradient.enable) then
		local o
		if (conf.colour.gradient.horizontal) then
			o = "HORIZONTAL"
		else
			o = "VERTICAL"
		end

		gradient = {o, conf.colour.gradient.e.r, conf.colour.gradient.e.g, conf.colour.gradient.e.b, conf.colour.gradient.e.a, conf.colour.gradient.s.r, conf.colour.gradient.s.g, conf.colour.gradient.s.b, conf.colour.gradient.s.a}
	end

	if (type(subList) == "table") then
		frame:SetAlpha(conf.transparency.frame)
		for k,v in pairs(subList) do
			SetupUnitFrame(v)
		end
	else
		SetupUnitFrame(frame)
	end
end

-- TPerl_RegisterUnitFrame(frame)
local UnitFrames = {}
function TPerl_RegisterPerlFrames(frame, subList)
	if (not subList) then
		subList = true
	end
	UnitFrames[frame] = subList

	if (init_done) then
		SetupUnitFrameList(frame, subList)
	end
end

-- TPerl_SetupAllPerlFrames
function TPerl_SetupAllPerlFrames(frame)
	for k, v in pairs(UnitFrames) do
		SetupUnitFrameList(k, v)
	end
end

-- TPerl_SetAllFrames
function TPerl_SetAllFrames()
	TPerl_SetupAllPerlFrames()
	TPerl_SetHighlights()
end

-- TPerl_pcall
function TPerl_pcall(...)
	local success, error = pcall(...)
	if (not success) then
		errorCount = errorCount + 1
		if (not doneOptions) then
			TPerl_Notice("Error:"..error)
		end
		geterrorhandler()(error)
	end
end

-- GetNamesWithoutBuff
--[[local matches = {
	--{GetSpellInfo(21562)},				-- Fortitude
	--{GetSpellInfo(1459)},				-- Intellect
	--{GetSpellInfo(1126)},				-- Mark of the Wild
	--{GetSpellInfo(27683)},			-- Shadow Protection
	--{GetSpellInfo(19740)},				-- Blessing of Might
	--{GetSpellInfo(20217)},				-- Blessing of Kings
}]]

--local checkExpiring
local lastNamesList
local lastName
local lastWith
local lastNamesCount
local function GetNamesWithoutBuff(spellName, with, filter)
	if spellName == lastName and with == lastWith and lastNamesList then
		return lastNamesList, lastNamesCount
	end

	local count = 0
	local names
	local unitName

	--[[local _, class = UnitClass("player")

	if (not checkExpiring) then
		local cet = {}

		if (class == "PRIEST" or UnitIsGroupAssistant("player")) then
			--cet[GetSpellInfo(21562)] = 2			-- Fortitudeh
			--cet[GetSpellInfo(27683)] = 2			-- Shadow Protection
		end

		if (class == "DRUID" or UnitIsGroupAssistant("player")) then
			--cet[GetSpellInfo(1126)] = 2				-- Mark of the Wild
			--cet[GetSpellInfo(467)] = 1			-- Thorns
		end

		if (class == "MAGE" or UnitIsGroupAssistant("player")) then
			--cet[GetSpellInfo(1459)] = 2				-- Intellect
		end

		if (class == "PALADIN" or UnitIsGroupAssistant("player")) then
			--cet[GetSpellInfo(19740)] = 2			-- Blessing of Might
			--cet[GetSpellInfo(20217)] = 2			-- Blessing of Kings
		end

		checkExpiring = cet
	end]]

	--local withList = TPerl_GetReusableTable()
	local withList = { }
	for unitid, unitName, unitClass, group, zone, online, dead in TPerl_NextMember do
		local use

		if not conf.buffHelper.visible then
			use = true
		else
			if conf.raid.sortByClass then
				if (conf.raid.class[group].enable) then
					use = unitClass == conf.raid.class[group].name
				end
			else
				use = conf.raid.group[group]
			end
		end

		if unitName and use and online and not dead then
			local hasBuff
			for i = 1, 40 do
				local name, icon, applications, duration, expirationTime, sourceUnit, isStealable
				if not IsVanillaClassic and C_UnitAuras then
					local auraData = C_UnitAuras.GetAuraDataByIndex(unitid, i, filter)
					if auraData then
						name = auraData.name
						icon = auraData.icon
						applications = auraData.applications
						duration = auraData.duration
						expirationTime = auraData.expirationTime
						sourceUnit = auraData.sourceUnit
						isStealable = auraData.isStealable
					end
				else
					local _
					name, icon, applications, _, duration, expirationTime, sourceUnit, isStealable = UnitAura(unitid, i, filter)
				end
				if not name then
					break
				end

				if name == spellName then
					hasBuff = true
				--[[else
					for dups, pair in pairs(matches) do
						if (name == pair[1] or name == pair[2]) then
							if (spellName == pair[1] or spellName == pair[2]) then
								hasBuff = true
								break
							end
						end
					end]]
				end
				--[[if (hasBuff) then
					if (without and checkExpiring) then
						local found = checkExpiring[name]

						if (found) then
							if (endTime and endTime > 0 and endTime <= GetTime() + (found * 60)) then
								GameTooltip:AddLine(format(TPERL_RAID_TOOLTIP_BUFFEXPIRING, TPerlColourTable[unitClass]..name.."|c", buffName, SecondsToTime(endTime - GetTime())), 1, 0.2, 0)
							end
						end
					end
					break
				end--]]
			end

			if (with and hasBuff) or (not with and not hasBuff) then
				count = count + 1

				if conf.buffHelper.sort == "group" then
					if (not withList[group]) then
						--withList[group] = TPerl_GetReusableTable()
						withList[group] = { }
					end
					tinsert(withList[group], {class = unitClass, name = unitName})
				elseif conf.buffHelper.sort == "class" then
					if not withList[unitClass] then
						--withList[unitClass] = TPerl_GetReusableTable()
						withList[unitClass] = { }
					end
					tinsert(withList[unitClass], unitName)
				else
					--local n = TPerl_GetReusableTable()
					local n = { }
					tinsert(withList, n)
					n.class = unitClass
					n.name = unitName
				end
			end
		end
	end

	if conf.buffHelper.sort == "group" then
		for i = 1, 8 do
			local list = withList[i]
			if list then
				sort(list, function(a, b) return a.name < b.name end)

				names = (names or "").."|r"..i..": "
				for i, item in ipairs(list) do
					if item.class and item.class then
						names = names..TPerlColourTable[item.class]..item.name.." "
					end
				end
				names = names.."|r\r"
			end
			--TPerl_FreeTable(list)
		end
	elseif conf.buffHelper.sort == "class" then
		for j, class in ipairs(classOrder) do
			local list = withList[class]
			if list then
				sort(list)

				for i, name in ipairs(list) do
					if i == 1 then
						names = (names or "")..TPerlColourTable[class]
					end
					names = (names or "")..name.." "
				end

				names = (names or "").."|r\r"
			end
			--TPerl_FreeTable(list)
		end
	else
		sort(withList, function(a, b) return a.name < b.name end)
		for i, item in ipairs(withList) do
			names = (names or "")..TPerlColourTable[item.class]..item.name.." "
			--TPerl_FreeTable(item)
		end

		names = (names or "").."\r"
	end

	--TPerl_FreeTable(withList)

	lastNamesList = names
	lastName = spellName
	lastWith = with
	lastNamesCount = count

	return names, count
end

local function UnitFullName(unit)
	local name, realm = UnitName(unit)
	if (name) then
		if (realm and realm ~= "") then
			return name .. "-" .. realm
		else
			return name
		end
	end
end

-- TPerl_ToolTip_AddBuffDuration
local function TPerl_ToolTip_AddBuffDuration(self, partyid, buffID, filter)
	if IsInRaid() or UnitInParty("player") then
		local name, applications, duration, expirationTime, sourceUnit, isStealable
		if not IsVanillaClassic and C_UnitAuras then
			local auraData = C_UnitAuras.GetAuraDataByIndex(partyid, buffID, filter)
			if auraData then
				name = auraData.name
				icon = auraData.icon
				applications = auraData.applications
				duration = auraData.duration
				expirationTime = auraData.expirationTime
				sourceUnit = auraData.sourceUnit
				isStealable = auraData.isStealable
			end
		else
			local _
			name, _, applications, _, duration, expirationTime, sourceUnit, isStealable = UnitAura(partyid, buffID, filter)
		end

		if conf.buffHelper.enable and partyid and (UnitInParty(partyid) or UnitInRaid(partyid)) then
			if name then
				local names, count = GetNamesWithoutBuff(name, IsAltKeyDown(), filter)
				if names then
					if IsAltKeyDown() then
						self:AddLine(format(TPERL_RAID_TOOLTIP_WITHBUFF, count), 0.3, 1, 0.2)
					else
						self:AddLine(format(TPERL_RAID_TOOLTIP_WITHOUTBUFF, count), 1, 0.3, 0.1)
					end

					if conf.buffHelper.sort then
						self:AddLine(names, 0.5, 0.5, 0.5)
					else
						self:AddLine(names, 0.5, 0.5, 0.5, 1)
					end
				end
			end
		end

		if sourceUnit and conf.buffs.names then
			local casterName = UnitFullName(sourceUnit)
			if casterName then
				local c
				if UnitIsPlayer(sourceUnit) then
					local _, class = UnitClass(sourceUnit)
					c = class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
				else
					c = TPerl_ReactionColour(sourceUnit)
				end
				if c then
					self:AddLine(casterName, c.r, c.g, c.b)
				else
					self:AddLine(casterName)
				end
			end
		end
	end


	GameTooltip:Show()
end

-- Buff Tooltip Hook
local function TPerl_GameTooltipSetUnitAura(self, unitId, buffId, filter)
	TPerl_ToolTip_AddBuffDuration(self, unitId, buffId, filter)
end

local function TPerl_GameTooltipSetUnitBuff(self, unitId, buffId)
	TPerl_ToolTip_AddBuffDuration(self, unitId, buffId, "HELPFUL")
end

local function TPerl_GameTooltipSetUnitDebuff(self, unitId, buffId)
	TPerl_ToolTip_AddBuffDuration(self, unitId, buffId, "HARMFUL")
end

-- TPerl_Init()
function TPerl_Init()
	init_done = true
	if GameTooltip.SetUnitAura then
		hooksecurefunc(GameTooltip, "SetUnitAura", TPerl_GameTooltipSetUnitAura)
		hooksecurefunc(GameTooltip, "SetUnitBuff", TPerl_GameTooltipSetUnitBuff)
		hooksecurefunc(GameTooltip, "SetUnitDebuff", TPerl_GameTooltipSetUnitDebuff)
	end

	C_AddOns.DisableAddOn("XPerl_TeamSpeak")

	-- Check for eCastbar and disable old frame if used.
	if eCastingBar_Saved and eCastingBar_Player and eCastingBar_Saved[eCastingBar_Player].Enabled == 1 then
		conf.player.castBar.original = nil
	elseif BCastBar and BCastingBar and BCastBarDragButton then
		conf.player.castBar.original = nil
	end

	local f = CreateFrame("Frame")
	local tx = f:CreateTexture()
	tx:SetPoint("CENTER", WorldFrame)
	tx:SetAlpha(0)
	f:SetAllPoints(tx)
	f:SetScript("OnSizeChanged", function(self, width, height)
		local size = format("%.0f%.0f", width, height)
		if size == "11" then
			conf.bar.texture[1] = "Perl v2"
			conf.bar.texture[2] = "Interface\\AddOns\\TPerl\\Images\\TPerl_StatusBar"
			TPerl_SetBarTextures()
		end
	end)
	tx:SetTexture(conf.bar.texture[2])
	tx:SetSize(0, 0)

	TPerl_pcall(TPerl_OptionActions)

	--PartyMemberFrame:UnregisterEvent("UNIT_NAME_UPDATE")

	if CT_PartyBuffFrame1 then
		if (TPerl_party1) then
			CT_PartyBuffFrame1:Hide()
			CT_PartyBuffFrame2:Hide()
			CT_PartyBuffFrame3:Hide()
			CT_PartyBuffFrame4:Hide()
		end
		if TPerl_Player_Pet then
			CT_PetBuffFrame:Hide()
		end
	end

	if CT_RAMTGroup then
		-- Fix CTRA lockup issues for WoW 2.1
		-- Sure it's not my responsibility, but you can bet your ass I'll get blamed for it's lockups...
		CT_RAMTGroup:UnregisterEvent("UNIT_NAME_UPDATE")
		if CT_RAMTTGroup then
			CT_RAMTTGroup:UnregisterEvent("UNIT_NAME_UPDATE")
		end
		if CT_RAPTGroup then
			CT_RAPTGroup:UnregisterEvent("UNIT_NAME_UPDATE")
		end
		if CT_RAPTTGroup then
			CT_RAPTTGroup:UnregisterEvent("UNIT_NAME_UPDATE")
		end
		if CT_RAGroup1 then
			for i = 1, 8 do
				local f = _G["CT_RAGroup"..i]
				if f then
					f:UnregisterEvent("UNIT_NAME_UPDATE")
				end
			end
		end
	end

	local name, title, notes, enabled = C_AddOns.GetAddOnInfo("SupportFuncs")
	if name and enabled then
		local ver = GetAddOnMetadata and GetAddOnMetadata(name, "Version") or C_AddOns.GetAddOnMetadata(name, "Version")
		if (tonumber(ver) < 20000.2) then
			TPerl_Notice("Out-dated version of SupportFuncs detected. This will break the X-Perl Range Finder by replacing standard Blizzard API functions.")
		end
	end

	name, title, notes, enabled = C_AddOns.GetAddOnInfo("AutoBar")
	if name and enabled then
		local ver = GetAddOnMetadata and GetAddOnMetadata(name, "Version") or C_AddOns.GetAddOnMetadata(name, "Version")
		if (ver < "2.01.00.02") then
			TPerl_Notice("Out-dated version of AutoBar detected. This will taint the Targetting system for all mods that use them, including X-Perl.")
		end
	end

	name, title, notes, enabled = C_AddOns.GetAddOnInfo("TrinityBars")
	if name and enabled then
		local ver = GetAddOnMetadata and GetAddOnMetadata(name, "Version") or C_AddOns.GetAddOnMetadata(name, "Version")
		if (ver <= "20003.14") then
			TPerl_Notice("Out-dated version of TrinityBars detected. This will taint the Targetting system for all mods that use them, including X-Perl.")
		end
	end

	if EarthFeature_AddButton then
		EarthFeature_AddButton ({name = TPerl_ProductName, icon = TPerl_ModMenuIcon, subtext = "by "..TPerl_Author, tooltip = TPerl_LongDescription, callback = TPerl_Toggle})
	end

	if CT_RegisterMod then
		CT_RegisterMod(TPerl_ProductName.." "..TPerl_VersionNumber, "By "..TPerl_Author, 4, TPerl_ModMenuIcon, TPerl_LongDescription, "switch", "", TPerl_Toggle)
	end

	--[[if (myAddOnsFrame) then
		myAddOnsList.TPerl_Description = {
			name			= TPerl_Description,
			description		= TPerl_LongDescription,
			version			= TPerl_VersionNumber,
			category		= MYADDONS_CATEGORY_OTHERS,
			frame			= "TPerl_Globals",
			optionsframe	= "TPerl_Options"
		}
	end--]]

	--TPerl_RegisterSMBarTextures()

	TPerl_pcall(TPerl_DebufHighlightInit)

	TPerl_Init = nil
end

-- TPerl_StatsFrame_Setup
function TPerl_StatsFrameSetup(self, others, offset)
	if (not self) then
		return
	end
	local StatsFrame = self.statsFrame
	if (not StatsFrame) then
		return
	end

	local healthBar = StatsFrame.healthBar
	local healthBarText = healthBar.text
	local healthBarPercent = healthBar.percent
	local manaBar = StatsFrame.manaBar
	local manaBarPercent = manaBar.percent
	local otherBars = {}
	local secondaryBarsShown = 0
	local percentSize = 0
	if (healthBarPercent:IsShown() or manaBarPercent:IsShown()) then
		percentSize = 35
	end

	offset = (offset or 0)

	healthBar:SetWidth(0)

	if (manaBar:IsShown()) then
		secondaryBarsShown = secondaryBarsShown + 1
		manaBar:SetWidth(0)
	end

	local needTicker = 0
	if (StatsFrame.energyTicker) then
		needTicker = 1
	end

	if (others) then
		for i, bar in pairs(others) do
			if (bar) then
				tinsert(otherBars, bar)
				if (bar:IsShown()) then
					secondaryBarsShown = secondaryBarsShown + 1
					bar:SetWidth(0)
				end
			end
		end
	end

	if (conf.bar.fat) then
		if (StatsFrame == TPerl_Player_PetstatsFrame) then
			healthBarText:SetFontObject(GameFontNormalSmall)
		else
			healthBarText:SetFontObject(GameFontNormal)
		end

		local x = 10

		local frameName = self:GetName()
		if frameName == "TPerl_partypet1" or frameName == "TPerl_partypet2" or frameName == "TPerl_partypet3" or frameName == "TPerl_partypet4" or frameName == "TPerl_partypet5" then
			x = 7
		end

		healthBar:ClearAllPoints()
		healthBar:SetPoint("TOPLEFT", 5, -5)
		healthBar:SetPoint("BOTTOMRIGHT", -(5 + percentSize), 5 + needTicker + (secondaryBarsShown * x))

		manaBar:ClearAllPoints()
		manaBar:SetPoint("BOTTOMLEFT", 5, -5 + needTicker + (secondaryBarsShown * 10))
		manaBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)

		local lastBar = manaBar
		local tickerSpace = needTicker * 1.5
		for i,bar in pairs(otherBars) do
			if (bar:IsShown()) then
				bar:ClearAllPoints()

				bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, -tickerSpace)
				bar:SetPoint("BOTTOMRIGHT", lastBar, "BOTTOMRIGHT", 0, -10 - tickerSpace)

				lastBar = bar
				tickerSpace = 0
			end
		end
	else
		healthBarText:SetFontObject(GameFontNormalSmall)

		healthBar:ClearAllPoints()
		healthBar:SetPoint("TOPLEFT", 8, -9 + offset)
		healthBar:SetPoint("BOTTOMRIGHT", StatsFrame, "TOPRIGHT", -(8 + percentSize), -19 + offset)

		manaBar:ClearAllPoints()
		manaBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -2)
		manaBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, -12)

		local lastBar = manaBar
		for i, bar in pairs(otherBars) do
			if (bar:IsShown()) then
				bar:ClearAllPoints()

				bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, -2)
				bar:SetPoint("BOTTOMRIGHT", lastBar, "BOTTOMRIGHT", 0, -12)

				lastBar = bar
			end
		end
	end
end

-- TPerl_RegisterUnitText(self)
local unitText = {}
function TPerl_RegisterUnitText(self)
	tinsert(unitText, self)
end

-- TPerl_SetTextTransparency()
function TPerl_SetTextTransparency()
	local t = conf.transparency.text
	for k, v in pairs(unitText) do
		if (v.GetTextColor) then
			local r, g, b = v:GetTextColor()
			v:SetTextColor(r, g, b, t)
		end
	end
	if TPerl_Player_TargettingFrametext then
		local r, g, b = TPerl_Player_TargettingFrametext:GetTextColor()
		TPerl_Player_TargettingFrametext:SetTextColor(r, g, b, t)
	end
	if TPerl_Target_AssistFrametext then
		local r, g, b = TPerl_Target_AssistFrametext:GetTextColor()
		TPerl_Target_AssistFrametext:SetTextColor(r, g, b, t)
	end
end

-- Set1Bar
local function Set1Bar(bar, tex)
	if (bar.tex) then
		bar.tex:SetTexture(tex)
		bar.tex:SetHorizTile(false)
		bar.tex:SetVertTile(false)
	end
	if (bar.bg) then
		if (conf.bar.background) then
			bar.bg:SetTexture(tex)
		else
			bar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
		end
		bar.bg:SetHorizTile(false)
		bar.bg:SetVertTile(false)
	end
end

-- TPerl_RegisterBar
local TPerlBars = {}
function TPerl_RegisterBar(bar)
	tinsert(TPerlBars, bar)
	if (init_done) then
		local tex = TPerl_GetBarTexture()
		Set1Bar(bar, tex)
	end
end

-- TPerl_SetBarTextures
function TPerl_SetBarTextures()
	local tex = TPerl_GetBarTexture()
	for k, v in pairs(TPerlBars) do
		Set1Bar(v, tex)
	end
end

-- TPerl_RegisterOptionChanger
local optionFuncs = {}
function TPerl_RegisterOptionChanger(f, s)
	tinsert(optionFuncs, {func = f, slf = s})
end

-- TPerl_OptionActions()
function TPerl_OptionActions(which)

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE") -- IMPORTANT! Stops raid framerate lagging when members join/leave/zone

	if (InCombatLockdown()) then
		TPerl_OutOfCombatOptionSet = true
		return
	end

	conf.transparency.frame	= min(max(tonumber(conf.transparency.frame or 1), 0), 1)
	conf.transparency.text	= min(max(tonumber(conf.transparency.text or 1), 0), 1)

	TPerl_pcall(TPerl_SetBarTextures)

	TPerl_pcall(TPerl_SetAllFrames)

	for k, v in pairs(optionFuncs) do
		TPerl_NoFadeBars(true)
		TPerl_pcall(v.func, v.slf, which)
	end
	TPerl_NoFadeBars()

	TPerl_pcall(TPerl_SetTextTransparency)
	doneOptions = true

	-- Avoid tainting default blizzard buffs using cooldown options. Cooldowns won't show immediately atm.
	--[[if (conf.buffs.blizzardCooldowns and BuffFrame and BuffFrame:IsShown()) then
		securecall("BuffFrame_Update")
	end]]
end
