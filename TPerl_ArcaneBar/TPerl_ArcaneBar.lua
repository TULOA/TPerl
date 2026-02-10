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
	local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(self.unit)
	if (not name) then
		name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitChannelInfo(self.unit)
	end
	if (name and endTime > t + 500) then
		return true
	end
end

--------------------------------------------------
--
-- Event/Update Handlers
--
--------------------------------------------------

-- TPerl_ArcaneBar_OnEvent
function TPerl_ArcaneBar_OnEvent(self, event, unit, ...)
	-- Helpers para evitar "secret value" en comparaciones/aritmética
	local function SafeComparable(v)
		-- Queremos algo que podamos comparar con ~= sin petar.
		-- Intentamos convertir a string de forma segura.
		if v == nil then return nil end
		local ok, s = pcall(function() return tostring(v) end)
		if ok then return s end
		return nil
	end

	local function SafeNumber(v)
		-- Devuelve number normal o nil (si secret / no numérico)
		if type(v) ~= "number" then return nil end
		local ok, n = pcall(function() return v * 1 end)
		if ok then return n end
		return nil
	end

	-- Override for showPlayer attribute in party.
	if self.unit == "partyplayer" then
		self.unit = "player"
	end

	if (event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED"
		or event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE") then
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
		local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(self.unit)
		if (not name or (not self.showTradeSkills and isTradeSkill)) then
			self:Hide()
			return
		end

		self:SetStatusBarColor(barColours.main.r, barColours.main.g, barColours.main.b, conf.transparency.frame)

		if not IsRetail then
			if (not IsClassic and notInterruptible) then
				self.spellText:SetText(shield_icon..shield_icon..name:gsub(" %- No Text", "")..shield_icon..shield_icon)
			else
				self.spellText:SetText(name:gsub(" %- No Text", ""))
			end
		else
			self.spellText:SetText(name)
		end

		-- Guardar castID de forma segura (string comparable). Si no, nil.
		self.castID = SafeComparable(castID)

		self.barParentName:Hide()
		self.barSpark:Show()

		-- Guardar tiempos de forma consistente:
		-- No-Retail: segundos (como tenías)
		-- Retail: ms (y OnUpdate se encarga de /1000 con SafeNum)
		if not IsRetail then
			local st = SafeNumber(startTime) or 0
			local et = SafeNumber(endTime) or 0
			self.startTime = st / 1000
			self.maxValue  = et / 1000
		else
			-- Retail: start/end suelen venir en ms; si vienen "secret", no arrancamos la barra
			local st = SafeNumber(startTime)
			local et = SafeNumber(endTime)
			if not st or not et then
				self:Hide()
				return
			end
			self.startTime = st
			self.maxValue  = et
		end

		self:SetMinMaxValues(self.startTime, self.maxValue)
		self:SetValue(self.startTime)
		self:SetAlpha(0.8)
		self.holdTime = 0
		self.casting, self.channeling, self.fadeOut, self.flash = 1, nil, nil, nil
		self:Show()
		self.delaySum = 0
		if (conf.player.castBar.castTime) then
			self.castTimeText:Show()
		else
			self.castTimeText:Hide()
		end

	elseif ((event == "UNIT_SPELLCAST_STOP" and self.casting) or (event == "UNIT_SPELLCAST_CHANNEL_STOP" and self.channeling)) then
		local lineGUID, spellID = ...
		local guid = SafeComparable(lineGUID)

		-- Filtro por castID SOLO si ambos son comparables
		if event == "UNIT_SPELLCAST_STOP" then
			local myCast = SafeComparable(self.castID)
			if myCast and guid and myCast ~= guid then
				return
			end
		end

		if (not ActiveCasting(self)) then
			self.delaySum = 0
			self.sign = "+"
			self.castTimeText:Hide()
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
		local guid = SafeComparable(lineGUID)
		local myCast = SafeComparable(self.castID)

		-- Filtro por castID SOLO si ambos son comparables
		if myCast and guid and myCast ~= guid then
			return
		end

		if (not self.fadeOut and self:IsShown() and not ActiveCasting(self)) then
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
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(self.unit)
			if (not name) then
				name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitChannelInfo(self.unit)
			end
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				self:Hide()
				return
			end
			if (not IsClassic and notInterruptible) then
				self.spellText:SetText(shield_icon..shield_icon..name:gsub(" %- No Text", "")..shield_icon..shield_icon)
			else
				self.spellText:SetText(name:gsub(" %- No Text", ""))
			end

			-- Mantén consistencia con tu lógica original (segundos)
			local st = SafeNumber(startTime) or 0
			local et = SafeNumber(endTime) or 0
			self.startTime = st / 1000
			self.maxValue  = et / 1000
			self:SetMinMaxValues(self.startTime, self.maxValue)
		end

	elseif (event == "UNIT_SPELLCAST_DELAYED") then
		if (self:IsShown()) then
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(self.unit)
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				self:Hide()
				return
			end
			local st = SafeNumber(startTime) or 0
			local et = SafeNumber(endTime) or 0
			self.startTime = st / 1000
			self.maxValue  = et / 1000
			self:SetMinMaxValues(self.startTime, self.maxValue)
		end

	elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(self.unit)
		if (not name or (not self.showTradeSkills and isTradeSkill)) then
			self:Hide()
			return
		end

		self:SetStatusBarColor(barColours.channel.r, barColours.channel.g, barColours.channel.b, conf.transparency.frame)
		self.barSpark:Show()
		self.barParentName:Hide()
		if (not IsClassic and notInterruptible) then
			self.spellText:SetText(shield_icon..shield_icon..name:gsub(" %- No Text", "")..shield_icon..shield_icon)
		else
			self.spellText:SetText(name:gsub(" %- No Text", ""))
		end

		self.maxValue = 1
		local st = SafeNumber(startTime) or 0
		local et = SafeNumber(endTime) or 0
		self.startTime = st / 1000
		self.endTime = et / 1000
		self:SetMinMaxValues(self.startTime, self.endTime)
		self:SetValue(self.endTime)
		self:SetAlpha(1.0)
		self.holdTime = 0
		self.casting, self.channeling, self.fadeOut, self.flash = nil, 1, nil, nil
		self:Show()
		self.delaySum = 0
		if (conf.player.castBar.castTime) then
			self.castTimeText:Show()
		else
			self.castTimeText:Hide()
		end

	elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
		if (self:IsShown()) then
			local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(self.unit)
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				self:Hide()
				return
			end
			local st = SafeNumber(startTime) or 0
			local et = SafeNumber(endTime) or 0
			self.startTime = st / 1000
			self.endTime = et / 1000
			self.maxValue = self.startTime
			self:SetMinMaxValues(self.startTime, self.endTime)
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
	-- Devuelve un número "real" o nil si es secret/invalid
	local function SafeNum(v)
		if type(v) ~= "number" then
			return nil
		end
		local ok, n = pcall(function() return v * 1 end) -- prueba aritmética
		if ok then return n end
		return nil
	end

	local now = GetTime()

	local startTime = SafeNum(self.startTime)
	local maxValue  = SafeNum(self.maxValue)
	local endTime   = SafeNum(self.endTime) or 0
	local holdTime  = SafeNum(self.holdTime) or 0

	-- Si está casteando/canalizando pero no hay tiempos válidos, no calcules nada
	if (self.casting or self.channeling) and (not startTime or not maxValue) then
		return
	end

	-- Retail: convierte ms -> s (solo con números ya validados)
	if IsRetail then
		if startTime then startTime = startTime / 1000 end
		if maxValue  then maxValue  = maxValue  / 1000 end
		endTime = endTime / 1000
	end

	-- (Opcional) guardar normalizados
	if startTime then self.startTime = startTime end
	if maxValue  then self.maxValue  = maxValue  end
	self.endTime = endTime
	self.holdTime = holdTime

	-- Tiempo mostrado
	local current_time
	if self.channeling then
		current_time = endTime - now
	else
		-- recomiendo “restante” en ambos para que tenga sentido
		current_time = (maxValue or 0) - now
	end
	if current_time < 0 then current_time = 0 end
	self.castTimeText:SetText(format("%.1f", current_time))

	if self.casting then
		local status = now
		if status > maxValue then
			status = maxValue
			self.tex:SetTexCoord(0, 1, 0, 1)
			self.casting = nil
			self.barFlash:SetAlpha(0)
			self.barFlash:Show()
			if not self.fadeOut then self.flash = 1 end
			self.holdTime = 0
			self.fadeOut = 1
			return
		end

		local denom = (maxValue - startTime)
		if denom == 0 then denom = 1 end

		local pct = (status - startTime) / denom
		if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end

		self.tex:SetTexCoord(0, pct, 0, 1)
		self:SetValue(status)
		self.barFlash:Hide()

		local sparkPosition = pct * self:GetWidth()
		if sparkPosition < 0 then sparkPosition = 0 end
		self.barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 1)

		ShowPrecast(self, "RIGHT")

	elseif self.channeling then
		local t = now
		if t > endTime then t = endTime end
		if t == endTime then
			self.channeling = nil
			self.barFlash:SetAlpha(0)
			self.barFlash:Show()
			if not self.fadeOut then self.flash = 1 end
			self.holdTime = 0
			self.fadeOut = 1
			return
		end

		local denom = (endTime - startTime)
		if denom == 0 then denom = 1 end

		local barValue = startTime + (endTime - t)
		local pct = (barValue - startTime) / denom
		pct = min(1, max(0, pct))

		self.tex:SetTexCoord(0, pct, 0, 1)
		self:SetValue(barValue)
		self.barFlash:Hide()

		local sparkPosition = pct * self:GetWidth()
		self.barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 1)

		ShowPrecast(self, "LEFT")

	elseif now < holdTime then
		return

	elseif self.flash then
		local alpha = self.barFlash:GetAlpha() + elapsed * 3
		if alpha < 1 then
			self.barFlash:SetAlpha(alpha)
		else
			self.flash = nil
		end

	elseif self.fadeOut then
		local alpha = self:GetAlpha() - elapsed * 2
		if alpha > 0 then
			self:SetAlpha(alpha)
			self.barParentName:SetAlpha((1 - alpha) * conf.transparency.text)
			self.barParentName:Show()
		else
			self.fadeOut = nil
			self:Hide()
		end
	end

	if not self:IsShown() then
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
