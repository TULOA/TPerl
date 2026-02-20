-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local ArcaneBars = {}
local shield_icon = "|TInterface\\GroupFrame\\UI-Group-MainTankIcon:0:0:0:0|t"

--[===[@debug@
local function d(...)
	ChatFrame1:AddMessage("TPerl: "..format(...))
end
--@end-debug@]===]

local conf
TPerl_RequestConfig(function(new)
	conf = new
end, "$Revision:  $")


local _, _, _, clientRevision = GetBuildInfo()

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsTBCAnni = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local min = min
local max = max
local pairs = pairs
local format = format
local strfind = strfind
local pcall = pcall

local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetNetStats = GetNetStats
local CreateColor = CreateColor
local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local C_Spell_GetSpellName = C_Spell and C_Spell.GetSpellName
local C_Spell_GetSpellInfo = C_Spell and C_Spell.GetSpellInfo
local UNKNOWN_CAST_NAME = UNKNOWN or "???"
local strgsub = string.gsub

-- Midnight/Retail: some UnitCastingInfo/UnitChannelInfo return values can be "secret"
-- (e.g. notInterruptible). Never boolean-test secret values.
local canaccessvalue = canaccessvalue
local issecretvalue = issecretvalue
local function TPerl_AB_CanAccess(v)
	-- Classic branches don't use secret values.
	if (not IsRetail) then
		return v ~= nil
	end
	-- Midnight/Retail: reject secret values explicitly (strings/numbers/booleans).
	if issecretvalue then
		local okS, isSecret = pcall(issecretvalue, v)
		if okS and isSecret then
			return false
		end
	end
	-- Use canaccessvalue (guarded by pcall) as the authoritative check when present.
	if canaccessvalue then
		local ok, res = pcall(canaccessvalue, v)
		return ok and res or false
	end
	return v ~= nil
end


local function TPerl_AB_SafeBool(v)
	if (not IsRetail) then
		return (v and true or false)
	end
	if not TPerl_AB_CanAccess(v) then
		return false
	end
	local ok, res = pcall(function()
		return (v and true or false)
	end)
	return ok and res or false
end


local function TPerl_AB_CastIdMatches(castID, lineGUID)
	-- If we can't safely compare (secret values), we simply don't filter the event.
	if castID == nil then
		return true
	end
	local t = type(castID)
	if t == "number" and castID == 0 then
		return true
	end
	-- Only compare when both ids are accessible *and* lineGUID looks like a string.
	if type(lineGUID) ~= "string" then
		return true
	end
	if not (TPerl_AB_CanAccess(castID) and TPerl_AB_CanAccess(lineGUID)) then
		return true
	end
	return castID == lineGUID
end

local function TPerl_AB_StripNoText(s)
	if not s then
		return nil
	end
	-- Midnight/Retail: never run string operations on secret strings.
	if IsRetail and (not TPerl_AB_CanAccess(s)) then
		return nil
	end
	local ok, out = pcall(strgsub, s, " %- No Text", "")
	return ok and out or nil
end


local function TPerl_AB_SpellNameFromID(spellID)
	if not spellID then
		return nil
	end
	-- In Midnight/Retail, spellID can sometimes be a secret number.
	-- Some APIs may reject secret values; always wrap calls in pcall.
	if C_Spell_GetSpellName then
		local ok, n = pcall(C_Spell_GetSpellName, spellID)
		if ok and n then
			return n
		end
	end
	if GetSpellInfo then
		local ok, n = pcall(GetSpellInfo, spellID)
		if ok and n then
			return n
		end
	end
	return nil
end


local function TPerl_AB_SpellCastTimeFromID(spellID)
	if not spellID then
		return nil
	end
	-- Try the newer Retail API first if present.
	if C_Spell_GetSpellInfo then
		local ok, info = pcall(C_Spell_GetSpellInfo, spellID)
		if ok and info and type(info) == "table" then
			local ct = info.castTime
			if (ct ~= nil) and TPerl_AB_CanAccess(ct) then
				local ok2, gt0 = pcall(function() return ct > 0 end)
				if ok2 and gt0 then
					return ct / 1000
				end
			end
		end
	end
	-- Fallback to the classic-style API.
	if GetSpellInfo then
		local ok, _, _, _, castTimeMS = pcall(GetSpellInfo, spellID)
		if ok and (castTimeMS ~= nil) and TPerl_AB_CanAccess(castTimeMS) then
			local ok2, gt0 = pcall(function() return castTimeMS > 0 end)
			if ok2 and gt0 then
				return castTimeMS / 1000
			end
		end
	end
	return nil
end

local function TPerl_AB_GetCastText(name, text, spellID)
	-- Prefer resolving by spellID first. For hostile units in Midnight/Retail, the
	-- cast name/text may be returned as a secret string and can't be safely manipulated.
	local n = TPerl_AB_SpellNameFromID(spellID)
	if n then
		return TPerl_AB_StripNoText(n) or n
	end
	if name and TPerl_AB_CanAccess(name) then
		return TPerl_AB_StripNoText(name) or name
	end
	if text and TPerl_AB_CanAccess(text) then
		return TPerl_AB_StripNoText(text) or text
	end
	return UNKNOWN_CAST_NAME
end


-- Midnight/Retail: some cast timing values may be returned as secret numbers.
-- Avoid hard-failing the castbar when we can't safely do math or pass those
-- values to StatusBar APIs. Try via pcall; if that fails, show an indeterminate bar.
local function TPerl_AB_ShowIndeterminate(self)
	-- Last resort: unknown duration. Animate in one direction (no bouncing).
	self.indeterminate = true
	self.indeterminatePos = 0
	self.startTime = nil
	self.endTime = nil
	self.maxValue = 1
	pcall(self.SetMinMaxValues, self, 0, 1)
	pcall(self.SetValue, self, 0)
	-- No reliable time values -> hide the time text.
	if self.castTimeText then
		self.castTimeText:Hide()
	end
end

local function TPerl_AB_TrySetEstimatedTimes(self, startTime, endTime, isChannel, spellID)
	-- Use safe (non-secret) time values based on an estimated duration so the bar
	-- can still progress in a single direction.
	local durationSec = nil

	-- Try deriving duration from the API timings without ever comparing them.
	local okD, d = pcall(function()
		return (endTime - startTime) / 1000
	end)
	if okD and d and d > 0 then
		durationSec = d
	end

	-- Fallback to base spell cast time from spellID.
	if not durationSec then
		durationSec = TPerl_AB_SpellCastTimeFromID(spellID)
	end

	-- Final fallback.
	if (not durationSec) or durationSec <= 0 then
		durationSec = (isChannel and 6.0) or 1.5
	end

	local now = GetTime()
	local estStart = now
	local estEnd = now + durationSec

	local ok2 = pcall(function()
		self.startTime = estStart
		if isChannel then
			self.endTime = estEnd
			self.maxValue = estEnd
			self:SetMinMaxValues(estStart, estEnd)
			self:SetValue(estEnd)
		else
			self.maxValue = estEnd
			self:SetMinMaxValues(estStart, estEnd)
			self:SetValue(estStart)
		end
	end)

	if not ok2 then
		return false
	end

	self.indeterminate = nil
	self.estimated = true
	return true
end


local function TPerl_AB_TrySetTimes(self, startTime, endTime, isChannel)
	if not startTime or not endTime then
		return false
	end

	-- First try the real cast times (may fail with secret values in Midnight/Retail).
	local ok, startSec, endSec = pcall(function()
		return (startTime / 1000), (endTime / 1000)
	end)

	if ok and startSec and endSec then
		local ok2 = pcall(function()
			if isChannel then
				self.startTime = startSec
				self.endTime = endSec
				self.maxValue = endSec
				self:SetMinMaxValues(startSec, endSec)
				self:SetValue(endSec)
			else
				self.startTime = startSec
				self.maxValue = endSec
				self:SetMinMaxValues(startSec, endSec)
				self:SetValue(startSec)
			end
		end)

		if ok2 then
			self.indeterminate = nil
			self.estimated = nil
			return true
		end
	end

	-- Fallback: use an estimated duration with safe (non-secret) values so the bar
	-- still progresses in a single direction (no bouncing).
	if TPerl_AB_TrySetEstimatedTimes(self, startTime, endTime, isChannel, self.spellID) then
		return true
	end

	return false
end



local CASTING_BAR_HOLD_TIME = CASTING_BAR_HOLD_TIME
local FAILED = FAILED
local SPELL_FAILED_INTERRUPTED = SPELL_FAILED_INTERRUPTED

-- Registers frame to spellcast events.
local barColours = {
	main = {r = 1.0, g = 0.7, b = 0.0},
	channel = {r = 0.0, g = 1.0, b = 0.0},
	success = {r = 0.0, g = 1.0, b = 0.0},
	failure = {r = 1.0, g = 0.0, b = 0.0}
}

local events = {
	"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP", "PLAYER_ENTERING_WORLD"
}

-- enableToggle
local function enableToggle(self, value)
	if (value) then
		if (not self.Enabled) then
			local CastbarEventHandler = function(event, ...)
				return TPerl_ArcaneBar_OnEvent(self, event, ...)
			end
			for i, event in pairs(events) do
				if pcall(self.RegisterEvent, self, event) then
					self:RegisterEvent(event)
				end
			end

			self:SetScript("OnUpdate", TPerl_ArcaneBar_OnUpdate)
			if (self.unit == "target") then
				self:RegisterEvent("PLAYER_TARGET_CHANGED")
			elseif (self.unit == "focus") then
				if not IsVanillaClassic then
					self:RegisterEvent("PLAYER_FOCUS_CHANGED")
				end
			elseif (strfind(self.unit, "^party")) then
				self:RegisterEvent("PARTY_MEMBER_ENABLE")
				self:RegisterEvent("PARTY_MEMBER_DISABLE")
			end
			self.Enabled = 1
		end
	else
		if (self.Enabled) then
			self:UnregisterAllEvents()
			self:SetScript("OnUpdate", nil)
			self.Enabled = nil
			self:Hide()
		end
	end
end

-- overrideToggle
local function overrideToggle(value)
	local pconf = ArcaneBars.player
	if (pconf) then
		if (value) then
			if (pconf.bar.Overrided) then
				local CastbarEventHandler = function(event, ...)
					return TPerl_ArcaneBar_OnEvent(CastingBarFrame, event, ...)
				end
				for i, event in pairs(events) do
					if IsRetail or IsTBCAnni then
						PlayerCastingBarFrame:RegisterEvent(event)
					else
						if event ~= "UNIT_SPELLCAST_INTERRUPTIBLE" and event ~= "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
							CastingBarFrame:RegisterEvent(event)
						end
					end
				end
				pconf.bar.Overrided = nil
			end
		else
			if (not pconf.bar.Overrided) then
				if IsRetail or IsTBCAnni then
					PlayerCastingBarFrame:Hide()
					PlayerCastingBarFrame:UnregisterAllEvents()
				else
					CastingBarFrame:Hide()
					CastingBarFrame:UnregisterAllEvents()
				end
				pconf.bar.Overrided = 1
			end
		end
	end
end

-- ActiveCasting
-- See if we're probably still casting a spell, even though some other spell END event occured
local function ActiveCasting(self)
	local t = GetTime() * 1000
	local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(self.unit)
	if (not name) then
		name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitChannelInfo(self.unit)
	end
	if (name) then
		-- endTime can be a secret value in Midnight; avoid comparing secret numbers.
		if (endTime and not TPerl_AB_CanAccess(endTime)) then
			return true
		end
		if (endTime) then
			local ok, res = pcall(function()
				return endTime > t + 500
			end)
			if ok and res then
				return true
			end
		end
	end
end

--------------------------------------------------
--
-- Event/Update Handlers
--
--------------------------------------------------

-- TPerl_ArcaneBar_OnEvent
function TPerl_ArcaneBar_OnEvent(self, event, unit, ...)
	-- Override for showPlayer attribute in party.
	if self.unit == "partyplayer" then
		self.unit = "player"
	end

	if (event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE") then
		local nameChannel = UnitChannelInfo(self.unit)
		local nameSpell = UnitCastingInfo(self.unit)
		if nameChannel then
			event = "UNIT_SPELLCAST_CHANNEL_START"
			unit = self.unit
		elseif (nameSpell) then
			event = "UNIT_SPELLCAST_START"
			unit = self.unit
		else
			self:Hide()
			self.castTimeText:Hide()
			self.barParentName:SetAlpha(conf.transparency.text)
			self.barParentName:Show()
			return
		end
	end

	if (unit ~= self.unit) then
		return
	end

	if (event == "UNIT_SPELLCAST_START") then
		-- In Retail, the event payload contains (castGUID, spellID).
		-- This is often more reliable than UnitCastingInfo() when the cast name
		-- is returned as a secret string.
		local _, eventSpellID = ...
		local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(self.unit)
		if (not name or (not self.showTradeSkills and isTradeSkill)) then
			self:Hide()
			return
		end
		-- Prefer an accessible spellID, falling back to the event spellID.
		local sid = spellID
		if (not sid or (canaccessvalue and not TPerl_AB_CanAccess(sid))) then
			sid = eventSpellID
		end
		self.spellID = sid
		self.estimated = nil

		self:SetStatusBarColor(barColours.main.r, barColours.main.g, barColours.main.b, conf.transparency.frame)
		local displayName = TPerl_AB_GetCastText(name, text, sid)
		if (not IsClassic and TPerl_AB_SafeBool(notInterruptible)) then
			self.spellText:SetText(shield_icon..shield_icon..displayName..shield_icon..shield_icon)
		else
			self.spellText:SetText(displayName)
		end
		self.castID = castID
		self.barParentName:Hide()
		self.barSpark:Show()
		if (not startTime or not endTime) then
			-- Midnight/Retail: some channel casts may not provide usable timing info (or values may be blocked/secret).
			-- Try to estimate a duration from spellID so we can still show a progressing bar (one direction).
			if IsRetail then
				local dur = TPerl_AB_SpellCastTimeFromID(sid)
				-- If we can't read a real duration, use a sensible default for channels.
				if (not dur) or dur <= 0 then
					dur = 6.0
				end
				local now = GetTime()
				self.indeterminate = nil
				self.estimated = true
				self.startTime = now
				self.endTime = now + dur
				self.maxValue = self.endTime
				pcall(self.SetMinMaxValues, self, self.startTime, self.endTime)
				pcall(self.SetValue, self, self.endTime)
				self:SetAlpha(1.0)
				self.holdTime = 0
				self.casting, self.channeling, self.fadeOut, self.flash = nil, 1, nil, nil
				self:Show()
				self.delaySum = 0
				if (conf.player.castBar.castTime and not self.indeterminate) then
					self.castTimeText:Show()
				else
					self.castTimeText:Hide()
				end
			else
				self:Hide()
			end
			return
		end
		if (not TPerl_AB_TrySetTimes(self, startTime, endTime, false)) then
			TPerl_AB_ShowIndeterminate(self)
		end
		self:SetAlpha(0.8)
		self.holdTime = 0
		self.casting, self.channeling, self.fadeOut, self.flash = 1, nil, nil, nil
		self:Show()
		self.delaySum = 0
		if (conf.player.castBar.castTime and not self.indeterminate) then
			self.castTimeText:Show()
		else
			self.castTimeText:Hide()
		end
	elseif ((event == "UNIT_SPELLCAST_STOP" and self.casting) or (event == "UNIT_SPELLCAST_CHANNEL_STOP" and self.channeling)) then
		local lineGUID, spellID = ...
		if event == "UNIT_SPELLCAST_STOP" and not TPerl_AB_CastIdMatches(self.castID, lineGUID) then
			return
		end
		if (not ActiveCasting(self)) then
			self.indeterminate = nil
			self.estimated = nil
			self.delaySum = 0
			self.sign = "+"
			self.castTimeText:Hide()
			self.spellID = nil
			if (not self:IsVisible()) then
				self:Hide()
			end
			if (self:IsShown()) then
				self:SetValue(self.maxValue)
				self:SetStatusBarColor(barColours.success.r, barColours.success.g, barColours.success.b, conf.transparency.frame)
				self.barSpark:Hide()
				self.barFlash:SetAlpha(0)
				self.barFlash:Show()
				self.casting = nil
				self.channeling = nil
				if (not self.fadeOut or event == "UNIT_SPELLCAST_CHANNEL_STOP") then
					self.flash = 1
				end
				self.fadeOut = 1
				self.holdTime = 0
			end
		end
	elseif (event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED") then
		local lineGUID, spellID = ...
		if not TPerl_AB_CastIdMatches(self.castID, lineGUID) then
			return
		end
		if (not self.fadeOut and self:IsShown() and not ActiveCasting(self)) then
			self.indeterminate = nil
			self.estimated = nil
			self.spellID = nil
			if (event == "UNIT_SPELLCAST_FAILED") then
				self.spellText:SetText(FAILED)
			else
				self.spellText:SetText(SPELL_FAILED_INTERRUPTED)
			end

			self:SetValue(self.maxValue)
			self:SetStatusBarColor(barColours.failure.r, barColours.failure.g, barColours.failure.b, conf.transparency.frame)
			self.barSpark:Hide()
			self.casting = nil
			self.channeling = nil
			if (not self.fadeOut) then
				self.flash = 1
			end
			self.fadeOut = 1
			self.holdTime = GetTime() + (CASTING_BAR_HOLD_TIME or 1)
		end
	elseif (event == "UNIT_SPELLCAST_INTERRUPTIBLE") or (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then
		if (self:IsShown()) then
			local _, eventSpellID = ...
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(self.unit)
			if (not name) then
				name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitChannelInfo(self.unit)
			end
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				self:Hide()
				return
			end
			local sid = spellID
			if (not sid or (canaccessvalue and not TPerl_AB_CanAccess(sid))) then
				sid = self.spellID or eventSpellID
			end
			self.spellID = sid
			self.estimated = nil
			local displayName = TPerl_AB_GetCastText(name, text, sid)
			if (not IsClassic and TPerl_AB_SafeBool(notInterruptible)) then
				self.spellText:SetText(shield_icon..shield_icon..displayName..shield_icon..shield_icon)
			else
				self.spellText:SetText(displayName)
			end
			if (not startTime or not endTime) then
				self:Hide()
				return
			end
			if (not TPerl_AB_TrySetTimes(self, startTime, endTime, self.channeling)) then
				TPerl_AB_ShowIndeterminate(self)
			end
		end
	elseif (event == "UNIT_SPELLCAST_DELAYED") then
		if (self:IsShown()) then
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(self.unit)
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				self:Hide()
				return
			end
			if (not startTime or not endTime) then
				self:Hide()
				return
			end
			if (not TPerl_AB_TrySetTimes(self, startTime, endTime, false)) then
				TPerl_AB_ShowIndeterminate(self)
			end
		end
	elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
		local _, eventSpellID = ...
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(self.unit)
		if (not name or (not self.showTradeSkills and isTradeSkill)) then
			-- if there is no name, there is no bar
			self:Hide()
			return
		end
		local sid = spellID
		if (not sid or (canaccessvalue and not TPerl_AB_CanAccess(sid))) then
			sid = eventSpellID
		end
		self.spellID = sid
		self.estimated = nil

		self:SetStatusBarColor(barColours.channel.r, barColours.channel.g, barColours.channel.b, conf.transparency.frame)
		self.barSpark:Show()
		self.barParentName:Hide()
		local displayName = TPerl_AB_GetCastText(name, text, sid)
		if (not IsClassic and TPerl_AB_SafeBool(notInterruptible)) then
			self.spellText:SetText(shield_icon..shield_icon..displayName..shield_icon..shield_icon)
		else
			self.spellText:SetText(displayName)
		end
		self.maxValue = 1
		if (not startTime or not endTime) then
			-- Midnight/Retail: channels may not provide usable timing info (or values may be blocked/secret).
			-- Keep the bar visible in indeterminate mode until CHANNEL_STOP.
			if IsRetail then
				TPerl_AB_ShowIndeterminate(self)
				self:SetAlpha(1.0)
				self.holdTime = 0
				self.casting, self.channeling, self.fadeOut, self.flash = nil, 1, nil, nil
				self:Show()
				self.delaySum = 0
				self.castTimeText:Hide()
			else
				self:Hide()
			end
			return
		end
		if (not TPerl_AB_TrySetTimes(self, startTime, endTime, true)) then
			TPerl_AB_ShowIndeterminate(self)
		end
		self:SetAlpha(1.0)
		self.holdTime = 0
		self.casting, self.channeling, self.fadeOut, self.flash = nil, 1, nil, nil
		self:Show()
		self.delaySum = 0
		if (conf.player.castBar.castTime and not self.indeterminate) then
			self.castTimeText:Show()
		else
			self.castTimeText:Hide()
		end
	elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
		if (self:IsShown()) then
			local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(self.unit)
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				self:Hide()
				return
			end
			if (not startTime or not endTime) then
				-- Midnight/Retail: channels may omit usable timing values. Estimate a duration so the bar can still progress.
				if IsRetail then
					if self.estimated then
						-- Keep the estimated bar running; wait for CHANNEL_STOP.
						return
					end
					local sid = self.spellID or spellID
					local dur = TPerl_AB_SpellCastTimeFromID(sid)
					if (not dur) or dur <= 0 then
						dur = 6.0
					end
					local now = GetTime()
					self.indeterminate = nil
					self.estimated = true
					self.startTime = now
					self.endTime = now + dur
					self.maxValue = self.endTime
					pcall(self.SetMinMaxValues, self, self.startTime, self.endTime)
					pcall(self.SetValue, self, self.endTime)
					if (conf.player.castBar.castTime and not self.indeterminate) then
						self.castTimeText:Show()
					else
						self.castTimeText:Hide()
					end
					return
				end
				self:Hide()
				return
			end
			if (not TPerl_AB_TrySetTimes(self, startTime, endTime, true)) then
				-- If we can't use API timings, fall back to an estimated duration.
				if IsRetail then
					local sid = self.spellID or spellID
					local dur = TPerl_AB_SpellCastTimeFromID(sid)
					if (not dur) or dur <= 0 then
						dur = 6.0
					end
					local now = GetTime()
					self.indeterminate = nil
					self.estimated = true
					self.startTime = now
					self.endTime = now + dur
					self.maxValue = self.endTime
					pcall(self.SetMinMaxValues, self, self.startTime, self.endTime)
					pcall(self.SetValue, self, self.endTime)
				else
					TPerl_AB_ShowIndeterminate(self)
				end
			end
		end
	end

	if (not self:IsShown()) then
		self.castTimeText:Hide()
		self.barParentName:SetAlpha(conf.transparency.text)
		self.barParentName:Show()
	end
end

local function ShowPrecast(self, side)
	if (self.precast) then
		if (conf.player.castBar.precast) then
			local _, _, _, latencyWorld = GetNetStats()
			local lag = min(1000, latencyWorld)
			if (lag < 10) then
				self.precast:Hide()
			else
				local total = self.maxValue - self.startTime
				if total == 0 then
					total = 1.5
				end
				local width = self:GetWidth() / ((total * 1000) / lag)

				self.precast:ClearAllPoints()
				self.precast:SetPoint(side)
				self.precast:SetWidth(width)
				self.precast:SetHeight(self:GetHeight())
				self.precast:Show()
			end
		else
			self.precast:Hide()
		end
	end
end

-- TPerl_ArcaneBar_OnUpdate
function TPerl_ArcaneBar_OnUpdate(self, elapsed)
	local getTime = GetTime()

	-- Indeterminate mode (Retail/Midnight secret cast times): animate the bar
	-- without relying on start/end time values.
	if (self.indeterminate and (self.casting or self.channeling)) then
		local pos = (self.indeterminatePos or 0) + (elapsed * 0.9)
		if (pos > 1) then
			pos = 0
		end
		self.indeterminatePos = pos
		pcall(self.SetMinMaxValues, self, 0, 1)
		pcall(self.SetValue, self, pos)
		if self.tex then
			pcall(self.tex.SetTexCoord, self.tex, 0, pos, 0, 1)
		end
		if self.barSpark then
			local sparkPosition = pos * self:GetWidth()
			pcall(self.barSpark.SetPoint, self.barSpark, "CENTER", self, "LEFT", sparkPosition, 1)
		end
		return
	end
	local current_time = self.maxValue - getTime
	if (self.channeling) then
		current_time = self.endTime - getTime
	end
	if (current_time < 0) then
		current_time = 0
	end
	local text = format("%.1f", current_time)

	self.castTimeText:SetText(text)

	if (self.casting) then
		local status = getTime
		if (status > self.maxValue) then
			status = self.maxValue
			self.tex:SetTexCoord(0, 1, 0, 1)
			self:SetValue(status)
			self.barFlash:Hide()
			-- If we're using estimated timings, don't auto-complete the castbar.
			-- Wait for UNIT_SPELLCAST_STOP instead.
			if self.estimated then
				if self.barSpark then
					self.barSpark:Hide()
				end
				return
			end
			self.casting = nil
			self.barFlash:SetAlpha(0)
			self.barFlash:Show()
			if (not self.fadeOut) then
				self.flash = 1
			end
			self.holdTime = 0
			self.fadeOut = 1
			return
		end

		self.tex:SetTexCoord(0, (status - self.startTime) / (self.maxValue - self.startTime), 0, 1)
		self:SetValue(status)
		self.barFlash:Hide()

		local sparkPosition = ((status - self.startTime) / (self.maxValue - self.startTime)) * self:GetWidth()
		if (sparkPosition < 0) then
			sparkPosition = 0
		end
		self.barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 1)

		ShowPrecast(self, "RIGHT")
	elseif (self.channeling) then
		local time = getTime
		if (time > self.endTime) then
			time = self.endTime
		end
		if (time == self.endTime) then
			-- If we're using estimated timings, don't auto-complete the channel bar.
			-- Wait for UNIT_SPELLCAST_CHANNEL_STOP instead.
			if self.estimated then
				local barValue = self.startTime
				self.tex:SetTexCoord(0, 0, 0, 1)
				self:SetValue(barValue)
				self.barFlash:Hide()
				if self.barSpark then
					self.barSpark:Hide()
				end
				return
			end
			self.channeling = nil
			self.barFlash:SetAlpha(0)
			self.barFlash:Show()
			if (not self.fadeOut) then
				self.flash = 1
			end
			self.holdTime = 0
			self.fadeOut = 1
			return
		end
		local barValue = self.startTime + (self.endTime - time)
		self.tex:SetTexCoord(0, min(1, max(0, (barValue - self.startTime) / (self.endTime - self.startTime))), 0, 1)
		self:SetValue( barValue )
		self.barFlash:Hide()

		local sparkPosition = ((barValue - self.startTime) / (self.endTime - self.startTime)) * self:GetWidth()
		self.barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 1)

		ShowPrecast(self, "LEFT")
	elseif (getTime < self.holdTime) then
		return
	elseif (self.flash) then
		local alpha = self.barFlash:GetAlpha() + elapsed * 3	-- CASTING_BAR_FLASH_STEP
		if (alpha < 1) then
			self.barFlash:SetAlpha(alpha)
		else
			self.flash = nil
		end
	elseif (self.fadeOut) then
		local alpha = self:GetAlpha() - elapsed * 2			-- CASTING_BAR_ALPHA_STEP
		if (alpha > 0) then
			self:SetAlpha(alpha)
			self.barParentName:SetAlpha((1 - alpha) * conf.transparency.text)
			self.barParentName:Show()
		else
			self.fadeOut = nil
			self:Hide()
		end
	end

	if (not self:IsShown()) then
		self.castTimeText:Hide()
		self.barParentName:SetAlpha(conf.transparency.text)
		self.barParentName:Show()
	end
end

-- TPerl_ArcaneBar_OnLoad
function TPerl_ArcaneBar_OnLoad(self)
	TPerl_SetChildMembers(self)

	self.barFlash.tex:SetTexture("Interface\\AddOns\\TPerl\\Images\\TPerl_ArcaneBarFlash")
	self.tex:SetTexture("Interface\\AddOns\\TPerl\\Images\\TPerl_StatusBar")
	self.tex:SetHorizTile(false)
	self.tex:SetVertTile(false)

	self.casting = nil
	self.holdTime = 0

	TPerl_RegisterBar(self)
end

-- TPerl_ArcaneBar_Set
function TPerl_ArcaneBar_Set()
	--print("TPerl_ArcaneBar.lua:477")
	if (conf) then
		for k, v in pairs(ArcaneBars) do
			if (v.optFrame and v.optFrame.conf and v.optFrame.conf.castBar) then
				enableToggle(v.bar, v.optFrame.conf.castBar.enable)

				v.bar.castTimeText:ClearAllPoints()
				--if (v.optFrame.conf.castBar.inside) then
				if (conf.player.castBar.inside) then
					v.bar.castTimeText:SetPoint("RIGHT", v.bar, "RIGHT", -2, 0)
					v.bar.castTimeText:SetJustifyH("RIGHT")
				else
					v.bar.castTimeText:SetPoint("LEFT", v.bar, "RIGHT", 2, 0)
					v.bar.castTimeText:SetJustifyH("LEFT")
				end
			end
		end

		overrideToggle(conf.player.castBar.original)
	end
end

-- SetArcaneBar
local function SetArcaneBar(value, new)
	for k, v in pairs(ArcaneBars) do
		if (v.bar == new.bar) then
			ArcaneBars[k] = nil
		end
	end

	ArcaneBars[value] = new
end

-- TPerl_MakePreCast
local function TPerl_MakePreCast(self)
	local tex = TPerl_GetBarTexture()
	self.precast = self:CreateTexture(nil, "ARTWORK")
	self.precast:SetTexture(tex)
	self.precast:SetPoint("RIGHT")
	self.precast:SetWidth(1)
	self.precast:Hide()
	self.precast:SetBlendMode("ADD")
	self.precast:SetGradient("HORIZONTAL", CreateColor(0, 0, 1, 1), CreateColor(1, 0, 0, 1))
end

-- TPerl_ArcaneBar_RegisterFrame
function TPerl_ArcaneBar_RegisterFrame(self, unit)
	local f = self.castBar
	if (not f) then
		f = CreateFrame("StatusBar", self:GetName().."CastBar", self, "TPerl_ArcaneBarTemplate")
		self.castBar = f
	end

	if (unit == "player") then
		TPerl_MakePreCast(f)
	end

	f.unit = unit
	f.showTradeSkills = true
	f.barParentName = self.text
	f:SetPoint("TOPLEFT", 4, -4)
	f:SetPoint("BOTTOMRIGHT", -4, 4)

	SetArcaneBar(unit, {bar = f, optFrame = self:GetParent()})

	TPerl_ArcaneBar_Set()
end

-- TPerl_ArcaneBar_SetUnit
function TPerl_ArcaneBar_SetUnit(self, unit)
	if (self.castBar) then
		self.castBar.unit = unit
	end
end

TPerl_RegisterOptionChanger(TPerl_ArcaneBar_Set, nil, "TPerl_ArcaneBar_Set")
