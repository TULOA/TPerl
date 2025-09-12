-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsCataClassic = WOW_PROJECT_ID == WOW_PROJECT_CATA_CLASSIC
local IsMistsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

TPerlLocked = 1
local conf
local ConfigRequesters = {}
TPerl_OutOfCombatQueue	= {}
local playerName
local iFixed1
local totalBlocked = 0
local xperlBlocked = 0
local lastConfigMode
local maxRevision

local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local CLASS_COUNT = 0
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	if k ~= "Adventurer" then
		CLASS_COUNT = CLASS_COUNT + 1
	end
end

TPerl_Tooltip_Edge_9 = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 9,
	title = true
}

TPerl_Tooltip_Edge_6 = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 6,
	title = true
}

TPerl_Frame_Backdrop_32_16_3333 = {
	bgFile = "Interface\\Addons\\TPerl\\Images\\TPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

TPerl_Frame_Backdrop_32_16_4444 = {
	bgFile = "Interface\\Addons\\TPerl\\Images\\TPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

TPerl_Frame_Backdrop_16_16_4444 = {
	bgFile = "Interface\\Addons\\TPerl\\Images\\TPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

TPerl_Frame_Backdrop_8_16_3333 = {
	bgFile = "Interface\\Addons\\TPerl\\Images\\TPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 8,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

TPerl_Icon_Backdrop_8_16_3333 = {
	bgFile = "",
	edgeFile = "",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 3, right = 4, top = 3, bottom = 3 }
}

TPerl_Frame_Backdrop_256_10_1211 = {
	bgFile = "Interface\\AddOns\\TPerl\\Images\\TPerl_FrameBack",
	edgeFile = "Interface\\Addons\\TPerl\\Images\\TPerl_ThinEdge",
	tile = true,
	tileSize = 256,
	edgeSize = 10,
	insets = { left = 1, right = 2, top = 1, bottom = 1 }
}

TPerl_Raid_Backdrop_16_9_3333 = {
	bgFile = "Interface\\AddOns\\TPerl_RaidHelper\\Images\\TPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 9,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

TPerl_Raid_Backdrop_32_16_3333 = {
	bgFile = "Interface\\AddOns\\TPerl_RaidHelper\\Images\\TPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

TPerl_Options_Backdrop_256_16_3333 = {
	bgFile = "Interface\\Addons\\TPerl_Options\\Images\\TPerl_FancyBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 256,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

TPerl_Options_Backdrop_256_16_5555 = {
	bgFile = "Interface\\Addons\\TPerl_Options\\Images\\TPerl_FancyBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 256,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

TPerl_UISlider_Backdrop_8_8_3366 = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	tile = true,
	tileSize = 8,
	edgeSize = 8,
	insets = { left = 3, right = 3, top = 6, bottom = 6 }
}

TPerl_Frame_Backdrop_32_16_2222 = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	tile = true,
	tileSize = 8,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local BackdropTemplatePolyfillMixin = {}

function BackdropTemplatePolyfillMixin:OnBackdropLoaded()
	if not self.backdropInfo then
		return
	end

	if not self.backdropInfo.edgeFile and not self.backdropInfo.bgFile then
		self.backdropInfo = nil
		return
	end

	self:ApplyBackdrop()

	if self.backdropColor then
		local r, g, b = self.backdropColor:GetRGB()
		self:SetBackdropColor(r, g, b, self.backdropColorAlpha or 1)
	end

	if self.backdropBorderColor then
		local r, g, b = self.backdropBorderColor:GetRGB()
		self:SetBackdropBorderColor(r, g, b, self.backdropBorderColorAlpha or 1)
	end

	if self.backdropBorderBlendMode then
		self:SetBackdropBorderBlendMode(self.backdropBorderBlendMode)
	end
end

function BackdropTemplatePolyfillMixin:OnBackdropSizeChanged()
	if self.backdropInfo then
		self:SetupTextureCoordinates()
	end
end

function BackdropTemplatePolyfillMixin:ApplyBackdrop()
	-- The SetBackdrop call will implicitly reset the background and border
	-- texture vertex colors to white, consistent across all client versions.

	self:SetBackdrop(self.backdropInfo)
end

function BackdropTemplatePolyfillMixin:ClearBackdrop()
	self:SetBackdrop(nil)
	self.backdropInfo = nil
end

function BackdropTemplatePolyfillMixin:GetEdgeSize()
	-- The below will indeed error if there's no backdrop assigned this is
	-- consistent with how it works on 9.x clients.

	return self.backdropInfo.edgeSize or 39
end

function BackdropTemplatePolyfillMixin:HasBackdropInfo(backdropInfo)
	return self.backdropInfo == backdropInfo
end

function BackdropTemplatePolyfillMixin:SetBorderBlendMode()
	-- The pre-9.x API doesn't support setting blend modes for backdrop
	-- borders, so this is a no-op that just exists in case we ever assume
	-- it exists.
end

function BackdropTemplatePolyfillMixin:SetupPieceVisuals()
	-- Deliberate no-op as backdrop internals are handled C-side pre-9.x.
end

function BackdropTemplatePolyfillMixin:SetupTextureCoordinates()
	-- Deliberate no-op as texture coordinates are handled C-side pre-9.x.
end

TPerlBackdropTemplateMixin = CreateFromMixins(BackdropTemplateMixin or BackdropTemplatePolyfillMixin)

function TPerl_GetRevision()
	return (maxRevision and "r"..maxRevision) or ""
end

function TPerl_SetModuleRevision(rev)
	if (rev) then
		rev = strmatch(rev, "Revision: (%d+)")
		if (rev) then
			rev = tonumber(rev)
			if (not maxRevision or rev > maxRevision) then
				maxRevision = rev
			end
		end
	end
end
local AddRevision = TPerl_SetModuleRevision

TPerl_SetModuleRevision("$Revision:  $")

function TPerl_Notice(...)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(TPerl_ProductName.." - |c00FFFF80"..format(...))
	end
end

do
	local function DisableOther(modName, issues)
		local name, title, notes, enabled = C_AddOns.GetAddOnInfo(modName)
		if (name and enabled) then
			DisableAddOn(modName)
			local notice = "Disabled '"..modName.."' addon. It is not compatible or needed with X-Perl"
			if (issues) then
				notice = notice..", and creates display issues."
			end
			TPerl_Notice(notice)
		end
	end

	DisableOther("PerlButton")		-- PerlButton was made for Nymbia's Perl UnitFrames. We have our own minimap button
	DisableOther("WT_ZoningTimeFix", true)

	local name, _, _, enabled, loadable = C_AddOns.GetAddOnInfo("TPerl_Party")
	if (enabled) then
		DisableOther("CT_PartyBuffs", true)
	end

	local name, _, _, enabled, loadable = C_AddOns.GetAddOnInfo("TPerl_GrimReaper")
	if (enabled) then
		C_AddOns.DisableAddOn("XPerl_GrimReaper")
		TPerl_Notice("Disabled XPerl_GrimReaper. This has been replaced by a standalone version 'GrimReaper' available on the WoW Ace Updater or from files.wowace.com")
	end
end

-- TPerl_RequestConfig
-- Setup a callback to give config around to local variables
function TPerl_RequestConfig(getConfig, rev)
	tinsert(ConfigRequesters, getConfig)
	if (TPerlDB) then
		getConfig(TPerlDB)
	end
	AddRevision(rev)
end

-- CurrentConfig()
local function CurrentConfig()
	local ret

	local function QuickValidate(set)
		return set.player and set.pet and set.colour and set.target and set.targettarget and set.focus and set.party and set.partypet and set.raid and set.rangeFinder and set.highlight and set.highlightDebuffs and set.buffs and set.buffHelper and set.bar
	end

	if (TPerlConfigSavePerCharacter) then
		if (not TPerlConfigNew[GetRealmName()]) then
			TPerlConfigNew[GetRealmName()] = {}
		end

		if (not TPerlConfigNew[GetRealmName()][playerName] or not QuickValidate(TPerlConfigNew[GetRealmName()][playerName])) then
			local new = {}
			TPerl_Defaults(new)
			TPerlConfigNew[GetRealmName()][playerName] = new -- TODO: use last used config
		end

		ret = TPerlConfigNew[GetRealmName()][playerName]
	else
		if (not TPerlConfigNew.global or not QuickValidate(TPerlConfigNew.global)) then
			local new = {}
			TPerl_Defaults(new)
			TPerlConfigNew.global = new -- TODO: use last used config
		end

		ret = TPerlConfigNew.global
	end

	return ret
end

-- GiveConfig
local function GiveConfig()
	conf = CurrentConfig()
	TPerlDB = conf

	for k, v in pairs(ConfigRequesters) do
		v(conf)
	end
end

TPerl_GiveConfig = GiveConfig

-- TPerl_ResetDefaults
function TPerl_ResetDefaults()
	local conf = {}

	TPerl_Defaults(conf)

	if (TPerlConfigSavePerCharacter) then
		TPerlConfigNew[GetRealmName()][playerName] = conf
	else
		TPerlConfigNew.global = conf
	end

	GiveConfig()

	if TPerl_Assists_FrameAnchor then
		TPerl_Assists_FrameAnchor:ClearAllPoints()
		TPerl_Assists_FrameAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		if (TPerl_SavePosition) then
			TPerl_SavePosition(TPerl_Assists_FrameAnchor)
		end
	end
	if TPerl_RaidMonitor_Anchor then
		TPerl_RaidMonitor_Anchor:ClearAllPoints()
		TPerl_RaidMonitor_Anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		if (TPerl_SavePosition) then
			TPerl_SavePosition(TPerl_RaidMonitor_Anchor)
		end
	end
	if TPerl_RosterTextAnchor then
		TPerl_RosterTextAnchor:ClearAllPoints()
		TPerl_RosterTextAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		if (TPerl_SavePosition) then
			TPerl_SavePosition(TPerl_RosterTextAnchor)
		end
	end
	if TPerl_CheckAnchor then
		TPerl_CheckAnchor:ClearAllPoints()
		TPerl_CheckAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		if (TPerl_SavePosition) then
			TPerl_SavePosition(TPerl_CheckAnchor)
		end
	end
	if TPerl_AdminFrameAnchor then
		TPerl_AdminFrameAnchor:ClearAllPoints()
		TPerl_AdminFrameAnchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		if (TPerl_SavePosition) then
			TPerl_SavePosition(TPerl_AdminFrameAnchor)
		end
	end

	TPerl_OptionActions()

	if (TPerl_Options and TPerl_Options:IsShown()) then
		TPerl_Options:Hide()
		TPerl_Options:Show()
	end
end

-- CopyTable
function TPerl_CopyTable(old)
	if (not old) then
		return
	end

	--local new = TPerl_GetReusableTable()
	local new = { }

	for k, v in pairs(old) do
		if (type(v) == "table") then
			new[k] = TPerl_CopyTable(v)
		else
			new[k] = v
		end
	end

	return new
end

-- ImportOldConfigs()
local function ImportOldConfigs()
	if (TPerlConfig_Global) then
		-- Convert old global configs
		TPerlConfigNew = {}

		for realm, realmList in pairs(TPerlConfig_Global) do
			TPerlConfigNew[realm] = {}
			for player, settings in pairs(realmList) do
				TPerlConfigNew[realm][player] = TPerl_ImportOldConfig(settings)
			end
		end

		TPerlConfig_Global = nil
	end
	if (TPerlConfig) then
		-- Convert old config
		if (not TPerlConfigNew) then
			TPerlConfigNew = {}
		end

		if (TPerlConfig) then
			TPerlConfigNew.global = TPerl_ImportOldConfig(TPerlConfig)
			TPerlConfig = nil
		end
	end
end

-- onEventPostSetup
local function onEventPostSetup(self, event, unit, ...)
	if (not TPerlDB) then
		return
	end
	if (TPerl_OutOfCombatOptionSet) then
		TPerl_OutOfCombatOptionSet = nil
		TPerl_OptionActions()
	end
	for func, arg in pairs(TPerl_OutOfCombatQueue) do
		assert(type(func) == "function")
		func(arg)
		TPerl_OutOfCombatQueue[func] = nil
	end
end

-- TPerl_RegisterLDB
local function TPerl_RegisterLDB()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDI = LibStub("LibDBIcon-1.0", true)
    if not (LDB and LDI) then return end

    if not TPerlDB then TPerlDB = {} end
    if not TPerlDB.minimap then TPerlDB.minimap = {} end

    local ldbSource = LDB:NewDataObject("TPerl_UnitFrames", {
        type = "launcher",
        text = TPerl_ShortProductName,
        icon = TPerl_ModMenuIcon or "Interface\\Icons\\INV_Misc_QuestionMark", -- always valid
        OnClick = TPerl_MinimapButton_OnClick,
        OnTooltipShow = function(tt) TPerl_MinimapButton_Details(tt, true) end,
    })

    function ldbSource:Update()
        self.text = TPerl_Version
    end

    -- Register with LibDBIcon so a minimap button shows
    LDI:Register("TPerl_UnitFrames", ldbSource, TPerlDB.minimap)
				--TPerl_MinimapButton_Frame:Hide()
end



local function settingspart1(self, event)
	playerName = UnitName("player")
	self:UnregisterEvent(event)

	local newUser = not TPerlConfigNew and not TPerlConfig

	if (not TPerlConfigNew) then
		if (TPerlConfig_Global or TPerlConfig) then
			TPerl_pcall(ImportOldConfigs)
		else
			TPerlConfigNew = {}
		end
	end

	GiveConfig()

	-- Variable checking only occurs for new install and version number change
	if (not TPerlConfigNew.ConfigVersion or TPerlConfigNew.ConfigVersion ~= TPerl_VersionNumber) then
		TPerl_pcall(TPerl_UpgradeSettings)
		TPerlConfigNew.ConfigVersion = TPerl_VersionNumber
	end

	ImportOldConfigs = nil
	TPerl_ImportOldConfig = nil
	TPerl_UpgradeSettings = nil

	TPerl_pcall(TPerl_ValidateSettings)

	TPerl_RegisterSMBarTextures()
end

local function startupCheckSettings(self,event)
--print("Startup Check Settings called")
	TPerl_Init()
	TPerl_BlizzFrameDisable = nil
	TPerl_RegisterLDB()

	lastConfigMode = TPerlConfigSavePerCharacter
	TPerl_Globals_AddonLoaded = nil
end

function TPerl_ForceImportAll()
	if C_AddOns.IsAddOnLoaded("TPerl") then
		if (TPerlConfig) then
			TPerlConfig = TPerlConfig
		end
		if (TPerlConfig_Global) then
			TPerlConfig_Global = TPerlConfig_Global
		end
		if (TPerlConfigNew) then
			TPerlConfigNew = TPerlConfigNew
		end
		if (TPerlConfigSavePerCharacter) then
			TPerlConfigSavePerCharacter = TPerlConfigSavePerCharacter
		end
		C_AddOns.DisableAddOn("ZPerl")
		print("TPerl: Profile importing done, please reload you UI for the process to complete.")
	else
		print("X-Perl is not loaded. You must load it first, to access it's variables for the import.")
	end
end

-- TPerl_GetLayout
function TPerl_GetLayout(name)
	if (TPerlConfigNew.savedPositions) then
		for realmName, realmList in pairs(TPerlConfigNew.savedPositions) do
			for playerName, frames in pairs(realmList) do
				local find
				if (realmName == "saved") then
					find = playerName
				else
					find = format("%s(%s)", realmName, playerName)
				end

				if (name == find) then
					return frames
				end
			end
		end
	end
end

-- TPerl_LoadFrameLayout
function TPerl_LoadFrameLayout(name)
	local layout = TPerl_GetLayout(name)

	if (layout) then
		local name = UnitName("player")
		local realm = GetRealmName()

		if (not TPerlConfigNew.savedPositions) then
			TPerlConfigNew.savedPositions = { }
		end
		local c = TPerlConfigNew.savedPositions
		if (not c[realm]) then
			c[realm] = { }
		end
		if (not c[realm][name]) then
			c[realm][name] = { }
		end

		TPerl_RestoreAllPositions()
	end
end

-- TPerl_Raid_GetGap
function TPerl_Raid_GetGap()
	if (TPerl_Raid_Grp2) then
		if (TPerlDB.raid.anchor == "TOP" or TPerlDB.raid.anchor == "BOTTOM") then
			return tonumber(floor(floor(((TPerl_Raid_Grp2:GetLeft() or 0) - (TPerl_Raid_Grp1:GetRight() or TPerl_Raid_Grp2:GetLeft() or 80) + 0.5) * 100) / 100))
		else
			return tonumber(floor((floor(((TPerl_Raid_Grp1:GetTop() or TPerl_Raid_Grp2:GetTop() or 200) - (TPerl_Raid_Grp2:GetBottom() or 200) + 0.5) * 100) / 100) - 46))
		end
	end
	return 0
end

-- TPerl_Globals_OnEvent
function TPerl_Globals_OnEvent(self, event, arg1, ...)
	if (event == "ADDON_LOADED" and arg1 == "TPerl") then
		self:UnregisterEvent(event)
		settingspart1(self, event)
	elseif (event == "PLAYER_LOGIN") then
		self:UnregisterEvent(event)
		startupCheckSettings(self, event)
		--TPerl_MinimapButton_Init(TPerl_MinimapButton_Frame)
	elseif (event == "PLAYER_ENTERING_WORLD") then
		self:UnregisterEvent(event)
		self:UnregisterAllEvents()
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", onEventPostSetup)
		-- Load the player's layout, will be profile dependent later.
		local layout = format("%s(%s)", GetRealmName(), UnitName("player"))
		TPerl_LoadFrameLayout(layout)
		TPerl_Globals_OnEvent = nil
	end
end

-- TPerl_SetMyGlobal
function TPerl_SetMyGlobal()
	local realm = GetRealmName()

	if (not lastConfigMode and TPerlConfigSavePerCharacter) then
		if (not TPerlConfigNew[realm]) then
			TPerlConfigNew[realm] = {}
		end
		if (TPerlConfigNew.global) then
			TPerlConfigNew[realm][playerName] = TPerl_CopyTable(TPerlConfigNew.global)
		else
			TPerl_LoadOptions()
			TPerlConfigNew[realm][playerName] = {}
			TPerl_Options_Defaults(TPerlConfigNew[realm][playerName])
		end

	elseif (lastConfigMode and not TPerlConfigSavePerCharacter) then
		if (TPerlConfigNew[realm] and TPerlConfigNew[realm][playerName]) then
			TPerlConfigNew.global = TPerl_CopyTable(TPerlConfigNew[realm][playerName])
		else
			TPerl_LoadOptions()
			TPerlConfigNew.global = {}
			TPerl_Options_Defaults(TPerlConfigNew.global)
		end
	end

	lastConfigMode = TPerlConfigSavePerCharacter

	GiveConfig()
end

-- TPerl_LoadOptions
function TPerl_LoadOptions()
	if (not C_AddOns.IsAddOnLoaded("TPerl_Options")) then
		C_AddOns.EnableAddOn("TPerl_Options")
		local ok, reason = C_AddOns.LoadAddOn("TPerl_Options")

		if (not ok) then
			TPerl_Notice("Failed to load TPerl Options ("..tostring(reason)..")")
		--[[else
			collectgarbage()]]			-- Reclaims about 1.4Mb from loading options
		end
	end

	return TPerl_Options_Defaults
end

-- TPerl_ImportOldConfig
function TPerl_ImportOldConfig(old)
	if (TPerl_LoadOptions()) then
		return TPerl_Options_ImportOldConfig(old)
	end

	return {}
end

-- TPerl_Defaults()
function TPerl_Defaults(new)
	if (TPerl_LoadOptions()) then
		TPerl_Options_Defaults(new)
	end
end

-- TPerl_UpgradeSettings
function TPerl_UpgradeSettings()
	if (TPerl_LoadOptions()) then
		TPerl_Options_UpgradeSettings()
	end
end

-- DefaultRaidClasses
local function DefaultRaidClasses()
	if IsRetail then
		return {
			{enable = true, name = "WARRIOR"},
			{enable = true, name = "DEATHKNIGHT"},
			{enable = true, name = "ROGUE"},
			{enable = true, name = "HUNTER"},
			{enable = true, name = "MAGE"},
			{enable = true, name = "WARLOCK"},
			{enable = true, name = "PRIEST"},
			{enable = true, name = "DRUID"},
			{enable = true, name = "SHAMAN"},
			{enable = true, name = "PALADIN"},
			{enable = true, name = "MONK"},
			{enable = true, name = "DEMONHUNTER"},
			{enable = true, name = "EVOKER"}
		}
	elseif IsCataClassic then
		return {
			{enable = true, name = "WARRIOR"},
			{enable = true, name = "DEATHKNIGHT"},
			{enable = true, name = "ROGUE"},
			{enable = true, name = "HUNTER"},
			{enable = true, name = "MAGE"},
			{enable = true, name = "WARLOCK"},
			{enable = true, name = "PRIEST"},
			{enable = true, name = "DRUID"},
			{enable = true, name = "SHAMAN"},
			{enable = true, name = "PALADIN"},
		}
	elseif IsMistsClassic then
		return {
			{enable = true, name = "WARRIOR"},
			{enable = true, name = "DEATHKNIGHT"},
			{enable = true, name = "ROGUE"},
			{enable = true, name = "HUNTER"},
			{enable = true, name = "MAGE"},
			{enable = true, name = "WARLOCK"},
			{enable = true, name = "PRIEST"},
			{enable = true, name = "DRUID"},
			{enable = true, name = "SHAMAN"},
			{enable = true, name = "PALADIN"},
			{enable = true, name = "MONK"},
		}
	else
		return {
			{enable = true, name = "WARRIOR"},
			{enable = true, name = "ROGUE"},
			{enable = true, name = "HUNTER"},
			{enable = true, name = "MAGE"},
			{enable = true, name = "WARLOCK"},
			{enable = true, name = "PRIEST"},
			{enable = true, name = "DRUID"},
			{enable = true, name = "SHAMAN"},
			{enable = true, name = "PALADIN"},
		}
	end
end

-- ValidateClassNames
local function ValidateClassNames(part)
	if not part then
		return
	end
	-- This should never happen, but I'm sure someone will find a way to break it

	local list
	if IsRetail then
		list = {WARRIOR = false, MAGE = false, ROGUE = false, DRUID = false, HUNTER = false, SHAMAN = false, PRIEST = false, WARLOCK = false, PALADIN = false, DEATHKNIGHT = false, MONK = false, DEMONHUNTER = false, EVOKER = false}
	elseif IsCataClassic then
		list = {WARRIOR = false, MAGE = false, ROGUE = false, DRUID = false, HUNTER = false, SHAMAN = false, PRIEST = false, WARLOCK = false, PALADIN = false, DEATHKNIGHT = false}
	elseif IsMistsClassic then
		list = {WARRIOR = false, MAGE = false, ROGUE = false, DRUID = false, HUNTER = false, SHAMAN = false, PRIEST = false, WARLOCK = false, PALADIN = false, DEATHKNIGHT = false, MONK = false}
	else
		list = {WARRIOR = false, MAGE = false, ROGUE = false, DRUID = false, HUNTER = false, SHAMAN = false, PRIEST = false, WARLOCK = false, PALADIN = false}
	end
	local valid
	if (part.class) then
		local classCount = 0
		for i, info in pairs(part.class) do
			if (type(info) == "table" and info.name) then
				classCount = classCount + 1
			end
		end
		if (classCount == CLASS_COUNT) then
			valid = true
		end

		if (valid) then
			for i = 1, CLASS_COUNT do
				if (part.class[i]) then
					list[part.class[i].name] = true
				end
			end
		end
	end

	if (valid) then
		for k, v in pairs(list) do
			if (not v) then
				valid = nil
			end
		end
	end

	if (not valid) then
		part.class = DefaultRaidClasses(true)
	end
end

-- TPerl_ValidateSettings()
function TPerl_ValidateSettings()

	local function validate(set)
		if (set) then
			if (not set.buffs) then
				set.buffs = {enable = 1, size = 20, maxrows = 2}
			else
				if (not set.buffs.size) then
					set.buffs.size = 20
				end
				if (not set.buffs.maxrows) then
					set.buffs.maxrows = 2
				end
			end
			if (not set.debuffs) then
				set.debuffs = {enable = 1, size = 20}
			elseif (not set.debuffs.size) then
				set.debuffs.size = set.buffs.size
			end

			if (not set.healerMode) then
				set.healerMode = {type = 1}
			end
			if (not set.size) then
				set.size = {width = 0}
			end
		end
	end

	local list = {"player", "pet", "party", "partypet", "target", "focus", "targettarget", "targettargettarget", "focustarget", "pettarget", "raid"}

	for k, v in pairs(list) do
		validate(conf[v])
	end

	if (not conf.pet) then
		conf.pet = {enable = 1}
	end
	if (not conf.pet.castBar) then
		conf.pet.castBar = {enable = 1}
	end

	if (conf.colour and not conf.colour.gradient) then
		conf.colour.gradient = {
			enable = 1,
			s = {r = 0.25, g = 0.25, b = 0.25, a = 1},
			e = {r = 0.1, g = 0.1, b = 0.1, a = 0}
		}
	end

	if (not conf.colour.bar.absorb or conf.colour.bar.absorb[1]) then
		conf.colour.bar.absorbs = {r = 0.14, g = 0.33, b = 0.7, a = 0.7}
	end

	if (not conf.colour.bar.healprediction or conf.colour.bar.healprediction[1]) then
		conf.colour.bar.healprediction = {r = 0, g = 1, b = 1, a = 1}
	end

	if (not conf.colour.bar.runic_power or conf.colour.bar.runic_power[1]) then
		if (PowerBarColor) then
			conf.colour.bar.runic_power = {r = PowerBarColor["RUNIC_POWER"].r, g = PowerBarColor["RUNIC_POWER"].g, b = PowerBarColor["RUNIC_POWER"].b}
		else
			conf.colour.bar.runic_power = {r = 1, g = 0.25, b = 1}
		end
	end

	if (not conf.colour.bar.insanity or conf.colour.bar.insanity[1]) then
		if (PowerBarColor) then
			conf.colour.bar.insanity = {r = PowerBarColor["INSANITY"].r, g = PowerBarColor["INSANITY"].g, b = PowerBarColor["INSANITY"].b}
		else
			conf.colour.bar.insanity = {r = 0.4, g = 0, b = 0.8}
		end
	end

	if (not conf.colour.bar.lunar or conf.colour.bar.lunar[1]) then
		if (PowerBarColor) then
			conf.colour.bar.lunar = {r = PowerBarColor["LUNAR_POWER"].r, g = PowerBarColor["LUNAR_POWER"].g, b = PowerBarColor["LUNAR_POWER"].b}
		else
			conf.colour.bar.lunar = {r = 0.3, g = 0.52, b = 0.9}
		end
	end

	if (not conf.colour.bar.maelstrom or conf.colour.bar.maelstrom[1]) then
		if (PowerBarColor) then
			conf.colour.bar.maelstrom = {r = PowerBarColor["MAELSTROM"].r, g = PowerBarColor["MAELSTROM"].g, b = PowerBarColor["MAELSTROM"].b}
		else
			conf.colour.bar.maelstrom = {r = 0, g = 0.5, b = 1}
		end
	end

	if (not conf.colour.bar.fury or conf.colour.bar.fury[1]) then
		if (PowerBarColor) then
			conf.colour.bar.fury = {r = PowerBarColor["FURY"].r, g = PowerBarColor["FURY"].g, b = PowerBarColor["FURY"].b}
		else
			conf.colour.bar.fury = {r = 0.788, g = 0.259, b = 0.992}
		end
	end

	if (not conf.colour.bar.pain or conf.colour.bar.pain[1]) then
		if (PowerBarColor) then
			conf.colour.bar.pain = {r = PowerBarColor["PAIN"].r, g = PowerBarColor["PAIN"].g, b = PowerBarColor["PAIN"].b}
		else
			conf.colour.bar.pain = {r = 1, g = 0.611, b = 0}
		end
	end

	ValidateClassNames(TPerlDB.raid)

	TPerl_ValidateSettings = nil
end

function TPerl_Import()
 if C_AddOns.IsAddOnLoaded("ZPerl") then
		C_AddOns.EnableAddOn("ZPerl")
		if (ZPerlConfig) then
			TPerlConfig = ZPerlConfig
		end
		if (ZPerlConfig_Global) then
			TPerlConfig_Global = ZPerlConfig_Global
		end
		if (ZPerlConfigNew) then
			TPerlConfigNew = ZPerlConfigNew
		end
		if (ZPerlConfigSavePerCharacter) then
			TPerlConfigSavePerCharacter = ZPerlConfigSavePerCharacter
		end
		C_AddOns.DisableAddOn("ZPerl")
		TPerlImportDone = true
		print("TPerl: Profile importing done, please reload you UI for the process to complete.")
	end
	if C_AddOns.IsAddOnLoaded("ZPerl") then
		C_AddOns.DisableAddOn("ZPerl")
	end
end