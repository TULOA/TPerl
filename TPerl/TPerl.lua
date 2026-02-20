-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 18 October 2014

local conf
local percD	= "%d"..PERCENT_SYMBOL
local perc1F = "%.1f"..PERCENT_SYMBOL
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

TPerl_RequestConfig(function(New)
	conf = New
end, "$Revision: " .. GetAddOnMetadata("TPerl", "X-Revision") .. " $")
TPerl_SetModuleRevision("$Revision: " .. GetAddOnMetadata("TPerl", "X-Revision") .. " $")

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsTBCAnni = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local IsCataClassic = WOW_PROJECT_ID == WOW_PROJECT_CATA_CLASSIC
local IsMistsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

local UnitAuraWithBuffs
local LCD = IsVanillaClassic and LibStub and LibStub("LibClassicDurations", true)
if LCD then
	LCD:Register("TPerl")
	UnitAuraWithBuffs = LCD.UnitAuraWithBuffs
end
local HealComm = IsVanillaClassic and LibStub and LibStub("LibHealComm-4.0", true)

-- Upvalues
local _G = _G
local abs = abs
local atan2 = math.atan2
local collectgarbage = collectgarbage
local cos = cos
local deg = math.deg
local error = error
local floor = floor
local format = format
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local max = max
local min = min
local next = next
local pairs = pairs
local print = print
local select = select
local setmetatable = setmetatable
local sin = sin
local string = string
local strmatch = strmatch
local strsub = strsub
local strupper = strupper
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local type = type
local unpack = unpack

local CheckInteractDistance = CheckInteractDistance
local CreateFrame = CreateFrame
local DebuffTypeColor = _G.DebuffTypeColor or DebuffTypeColor or {}

-- Midnight "secret value" helpers (safe across versions)
local canaccessvalue = canaccessvalue
local issecretvalue = issecretvalue

local function TPerl_CanAccess(v)
	if v == nil then
		return false
	end
	-- In Midnight/Retail, values may be "secret" and cannot be compared/indexed in tainted code.
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

local function TPerl_SafeBool(v)
	-- Convert possibly-secret booleans into a safe Lua boolean.
	-- In Midnight/Retail, a 'secret boolean' can throw if used directly in a boolean test.
	if (not TPerl_CanAccess(v)) then
		return false
	end
	local ok, res = pcall(function()
		return (v and true or false)
	end)
	return ok and res or false
end

-- Debuff type colors: Blizzard usually provides DebuffTypeColor, but Midnight/Retail may not populate it early.
-- Provide safe defaults so dispellable debuff highlighting never crashes.
local TPerl_DefaultDebuffTypeColor = {
	Magic	= { r = 0.2, g = 0.6, b = 1.0, a = 1 },
	Curse	= { r = 0.6, g = 0.0, b = 1.0, a = 1 },
	Disease	= { r = 0.6, g = 0.4, b = 0.0, a = 1 },
	Poison	= { r = 0.0, g = 0.6, b = 0.0, a = 1 },
	none	= { r = 0.8, g = 0.0, b = 0.0, a = 1 },
}

local function TPerl_GetDebuffTypeColorSafe(debuffType)
	-- debuffType is typically one of: Magic, Curse, Disease, Poison, none
	local dt = debuffType
	if (dt and TPerl_CanAccess(dt)) then
		local tbl = _G.DebuffTypeColor
		if (type(tbl) == "table") then
			local c = tbl[dt] or tbl.none or tbl["none"]
			if (type(c) == "table" and c.r and c.g and c.b) then
				-- Avoid nil alpha, some clients omit it.
				if (c.a == nil) then
					c.a = 1
				end
				return c
			end
		end
		return TPerl_DefaultDebuffTypeColor[dt] or TPerl_DefaultDebuffTypeColor.none
	end
	return TPerl_DefaultDebuffTypeColor.none
end

-- Normalize dispel/debuff types across clients (Retail/Midnight/Classic/private).
-- Some clients return upper-case or localized strings; normalize them to Blizzard's canonical keys.
local function TPerl_NormalizeDispelType(dt)
	if (dt == nil) then
		return nil
	end

	-- Numeric codes (rare; some custom clients)
	if (type(dt) == "number") then
		if (dt == 1) then
			return "Magic"
		elseif (dt == 2) then
			return "Curse"
		elseif (dt == 3) then
			return "Disease"
		elseif (dt == 4) then
			return "Poison"
		end
		return nil
	end

	if (type(dt) ~= "string") then
		-- Could be a "secret string" userdata in Midnight; don't touch it.
		if (TPerl_CanAccess(dt)) then
			-- If it's accessible and tostring works, keep it.
			local ok, s = pcall(tostring, dt)
			return ok and s or nil
		end
		return nil
	end

	-- Avoid operating on secret strings.
	if (not TPerl_CanAccess(dt)) then
		return nil
	end

	local ok, low = pcall(string.lower, dt)
	if (not ok or not low) then
		return dt
	end

	-- English
	if (low == "magic") then return "Magic" end
	if (low == "curse") then return "Curse" end
	if (low == "disease") then return "Disease" end
	if (low == "poison") then return "Poison" end
	if (low == "none") then return "none" end

	-- Spanish (just in case a custom client localizes dispel types)
	if (low == "magia") then return "Magic" end
	if (low == "maldicion" or low == "maldición") then return "Curse" end
	if (low == "enfermedad") then return "Disease" end
	if (low == "veneno") then return "Poison" end
	if (low == "ninguno") then return "none" end

	-- Upper-case constants
	if (low == "magic" or low == "magic") then return "Magic" end

	-- Unknown string: return as-is (colour lookup will fall back to "none")
	return dt
end





-- Debuff-type fallback for clients that return secret dispel types.
-- Some Midnight/Retail servers return (name/dispelType) as secret values for UnitAura/C_UnitAuras,
-- but the GameTooltip still exposes the dispel type as plain text ("Magic"/"Poison"/etc).
-- We scan the tooltip only when needed and cache results by spellId.
TPerl_DispelTypeCache = TPerl_DispelTypeCache or {}

function TPerl_SafeSpellIdKey(spellId)
	if (spellId == nil) then
		return nil
	end
	if (not TPerl_CanAccess(spellId)) then
		return nil
	end
	if (type(spellId) == "number") then
		return spellId
	end
	local ok, n = pcall(tonumber, spellId)
	if (ok and type(n) == "number") then
		return n
	end
	return nil
end


function TPerl_GetCachedDispelType(spellId)
	local key = TPerl_SafeSpellIdKey(spellId)
	if (not key) then
		return nil
	end
	local e = TPerl_DispelTypeCache[key]
	if (e and e.dt) then
		-- 24h TTL to keep the cache bounded but stable
		if (not e.ts) then
			return e.dt, e.name
		end
		if (GetTime() - e.ts) < 86400 then
			return e.dt, e.name
		end
		TPerl_DispelTypeCache[key] = nil
	end
	return nil
end

function TPerl_SetCachedDispelType(spellId, dt, name)
	local key = TPerl_SafeSpellIdKey(spellId)
	if (not key or not dt) then
		return
	end
	TPerl_DispelTypeCache[key] = { dt = dt, name = name, ts = GetTime() }
end


-- Additional cache keyed by auraInstanceID (often accessible even when spellId/name are secret).
TPerl_DispelTypeCacheByAuraId = TPerl_DispelTypeCacheByAuraId or {}

function TPerl_SafeAuraIdKey(auraId)
	if (auraId == nil) then
		return nil
	end
	if (not TPerl_CanAccess(auraId)) then
		return nil
	end
	if (type(auraId) == "number") then
		return auraId
	end
	local ok, n = pcall(tonumber, auraId)
	if (ok and type(n) == "number") then
		return n
	end
	return nil
end



-- Safe table access helpers (avoid 'forbidden table' / taint errors)
function TPerl_SafeTableGet(t, k)
	if (type(t) ~= "table") then
		return nil
	end
	local ok, v = pcall(function() return t[k] end)
	if (ok) then
		return v
	end
	return nil
end

function TPerl_SafeTableIndex(t, i)
	if (type(t) ~= "table") then
		return nil
	end
	local ok, v = pcall(function() return t[i] end)
	if (ok) then
		return v
	end
	return nil
end




-- --------------------------------------------------------------------
-- Aura API safety helpers (Midnight/Retail restrictions)
-- Some C_UnitAuras calls reject compound unit tokens like "targettarget" or "pettarget".
-- Use these helpers to avoid hard errors and gracefully fall back to slot-based APIs when needed.
-- --------------------------------------------------------------------

function TPerl_UnitTokenAllowsC_UnitAuras(unit)
	if (type(unit) ~= "string") then
		return false
	end
	-- Blizzard Aura API rejects compound tokens containing "target" (e.g. "party1target", "targettarget", "pettarget").
	if (unit ~= "target" and strfind(unit, "target", 1, true)) then
		return false
	end
	return true
end

-- Returns auraData table (Retail-style) or nil. Never throws.
function TPerl_SafeGetAuraDataByIndex(unit, index, filter)
	if (IsRetail and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and TPerl_UnitTokenAllowsC_UnitAuras(unit)) then
		local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
		if (ok) then
			return auraData
		end
	end

	-- Fallback: slot-based APIs. UnitAura is removed on modern Retail (11.0.2+),
	-- and GetAuraDataByIndex rejects compound tokens, but UnitAuraSlots + GetAuraDataBySlot may still work.
	if (IsRetail and UnitAuraSlots and C_UnitAuras and C_UnitAuras.GetAuraDataBySlot) then
		local r = {pcall(UnitAuraSlots, unit, filter, index)}
		-- r[1]=ok, r[2]=continuationToken, r[3]=slot1...
		if (r[1]) then
			local slot = r[index + 2]
			if (slot) then
				local ok, auraData = pcall(C_UnitAuras.GetAuraDataBySlot, unit, slot)
				if (ok) then
					return auraData
				end
			end
		end
	end

	return nil
end


-- Midnight/Retail: secret/forbidden dispelType support via ColorCurve.
-- We avoid comparing dispelType strings and instead transform dispelType -> secret color.
TPerl_DebuffColorCurve = TPerl_DebuffColorCurve or nil

function TPerl_InitDebuffColorCurve()
	if (TPerl_DebuffColorCurve) then
		return TPerl_DebuffColorCurve
	end

	if (not C_CurveUtil or not C_CurveUtil.CreateColorCurve) then
		return nil
	end
	if (not Enum or not Enum.LuaCurveType or not Enum.AuraDispelType) then
		return nil
	end
	if (not CreateColor) then
		return nil
	end

	local ok, curve = pcall(C_CurveUtil.CreateColorCurve)
	if (not ok or not curve) then
		return nil
	end

	pcall(curve.SetType, curve, Enum.LuaCurveType.Step)

	pcall(curve.AddPoint, curve, Enum.AuraDispelType.None,    CreateColor(0.0, 0.0, 0.0, 0.0))
	pcall(curve.AddPoint, curve, Enum.AuraDispelType.Magic,   CreateColor(0.2, 0.6, 1.0))
	pcall(curve.AddPoint, curve, Enum.AuraDispelType.Curse,   CreateColor(0.6, 0.0, 1.0))
	pcall(curve.AddPoint, curve, Enum.AuraDispelType.Disease, CreateColor(0.6, 0.4, 0.0))
	pcall(curve.AddPoint, curve, Enum.AuraDispelType.Poison,  CreateColor(0.0, 0.6, 0.0))

	TPerl_DebuffColorCurve = curve
	return curve
end


-- Returns: colourTable{r,g,b,a}, auraId, spellId, name
-- Uses the official helper when available to convert (possibly secret) dispel type -> colour via our curve.
function TPerl_GetDebuffColorByAuraData(unit, auraData, curve)
	curve = curve or TPerl_InitDebuffColorCurve()
	if (not curve or not auraData) then
		return nil
	end

	local auraId = TPerl_SafeTableGet(auraData, "auraInstanceID") or TPerl_SafeTableGet(auraData, "auraInstanceId")
	local colourObj

	if (auraId and C_UnitAuras and C_UnitAuras.GetAuraDispelTypeColor) then
		local okC, c = pcall(C_UnitAuras.GetAuraDispelTypeColor, unit, auraId, curve)
		if (okC and c) then
			colourObj = c
		end
	end

	-- Fallback: some clients may expose dispelType as an object with :GetColorFromCurve(curve)
	if (not colourObj) then
		local dispelType = TPerl_SafeTableGet(auraData, "dispelType")
		if (dispelType) then
			local okC, c = pcall(dispelType.GetColorFromCurve, dispelType, curve)
			if (okC and c) then
				colourObj = c
			end
		end
	end

	if (not colourObj) then
		return nil
	end

	local okRGBA, r, g, b, a = pcall(colourObj.GetRGBA, colourObj)
	if (not okRGBA) then
		return nil
	end
	-- Allow curves to encode "no highlight" as alpha 0.
	if (a == 0) then
		return nil
	end

	local spellId = TPerl_SafeTableGet(auraData, "spellId") or TPerl_SafeTableGet(auraData, "spellID")
	local name = TPerl_SafeTableGet(auraData, "name")

	return { r = r, g = g, b = b, a = a }, auraId, spellId, name
end


-- Returns: colourTable{r,g,b,a}, auraId, spellId, name
function TPerl_GetDebuffColorByAuraIndex(unit, index)
	local curve = TPerl_InitDebuffColorCurve()
	if (not curve) then
		return nil
	end
	if (not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex) then
		return nil
	end

	local okAD, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HARMFUL")
	if (not okAD or not auraData) then
		return nil
	end

	return TPerl_GetDebuffColorByAuraData(unit, auraData, curve)
end

function TPerl_GetCachedDispelTypeByAuraId(auraId)
	local key = TPerl_SafeAuraIdKey(auraId)
	if (not key) then
		return nil
	end
	local e = TPerl_DispelTypeCacheByAuraId[key]
	if (e and e.dt) then
		if (not e.ts) then
			return e.dt
		end
		if (GetTime() - e.ts) < 86400 then
			return e.dt
		end
		TPerl_DispelTypeCacheByAuraId[key] = nil
	end
	return nil
end

function TPerl_SetCachedDispelTypeByAuraId(auraId, dt)
	local key = TPerl_SafeAuraIdKey(auraId)
	if (not key or not dt) then
		return
	end
	TPerl_DispelTypeCacheByAuraId[key] = { dt = dt, ts = GetTime() }
end

-- Scan tooltip data (C_TooltipInfo) safely to infer dispel type when the API returns secret values.
-- IMPORTANT: Do not use secret values as table indices or for string operations.
function TPerl_FindDispelTypeInTooltipData(data)
	-- C_TooltipInfo can return "forbidden" tables on some clients. Any direct indexing can hard error.
	-- Always use safe getters (pcall) and avoid #/ipairs on those tables.
	if (type(data) ~= "table") then
		return nil
	end

	local lines = TPerl_SafeTableGet(data, "lines")
	if (type(lines) ~= "table") then
		return nil
	end

	local nameLine = nil

	-- Tooltip lines are typically <= 10; scan a bounded range safely.
	for i = 1, 20 do
		local line = TPerl_SafeTableIndex(lines, i)
		if (not line) then
			break
		end

		if (type(line) == "table") then
			-- Remember first accessible text as "name line"
			if (not nameLine) then
				local n = TPerl_SafeTableGet(line, "leftText") or TPerl_SafeTableGet(line, "text") or TPerl_SafeTableGet(line, "rightText")
				if (n and TPerl_CanAccess(n)) then
					nameLine = n
				end
			end

			local function checkExact(s)
				if (not s or not TPerl_CanAccess(s)) then
					return nil
				end
				local dt = TPerl_NormalizeDispelType(s)
				if (dt == "Magic" or dt == "Curse" or dt == "Disease" or dt == "Poison" or dt == "none") then
					return dt
				end
				return nil
			end

			-- Check any available text fields for dispel keywords/types
			local c1 = TPerl_SafeTableGet(line, "leftText")
			local c2 = TPerl_SafeTableGet(line, "rightText")
			local c3 = TPerl_SafeTableGet(line, "text")

			local dt = checkExact(c1) or checkExact(c2) or checkExact(c3)
			if (dt) then
				return dt, nameLine
			end

			-- Heuristic: localized longer strings can include the type (e.g. "Tipo: Veneno")
			local function tryHeuristic(s)
				if (not s or not TPerl_CanAccess(s)) then
					return nil
				end
				local ss
				if (strtrim) then
					ss = strtrim(s)
				else
					ss = tostring(s):gsub("^%s+", ""):gsub("%s+$", "")
				end

				local ok2, low = pcall(string.lower, ss)
				if (ok2 and low and #low <= 120) then
					if (low:find("veneno", 1, true) or low:find("poison", 1, true)) then return "Poison" end
					if (low:find("maldici", 1, true) or low:find("curse", 1, true)) then return "Curse" end
					if (low:find("enfermedad", 1, true) or low:find("disease", 1, true)) then return "Disease" end
					if (low:find("magia", 1, true) or low:find("magic", 1, true)) then return "Magic" end
					if (low == "none" or low:find("sin tipo", 1, true)) then return "none" end
				end
				return nil
			end

			local dtH = tryHeuristic(c1) or tryHeuristic(c2) or tryHeuristic(c3)
			if (dtH) then
				return dtH, nameLine
			end
		end
	end

	return nil, nameLine
end

function TPerl_GetDispelTypeFromTooltip(unit, index)
	if (not unit or not index) then
		return nil
	end

	-- Prefer tooltip data API if available (doesn't require anchoring a visible GameTooltip).
	-- NOTE: Some Midnight clients can return "forbidden" tables here; always protect with pcall.
	if (C_TooltipInfo and C_TooltipInfo.GetUnitAura) then
		local ok, data = pcall(C_TooltipInfo.GetUnitAura, unit, index, "HARMFUL")
		if (ok and data) then
			local ok2, dt, nameLine = pcall(TPerl_FindDispelTypeInTooltipData, data)
			if (ok2 and dt) then
				return dt, nameLine
			end
		end
	end

	-- Fallback: hidden GameTooltip scan
	if (not TPerl_DebuffScanTT) then
		TPerl_DebuffScanTT = CreateFrame("GameTooltip", "TPerlDebuffScanTooltip", UIParent, "GameTooltipTemplate")
		TPerl_DebuffScanTT:SetOwner(UIParent, "ANCHOR_NONE")
		TPerl_DebuffScanTT:Hide()
	end

	local tt = TPerl_DebuffScanTT
	tt:SetOwner(UIParent, "ANCHOR_NONE")
	tt:ClearLines()

	-- Prefer SetUnitDebuff (works across versions); fallback to SetUnitAura for some clients.
	local okSet = pcall(tt.SetUnitDebuff, tt, unit, index)
	if (not okSet) then
		okSet = pcall(tt.SetUnitAura, tt, unit, index, "HARMFUL")
	end
	if (not okSet) then
		tt:Hide()
		return nil
	end

	local nameLineObj = _G["TPerlDebuffScanTooltipTextLeft1"]
	local nameLine = nameLineObj and nameLineObj:GetText()

	local function checkLine(line)
		if (not line or not TPerl_CanAccess(line)) then
			return nil
		end

		local s
		if (strtrim) then
			s = strtrim(line)
		else
			s = tostring(line):gsub("^%s+", ""):gsub("%s+$", "")
		end

		local dt = TPerl_NormalizeDispelType(s)
		if (dt == "Magic" or dt == "Curse" or dt == "Disease" or dt == "Poison" or dt == "none") then
			return dt
		end

		-- Heuristic: localized longer strings can include the type (e.g. "Tipo: Veneno")
		local ok2, low = pcall(string.lower, s)
		if (ok2 and low and #low <= 120) then
			if (low:find("veneno", 1, true) or low:find("poison", 1, true)) then return "Poison" end
			if (low:find("maldici", 1, true) or low:find("curse", 1, true)) then return "Curse" end
			if (low:find("enfermedad", 1, true) or low:find("disease", 1, true)) then return "Disease" end
			if (low:find("magia", 1, true) or low:find("magic", 1, true)) then return "Magic" end
			if (low == "none" or low:find("sin tipo", 1, true)) then return "none" end
		end

		return nil
	end

	local nlines = tt:NumLines() or 0
	-- Scan both left and right columns; some clients display the dispel type on the right (often on line 1).
	for i = 1, nlines do
		local objL = _G["TPerlDebuffScanTooltipTextLeft" .. i]
		local objR = _G["TPerlDebuffScanTooltipTextRight" .. i]
		local lineL = objL and objL:GetText()
		local lineR = objR and objR:GetText()

		local dt = checkLine(lineL) or checkLine(lineR)
		if (dt) then
			tt:Hide()
			return dt, nameLine
		end
	end

	tt:Hide()
	return nil, nameLine
end

-- TPerl_GetHarmfulAura
-- Best-effort harmful aura read that prefers the source which provides a usable dispel type.
-- Some Midnight/Retail clients can return "secret" values via C_UnitAuras, while UnitAura may still provide usable data.
function TPerl_GetHarmfulAura(unit, index)
	local nameUD, dispelUD, spellIdUD
	local nameUA, dispelUA, spellIdUA
	local nameCA, dispelCA, spellIdCA, auraIdCA

	-- UnitDebuff is often the most compatible for dispel type (Curse/Magic/Poison/Disease)
	local okD, nd, _, _, dd, _, _, _, _, sidD = pcall(UnitDebuff, unit, index)
	if (okD) then
		nameUD = nd
		dispelUD = dd
		spellIdUD = sidD
	end

	-- UnitAura first (more compatible with older addon logic, and sometimes less "secret" on custom clients)
	local ok, n, _, _, d, _, _, _, _, sid = pcall(UnitAura, unit, index, "HARMFUL")
	if (ok) then
		nameUA = n
		dispelUA = d
		spellIdUA = sid
	end

	-- C_UnitAuras fallback/alternative
	if (not IsVanillaClassic and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
		local okAD, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HARMFUL")
		if (okAD and auraData) then
			nameCA = TPerl_SafeTableGet(auraData, "name")
			dispelCA = TPerl_SafeTableGet(auraData, "dispelName")
			spellIdCA = TPerl_SafeTableGet(auraData, "spellId") or TPerl_SafeTableGet(auraData, "spellID")
			auraIdCA = TPerl_SafeTableGet(auraData, "auraInstanceID") or TPerl_SafeTableGet(auraData, "auraInstanceId")
		end
	end

	-- No aura in either source
	if (not nameUD and not nameUA and not nameCA) then
		return nil
	end

-- Choose dispel type: prefer one that normalizes to a known dispel type
local function isUseful(norm)
	return (norm == "Magic" or norm == "Curse" or norm == "Disease" or norm == "Poison" or norm == "none")
end

-- Prefer UnitDebuff's debuffType if it is usable, then UnitAura, then AuraData.
local chosenDispel = dispelUD
local normUD = TPerl_NormalizeDispelType(dispelUD)
if (not isUseful(normUD)) then
	chosenDispel = dispelUA
	local normUA = TPerl_NormalizeDispelType(dispelUA)
	if (not isUseful(normUA)) then
		local normCA = TPerl_NormalizeDispelType(dispelCA)
		if (isUseful(normCA)) then
			chosenDispel = dispelCA
		end
	end
end

-- Choose name: prefer any accessible name if available (UD > UA > CA)
local chosenName
if (nameUD and TPerl_CanAccess(nameUD)) then
	chosenName = nameUD
elseif (nameUA and TPerl_CanAccess(nameUA)) then
	chosenName = nameUA
elseif (nameCA and TPerl_CanAccess(nameCA)) then
	chosenName = nameCA
else
	chosenName = nameUD or nameUA or nameCA
end

	-- Choose spellId
	local chosenSpellId = spellIdUD or spellIdUA or spellIdCA

	-- Choose auraInstanceID (Retail aura data)
	local chosenAuraId = auraIdCA	-- Tooltip/cache fallback when dispel type is hidden/secret on some clients.
	local normChosen = TPerl_NormalizeDispelType(chosenDispel)
	local safeSpellKey = TPerl_SafeSpellIdKey(chosenSpellId)
	local safeAuraKey = TPerl_SafeAuraIdKey(chosenAuraId)

	if (not isUseful(normChosen)) then
		-- 1) AuraId cache (most stable)
		if (safeAuraKey) then
			local cdt = TPerl_GetCachedDispelTypeByAuraId(safeAuraKey)
			if (cdt) then
				chosenDispel = cdt
				normChosen = TPerl_NormalizeDispelType(chosenDispel)
			end
		end

		-- 2) SpellId cache (if usable)
		if (safeSpellKey and not isUseful(normChosen)) then
			local cachedDt, cachedName = TPerl_GetCachedDispelType(safeSpellKey)
			if (cachedDt) then
				chosenDispel = cachedDt
				normChosen = TPerl_NormalizeDispelType(chosenDispel)
				if ((not chosenName) or (not TPerl_CanAccess(chosenName))) and cachedName and TPerl_CanAccess(cachedName) then
					chosenName = cachedName
				end
			end
		end

		-- 3) Tooltip scan (doesn't require spellId)
		if (not isUseful(normChosen)) then
			local dtTT, nameTT = TPerl_GetDispelTypeFromTooltip(unit, index)
			if (dtTT) then
				chosenDispel = dtTT
				normChosen = TPerl_NormalizeDispelType(chosenDispel)
				if (safeAuraKey) then
					TPerl_SetCachedDispelTypeByAuraId(safeAuraKey, dtTT)
				end
				if (safeSpellKey) then
					TPerl_SetCachedDispelType(safeSpellKey, dtTT, nameTT)
				end
			end
			if ((not chosenName) or (not TPerl_CanAccess(chosenName))) and nameTT and TPerl_CanAccess(nameTT) then
				chosenName = nameTT
			end
		end
	end


return chosenName, chosenDispel, chosenSpellId, chosenAuraId, nameUA, dispelUA, spellIdUA, nameCA, dispelCA, spellIdCA, auraIdCA, nameUD, dispelUD, spellIdUD
end


-- Midnight: stack-count display that won't trigger secret-value compares.
-- Prefer the classic UnitAura count when accessible; otherwise query AuraData by auraInstanceID.
function TPerl_SetAuraStackText(button, legacyCount, unit, auraInstanceID)
	if (not button or not button.count) then
		return
	end

	-- Classic path (non-secret count)
	if (legacyCount ~= nil and TPerl_CanAccess(legacyCount) and legacyCount > 1) then
		button.count:SetText(legacyCount)
		button.count:Show()
		return
	end

	-- Midnight path (AuraData). applications/charges may be secret; we avoid comparing when secret.
	local aura
	if (auraInstanceID and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID and TPerl_UnitTokenAllowsC_UnitAuras(unit)) then
		local okAD, a = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, unit, auraInstanceID)
		if (okAD) then
			aura = a
		end
	end
	if (aura) then
		local apps = aura.applications
		if (type(apps) == "number") then
			if (TPerl_CanAccess(apps)) then
				if (apps > 1) then
					button.count:SetText(apps)
					button.count:Show()
					return
				end
			else
				-- Secret number: show it verbatim (may display "1" on non-stackable auras, but avoids errors)
				button.count:SetText(apps)
				button.count:Show()
				return
			end
		end

		local charges = aura.charges
		if (type(charges) == "number") then
			if (TPerl_CanAccess(charges)) then
				if (charges > 1) then
					button.count:SetText(charges)
					button.count:Show()
					return
				end
			else
				button.count:SetText(charges)
				button.count:Show()
				return
			end
		end
	end

	button.count:Hide()
end

-- Midnight: when aura timing is secret, we can't run our own countdown logic.
-- Let Blizzard render cooldown text by allowing countdown numbers and clearing noCooldownCount.
local function TPerl_EnableBlizzardCooldownText(cd)
	if (not cd) then
		return
	end
	if (cd.SetHideCountdownNumbers) then
		cd:SetHideCountdownNumbers(false)
	end
	-- Some cooldown-text systems (including Blizzard's) respect this opt-out flag.
	cd.noCooldownCount = nil
	if (cd.SetUseAuraDisplayTime) then
		cd:SetUseAuraDisplayTime(true)
	end
end


local GetAddOnCPUUsage = GetAddOnCPUUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local GetCursorPosition = GetCursorPosition
local GetDifficultyColor = GetDifficultyColor or GetQuestDifficultyColor
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetLocale = GetLocale
local GetNumAddOns = GetNumAddOns
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetRaidTargetIndex = GetRaidTargetIndex
local GetReadyCheckStatus = GetReadyCheckStatus
local GetRealmName = GetRealmName
local GetRealZoneText = GetRealZoneText
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsInRaid = IsInRaid
local IsItemInRange = IsItemInRange
local IsShiftKeyDown = IsShiftKeyDown
local IsSpellInRange = IsSpellInRange
local SecureButton_GetUnit = SecureButton_GetUnit
local SetCursor = SetCursor
local SetPortraitTexture = SetPortraitTexture
local SetPortraitToTexture = SetPortraitToTexture
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local SpellCanTargetUnit = SpellCanTargetUnit
local SpellIsTargeting = SpellIsTargeting
local UnitAffectingCombat = UnitAffectingCombat
local UnitAlternatePowerInfo = UnitAlternatePowerInfo
local UnitAura = UnitAura
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitInRange = UnitInRange
local UnitInVehicle = UnitInVehicle
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPlayerControlled = UnitPlayerControlled
local UnitPopup_ShowMenu = UnitPopup_ShowMenu
local UnitPopupMenus = UnitPopupMenus
local UnitPopupShown = UnitPopupShown
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction
local UnregisterUnitWatch = UnregisterUnitWatch
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

local BuffFrame = BuffFrame
local GameTooltip = GameTooltip
local Minimap = Minimap
local UIParent = UIParent

local ArcaneExclusions = TPerl_ArcaneExclusions

local largeNumTag = TPERL_LOC_LARGENUMTAG
local hugeNumTag = TPERL_LOC_HUGENUMTAG
local veryhugeNumTag = TPERL_LOC_VERYHUGENUMTAG

--[==[@debug@
local function d(...)
	ChatFrame1:AddMessage(format(...))
end
--@end-debug@]==]

-- Compact Raid frame manager
local c = _G.CompactRaidFrameManager
if c then
	c:SetFrameStrata("Medium")
end

------------------------------------------------------------------------------
-- Re-usable tables
local FreeTables = setmetatable({}, {__mode = "k"})
local requested, freed = 0, 0

function TPerl_GetReusableTable(...)
	requested = requested + 1
	for t in pairs(FreeTables) do
		FreeTables[t] = nil
		for i = 1, select("#", ...) do
			t[i] = select(i, ...)
		end
		return t
	end
	return {...}
end

function TPerl_FreeTable(t, deep)
	if (t) then
		if (type(t) ~= "table") then
			error("Usage: TPerl_FreeTable([table])")
		end
		if (FreeTables[t]) then
			error("TPerl_FreeTable - Table already freed")
		end

		freed = freed + 1

		FreeTables[t] = true
		for k, v in pairs(t) do
			if (deep and type(v) == "table") then
				TPerl_FreeTable(v, true)
			end
			t[k] = nil
		end
		--t[''] = 0
		--t[''] = nil
	end
end

function TPerl_TableStats()
	print(requested, freed)
	return requested, freed
end

--local new, del = TPerl_GetReusableTable, TPerl_FreeTable

local function rotate(angle)
	local A = cos(angle)
	local B = sin(angle)
	local ULx, ULy = -0.5 * A - -0.5 * B, -0.5 * B + -0.5 * A
	local LLx, LLy = -0.5 * A - 0.5 * B, -0.5 * B + 0.5 * A
	local URx, URy = 0.5 * A - -0.5 * B, 0.5 * B + -0.5 * A
	local LRx, LRy = 0.5 * A - 0.5 * B, 0.5 * B + 0.5 * A
	return ULx + 0.5, ULy + 0.5, LLx + 0.5, LLy + 0.5, URx + 0.5, URy + 0.5, LRx + 0.5, LRy + 0.5
end

-- meta table for string based colours. Allows for other mods changing class colours and things all working
TPerlColourTable = setmetatable({ }, {
	__index = function(self, class)
		if not class then
			return
		end
		local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[strupper(class or "")]
		if (c) then
			c = format("|c00%02X%02X%02X", 255 * c.r, 255 * c.g, 255 * c.b)
		else
			c = "|c00808080"
		end
		self[class] = c
		return c
	end
})

--TPerl_Percent = setmetatable({},
--	{__mode = "kv",
--	__index = function(self, i)
--		if (type(i) == "number" and i >= 0) then
--			self[i] = format(percD, i)
--			return self[i]
--		end
--		return ""
--	end
--	})
--local xpPercent = TPerl_Percent

-- TPerl_ShowMessage
-- debug function
--[[function TPerl_ShowMessage(cMsg)
	local str = "|c00FF7F00"..event.."|r"
	local theEnd
	if (arg1 and (arg1 == "player" or arg1 == "pet" or arg1 == "target" or arg1 =="focus" or strfind(arg1, "^raid") or strfind(arg1, "^party"))) then
		local class = select(2, UnitClass(arg1))
		if (class) then
			str = str..", |c00808080"..tostring(arg1).."("..TPerlColourTable[class]..UnitName(arg1).."|c00808080)|r"
			theEnd = 2
		end
	else
		theEnd = 1
	end

	local tail, doit = ""
	for i = 9,theEnd,-1 do
		local v = _G["arg"..i]
		if (v or doit) then
			if (tail ~= "") then
				tail = tostring(v)..", "..tail
			else
				tail = tostring(v)
			end
			doit = true
		end
	end
	if (tail ~= "") then
		str = str..", "..tail
	end

	if (cMsg) then
		str = cMsg.." - "..str
	end

	local cf = ChatFrame2
	if (not cf:IsVisible()) then
		cf = DEFAULT_CHAT_FRAME
	end
	if (self and self.GetName and self:GetName()) then
		cf:AddMessage("|c00007F7F"..self:GetName().."|r - "..str)
	else
		cf:AddMessage(str)
	end
end]]

TPerl_AnchorList = {"TOP", "LEFT", "BOTTOM", "RIGHT"}

-- FindABandage()
local function FindABandage()
	local bandages = {
		[173192] = true, -- Shrouded Cloth Bandage
		[173191] = true, -- Heavy Shrouded Cloth Bandage
		[158382] = true, -- Deep Sea Bandage
		[158381] = true, -- Tidespray Linen Bandage
		[142332] = true, -- Feathered Luffa
		[136653] = true, -- Silvery Salve
		[133942] = true, -- Silkweave Splint
		[133940] = true, -- Silkweave Bandage
		[115497] = true, -- Ashran Bandage
		[111603] = true, -- Antiseptic Bandage
		[72986] = true, -- Heavy Windwool Bandage
		[72985] = true, -- Windwool Bandage
		[53051] = true, -- Dense Embersilk Bandage
		[53050] = true, -- Heavy Embersilk Bandage
		[53049] = true, -- Embersilk Bandage
		[34722] = true, -- Heavy Frostweave Bandage
		[34721] = true,	-- Frostweave Bandage
		[21991] = true, -- Heavy Netherweave Bandage
		[21990] = true, -- Netherweave Bandage
		[14530] = true, -- Heavy Runecloth Bandage
		[14529] = true, -- Runecloth Bandage
		[8545] = true, -- Heavy Mageweave Bandage
		[8544] = true, -- Mageweave Bandage
		[6451] = true, -- Heavy Silk Bandage
		[6450] = true, -- Silk Bandage
		[3531] = true, -- Heavy Wool Bandage
		[3530] = true, -- Wool Bandage
		[2581] = true, -- Heavy Linen Bandage
		[1251] = true, -- Linen Bandage
	}

	for k, v in pairs(bandages) do
		if (C_Item and C_Item.GetItemCount) and C_Item.GetItemCount(k) or GetItemCount(k) > 0 then
			return GetItemInfo(k)
		end
	end
end

local playerClass

-- We have a dummy do-nothing function here for classes that don't have range checking
-- The do-something function is setup after variables_loaded and we work out spell to use just once
function TPerl_UpdateSpellRange()
	return
end

--local SpiritRealm = (C_Spell and C_Spell.GetSpellInfo(235621)) and C_Spell.GetSpellInfo(235621).name or GetSpellInfo(235621)

-- DoRangeCheck
local function DoRangeCheck(unit, opt)
	local range
	if opt.PlusHealth then
		local hp, hpMax = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit)), UnitHealthMax(unit)
		-- Begin 4.3 divide by 0 work around.
		local percent
		if UnitIsDeadOrGhost(unit) or (hp == 0 and hpMax == 0) then -- Probably dead target
			percent = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
		elseif hp > 0 and hpMax == 0 then -- We have current HP but max hp failed.
			hpMax = hp -- Make max hp at least equal to current health
			percent = 1 -- 100% if they are alive with > 0 cur hp, since curhp = maxhp in this hack.
		else
			percent = hp / hpMax -- Everything is dandy, so just do it right way.
		end
		-- End divide by 0 work around
		if (percent > opt.HealthLowPoint) then
			range = 0
		end
	end

	if opt.PlusDebuff and ((opt.PlusHealth and range == 0) or not opt.PlusHealth) then
		local name
		if IsRetail and C_UnitAuras then
			local auraData = TPerl_SafeGetAuraDataByIndex(unit, 1, "HARMFUL|RAID")
			if auraData then
				name = TPerl_SafeTableGet(auraData, "name")
			end
		else
			name = UnitAura(unit, 1, "HARMFUL|RAID")
		end
		if not name then
			range = 0
		else
			if ArcaneExclusions[name] then
				-- It's one of the filtered debuffs, so we have to iterate thru all debuffs to see if anything is curable
				for i = 1, 40 do
					local name
					if IsRetail and C_UnitAuras then
						local auraData = TPerl_SafeGetAuraDataByIndex(unit, i, "HARMFUL|RAID")
						if auraData then
							name = TPerl_SafeTableGet(auraData, "name")
						end
					else
						name = UnitAura(unit, i, "HARMFUL|RAID")
					end
					if not name then
						range = 0
						break
					elseif not ArcaneExclusions[name] then
						range = nil
						break
					end
				end
			else
				range = nil -- Override's the health check, because there's a debuff on unit
			end
		end
	end

	if not range then
		--local playerRealm = UnitAura("player", SpiritRealm, "HARMFUL")
		--local unitRealm = UnitAura(unit, SpiritRealm, "HARMFUL")

		--[[if playerRealm ~= unitRealm then
			range = nil
		else--]]
		if opt.interact then
		 if IsRetail then
			 return
			end
			if opt.interact == 6 then -- 45y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 5 then -- 40y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 3 then -- 10y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 2 then -- 20y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 1 then -- 30y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			end
			-- CheckInteractDistance
			-- 1 = Inspect = 28 yards (BCC = 28 yards) (Vanilla = 10 yards)
			-- 2 = Trade = 8 yards (BCC = 8 yards) (Vanilla = 11 yards)
			-- 3 = Duel = 7 yards (BCC = 7 yards) (Vanilla = 10 yards)
			-- 4 = Follow = 28 yards (BCC = 28 yards) (Vanilla = 28 yards)
			-- 5 = Pet-battle Duel = 7 yards (BCC = 7 yards) (Vanilla = 10 yards)
		elseif opt.spell or opt.spell2 then
			if IsRetail or IsVanillaClassic then
				if UnitCanAssist("player", unit) and opt.spell then
					range = (C_Spell and C_Spell.IsSpellInRange) and C_Spell.IsSpellInRange(opt.spell, unit) or (IsSpellInRange and IsSpellInRange(opt.spell, unit))
				elseif UnitCanAttack("player", unit) and opt.spell2 then
					range = (C_Spell and C_Spell.IsSpellInRange) and C_Spell.IsSpellInRange(opt.spell2, unit) or (IsSpellInRange and IsSpellInRange(opt.spell2, unit))
				else
					-- Fallback (28y) (BCC = 28y) (Vanilla = 28 yards)
					range = not InCombatLockdown() and CheckInteractDistance(unit, 4)
				end
			else
				if UnitCanAssist("player", unit) and opt.spell then
					range = (C_Spell and C_Spell.IsSpellInRange) and C_Spell.IsSpellInRange(opt.spell, unit) or (IsSpellInRange and IsSpellInRange(opt.spell, unit))
				elseif UnitCanAttack("player", unit) and opt.spell2 then
					range = (C_Spell and C_Spell.IsSpellInRange) and C_Spell.IsSpellInRange(opt.spell2, unit) or (IsSpellInRange and IsSpellInRange(opt.spell2, unit))
				else
					-- Fallback (28y) (BCC = 28y) (Vanilla = 28 yards)
					range = not InCombatLockdown() and CheckInteractDistance(unit, 4)
				end
			end
		elseif not IsRetail and not IsVanillaClassic and (opt.item or opt.item2) then
			if UnitCanAssist("player", unit) and opt.item then
				range = not InCombatLockdown() and IsItemInRange(opt.item, unit)
			elseif UnitCanAttack("player", unit) and opt.item2 then
				range = not InCombatLockdown() and IsItemInRange(opt.item2, unit)
			else
				-- Fallback (28y) (BCC = 28y) (Vanilla = 28 yards)
				range = not InCombatLockdown() and CheckInteractDistance(unit, 4)
			end
		else
			range = 1
		end
	end

	if range ~= 1 and range ~= true then
		return opt.FadeAmount
	end
end

-- TPerl_UpdateSpellRange(self)
function TPerl_UpdateSpellRange2(self, overrideUnit, isRaidFrame)
	local unit
	if (overrideUnit) then
		unit = overrideUnit
	else
		unit = self:GetAttribute("unit")
		if (not unit) then
			unit = SecureButton_GetUnit(self)
		end
	end
	if (unit) then
		local rf = conf.rangeFinder
		local mainA, nameA, statsA -- Receives main, name and stats alpha levels

		if (rf.enabled and (isRaidFrame or not conf.rangeFinder.raidOnly)) then
			if (not UnitIsVisible(unit))--[[ or UnitInVehicle(unit)]] then
				if (rf.Main.enabled) then
					mainA = conf.transparency.frame * rf.Main.FadeAmount
				else
					if (rf.NameFrame.enabled) then
						nameA = rf.NameFrame.FadeAmount
					end
					if (rf.StatsFrame.enabled) then
						statsA = rf.StatsFrame.FadeAmount
					end
				end
			--[[elseif (TPerl_Highlight:HasEffect(UnitName(unit), "AGGRO")) then
				mainA = conf.transparency.frame]]
			else
				if (rf.Main.enabled) then
					mainA = DoRangeCheck(unit, rf.Main)
					if (mainA) then
						mainA = mainA * conf.transparency.frame
					end
				end

				if (rf.NameFrame.enabled) then
					-- check for same item/spell. Saves doing the check multiple times
					if (rf.Main.enabled and (rf.Main.spell == rf.NameFrame.spell) and (rf.Main.item == rf.NameFrame.item) and (rf.Main.spell2 == rf.NameFrame.spell2) and (rf.Main.item2 == rf.NameFrame.item2) and (rf.Main.PlusHealth == rf.NameFrame.PlusHealth)) then
						if (mainA) then
							nameA = rf.NameFrame.FadeAmount
						end
					else
						nameA = DoRangeCheck(unit, rf.NameFrame)
						if (not nameA and mainA) then
							-- In range, but 'Whole' frame is out of range, so we need to override the fade for name
							nameA = 1
						end
					end
				end
				if (rf.StatsFrame.enabled) then
					-- check for same item/spell. Saves doing the check multiple times
					if (rf.Main.enabled and (rf.Main.spell == rf.StatsFrame.spell) and (rf.Main.item == rf.StatsFrame.item) and (rf.Main.spell2 == rf.StatsFrame.spell2) and (rf.Main.item2 == rf.StatsFrame.item2) and (rf.Main.PlusHealth == rf.StatsFrame.PlusHealth)) then
						if (mainA) then
							statsA = rf.StatsFrame.FadeAmount
						end
					else
						statsA = DoRangeCheck(unit, rf.StatsFrame)
						if (not statsA and mainA) then
							-- In range, but 'Whole' frame is out of range, so we need to override the fade for stats
							statsA = 1
						end
					end
				end
			end
		end

		local forcedMainA
		if (not mainA) then
			if (UnitIsConnected(unit)) then
				mainA = conf.transparency.frame
				forcedMainA = true
			else
				mainA = conf.transparency.frame * rf.Main.FadeAmount
				nameA, statsA = mainA
				forcedMainA = true
			end
		end

		self:SetAlpha(mainA)
		if (self.nameFrame) then
			if (nameA or forcedMainA) then
				self.nameFrame:SetAlpha(nameA or mainA)
			else
				self.nameFrame:SetAlpha(1)
			end
		end
		if (self.statsFrame) then
			if (nameA or forcedMainA) then
				self.statsFrame:SetAlpha(statsA or mainA)
			else
				self.statsFrame:SetAlpha(1)
			end
		end
	end
end

-- TPerl_StartupSpellRange()
function TPerl_StartupSpellRange()
		--print("TPerl.lua:315")
	local _, playerClass = UnitClass("player")

	if (not TPerl_DefaultRangeSpells.ANY) then
		TPerl_DefaultRangeSpells.ANY = {}
	end

	local bandage = FindABandage()
	if bandage then
		TPerl_DefaultRangeSpells.ANY.item = bandage
	end

	local rf = conf.rangeFinder

	local function Setup1(self)
		if type(self.spell) ~= "string" then
			self.spell = TPerl_DefaultRangeSpells[playerClass] and TPerl_DefaultRangeSpells[playerClass].spell
			if type(self.item) ~= "string" then
				self.item = (TPerl_DefaultRangeSpells.ANY and TPerl_DefaultRangeSpells.ANY.item) or ""
			end
		end
		if type(self.spell2) ~= "string" then
			self.spell2 = TPerl_DefaultRangeSpells[playerClass] and TPerl_DefaultRangeSpells[playerClass].spell2
			if type(self.item2) ~= "string" then
				self.item2 = (TPerl_DefaultRangeSpells.ANY and TPerl_DefaultRangeSpells.ANY.item2) or ""
			end
		end

		if (not self.FadeAmount) then
			self.FadeAmount = 0.3
		end
		if (not self.HealthLowPoint) then
			self.HealthLowPoint = 0.7
		end
	end

	Setup1(rf.Main)
	Setup1(rf.NameFrame)
	Setup1(rf.StatsFrame)

	--if (rangeCheckSpell) then
		-- Put the real work function in place
	TPerl_UpdateSpellRange = TPerl_UpdateSpellRange2
	--else
	--	TPerl_UpdateSpellRange = function() end
	--end
end

TPerl_RegisterOptionChanger(TPerl_StartupSpellRange, nil, "TPerl_StartupSpellRange")

-- TPerl_StatsFrame_SetGrey
local function TPerl_StatsFrame_SetGrey(self, r, g, b)
	if (not r) then
		r, g, b = 0.5, 0.5, 0.5
	end

	self.healthBar:SetStatusBarColor(r, g, b, 1)
	self.healthBar.bg:SetVertexColor(r, g, b, 0.5)
	if (self.manaBar) then
		self.manaBar:SetStatusBarColor(r, g, b, 1)
		self.manaBar.bg:SetVertexColor(r, g, b, 0.5)
	end
	self.greyMana = true
end

-- TPerl_SetChildMembers - Recursive
-- This iterates a frame's child frames and regions and assigns member variables
-- based on the sub-set part of the child's name compared to the parent frame name
function TPerl_SetChildMembers(self)
	local n = self:GetName()
	if (n) then
		local match = "^"..n.."(.+)$"

		local function AddList(list)
			for k, v in pairs(list) do
				local t = v:GetName()
				if (t) then
					local found = strmatch(t, match)
					if (found) then
						--if (self[found] == v) then
						--	break		-- Already done
						--end
						self[found] = v
					end
				end
			end
		end

		AddList({self:GetRegions()})

		local c = {self:GetChildren()}
		AddList(c, true)

		for k, v in pairs(c) do
			if (v:GetName()) then
				TPerl_SetChildMembers(v)
			end
			v:SetScript("OnLoad", nil)
		end

		self:SetScript("OnLoad", nil)
	end
end

do
	local shortlist
	local list
	local media

	-- TPerl_RegisterSMBarTextures
	function TPerl_RegisterSMBarTextures()
		if (LibStub) then
			media = LibStub("LibSharedMedia-3.0", true)
		end

		shortlist = {
			{"Perl v2", "Interface\\Addons\\TPerl\\Images\\TPerl_StatusBar"},
		}
		for i = 1, 9 do
			local name = i == 2 and "BantoBar" or "TPerl "..i
			tinsert(shortlist, {name, "Interface\\Addons\\TPerl\\Images\\TPerl_StatusBar"..(i + 1)})
		end

		if (media) then
			for k, v in pairs(shortlist) do
				media:Register("statusbar", v[1], v[2])
			end

			media:Register("border", "TPerl Thin", "Interface\\Addons\\TPerl\\Images\\TPerl_ThinEdge")
		end
	end

	-- TPerl_AllBarTextures
	function TPerl_AllBarTextures(short)
		if (not list) then
			if (short) then
				return shortlist
			end

			if (media) then
				list = { }
				local smlBars = media:List("statusbar")
				for k, v in pairs(smlBars) do
					tinsert(list, {v, media:Fetch("statusbar", v)})
				end
			else
				list = shortlist
			end
		end

		return list
	end
end

-- TPerl_GetBarTexture
function TPerl_GetBarTexture()
	return (conf and conf.bar and conf.bar.texture and conf.bar.texture[2]) or "Interface\\TargetingFrame\\UI-StatusBar"
end

-- TPerl_StatsFrame_Setup
function TPerl_StatsFrame_Setup(self)
	self:OnBackdropLoaded()
	TPerl_SetChildMembers(self)
	self.SetGrey = TPerl_StatsFrame_SetGrey
end

-- TPerl_GetClassColour
local defaultColour = {r = 0.5, g = 0.5, b = 1}
function TPerl_GetClassColour(class)
	return (class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]) or defaultColour
end

local hookedFrames = {}
local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

---------------------------------
--Loading Function             --
---------------------------------

-- TPerl_BlizzFrameDisable
function TPerl_BlizzFrameDisable(self)
	if not self then
		return
	end

	UnregisterUnitWatch(self)

	self:UnregisterAllEvents()

	if self == PlayerFrame then
		--[[local events = {
			"PLAYER_ENTERING_WORLD",
			"UNIT_ENTERING_VEHICLE",
			"UNIT_ENTERED_VEHICLE",
			"UNIT_EXITING_VEHICLE",
			"UNIT_EXITED_VEHICLE",
		}

		for i, event in pairs(events) do
			if pcall(self.RegisterEvent, self, event) then
				self:RegisterEvent(event)
			end
		end--]]

		if AlternatePowerBar then
			AlternatePowerBar:UnregisterAllEvents()
		end
	end

	if IsRetail and self == PartyFrame then
		for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
			TPerl_BlizzFrameDisable(frame)
		end
	end

	self:SetMovable(true)
	self:SetUserPlaced(true)
	self:SetDontSavePosition(true)
	self:SetMovable(false)

	if not InCombatLockdown() then
		self:Hide()
		self:SetParent(hiddenParent)
	end

	if not hookedFrames[self] then
		local ignoreParent
		hooksecurefunc(self, "SetParent", function()
			if ignoreParent then
				return
			end
			ignoreParent = true
			self:SetParent(hiddenParent)
			ignoreParent = nil
		end)

		hookedFrames[self] = true
	end

	local health = self.healthBar or self.healthbar or self.HealthBar
	if health then
		health:UnregisterAllEvents()
	end

	local power = self.manabar or self.ManaBar
	if power then
		power:UnregisterAllEvents()
	end

	local spell = self.castBar or self.spellbar or self.CastingBarFrame
	if spell then
		spell:UnregisterAllEvents()
	end

	local powerBarAlt = self.powerBarAlt or self.PowerBarAlt
	if powerBarAlt then
		powerBarAlt:UnregisterAllEvents()
	end

	local buffFrame = self.BuffFrame
	if buffFrame then
		buffFrame:UnregisterAllEvents()
	end

	local debuffFrame = self.DebuffFrame
	if debuffFrame then
		debuffFrame:UnregisterAllEvents()
	end

	local classPowerBar = self.classPowerBar
	if classPowerBar then
		classPowerBar:UnregisterAllEvents()
	end

	local ccRemoverFrame = self.CcRemoverFrame
	if ccRemoverFrame then
		ccRemoverFrame:UnregisterAllEvents()
	end

	local petFrame = self.petFrame or self.PetFrame
	if petFrame then
		petFrame:UnregisterAllEvents()
	end
end

	-- smoothColor (Midnight-safe)
	-- In Midnight, many unit-related values can become "secret" which cannot be used in math/logic.
	-- For Retail/Midnight, prefer UnitHealthPercent with a curve (secure path) and only fall back to
	-- numeric math when the value is accessible.
	local _tperlHealthColorCurve
	local function TPerl_GetHealthColorCurve()
		if not _tperlHealthColorCurve then
			local curve = C_CurveUtil.CreateColorCurve()
			curve:SetType(Enum.LuaCurveType.Linear)
			curve:AddPoint(0.0, CreateColor(1, 0, 0))
			curve:AddPoint(0.3, CreateColor(1, 1, 0))
			curve:AddPoint(0.7, CreateColor(0, 1, 0))
			_tperlHealthColorCurve = curve
		end
		return _tperlHealthColorCurve
	end

	local function TPerl_RGBFromColor(c)
		if not c then
			return nil
		end
		if type(c) == "table" then
			if c.GetRGB then
				local r, g, b = c:GetRGB()
				return r, g, b, c
			elseif c.r ~= nil then
				return c.r, c.g, c.b, c
			elseif c[1] ~= nil then
				return c[1], c[2], c[3], c
			end
		elseif type(c) == "userdata" and c.GetRGB then
			local r, g, b = c:GetRGB()
			return r, g, b, c
		end
		return nil
	end

	local function smoothColor(percentage, partyid)
		local r, g, b, color

		-- Classic branch expects a numeric percentage (0..1); guard against secret values
		if not IsRetail then
			if not TPerl_CanAccess(percentage) then
				return 1, 1, 1
			end
			if (percentage < 0.5) then
				r = 1
				g = min(1, max(0, 2 * percentage))
				b = 0
			else
				g = 1
				r = min(1, max(0, 2 * (1 - percentage)))
				b = 0
			end
			return r, g, b
		end

		-- Retail/Midnight: do NOT do any math on potentially secret 'percentage'. Use secure API when possible.
		local curve = TPerl_GetHealthColorCurve()

		-- If we have a valid unit token, let the secure API compute the value (safe even when health is secret).
		if partyid and UnitExists(partyid) then
			local result = UnitHealthPercent(partyid, false, curve)
			r, g, b, color = TPerl_RGBFromColor(result)
			if r then
				return r, g, b, color
			end
		end

		-- Fallback: only if the numeric percentage is accessible (e.g. threat scaledPercent)
		if TPerl_CanAccess(percentage) then
			local p = percentage
			-- Some call-sites feed 0..100 (e.g. threat scaledPercent)
			if p > 1 then
				p = p / 100
			end
			p = min(1, max(0, p))
			local result = curve:Evaluate(p)
			r, g, b, color = TPerl_RGBFromColor(result)
			if r then
				return r, g, b, color
			end
		end

		-- Final fallback: neutral (avoid errors)
		return 1, 1, 1
	end

---------------------------------
--Smooth Health Bar Color      --
---------------------------------
function TPerl_SetSmoothBarColor(self, percentage)
	if (self) then
		local r, g, b
		if (conf.colour.classic) then
			r, g, b = smoothColor(percentage, self.partyid)
		else
			local c = conf.colour.bar
			local pct = percentage
				-- Some call sites (notably RaidHelper during secure header updates) can call
				-- with a nil/unknown percentage. math.max/min will error on nil, so default.
				if pct == nil then
					pct = 1
				end
			if not TPerl_CanAccess(pct) then
				pct = 1
			elseif pct > 1 then
				pct = pct / 100
			end
			pct = min(1, max(0, pct))
			r = min(1, max(0, c.healthEmpty.r + ((c.healthFull.r - c.healthEmpty.r) * pct)))
			g = min(1, max(0, c.healthEmpty.g + ((c.healthFull.g - c.healthEmpty.g) * pct)))
			b = min(1, max(0, c.healthEmpty.b + ((c.healthFull.b - c.healthEmpty.b) * pct)))
		end

  if not IsRetail then
 		self:SetStatusBarColor(r, g, b)
		else
		 --TODO: find a way to just actually color the bar keeping the texture.
		 --self:GetStatusBarTexture():SetVertexColor(r, g, b)
			local curve = C_CurveUtil.CreateColorCurve()
			curve:SetType(Enum.LuaCurveType.Linear)
			curve:AddPoint(0.0, CreateColor(1, 0, 0))
			curve:AddPoint(0.3, CreateColor(1, 1, 0))
			curve:AddPoint(0.7, CreateColor(0, 1, 0))

				-- NOTE: UnitHealthPercent requires a valid unit token. Some bar objects can be created
				-- before partyid is populated, so guard this call.
				if self.partyid and UnitExists(self.partyid) then
					local _ = UnitHealthPercent(self.partyid, false, curve)
				end
		end
		
		if (self.bg) then
			self.bg:SetVertexColor(r, g, b, 0.25)
		end
	end
end

local barColours
function TPerl_ResetBarColourCache()
	barColours = setmetatable({ }, {
		__index = function(self, k)
			local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[k]
			if (c) then
				if (not conf.colour.classbarBright) then
					conf.colour.classbarBright = 1
				end
				self[k] = {
					r = max(0, min(1, c.r * conf.colour.classbarBright)),
					g = max(0, min(1, c.g * conf.colour.classbarBright)),
					b = max(0, min(1, c.b * conf.colour.classbarBright))
				}
				return self[k]
			end
		end
	})
end
TPerl_ResetBarColourCache()

-- TPerl_ColourHealthBar
function TPerl_ColourHealthBar(self, healthPct)
	if (not partyid) then
		partyid = self.partyid
	end
	local bar = self.statsFrame.healthBar
	bar.partyid = partyid
	if (--[[string.find(partyid, "raid") and ]]conf.colour.classbar and UnitIsPlayer(partyid)) then
		local _, class = UnitClass(partyid)
		if (class) then
			local c = barColours[class]
			if (c) then
				bar:SetStatusBarColor(c.r, c.g, c.b)
				if (bar.bg) then
					bar.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
				end
				return
			end
		end
	end

 --Fix AFK Bug. Check Done in incorrect spot. Will likely move later.
 if TPerl_SafeBool(UnitIsAFK(partyid)) then
		bar:SetStatusBarColor(0.2, 0.2, 0.2, 0.7)
	else
		if not conf.colour.bar.healthFull then
			conf.colour.bar.healthFull = { }
			conf.colour.bar.healthFull.r = 0
			conf.colour.bar.healthFull.g = 1
			conf.colour.bar.healthFull.b = 0
			conf.colour.bar.healthFull.a = 1
		end

		bar:SetStatusBarColor(conf.colour.bar.healthFull.r, conf.colour.bar.healthFull.g, conf.colour.bar.healthFull.b, conf.colour.bar.healthFull.a)
	end
 
	TPerl_SetSmoothBarColor(bar, healthPct)
end
--local TPerl_ColourHealthBar = TPerl_ColourHealthBar

-- TPerl_SetValuedText
function TPerl_SetValuedText(self, unitHealth, unitHealthMax, suffix)
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		if unitHealthMax >= 1000000000000 then
			if abs(unitHealth) >= 1000000000000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000000000, veryhugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000000 then
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 10000, hugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 1000000000 then
			if abs(unitHealth) >= 1000000000 then
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000000 then
				self:SetFormattedText("%.2f%s/%.1f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.1f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 100000000 then
			if abs(unitHealth) >= 100000000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 1000000 then
			if abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 10000, largeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 10000, largeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.1f%s%s", unitHealth, unitHealthMax / 10000, largeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 100000 then
			if abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 10000, largeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 10000, largeNumTag, suffix or "")
			end
		else
			self:SetFormattedText("%d/%d%s", unitHealth, unitHealthMax, suffix or "")
		end
	else
	 if not IsRetail then
				if unitHealthMax >= 1000000000 then
					if abs(unitHealth) >= 1000000000 then
						-- 1.23G/1.23G
						self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000000, veryhugeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
					elseif abs(unitHealth) >= 10000000 then
						-- 12.3M/1.23G
						self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
					elseif abs(unitHealth) >= 1000000 then
						-- 1.23M/1.23G
						self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
					elseif abs(unitHealth) >= 100000 then
						-- 123.4K/1.23G
						self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
					else
						-- 12345/1.23G
						self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
					end
				elseif unitHealthMax >= 10000000 then
					if abs(unitHealth) >= 10000000 then
						-- 12.3M/12.3M
						self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
					elseif abs(unitHealth) >= 1000000 then
						-- 1.23M/12.3M
						self:SetFormattedText("%.2f%s/%.1f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
					elseif abs(unitHealth) >= 100000 then
						-- 123.4K/12.3M
						self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
					else
						-- 12345/12.3M
						self:SetFormattedText("%d/%.1f%s%s", unitHealth, unitHealthMax / 1000000, hugeNumTag, suffix or "")
					end
				elseif unitHealthMax >= 1000000 then
					if abs(unitHealth) >= 1000000 then
						-- 1.23M/1.23M
						self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
					elseif abs(unitHealth) >= 100000 then
						-- 123.4K/1.23M
						self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
					else
						-- 12345/1.23M
						self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 1000000, hugeNumTag, suffix or "")
					end
				elseif unitHealthMax >= 100000 then
					if abs(unitHealth) >= 100000 then
						-- 123.4K/123.4K
						self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000, largeNumTag, suffix or "")
					else
						-- 12345/123.4K
						self:SetFormattedText("%d/%.1f%s%s", unitHealth, unitHealthMax / 1000, largeNumTag, suffix or "")
					end
				else
					-- 12345/12345
					self:SetFormattedText("%d/%d%s", unitHealth, unitHealthMax, suffix or "")
				end
		else
		  --print("Set: " .. AbbreviateNumbers(unitHealth) .. "/" .. AbbreviateNumbers(unitHealthMax) .. (suffix or ""))
		  self:SetText(AbbreviateNumbers(unitHealth) .. "/" .. AbbreviateNumbers(unitHealthMax) .. (suffix or ""))
		end
	end
end
local SetValuedText = TPerl_SetValuedText

-- TPerl_SetHealthBar
function TPerl_SetHealthBar(self, hp, Max, hpInverse)
	local bar = self.statsFrame.healthBar
	bar:SetMinMaxValues(0, Max)
	
	local percent
	if not IsRetail then
		if hp >= 1 and Max == 0 then -- For some dumb reason max HP is 0, normal HP is not, so lets use normal HP as max
			Max = hp
			percent = 1
		elseif hp == 0 and Max == 0 then -- Both are 0, so it's probably dead since usually current HP returns correctly when Max HP fails.
			percent = 0
		else
			percent = hp / Max
		end
		if percent > 1 then percent = 1 end -- percent only goes to 100
		if (conf.bar.inverse) then
			bar:SetValue(hpInverse)
			bar.tex:SetTexCoord(0, max(0,(1 - percent)), 0, 1)
		else
			bar:SetValue(hp)
			bar.tex:SetTexCoord(0, max(0, percent), 0, 1)
		end
	else
	 percent = UnitHealthPercent(self.partyid)
	 percent100 = UnitHealthPercent(self.partyid, false, CurveConstants.ScaleTo100)
		if (conf.bar.inverse) then
			bar:SetValue( hpInverse)
			bar.tex:SetTexCoord(0, hpInverse, 0, 1)
		else
			bar:SetValue(hp)
			bar.tex:SetTexCoord(0, percent, 0, 1)
		end
		
	end

 --TODO: STOP using the below function or update it to color curves.
	TPerl_ColourHealthBar(self, percent)
	
 --Percent Display.
	if (bar.percent) then
	  --if not IsRetail then
					if (self.conf.healerMode and self.conf.healerMode.enable and self.conf.healerMode.type == 2) then
									--bar.percent:SetText(hp - Max)
									if not IsRetail then	
													local health = hp - Max
													local locale = GetLocale()
													if locale == "zhCN" or locale == "zhTW" then
																	if (abs(health) >= 1000000000000) then
																		bar.percent:SetFormattedText("%.0f%s", health / 1000000000000, veryhugeNumTag)
																	elseif (abs(health) >= 100000000) then
																		bar.percent:SetFormattedText("%.0f%s", health / 100000000, hugeNumTag)
																	elseif (abs(health) >= 1000000) then
																		bar.percent:SetFormattedText("%.0f%s", health / 10000, largeNumTag)
																	elseif (abs(health) >= 1000) then
																		bar.percent:SetFormattedText("%.1f%s", health / 10000, largeNumTag)
																	else
																		bar.percent:SetFormattedText("%d", health)
																	end
													else
																	if (abs(health) >= 10000000000) then
																		bar.percent:SetFormattedText("%.0f%s", health / 1000000000, veryhugeNumTag)
																	elseif (abs(health) >= 1000000000) then
																		bar.percent:SetFormattedText("%.1f%s", health / 1000000000, veryhugeNumTag)
																	elseif (abs(health) >= 10000000) then
																		bar.percent:SetFormattedText("%.0f%s", health / 1000000, hugeNumTag)
																	elseif (abs(health) >= 1000000) then
																		bar.percent:SetFormattedText("%.1f%s", health / 1000000, hugeNumTag)
																	elseif (abs(health) >= 10000) then
																		bar.percent:SetFormattedText("%.0f%s", health / 1000, largeNumTag)
																	elseif (abs(health) >= 1000) then
																		bar.percent:SetFormattedText("%.1f%s", health / 1000, largeNumTag)
																	else
																		bar.percent:SetFormattedText("%d", health)
																	end
													end
									else
													-- unsure what this does yet.
													-- Blizz may have nuked this and the setting for hp display might be handled in the client settings.
													-- TODO: Investigate.
													local health = hp
													bar.percent:SetFormattedText("%d", health)
									end
					else
									if not IsRetail then
													-- Can only do math outside of retail.
													local show = percent * 100
													if (show < 10) then
																	bar.percent:SetFormattedText(perc1F or "%.1f%%", percent == 1 and 100 or show + 0.05)
													else
																	bar.percent:SetFormattedText(percD or "%d%%", percent == 1 and 100 or show + 0.5)
													end
									else
													-- Otherwise we have to trust blizzard.
													-- also it should already be in range of 0 to 100
													local show = percent100
														-- Cant do show math.
													bar.percent:SetFormattedText(percD or "%d%%", percent100)
									end
					end
					
					-- End Not isRetail
				--else
				 
			--end
	end

	if (bar.text) then
					local hbt = bar.text
						--if not IsRetail then		
							if (self.conf.healerMode.enable and self.conf.healerMode.type ~= 2) then
										if not IsRetail then
														local health = hp - Max
														if (self.conf.healerMode.type == 1) then
																		SetValuedText(hbt, health, Max)
														else
																		local locale = GetLocale()
																		if locale == "zhCN" or locale == "zhTW" then
																					if (abs(health) >= 1000000000000) then
																						hbt:SetFormattedText("%.2f%s", health / 1000000000000, veryhugeNumTag)
																					elseif (abs(health) >= 1000000000) then
																						hbt:SetFormattedText("%.0f%s", health / 100000000, hugeNumTag)
																					elseif (abs(health) >= 100000000) then
																						hbt:SetFormattedText("%.1f%s", health / 100000000, hugeNumTag)
																					elseif (abs(health) >= 1000000) then
																						hbt:SetFormattedText("%.0f%s", health / 10000, largeNumTag)
																					elseif (abs(health) >= 100000) then
																						hbt:SetFormattedText("%.1f%s", health / 10000, largeNumTag)
																					else
																						hbt:SetFormattedText("%d", health)
																					end
																		else
																						if (abs(health) >= 1000000000) then
																							hbt:SetFormattedText("%.2f%s", health / 1000000000, veryhugeNumTag)
																						elseif (abs(health) >= 10000000) then
																							hbt:SetFormattedText("%.1f%s", health / 1000000, hugeNumTag)
																						elseif (abs(health) >= 1000000) then
																							hbt:SetFormattedText("%.2f%s", health / 1000000, hugeNumTag)
																						elseif (abs(health) >= 100000) then
																							hbt:SetFormattedText("%.1f%s", health / 1000, largeNumTag)
																						else
																							hbt:SetFormattedText("%d", health)
																						end
																		end
														end
										else
														SetValuedText(hbt, hp, Max)
										end
							else
							    --if IsRetail then
											   SetValuedText(hbt, hp, Max)
											--end
					  end
					--end
	end
	--TPerl_SetExpectedHealth(self)
end

---------------------------------
--Class Icon Location Functions--
---------------------------------
--local ClassPos = {
--	WARRIOR	= {0,    0.25,    0,	0.25},
--	MAGE	= {0.25, 0.5,     0,	0.25},
--	ROGUE	= {0.5,  0.75,    0,	0.25},
--	DRUID	= {0.75, 1,       0,	0.25},
--	HUNTER	= {0,    0.25,    0.25,	0.5},
--	SHAMAN	= {0.25, 0.5,     0.25,	0.5},
--	PRIEST	= {0.5,  0.75,    0.25,	0.5},
--	WARLOCK	= {0.75, 1,       0.25,	0.5},
--	PALADIN	= {0,    0.25,    0.5,	0.75},
--	none	= {0.25, 0.5, 0.5, 0.75},
--}
--function TPerl_ClassPos(class)
--	return unpack(ClassPos[class] or ClassPos.none)
--end

local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS
function TPerl_ClassPos(unitClass)
	local b = CLASS_ICON_TCOORDS[unitClass]		-- Now using the Blizzard supplied from FrameXML/WorldStateFrame.lua
	if (b) then
		return unpack(b)
	end
	return 0.25, 0.5, 0.5, 0.75
end

-- TPerl_Toggle
function TPerl_Toggle()
	if (TPerlLocked == 1) then
		TPerl_UnlockFrames()
	else
		TPerl_LockFrames()
	end
end

-- TPerl_UnlockFrames
function TPerl_UnlockFrames()
	TPerl_LoadOptions()

	TPerlLocked = 0

	if (TPerl_Party_Virtual) then
		TPerl_Party_Virtual(true)
	end

	if (TPerl_Player_Pet_Virtual) then
		TPerl_Player_Pet_Virtual(true)
	end

	if (TPerl_AggroAnchor) then
		TPerl_AggroAnchor:Enable()
	end

	--[[if (TPerl_Player) then
		if (TPerl_Player.runes and not InCombatLockdown()) then
			TPerl_Player.runes:EnableMouse(true)
		end
	end]]

	if (TPerl_Options) then
		TPerl_Options:Show()
		TPerl_Options:SetAlpha(0)
		TPerl_Options.Fading = "in"
	end

	if (TPerl_RaidTitles) then
		TPerl_RaidTitles()
		if (TPerl_RaidPets_Titles) then
			TPerl_RaidPets_Titles()
		end
	end
end

-- TPerl_LockFrames
function TPerl_LockFrames()
	TPerlLocked = 1
	if (TPerl_Options) then
		TPerl_Options.Fading = "out"
	end

	if (TPerl_Party_Virtual) then
		TPerl_Party_Virtual()
	end

	if (TPerl_Player_Pet_Virtual) then
		TPerl_Player_Pet_Virtual()
	end

	if (TPerl_AggroAnchor) then
		TPerl_AggroAnchor:Disable()
	end

	--[[if (TPerl_Player) then
		if (TPerl_Player.runes and not InCombatLockdown()) then
			TPerl_Player.runes:EnableMouse(false)
		end
	end]]

	if (TPerl_RaidTitles) then
		TPerl_RaidTitles()
		if (TPerl_RaidPets_Titles) then
			TPerl_RaidPets_Titles()
		end
	end

	TPerl_OptionActions()
end

-- Minimap Icon
function TPerl_MinimapButton_OnClick(self, button)
	GameTooltip:Hide()
	if (button == "LeftButton") then
		TPerl_Toggle()
	elseif (button == "RightButton") then
		TPerl_MinimapMenu(self)
	end
end

-- TPerl_MinimapMenu_OnLoad
function TPerl_MinimapMenu_OnLoad(self)
	local dropdown = MSA_DropDownMenu_Create(self:GetName().."_DropDown", self)
	dropdown.displayMode = "MENU"
	dropdown:SetAllPoints(self)
	MSA_DropDownMenu_Initialize(dropdown, TPerl_MinimapMenu_Initialize)
end

-- TPerl_MinimapMenu_Initialize
function TPerl_MinimapMenu_Initialize(self, level)
	local info

	if (level == 2) then
		return
	end

	info = MSA_DropDownMenu_CreateInfo()
	info.isTitle = 1
	info.text = TPerl_ProductName
	MSA_DropDownMenu_AddButton(info)

	info = MSA_DropDownMenu_CreateInfo()
	info.notCheckable = 1
	info.func = TPerl_Toggle
	info.text = TPERL_MINIMENU_OPTIONS
	MSA_DropDownMenu_AddButton(info)

	if (C_AddOns.IsAddOnLoaded("TPerl_RaidHelper")) then
		if (TPerl_Assists_Frame and not TPerl_Assists_Frame:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = TPERL_MINIMENU_ASSIST
			info.func = function()
					TPerlConfigHelper.AssistsFrame = 1
					TPerlConfigHelper.TargettingFrame = 1
					TPerl_SetFrameSides()
				end
			MSA_DropDownMenu_AddButton(info)
		end
	end

	if (C_AddOns.IsAddOnLoaded("TPerl_RaidMonitor")) then
		if (TPerl_RaidMonitor_Frame and not TPerl_RaidMonitor_Frame:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = TPERL_MINIMENU_CASTMON
			info.func = function()
				TPerlRaidMonConfig.enabled = 1
				TPerl_RaidMonitor_Frame:SetFrameSizes()
			end
			MSA_DropDownMenu_AddButton(info)
		end
	end

	if (C_AddOns.IsAddOnLoaded("TPerl_RaidAdmin")) then
		if (TPerl_AdminFrame and not TPerl_AdminFrame:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = TPERL_MINIMENU_RAIDAD
			info.func = function() TPerl_AdminFrame:Show() end
			MSA_DropDownMenu_AddButton(info)
		end

		if (TPerl_Check and not TPerl_Check:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = TPERL_MINIMENU_ITEMCHK
			info.func = function() TPerl_Check:Show() end
			MSA_DropDownMenu_AddButton(info)
		end

		if (TPerl_RosterText and not TPerl_RosterText:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = TPERL_MINIMENU_ROSTERTEXT
			info.func = function() TPerl_RosterText:Show() end
			MSA_DropDownMenu_AddButton(info)
		end
	end
end

-- TPerl_MinimapMenu
function TPerl_MinimapMenu(self)
	if (not TPerl_Minimap) then
		CreateFrame("Frame", "TPerl_Minimap", nil, BackdropTemplateMixin and "BackdropTemplate")
		TPerl_MinimapMenu_OnLoad(TPerl_Minimap)
	end

	MSA_ToggleDropDownMenu(1, nil, TPerl_Minimap_DropDown, "cursor", 0, 0)
end

local xpModList = {"TPerl", "TPerl_Player", "TPerl_PlayerBuffs", "TPerl_PlayerPet", "TPerl_Target", "TPerl_TargetTarget", "TPerl_Party", "TPerl_PartyPet", "TPerl_ArcaneBar", "TPerl_RaidFrames", "TPerl_RaidHelper", "TPerl_RaidAdmin", "TPerl_RaidMonitor", "TPerl_RaidPets"}
local xpStartupMemory = {}

-- TPerl_MinimapButton_Init
function TPerl_MinimapButton_Init(self)
	--self.time = 0
	collectgarbage()
	UpdateAddOnMemoryUsage()
	local totalKB = 0
	for k, v in pairs(xpModList) do
		local usedKB = GetAddOnMemoryUsage(v)
		if ((usedKB or 0) > 0) then
			xpStartupMemory[v] = usedKB
		end
	end

	TPerl_MinimapButton_UpdatePosition(self)

	if (conf.minimap.enable) then
		self:Show()
	else
		self:Hide()
	end

	--self.UpdateTooltip = TPerl_MinimapButton_OnEnter

	TPerl_MinimapButton_Init = nil
end

-- TPerl_MinimapButton_UpdatePosition
function TPerl_MinimapButton_UpdatePosition(self)
	if (not conf.minimap.radius) then
		if IsRetail then
			conf.minimap.radius = 101
		else
			conf.minimap.radius = 78
		end
	end
	self:ClearAllPoints()
	if IsRetail then
		self:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 80 - (conf.minimap.radius * cos(conf.minimap.pos)), (conf.minimap.radius * sin(conf.minimap.pos)) - 82)
	else
		self:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 54 - (conf.minimap.radius * cos(conf.minimap.pos)), (conf.minimap.radius * sin(conf.minimap.pos)) - 55)
	end
end

-- TPerl_MinimapButton_Dragging
function TPerl_MinimapButton_Dragging(self, elapsed)
	local xpos, ypos = GetCursorPosition()
	local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin - xpos / UIParent:GetScale() + 70
	ypos = ypos / UIParent:GetScale() - ymin - 70

	if (IsAltKeyDown()) then
		local radius = (xpos ^ 2 + ypos ^ 2) ^ 0.5
		if (radius < 78) then
			radius = 78
		end
		if (radius > 148) then
			radius = 148
		end
		conf.minimap.radius = radius
		end

	local angle = deg(atan2(ypos, xpos))
	if (angle < 0) then
		angle = angle + 360
	end
	conf.minimap.pos = angle

	TPerl_MinimapButton_UpdatePosition(self)
end

-- DiffColour(diff, val)
local function DiffColour(val)
	local r, g, b, offset
	offset = max(0, min(0.5, 0.5 * min(1, val)))
	if (val < 0) then
		r = 0.5 + offset
		g = 0.5 - offset
		b = r
	else
		r = 0.5 + offset
		g = 0.5 - offset
		b = g
	end
	return format("|c00%02X%02X%02X", 255 * r, 255 * g, 255 * b)
end

-- TPerl_MinimapButton_OnEnter
function TPerl_MinimapButton_OnEnter(self)
	if (self.dragging) then
		return
	end

	GameTooltip:SetOwner(self or UIParent, "ANCHOR_LEFT")
	TPerl_MinimapButton_Details(GameTooltip)
end

-- TPerl_MinimapButton_Details
function TPerl_MinimapButton_Details(tt, ldb)
	tt:SetText(TPerl_Version.." "..TPerl_GetRevision(), 1, 1, 1)
	tt:AddLine(TPERL_MINIMAP_HELP1)
	if (not ldb) then
		tt:AddLine(TPERL_MINIMAP_HELP2)
	end
	if UpdateAddOnMemoryUsage then
		if (IsAltKeyDown()) then
			tt:AddLine(TPERL_MINIMAP_HELP6)
		elseif (not IsShiftKeyDown()) then
			tt:AddLine(TPERL_MINIMAP_HELP5)
		end
	end
	--GetRealNumRaidMembers doesn't exist anymore in 5.0.4
	--[==[if (GetRealNumRaidMembers) then
		if (GetNumGroupMembers() > 0 and GetRealNumRaidMembers() > 0) then
			if (select(2, IsInInstance()) == "pvp") then
				tt:AddLine(format(TPERL_MINIMAP_HELP3, GetRealNumRaidMembers(), GetNumSubgroupMembers(LE_PARTY_CATEGORY_HOME)))

				if (IsRealPartyLeader()) then
					tt:AddLine(TPERL_MINIMAP_HELP4)
				end
			end
		end
	end]==]

	if UpdateAddOnMemoryUsage and IsAltKeyDown() then
		local showDiff = IsShiftKeyDown()

		local allAddonsCPU = 0
		for i = 1, GetNumAddOns() do
			allAddonsCPU = allAddonsCPU + GetAddOnCPUUsage(i)
		end

		-- Show TPerl memory usage
		UpdateAddOnMemoryUsage()
		UpdateAddOnCPUUsage()
		local totalKB, totalCPU, diffKB, diff = 0, 0, 0
		local cpuText = ""
		for k, v in pairs(xpModList) do
			local usedKB = GetAddOnMemoryUsage(v)
			local usedCPU = GetAddOnCPUUsage(v)
			if ((usedKB or 0) > 0) then
				totalKB = totalKB + usedKB
				totalCPU = totalCPU + usedCPU

				if (allAddonsCPU > 0) then
					cpuText = format(" |c008080FF%.2f%%|r", 100 * (usedCPU / allAddonsCPU))
				end

				if (showDiff) then
					diff = usedKB - xpStartupMemory[v]
					diffKB = diffKB + diff
					tt:AddDoubleLine(format(" %s", v), format("%.1fkB (%s%.1fkB|r)%s", usedKB, DiffColour(diff / 1000), diff, cpuText), 1, 1, 0.5, 1, 1, 1)
				else
					tt:AddDoubleLine(format(" %s", v), format("%.1fkB%s", usedKB, cpuText), 1, 1, 0.5, 1, 1, 1)
				end
			end
		end

		if (showDiff) then
			local color = DiffColour(diffKB / 3000)

			tt:AddDoubleLine("Total", format("%.1fkB (%s%.1fkB|r)", totalKB, color, diffKB), 1, 1, 1, 1, 1, 1)
		else
			tt:AddDoubleLine("Total", format("%.1fkB", totalKB), 1, 1, 1, 1, 1, 1)
		end

		local usedKB = GetAddOnMemoryUsage("TPerl_Options")
		if ((usedKB or 0) > 0) then
			tt:AddDoubleLine(" TPerl_Options", format("%.1fkB", usedKB), 0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
		end

		if (totalCPU > 0) then
			tt:AddDoubleLine(" TPerl CPU Usage Comparison", format("%.2f%%", 100 * (totalCPU / allAddonsCPU)), 0.5, 0.5, 1, 0.5, 0.5, 1)
		end
	end

	tt:Show()
	--tt.updateTooltip = 1
end

function TPerl_GetDisplayedPowerType(unitID)
	local barInfo = not IsClassic and GetUnitPowerBarInfo(unitID)
	if barInfo and barInfo.showOnRaid and UnitHasVehicleUI(unitID) and (UnitInParty(unitID) or UnitInRaid(unitID)) then
		return ALTERNATE_POWER_INDEX
	else
		return UnitPowerType(unitID) or 0
	end
end

local ManaColours = {
	[Enum.PowerType.Mana] = "mana",
	[Enum.PowerType.Rage] = "rage",
	[Enum.PowerType.Focus] = "focus",
	[Enum.PowerType.Energy] = "energy",
	[Enum.PowerType.Runes] = "runes",
	[Enum.PowerType.RunicPower] = "runic_power",
	[Enum.PowerType.Insanity] = "insanity",
	[Enum.PowerType.LunarPower] = "lunar",
	[Enum.PowerType.Maelstrom] = "maelstrom",
	[Enum.PowerType.Fury] = "fury",
	[Enum.PowerType.Pain] = "pain",
	[Enum.PowerType.Alternate] = "energy", -- used by some bosses, show it as energy bar
}

-- TPerl_SetManaBarType
function TPerl_SetManaBarType(self)
	local m = self.statsFrame.manaBar
	if (m and not self.statsFrame.greyMana) then
		local unit = self.partyid -- SecureButton_GetUnit(self)
		if not unit then
			self.targetmanatype = 0
			return
		end
		if (unit) then
			local p = TPerl_GetDisplayedPowerType(unit)
			self.targetmanatype = p
			if (p) then
				local c = conf.colour.bar[ManaColours[p]]
				if (c) then
					m:SetStatusBarColor(c.r, c.g, c.b, 1)
					m.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
				end
			end
		end
	end
end

-- TPerl_TooltipModiferPressed
function TPerl_TooltipModiferPressed(buffs)
	local mod, ic
	if (buffs) then
		if (not conf.tooltip.enableBuffs) then
			return
		end
		mod = conf.tooltip.buffModifier
		ic = conf.tooltip.buffHideInCombat
	else
		if (not conf.tooltip.enable) then
			return
		end
		mod = conf.tooltip.modifier
		ic = conf.tooltip.hideInCombat
	end

	if (mod == "alt") then
		mod = IsAltKeyDown()
	elseif (mod == "shift") then
		mod = IsShiftKeyDown()
	elseif (mod == "control") then
		mod = IsControlKeyDown()
	else
		mod = true
	end

	mod = mod and (not ic or not InCombatLockdown())

	return mod
end

-- TPerl_PlayerTip
function TPerl_PlayerTip(self, unitid)
	if (not unitid) then
		unitid = SecureButton_GetUnit(self)
	end

	if (not unitid or TPerlLocked == 0) then
		return
	end

	if (not TPerl_TooltipModiferPressed()) then
		return
	end

	if (SpellIsTargeting()) then
		if (SpellCanTargetUnit(unitid)) then
			SetCursor("CAST_CURSOR")
		else
			SetCursor("CAST_ERROR_CURSOR")
		end
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(unitid)
	local r, g, b = GameTooltip_UnitColor(unitid)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
	GameTooltip:Show()

	if (TPerl_RaidTipExtra) then
		TPerl_RaidTipExtra(unitid)
	end

	TPerl_Highlight:TooltipInfo(UnitName(unitid))
end

-- TPerl_PlayerTipHide
function TPerl_PlayerTipHide()
	if (conf.tooltip.fading) then
		GameTooltip:FadeOut()
	else
		GameTooltip:Hide()
	end
end

-- TPerl_ColourFriendlyUnit
function TPerl_ColourFriendlyUnit(self, partyid)
	local color
	if (UnitCanAttack("player", partyid) and UnitIsEnemy("player", partyid)) then	-- For dueling
		color = conf.colour.reaction.enemy
	else
		if (conf.colour.class) then
			local _, class = UnitClass(partyid)
			color = TPerl_GetClassColour(class)
		else
			if (UnitIsPVP(partyid)) then
				color = conf.colour.reaction.friend
			else
				color = conf.colour.reaction.none
			end
		end
	end

	self:SetTextColor(color.r, color.g, color.b, conf.transparency.text)
end

-- TPerl_ReactionColour
function TPerl_ReactionColour(argUnit)
	if (UnitPlayerControlled(argUnit) or not UnitIsVisible(argUnit)) then
		if (UnitFactionGroup("player") == UnitFactionGroup(argUnit)) then
			if (UnitIsEnemy("player", argUnit)) then
				-- Dueling
				return conf.colour.reaction.enemy
			elseif (UnitIsPVP(argUnit)) then
				return conf.colour.reaction.friend
			end
		else
			if (UnitIsPVP(argUnit)) then
				if (UnitIsPVP("player")) then
					return conf.colour.reaction.enemy
				else
					return conf.colour.reaction.neutral
				end
			end
		end
	else
		if UnitIsTapDenied(argUnit) and not UnitIsFriend("player", argUnit) then
			return conf.colour.reaction.tapped
		else
			local reaction = UnitReaction(argUnit, "player")
			if (reaction) then
				if (reaction >= 5) then
					return conf.colour.reaction.friend
				elseif (reaction <= 2) then
					return conf.colour.reaction.enemy
				elseif (reaction == 3) then
					return conf.colour.reaction.unfriendly
				else
					return conf.colour.reaction.neutral
				end
			else
				if (UnitFactionGroup("player") == UnitFactionGroup(argUnit)) then
					return conf.colour.reaction.friend
				elseif (UnitIsEnemy("player", argUnit)) then
					return conf.colour.reaction.enemy
				else
					return conf.colour.reaction.neutral
				end
			end
		end
	end

	return conf.colour.reaction.none
end

-- TPerl_SetUnitNameColor
function TPerl_SetUnitNameColor(self, unit)
	local color
	if (UnitIsPlayer(unit) or not UnitIsVisible(unit)) then -- Changed UnitPlayerControlled to UnitIsPlayer for 2.3.5
		-- 1.8.3 - Changed to override pvp name colours
		if (conf.colour.class) then
			local _, class = UnitClass(unit)
			color = TPerl_GetClassColour(class)
		else
			color = TPerl_ReactionColour(unit)
		end
	else
		if UnitIsTapDenied(unit) and not UnitIsFriend("player", unit) then
			color = conf.colour.reaction.tapped
		else
			color = TPerl_ReactionColour(unit)
		end
	end

	self:SetTextColor(color.r, color.g, color.b, conf.transparency.text)
end

-- TPerl_CombatFlashSet
function TPerl_CombatFlashSet(self, elapsed, argNew, argGreen)
	if (not conf.combatFlash) then
		self.PlayerFlash = nil
		return
	end

	if (self) then
		if (argNew) then
			self.PlayerFlash = 1.2 -- Old value: 1.5
			self.PlayerFlashGreen = argGreen
		else
			if (elapsed and self.PlayerFlash) then
				self.PlayerFlash = self.PlayerFlash - elapsed

				if (self.PlayerFlash <= 0) then
					self.PlayerFlash = 0
					self.PlayerFlashGreen = nil
				end
			else
				return
			end
		end

		return true
	end
end

-- TPerl_CombatFlashSetFrames
function TPerl_CombatFlashSetFrames(self)
	if (self.PlayerFlash) then
		local baseColour = self.forcedColour or conf.colour.border

		local r, g, b, a
		if (self.PlayerFlash > 0) then
			local flashOffsetColour = min(self.PlayerFlash, 1) / 2
			if (self.PlayerFlashGreen) then
				r = min(1, max(0, baseColour.r - flashOffsetColour))
				g = min(1, max(0, baseColour.g + flashOffsetColour))
			else
				r = min(1, max(0, baseColour.r + flashOffsetColour))
				g = min(1, max(0, baseColour.g - flashOffsetColour))
			end
			b = min(1, max(0, baseColour.b - flashOffsetColour))
			a = min(1, max(0, baseColour.a + flashOffsetColour))
		else
			r, g, b, a = baseColour.r, baseColour.g, baseColour.b, baseColour.a
			self.PlayerFlash = false
		end

		for i = 1, #self.FlashFrames do
			self.FlashFrames[i]:SetBackdropBorderColor(r, g, b, a)
		end
	end
end

local MagicCureTalentsClassic = {
	["PALADIN"] = 4987, -- Clense
}

local MagicCureTalents = {
	["DRUID"] = 4, -- Resto
	["PALADIN"] = 1, -- Holy
	["SHAMAN"] = 3, -- Resto
	["MONK"] = 2, -- Mistweaver
	["EVOKER"] = 2 -- Preservation
}

local function CanClassCureMagic(class)
	if (MagicCureTalents[class]) then
		return not IsClassic and GetSpecialization() == MagicCureTalents[class] or (MagicCureTalentsClassic[class] and IsSpellKnown(MagicCureTalentsClassic[class]))
	end
end

local getShow
function TPerl_DebufHighlightInit()
	-- We also re-set the colours here so that we highlight best colour per class
	if (playerClass == "MAGE") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Curse or show
		end
	elseif (playerClass == "DRUID") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Curse or Curses.Poison or magic or show
		end
	elseif (playerClass == "PRIEST") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Magic or Curses.Disease or show
		end
	elseif (playerClass == "WARLOCK") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Magic or show
		end
	elseif (playerClass == "MONK") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Poison or Curses.Disease or magic or show
		end
	elseif (playerClass == "PALADIN") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Poison or Curses.Disease or magic or show
		end
	elseif (playerClass == "SHAMAN") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return (not IsVanillaClassic and Curses.Curse) or (IsClassic and Curses.Poison) or (IsClassic and Curses.Disease) or magic or show
		end
	elseif (playerClass == "ROGUE") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Poison or show
		end
	elseif (playerClass == "EVOKER") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Curse or Curses.Poison or Curses.Disease or magic or show
		end
	else
		getShow = function(Curses)
			return Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
		end
	end

	TPerl_DebufHighlightInit = nil
end

local bgDef = {
	bgFile = "Interface\\Addons\\TPerl\\Images\\TPerl_FrameBack",
	edgeFile = "",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = {left = 2, right = 2, top = 2, bottom = 2}
}
local normalEdge = "Interface\\Tooltips\\UI-Tooltip-Border"
local curseEdge = "Interface\\Addons\\TPerl\\Images\\TPerl_Curse"

-- TPerl_CheckDebuffs
--local Curses = setmetatable({ }, {__mode = "k"})	-- 2.2.6 - Now re-using static table to save garbage memory creation
local Curses = { }
function TPerl_CheckDebuffs(self, unit, resetBorders)
	if not self.FlashFrames then
		return
	end

	local high = conf.highlightDebuffs.enable or (self == TPerl_Target and conf.target.highlightDebuffs.enable) or (self == TPerl_Focus and conf.focus.highlightDebuffs.enable)

	if resetBorders or not high or not getShow then
		-- Reset the frame edges back to normal in case they changed options while debuffed.
		self.forcedColour = nil
		bgDef.edgeFile = self.edgeFile or normalEdge
		bgDef.edgeSize = self.edgeSize or 16
		bgDef.insets.left = self.edgeInsets or 3
		bgDef.insets.top = self.edgeInsets or 3
		bgDef.insets.right = self.edgeInsets or 3
		bgDef.insets.bottom = self.edgeInsets or 3
		--for i, f in pairs(self.FlashFrames) do
		for i = 1, #self.FlashFrames do
			local f = self.FlashFrames[i]
			f:SetBackdrop(bgDef)
			f:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
			f:SetBackdropBorderColor(conf.colour.border.r, conf.colour.border.g, conf.colour.border.b, conf.colour.border.a)
		end
		return
	end

	if not unit then
		unit = self:GetAttribute("unit")
		if not unit then
			return
		end
	end

	Curses.Magic, Curses.Curse, Curses.Poison, Curses.Disease = nil, nil, nil, nil

	local show
	local secretBorderColour
	local debuffCount = 0
	local anyDebuff = false
	local typedButSecret = false
	local _, unitClass = UnitClass(unit)

	-- Cache the last typed debuff highlight so it stays stable if dispel type becomes hidden/secret
	local lastShow = self._tperlLastDebuffShow
	local lastNames = self._tperlLastDebuffNames
	local lastSpellIds = self._tperlLastDebuffSpellIds
	local lastAuraIds = self._tperlLastDebuffAuraIds
	local lastTS = self._tperlLastDebuffTS
	local lastPresent = false


local lastColor = self._tperlLastDebuffColor
local lastColorNames = self._tperlLastDebuffColorNames
local lastColorSpellIds = self._tperlLastDebuffColorSpellIds
local lastColorAuraIds = self._tperlLastDebuffColorAuraIds
local lastColorTS = self._tperlLastDebuffColorTS
local lastColorPresent = false

local secretColor
local secretNames
local secretSpellIds
local secretAuraIds

local typedNames
	local typedSpellIds
	local typedAuraIds

local useNewAuraScan = (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex)
for i = 1, 40 do
	local name, dispelName, spellId, auraId
	local auraData

	if useNewAuraScan then
		local okAD, ad = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
		if (not okAD or not ad) then
			break
		end
		auraData = ad
		name = TPerl_SafeTableGet(ad, "name")
		dispelName = TPerl_SafeTableGet(ad, "dispelName")
		spellId = TPerl_SafeTableGet(ad, "spellId") or TPerl_SafeTableGet(ad, "spellID")
		auraId = TPerl_SafeTableGet(ad, "auraInstanceID") or TPerl_SafeTableGet(ad, "auraInstanceId")
	else
		name, dispelName, spellId, auraId = TPerl_GetHarmfulAura(unit, i)
		if not name then
			break
		end
	end

	-- Track if the previously-typed debuff is still present (even if its type becomes hidden later)
		if lastShow then
			if auraId and TPerl_CanAccess(auraId) and lastAuraIds and lastAuraIds[auraId] then
				lastPresent = true
			elseif spellId and TPerl_CanAccess(spellId) and lastSpellIds and lastSpellIds[spellId] then
				lastPresent = true
			elseif name and TPerl_CanAccess(name) and lastNames and lastNames[name] then
				lastPresent = true
			end
		end


if lastColor then
	if auraId and TPerl_CanAccess(auraId) and lastColorAuraIds and lastColorAuraIds[auraId] then
		lastColorPresent = true
	elseif spellId and TPerl_CanAccess(spellId) and lastColorSpellIds and lastColorSpellIds[spellId] then
		lastColorPresent = true
	elseif name and TPerl_CanAccess(name) and lastColorNames and lastColorNames[name] then
		lastColorPresent = true
	end
end

		-- Midnight/Retail: aura fields such as name/dispelName may be "secret".
		-- Do NOT index tables with secret values. If we can't read the dispel type,
		-- still track that the unit has a harmful aura so border highlighting can work.
		local exclude
		if name and TPerl_CanAccess(name) then
			exclude = ArcaneExclusions[name]
		end
		if not exclude or (type(exclude) == "table" and not exclude[unitClass]) then
			anyDebuff = true

-- Midnight/Retail: dispelType may be a secret object. Convert dispelType -> secret colour via ColorCurve.
local sCol, sAuraId, sSpellId, sName
if useNewAuraScan and auraData then
	sCol, sAuraId, sSpellId, sName = TPerl_GetDebuffColorByAuraData(unit, auraData)
else
	sCol, sAuraId, sSpellId, sName = TPerl_GetDebuffColorByAuraIndex(unit, i)
end
if sCol then
	if not secretColor then
		secretColor = sCol
	end
	if not secretNames then
		secretNames = { }
		secretSpellIds = { }
		secretAuraIds = { }
	end
	if sName and TPerl_CanAccess(sName) then
		secretNames[sName] = true
	end
	if sSpellId and TPerl_CanAccess(sSpellId) then
		secretSpellIds[sSpellId] = true
	end
	if sAuraId and TPerl_CanAccess(sAuraId) then
		secretAuraIds[sAuraId] = true
	end
end
			if dispelName then
				if TPerl_CanAccess(dispelName) then
					local dt = TPerl_NormalizeDispelType(dispelName)
					if (dt) then
						Curses[dt] = dt
						debuffCount = debuffCount + 1

						-- Remember typed debuffs we can identify this pass (used for stable caching)
						if not typedNames then
							typedNames = { }
							typedSpellIds = { }
						end
						if name and TPerl_CanAccess(name) then
							typedNames[name] = true
						end
						if spellId then
							typedSpellIds[spellId] = true
						end
					end
				else
					-- Midnight/Retail can hide dispel type as a secret value; remember that a typed debuff exists.
					typedButSecret = true
				end
			end
		end
	end

	if debuffCount > 0 then
		-- 2.2.6 - Very (very very) slight speed optimization by having a function per class which is set at startup
		show = getShow(Curses)

		-- Cache last typed highlight so it stays stable if the dispel type becomes hidden/secret on later refreshes.
		if show and show ~= "none" then
			self._tperlLastDebuffShow = show
			self._tperlLastDebuffTS = GetTime()
			self._tperlLastDebuffNames = typedNames
			self._tperlLastDebuffSpellIds = typedSpellIds
				self._tperlLastDebuffAuraIds = typedAuraIds
		end
	else
		-- No accessible typed debuffs this pass.
		-- If we still see the previously typed debuff (by name/spellId), keep the last highlight stable.
		-- If the type is hidden/secret and we can't verify presence, keep it briefly to avoid flicker.
		if lastShow and (lastPresent or (typedButSecret and lastTS and (GetTime() - lastTS) < 2)) then
			show = lastShow
		else
			-- If we have debuffs but none are typed (e.g. bleeds), optionally use the generic 'none' colour
			-- when not restricted to 'only curable by my class'.
			if anyDebuff and ((not conf.highlightDebuffs) or (not conf.highlightDebuffs.class) or typedButSecret) then
				show = "none"
			end
			-- No sign of typed debuffs -> clear cached typed highlight to avoid stale colours.
			self._tperlLastDebuffShow = nil
			self._tperlLastDebuffTS = nil
			self._tperlLastDebuffNames = nil
			self._tperlLastDebuffSpellIds = nil
				self._tperlLastDebuffAuraIds = nil
		end
	end



-- Secret/forbidden dispelType support via ColorCurve (Midnight/Retail)
-- If we couldn't derive a readable dispel name, try to keep a stable border colour via secret dispelType -> curve.
if (not show or show == "none") then
	if secretColor then
		if lastColor and lastColorPresent then
			secretBorderColour = lastColor
		else
			secretBorderColour = secretColor
			self._tperlLastDebuffColor = secretColor
			self._tperlLastDebuffColorTS = GetTime()
			self._tperlLastDebuffColorNames = secretNames
			self._tperlLastDebuffColorSpellIds = secretSpellIds
			self._tperlLastDebuffColorAuraIds = secretAuraIds
		end
	elseif lastColor and (lastColorPresent or (anyDebuff and lastColorTS and (GetTime() - lastColorTS) < 2)) then
		-- Keep briefly to avoid flicker if dispelType becomes hidden intermittently.
		secretBorderColour = lastColor
	else
		-- Clear stale secret colour cache.
		self._tperlLastDebuffColor = nil
		self._tperlLastDebuffColorTS = nil
		self._tperlLastDebuffColorNames = nil
		self._tperlLastDebuffColorSpellIds = nil
		self._tperlLastDebuffColorAuraIds = nil
	end
end
	-- No debuffs at all -> clear cache
	if not anyDebuff then
		self._tperlLastDebuffShow = nil
		self._tperlLastDebuffTS = nil
		self._tperlLastDebuffNames = nil
		self._tperlLastDebuffSpellIds = nil
				self._tperlLastDebuffAuraIds = nil

self._tperlLastDebuffColor = nil
self._tperlLastDebuffColorTS = nil
self._tperlLastDebuffColorNames = nil
self._tperlLastDebuffColorSpellIds = nil
self._tperlLastDebuffColorAuraIds = nil
	end


	

local colour, borderColour
if secretBorderColour then
	-- Secret dispelType -> curve colour (Midnight/Retail)
	if conf.highlightDebuffs.frame then
		colour = secretBorderColour
	else
		colour = conf.colour.frame
	end
	if conf.highlightDebuffs.border then
		borderColour = secretBorderColour
	else
		borderColour = conf.colour.border
	end
elseif show then
	colour = TPerl_GetDebuffTypeColorSafe(show)
	if conf.highlightDebuffs.border then
		borderColour = colour
	else
		borderColour = conf.colour.border
	end
else
	colour = conf.colour.frame
	borderColour = conf.colour.border
end


	-- IMPORTANT:
	-- When highlighting *only the border*, combat-flash can overwrite the border colour and
	-- then restore it to the default border colour when the flash ends.
	-- To keep the debuff border highlight stable, ensure we set forcedColour whenever the
	-- border highlight is active.
	if (show or secretBorderColour) and conf.highlightDebuffs.border then
		self.forcedColour = borderColour
	else
		self.forcedColour = nil
	end

	if (show or secretBorderColour) and conf.highlightDebuffs.frame then
		bgDef.edgeFile = curseEdge
	else
		--bgDef.edgeFile = normalEdge

		bgDef.edgeFile = self.edgeFile or normalEdge
		bgDef.edgeSize = self.edgeSize or 16
		bgDef.insets.left = self.edgeInsets or 3
		bgDef.insets.top = self.edgeInsets or 3
		bgDef.insets.right = self.edgeInsets or 3
		bgDef.insets.bottom = self.edgeInsets or 3
	end

	--for i, f in pairs(self.FlashFrames) do
	for i = 1, #self.FlashFrames do
		local f = self.FlashFrames[i]
		if not conf.highlightDebuffs.frame then
			colour = conf.colour.frame
		end
		f:SetBackdrop(bgDef)
		f:SetBackdropColor(colour.r, colour.g, colour.b, colour.a)
		f:SetBackdropBorderColor(borderColour.r, borderColour.g, borderColour.b, borderColour.a)
	end
end

-- TPerl_GetSavePositionTable
function TPerl_GetSavePositionTable(create)
	if (not TPerlConfigNew) then
		return
	end

	local name = UnitName("player")
	local realm = GetRealmName()

	if (not TPerlConfigNew.savedPositions) then
		if (not create) then
			return
		end
		TPerlConfigNew.savedPositions = {}
	end
	local c = TPerlConfigNew.savedPositions
	if (not c[realm]) then
		if (not create) then
			return
		end
		c[realm] = {}
	end
	if (not c[realm][name]) then
		if (not create) then
			return
		end
		c[realm][name] = {}
	end
	local table = c[realm][name]

	return table
end


-- TPerl_SavePosition
function TPerl_SavePosition(self, onlyIfEmpty)
	local name = self:GetName()
	if (name) then
		local s = self:GetScale()
		local t = self:GetTop()
		local l = self:GetLeft()
		local h = self:IsResizable() and self:GetHeight()
		local w = self:IsResizable() and self:GetWidth()

		local table = TPerl_GetSavePositionTable(true)
		if (table) then
			if (not onlyIfEmpty or (onlyIfEmpty and not table[name])) then
				if (t and l) then
					if (not table[name]) then
						table[name] = {}
					end
					table[name].top = t * s
					table[name].left = l * s
					table[name].height = h
					table[name].width = w
				else
					table[name] = nil
				end
			else
				if (table[name] and not self:IsUserPlaced()) then
					TPerl_RestorePosition(self)
				end
			end
		end
	end
end

-- TPerl_RestorePosition
function TPerl_RestorePosition(self)
	if (TPerlConfigNew.savedPositions) then
		local name = self:GetName()
		if (name) then
			local table = TPerl_GetSavePositionTable()
			if (table) then
				local pos = table[name]
				if (pos and pos.left and pos.top) then
					self:ClearAllPoints()
					self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left / self:GetScale(), pos.top / self:GetScale())

					if (pos.height and pos.width) then
						if (self:IsResizable()) then
							self:SetHeight(pos.height)
							self:SetWidth(pos.width)
						else
							pos.height, pos.width = nil, nil
						end
					end

					self:SetUserPlaced(true)
				end
			end
		end
	end
end

-- TPerl_RestoreAllPositions
function TPerl_RestoreAllPositions()
	local table = TPerl_GetSavePositionTable()
	if table then
		for k, v in pairs(table) do
			if k == "TPerl_Runes" or k == "TPerl_RaidHelper_Frame" or k == "TPerl_RaidMonitor_Frame" or k == "TPerl_Check" or k == "TPerl_AdminFrame" or k == "TPerl_Assists_Frame" then
				-- Fix for a wrong name with versions 2.3.2 and 2.3.2a
				-- It was using TPerl_Frame instead of TPerl_MTList_Anchor
				-- and TPerl_RaidMonitor_Frame instead of TPerl_RaidMonitor_Anchor
				-- And now a change to TPerl_Check to TPerl_CheckAnchor and TPerl_AdminFrame to TPerl_AdminFrameAnchor
				table[k] = nil
			elseif k == "TPerl_Options" or k == "TPerl_OptionsAnchor" then
				-- Noop
			else
				local frame = _G[k]
				if frame then
					--[[if k == "TPerl_Runes" and conf.player.dockRunes then
						break
					end]]
					if v.left and v.top then
						frame:SetUserPlaced(false)
						frame:ClearAllPoints()
						frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", v.left / frame:GetScale(), v.top / frame:GetScale())
						if k == "TPerl_Assists_FrameAnchor" then
							if TPerlConfigHelper then
								if TPerlConfigHelper.sizeAssistsX and TPerlConfigHelper.sizeAssistsY then
									TPerl_Assists_Frame:SetWidth(TPerlConfigHelper.sizeAssistsX)
									TPerl_Assists_Frame:SetHeight(TPerlConfigHelper.sizeAssistsY)
								end
								if TPerlConfigHelper.sizeAssistsS then
									TPerl_Assists_Frame:SetScale(TPerlConfigHelper.sizeAssistsS)
								end
							end
						else
							if v.height and v.width then
								if frame:IsResizable() then
									frame:SetHeight(v.height)
									frame:SetWidth(v.width)
								else
									v.height, v.width = nil, nil
								end
							end
						end
						--[[if (k == "TPerl_Runes") then
							frame:SetMovable(true)
							frame:EnableMouse(true)
							frame:RegisterForDrag("LeftButton")
							frame:SetScript("OnDragStart", frame.StartMoving)
							frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
							frame:SetUserPlaced(true)
						else]]
							--frame:SetUserPlaced(true)
						--end
					end
				end
			end
		end
	end
end

local BuffExceptions
local DebuffExceptions
local SeasonalDebuffs
local RaidFrameIgnores
if IsRetail then
	BuffExceptions = {
		PRIEST = {
			[C_Spell.GetSpellInfo(774).name] = true,					-- Rejuvenation
			[C_Spell.GetSpellInfo(8936).name] = true,				-- Regrowth
			[C_Spell.GetSpellInfo(33076).name] = true,				-- Prayer of Mending
			[C_Spell.GetSpellInfo(81749).name] = true,				-- Atonement
		},
		DRUID = {
			[C_Spell.GetSpellInfo(139).name] = true,					-- Renew
		},
		WARLOCK = {
			[C_Spell.GetSpellInfo(20707).name] = true,				-- Soulstone Resurrection
		},
		HUNTER = {
			--[C_Spell.GetSpellInfo(13165).name] = true,				-- Aspect of the Hawk
			--[C_Spell.GetSpellInfo(5118).name] = true,				-- Aspect of the Cheetah
			--[C_Spell.GetSpellInfo(13159).name] = true,				-- Aspect of the Pack
			[C_Spell.GetSpellInfo(61648).name] = true,				-- Aspect of the Beast
			-- [C_Spell.GetSpellInfo(13163).name] = true,			-- Aspect of the Monkey
			--[C_Spell.GetSpellInfo(19506).name] = true,				-- Trueshot Aura
			[C_Spell.GetSpellInfo(5384).name] = true,				-- Feign Death
		},
		ROGUE = {
			[C_Spell.GetSpellInfo(1784).name] = true,				-- Stealth
			[C_Spell.GetSpellInfo(1856).name] = true,				-- Vanish
			[C_Spell.GetSpellInfo(2983).name] = true,				-- Sprint
			[C_Spell.GetSpellInfo(13750).name] = true,				-- Adrenaline Rush
			[C_Spell.GetSpellInfo(13877).name] = true,				-- Blade Flurry
		},
		PALADIN = {
			--[C_Spell.GetSpellInfo(20154).name] = true,				-- Seal of Righteousness
			--[C_Spell.GetSpellInfo(20165).name] = true,				-- Seal of Insight
			--[C_Spell.GetSpellInfo(20164).name] = true,				-- Seal of Justice
			--[C_Spell.GetSpellInfo(31801).name] = true,				-- Seal of Truth
			--[C_Spell.GetSpellInfo(20375).name] = true,				-- Seal of Command
			--[C_Spell.GetSpellInfo(20166).name] = true,				-- Seal of Wisdom
			--[C_Spell.GetSpellInfo(20165).name] = true,				-- Seal of Light
			--[C_Spell.GetSpellInfo(53736).name] = true,				-- Seal of Corruption
			--[C_Spell.GetSpellInfo(31892).name] = true,				-- Seal of Blood
			--[C_Spell.GetSpellInfo(31801).name] = true,				-- Seal of Vengeance
			[C_Spell.GetSpellInfo(25780).name] = true,				-- Righteous Fury
			--[C_Spell.GetSpellInfo(20925).name] = true,				-- Holy Shield
			--[C_Spell.GetSpellInfo(54428).name] = true,				-- Divine Plea
		},
	}
	DebuffExceptions = {
		ALL = {
			[C_Spell.GetSpellInfo(11196).name] = true,				-- Recently Bandaged
		},
		PRIEST = {
			[C_Spell.GetSpellInfo(6788).name] = true,				-- Weakened Soul
		},
		PALADIN = {
			[C_Spell.GetSpellInfo(25771).name] = true				-- Forbearance
		}
	}
	SeasonalDebuffs = {
		[C_Spell.GetSpellInfo(26004).name] = true,					-- Mistletoe
		[C_Spell.GetSpellInfo(26680).name] = true,					-- Adored
		[C_Spell.GetSpellInfo(26898).name] = true,					-- Heartbroken
		[C_Spell.GetSpellInfo(64805).name] = true,					-- Bested Darnassus
		[C_Spell.GetSpellInfo(64808).name] = true,					-- Bested the Exodar
		[C_Spell.GetSpellInfo(64809).name] = true,					-- Bested Gnomeregan
		[C_Spell.GetSpellInfo(64810).name] = true,					-- Bested Ironforge
		[C_Spell.GetSpellInfo(64811).name] = true,					-- Bested Orgrimmar
		[C_Spell.GetSpellInfo(64812).name] = true,					-- Bested Sen'jin
		[C_Spell.GetSpellInfo(64813).name] = true,					-- Bested Silvermoon City
		[C_Spell.GetSpellInfo(64814).name] = true,					-- Bested Stormwind
		[C_Spell.GetSpellInfo(64815).name] = true,					-- Bested Thunder Bluff
		[C_Spell.GetSpellInfo(64816).name] = true,					-- Bested the Undercity
		[C_Spell.GetSpellInfo(36900).name] = true,					-- Soul Split: Evil!
		[C_Spell.GetSpellInfo(36901).name] = true,					-- Soul Split: Good
		[C_Spell.GetSpellInfo(36899).name] = true,					-- Transporter Malfunction
		[C_Spell.GetSpellInfo(24755).name] = true,					-- Tricked or Treated
		[C_Spell.GetSpellInfo(69127).name] = true,					-- Chill of the Throne
		[C_Spell.GetSpellInfo(69438).name] = true,					-- Sample Satisfaction
	}

	RaidFrameIgnores = {
		[C_Spell.GetSpellInfo(26013).name] = true,					-- Deserter
		[C_Spell.GetSpellInfo(71041).name] = true,					-- Dungeon Deserter
		[C_Spell.GetSpellInfo(71328).name] = true,					-- Dungeon Cooldown
	}
else
	BuffExceptions = {
		PRIEST = {
			[GetSpellInfo(774)] = true,					-- Rejuvenation
			[GetSpellInfo(8936)] = true,				-- Regrowth
			--[GetSpellInfo(33076)] = true,				-- Prayer of Mending
			--[GetSpellInfo(81749)] = true,				-- Atonement
		},
		DRUID = {
			[GetSpellInfo(139)] = true,					-- Renew
		},
		WARLOCK = {
			[GetSpellInfo(20707)] = true,				-- Soulstone Resurrection
		},
		HUNTER = {
			[GetSpellInfo(13165)] = true,				-- Aspect of the Hawk
			[GetSpellInfo(5118)] = true,				-- Aspect of the Cheetah
			[GetSpellInfo(13159)] = true,				-- Aspect of the Pack
			--[GetSpellInfo(61648)] = true,				-- Aspect of the Beast
			--[GetSpellInfo(13163)] = true,				-- Aspect of the Monkey
			[GetSpellInfo(19506)] = true,				-- Trueshot Aura
			[GetSpellInfo(5384)] = true,				-- Feign Death
		},
		ROGUE = {
			[GetSpellInfo(1784)] = true,				-- Stealth
			[GetSpellInfo(1856)] = true,				-- Vanish
			[GetSpellInfo(2983)] = true,				-- Sprint
			[GetSpellInfo(13750)] = true,				-- Adrenaline Rush
			[GetSpellInfo(13877)] = true,				-- Blade Flurry
		},
		PALADIN = {
			[GetSpellInfo(20154)] = true,				-- Seal of Righteousness
			[GetSpellInfo(20165)] = true,				-- Seal of Insight
			[GetSpellInfo(20164)] = true,				-- Seal of Justice
			--[GetSpellInfo(31801)] = true,				-- Seal of Truth
			--[GetSpellInfo(20375)] = true,				-- Seal of Command
			--[GetSpellInfo(20166)] = true,				-- Seal of Wisdom
			[GetSpellInfo(20165)] = true,				-- Seal of Light
			--[GetSpellInfo(53736)] = true,				-- Seal of Corruption
			--[GetSpellInfo(31892)] = true,				-- Seal of Blood
			--[GetSpellInfo(31801)] = true,				-- Seal of Vengeance
			[GetSpellInfo(25780)] = true,				-- Righteous Fury
			[GetSpellInfo(20925)] = true,				-- Holy Shield
			--[GetSpellInfo(54428)] = true,				-- Divine Plea
		},
	}
	DebuffExceptions = {
		ALL = {
			[GetSpellInfo(11196)] = true,				-- Recently Bandaged
		},
		PRIEST = {
			[GetSpellInfo(6788)] = true,				-- Weakened Soul
		},
		PALADIN = {
			[GetSpellInfo(25771)] = true				-- Forbearance
		}
	}

	SeasonalDebuffs = {
		[GetSpellInfo(26004)] = true,					-- Mistletoe
		[GetSpellInfo(26680)] = true,					-- Adored
		[GetSpellInfo(26898)] = true,					-- Heartbroken
		--[GetSpellInfo(64805)] = true,					-- Bested Darnassus
		--[GetSpellInfo(64808)] = true,					-- Bested the Exodar
		--[GetSpellInfo(64809)] = true,					-- Bested Gnomeregan
		--[GetSpellInfo(64810)] = true,					-- Bested Ironforge
		--[GetSpellInfo(64811)] = true,					-- Bested Orgrimmar
		--[GetSpellInfo(64812)] = true,					-- Bested Sen'jin
		--[GetSpellInfo(64813)] = true,					-- Bested Silvermoon City
		--[GetSpellInfo(64814)] = true,					-- Bested Stormwind
		--[GetSpellInfo(64815)] = true,					-- Bested Thunder Bluff
		--[GetSpellInfo(64816)] = true,					-- Bested the Undercity
		--[GetSpellInfo(36900)] = true,					-- Soul Split: Evil!
		--[GetSpellInfo(36901)] = true,					-- Soul Split: Good
		--[GetSpellInfo(36899)] = true,					-- Transporter Malfunction
		[GetSpellInfo(24755)] = true,					-- Tricked or Treated
		--[GetSpellInfo(69127)] = true,					-- Chill of the Throne
		--[GetSpellInfo(69438)] = true,					-- Sample Satisfaction
	}

	RaidFrameIgnores = {
		[GetSpellInfo(26013)] = true,					-- Deserter
		--[GetSpellInfo(71041)] = true,					-- Dungeon Deserter
		--[GetSpellInfo(71328)] = true,					-- Dungeon Cooldown
	}
end

-- BuffException
local showInfo

local function BuffException(unit, index, filter, func, exceptions, raidFrames)
	-- Midnight/Retail note:
	-- C_UnitAuras can return auraData where some fields (name/icon/etc) are "secret" and appear as nil
	-- in tainted addon code. Callers often treat (name == nil) as end-of-list, so we must return a
	-- stable placeholder name when an aura exists but its name is not accessible.
	local function ReadAura(u, i, f)
		if (IsRetail and C_UnitAuras and func) then
			local auraData = func(u, i, f)
			if (not auraData) then
				return nil
			end

			local name = TPerl_SafeTableGet(auraData, "name")
			local icon = TPerl_SafeTableGet(auraData, "icon")
			local applications = TPerl_SafeTableGet(auraData, "applications")
			local dispelName = TPerl_SafeTableGet(auraData, "dispelName")
			local duration = TPerl_SafeTableGet(auraData, "duration")
			local expirationTime = TPerl_SafeTableGet(auraData, "expirationTime")
			local sourceUnit = TPerl_SafeTableGet(auraData, "sourceUnit")
			local isStealable = TPerl_SafeTableGet(auraData, "isStealable")
			local nameplateShowPersonal = TPerl_SafeTableGet(auraData, "nameplateShowPersonal")
			local spellId = TPerl_SafeTableGet(auraData, "spellId")
			local auraInstanceID = TPerl_SafeTableGet(auraData, "auraInstanceID")

			if (not name) then
				-- Use a stable placeholder (never used as a lookup key) so loops don't stop early.
				local aid = auraInstanceID
				if (aid and TPerl_CanAccess(aid)) then
					name = "\0" .. aid
				else
					name = "\0" .. i
				end
			end

			return name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, auraInstanceID
		end

		-- Classic/Mists path
		local name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId = func(u, i, f)
		if (not name) then
			return nil
		end
		return name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, nil
	end

	local raidFiltered = (filter == "HELPFUL|RAID" or filter == "HARMFUL|RAID")
	if (not raidFiltered) then
		local name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId = ReadAura(unit, index, filter)
		return name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, index
	end

	local name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, auraInstanceID = ReadAura(unit, index, filter)
	if (not name) then
		return nil
	end

	-- When WoW returns an aura in the filtered list, we need its index in the base list for tooltips.
	if (icon) then
		local baseFilter = (filter == "HELPFUL|RAID") and "HELPFUL" or "HARMFUL"

		if (IsRetail and C_UnitAuras and auraInstanceID and TPerl_CanAccess(auraInstanceID)) then
			for i = 1, 40 do
				local a = func(unit, i, baseFilter)
				if (not a) then
					break
				end
				local aid = a.auraInstanceID
				if (aid and TPerl_CanAccess(aid) and aid == auraInstanceID) then
					index = i
					break
				end
			end
		else
			-- Fallback for non-retail where values are not secret
			local origName, origIcon, origApplications, origSourceUnit = name, icon, applications, sourceUnit
			for i = 1, 40 do
				local n, ic, ap, _, _, _, su = func(unit, i, baseFilter)
				if (not n) then
					break
				end
				if (n == origName and ic == origIcon and ap == origApplications and su == origSourceUnit) then
					index = i
					break
				end
			end
		end

		return name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, index
	end

	-- No aura found in the filtered list for this index. Determine how many filtered auras exist by default...
	local normalBuffFilterCount = 0
	for i = 1, 40 do
		if (IsRetail and C_UnitAuras) then
			local a = func(unit, i, filter)
			if (not a) then
				normalBuffFilterCount = i - 1
				break
			end
		else
			local n = func(unit, i, filter)
			if (not n) then
				normalBuffFilterCount = i - 1
				break
			end
		end
	end

	-- ...then tack on exception auras from the base list (HELPFUL/HARMFUL) after the default filtered list.
	local baseFilter = (filter == "HELPFUL|RAID") and "HELPFUL" or "HARMFUL"
	local foundValid = 0
	local playerClass = select(2, UnitClass("player"))

	for i = 1, 40 do
		local n, ic, ap, dt, dur, exp, su, steal, np, sid = ReadAura(unit, i, baseFilter)
		if (not n) then
			break
		end

		-- Only consider exceptions when we can safely use the real name as a lookup key.
		if (TPerl_CanAccess(n) and strsub(n, 1, 1) ~= "\0") then
			if (exceptions[playerClass] and exceptions[playerClass][n]) or (exceptions[1] and exceptions[1][n]) then
				if (not raidFrames or not raidFrames.Ignores or not raidFrames.Ignores[n]) then
					foundValid = foundValid + 1
					if (foundValid + normalBuffFilterCount == index) then
						return n, ic, ap, dt, dur, exp, su, steal, np, sid, i
					end
				end
			end
		end
	end
end

-- DebuffException
local function DebuffException(unit, start, filter, func, raidFrames)
	local valid = 0
	local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId, index
	local i

	for i = 1, 40 do
		name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId, index = BuffException(unit, i, filter, func, DebuffExceptions, raidFrames)
		if (not name) then
			break
		end

		-- skip seasonal debuffs by name when available (ignore placeholder secret names)
		if (TPerl_CanAccess(name) and strsub(name, 1, 1) ~= "\0" and SeasonalDebuffs[name]) then
			-- skip
		else
			valid = valid + 1
			if (valid == start) then
				return name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId, index
			end
		end
	end
end

-- TPerl_UnitBuff
function TPerl_UnitBuff(unit, index, filter, raidFrames)
	return BuffException(unit, index, filter, (IsVanillaClassic and unit == "target") and UnitAuraWithBuffs or (IsRetail and C_UnitAuras and TPerl_SafeGetAuraDataByIndex) or UnitAura, BuffExceptions, raidFrames)
end

-- TPerl_UnitDebuff
function TPerl_UnitDebuff(unit, index, filter, raidFrames)
	if (conf.buffs.ignoreSeasonal or raidFrames) then
		return DebuffException(unit, index, filter, (IsRetail and C_UnitAuras and TPerl_SafeGetAuraDataByIndex) or UnitAura, raidFrames)
	end
	return BuffException(unit, index, filter, (IsRetail and C_UnitAuras and TPerl_SafeGetAuraDataByIndex) or UnitAura, DebuffExceptions, raidFrames)
end

-- TPerl_TooltipSetUnitBuff
-- Retreives the index of the actual unfiltered buff, and uses this on unfiltered tooltip call
function TPerl_TooltipSetUnitBuff(self, unit, ind, filter, raidFrames)
	local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, index = BuffException(unit, ind, filter, (IsVanillaClassic and unit == "target") and UnitAuraWithBuffs or (IsRetail and C_UnitAuras and TPerl_SafeGetAuraDataByIndex) or UnitAura, BuffExceptions, raidFrames)
	if (name and index) then
		if (Utopia_SetUnitBuff) then
			Utopia_SetUnitBuff(self, unit, index)
		else
			self:SetUnitBuff(unit, index)
		end
	end
end

-- TPerl_TooltipSetUnitDebuff
-- Retreives the index of the actual unfiltered debuff, and uses this on unfiltered tooltip call
function TPerl_TooltipSetUnitDebuff(self, unit, ind, filter, raidFrames)
	local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, index = TPerl_UnitDebuff(unit, ind, filter, raidFrames)
	if (name and index) then
		if (Utopia_SetUnitDebuff) then
			Utopia_SetUnitDebuff(self, unit, index)
		else
			self:SetUnitDebuff(unit, index)
		end
	end
end

----------------------
-- Fading Bar Stuff --
----------------------
local fadeBars = {}
local freeFadeBars = {}
local tempDisableFadeBars

function TPerl_NoFadeBars(tempDisable)
	tempDisableFadeBars = tempDisable
end

-- CheckOnUpdate
local function CheckOnUpdate()
	if (next(fadeBars)) then
		TPerl_Globals:SetScript("OnUpdate", TPerl_BarUpdate)
	else
		TPerl_Globals:SetScript("OnUpdate", nil)
	end
end

-- TPerl_BarUpdate
--local speakerTimer = 0
--local speakerCycle = 0
function TPerl_BarUpdate(self, arg1)
	local did
	for k,v in pairs(fadeBars) do
		if (k:IsShown()) then
			v:SetAlpha(k.fadeAlpha)
			k.fadeAlpha = k.fadeAlpha - (arg1 / conf.bar.fadeTime)

			local r, g, b = v.tex:GetVertexColor()
			v:SetStatusBarColor(r, g, b)
		else
			-- Not shown, so end it
			k.fadeAlpha = 0
		end

		if (k.fadeAlpha <= 0) then
			tinsert(freeFadeBars, v)
			fadeBars[k] = nil
			k.fadeAlpha = nil
			k.fadeBar = nil
			v:SetValue(0)
			v:Hide()
			v.tex = nil
			did = true
		end
	end

	if (did) then
		CheckOnUpdate()
	end
end

-- GetFreeFader
local function GetFreeFader(parent)
	local bar = freeFadeBars[1]
	if (bar) then
		tremove(freeFadeBars, 1)
		bar:SetParent(parent)
	else
		bar = CreateFrame("StatusBar", nil, parent)
	end

	if (bar) then
		fadeBars[parent] = bar
		CheckOnUpdate()

		bar.tex = parent.tex

		local tex = parent:GetStatusBarTexture()
		if tex:GetTexture() then
			bar:SetStatusBarTexture(tex:GetTexture())
			bar:GetStatusBarTexture():SetHorizTile(false)
			bar:GetStatusBarTexture():SetVertTile(false)
		end

		local r, g, b = bar.tex:GetVertexColor()
		bar:SetStatusBarColor(r, g, b)

		bar:SetFrameLevel(parent:GetFrameLevel())

		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", 0, 0)
		bar:SetPoint("BOTTOMRIGHT", 0, 0)
		bar:SetAlpha(1)

		return bar
	end
end

-- TPerl_StatusBarSetValue
function TPerl_StatusBarSetValue(self, val)
	if (not tempDisableFadeBars and conf.bar.fading and self:GetName()) then
		local min, max = self:GetMinMaxValues()
		local current = self:GetValue()

		if (val < current and val <= max and val >= min) then
			local bar = fadeBars[self]

			if (not bar) then
				bar = GetFreeFader(self)
			end

			if (bar) then
				if (not self.fadeAlpha) then
					self.fadeAlpha = self:GetParent():GetAlpha()
					bar:SetValue(current)
				end

				bar:SetMinMaxValues(min, max)
				bar:SetAlpha(self.fadeAlpha)
				bar:Show()
			end
		end
	end

	TPerl_OldStatusBarSetValue(self, val)
end

-- TPerl_RegisterClickCastFrame
function TPerl_RegisterClickCastFrame(self)
	if (not ClickCastFrames) then
		ClickCastFrames = { }
	end
	ClickCastFrames[self] = true
end

function TPerl_UnregisterClickCastFrame(self)
	if (ClickCastFrames) then
		ClickCastFrames[self] = nil
	end
end

-- TPerl_SecureUnitButton_OnLoad
function TPerl_SecureUnitButton_OnLoad(self, unit, menufunc, m1, m2, toggledisabled)
	self:SetAttribute("*type1", "target")
	if (toggledisabled) then
		self:SetAttribute("type2", "menu")
	else
		self:SetAttribute("type2", "togglemenu")
	end

	if (unit) then
		self:SetAttribute("unit", unit)
	end

	TPerl_RegisterClickCastFrame(self)
end

-- TPerl_GetBuffButton
local buffIconCount = 0
function TPerl_GetBuffButton(self, buffnum, debuff, createIfAbsent, newID)
	debuff = (debuff or 0)
	local buffType, buffList		--, buffFrame

	if (debuff == 1) then
		--buffFrame = self.debuffFrame
		buffType = "DeBuff"
		buffList = self.buffFrame.debuff
		if (not buffList) then
			self.buffFrame.debuff = {}
			buffList = self.buffFrame.debuff
		end
	else
		--buffFrame = self.buffFrame
		buffType = "Buff"
		buffList = self.buffFrame.buff
		if (not buffList) then
			self.buffFrame.buff = {}
			buffList = self.buffFrame.buff
		end
	end

	local button = buffList and buffList[buffnum]

	if (not button and createIfAbsent) then
		local setup = self.buffSetup
		local parent = self.buffFrame

		if (debuff == 1 and setup.debuffParent) then
			parent = self.debuffFrame
		end

		buffIconCount = buffIconCount + 1
		button = CreateFrame("Button", "TPerlBuff"..buffIconCount, parent, BackdropTemplateMixin and format("BackdropTemplate,TPerl_Cooldown_%sTemplate", buffType) or format("TPerl_Cooldown_%sTemplate", buffType))
		button:Hide()

		if (setup.rightClickable) then
			button:RegisterForClicks("RightButtonUp")
			--button:SetAttribute("type", "cancelaura")
			--button:SetAttribute("index", "number")
		end

		local size = self.conf.buffs.size
		if (debuff == 1) then
			size = self.conf.debuffs.size or (size * (1 + (setup.debuffSizeMod * debuff)))
		end
		button:SetScale(size / 32)

		if (setup.onCreate) then
			setup.onCreate(button)
		end

		if (debuff == 1) then
			--buffFrame.UpdateTooltip = setup.updateTooltipDebuff
			button.UpdateTooltip = setup.updateTooltipDebuff
			for k,v in pairs (setup.debuffScripts) do
				button:SetScript(k, v)
			end
		else
			--buffFrame.UpdateTooltip = setup.updateTooltipBuff
			button.UpdateTooltip = setup.updateTooltipBuff
			for k,v in pairs (setup.buffScripts) do
				button:SetScript(k, v)
			end
		end
		buffList[buffnum] = button

		button:ClearAllPoints()
		if (buffnum == 1) then
			if (debuff == 1) then
				if (setup.debuffAnchor1) then
					setup.debuffAnchor1(self, button)
				end
			else
				if (setup.buffAnchor1) then
					setup.buffAnchor1(self, button)
				end
			end
		else
			button:SetPoint("TOPLEFT", buffList[buffnum - 1], "TOPRIGHT", 1 + debuff, 0)
		end
	end
	-- TODO: Variable this
	button.cooldown:SetDrawEdge(false)
	-- Blizzard Cooldown Text Support
	if not conf.buffs.blizzard then
		button.cooldown:SetHideCountdownNumbers(true)
	else
		button.cooldown:SetHideCountdownNumbers(false)
	end
	-- OmniCC Support
	if not conf.buffs.omnicc then
		button.cooldown.noCooldownCount = true
	else
		button.cooldown.noCooldownCount = nil
	end
	button:SetID(newID or buffnum)

	return button
end

-- BuffCooldownDisplay
local function BuffCooldownDisplay(self)
	if (self.countdown) then
		local t = GetTime()
		if (t > self.endTime - 1) then
			self.countdown:SetText(strsub(format("%.1f", max(0, self.endTime - t)), 2, 10))
			self.countdown:Show()
		elseif (t > self.endTime - conf.buffs.countdownStart) then
			self.countdown:SetText(max(0, floor(self.endTime - t)))
			self.countdown:Show()
		else
			self.countdown:Hide()
		end
	end
end

-- TPerl_CooldownFrame_SetTimer(self, start, duration, enable)
function TPerl_CooldownFrame_SetTimer(self, start, duration, enable, mine)
	if ( start > 0 and duration > 0 and enable > 0) then
		self:SetCooldown(start, duration)
		self.endTime = start + duration

		if (conf.buffs.countdown and (mine or conf.buffs.countdownAny)) then
			self:SetScript("OnUpdate", BuffCooldownDisplay)
		else
			self:SetScript("OnUpdate", nil)
			self.countdown:Hide()
		end

		self:Show()
	else
		self:Hide()
	end
end

-- AuraButtonOnShow
local function AuraButtonOnShow(self)
	if (not conf.buffs.blizzardCooldowns) then
		if (self.cooldown) then
			self.cooldown:Hide()
		end
		return
	end

	local cd = self.cooldown
	if (not cd) then
		cd = CreateFrame("Cooldown", nil, self, BackdropTemplateMixin and "BackdropTemplate,CooldownFrameTemplate" or "CooldownFrameTemplate")
		self.cooldown = cd
		if self.Icon then
			cd:SetAllPoints(self.Icon)
		else
			cd:SetAllPoints(self:GetName().."Icon")
		end
	end
	cd:SetReverse(true)
	--cd:SetDrawEdge(true) Blizzard removed this call from 5.0.4, commented it out to avoid lua error

	if (not cd.countdown) then
		cd.countdown = self.cooldown:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
		if self.Icon then
			cd.countdown:SetPoint("TOPLEFT", self.Icon)
			cd.countdown:SetPoint("BOTTOMRIGHT", self.Icon, -1, 2)
		else
			cd.countdown:SetPoint("TOPLEFT", self:GetName().."Icon")
			cd.countdown:SetPoint("BOTTOMRIGHT", self:GetName().."Icon", -1, 2)
		end
		cd.countdown:SetTextColor(1, 1, 0)
	end

	local duration, expirationTime, sourceUnit
	if not IsVanillaClassic and C_UnitAuras then
		local auraData = TPerl_SafeGetAuraDataByIndex("player", self.xindex, self.xfilter)
		if auraData then
			duration = TPerl_SafeTableGet(auraData, "duration")
			expirationTime = TPerl_SafeTableGet(auraData, "expirationTime")
			sourceUnit = TPerl_SafeTableGet(auraData, "sourceUnit")
		end
	else
		local _
		_, _, _, _, duration, expirationTime, sourceUnit = UnitAura("player", self.xindex, self.xfilter)
	end

	if duration and expirationTime then
		local start = expirationTime - duration
		TPerl_CooldownFrame_SetTimer(self.cooldown, start, duration, 1, sourceUnit == "player")
	end
end

-- TPerl_AuraButton_UpdateInFo
-- Hook for Blizzard aura button setup to add cooldowns if we have them enabled
local function TPerl_AuraButton_UpdateInfo(button, buttonInfo, expanded)
	if not button then
		return
	end
	if (conf.buffs.blizzardCooldowns and BuffFrame:IsShown()) then
		button.xindex = buttonInfo.index
		button.xfilter = buttonInfo.filter
		button:SetScript("OnShow", AuraButtonOnShow)
		if (button:IsShown()) then
			AuraButtonOnShow(button)
		end
	end
end

-- TPerl_AuraButton_Update
-- Hook for Blizzard aura button setup to add cooldowns if we have them enabled
local function TPerl_AuraButton_Update(buttonName, index, filter)
	if (conf.buffs.blizzardCooldowns and BuffFrame:IsShown()) then
		local buffName = buttonName..index
		local button = _G[buffName]
		if (button) then
			button.xindex = index
			button.xfilter = filter
			button:SetScript("OnShow", AuraButtonOnShow)
			if (button:IsShown()) then
				AuraButtonOnShow(button)
			end
		end
	end
end

if AuraFrameMixin then
	-- TODO: Figure out what's changed here
	--hooksecurefunc(AuraFrameMixin, "Update", TPerl_AuraButton_UpdateInfo)
elseif AuraButton_Update then
	hooksecurefunc("AuraButton_Update", TPerl_AuraButton_Update)
end

-- TPerl_Unit_BuffSpacing
local function TPerl_Unit_BuffSpacing(self)
	local w = self.statsFrame:GetWidth()
	if (self.portraitFrame and self.portraitFrame:IsShown()) then
		w = w - 2 + self.portraitFrame:GetWidth()
	end
	if (self.levelFrame and self.levelFrame:IsShown()) then
		w = w - 2 + self.levelFrame:GetWidth()
	end
	if (not self.buffSpacing) then
		--self.buffSpacing = TPerl_GetReusableTable()
		self.buffSpacing = { }
	end
	self.buffSpacing.rowWidth = w

	local srs = 0
	if (not self.conf.buffs.above) then
		if (not self.statsFrame.manaBar or not self.statsFrame.manaBar:IsShown()) then
			srs = 10
		end

		if (self.creatureTypeFrame and self.creatureTypeFrame:IsShown()) then
			srs = srs + self.creatureTypeFrame:GetHeight() - 2
		end
	end

	if (srs > 0) then
		self.buffSpacing.smallRowHeight = srs
		self.buffSpacing.smallRowWidth = self.statsFrame:GetWidth()
	else
		self.buffSpacing.smallRowHeight = 0
		self.buffSpacing.smallRowWidth = w
	end
end

-- WieghAnchor(self, at)
local function WieghAnchor(self)
	if (not self.TOPLEFT or self.conf.flip ~= self.lastFlip or self.conf.buffs.above ~= self.lastAbove) then
		self.lastFlip = self.conf.flip or false
		self.lastAbove = self.conf.buffs.above

		local left, right, top, bottom
		if (self.conf.flip) then
			left, right = "RIGHT", "LEFT"
			self.SPACING = -1
		else
			left, right = "LEFT", "RIGHT"
			self.SPACING = 1
		end
		if (self.conf.buffs.above) then
			top, bottom = "BOTTOM", "TOP"
			self.VSPACING = 1
		else
			top, bottom = "TOP", "BOTTOM"
			self.VSPACING = -1
		end

		self.TOPLEFT = top..left
		self.TOPRIGHT = top..right
		self.BOTTOMLEFT = bottom..left
		self.BOTTOMRIGHT = bottom..right
	end
end

-- TPerl_Unit_BuffPositionsType
local function TPerl_Unit_BuffPositionsType(self, list, useSmallStart, buffSizeBase)
	local prevBuff, reusedSpace, hideFrom
	local firstOfRow = nil
	local prevRow, prevRowI = list[1], 1
	if (not prevRow) then
		return
	end
	local above = self.conf.buffs.above
	local colPoint, curRow, rowsHeight = 0, 1, 0
	--print(useSmallStart, self.buffSpacing.smallRowWidth, self.buffSpacing.rowWidth)
	local rowSize = (useSmallStart and self.buffSpacing.smallRowWidth) or self.buffSpacing.rowWidth
	local maxRows = self.conf.buffs.rows or 99
	local decrementMaxRowsIfLastIsBig -- Descriptive variable names ftw... If only upvalues took no actual memory space for the name... :(

	for i = 1, #list do
		if (curRow > maxRows) then
			hideFrom = i
			break
		end

		if (rowsHeight >= self.buffSpacing.smallRowHeight) then
			rowSize = self.buffSpacing.rowWidth
		end

		local buff = list[i]
		if (i > 1 and not buff:IsShown()) then
			break
		end

		local buffSize = (buff.big and (buffSizeBase * 2)) or buffSizeBase

		buff:ClearAllPoints()
		if (i == 1) then
			prevRow, prevRowI = buff, 1

			if (buff.big) then
				if (curRow == maxRows) then
					maxRows = maxRows + 1
					decrementMaxRowsIfLastIsBig = true
				end
			end

			if (self.prevBuff) then
				buff:SetPoint(self.TOPLEFT, self.prevBuff, self.BOTTOMLEFT, 0, self.VSPACING)
			else
				buff:SetPoint(self.TOPLEFT, 0, 0)
			end
		elseif (firstOfRow) then
			firstOfRow = nil
			if (not buff.big and prevRow.big and not reusedSpace) then
				-- Previous row starts with a big buff at start, so we try to use the odd space between rows
				-- for normal size buffs instead of starting a new row and having a buff width of wasted space.
				-- So we get:
				--	1123456
				--	11789AB
				--	CDEF
				-- Instead of:
				--	1123456
				--	11
				--	789ABCD
				--	EF

				local tempColPoint = (buffSizeBase * 2) + 1
				local j = prevRowI
				while (j < #list) do
					local temp = list[j + 1]
					if (temp and temp.big) then
						tempColPoint = tempColPoint + (buffSizeBase * 2) + 1
						j = j + 1
					else
						break
					end
				end

				if (tempColPoint < rowSize - buffSizeBase) then		--  and rowsHeight - buffSizeBase - 1 >= self.buffSpacing.smallRowHeight
					local prevRowBig, prevRowBigI = list[j], j
					colPoint = tempColPoint
					buff:SetPoint(self.BOTTOMLEFT, prevRowBig, self.BOTTOMRIGHT, self.SPACING, 0)
				else
					buff:SetPoint(self.TOPLEFT, prevRow, self.BOTTOMLEFT, 0, self.VSPACING)
					prevRow, prevRowI = buff, i
				end
				reusedSpace = true
			else
				buff:SetPoint(self.TOPLEFT, prevRow, self.BOTTOMLEFT, 0, self.VSPACING)
				prevRow, prevRowI = buff, i
				reusedSpace = nil

				if (buff.big) then
					if (curRow == maxRows) then
						maxRows = maxRows + 1
						decrementMaxRowsIfLastIsBig = true
					end
				end
			end
		else
			buff:SetPoint(self.TOPLEFT, prevBuff, self.TOPRIGHT, self.SPACING, 0)
		end

		colPoint = colPoint + buffSize + 1

		local nextBuff = list[i + 1]
		local nextBuffSize = buffSize
		if (nextBuff) then
			nextBuffSize = (nextBuff.big and (buffSizeBase * 2)) or buffSizeBase
		end

		if (self.conf.buffs.wrap and colPoint + nextBuffSize + 1 > rowSize) then
			if (buff.big and decrementMaxRowsIfLastIsBig) then
				decrementMaxRowsIfLastIsBig = nil
				maxRows = maxRows - 1
			end

			colPoint = 0
			curRow = curRow + 1
			if (prevRow.big) then
				rowsHeight = rowsHeight + (buffSize * 2) + 1
			else
				rowsHeight = rowsHeight + buffSize + 1
			end
			firstOfRow = true
		end

		prevBuff = buff
	end

	if (hideFrom) then
		for i = hideFrom,#list do
			list[i]:Hide()
		end
	end
	if (useSmallStart) then
		self.hideFrom1 = hideFrom
	else
		self.hideFrom2 = hideFrom
	end

	self.prevBuff = prevRow
end

-- TPerl_Unit_BuffPositions
function TPerl_Unit_BuffPositions(self, buffList1, buffList2, size1, size2)
	local optMix
	if not IsRetail then
	 optMix = format("%d%d%d%d%d%d%d", self.perlBuffs or 0, self.perlDebuffs or 0, self.perlBuffsMine or 0, self.perlDebuffsMine or 0, UnitCanAttack("player", self.partyid) and 1 or 0, (UnitPowerMax(self.partyid) > 0) and 1 or 0, (self.creatureTypeFrame and self.creatureTypeFrame:IsVisible()) and 1 or 0)
	else
	optMix = format("%d%d%d%d%d%d%d", self.perlBuffs or 0, self.perlDebuffs or 0, self.perlBuffsMine or 0, self.perlDebuffsMine or 0, UnitCanAttack("player", self.partyid) and 1 or 0, 0, (self.creatureTypeFrame and self.creatureTypeFrame:IsVisible()) and 1 or 0)
	end
	if (optMix ~= self.buffOptMix) then
		if self.partyid ~= "player" then
		 WieghAnchor(self)
		end

		local buffsFirst = self.buffFrame.buff == buffList1

		self.buffOptMix = optMix
		self.prevBuff = nil

		if (self.GetBuffSpacing) then
			self:GetBuffSpacing(self)
		else
			TPerl_Unit_BuffSpacing(self)
		end

		-- De-anchor first 2 because faction changes can mess up the order of things.
		if (buffList1 and buffList1[1]) then
			buffList1[1]:ClearAllPoints()
		end
		if (buffList2 and buffList2[1]) then
			buffList2[1]:ClearAllPoints()
		end

		if (buffList1) then
			TPerl_Unit_BuffPositionsType(self, buffList1, true, size1)
		end
		if (buffList2) then
			TPerl_Unit_BuffPositionsType(self, buffList2, false, size2)
		end

		if (buffList2) then
			-- If top row is disabled, then nudge the bottom row into it's place
			if (buffsFirst) then
				if (not self.conf.buffs.enable) then
					buffList2[1]:SetPoint(self.TOPLEFT, self.buffFrame, self.TOPLEFT, 0, self.VSPACING)
				end
			else
				if (not self.conf.debuffs.enable) then
					buffList2[1]:SetPoint(self.TOPLEFT, self.buffFrame, self.TOPLEFT, 0, self.VSPACING)
				end
			end
		end
	else
		if (self.hideFrom1 and buffList1) then
			for i = self.hideFrom1,#buffList1 do
				buffList1[i]:Hide()
			end
		end
		if (self.hideFrom2 and buffList2) then
			for i = self.hideFrom2,#buffList2 do
				buffList2[i]:Hide()
			end
		end
	end
end

--[[local function fixMeBlizzard(self)
	self.anim:Play()
	self:SetScript("OnUpdate", nil)
end]]

-- TPerl_Unit_UpdateBuffs(self)
function TPerl_Unit_UpdateBuffs(self, maxBuffs, maxDebuffs, castableOnly, curableOnly)
	local buffs, debuffs, buffsMine, debuffsMine = 0, 0, 0, 0
	local partyid = self.partyid

	if (self.conf and UnitExists(partyid)) then
		if (not maxBuffs) then
			maxBuffs = 40
		end
		if (not maxDebuffs) then
			maxDebuffs = 40
		end
		local lastIcon = 0

		TPerl_GetBuffButton(self, 1, 0, true)
		TPerl_GetBuffButton(self, 1, 1, true)

		local isFriendly = not UnitCanAttack("player", partyid)

		if (self.conf.buffs.enable and maxBuffs and maxBuffs > 0) then
			local buffIconIndex = 1
			local playerBuffByID
			if (IsRetail and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
				playerBuffByID = { }
				for i = 1, maxBuffs do
					local aura = TPerl_SafeGetAuraDataByIndex(partyid, i, "HELPFUL|PLAYER")
					if (not aura) then
						break
					end
					local aid = aura.auraInstanceID
					if (aid) then
						playerBuffByID[aid] = true
					end
				end
			end
			self.buffFrame:Show()
			for mine = 1, 2 do
				if (self.conf.buffs.onlyMine and mine == 2) then
					if (not UnitCanAttack("player", partyid)) then
						break
					end
					-- else we'll ignore this option for enemy targets, because
					-- it's unlikey that we'll be buffing them
				end
				-- Two passes here now since 3.0.1, cos they did away with the GetPlayerBuff function
				-- in favor of all in UnitAura instead. We still want our big buffs first in the list,
				-- so we have to scan thru twice. I know what you're thinking: "Why do 2 passes when
				-- player's buffs are first anyway". Well, usually they are, but in the case of hunters
				-- and warlocks, the pet triggered buffs can be anywhere, but we still want those alongside
				-- our own buffs.
				for buffnum = 1, maxBuffs do
					local filter = castableOnly == 1 and "HELPFUL|RAID" or "HELPFUL"
					local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID = TPerl_UnitBuff(partyid, buffnum, filter)
					if (not name) then
						if (mine == 1) then
							maxBuffs = buffnum - 1
						end
						break
					end

						-- Midnight: grab auraInstanceID (NeverSecret) so we can ask the engine for displayable info
						-- (stack count, duration) even when UnitAura results are secret.
						local auraInstanceID
						if (IsRetail and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
							local aura = TPerl_SafeGetAuraDataByIndex(partyid, buffnum, filter)
							auraInstanceID = aura and aura.auraInstanceID
						end

					local isPlayer = false
					local canSteal = TPerl_SafeBool(canStealOrPurge)

					-- Midnight: Prefer auraInstanceID mapping to decide if this buff is ours (avoids secret-string caster issues).
					if (playerBuffByID and auraInstanceID and playerBuffByID[auraInstanceID]) then
						isPlayer = true
					end

					if (unitCaster ~= nil and TPerl_CanAccess(unitCaster)) then
						if (self.conf.buffs.bigpet) then
							isPlayer = (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle")
						else
							isPlayer = (unitCaster == "player" or unitCaster == "vehicle")
						end
					elseif (nameplateShowPersonal ~= nil and TPerl_CanAccess(nameplateShowPersonal)) then
						-- Fallback when caster is a "secret string"
						isPlayer = nameplateShowPersonal and true or false
					end

					if (icon and (((mine == 1) and (isPlayer or canSteal)) or ((mine == 2) and not (isPlayer or canSteal)))) then
						local button = TPerl_GetBuffButton(self, buffIconIndex, 0, true, buffnum)
						button.filter = filter
						button:SetAlpha(1)

						buffs = buffs + 1

							button.icon:SetTexture(icon)
							TPerl_SetAuraStackText(button, count, partyid, auraInstanceID)

	-- Handle cooldowns
	if (button.cooldown) then
		local canCooldown = (conf.buffs.cooldown and (isPlayer or conf.buffs.cooldownAny))
		if (canCooldown) then
			-- If aura timing is accessible, keep the classic path (lets our custom countdown work).
			if (duration and expirationTime and TPerl_CanAccess(duration) and TPerl_CanAccess(expirationTime) and duration > 0 and expirationTime > 0) then
				local start = expirationTime - duration
				TPerl_CooldownFrame_SetTimer(button.cooldown, start, duration, 1, isPlayer)
			else
				-- Midnight: fall back to DurationObject for restricted/secret aura timing.
				-- We can't run our own countdown on secret time; allow Blizzard to render countdown numbers.
				if (auraInstanceID and C_UnitAuras and C_UnitAuras.GetAuraDuration and button.cooldown.SetCooldownFromDurationObject) then
					local durObj
						if (TPerl_UnitTokenAllowsC_UnitAuras(partyid)) then
							local okDur, d = pcall(C_UnitAuras.GetAuraDuration, partyid, auraInstanceID)
							if (okDur) then durObj = d end
						end
					if (durObj) then
						button.cooldown.endTime = nil
						button.cooldown:SetScript("OnUpdate", nil)
						if (button.cooldown.countdown) then
							button.cooldown.countdown:Hide()
						end
						button.cooldown:SetCooldownFromDurationObject(durObj, true)
						if (conf.buffs.countdown or conf.buffs.blizzard) then
							TPerl_EnableBlizzardCooldownText(button.cooldown)
						end
						button.cooldown:Show()
					else
						button.cooldown:Hide()
					end
				else
					button.cooldown:Hide()
				end
			end
		else
			button.cooldown:Hide()
		end
	end
						button:Show()

						if (canSteal) then
							if (not button.steal) then
								button.steal = CreateFrame("Frame", nil, button, BackdropTemplateMixin and "BackdropTemplate")
								button.steal:SetPoint("TOPLEFT", -2, 2)
								button.steal:SetPoint("BOTTOMRIGHT", 2, -2)

								button.steal.tex = button.steal:CreateTexture(nil, "OVERLAY")
								button.steal.tex:SetAllPoints()
								button.steal.tex:SetTexture("Interface\\Addons\\TPerl\\Images\\StealMe")

								local g = button.steal.tex:CreateAnimationGroup()
								button.steal.anim = g
								local r = g:CreateAnimation("Rotation")
								g.rot = r

								r:SetDuration(4)
								r:SetDegrees(-360)
								r:SetOrigin("CENTER", 0, 0)

								g:SetLooping("REPEAT")
								g:Play()
							end

							button.steal:Show()
							button.steal.anim:Play()
						else
							if (button.steal) then
								button.steal:Hide()
							end
						end

						lastIcon = buffIconIndex

						if ((self.conf.buffs.big and isPlayer) or (self.conf.buffs.bigStealable and canSteal)) then
							buffsMine = buffsMine + 1
							button.big = true
							button:SetScale((self.conf.buffs.size * 2) / 32)
						else
							button.big = nil
							button:SetScale(self.conf.buffs.size / 32)
						end
						buffIconIndex = buffIconIndex + 1
					end
				end
			end
			for buffnum = lastIcon + 1, 40 do
				local button = self.buffFrame.buff and self.buffFrame.buff[buffnum]
				if (button) then
					button.expireTime = nil
					button:Hide()
				else
					break
				end
			end
		else
			self.buffFrame:Hide()
		end

		if (self.conf.debuffs.enable and maxDebuffs and maxDebuffs > 0) then
			local buffIconIndex = 1
			local playerDebuffByID
			if (IsRetail and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
				playerDebuffByID = { }
				-- Use auraInstanceID (NeverSecret) so we can reliably detect our debuffs even when UnitAura returns secret values
				for i = 1, maxDebuffs do
					local aura = TPerl_SafeGetAuraDataByIndex(partyid, i, "HARMFUL|PLAYER")
					if (not aura) then
						break
					end
					local aid = aura.auraInstanceID
					if (aid) then
						playerDebuffByID[aid] = true
					end
				end
			end
			self.debuffFrame:Show()
			lastIcon = 0
			for mine = 1, 2 do
				if (self.conf.debuffs.onlyMine and mine == 2) then
					if (UnitCanAttack("player", partyid)) then
						break
					end
					-- Else we'll ignore this option for friendly targets, because it's unlikey
					-- (except for PW:Shield and HoProtection) that we'll be debuffing friendlies
				end

				for buffnum = 1, maxDebuffs do
					-- NOTE: "HARMFUL|RAID" is not a reliable way to filter "curable" debuffs.
					-- Always scan normal harmful auras, then apply our own "curable" filter using the debuffType.
					local filter = "HARMFUL"
					local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, auraIndex = TPerl_UnitDebuff(partyid, buffnum, filter)

					if (not name) then
						if (mine == 1) then
							maxDebuffs = buffnum - 1
						end
						break
					end

local isPlayer = false
local auraInstanceID
-- Midnight: prefer auraInstanceID (NeverSecret) + a PLAYER-filter scan to decide if the aura is ours.
if (IsRetail and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
	local aura = TPerl_SafeGetAuraDataByIndex(partyid, auraIndex or buffnum, filter)
	auraInstanceID = aura and aura.auraInstanceID
	if (playerDebuffByID and auraInstanceID and playerDebuffByID[auraInstanceID]) then
		isPlayer = true
	end
end
					if (not isPlayer) then
						if (unitCaster ~= nil and TPerl_CanAccess(unitCaster)) then
							if (self.conf.buffs.bigpet) then
								isPlayer = (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle")
							else
								isPlayer = (unitCaster == "player")
							end
						elseif (nameplateShowPersonal ~= nil and TPerl_CanAccess(nameplateShowPersonal)) then
							-- Fallback when caster is a "secret string"
							isPlayer = nameplateShowPersonal and true or false
						end
					end
					local showDebuff = true
					-- "Curable" option (party/pet/etc): show only dispellable types, even if our class can't dispel.
					-- Apply this only for friendly units (where this option makes sense).
					if (isFriendly and curableOnly == 1) then
						local dt = TPerl_NormalizeDispelType(debuffType)
						if (dt) then
							showDebuff = (dt == "Magic" or dt == "Curse" or dt == "Disease" or dt == "Poison")
						else
							-- If the type is restricted/secret/unknown, don't treat it as "curable".
							showDebuff = false
						end
					end

					if (showDebuff and icon and (((mine == 1) and isPlayer) or ((mine == 2) and not isPlayer))) then
						local button = TPerl_GetBuffButton(self, buffIconIndex, 1, true, buffnum)
						button.filter = filter
						button:SetAlpha(1)

						debuffs = debuffs + 1

							button.icon:SetTexture(icon)
							TPerl_SetAuraStackText(button, count, partyid, auraInstanceID)

						local debuffKey = "none"
						local dt = TPerl_NormalizeDispelType(debuffType)
						if (dt) then
							debuffKey = dt
						elseif (TPerl_CanAccess(debuffType)) then
							-- Accessible but unknown string: keep it; colour lookup will fall back to 'none'
							debuffKey = debuffType
						end
						local borderColor = TPerl_GetDebuffTypeColorSafe(debuffKey)
						button.border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)
												-- Handle cooldowns
							if (button.cooldown) then
								local canCooldown = (conf.buffs.cooldown and (isPlayer or conf.buffs.cooldownAny))
								if (canCooldown) then
									local usedDurationObj
									-- Midnight: prefer DurationObject; if values aren't secret, also feed SetCooldown for text addons.
									if (auraInstanceID and C_UnitAuras and C_UnitAuras.GetAuraDuration and button.cooldown.SetCooldownFromDurationObject) then
										local durObj
						if (TPerl_UnitTokenAllowsC_UnitAuras(partyid)) then
							local okDur, d = pcall(C_UnitAuras.GetAuraDuration, partyid, auraInstanceID)
							if (okDur) then durObj = d end
						end
										if (durObj) then
											usedDurationObj = true
											-- Clear any old per-icon countdown state; we'll re-enable it below when safe.
											button.cooldown.endTime = nil
											button.cooldown:SetScript("OnUpdate", nil)
											if (button.cooldown.countdown) then
												button.cooldown.countdown:Hide()
											end

											if (durObj.HasSecretValues and not durObj:HasSecretValues()) then
												local start = durObj.GetStartTime and durObj:GetStartTime()
												local total = durObj.GetTotalDuration and durObj:GetTotalDuration()
												local modRate = (durObj.GetModRate and durObj:GetModRate()) or 1
												if (start and total and TPerl_CanAccess(start) and TPerl_CanAccess(total) and total > 0) then
													button.cooldown:SetCooldown(start, total, modRate)
													button.cooldown.endTime = start + total
													if (conf.buffs.countdown and (isPlayer or conf.buffs.countdownAny)) then
														button.cooldown:SetScript("OnUpdate", BuffCooldownDisplay)
													end
												else
													button.cooldown:SetCooldownFromDurationObject(durObj, true)
												end
											else
														button.cooldown:SetCooldownFromDurationObject(durObj, true)
														-- Custom countdown can't run on secret time; allow Blizzard to render the countdown numbers.
														if (conf.buffs.countdown or conf.buffs.blizzard) then
															TPerl_EnableBlizzardCooldownText(button.cooldown)
														end
											end

											button.cooldown:Show()
										end
									end
									if (not usedDurationObj) then
										if (duration and expirationTime and TPerl_CanAccess(duration) and TPerl_CanAccess(expirationTime) and duration > 0 and expirationTime > 0) then
											local start = expirationTime - duration
											TPerl_CooldownFrame_SetTimer(button.cooldown, start, duration, 1, isPlayer)
										else
											button.cooldown:Hide()
										end
									end
								else
									button.cooldown:Hide()
								end
							end

lastIcon = buffIconIndex
						button:Show()

						if (self.conf.debuffs.big and isPlayer) then
							debuffsMine = debuffsMine + 1
							button.big = true
							button:SetScale((self.conf.debuffs.size * 2) / 32)
						else
							button.big = nil
							button:SetScale(self.conf.debuffs.size / 32)
						end
						buffIconIndex = buffIconIndex + 1
					end
				end
			end
			for buffnum = lastIcon + 1, 40 do
				local button = self.buffFrame.debuff and self.buffFrame.debuff[buffnum]
				if (button) then
					button.expireTime = nil
					button:Hide()
				else
					break
				end
			end
		else
			self.debuffFrame:Hide()
		end
	end

	self.perlBuffs = buffs
	self.perlDebuffs = debuffs

	if (self.conf and self.conf.buffs.big) then
		self.perlBuffsMine = buffsMine
		self.perlDebuffsMine = debuffsMine
	else
		self.perlBuffsMine, self.perlDebuffsMine = nil, nil
	end
end

-- TPerl_SetBuffSize
function TPerl_SetBuffSize(self)
	local sizeBuff = self.conf.buffs.size
	local sizeDebuff = (self.conf.debuffs and self.conf.debuffs.size) or (sizeBuff * (1 + self.buffSetup.debuffSizeMod))

	local buff
	for i = 1, 40 do
		buff = self.buffFrame.buff and self.buffFrame.buff[i]
		if (buff) then
			if (buff.big) then
				buff:SetScale((sizeBuff * 2) / 32)
			else
				buff:SetScale(sizeBuff / 32)
			end
		end

		buff = self.buffFrame.debuff and self.buffFrame.debuff[i]
		if (buff) then
			if (buff.big) then
				buff:SetScale((sizeDebuff * 2) / 32)
			else
				buff:SetScale(sizeDebuff / 32)
			end
		end

		buff = self.buffFrame.tempEnchant and self.buffFrame.tempEnchant[i]
		if (buff) then
			buff:SetScale(sizeBuff / 32)
		end
	end
end

-- TPerl_Update_RaidIcon
function TPerl_Update_RaidIcon(self, unit)
	local index = GetRaidTargetIndex(unit)
	if index then
		local mark
		if unit == "player" or unit == "vehicle" or unit == "target" or unit == "focus" then
			if self.texture then
				mark = self.texture
			else
				mark = self
			end
		else
			mark = self
		end
		SetRaidTargetIconTexture(mark, index)
		self:Show()
	else
		self:Hide()
	end
end

------------------------------------------------------------------------------
-- Flashing frames handler. Is hidden when there's nothing to do.
local FlashFrame = CreateFrame("Frame", "TPerl_FlashFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
FlashFrame.list = { }

-- TPerl_FrameFlash_OnUpdate(self, elapsed)
local function TPerl_FrameFlash_OnUpdate(self, elapsed)
	for k, v in pairs(self.list) do
		if (k.frameFlash.out) then
			k.frameFlash.alpha = k.frameFlash.alpha - elapsed
			if (k.frameFlash.alpha < 0.2) then
				k.frameFlash.alpha = 0.2
				k.frameFlash.out = nil

				if (k.frameFlash.method == "out") then
					TPerl_FrameFlashStop(k)
				end
			end
		else
			k.frameFlash.alpha = k.frameFlash.alpha + elapsed
			if (k.frameFlash.alpha > 1) then
				k.frameFlash.alpha = 1
				k.frameFlash.out = true

				if (k.frameFlash.method == "in") then
					TPerl_FrameFlashStop(k)
				end
			end
		end

		if (k.frameFlash) then
			k:SetAlpha(k.frameFlash.alpha)
		end
	end
end

FlashFrame:SetScript("OnUpdate", TPerl_FrameFlash_OnUpdate)

-- TPerl_FrameFlash
function TPerl_FrameFlash(self)
	if (not FlashFrame.list[self]) then
		if (self.frameFlash) then
			error("TPerl ["..self:GetName()..".frameFlash is set with no entry in FlashFrame.list]")
		end

		--[[self.frameFlash = TPerl_GetReusableTable()
		self.frameFlash.out = true
		self.frameFlash.alpha = 1
		self.frameFlash.shown = self:IsShown()]]
		self.frameFlash = {out = true, alpha = 1, shown = self:IsShown()}

		FlashFrame.list[self] = true
		FlashFrame:Show()
		self:Show()
	end
end

-- TPerl_FrameIsFlashing(self)
function TPerl_FrameIsFlashing(self)
	return self.frameFlash		--FlashFrame.list[self]
end

-- TPerl_FrameFlashStop
function TPerl_FrameFlashStop(self, method)
	if (not self.frameFlash) then
		return
	end

	if (method) then
		self.frameFlash.method = method
		return
	end

	if (not self.frameFlash.shown) then
		self:Hide()
	end

	--TPerl_FreeTable(self.frameFlash)
	self.frameFlash = nil

	self:SetAlpha(1)

	FlashFrame.list[self] = nil

	if (not next(FlashFrame.list)) then
		FlashFrame:Hide()
	end
end

-- TPerl_ProtectedCall
function TPerl_ProtectedCall(func, self)
	if (func) then
		if (InCombatLockdown()) then
			TPerl_OutOfCombatQueue[func] = self == nil and false or self
			--[[if (self) then
				tinsert(TPerl_OutOfCombatQueue, {func, self})
			else
				tinsert(TPerl_OutOfCombatQueue, func)
			end]]
		else
			func(self)
		end
	end
end

-- nextMember(last)
function TPerl_NextMember(_, last)
	if (last) then
		local raidCount = GetNumGroupMembers()
		if (raidCount > 0) then
			if (IsInRaid()) then
				local i = tonumber(strmatch(last, "^raid(%d+)"))
				if (i and i < raidCount) then
					i = i + 1
					local unitName, _, group, _, _, unitClass, zone, online, dead = GetRaidRosterInfo(i)
					return "raid"..i, unitName, unitClass, group, zone, online, dead
				end
			else
				local partyCount = GetNumSubgroupMembers()
				if (partyCount > 0) then
					local id
					if (last == "player") then
						id = "party1"
					else
						local i = tonumber(strmatch(last, "^party(%d+)"))
						if (i and i < partyCount) then
							i = i + 1
							id = "party"..i
						end
					end

					if (id) then
						local _, class = UnitClass(id)
						return id, UnitName(id), class, 1, "", UnitIsConnected(id), UnitIsDeadOrGhost(id)
					end
				end
			end
		end
	else
		if (IsInRaid()) then
			local unitName, _, group, _, _, unitClass, zone, online, dead = GetRaidRosterInfo(1)
			return "raid1", unitName, unitClass, group, zone, online, dead
		else
			local _, class = UnitClass("player")
			return "player", UnitName("player"), class, 1, GetRealZoneText(), 1, UnitIsDeadOrGhost("player")
		end
	end
end

-- TPerl_Unit_UpdatePortrait
function TPerl_Unit_UpdatePortrait(self, force)
	if (self.conf and self.conf.portrait) then
		if self.conf.classPortrait then
			local _, englishClass = UnitClass(self.partyid)
			if UnitIsPlayer(self.partyid) and englishClass then
				SetPortraitToTexture(self.portraitFrame.portrait, "Interface\\Icons\\ClassIcon_"..englishClass)
			else
				SetPortraitTexture(self.portraitFrame.portrait, self.partyid)
			end
		else
			SetPortraitTexture(self.portraitFrame.portrait, self.partyid)
		end
		-- If a player moves out of range for a 3D portrait, it will show their proper 2D one
		if (self.conf.portrait3D and UnitIsVisible(self.partyid)) then
			self.portraitFrame.portrait:Hide()
			local guid = UnitGUID(self.partyid)
			local guidAcc = TPerl_CanAccess(guid)
			local oldGuid = self.portraitFrame.portrait3D.guid
			local oldAcc = TPerl_CanAccess(oldGuid)
			local needsUpdate = force or (not self.portraitFrame.portrait3D:IsShown())
			if (not needsUpdate) then
				if (guidAcc and oldAcc) then
					needsUpdate = (guid ~= oldGuid)
				else
					needsUpdate = true
				end
			end
			if needsUpdate then
				self.portraitFrame.portrait3D:Show()
				self.portraitFrame.portrait3D:ClearModel()
				self.portraitFrame.portrait3D:SetUnit(self.partyid)
				self.portraitFrame.portrait3D:SetPortraitZoom(1)
				-- Don't store secret GUIDs; comparisons later would error in tainted execution
				self.portraitFrame.portrait3D.guid = guidAcc and guid or nil
			end
		else
			self.portraitFrame.portrait:Show()
			self.portraitFrame.portrait3D:Hide()
		end
	end
end

-- TPerl_Unit_UpdateLevel
function TPerl_Unit_UpdateLevel(self)
	local level = UnitLevel(self.partyid)
	local color = GetDifficultyColor(level)
	if (self.levelFrame) then
		self.levelFrame.text:SetTextColor(color.r,color.g,color.b)
		self.levelFrame.text:SetText(level)
	elseif (self.nameFrame.level) then
		if (level == 0) then
			level = ""
		end
		self.nameFrame.level:SetTextColor(color.r,color.g,color.b)
		self.nameFrame.level:SetText(level)
	end
end

-- TPerl_Unit_GetHealth
--This function sucks, it needs reworking so it self corrects /0 problems here. But i haven't quite figured out how to approach it here yet. So i just fix stuff at sethealth functions.
function TPerl_Unit_GetHealth(self)
	local partyid = self.partyid
	local hp, hpMax = UnitHealth(partyid), UnitHealthMax(partyid)
 if not IsRetail then
		if (hp > hpMax) then
			if (UnitIsGhost(partyid)) then
				hp = 1
			elseif UnitIsDead(partyid) then
				hp = 0
			else
				hp = hpMax
			end
		end
 else
	  -- Do Nothing. This code logic is not needed.
			--[[
	 if (UnitIsGhost(partyid)) then
			hp = 1
		elseif UnitIsDead(partyid) then
			hp = 0
		else
			hp = hpMax
		end
		]]--
	end
	
	if not IsRetail then
	 return hp or 0, hpMax or 1, (hpMax == 100)
	else
	 return hp, hpMax, false
	end
end

-- TPerl_Unit_OnEnter
function TPerl_Unit_OnEnter(self)
	TPerl_PlayerTip(self)
	if (self.highlight) then
		self.highlight:Select()
	end

	if (self.statsFrame and self.statsFrame.healthBar and self.statsFrame.healthBar.text and not self.statsFrame.healthBar.text:IsShown()) then
		self.hideValues = true
		self.statsFrame.healthBar.text:Show()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Show()
		end
		if (self.statsFrame.xpBar and self.statsFrame.xpBar:IsShown()) then
			self.statsFrame.xpBar.text:Show()
		end
		if (self.statsFrame.repBar and self.statsFrame.repBar:IsShown()) then
			self.statsFrame.repBar.text:Show()
		end
	end
end

-- TPerl_Unit_OnLeave
function TPerl_Unit_OnLeave(self)
	TPerl_PlayerTipHide()
	if (self.highlight) then
		self.highlight:Deselect()
	end

	if (self.hideValues) then
		self.hideValues = nil

		self.statsFrame.healthBar.text:Hide()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Hide()
		end
		if (self.statsFrame.xpBar and self.statsFrame.xpBar:IsShown()) then
			self.statsFrame.xpBar.text:Hide()
		end
		if (self.statsFrame.repBar and self.statsFrame.repBar:IsShown()) then
			self.statsFrame.repBar.text:Hide()
		end
	end
end

-- TPerl_Unit_SetBuffTooltip
function TPerl_Unit_SetBuffTooltip(self)
	if (conf and conf.tooltip.enableBuffs and TPerl_TooltipModiferPressed(true)) then
		if (not conf.tooltip.buffHideInCombat or not InCombatLockdown()) then
			local frame = self:GetParent():GetParent()
			local partyid = frame.partyid
			if (partyid) then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 0)
				TPerl_TooltipSetUnitBuff(GameTooltip, partyid, self:GetID(), self.filter)
			end
		end
	end
end

-- TPerl_Unit_SetDeBuffTooltip
function TPerl_Unit_SetDeBuffTooltip(self)
	if (conf and conf.tooltip.enableBuffs and TPerl_TooltipModiferPressed(true)) then
		if (not conf.tooltip.hideInCombat or not InCombatLockdown()) then
			local frame = self:GetParent():GetParent()
			local partyid = frame.partyid
			if (partyid) then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 0)
				TPerl_TooltipSetUnitDebuff(GameTooltip, partyid, self:GetID(), self.filter)
			end
		end
	end
end

-- TPerl_Unit_UpdateReadyState
function TPerl_Unit_UpdateReadyState(self)
	local status = conf.showReadyCheck and self.partyid and GetReadyCheckStatus(self.partyid)
	if status then
		self.statsFrame.ready:Show()
		if status == "ready" then
			if IsRetail then
				self.statsFrame.ready.check:SetAtlas(READY_CHECK_READY_TEXTURE)
			else
				self.statsFrame.ready.check:SetTexture(READY_CHECK_READY_TEXTURE)
			end
		elseif status == "waiting" then
			if IsRetail then
				self.statsFrame.ready.check:SetAtlas(READY_CHECK_WAITING_TEXTURE)
			else
				self.statsFrame.ready.check:SetTexture(READY_CHECK_WAITING_TEXTURE)
			end
		elseif status == "notready" then
			if IsRetail then
				self.statsFrame.ready.check:SetAtlas(READY_CHECK_NOT_READY_TEXTURE)
			else
				self.statsFrame.ready.check:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
			end
		else
			self.statsFrame.ready:Hide()
		end
	else
		self.statsFrame.ready:Hide()
	end
end

-- TPerl_SwitchAnchor(self, new)
-- Changes anchored corner without actually moving the frame

-- TPerl_SwitchAnchor
function TPerl_SwitchAnchor(self, New)
	if (not self:GetPoint(2)) then
		local a1, f, a2, x, y = self:GetPoint(1)

		if (a1 == a2 and New ~= a1) then
			local parent = self:GetParent()
			local newV = strmatch(New, "TOP") or strmatch(New, "BOTTOM")
			local newH = strmatch(New, "LEFT") or strmatch(New, "RIGHT")

			if (newV == "TOP") then
				y = -(768 - (self:GetTop() * self:GetEffectiveScale())) / self:GetEffectiveScale()
			elseif (newV == "BOTTOM") then
				y = self:GetBottom()
			else
				y = self:GetBottom() + self:GetHeight() / 2
			end

			if (newH == "LEFT") then
				x = self:GetLeft()
			elseif (newV == "RIGHT") then
				x = self:GetRight()
			else
				x = self:GetLeft() + self:GetWidth() / 2
			end

			self:ClearAllPoints()
			self:SetPoint(New, f, New, x, y)
		end
	end
end

---------------------------------
-- Scaling frame corner thingy --
---------------------------------
-- Seems a convoluted way of doing things, rather than just anchoring bottomleft, topright.. but
-- doing that introduces a really ugly latency between the anchor moving and the frame scaling because
-- the OnSizeChanged event is fired on the frame after the actual resize took place.

local scaleIndication

local function scaleMouseDown(self)

	GameTooltip:Hide()

	if (self.resizable and IsShiftKeyDown()) then
		self.sizing = true
	elseif (self.scalable) then
		self.scaling = true
	end

	if (not scaleIndication) then
		scaleIndication = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		scaleIndication:SetWidth(100)
		scaleIndication:SetHeight(18)
		scaleIndication.text = scaleIndication:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		scaleIndication.text:SetAllPoints()
		scaleIndication.text:SetJustifyH("LEFT")
	end

	scaleIndication:Show()
	scaleIndication:ClearAllPoints()
	scaleIndication:SetPoint("LEFT", self, "RIGHT", 4, 0)

	if (self.scaling) then
		scaleIndication.text:SetFormattedText("%.1f%%", self.frame:GetScale() * 100)
	else
		scaleIndication.text:SetFormattedText("%dx%d", self.frame:GetWidth(), self.frame:GetHeight())
	end

	self.anchor:StartSizing(self.resizeTop and "TOPRIGHT")

	self.oldBdBorder = {self.frame:GetBackdropBorderColor()}
	self.frame:SetBackdropBorderColor(1, 1, 0.5, 1)
end

local function scaleMouseUp(self)
	self.anchor:StopMovingOrSizing()

	scaleIndication:Hide()

	TPerl_SavePosition(self.anchor)

	if self.resizeTop then
		TPerl_SwitchAnchor(self.anchor, "BOTTOMLEFT")
	end

	if self.scaling then
		if self.onScaleChanged then
			self:onScaleChanged(self.frame:GetScale())
		end
	end

	if self.sizing then
		if self.onSizeChanged then
			self:onSizeChanged(self.frame:GetWidth(), self.frame:GetHeight())
		end
	end

	if self.oldBdBorder then
		self.frame:SetBackdropBorderColor(unpack(self.oldBdBorder))
		self.oldBdBorder = nil
	end

	self.scaling = nil
	self.sizing = nil
end

local function scaleMouseChange(self)
	if (self.corner.sizing) then
		self.corner.frame:SetWidth(self:GetWidth() / self.corner.frame:GetScale())
		self.corner.frame:SetHeight(self:GetHeight() / self.corner.frame:GetScale())

		self.corner.startSize.w = self.corner.frame:GetWidth()
		self.corner.startSize.h = self.corner.frame:GetHeight()

		if (scaleIndication and scaleIndication:IsShown()) then
			scaleIndication.text:SetFormattedText("|c00FFFF80%d|c00808080x|c00FFFF80%d", self.corner.frame:GetWidth(), self.corner.frame:GetHeight())
		end

	elseif (self.corner.scaling) then
		local w = self:GetWidth()
		if (w) then
			self.corner.scaling = nil
			local ratio = self.corner.frame:GetWidth() / self.corner.frame:GetHeight()
			local s = min(self.corner.maxScale, max(self.corner.minScale, w / self.corner.startSize.w))	-- New Scale

			w = self.corner.startSize.w * s		-- Set height and width of anchor window to match ratio of actual
			if (self.corner.resizeTop) then
				TPerl_SwitchAnchor(self, "BOTTOMLEFT")
				local bottom, left = self:GetBottom(), self:GetLeft()
				self:SetWidth(w)
				self:SetHeight(w / ratio)
			else
				self:SetWidth(w)
				self:SetHeight(w / ratio)
			end

			if (scaleIndication and scaleIndication:IsShown()) then
				scaleIndication.text:SetFormattedText("%.1f%%", s * 100)
			end

			self.corner.frame:SetScale(s)
			self.corner.scaling = true
		end
	end
end

-- scaleMouseEnter
local function scaleMouseEnter(self)
	self.tex:SetVertexColor(1, 1, 1, 1)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if (self.scalable) then
		GameTooltip:SetText(TPERL_DRAGHINT1, nil, nil, nil, nil, true)
	end
	if (self.resizable) then
		GameTooltip:AddLine(TPERL_DRAGHINT2, nil, nil, nil, true)
	end
	GameTooltip:Show()
end

-- scaleMouseLeave
local function scaleMouseLeave(self)
	self.tex:SetVertexColor(1, 1, 1, 0.5)
	GameTooltip:Hide()
end

-- TPerl_RegisterScalableFrame
function TPerl_RegisterScalableFrame(self, anchorFrame, minScale, maxScale, resizeTop, resizable, scalable)
	if (scalable == nil) then
		scalable = true
	end

	if (not self.corner) then
		self.corner = CreateFrame("Frame", nil, self)
		self.corner:SetFrameLevel(self:GetFrameLevel() + 3)
		self.corner:EnableMouse(true)
		self.corner:SetScript("OnMouseDown", scaleMouseDown)
		self.corner:SetScript("OnMouseUp", scaleMouseUp)
		self.corner:SetScript("OnEnter", scaleMouseEnter)
		self.corner:SetScript("OnLeave", scaleMouseLeave)
		self.corner:SetHeight(12)
		self.corner:SetWidth(12)

		anchorFrame:SetScript("OnSizeChanged", scaleMouseChange)
		anchorFrame.corner = self.corner

		self.corner.tex = self.corner:CreateTexture(nil, "BORDER")
		self.corner.tex:SetTexture("Interface\\Addons\\TPerl\\Images\\TPerl_Elements")
		self.corner.tex:SetAllPoints()
		self.corner.tex:SetVertexColor(1, 1, 1, 0.5)

		self.corner.anchor = anchorFrame
		self.corner.frame = self
	end

	if self.SetResizeBounds then
		self:SetResizeBounds(10, 10)
	else
		self:SetMinResize(10, 10)
	end

	self.corner.scalable = scalable
	self.corner.resizable = resizable
	self.corner.resizeTop = resizeTop
	self.corner.minScale = minScale or 0.4
	self.corner.maxScale = maxScale or 5
	self.corner.startSize = {w = self:GetWidth(), h = self:GetHeight()}

	local bgDef = self:GetBackdrop()

	self.corner:ClearAllPoints()
	if (resizeTop) then
		self.corner.tex:SetTexCoord(0.78125, 1, 0.5, 0.703125)
		self.corner:SetPoint("TOPRIGHT", -bgDef.insets.right, -bgDef.insets.top)
		self.corner:SetHitRectInsets(0, -6, -6, 0)		-- So the click area extends over the tooltip border
	else
		self.corner.tex:SetTexCoord(0.78125, 1, 0.78125, 1)
		self.corner:SetPoint("BOTTOMRIGHT", -bgDef.insets.right, bgDef.insets.bottom)
		self.corner:SetHitRectInsets(0, -6, 0, -6)		-- So the click area extends over the tooltip border
	end

	self.corner.scaling = true
	scaleMouseChange(anchorFrame)
	self.corner.scaling = nil
end

-- TPerl_SetExpectedAbsorbs
function TPerl_SetExpectedAbsorbs(self)
	local bar
	if self.statsFrame and self.statsFrame.expectedAbsorbs then
		bar = self.statsFrame.expectedAbsorbs
	else
		bar = self.expectedAbsorbs
	end
	if (bar) then
		local unit = self.partyid

		if not unit then
			unit = self:GetParent().targetid
		end
		
		if not IsRetail then
		 local amount = not IsClassic and UnitGetTotalAbsorbs(unit)
			
			if (amount and amount > 0 and not UnitIsDeadOrGhost(unit)) then
				local healthMax = UnitHealthMax(unit)
				local health = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit))

				if UnitIsAFK(unit) then
					bar:SetStatusBarColor(0.2, 0.2, 0.2, 0.7)
				else
					if not conf.colour.bar.absorb then
						conf.colour.bar.absorb = { }
						conf.colour.bar.absorb.r = 0.14
						conf.colour.bar.absorb.g = 0.33
						conf.colour.bar.absorb.b = 0.7
						conf.colour.bar.absorb.a = 0.7
					end

					bar:SetStatusBarColor(conf.colour.bar.absorb.r, conf.colour.bar.absorb.g, conf.colour.bar.absorb.b, conf.colour.bar.absorb.a)
				end

				bar:Show()
				bar:SetMinMaxValues(0, healthMax)

				local healthBar
				if self.statsFrame and self.statsFrame.healthBar then
					healthBar = self.statsFrame.healthBar
				else
					healthBar = self.healthBar
				end
				local min, max = healthBar:GetMinMaxValues()
				local position = ((max - healthBar:GetValue()) / max) * healthBar:GetWidth()

				if healthBar:GetWidth() <= 0 or healthBar:GetWidth() == position then
					return
				end

				bar:SetValue(amount * (healthBar:GetWidth() / (healthBar:GetWidth() - position)))

				bar:SetPoint("TopRight", healthBar, "TopRight", -position, 0)
				bar:SetPoint("BottomRight", healthBar, "BottomRight", -position, 0)
				return
			end
		else
			-- Retail/Midnight: show total damage absorbs (all sources).
			-- Values may be "secret" in tainted code, so avoid boolean tests/comparisons on them.
			local okAmt, amount = pcall(UnitGetTotalAbsorbs, unit)
			if okAmt then
				-- If the >0 comparison is blocked (secret number), default to showing and let SetValue decide.
				local show = false
				local okShow, resShow = pcall(function()
					return amount > 0
				end)
				if okShow then
					show = resShow
				else
					show = true
				end
				if show and not TPerl_SafeBool(UnitIsDeadOrGhost(unit)) then
					local healthBar
					if self.statsFrame and self.statsFrame.healthBar then
						healthBar = self.statsFrame.healthBar
					else
						healthBar = self.healthBar
					end
					local isAFK = TPerl_SafeBool(UnitIsAFK(unit))
					if (isAFK) then
						bar:SetStatusBarColor(0.2, 0.2, 0.2, 0.7)
					else
						if not conf.colour.bar.absorb then
							conf.colour.bar.absorb = { r = 0.14, g = 0.33, b = 0.7, a = 0.7 }
						end
						bar:SetStatusBarColor(conf.colour.bar.absorb.r, conf.colour.bar.absorb.g, conf.colour.bar.absorb.b, conf.colour.bar.absorb.a)
					end
					-- Draw absorbs as a light overlay on top of the HP bar (legacy TPerl/XPerl style).
					if (healthBar) then
						bar:ClearAllPoints()
						bar:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
						bar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
						if bar.SetFrameLevel and healthBar.GetFrameLevel then
							bar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
						end
					end
					pcall(function()
						bar:SetReverseFill(true)
					end)
					local okMax, healthMax = pcall(UnitHealthMax, unit)
					local okMM = false
					if okMax then
						okMM = pcall(bar.SetMinMaxValues, bar, 0, healthMax)
					end
					if not okMM then
						pcall(bar.SetMinMaxValues, bar, 0, 1)
					end
					local okSet = pcall(bar.SetValue, bar, amount)
					if okSet then
						bar:Show()
						return
					end
				end
			end
		end
		bar:Hide()
	end
end

-- TPerl_SetExpectedHots
function TPerl_SetExpectedHots(self)
	if WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then
		return
	end
	local bar
	if self.statsFrame and self.statsFrame.expectedHots then
		bar = self.statsFrame.expectedHots
	else
		bar = self.expectedHots
	end
	if (bar) then
		local unit = self.partyid

		if not unit then
			unit = self:GetParent().targetid
		end

		local amount
		if IsVanillaClassic then
			local guid = UnitGUID(unit)
			amount = (HealComm:GetHealAmount(guid, HealComm.OVERTIME_HEALS, GetTime() + 3) or 0) * HealComm:GetHealModifier(guid)
		end

		if (amount and amount > 0 and not UnitIsDeadOrGhost(unit)) then
			local healthMax = UnitHealthMax(unit)
			local health = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit))

			if UnitIsAFK(unit) then
				bar:SetStatusBarColor(0.2, 0.2, 0.2, 0.7)
			else
				bar:SetStatusBarColor(conf.colour.bar.hot.r, conf.colour.bar.hot.g, conf.colour.bar.hot.b, conf.colour.bar.hot.a)
			end

			bar:Show()
			bar:SetMinMaxValues(0, healthMax)
			bar:SetValue(min(healthMax, health + amount))

			return
		end
		bar:Hide()
	end
end

-- TPerl_SetExpectedHealth
function TPerl_SetExpectedHealth(self)
			local bar
			if self.statsFrame and self.statsFrame.expectedHealth then
				bar = self.statsFrame.expectedHealth
			else
				bar = self.expectedHealth
			end
	
	
					if (bar) then
										local unit = self.partyid

										if not unit then
											unit = self:GetParent().targetid
										end

										local amount
										if IsVanillaClassic then
											local guid = UnitGUID(unit)
											amount = (HealComm:GetHealAmount(guid, HealComm.CASTED_HEALS, GetTime() + 3) or 0) * HealComm:GetHealModifier(guid)
										else
											amount = UnitGetIncomingHeals(unit)
										end
										
										
										if IsRetail then
								
															--[[
															--DOES NOT WORK IN RETAIL ANYMORE. RIP
															if (amount and not UnitIsDeadOrGhost(unit)) then
																local healthMax = UnitHealthMax(unit)
																local health = UnitHealth(unit)
																if not conf.colour.bar.healprediction then
																	conf.colour.bar.healprediction = { }
																	conf.colour.bar.healprediction.r = 0
																	conf.colour.bar.healprediction.g = 1
																	conf.colour.bar.healprediction.b = 1
																	conf.colour.bar.healprediction.a = 1
																end

																bar:SetStatusBarColor(conf.colour.bar.healprediction.r, conf.colour.bar.healprediction.g, conf.colour.bar.healprediction.b, conf.colour.bar.healprediction.a)

																bar:Show()
																bar:SetMinMaxValues(0, healthMax)
																bar:SetValue(min(healthMax, amount))
															end 
															]]--
															
															--TODO: Rewrite using: UnitHealth(unit, true) -- <-- the true uses blizzards predicted health amount instead.

														return
										else
														if (amount and amount > 0 and not UnitIsDeadOrGhost(unit)) then
																			local healthMax = UnitHealthMax(unit)
																			local health = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit))
																			if not conf.colour.bar.healprediction then
																				conf.colour.bar.healprediction = { }
																				conf.colour.bar.healprediction.r = 0
																				conf.colour.bar.healprediction.g = 1
																				conf.colour.bar.healprediction.b = 1
																				conf.colour.bar.healprediction.a = 1
																			end

																			bar:SetStatusBarColor(conf.colour.bar.healprediction.r, conf.colour.bar.healprediction.g, conf.colour.bar.healprediction.b, conf.colour.bar.healprediction.a)

																			bar:Show()
																			bar:SetMinMaxValues(0, healthMax)
																			bar:SetValue(min(healthMax, health + amount))

																			return
															end
											
															bar:Hide()
											end
							end
end

-- Threat Display
local function DrawHand(self, percent)
	local angle = 360 - (percent * 2.7 - 135)
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = rotate(angle)
	self.needle:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

local function DrawSlider(self, percent)
	local offset = (self:GetWidth() - 9) / 100 * percent
	self.needle:ClearAllPoints()
	self.needle:SetPoint("CENTER", self, "TOPLEFT", offset + 5, -2)

	local r, g, b
	if (percent <= 70) then
		r, g, b = 0, 1, 0
	else
		r, g, b = smoothColor(abs((percent - 100) / 30))
	end

	self.needle:SetVertexColor(r, g, b)
end

-- TPerl_ThreatDisplayOnLoad
function TPerl_ThreatDisplayOnLoad(self, mode)
	TPerl_SetChildMembers(self)
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 4)
	self.text:SetWidth(100)
	self.current, self.target = 0, 0
	self.mode = mode

	if (mode == "nameFrame") then
		self.Draw = DrawSlider
	else
		self.Draw = DrawHand
	end
	self:Draw(0)
end

-- threatOnUpdate
local function threatOnUpdate(self, elapsed)
	local diff = (self.target - self.current) * 0.2
	self.current = min(100, max(0, self.current + diff))
	if (abs(self.current - self.target) <= 0.01) then
		self.current = self.target
		self:SetScript("OnUpdate", nil)
	end

	self:Draw(self.current)
end

-- TPerl_Unit_ThreatStatus
function TPerl_Unit_ThreatStatus(self, relative, immediate)
	if (IsClassic or not self.partyid or not self.conf) then
		return
	end

	local mode = self.conf.threatMode or (self.conf.portrait and "portraitFrame" or "nameFrame")
	local t = self.threatFrames and self.threatFrames[mode]
	if (not self.conf.threat) then
		if (t) then
			t:Hide()
		end
		return
	end

	if (not t) then
		if (self.threatFrames) then
			for mode,frame in pairs(self.threatFrames) do
				frame:SetScript("OnUpdate", nil)
				frame.current, frame.target = 0, 0
				frame:Hide()
			end
		else
			self.threatFrames = {}
		end
		if (self[mode]) then -- If desired parent frame exists
			t = CreateFrame("Frame", self:GetName().."Threat"..mode, self[mode], BackdropTemplateMixin and "BackdropTemplate,TPerl_ThreatTemplate"..mode or "TPerl_ThreatTemplate"..mode)
			t:SetAllPoints()
			self.threatFrames[mode] = t
		end

		self.threat = self.threatFrames[mode]
	end

	if (t) then
		local isTanking, state, scaledPercent, rawPercent, threatValue
		local one, two
		if (UnitAffectingCombat(self.partyid) or (relative and UnitAffectingCombat(relative))) then
			if (relative and UnitCanAttack(relative, self.partyid)) then
				one, two = relative, self.partyid
			else
				if (UnitExists("target") and UnitCanAttack(self.partyid, "target")) then
					one, two = self.partyid, "target"
				elseif (UnitCanAttack("player", self.partyid)) then
					one, two = "player", self.partyid
				elseif (UnitCanAttack(self.partyid, self.partyid.."target")) then
					one, two = self.partyid, self.partyid.."target"
				end
			end

			if (one) then
				-- scaledPercent is 0% - 100%, 100 means you pull agro
				-- rawPercent is before normalization so can go up to 110% or 130% before you pull agro
				isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation(one, two)
			end
		end

			-- Midnight/Retail can return "secret" threat values which cannot be compared or used in arithmetic.
			-- Prefer the detailed scaled percent when accessible, otherwise fall back to UnitThreatSituation.
			local percent
				if (scaledPercent and TPerl_CanAccess(scaledPercent)) then
					percent = scaledPercent
				elseif (one and two and UnitThreatSituation) then
					local okTS, ts = pcall(UnitThreatSituation, one, two)
					-- In Midnight/Retail, UnitThreatSituation can also return a secret number.
					-- Never compare it unless we can access it.
					if (okTS and type(ts) == "number" and TPerl_CanAccess(ts)) then
						-- Approximate percent from threat state (0..3) to keep the UI functional.
						if (ts == 1) then
							percent = 30
						elseif (ts == 2) then
							percent = 70
						elseif (ts >= 3) then
							percent = 100
						end
					end
				end

			if (percent) then
				if (percent ~= t.target) then
					t.target = percent
					if (immediate) then
						t.current = percent
					end
					t.one = one
					t.two = two
					t:SetScript("OnUpdate", threatOnUpdate)
				end

				t.text:SetFormattedText("%d%%", percent)
				local r, g, b = smoothColor(percent)
				t.text:SetTextColor(r, g, b)

				t:Show()
				return
			end

		t:Hide()
	end
end

function TPerl_Register_Prediction(self, conf, guidToUnit, ...)
	if not self then
		return
	end

	if not IsVanillaClassic then
		if conf.healprediction then
			self:RegisterUnitEvent("UNIT_HEAL_PREDICTION", ...)
		else
			self:UnregisterEvent("UNIT_HEAL_PREDICTION")
		end

		if not (IsCataClassic or IsMistsClassic) then
			if conf.absorbs then
				self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", ...)
			else
				self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
			end
		--[[else
			-- HoT predictions do not work properly on Wrath/Cata Classic so use HealComm
			if conf.hotPrediction then
				local UpdateHealth = function(event, ...)
					local unit = guidToUnit(select(select("#", ...), ...))
					if unit then
						local f = self:GetScript("OnEvent")
						f(self, "UNIT_HEAL_PREDICTION", unit)
					end
				end
				HealComm.RegisterCallback(self, "HealComm_HealStarted", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_HealStopped", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_HealDelayed", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_HealUpdated", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_ModifierChanged", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_GUIDDisappeared", UpdateHealth)
			else
				HealComm.UnregisterCallback(self, "HealComm_HealStarted")
				HealComm.UnregisterCallback(self, "HealComm_HealStopped")
				HealComm.UnregisterCallback(self, "HealComm_HealDelayed")
				HealComm.UnregisterCallback(self, "HealComm_HealUpdated")
				HealComm.UnregisterCallback(self, "HealComm_ModifierChanged")
				HealComm.UnregisterCallback(self, "HealComm_GUIDDisappeared")
			end--]]
		end
	else
		if conf.healprediction then
			local UpdateHealth = function(event, ...)
				local unit = guidToUnit(select(select("#", ...), ...))
				if unit then
					local f = self:GetScript("OnEvent")
					f(self, "UNIT_HEAL_PREDICTION", unit)
				end
			end
			HealComm.RegisterCallback(self, "HealComm_HealStarted", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_HealStopped", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_HealDelayed", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_HealUpdated", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_ModifierChanged", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_GUIDDisappeared", UpdateHealth)
		else
			HealComm.UnregisterCallback(self, "HealComm_HealStarted")
			HealComm.UnregisterCallback(self, "HealComm_HealStopped")
			HealComm.UnregisterCallback(self, "HealComm_HealDelayed")
			HealComm.UnregisterCallback(self, "HealComm_HealUpdated")
			HealComm.UnregisterCallback(self, "HealComm_ModifierChanged")
			HealComm.UnregisterCallback(self, "HealComm_GUIDDisappeared")
		end
	end
end
------------------------------------------------------------------------------
-- Debug helpers
-- /tperl debugdebuffs
function TPerl_DebugDumpDebuffs()
	local units = { "player", "party1", "party2", "party3", "party4" }

	DEFAULT_CHAT_FRAME:AddMessage("|c00FFFF80[TPerl] Debuff dump (HARMFUL) - showing name, dispelType, normalizedType, spellId, auraId, excluded|r")

	for _, unit in ipairs(units) do
		if UnitExists(unit) then
			local uname = UnitName(unit)
			if not TPerl_CanAccess(uname) then
				uname = "<secret>"
			end
			DEFAULT_CHAT_FRAME:AddMessage(format("|c00FFFF80-- %s (%s) --|r", unit, uname or ""))
			for i = 1, 40 do
				local name, dispelName, spellId, auraId, nameUA, dispelUA, spellIdUA, nameCA, dispelCA, spellIdCA, auraIdCA, nameUD, dispelUD, spellIdUD = TPerl_GetHarmfulAura(unit, i)
				if not name then
					break
				end


				local nameSafe = (name and TPerl_CanAccess(name)) and name or "<secret>"
				local dispelSafe = (dispelName and TPerl_CanAccess(dispelName)) and tostring(dispelName) or "<nil/secret>"
				local dispelUA_safe = (dispelUA and TPerl_CanAccess(dispelUA)) and tostring(dispelUA) or "<nil/secret>"
				local dispelCA_safe = (dispelCA and TPerl_CanAccess(dispelCA)) and tostring(dispelCA) or "<nil/secret>"
				local dispelUD_safe = (dispelUD and TPerl_CanAccess(dispelUD)) and tostring(dispelUD) or "<nil/secret>"
				local ttDt
				-- Try tooltip scan regardless of spellId; cache lookups are best-effort
				local safeSpellKey = TPerl_SafeSpellIdKey(spellId)
				local safeAuraKey = TPerl_SafeAuraIdKey(auraId)
				if (safeAuraKey) then
					local cdt = TPerl_GetCachedDispelTypeByAuraId(safeAuraKey)
					if (cdt) then
						ttDt = cdt
					end
				end
				if (not ttDt and safeSpellKey) then
					local cdt = select(1, TPerl_GetCachedDispelType(safeSpellKey))
					if (cdt) then
						ttDt = cdt
					end
				end
				if (not ttDt) then
					local dtTT = select(1, TPerl_GetDispelTypeFromTooltip(unit, i))
					ttDt = dtTT
				end
				local tt_safe = (ttDt and TPerl_CanAccess(ttDt)) and tostring(ttDt) or "<nil/secret>"
				local src = "?"
				local nUA = TPerl_NormalizeDispelType(dispelUA)
				local nCA = TPerl_NormalizeDispelType(dispelCA)
				if (nUA == "Magic" or nUA == "Curse" or nUA == "Disease" or nUA == "Poison" or nUA == "none") then
					src = "UA"
				elseif (nCA == "Magic" or nCA == "Curse" or nCA == "Disease" or nCA == "Poison" or nCA == "none") then
					src = "CA"
				elseif (ttDt == "Magic" or ttDt == "Curse" or ttDt == "Disease" or ttDt == "Poison" or ttDt == "none") then
					src = "TT"
				end
				local norm = TPerl_NormalizeDispelType(dispelName) or "<nil>"
				local excluded = false

				if (name and TPerl_CanAccess(name)) then
					local ex = ArcaneExclusions and ArcaneExclusions[name]
					if (ex == true) then
						excluded = true
					elseif (type(ex) == "table") then
						local _, class = UnitClass(unit)
						excluded = (class and ex[class]) and true or false
					end
				end

				DEFAULT_CHAT_FRAME:AddMessage(format("  %02d) %s | type=%s (UD=%s, UA=%s, CA=%s, TT=%s, src=%s) | norm=%s | spellId=%s | auraId=%s | excluded=%s", i, nameSafe, dispelSafe, dispelUD_safe, dispelUA_safe, dispelCA_safe, tt_safe, src, tostring(norm), ((spellId and TPerl_CanAccess(spellId)) and tostring(spellId) or "<nil/secret>"), ((auraId and TPerl_CanAccess(auraId)) and tostring(auraId) or "<nil/secret>"), excluded and "yes" or "no"))
			end
		end
	end
end

