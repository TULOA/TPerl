-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

TPerl_SetModuleRevision("$Revision:  $")

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsCataClassic = WOW_PROJECT_ID == WOW_PROJECT_CATA_CLASSIC
local IsMistsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsTBCAnni = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local CLASS_COUNT = #(CLASS_SORT_ORDER or DefaultRaidClasses())

local protected = { }

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

function TPerl_OptionsFrame_DisableSlider(slider)
	local name = slider:GetName()
	getmetatable(slider).__index.Disable(slider)
	_G[name.."Text"]:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
	_G[name.."Low"]:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
	_G[name.."High"]:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
end

function TPerl_OptionsFrame_EnableSlider(slider)
	local name = slider:GetName()
	getmetatable(slider).__index.Enable(slider)
	_G[name.."Text"]:SetVertexColor(NORMAL_FONT_COLOR.r , NORMAL_FONT_COLOR.g , NORMAL_FONT_COLOR.b)
	_G[name.."Low"]:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	_G[name.."High"]:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end


function TPerl_Options_SetupFunc(self)
	TPerl_DoGradient(self, true)
	self:OnBackdropLoaded()
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
end

-- TPerl_OptionsFrame_SelectFrame
function TPerl_OptionsFrame_SelectFrame(frame)
	TPerl_Options:Show()

	if (frame == "player") then
		TPerl_Options_Player:Show()
		TPerl_Options_Party:Hide()
		TPerl_Options_Raid:Hide()

	elseif (frame == "party") then
		TPerl_Options_Player:Hide()
		TPerl_Options_Party:Show()
		TPerl_Options_Raid:Hide()

	elseif (frame == "raid") then
		TPerl_Options_Player:Hide()
		TPerl_Options_Party:Hide()
		TPerl_Options_Raid:Show()
	end
end

-- TPerl_OptionsSetMyText
function TPerl_OptionsSetMyText(f, str, keep)
	if (f and str) then
		local textFrame = _G[f:GetName().."Text"]

		if (not keep and not strfind(str, "^TPERL")) then
			ChatFrame1:AddMessage("WARNING: Not keeping '"..str.."'")
		end

		if (textFrame) then
			textFrame:SetText(_G[str])
			f.tooltipText = _G[str.."_DESC"]

			if ((f.GetFrameType or f.GetObjectType)(f) == "CheckButton") then
				f:SetHitRectInsets(0, -(textFrame:GetStringWidth()), 0, 0)
			end

		elseif ((f.GetFrameType or f.GetObjectType)(f) == "Button") then
			f:SetText(_G[str])
			f.tooltipText = _G[str.."_DESC"]
		end

		if (not keep) then
			_G[str] = nil
			_G[str.."_DESC"] = nil
		end
	end
end

-- TPerl_Options_CheckButton_OnEnter
function TPerl_Options_CheckButton_OnEnter(self)
	if (self.flashFrame and not InCombatLockdown()) then
		local array
		if (table.getn(self.flashFrame) == 0) then
			array = {self.flashFrame}
		else
			array = self.flashFrame
		end

		for i, f in pairs(array) do
			if (f and f.GetName) then
				if (f:IsShown()) then
					TPerl_FrameFlash(f)
				end
			end
		end
	end
	if ( self.tooltipText ) then
		local p = _G[self:GetName().."Text"]
		local title = p and p:GetText()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if (title) then
			GameTooltip:SetText(title, 1, 1, 1)
			GameTooltip:AddLine(self.tooltipText, nil, nil, nil, 1)
		else
			GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
		end
		GameTooltip:Show()
	end

	_G[self:GetName().."Text"]:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end

-- TPerl_GetCheck
function TPerl_GetCheck(f)
	if (f:GetChecked()) then
		return 1
	else
		return 0
	end
end

-- TPerl_Options_GetSibling
function TPerl_Options_GetSibling(sibling, self)
	return _G[self:GetParent():GetName().."_"..sibling]
end

-- TPerl_Options_EnableSibling
function TPerl_Options_EnableSibling(self, sibling, check2nd, check3rd)
	local siblingName = self:GetParent():GetName().."_"..sibling
	local siblingFrame = _G[siblingName]
	local second = true
	local condition = "and"

	if (type(check2nd) == "string" and (check2nd == "or" or check2nd == "and")) then
		condition = check2nd
		check2nd = check3rd
	end
	if (check2nd) then
		if (type(check2nd) == "table") then
			second = check2nd:GetChecked()
		elseif (type(check2nd) == "string") then
			local sib2 = self:GetParent():GetName().."_"..check2nd
			local sibf2 = _G[sib2]
			if (sibf2) then
				second = sibf2:GetChecked()
			else
				DEFAULT_CHAT_FRAME:AddMessage("|c00FF0000TPerl|r - No 2nd sibling called '"..sib2.."'")
			end
		else
			second = check2nd
		end
	end

	local result
	if (condition == "and") then
		result = (self:GetChecked() and second)
	elseif (condition == "or") then
		result = (self:GetChecked() or second)
	end

	if (siblingFrame) then
		if ((siblingFrame.GetFrameType or siblingFrame.GetObjectType)(siblingFrame) == "Button") then
			if (result) then
				siblingFrame:Enable()
				if siblingFrame == TPerl_Options_Colour_Options_FrameColours_Start or siblingFrame == TPerl_Options_Colour_Options_FrameColours_End then
					_G[siblingFrame:GetName().."Text"]:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
				end
			else
				siblingFrame:Disable()
				if siblingFrame == TPerl_Options_Colour_Options_FrameColours_Start or siblingFrame == TPerl_Options_Colour_Options_FrameColours_End then
					_G[siblingFrame:GetName().."Text"]:SetTextColor(0.5, 0.5, 0.5)
				end
			end
		elseif ((siblingFrame.GetFrameType or siblingFrame.GetObjectType)(siblingFrame) == "CheckButton") then
			TPerl_Options_EnableCheck(siblingFrame, result)
		elseif ((siblingFrame.GetFrameType or siblingFrame.GetObjectType)(siblingFrame) == "Slider") then
			if (result) then
				siblingFrame:EnableSlider()
			else
				siblingFrame:DisableSlider()
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|c00FF0000TPerl|r - No code to disable '"..siblingFrame:GetName().."' type: "..(siblingFrame.GetFrameType or siblingFrame.GetObjectType)(siblingFrame))
		end

		if siblingFrame.protected then
			protected[siblingFrame] = result
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c00FF0000TPerl|r - No sibling found called '"..siblingName.."'")
	end
end

-- TPerl_Options_EnableCheck
function TPerl_Options_EnableCheck(self, on)
	local textFrame = _G[self:GetName().."Text"]
	if (on) then
		self:Enable()
		textFrame:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	else
		self:Disable()
		textFrame:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
	end

	if ((self.GetFrameType or self.GetObjectType)(self) == "Button") then
		local normalTexture = _G[self:GetName().."NormalTexture"]
		local icon = _G[self:GetName().."Icon"]
		if (normalTexture and icon) then
			if (on) then
				icon:SetVertexColor(1, 1, 1)
				normalTexture:SetVertexColor(1, 1, 1)
			else
				icon:SetVertexColor(0.5, 0.5, 0.5)
				normalTexture:SetVertexColor(0.5, 0.5, 0.5)
			end
		end
	end
end

-- TPerl_Options_IncrementSibling
function TPerl_Options_IncrementSibling(self, sibling)
	local siblingName = self:GetParent():GetName().."_"..sibling
	local siblingFrame = _G[siblingName]

	if (siblingFrame and (siblingFrame.GetFrameType or siblingFrame.GetObjectType)(siblingFrame) == "EditBox") then
		local n = tonumber(siblingFrame:GetText())
		n = n + 1
		siblingFrame:SetText(n)
		return n
	end
end

-- TPerl_Options_DecrementSibling
function TPerl_Options_DecrementSibling(self, sibling)
	local siblingName = self:GetParent():GetName().."_"..sibling
	local siblingFrame = _G[siblingName]

	if (siblingFrame and (siblingFrame.GetFrameType or siblingFrame.GetObjectType)(siblingFrame) == "EditBox") then
		local n = tonumber(siblingFrame:GetText())
		n = n - 1
		siblingFrame:SetText(n)
		return n
	end
end

-- TPerl_Options_CheckRadio
function TPerl_Options_CheckRadio(self,buttons)
	local prefix = self:GetParent():GetName().."_"

	for i, name in pairs(buttons) do
		if (prefix..name == self:GetName()) then
			_G[prefix..name]:SetChecked(true)
		else
			_G[prefix..name]:SetChecked(false)
		end
	end
end

-- TPerl_Options_GetSiblingChecked
function TPerl_Options_GetSiblingChecked(name,self)
	local prefix = self:GetParent():GetName().."_"
	return _G[prefix..name]:GetChecked()
end

-- TPerl_Raid_OptionActions
function TPerl_Raid_OptionActions()
	if (TPerl_Raid_Position) then
		TPerl_Raid_Position()
		TPerl_Raid_Set_Bits(TPerl_Raid_Frame)
		TPerl_Raid_UpdateDisplayAll()
		if (TPerl_RaidPets_OptionActions) then
			TPerl_RaidPets_OptionActions()
		end
	end
end

-- TPerl_Options_OnUpdate
function TPerl_Options_OnUpdate(self, arg1)
	if (self.Fading) then
		local alpha = self:GetAlpha()
		if (self.Fading == "in") then
			alpha = alpha + (arg1 * 2)		-- elapsed * 2 == fade in/out in 1/2 second
			if (alpha > 1) then
				alpha = 1
			end
		elseif (self.Fading == "out") then
			alpha = alpha - (arg1 * 2)
			if (alpha < 0) then
				alpha = 0
			end
		end
		self:SetAlpha(alpha)
		if (alpha == 0) then
			self.Fading = nil
			self:Hide()
		elseif (alpha == 1) then
			self.Fading = nil
		end
	else
		local f = (GetMouseFoci and GetMouseFoci()[1]) or (GetMouseFocus and GetMouseFocus())
		if (f) then
			local n = f:GetName()
			if (n) then
				if (strfind(n, "TPerl_Player") or strfind(n, "TPerl_Target") or strfind(n, "TPerl_Focus")) then
					TPerl_OptionsFrame_SelectFrame("player")
				elseif (strfind(strlower(n), "xperl_party")) then
					TPerl_OptionsFrame_SelectFrame("party")
				elseif (strfind(n, "TPerl_Raid")) then
					TPerl_OptionsFrame_SelectFrame("raid")
				end
			end
		end
	end
end

-- TPerl_Options_MaxScaleSet
local Sliders = { }
function TPerl_Options_MaxScaleSet()
	for i, slider in pairs(Sliders) do
		local old = slider:GetValue()
		local min = slider.min or 50
		local max = slider.max or floor(TPerlDB.maximumScale * 100 + 0.5)

		slider:SetMinMaxValues(min, max)

		_G[slider:GetName().."Low"]:SetFormattedText("%d"..PERCENT_SYMBOL, min)
		_G[slider:GetName().."High"]:SetFormattedText("%d"..PERCENT_SYMBOL, max)

		if (old > max) then
			slider:SetValue(max)
		-- This is only needed for the mininum change
		--[[elseif (old < min) then
			slider:SetValue(min)]]
		end
	end
end

-- TPerl_SliderSetup(self)
function TPerl_SliderSetup(self, percent)
	self.xperlSliderEnabled = true

	self.IsEnabled = function(self)
		return self.xperlSliderEnabled
	end
	self.DisableSlider = function(self)
		self.xperlSliderEnabled = false
		TPerl_OptionsFrame_DisableSlider(self)
		_G[self:GetName().."Current"]:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
		self:EnableMouse(false)
		self:EnableMouseWheel(false)
	end
	self.EnableSlider = function(self)
		self.xperlSliderEnabled = true
		TPerl_OptionsFrame_EnableSlider(self)
		_G[self:GetName().."Current"]:SetVertexColor(0.4, 0.4, 0.80)
		self:EnableMouse(true)
		self:EnableMouseWheel(true)
	end

	local low = _G[self:GetName().."Low"]
	if (not tonumber(low:GetText())) then
		local min, max = self:GetMinMaxValues()
		if (min and max) then
			if (percent) then
				min = format("%d"..PERCENT_SYMBOL, min)
				max = format("%d"..PERCENT_SYMBOL, max)
			end
			low:SetText(min)
			_G[self:GetName().."High"]:SetText(max)
		end
	end

	if self.backdropInfo then
		self:OnBackdropLoaded()
	end

	self:SetScript("OnLoad", nil)
end

function TPerl_EditBoxSetup(self)
	self.xperlEditEnabled = true
	self.IsEnabled = function(self)
		return self.xperlEditEnabled
	end
	self.Enable = function(self)
		self.xperlEditEnabled = true
		self:EnableMouse(true)
	end
	self.Disable = function(self)
		self.xperlEditEnabled = false
		self:EnableMouse(false)
	end
end

-- GetTable(self)
local function GetTable(self)
	if (self.configIndex == nil) then
		error("No index for configBase in "..self:GetName())
	end

	local table = RunScript("TPerlTemp = "..self.configBase)
	local val = TPerlTemp
	TPerlTemp = nil

	if (type(val) == "table") then
		return val
	end
	--error(self:GetName().." needs to return a table from self.configBase")
end

-- TPerl_Options_GetIndex(self)
function TPerl_Options_GetIndex(self)
	if (type(self.configBase) == "string") then
		local val = GetTable(self)
		if (val) then
			return val[self.configIndex]
		end

	elseif (type(self.configBase) == "table") then
		if (self.configIndex == nil) then
			error("No index for configBase in "..self:GetName())
		end

		return self.configBase[self.configIndex]
	end
end

-- TPerl_Options_SetIndex
function TPerl_Options_SetIndex(self, new)
	if (type(self.configBase) == "string") then
		local val = GetTable(self)
		if val then
			val[self.configIndex] = new
		end
	elseif (type(self.configBase) == "table") then
		if (self.configIndex == nil) then
			error("No index for configBase in "..self:GetName())
		end
		self.configBase[self.configIndex] = new
	end
end

-- scalingOnShow
local function scalingOnShow(self)
	local i = TPerl_Options_GetIndex(self)
	if (i) then
		self:SetValue(floor(100 * i + 0.5))
	end
end

-- scalingOnValueChanged
local function scalingOnValueChanged(self, value)
	local i = TPerl_Options_GetIndex(self)

	if (i) then
		if (floor(100 * i + 0.5) ~= value) then
			TPerl_Options_SetIndex(self, value / 100)
			if (self.configClick) then
				self.configClick()
			end
		end
		_G[self:GetName().."Current"]:SetText(floor(value + 0.5).."%")
	end
end

-- TPerl_Options_RegisterScalingSlider
function TPerl_Options_RegisterScalingSlider(self, min, max)
	TPerl_Options_RegisterProtected(self)

	Sliders[self:GetName()] = self

	if (min) then
		self.min = min
	else
		min = 50
	end
	if (max) then
		self.max = max
	else
		max = floor(((TPerlDB and TPerlDB.maximumScale) or 1.5) * 100 + 0.5)
	end

	_G[self:GetName().."Low"]:SetFormattedText("%d"..PERCENT_SYMBOL, min)
	_G[self:GetName().."High"]:SetFormattedText("%d"..PERCENT_SYMBOL, max)

	self:SetMinMaxValues(min, max)
	self:SetValueStep(1)

	if (self.configBase) then
		self:SetScript("OnShow", scalingOnShow)
		self:SetScript("OnValueChanged", scalingOnValueChanged)
	end
end

-- TPerl_Popup
function TPerl_Popup(question, onAccept)
	TPerl_OptionsQuestionDialogText:SetText(question)
	TPerl_OptionsQuestionDialog.onAccept = onAccept
	TPerl_OptionsQuestionDialog:SetScale(1.5)
	TPerl_OptionsQuestionDialog:Show()

	TPerl_OptionsQuestionDialog:SetPoint("CENTER", 0, 0)

	local w = TPerl_OptionsQuestionDialogText:GetStringWidth() + 20

	if (w > 320) then
		TPerl_OptionsQuestionDialog:SetWidth(320)
		TPerl_OptionsQuestionDialog:SetHeight(100)
	else
		TPerl_OptionsQuestionDialog:SetWidth(w)
		TPerl_OptionsQuestionDialog:SetHeight(80)
	end

	if (TPerl_Options:IsShown()) then
		TPerl_OptionsQuestionDialog.hideMask = true
		TPerl_Options_Mask:Show()
	else
		TPerl_OptionsQuestionDialog.hideMask = nil
	end
end

-- Load settings menu
local MyIndex = 0
local function GetPlayerList()
	local ret = {}
	if (TPerlConfigNew) then
		local me = GetRealmName().." / "..UnitName("player")
		for realmName, realmConfig in pairs(TPerlConfigNew) do
			if (type(realmConfig) == "table" and realmName ~= "global" and realmName ~= "savedPositions") then
				for playerName, settings in pairs(realmConfig) do
					local entry = realmName.." / "..playerName

					tinsert(ret, {name = entry, config = settings})

					if (entry == me) then
						MyIndex = #ret
					end
				end
			end
		end
	end
	return ret
end

-- TPerl_Options_LoadSettings_OnLoad
function TPerl_Options_LoadSettings_OnLoad(self)
	local dropdown = MSA_DropDownMenu_Create(self:GetName().."_DropDown", self)
	dropdown:SetAllPoints(self)
	MSA_DropDownMenu_Initialize(dropdown, TPerl_Options_LoadSettings_Initialize)
	MSA_DropDownMenu_SetWidth(dropdown, 150)
	if (MyIndex == 0) then
		_G[dropdown:GetName().."Text"]:SetText("")
	else
		MSA_DropDownMenu_SetSelectedID(dropdown, MyIndex, 1)
	end

	TPerl_Options_RegisterProtected(_G[dropdown:GetName().."Button"])
end

-- TPerl_Options_LoadSettings_Initialize
function TPerl_Options_LoadSettings_Initialize()
	local list = GetPlayerList()

	for i, entry in pairs(list) do
		local info = MSA_DropDownMenu_CreateInfo()
		info.text = entry.name
		info.func = TPerl_Options_LoadSettings_OnClick
		MSA_DropDownMenu_AddButton(info)
	end
end

-- TPerl_Options_DeleteSettings_OnLoad
function TPerl_Options_DeleteSettings_OnLoad(self)
	local dropdown = MSA_DropDownMenu_Create(self:GetName().."_DropDown", self)
	dropdown:SetAllPoints(self)
	MSA_DropDownMenu_Initialize(dropdown, TPerl_Options_DeleteSettings_Initialize)
	MSA_DropDownMenu_SetWidth(dropdown, 150)

	_G[dropdown:GetName().."Text"]:SetText("")

	TPerl_Options_RegisterProtected(_G[dropdown:GetName().."Button"])
end

-- TPerl_Options_DeleteSettings_Initialize
function TPerl_Options_DeleteSettings_Initialize()
	local list = GetPlayerList()

	for i, entry in pairs(list) do
		local info = MSA_DropDownMenu_CreateInfo()
		info.text = entry.name
		info.func = TPerl_Options_DeleteSettings_OnClick
		MSA_DropDownMenu_AddButton(info)
	end
end

-- TPerl_Options_Anchor_OnLoad
function TPerl_Options_Anchor_OnLoad(self)
	local dropdown = MSA_DropDownMenu_Create(self:GetName().."_DropDown", self)
	dropdown:SetAllPoints(self)
	MSA_DropDownMenu_Initialize(dropdown, TPerl_Options_Anchor_Initialize)
	MSA_DropDownMenu_SetWidth(dropdown, 100)
	local current = self.varGet() or "TOP"
	MSA_DropDownMenu_SetSelectedName(dropdown, current, 1)

	TPerl_Options_RegisterProtected(_G[dropdown:GetName().."Button"])
end

-- TPerl_Options_Anchor_Initialize
function TPerl_Options_Anchor_Initialize(dropdown)
	local info
	local current = dropdown:GetParent().varGet() or "TOP"

	for k, v in pairs(TPerl_AnchorList) do
		info = { }
		info.text = v
		info.func = function(self)
			dropdown:GetParent().varSet(TPerl_AnchorList[self:GetID()])

			MSA_DropDownMenu_SetSelectedName(dropdown, v, 1)

			TPerl_ProtectedCall(dropdown:GetParent().setFunc)

			if (TPerl_Party_Virtual) then
				TPerl_Party_Virtual(true)
			end

			if (TPerl_RaidTitles) then
				TPerl_RaidTitles()
			end
		end

		MSA_DropDownMenu_AddButton(info)
	end
end

-- CopySelectedSettings
local CopyFrom
local function CopySelectedSettings()
	TPerlDB = TPerl_CopyTable(CopyFrom.config)

	if (TPerlConfigSavePerCharacter) then
		if (not TPerlConfigNew[GetRealmName()]) then
			TPerlConfigNew[GetRealmName()] = {}
		end

		TPerlConfigNew[GetRealmName()][UnitName("player")] = TPerlDB
	else
		TPerlConfigNew[GetRealmName()].global = TPerlDB
	end

	TPerl_GiveConfig()
	TPerl_StartupSpellRange() -- Re-validate the spell range stuff

	ValidateClassNames(TPerlDB.raid)

	TPerl_Options:Hide()
	TPerl_Options:Show()

	TPerl_OptionActions()
end

-- TPerl_Options_LoadSettings_OnClick
function TPerl_Options_LoadSettings_OnClick(self)
	local list = GetPlayerList()

	if (self:GetID() ~= MyIndex) then
		local entry = list[self:GetID()]

		if (entry) then
			CopyFrom = entry
			TPerl_Popup(format("Copy settings from %s?", entry.name), CopySelectedSettings)
		end
	end
end

-- DeleteSelectedSettings
local DeleteFrom
local function DeleteSelectedSettings()
	local realm, player = string.match(DeleteFrom.name, "([^,]+) / ([^,]+)")

	TPerlConfigNew[realm][player] = nil

	TPerl_GiveConfig()

	TPerl_Options:Hide()
	TPerl_Options:Show()

	TPerl_OptionActions()
end

-- TPerl_Options_DeleteSettings_OnClick
function TPerl_Options_DeleteSettings_OnClick(self)
	local list = GetPlayerList()

	if (self:GetID() ~= MyIndex) then
		local entry = list[self:GetID()]

		if (entry) then
			DeleteFrom = entry
			TPerl_Popup(format("Delete settings from profile %s?", entry.name), DeleteSelectedSettings)
		end
	end
end

-- TPerl_Options_TextureSelect_Onload
function TPerl_Options_TextureSelect_Onload(self)
	self.Setup = TPerl_Options_SetupFunc
	self.scrollBar = _G[self:GetName().."scrollBar"]
	self.list = TPerl_AllBarTextures()
	self.Selection = 1
	if (self.list) then
		self.scrollBar.bar:SetValue(max(0, min(self.Selection - 5, #self.list - 8)))
	else
		self.scrollBar.bar:SetValue(1)
	end

	self.UpdateFunction = function(self)
		self:GetParent():SetBarColours()
	end

	self.SetBarColours = function(self)
		local offset = self.scrollBar.bar:GetValue()
		for i = 0, 9 do
			local r, g, b
			if (self.Selection - offset - 1 == i) then
				r, g, b = 0, 1, 0
			else
				r, g, b = 0.5, 0.5, 0.5
			end
			local f = _G[self:GetName()..i]
			if (f) then
				if (i + offset + 1 > #self.list) then
					f:Hide()
				else
					f:Show()
					f.name:SetText(self.list[i + offset + 1][1])
					f.tex:SetTexture(self.list[i + offset + 1][2])
					f.tex:SetVertexColor(r, g, b, 1)
				end
			end
		end

		if (FauxScrollFrame_Update(self.scrollBar, #self.list, 10, 1)) then
			self.scrollBar:Show()
		else
			self.scrollBar:Hide()
		end
	end

	if self and self.scrollBar and self.list then
		FauxScrollFrame_Update(self.scrollBar, #self.list, 10, 1)
	end

	TPerl_Options_TextureSelect_Onload = nil
end

-- TPerl_Options_SetTabColor
function TPerl_Options_SetTabColor(self, color)
	for i, y in pairs({"Enabled", "Disabled"}) do
		for j, z in pairs({"Left", "Right", "Middle"}) do
			local f = _G[self:GetName()..y..z]
			--if (TPerlDB and TPerlDB.colour.gradient.enable) then
				local c = TPerlDB.colour.gradient.s
				f:SetVertexColor(c.r, c.g, c.b, c.a)
			--else
			--	f:SetVertexColor(0.8, 0.8, 0.8, 1)
			--end
		end
	end
end

-- TPerl_Options_EnableTab
function TPerl_Options_EnableTab(self, enable)
	for i, y in pairs({"Enabled", "Disabled"}) do
		for j, z in pairs({"Left", "Right", "Middle"}) do
			local f = _G[self:GetName()..y..z]

			if ((i == 1 and enable) or (i == 2 and not enable)) then
				f:Show()
			else
				f:Hide()
			end
		end
	end
end

-- TPerl_Options_InCombatChange
function TPerl_Options_InCombatChange(inCombat)
	for k, v in pairs(protected) do
		if ((k.GetFrameType or k.GetObjectType)(k) == "CheckButton") then
			local textFrame = _G[k:GetName().."Text"]

			if (inCombat) then
				if not k.wasChecked then
					k.wasChecked = k:GetChecked()
				end
				if not v then
					v = k:IsEnabled()
				end
				k:SetChecked(false)
				k:Disable()
				textFrame:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
				k.combatIcon:Show()
			else
				k.combatIcon:Hide()

				if (v) then
					k:Enable()
					textFrame:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
				else
					k:Disable()
					textFrame:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
				end

				if (k.wasChecked) then
					k:SetChecked(true)

					k.wasChecked = nil
				end
			end
		elseif ((k.GetFrameType or k.GetObjectType)(k) == "Slider") then
			if (inCombat) then
				if not v then
					v = k:IsEnabled()
				end
				k:DisableSlider()
				k.combatIcon:Show()
			else
				k.combatIcon:Hide()

				if (v) then
					k:EnableSlider()
				else
					k:DisableSlider()
				end
			end
		elseif ((k.GetFrameType or k.GetObjectType)(k) == "Button") then
			if (inCombat) then
				if not v then
					v = k:IsEnabled()
				end
				k:Disable()
				k.combatIcon:Show()
			else
				k.combatIcon:Hide()

				if (v) then
					k:Enable()
				else
					k:Disable()
				end
			end
		elseif ((k.GetFrameType or k.GetObjectType)(k) == "EditBox") then
			if (inCombat) then
				if not v then
					v = k:IsEnabled()
				end
				k:Disable()
				k.combatIcon:Show()
			else
				k.combatIcon:Hide()

				if (v) then
					k:Enable()
				else
					k:Disable()
				end
			end
		end
	end
end

-- TPerl_Options_RegisterProtected
function TPerl_Options_RegisterProtected(self)
	if ((self.GetFrameType or self.GetObjectType)(self) == "Slider") then
		TPerl_SliderSetup(self)
	elseif ((self.GetFrameType or self.GetObjectType)(self) == "EditBox") then
		TPerl_EditBoxSetup(self)
	end

	protected[self] = self:IsEnabled()

	self.protected = true

	if not self.combatIcon then
		self.combatIcon = self:CreateTexture(self:GetName().."CombatIcon", "OVERLAY")

		self.combatIcon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
		self.combatIcon:SetTexCoord(0.5, 1.0, 0.0, 0.49)

		self.combatIcon:SetWidth(32)
		self.combatIcon:SetHeight(32)
		self.combatIcon:SetPoint("CENTER", 0, 0)
		self.combatIcon:Hide()
	end

	self:SetScript("OnLoad", nil)
end

-- GetSpell
local function GetSpell()
	return TPerlDB and TPerlDB.rangeFinder[TPerl_Options.optRange].spell
end

-- GetItem
local function GetItem()
	return TPerlDB and TPerlDB.rangeFinder[TPerl_Options.optRange].item
end

-- GetSpellEnemy
local function GetSpellEnemy()
	return TPerlDB and TPerlDB.rangeFinder[TPerl_Options.optRange].spell2
end

-- GetItemEnemy
local function GetItemEnemy()
	return TPerlDB and TPerlDB.rangeFinder[TPerl_Options.optRange].item2
end

-- TPerl_Options_GetRangeTexture
function TPerl_Options_GetRangeTexture(self, isEnemy)
	local spell = GetSpell(isEnemy)
	if spell then
		local tex = (C_Spell and C_Spell.GetSpellTexture) and C_Spell.GetSpellTexture(spell) or (GetSpellTexture and GetSpellTexture(spell))
		return tex, spell
	end

	local item = GetItem(isEnemy)
	if item then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture = GetItemInfo(item)
		if itemName then
			return invTexture, itemName
		end
	end

	return
end

-- TPerl_Options_GetRangeTexture
function TPerl_Options_GetRangeTextureEnemy(self)
	local spell = GetSpellEnemy()
	if spell then
		local tex = (C_Spell and C_Spell.GetSpellTexture) and C_Spell.GetSpellTexture(spell) or (GetSpellTexture and GetSpellTexture(spell))
		return tex, spell
	end

	local item = GetItemEnemy()
	if item then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture = GetItemInfo(item)
		if itemName then
			return invTexture, itemName
		end
	end

	return
end

-- TPerl_Options_DoRangeTooltip
function TPerl_Options_DoRangeTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -15, 0)

	local spell = GetSpell()
	if spell then
		local link = (C_Spell and C_Spell.GetSpellLink) and C_Spell.GetSpellLink(spell) or (GetSpellLink and GetSpellLink(spell))
		if link then
			if IsClassic then
				local _, _, _, _, _, _, spellID = GetSpellInfo(spell)
				if spellID then
					local newLink = format("spell:%d:0:0:0", spellID)
					GameTooltip:SetHyperlink(newLink)
				end
			else
				GameTooltip:SetHyperlink(link)
			end
		else
			GameTooltip:SetText(spell or UNKNOWN, 1, 1, 1)
		end

		GameTooltip:AddLine(" ")
		if TPerlDB.rangeFinder[TPerl_Options.optRange].spell then
			GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC, 0.5, 1, 0.5)
		else
			GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC2, 0.5, 1, 0.5)
		end
		GameTooltip:Show()
		return
	else
		GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC2, 0.5, 1, 0.5)
		GameTooltip:Show()
		return
	end

	local item = GetItem()
	if item then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture = GetItemInfo(item)
		if itemName then
			local itemId = strmatch(itemLink, "item:(%d+):")
			if itemId then
				local newLink = format("item:%d:0:0:0", itemId)
				GameTooltip:SetHyperlink(newLink)

				GameTooltip:AddLine(" ")
				if TPerlDB.rangeFinder[TPerl_Options.optRange].item then
					GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC, 0.5, 1, 0.5)
				else
					GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC2, 0.5, 1, 0.5)
				end
				GameTooltip:Show()
			end
		end
	else
		GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC2, 0.5, 1, 0.5)
		GameTooltip:Show()
	end
end

-- TPerl_Options_DoRangeTooltipEnemy
function TPerl_Options_DoRangeTooltipEnemy(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -15, 0)

	local spell = GetSpellEnemy()
	if spell then
		local link = (C_Spell and C_Spell.GetSpellLink) and C_Spell.GetSpellLink(spell) or (GetSpellLink and GetSpellLink(spell))
		if link then
			if IsClassic then
				local _, _, _, _, _, _, spellID = GetSpellInfo(spell)
				if spellID then
					local newLink = format("spell:%d:0:0:0", spellID)
					GameTooltip:SetHyperlink(newLink)
				end
			else
				GameTooltip:SetHyperlink(link)
			end
		else
			GameTooltip:SetText(spell or UNKNOWN, 1, 1, 1)
		end

		GameTooltip:AddLine(" ")
		if TPerlDB.rangeFinder[TPerl_Options.optRange].spell2 then
			GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC, 0.5, 1, 0.5)
		else
			GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_ENEMY_DESC2, 0.5, 1, 0.5)
		end
		GameTooltip:Show()
		return
	else
		GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_ENEMY_DESC2, 0.5, 1, 0.5)
		GameTooltip:Show()
		return
	end

	local item = GetItemEnemy()
	if item then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, invTexture = GetItemInfo(item)
		if itemName then
			local itemId = strmatch(itemLink, "item:(%d+):")
			if itemId then
				local newLink = format("item:%d:0:0:0", itemId)
				GameTooltip:SetHyperlink(newLink)

				GameTooltip:AddLine(" ")
				if TPerlDB.rangeFinder[TPerl_Options.optRange].item2 then
					GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_DESC, 0.5, 1, 0.5)
				else
					GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_ENEMY_DESC2, 0.5, 1, 0.5)
				end
				GameTooltip:Show()
			end
		end
	else
		GameTooltip:AddLine(TPERL_CONF_CUSTOMSPELL_ENEMY_DESC2, 0.5, 1, 0.5)
		GameTooltip:Show()
	end
end

-- SetClassNames
local function SetClassNames(self)
	ValidateClassNames(TPerlDB.raid)

	local prefix = self:GetParent():GetParent():GetName().."_"
	for i = 1, CLASS_COUNT do
		local f = _G[prefix.."ClassSel"..i.."_EnableText"]
		if (f) then
			local class = TPerlDB.raid.class[i].name
			f:SetText(LOCALIZED_CLASS_NAMES_MALE[class])
		end
	end
end

-- TPerl_Options_MoveRaidClassUp
function TPerl_Options_MoveRaidClassUp(self)
	local i = self:GetID()

	ValidateClassNames(TPerlDB.raid)

	local save = TPerlDB.raid.class[i].name
	TPerlDB.raid.class[i].name = TPerlDB.raid.class[i - 1].name
	TPerlDB.raid.class[i - 1].name = save

	SetClassNames(self)
end

-- TPerl_Options_MoveRaidClassDown
function TPerl_Options_MoveRaidClassDown(self)
	local i = self:GetID()

	ValidateClassNames(TPerlDB.raid)

	local save = TPerlDB.raid.class[i]
	TPerlDB.raid.class[i] = TPerlDB.raid.class[i + 1]
	TPerlDB.raid.class[i + 1] = save

	SetClassNames(self)
end

-- TPerl_Options_RaidSelectAll
function TPerl_Options_RaidSelectAll(self, enable)
	local val
	local prefix = self:GetParent():GetName().."_"

	for i = 1, CLASS_COUNT do
		local f = _G[prefix.."Grp"..i]
		if (f) then
			f:SetChecked(enable)
			if f:GetChecked() then
				TPerlDB.raid.group[i] = 1
			else
				TPerlDB.raid.group[i] = nil
			end
		end

		f = _G[prefix.."ClassSel"..i.."_Enable"]
		if (f) then
			f:SetChecked(enable)
			if f:GetChecked() then
				TPerlDB.raid.class[i].enable = 1
			else
				TPerlDB.raid.class[i].enable = nil
			end
		end
	end

	TPerl_Raid_ChangeAttributes()
	TPerl_Raid_OptionActions()
end

-- TPerl_Options_SetupStatsFrames
function TPerl_Options_SetupStatsFrames()
	if (TPerl_Player) then
		TPerl_StatsFrameSetup(TPerl_Player, {TPerl_Player.statsFrame.druidBar, TPerl_Player.statsFrame.xpBar, TPerl_Player.statsFrame.repBar})
	end
	if (TPerl_Player_Pet) then
		TPerl_StatsFrameSetup(TPerl_Player_Pet, nil, 2)
	end
	TPerl_StatsFrameSetup(TPerl_Target)
	TPerl_StatsFrameSetup(TPerl_Focus)
	TPerl_StatsFrameSetup(TPerl_TargetTarget)
	TPerl_StatsFrameSetup(TPerl_TargetTargetTarget)
	TPerl_StatsFrameSetup(TPerl_FocusTarget)
	TPerl_StatsFrameSetup(TPerl_PetTarget)

	for i = 1, 4 do
		TPerl_StatsFrameSetup(_G["TPerl_party"..i])
		TPerl_StatsFrameSetup(_G["TPerl_partypet"..i], nil, 2)
	end
end

-- TPerl_Player_Reset()
function TPerl_Player_Reset()
	if (TPerl_Player) then
		TPerl_Player_Set_Bits(TPerl_Player)
		TPerl_Player_UpdateDisplay(TPerl_Player)
		if (TPerl_Player_BuffSetup) then
			TPerl_Player.buffOptMix = nil
			TPerl_Player_BuffSetup(TPerl_Player)
		end
	end
end

-- TPerl_Player_Pet_Reset
function TPerl_Player_Pet_Reset()
	if (TPerl_Player_Pet) then
		TPerl_Player_Pet_Set_Bits(TPerl_Player_Pet)
		TPerl_Player_Pet_UpdateDisplay(TPerl_Player_Pet)
	end
end

-- TPerl_Target_Reset()
function TPerl_Target_Reset()
	if (TPerl_Target) then
		TPerl_Target_Set_Bits(TPerl_Target)
		TPerl_Target_UpdateDisplay(TPerl_Target)
	end

	if (TPerl_Focus) then
		TPerl_Target_Set_Bits(TPerl_Focus)
		TPerl_Target_UpdateDisplay(TPerl_Focus)
	end
end

-- TPerl_TargetTarget_Reset()
function TPerl_TargetTarget_Reset()
	if (TPerl_TargetTarget_Set_Bits) then
		TPerl_TargetTarget_Set_Bits()

		TPerl_TargetTarget_UpdateDisplay(TPerl_TargetTarget)
		if (TPerl_TargetTargetTarget) then
			TPerl_TargetTarget_UpdateDisplay(TPerl_TargetTargetTarget)
		end
		if (TPerl_FocusTarget) then
			TPerl_TargetTarget_UpdateDisplay(TPerl_FocusTarget)
		end
		if (TPerl_PetTarget) then
			TPerl_TargetTarget_UpdateDisplay(TPerl_PetTarget)
		end
	end
end

-- TPerl_Party_Reset()
function TPerl_Party_Reset()
	if (TPerl_Party_Set_Bits) then
		TPerl_Party_Set_Bits()
		TPerl_Party_UpdateDisplayAll()
	end
end

-- TPerl_PartyPet_Reset()
function TPerl_PartyPet_Reset()
	if (TPerl_Party_Pet_Set_Bits) then
		TPerl_Party_Pet_Set_Bits()
		TPerl_Party_Pet_UpdateDisplayAll()
	end
end

-- Moving stuff
function TPerl_Player_GetGap()
	if (TPerl_Player and TPerl_Target) then
		local pr = TPerl_Player.statsFrame:GetRight()
		local ps = TPerl_Player:GetEffectiveScale()
		if (pr and ps) then
			local playerLeft = pr * ps
			local tl = TPerl_Target:GetLeft()
			local ts = TPerl_Target:GetEffectiveScale()
			if (tl and ts) then
				local targetLeft = tl * ts
				local a = targetLeft - playerLeft
				return tonumber(floor(floor((a + 0.5) * 100) / 100 + 4))
			end
		end
	end
	return 0
end

-- TPerl_Player_SetGap
function TPerl_Player_SetGap(newGap)
	if not newGap or type(newGap) ~= "number" then
		return
	end
	newGap = newGap - 4

	local function SetChildGap(self, other)
		if (self and other) then
			local top = other:GetTop()
			local left

			if (self == TPerl_Player) then
				left = ((self.statsFrame:GetRight() * self:GetEffectiveScale()) + newGap) / other:GetEffectiveScale()
			else
				left = ((self:GetRight() * self:GetEffectiveScale()) + newGap) / other:GetEffectiveScale()
			end

			if (self == TPerl_Target or self == TPerl_TargetTarget or self == TPerl_Focus) then
				if (self.levelFrame and self.levelFrame:IsShown()) then
					left = left + self.levelFrame:GetWidth()
				end
			end

			other:ClearAllPoints()
			other:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
			other:SetUserPlaced(true)
			TPerl_SavePosition(other)
		end
	end

	SetChildGap(TPerl_Player, TPerl_Target)
	SetChildGap(TPerl_Target, TPerl_TargetTarget)
	SetChildGap(TPerl_TargetTarget, TPerl_TargetTargetTarget)
	SetChildGap(TPerl_Focus, TPerl_FocusTarget)
	SetChildGap(TPerl_Player_Pet, TPerl_PetTarget)

	if (TPerl_Player) then
		TPerl_SavePosition(TPerl_Player)
	end
end

-- TPerl_Player_AlignTop
function TPerl_Player_AlignTop()

	-- We set this for 1 reason, so that all the related frames scale in the same direction should the user do that...
	if (TPerl_Player) then
		TPerl_Player:ClearAllPoints()
		TPerl_Player:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", TPerl_Player:GetLeft() or 5, TPerl_Player:GetTop() or 948)
		TPerl_Player:SetUserPlaced(true)
	end

	local function AlignChildTop(self, other)
		if (self and other) then
			local top = self:GetTop() * self:GetEffectiveScale()
			local otherLeft = other:GetLeft() or 220
			local selfLeft = self:GetLeft() or 5

			if (otherLeft == nil) then
				otherLeft = selfLeft + 200
			end

			other:ClearAllPoints()
			local newTop = top / other:GetEffectiveScale()
			other:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", otherLeft, newTop)
			other:SetUserPlaced(true)
			TPerl_SavePosition(other)
		end
	end

	AlignChildTop(TPerl_Player, TPerl_Target)
	AlignChildTop(TPerl_Target, TPerl_TargetTarget)
	AlignChildTop(TPerl_TargetTarget, TPerl_TargetTargetTarget)
	AlignChildTop(TPerl_Focus, TPerl_FocusTarget)
	AlignChildTop(TPerl_Player_Pet, TPerl_PetTarget)
end


-- InterestingFrames
local function InterestingFrames()
	local interest = TPerl_Options.raidAlign
	local ret = { }
 local GROUP_COUNT = 8
	
	if (interest == "all") then
		for i = 1, GROUP_COUNT do
			tinsert(ret, _G["TPerl_Raid_Title"..i])
		end
	elseif (interest == "odd") then
		for i = 1, GROUP_COUNT, 2 do
			tinsert(ret, _G["TPerl_Raid_Title"..i])
		end
	elseif (interest == "even") then
		for i = 2, GROUP_COUNT, 2 do
			tinsert(ret, _G["TPerl_Raid_Title"..i])
		end
	elseif (interest == "first4") then
		for i = 1, 4 do
			tinsert(ret, _G["TPerl_Raid_Title"..i])
		end
	elseif (interest == "last4") then
		for i = 5, GROUP_COUNT do
			tinsert(ret, _G["TPerl_Raid_Title"..i])
		end
	end
	return ret
end

-- TPerl_Raid_SetGap
function TPerl_Raid_SetGap(newGap)
	if not newGap or type(newGap) ~= "number" then
		return
	end
	local frames = InterestingFrames()

	if (TPerlDB.raid.anchor == "TOP" or TPerlDB.raid.anchor == "BOTTOM") then
		local framePrev

		for i, frame in pairs(frames) do
			if (framePrev and frame) then
				local right = framePrev:GetRight()
				local top = frame:GetTop()

				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", right + newGap, top)
				frame:SetUserPlaced(true)
				TPerl_SavePosition(frame)
			end

			framePrev = frame
		end
	else
		local framePrev

		for i, frame in pairs(frames) do
			if (framePrev and frame) then
				local bottom = framePrev:GetBottom()
				local left = frame:GetLeft()

				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, bottom + newGap - 26)
				frame:SetUserPlaced(true)
				TPerl_SavePosition(frame)
			end

			framePrev = frame
		end
	end
	TPerlDB.raid.gap = newGap
end

-- TPerl_Raid_AlignTop
function TPerl_Raid_AlignTop()
	if (not TPerl_Raid_Grp1) then
		return
	end

	local frames = InterestingFrames()

	local top = frames[1]:GetTop()

	for i, frame in pairs(frames) do
		local left = frame:GetLeft()

		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		frame:SetUserPlaced(true)
		TPerl_SavePosition(frame)
	end
end

-- TPerl_Raid_AlignLeft
function TPerl_Raid_AlignLeft()
	if (not TPerl_Raid_Grp1) then
		return
	end

	local frames = InterestingFrames()

	local left = frames[1]:GetLeft()

	for i, frame in pairs(frames) do
		local top = frame:GetTop()

		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		frame:SetUserPlaced(true)
		TPerl_SavePosition(frame)
	end
end

--------------------------------------------------------------------
-------------------------- LAYOUT STUFF ----------------------------
--------------------------------------------------------------------

-- TPerl_Options_LayoutGetList
function TPerl_Options_LayoutGetList(self)
	local list = { }

	if (TPerlConfigNew.savedPositions) then
		for realmName, realmList in pairs(TPerlConfigNew.savedPositions) do
			for playerName,frames in pairs(realmList) do
				if (realmName == "saved") then
					tinsert(list, playerName)
				else
					tinsert(list, format("%s(%s)", realmName, playerName))
				end
			end
		end

		sort(list)
	end

	return list
end

-- TPerl_Options_GetLayout
function TPerl_Options_GetLayout(name)
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

-- TPerl_Options_SaveFrameLayout
function TPerl_Options_SaveFrameLayout(name)
	if (not TPerlConfigNew.savedPositions) then
		TPerlConfigNew.savedPositions = { }
	end
	if (not TPerlConfigNew.savedPositions.saved) then
		TPerlConfigNew.savedPositions.saved = { }
	end
	TPerlConfigNew.savedPositions.saved[name] = TPerl_CopyTable(TPerl_GetSavePositionTable())
end

-- TPerl_Options_LoadFrameLayout
function TPerl_Options_LoadFrameLayout(name)
	local layout = TPerl_Options_GetLayout(name)

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

		c[realm][name] = TPerl_CopyTable(layout)

		TPerl_RestoreAllPositions()
	end
end

-- TPerl_Options_DeleteFrameLayout
function TPerl_Options_DeleteFrameLayout(name)
	local me = format("%s(%s)", GetRealmName(), UnitName("player"))

	if (TPerlConfigNew.savedPositions) then
		for realmName, realmList in pairs(TPerlConfigNew.savedPositions) do
			for playerName, frames in pairs(realmList) do
				local find
				if (realmName == "saved") then
					find = playerName
				else
					find = format("%s(%s)", realmName, playerName)
				end

				if (name ~= me and name == find) then
					realmList[playerName] = nil
					return true
				end
			end
		end
	end
end

-- TPerl_Options_LayoutFill
function TPerl_Options_LayoutFill(self, setName)
	local list = TPerl_Options_LayoutGetList(self)

	self.start = self.scrollBar.bar:GetValue() + 1

	if (self.selection) then
		if (self.selection < 1) then
			self.selection = 1
		elseif (self.selection > #list) then
			self.selection = #list
		end
	end

	for i = 1,#self.line do
		self.line[i]:SetText("")
		self.line[i]:UnlockHighlight()
		self.line[i]:Hide()
	end

	local newName
	local line = 1
	for i = self.start,self.start + #self.line - 1 do
		if (i > #list) then
			break
		end

		self.line[line].raw = list[i]

		if (strsub(list[i], strlen(list[i])) == ")") then
			self.line[line]:SetText("|cFF6060A0"..list[i])
		else
			self.line[line]:SetText(list[i])
		end

		self.line[line]:Show()

		if (i == self.selection) then
			self.line[line]:LockHighlight()

			if (setName) then
				newName = list[i]
			end
		end

		line = line + 1
	end

	if (setName) then
		if (newName) then
			TPerl_Options_Layout_Name:SetText(newName)
		else
			TPerl_Options_Layout_Name:SetText("")
		end
	end

	local offset = self.scrollBar.bar:GetValue()

	if (FauxScrollFrame_Update(self.scrollBar, #list, 16, 1)) then
		self.scrollBar:Show()
	else
		self.scrollBar:Hide()
	end
end

---------------------------------------------------------------------
-------------------------- CONFIG IMPORT ----------------------------
---------------------------------------------------------------------
if (TPerlConfig or TPerlConfig_Global) then

-- Convert		-- Convert old options (we have 1 or nil now instead of 1 or 0)
local function Convert(opt)
	if (opt == 0) then
		return nil
	end
	return opt
end

-- TPerl_Options_ImportOldConfig
function TPerl_Options_ImportOldConfig(old)

	if (not old) then
		return
	end

	local new = {
		bar = {
			texture		= old.BarTexture,
			background	= Convert(old.BackgroundTextures),
			fading		= Convert(old.FadingBars), -- 1.8.9
			fadeTime	= old.FadingBarsTime or 0.5, -- 1.9.1
			fat			= Convert(old.FatHealthBars),
			inverse		= Convert(old.InverseBars), -- 1.8.6
		},
		transparency = {
			frame		= old.Transparency			or 1,
			text		= old.TextTransparency			or 1,
		},
		colour = {
			frame			= old.BackColour		or {r = 0, g = 0, b = 0, a = 1},
			border			= old.BorderColour		or {r = 0.5, g = 0.5, b = 0.5, a = 1},
			class			= Convert(old.ClassColouredNames),
			guildList		= Convert(old.ApplyToGuildList),		-- 1.8.9
			classic			= Convert(old.ClassicHealthBar),
			bar = {
				healthEmpty	= old.ColourHealthEmpty		or {r = 1, g = 0, b = 0},
				healthFull	= old.ColourHealthFull		or {r = 0, g = 1, b = 0},
				absorb		= {r = 0.14, g = 0.33, b = 0.7, a = 0.7},
				healprediction = {r = 0, g = 1, b = 1, a = 1},
				hot			= {r = 1, g = 0.72, b = 0.1, a = 0.7},
				mana		= old.ColourMana		or {r = 0, g = 0, b = 1},
				energy		= old.ColourEnergy		or {r = 1, g = 1, b = 0},
				rage		= old.ColourRage		or {r = 1, g = 0, b = 0},
				focus		= old.ColourFocus		or {r = 1, g = 0.5, b = 0.25},
				runic_power	= {r = PowerBarColor and PowerBarColor["RUNIC_POWER"].r or 1, g = PowerBarColor and PowerBarColor["RUNIC_POWER"].g or 1, b = PowerBarColor and PowerBarColor["RUNIC_POWER"].b or 1},
			},
			reaction = {
				enemy		= old.ColourReactionEnemy	or {r = 1, g = 0, b = 0},
				neutral		= old.ColourReactionNeutral	or {r = 1, g = 1, b = 0},
				unfriendly	= old.ColourReactionUnfriendly	or {r = 1, g = 0.5, b = 0},
				friend		= old.ColourReactionFriend	or {r = 0, g = 1, b = 0},
				none		= old.ColourReactionNone	or {r = 0.5, g = 0.5, b = 1},
				tapped		= old.ColourTapped		or {r = 0.5, g = 0.5, b = 0.5},
			},
			gradient = TPerl_DefaultGradientColours(),
		},
		highlightSelection	= Convert(old.HighlightSelection),
		minimap = {
			enable		= Convert(old.MinimapButtonShown),
			pos		= old.MinimapButtonPosition	or 186,
			radius = IsRetail and 101 or 78,
		},
		combatFlash		= Convert(old.PerlCombatFlash),
		highlightDebuffs = {
			enable		= Convert(old.HighlightDebuffs),
			border		= 1,
			frame		= 1,
			class		= Convert(old.HighlightDebuffsClass),
		},
		buffHelper = {
			enable		= Convert(old.BuffTooltipHelper),
			sort		= old.BuffTooltipHelperSort	or "group",		-- 2.2.5
			visible		= Convert(old.BuffTooltipHelperVisible or 1),		-- 2.2.9
		},
		tooltip = {
			enable		= Convert(old.UnitTooltips),				-- 2.0.5
			enableBuffs	= 1,							-- 2.3.4a
			fading		= Convert(old.FadingTooltip),				-- 1.8.3
			xperlInfo	= Convert(old.TPerlTooltipInfo),			-- 1.8.6
			modifier	= old.UnitTooltipsModifiers	or "all",		-- 2.0.6
		},
		maximumScale		= old.MaximumScale		or 1.5,
		optionsColour		= old.OptionsColour		or {r = 0.7, g = 0.2, b = 0.2},	-- 1.8.3
		showAFK			= Convert(old.ShowAFK),					-- 2.2.4
		buffs = {
			cooldown	= Convert(old.BuffCooldown),				-- 2.2.3
			countdown	= Convert(old.BuffCountdown),				-- 2.2.2
			countdownStart	= old.BuffCountdownStart	or 20,			-- 2.2.2
		},
		rangeFinder = old.RangeFinder or TPerl_DefaultRangeFinder(),
		highlight = {
			enable			= Convert(old.RaidHighlights),
			HOT			= Convert(old.RaidHighlightHoTs),
			SHIELD			= Convert(old.RaidHighlightShields),
			AGGRO			= Convert(old.RaidHighlightAggro),
			MISSING			= Convert(old.RaidHighlightMissing),
			all			= Convert(old.RaidHighlightMissingAll),
		},
		player = {
			enable			= 1,
			castBar = {
				enable		= Convert(old.ArcaneBarPlayer),
				original	= Convert(old.OldCastBar),
				castTime	= Convert(old.CastTime),
			},
			portrait		= Convert(old.ShowPlayerPortrait),
			portrait3D		= Convert(old.ShowPlayerPortrait3D),
			hitIndicator	= Convert(old.CombatHitIndicator),
			level			= Convert(old.ShowPlayerLevel),
			classIcon		= Convert(old.ShowPlayerClassIcon),
			xpBar			= Convert(old.ShowPlayerXPBar),
			repBar			= Convert(old.ShowPlayerRepBar),
			pvpIcon			= Convert(old.ShowPlayerPVP),
			values			= Convert(old.ShowPlayerValues),
			percent			= Convert(old.ShowPlayerPercent),
			scale			= old.Scale_PlayerFrame		or 0.8,
			partyNumber		= Convert(old.ShowPartyNumber),
			withName		= Convert(old.ShowPartyNumberWithName),
			showRunes		= 1,
			dockRunes		= 1,
			lockRunes		= 1,


			fullScreen = {
				enable		= Convert(old.FullScreenStatus),
				lowHP		= old.FullScreenStatusWarn	or 30,
				highHP		= old.FullScreenStatusOK	or 40,
			},

			healerMode = {
				enable		= Convert(old.HealerModePlayer),
				type		= old.HealerModePlayerType	or 1,
			},

			buffs = {
				enable		= Convert(old.PlayerBuffs),
				above		= Convert(old.PlayerBuffsAbove),
				size		= old.PlayerBuffSize		or 15,
				hideBlizzard	= Convert(old.HideBlizzardBuffBar),
				count		= old.PlayerBuffMaxDisplay	or 40,
				cooldown	= Convert(old.PlayerBuffsCooldown),
				flash		= Convert(old.PlayerBuffsFlash),
				wrap		= 1,			-- 2.3.5
				rows		= 2,			-- 2.3.5
			},
			debuffs = {
				enable		= Convert(old.PlayerBuffs),
				size		= old.PlayerBuffSize		or 19,
			},
			size = {
				width		= old.PlayerWidthBonus		or 0,
			},
		},
		pet = {
			enable			= 1,
			castBar = {
				enable		= Convert(old.ArcaneBarPlayer),
			},
			portrait		= Convert(old.ShowPlayerPetPortrait),
			portrait3D		= Convert(old.ShowPlayerPetPortrait3D),
			hitIndicator		= Convert(old.PetCombatHitIndicator),
			happiness = {
				enable		= Convert(old.PetHappiness),
				onlyWhenSad	= Convert(old.PetHappinessSad),
				flashWhenSad	= Convert(old.PetFlashWhenSad),
			},
			level			= Convert(old.ShowPetLevel),
			scale			= old.Scale_PetFrame		or 0.8,
			name			= Convert(old.ShowPlayerPetName),
			buffs = {
				enable		= 1,
				size		= old.PlayerPetBuffSize		or 15,
				wrap		= 1,			-- 2.3.5
			},
			debuffs = {
				enable		= 1,
				size		= old.PlayerPetBuffSize		or 19,
			},
			healerMode = {
--				enable		= nil,
				type		= 1,
			},
			values			= Convert(old.ShowPlayerPetValues),
			size = {
				width		= old.PetWidthBonus		or 0,
			},
		},
		target = {
			enable			= 1,
			portrait		= Convert(old.ShowTargetPortrait),
			portrait3D		= Convert(old.ShowTargetPortrait3D),
			castBar = {
				enable		= Convert(old.ArcaneBarTarget),
			},
			hitIndicator	= Convert(old.TargetCombatHitIndicator),			-- 2.1.7
			classIcon		= Convert(old.ShowTargetClassIcon),
			classText		= Convert(old.ShowTargetClassText),			-- 2.0.6
			mobType			= Convert(old.ShowTargetMobType),
			level			= Convert(old.ShowTargetLevel),
			elite			= Convert(ceil((old.ShowTargetElite or 1) / 2)),
			eliteGfx		= Convert(floor((old.ShowTargetElite or 1) / 2)),
			mana			= Convert(old.ShowTargetMana),
			percent			= Convert(old.ShowTargetPercent),
			values			= Convert(old.ShowTargetValues),
			combo = {
				enable		= Convert(old.UseCPMeter),
				blizzard	= Convert(old.BlizzardCPMeter),
				pos			= old.BlizzardCPPosition	or "top",
			},
			pvpIcon			= Convert(old.ShowTargetPVP),			-- 1.8.3
			scale			= old.Scale_TargetFrame		or 0.8,
			raidIconAlternate	= Convert(old.AlternateRaidIcon),
			buffs = {
				enable		= 1,
				wrap		= 1,
				above		= Convert(old.TargetBuffsAbove),
				size		= old.TargetBuffSize		or 15,
				rows		= old.TargetBuffRows		or 3,
				castable	= old.TargetCastableBuffs	or 0,
			},
			debuffs = {
				enable		= 1,
				curable		= old.TargetCurableDebuffs	or 0,
				size		= old.TargetBuffSize		or 19,
				big		= 1,						-- 2.3.6
			},
			reactionHighlight	= Convert(old.TargetReactionHighlight),			-- 1.8.6
			healerMode = {
				enable		= Convert(old.HealerModeTarget),		-- 1.9.1
				type		= old.HealerModeTargetType	or 1,		-- 1.9.1
			},
			defer			= Convert(old.TargetChangeDefer),			-- 1.9.5
			highlightDebuffs = {
				enable		= Convert(old.TargetDebuffHighlight),
				who		= old.TargetDebuffHighlightWho	or 1			-- 2.2.0
			},
			size = {
				width		= old.TargetWidthBonus		or 0,
			},
			sound			= Convert(old.TargetSounds or 1),		-- 2.2.6
		},
		focus = {
			enable			= Convert(old.ShowFocus),
			portrait		= Convert(old.ShowFocusPortrait),
			portrait3D		= Convert(old.ShowFocusPortrait3D),
			castBar = {
				enable		= Convert(old.ArcaneBarFocus),
			},
			hitIndicator		= Convert(old.FocusCombatHitIndicator),			-- 2.1.7
			classIcon		= Convert(old.ShowFocusClassIcon),
			classText		= Convert(old.ShowFocusClassText),			-- 2.0.6
			mobType			= Convert(old.ShowFocusMobType),
			level			= Convert(old.ShowFocusLevel),
			elite			= Convert(ceil((old.ShowFocusElite or 1) / 2)),
			eliteGfx		= Convert(floor((old.ShowFocusElite or 1) / 2)),
			mana			= Convert(old.ShowFocusMana),
			percent			= Convert(old.ShowFocusPercent),
			values			= Convert(old.ShowFocusValues),
			pvpIcon			= Convert(old.ShowFocusPVP),			-- 1.8.3
			scale			= old.Scale_FocusFrame		or 0.8,
			raidIconAlternate	= Convert(old.AlternateRaidIcon),
			buffs = {
				enable		= 1,
				wrap		= 1,
				above		= Convert(old.FocusBuffsAbove),
				size		= old.FocusBuffSize		or 15,
				rows		= old.FocusBuffRows		or 3,
				castable	= old.FocusCastableBuffs	or 0,
				curable		= old.FocusCurableDebuffs	or 0,
			},
			debuffs = {
				enable		= 1,
				size		= old.FocusBuffSize		or 19,
				curable		= old.TargetCurableDebuffs	or 0,
			},
			reactionHighlight	= Convert(old.FocusReactionHighlight),			-- 1.8.6
			healerMode = {
				enable		= Convert(old.HealerModeFocus),				-- 1.9.1
				type		= old.HealerModeFocusType	or 1,			-- 1.9.1
			},
			defer			= Convert(old.TargetChangeDefer),			-- 1.9.5
			highlightDebuffs = {
				enable		= Convert(old.FocusDebuffHighlight),
				who		= old.FocusDebuffHighlightWho	or 1,			-- 2.2.0
			},
			size = {
				width		= old.FocusWidthBonus		or 0,
			},
		},
		targettarget = {
			enable			= Convert(old.ShowTargetTarget),
			buffs = {
				enable		= Convert(old.TargetTargetBuffs),
				above		= Convert(old.TargetTargetBuffsAbove),
				size		= old.FocusBuffSize		or 15,
				rows		= old.FocusBuffRows		or 3,
				castable	= old.TargetCastableBuffs	or 0,
				curable		= old.TargetCurableDebuffs	or 0,
				wrap		= 1,			-- 2.3.5
			},
			debuffs = {
				enable		= Convert(old.TargetTargetBuffs),
				size		= old.FocusBuffSize		or 19,
			},
			scale			= old.Scale_TargetTargetFrame	or 0.8,
			percent			= Convert(old.ShowTargetTargetPercent),
			values			= Convert(old.ShowTargetTargetValues),
			level			= Convert(old.ShowTargetTargetLevel),
			mana			= Convert(old.ShowTargetTargetMana),
			size = {
				width		= old.TargetTargetWidthBonus	or 0,
			},
		},
		targettargettarget = {
			enable			= Convert(old.ShowTargetTargetTarget),
			buffs = {
				enable		= Convert(old.TargetTargetTargetBuffs),
				above		= Convert(old.TargetTargetBuffsAbove),
				size		= old.FocusBuffSize		or 15,
				rows		= old.FocusBuffRows		or 3,
				castable	= old.TargetCastableBuffs	or 0,
				curable		= old.TargetCurableDebuffs	or 0,
			},
			debuffs = {
				enable		= Convert(old.TargetTargetBuffs),
				size		= old.FocusBuffSize		or 19,
			},
			scale			= old.Scale_TargetTargetFrame	or 0.8,
			percent			= Convert(old.ShowTargetTargetPercent),
			values			= Convert(old.ShowTargetTargetValues),
			level			= Convert(old.ShowTargetTargetLevel),
			mana			= Convert(old.ShowTargetTargetMana),
			size = {
				width		= old.TargetTargetWidthBonus	or 0,
			},
		},
		focustarget = {
			enable			= Convert(old.ShowFocusTarget),
			buffs = {
				enable		= Convert(old.FocusTargetBuffs),
				above		= Convert(old.FocusTargetBuffsAbove),
				size		= old.FocusBuffSize		or 15,
				rows		= old.FocusBuffRows		or 3,
				castable	= old.TargetCastableBuffs	or 0,
				curable		= old.TargetCurableDebuffs	or 0,
				wrap		= 1,			-- 2.3.5
			},
			debuffs = {
				enable		= Convert(old.TargetTargetBuffs),
				size		= old.FocusBuffSize		or 19,
			},
			scale			= old.Scale_FocusTargetFrame	or 0.8,
			percent			= Convert(old.ShowFocusTargetPercent),
			values			= Convert(old.ShowFocusTargetValues),
			level			= Convert(old.ShowFocusTargetLevel),
			mana			= Convert(old.ShowFocusTargetMana),
			size = {
				width		= old.FocusTargetWidthBonus	or 0,
			},
		},
		pettarget = {
			enable			= Convert(old.ShowPetTarget),
			buffs = {
				enable		= Convert(old.PlayerPetTargetBuffs),
				above		= Convert(old.PlayerPetTargetBuffsAbove),
				size		= old.TargetBuffSize		or 15,
				rows		= old.TargetBuffRows		or 3,
				castable	= old.TargetCastableBuffs	or 0,
				curable		= old.TargetCurableDebuffs	or 0,
				wrap		= 1,			-- 2.3.5
			},
			debuffs = {
				enable		= Convert(old.TargetTargetBuffs),
				size		= old.TargetBuffSize		or 19,
			},
			scale			= old.Scale_PlayerPetTargetFrame or 0.8,
			percent			= Convert(old.ShowPlayerPetTargetPercent),
			values			= Convert(old.ShowPlayerPetTargetValues),
			level			= Convert(old.ShowPlayerPetTargetLevel),
			mana			= Convert(old.ShowPlayerPetTargetMana),
			size = {
				width		= old.FocusTargetWidthBonus	or 0,
			},
		},
		party = {
			enable			= 1,
			castBar = {
				enable		= Convert(old.ArcaneBarParty),
				castTime	= Convert(old.CastTime),
			},
			spacing			= old.PartySpacing		or 23,
			anchor			= old.PartyAnchor		or "TOP",
			portrait		= Convert(old.ShowPartyPortrait),
			portrait3D		= Convert(old.ShowPartyPortrait3D),
			target = {
				enable		= Convert(old.ShowPartyTarget),
				large		= Convert(old.PartyTargetLarge),
				size		= old.PartyTargetSize		or 120,			-- 2.0.9
			},
			level			= Convert(old.ShowPartyLevel),
			name			= Convert(old.ShowPartyNames),
			values			= Convert(old.ShowPartyValues),
			percent			= Convert(old.ShowPartyPercent),
			classIcon		= Convert(old.ShowPartyClassIcon),
			pvpIcon			= Convert(old.ShowPartyPVP),			-- 1.8.3
			inRaid			= Convert(old.ShowPartyRaid),
			buffs = {
				wrap		= 1,
				enable		= Convert(old.PartyBuffs),
				size		= old.PartyBuffSize		or 22,
				castable	= old.PartyCastableBuffs	or 0,
				rows		= 2,
			},
			debuffs = {
				enable		= Convert(old.PartyDebuffs),
				size		= old.PartyBuffSize		or 32,
				curable		= old.PartyCurableDebuffs	or 0,
				halfSize	= Convert(old.PartyDebuffsHalfSize),			-- 2.2.6
				below		= Convert(old.PartyDebuffsBelow),
			},
			scale			= old.Scale_PartyFrame		or 0.8,
			healerMode = {
				enable		= Convert(old.HealerModeParty),			-- 1.9.1
				type		= old.HealerModePartyType	or 1,			-- 1.9.1
			},
			hitIndicator		= Convert(old.PartyCombatHitIndicator),			-- 2.1.7
			size = {
				width		= old.PartyWidthBonus		or 0,
			},
			flip			= Convert(old.PartyFlip),			-- 2.2.7
		},
		partypet = {
			enable			= Convert(old.ShowPartyPets),
			scale			= old.Scale_PartyPets		or 0.7,
			name			= Convert(old.ShowPartyPetName),
			buffs = {
				enable		= Convert(old.ShowPartyPetBuffs),
				castable	= old.PartyCastableBuffs	or 0,
				size		= 12,
			},
			debuffs = {
				enable		= Convert(old.ShowPartyPetBuffs),
				curable		= old.PartyCurableDebuffs	or 0,
			},
			healerMode = {
--				enable		= nil,
				type		= 1,
			},
			mana			= Convert(old.ShowPartyPetMana),			-- 1.9.1
			level			= Convert(old.ShowPartyPetLevel),			-- 1.9.1
		},
		raid = {
			enable			= Convert(old.ShowRaid),
			sortByClass		= Convert(old.SortRaidByClass),
			sortByRole		= Convert(old.sortByRole),
			sortAlpha		= Convert(old.SortRaidAlpha),
			group = {
				Convert(old.ShowGroup1),
				Convert(old.ShowGroup2),
				Convert(old.ShowGroup3),
				Convert(old.ShowGroup4),
				Convert(old.ShowGroup5),
				Convert(old.ShowGroup6),
				Convert(old.ShowGroup7),
				Convert(old.ShowGroup8),
				Convert(old.ShowGroup9),
			},
			class = {
				{enable = Convert(old.RaidClass1Enable), name = old.RaidClass1 or "WARRIOR"},
				{enable = Convert(old.RaidClass2Enable), name = old.RaidClass2 or "ROGUE"},
				{enable = Convert(old.RaidClass3Enable), name = old.RaidClass3 or "HUNTER"},
				{enable = Convert(old.RaidClass4Enable), name = old.RaidClass4 or "MAGE"},
				{enable = Convert(old.RaidClass5Enable), name = old.RaidClass5 or "WARLOCK"},
				{enable = Convert(old.RaidClass6Enable), name = old.RaidClass6 or "PRIEST"},
				{enable = Convert(old.RaidClass7Enable), name = old.RaidClass7 or "DRUID"},
				{enable = Convert(old.RaidClass8Enable), name = old.RaidClass8 or "SHAMAN"},
				{enable = Convert(old.RaidClass9Enable), name = old.RaidClass9 or "PALADIN"},
				{enable = true, name = "DEATHKNIGHT"},
				{enable = true, name = "MONK"},
				{enable = true, name = "DEMONHUNTER"},
				{enable = true, name = "EVOKER"},
			},
			titles			= Convert(old.ShowRaidTitles),
			percent			= Convert(old.ShowRaidPercents),
			scale			= old.Scale_Raid		or 0.8,
			buffs = {
				enable		= Convert(old.RaidBuffs),
				castable	= old.BuffsCastableCurable	or 0,
				right		= Convert(old.RaidBuffsRight),
				inside		= Convert(old.RaidBuffsInside),
				untilDebuffed	= Convert(old.RaidBuffsUntilDebuffed),			-- 2.1.3
			},
			debuffs = {
				enable		= old.RaidDebuffs		or 0,
			},
			mana			= Convert(old.RaidMana),
			healerMode = {
				enable		= Convert(old.HealerModeRaid),
				type		= old.HealerModeRaidType	or 1,
			},
			spacing			= old.RaidVerticalSpacing	or 0,
			anchor			= old.RaidAnchor		or "TOP",
		},
		raidpet = {
			enable			= Convert(old.ShowRaidPets),				-- 2.1.3
			hunter			= Convert(old.ShowRaidPetsHunter),			-- 2.1.3
			warlock			= Convert(old.ShowRaidPetsWarlock),			-- 2.1.3
		},
		savedPositions = TPerl_CopyTable(old.SavedPositions),
	}

	return new
end

end




-------------------------------------------------------------------------------------
---------------------------------- DEFAULT CONFIGS ----------------------------------
-------------------------------------------------------------------------------------

local defaultConfig = {}


-- TPerl_RegisterConfigDefault
local function TPerl_RegisterConfigDefault(configFunc, configSection)
	tinsert(defaultConfig, {func = configFunc, section = configSection})
end

local function TPerl_MakeDefaultConfig(new)
	for k, v in pairs(defaultConfig) do
		v.func(new, v.section)
	end
end

-- TPerl_Options_Defaults()
function TPerl_Options_Defaults(new)
	TPerl_MakeDefaultConfig(new)
end


-- TPerl_Global_ConfigDefault
local function TPerl_Global_ConfigDefault(default)
	-- Defaults for global options

	if (not default) then
		error("Usage: TPerl_Global_ConfigDefault(<table>)")
		return
	end

	default.transparency = {
		frame		= 1,
		text		= 1,
	}

	default.highlightSelection	= 1
	default.combatFlash	= 1
	default.maximumScale	= 1.5
	default.optionsColour	= {r = 0.7, g = 0.2, b = 0.2}	-- 1.8.3
	default.showAFK		= 1				-- 2.2.4
	default.xperlOldroleicons = 1

	default.minimap = {
		pos		= 186,
		radius = IsRetail and 101 or 78,
		enable		= 1,
	}

	default.highlightDebuffs = {
		enable		= 1,
		border		= 1,
		frame		= 1,
		class		= 1,
	}

	default.buffHelper = {
		enable		= 1,
		sort		= "group",		-- 2.2.5
		visible		= 1,			-- 2.2.9
	}

	default.buffs = {
		cooldown	= 1,			-- 2.2.3
		countdown	= 1,			-- 2.2.2
		countdownStart	= 20,			-- 2.2.2
	}

	default.rangeFinder = TPerl_DefaultRangeFinder()

	default.tooltip = {
		enable		= 1,			-- 2.0.5
		enableBuffs	= 1,			-- 2.3.4a
--		fading		= nil,			-- 1.8.3
--		xperlInfo	= nil,			-- 1.8.6
		modifier	= "all",		-- 2.0.6
	}

	default.colour = {
		border		= {r = 0.5, g = 0.5, b = 0.5, a = 1},
		frame		= {r = 0, g = 0, b = 0, a = 1},
		class		= 1,
		guildList	= 1,		-- 1.8.9
		classic		= 1,
		bar		= TPerl_DefaultBarColours(),
		reaction	= TPerl_DefaultReactionColours(),
		gradient	= TPerl_DefaultGradientColours(),
	}

	default.bar = {
		texture		= {"Perl v2", "Interface\\Addons\\TPerl\\Images\\TPerl_StatusBar"},
		background	= 1,
--		fading		= nil,		-- 1.8.9
		fadeTime	= 0.5,		-- 1.9.1
		fat		= 1,
--		inverse		= nil,		-- 1.8.6
	}

	default.highlight = {
		enable			= 1,
		HOT			= 1,
		SHIELD			= 1,
		AGGRO			= 1,
--		MISSING			= nil,
--		all			= nil,
	}

end

-- TPerl_Target_ConfigDefault
local function TPerl_Target_ConfigDefault(default, section)
	local defaultHD, defaultHDwho
	local _, class = UnitClass("player")
	if (section == "target" and class == "ROGUE") then
		defaultHD = 1
		defaultHDwho = 3
	else
		defaultHDwho = 2
	end
	default[section] = {
		enable			= 1,
		portrait		= 1,
		portrait3D		= 1,
		castBar = {
			enable		= 1,
		},
		hitIndicator	= 1,			-- 2.1.7
		threat			= 1,
		threatMode		= "portraitFrame",
		classIcon		= 1,
--		classText		= nil,			-- 2.0.6
		mobType			= 1,
		level			= 1,
		healprediction	= 1,
		hotPrediction	= 1,
		absorbs			= 1,
		elite			= 1,
--		eliteGfx		= nil,
		mana			= 1,
		percent			= 1,
		values			= 1,
		combo = {
			enable		= 1,
			blizzard	= 1,
			pos		= "top",
		},
		comboindicator = {
			enable		= 1,			-- 5.0.4
		},
		pvpIcon			= 1,			-- 1.8.3
		scale			= 0.8,
		raidIconAlternate	= 1,
		buffs = {
			enable		= 1,
			wrap		= 1,
--			above		= nil,
			size		= 22,
			rows		= 3,
			castable	= 0,
		},
		debuffs = {
			enable		= 1,
			size		= 29,
			curable		= 0,
			big			= 1,			-- 2.3.6
		},
--		reactionHighlight	= nil,		-- 1.8.6
		healerMode = {
--			enable		= nil,			-- 1.9.1
			type		= 1,			-- 1.9.1
		},
--		defer			= nil,			-- 1.9.5
		highlightDebuffs = {
			enable		= defaultHD,
			who			= defaultHDwho		-- 2.2.0
		},
		size = {
			width		= 0,
		},
		sound			= 1,			-- 2.2.6
	}
end

-- TPerl_Party_ConfigDefault
local function TPerl_Party_ConfigDefault(default)
	default.party = {
		castBar = {
			enable		= 1,
			castTime	= 1,
		},
		spacing			= 23,
		anchor			= "TOP",
		enable			= 1,			-- 4.0.0
		portrait		= 1,
		portrait3D		= 1,
		hitIndicator	= 1,			-- 2.1.7
		threat			= 1,
		threatMode		= "portraitFrame",
		target = {
			enable		= 1,
			large		= 1,
			size		= 120,			-- 2.0.9
		},
		level			= 1,
		healprediction	= 1,
		absorbs			= 1,
		hotPrediction	= 1,
		name			= 1,
		values			= 1,
		percent			= 1,
		classIcon		= 1,
		pvpIcon			= 1,			-- 1.8.3
		showPlayer		= nil,
		inRaid			= 1,
		buffs = {
			enable		= 1,
			wrap		= 1,			-- 2.3.5
			size		= 22,
			castable	= 0,
			rows		= 2,
		},
		debuffs = {
			enable		= 1,
			size		= 32,
			curable		= 0,
			halfSize	= 1,			-- 2.2.6
			below		= 1,
		},
		scale			= 0.8,
		healerMode = {
--			enable		= nil,			-- 1.9.1
			type		= 1,			-- 1.9.1
		},
		size = {
			width		= 0,
		},
--		flip			= nil,			-- 2.2.7
	}
end

-- TPerl_PartyPet_ConfigDefault
local function TPerl_PartyPet_ConfigDefault(default)
	default.partypet = {
		enable			= 1,
		scale			= 0.7,
		name			= 1,
		buffs = {
			enable		= 1,
			castable	= 0,
			size		= 12,
		},
		debuffs = {
			enable		= 1,
			curable		= 0,
		},
		healerMode = {
			--enable		= nil,
			type		= 1,
		},
		mana			= 1,
		--level			= nil,
	}
end

-- TPerl_Player_ConfigDefault
local function TPerl_Player_ConfigDefault(default)
	default.player = {
		castBar = {
			enable		= 1,
--			original	= nil,
--			castTime	= nil,
		},
		portrait		= 1,
		portrait3D		= 1,
		hitIndicator	= 1,
		threat			= 1,
		threatMode		= "portraitFrame",
		level			= 1,
		healprediction	= 1,
		absorbs			= 1,
		hotPrediction	= 1,
		classIcon		= 1,
--		xpBar			= nil,
--		repBar			= nil,
		pvpIcon			= 1,
		values			= 1,
		percent			= 1,
		scale			= 0.9,
		partyNumber		= 1,
--		withName		= nil,
		showRunes		= 1,
		dockRunes		= 1,
		lockRunes		= 1,

		fullScreen = {
			enable		= 1,
			lowHP		= 30,
			highHP		= 40,
		},

		healerMode = {
--			enable		= nil,
			type		= 1,
		},

		buffs = {
			enable		= 1,
--			above		= nil,
			size		= 25,
			wrap		= 1,			-- 2.3.5
			rows		= 2,			-- 2.3.5
			hideBlizzard	= 1,
			count		= 40,
			cooldown	= 1,
			flash		= 1,
		},
		debuffs = {
			enable		= 1,
			size		= 25,
		},
		size = {
			width		= 0,
		},
	}
end

-- TPerl_Pet_ConfigDefault
local function TPerl_Pet_ConfigDefault(default)
	default.pet = {
		castBar = {
			enable = 1,
		},
		portrait = 1,
		portrait3D = 1,
		hitIndicator= 1,
		happiness = {
			enable = 1,
			onlyWhenSad	= 1,
			flashWhenSad = 1,
		},
		threat = 1,
		threatMode = "portraitFrame",
		level = 1,
		healprediction = 1,
		absorbs = 1,
		hotPrediction = 1,
		scale = 0.7,
		name = 1,
		buffs = {
			enable = 1,
			size = 18,
			wrap = 1,
			rows = 3,
		},
		debuffs = {
			enable = 1,
			size = 18,
		},
		values = 1,
		healerMode = {
			type = 1,
		},
		size = {
			width = 0,
		},
	}
end

-- TPerl_TargetTarget_ConfigDefault
local function TPerl_TargetTarget_ConfigDefault(default, section)
	local e
	if (section ~= "targettargettarget") then
		e = 1
	end

	default[section] = {
		enable			= e,
		buffs = {
			enable		= 1,
--			above		= nil,
			size		= 22,
			rows		= 3,
			castable	= 0,
			wrap		= 1,			-- 2.3.5
		},
		debuffs = {
			size		= 29,
			enable		= 1,
			curable		= 0,
		},
		scale			= 0.7,
		pvpIcon			= 1,
		percent			= 1,
		values			= 1,
--		level			= nil,
		healprediction	= 1,
		absorbs			= 1,
		hotPrediction	= 1,
		mana			= 1,
		size = {
			width		= 0,
		},
		healerMode = {
--			enable		= nil,			-- 1.9.1
			type		= 1,			-- 1.9.1
		},
	}
end

-- TPerl_Raid_ConfigDefault
local function TPerl_Raid_ConfigDefault(default)
	default.raid = {
		enable			= 1,
		disableDefault	= nil,
--		sortByClass		= nil,
		sortByRole 		= nil,
--		sortAlpha		= nil,
		group = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		class = {
			{enable = 1, name = "WARRIOR"},
			{enable = 1, name = "ROGUE"},
			{enable = 1, name = "HUNTER"},
			{enable = 1, name = "MAGE"},
			{enable = 1, name = "WARLOCK"},
			{enable = 1, name = "PRIEST"},
			{enable = 1, name = "DRUID"},
			{enable = 1, name = "SHAMAN"},
			{enable = 1, name = "PALADIN"},
			{enable = 1, name = "DEATHKNIGHT"},
			{enable = 1, name = "MONK"},
			{enable = 1, name = "DEMONHUNTER"},
			{enable = 1, name = "EVOKER"},
		},
		role			= nil,
		titles			= 1,
		percent			= 1,
		precisionPercent = 1,
		healprediction	= 1,
		absorbs			= 1,
		hotPrediction	= 1,
		mana			= 1,
		manaPercent		= 1,
		precisionManaPercent = 1,
		scale			= 0.8,
		spacing			= 0,
		inParty			= nil,
		buffs = {
--			enable		= nil,
			castable	= 0,
			right		= 1,
			inside		= 1,
--			untilDebuffed	= nil,			-- 2.1.3
		},
		debuffs = {
			enable		= 1,
		},
--		mana			= nil,
		healerMode = {
--			enable		= nil,
			type		= 1,
		},
		anchor			= "TOP",
		gap				= 0,
		size = {
			width		= 0,
		},
	}
end

-- TPerl_RaidPet_ConfigDefault
local function TPerl_RaidPet_ConfigDefault(default, section)
	default.raidpet = {
		enable			= 1,			-- 2.1.3
	}
end

TPerl_RegisterConfigDefault(TPerl_Global_ConfigDefault)
TPerl_RegisterConfigDefault(TPerl_Target_ConfigDefault, "target")
TPerl_RegisterConfigDefault(TPerl_Target_ConfigDefault, "focus")
TPerl_RegisterConfigDefault(TPerl_Party_ConfigDefault)
TPerl_RegisterConfigDefault(TPerl_PartyPet_ConfigDefault)
TPerl_RegisterConfigDefault(TPerl_Player_ConfigDefault)
TPerl_RegisterConfigDefault(TPerl_Pet_ConfigDefault)
TPerl_RegisterConfigDefault(TPerl_TargetTarget_ConfigDefault, "targettargettarget")
TPerl_RegisterConfigDefault(TPerl_TargetTarget_ConfigDefault, "targettarget")
TPerl_RegisterConfigDefault(TPerl_TargetTarget_ConfigDefault, "focustarget")
TPerl_RegisterConfigDefault(TPerl_TargetTarget_ConfigDefault, "pettarget")
TPerl_RegisterConfigDefault(TPerl_Raid_ConfigDefault)
TPerl_RegisterConfigDefault(TPerl_RaidPet_ConfigDefault)


-- TPerl_DefaultGradientColours
function TPerl_DefaultGradientColours()
	return {
		enable = 1,
		--horizontal = nil,
		s = {r = 0.25, g = 0.25, b = 0.25, a = 1},
		e = {r = 0.1, g = 0.1, b = 0.1, a = 0}
	}
end

-- TPerl_DefaultReactionColours
function TPerl_DefaultReactionColours()
	return {
		enemy		= {r = 1, g = 0, b = 0},
		neutral		= {r = 1, g = 1, b = 0},
		unfriendly	= {r = 1, g = 0.5, b = 0},
		friend		= {r = 0, g = 1, b = 0},
		none		= {r = 0.5, g = 0.5, b = 1},
		tapped		= {r = 0.5, g = 0.5, b = 0.5},
	}
end

-- TPerl_DefaultBarColours
function TPerl_DefaultBarColours()
	return {
		healthEmpty	= {r = 1, g = 0, b = 0},
		healthFull	= {r = 0, g = 1, b = 0},
		absorb		= {r = 0.14, g = 0.33, b = 0.7, a = 0.7},
		healprediction = {r = 0, g = 1, b = 1, a = 1},
		hot			= {r = 1, g = 0.72, b = 0.1, a = 0.7},
		mana		= {r = 0, g = 0, b = 1},
		energy		= {r = 1, g = 1, b = 0},
		rage		= {r = 1, g = 0, b = 0},
		focus		= {r = 1, g = 0.5, b = 0.25},
		runic_power	= {r = 0, g = 0.82, b = 1},
		insanity	= {r = 0.4, g = 0, b = 0.8},
		lunar		= {r = 0.3, g = 0.52, b = 0.9},
		maelstrom	= {r = 0, g = 0.5, b = 1},
		fury		= {r = 0.788, g = 0.259, b = 0.992},
		pain		= {r = 1, g = 0.611, b = 0},
	}
end

-- TPerl_DefaultFrameAppearance
function TPerl_DefaultFrameAppearance()
	TPerlDB.transparency.frame	= 1
	TPerlDB.transparency.text	= 1
	TPerlDB.colour.border		= {r = 0.5, g = 0.5, b = 0.5, a = 1}
	TPerlDB.colour.frame		= {r = 0, g = 0, b = 0, a = 1}
end

-- TPerl_DefaultRangeFinder
function TPerl_DefaultRangeFinder()
	return {						-- 2.1.7
--		enabled		= e,	-- 2.3.4a Defaulting to OFF now, because of so many confused users complaining about faded frames. RTFM... (TODO: Write a manual)
		Main		= {enabled = true, FadeAmount = 0.5, HealthLowPoint = 0.85},		-- PlusHealth = false,
		NameFrame	= {FadeAmount = 0.5, HealthLowPoint = 0.85},
		StatsFrame	= {FadeAmount = 0.5, HealthLowPoint = 0.85},
	}
end

-- TPerl_Custom_Config_OnShow
function TPerl_Custom_Config_OnShow(self)
	if (not TPerlDB.custom) then
		TPerlDB.custom = {
			enable = false,
			alpha = 0.5,
			blend = "ADD"
		}
	end
	if (not TPerlDB.custom.zones) then
		if (not TPerl_Custom) then
			LoadAddOn("TPerl_CustomHighlight")
		end
		if (TPerl_Custom) then
			TPerl_Custom:SetDefaultZoneData()
		end
	end

	self:SetScale(1.1)
	TPerl_Custom_ConfigNew:Hide()
	self:Setup()
	TPerl_Options_Mask:Show()
	TPerl_Options_Custom_StartIconDB(self)
end

local function CompareSpell(a, b)
	if IsRetail then
		local spellInfoA = C_Spell.GetSpellInfo(a)
		local spellNameA = ""
		if spellInfoA then
			spellNameA = spellInfoA.name
		end
		local spellInfoB = C_Spell.GetSpellInfo(b)
		local spellNameB = ""
		if spellInfoB then
			spellNameB = spellInfoB.name
		end
		return spellNameA < spellNameB
	else

		local nameA = GetSpellInfo(a)
		local nameB = GetSpellInfo(b)
		return nameA < nameB
	end
end

-- TPerl_Options_Custom_FillList
function TPerl_Options_Custom_FillList(self, setName)
	if (not TPerlDB) then
		return
	end

	self.start = self.scrollBar.bar:GetValue() + 1

	local typ = self.type
	local list, source
	if typ == "zone" then
		source = TPerlDB.custom and TPerlDB.custom.zones
	elseif typ == "debuff" then
		local zone = TPerl_Options_Custom_SelectedZone(TPerl_Custom_Config)
		if (zone) then
			source = TPerlDB.custom and TPerlDB.custom.zones and TPerlDB.custom.zones[zone]
		end
	end

	if source then
		for name, key in pairs(source) do
			if not list then
				list = {}
			end
			if typ == "debuff" then
				if C_Spell and C_Spell.GetSpellInfo then
					local spellInfo = C_Spell.GetSpellInfo(name)
					if spellInfo then
						tinsert(list, spellInfo.name)
					end
				else
					if GetSpellInfo(name) then
						tinsert(list, name)
					end
				end
			else
				tinsert(list, name)
			end
		end
		if list then
			if typ == "zone" then
				sort(list)
			elseif typ == "debuff" then
				sort(list, CompareSpell)
			end
		end
	end

	if not self.selection or not list then
		self.selection = 1
	else
		if self.selection < 1 then
			self.selection = 1
		elseif self.selection > #list then
			self.selection = #list
		end
	end

	for i = 1, #self.line do
		local row = self.line[i]
		row:SetText("")
		row:UnlockHighlight()
		row:Hide()
		row.spellid = nil
	end

	local db = TPerl_Custom_Config.iconDB
	if list then
		local newName
		local line = 1
		for i = self.start, self.start + #self.line - 1 do
			if i > #list then
				break
			end
			local row = self.line[line]

			if typ == "debuff" then
				local spellid = list[i]
				if C_Spell and C_Spell.GetSpellInfo then
					local spellInfo = C_Spell.GetSpellInfo(spellid)
					if spellInfo then
						if spellInfo.name and spellInfo.iconID then
							row:SetText(format("|T%s:0|t%s", spellInfo.iconID, spellInfo.name))
							row.spellid = spellid
						end
					end
				else
					local name, _, icon = GetSpellInfo(spellid)
					if name and icon then
						row:SetText(format("|T%s:0|t%s", icon, name))
						row.spellid = spellid
					end
				end
			else
				row:SetText(list[i])
			end
			row:Show()

			if i == self.selection then
				self.line[line]:LockHighlight()

				if setName then
					newName = list[i]
				end
			end

			line = line + 1
		end

		local offset = self.scrollBar.bar:GetValue()
		if FauxScrollFrame_Update(self.scrollBar, #list, 12, 1) then
			self.scrollBar:Show()
		else
			self.scrollBar:Hide()
		end
	else
		self.scrollBar:Hide()
	end
end

-- TPerl_Options_Custom_OnClick
function TPerl_Options_Custom_OnClick(self, line)
	if (self.type == "zone") then
		TPerl_Options_Custom_FillList(TPerl_Custom_Configdebuffs)
		if (TPerl_Custom_ConfigNew:IsShown()) then
			local zone = TPerl_Options_Custom_SelectedZone(TPerl_Custom_Config)
			if (zone) then
				TPerl_Custom_ConfigNew_Zone:SetText(zone)
			end
		end

	elseif (self.type == "debuff") then
		TPerl_Options_Custom_SetIcon()
	end

	TPerl_Options_Custom_Buttons(TPerl_Custom_Config)
end

-- TPerl_Options_Custom_SetIcon
function TPerl_Options_Custom_SetIcon()
	local name = TPerl_Custom_Configdebuffs.debuff
	local db = TPerl_Custom_Config.iconDB
	if (db and name) then
		local spellid = db and db[name]
		if (spellid) then
			if C_Spell and C_Spell.GetSpellInfo then
				local spellInfo = C_Spell.GetSpellInfo(spellid)
				if spellInfo then
					if spellInfo.iconID then
						TPerl_Custom_Config.icon:SetTexture(spellInfo.iconID)
						TPerl_Custom_Config.icon:Show()
						return
					end
				end
			else
				local _, _, icon = GetSpellInfo(spellid)
				if icon then
					TPerl_Custom_Config.icon:SetTexture(icon)
					TPerl_Custom_Config.icon:Show()
					return
				end
			end
		end
	end
end

-- TPerl_Options_Custom_InitList
function TPerl_Options_Custom_InitList(self, type)
	self:GetParent()["list"..type] = self
	self.type = type
	self.start = 1
	self.selection = 1
	self.scrollBar = _G[self:GetName().."scrollBar"]
	self.scrollBar.bar = _G[self:GetName().."scrollBarScrollBar"]
	self.FillList = TPerl_Options_Custom_FillList
	self.OnClick = TPerl_Options_Custom_OnClick
	self:FillList()

	if (type == "debuff") then
		self.debuff = nil
		if (self.line[1]:IsShown()) then
			self.debuff = self.line[1]:GetText()
			TPerl_Options_Custom_SetIcon()
		end
	end
end

-- customOnUpdate
local ICON_STEP_SIZE	= 500
local ICON_STOP_SCAN	= IsClassic and 33000 or 310000
local function customOnUpdate(self, elapsed)
	local db = self.iconDB
	local ind = self.iconIndex
	local stop
	for i = ind, ind + ICON_STEP_SIZE - 1 do
		if C_Spell and C_Spell.GetSpellLink and C_Spell.GetSpellInfo then
			if C_Spell.GetSpellLink(i) then -- Filter out talents
				local spellInfo = C_Spell.GetSpellInfo(i)
				if spellInfo then
					if spellInfo.name and spellInfo.iconID then
						if spellInfo.iconID ~= 134400 and spellInfo.iconID ~= 136235 then -- Filter out silly test ones
							db[i] = strlower(spellInfo.name)
						end
						self.missing = 0
					end
				end
			else
				self.missing = (self.missing or 0) + 1
				if self.missing > 1000 then
					stop = true
					break
				end
			end
		else
			if GetSpellLink(i) then -- Filter out talents
				local name, _, icon = GetSpellInfo(i)
				if name and icon then
					if icon ~= 134400 and icon ~= 136235 then -- Filter out silly test ones
						db[i] = strlower(name)
					end
				end
				self.missing = 0
			else
				self.missing = (self.missing or 0) + 1
				if self.missing > 1000 then
					stop = true
					break
				end
			end
		end
	end

	self.iconIndex = self.iconIndex + ICON_STEP_SIZE
	self.progress:SetValue(self.iconIndex)
	if stop or self.iconIndex == ICON_STOP_SCAN then
		self:SetScript("OnUpdate", nil)
		self.progress:SetValue(0)
		self.missing = nil
		TPerl_Options_Custom_FillList(TPerl_Custom_Configdebuffs)
	elseif self.iconIndex % ICON_STEP_SIZE == 0 then
		self:SetScript("OnUpdate", nil)

		C_Timer.After(0.1, function()
			self:SetScript("OnUpdate", customOnUpdate)
		end)
	end

	local search = TPerl_Custom_ConfigNew_Search:GetText()
	if (search and strlen(search) > 2) then
		TPerl_Options_Custom_ScanForIcons(TPerl_Custom_Config)
	end
end

-- TPerl_Options_Custom_StartIconDB
function TPerl_Options_Custom_StartIconDB(self, index)
	self.iconDB = TPerl_GetReusableTable()
	--self.iconDB = { }
	self.iconIndex = index or 0
	self.progress:SetMinMaxValues(index or 0, ICON_STOP_SCAN)
	self.progress:SetValue(index or 0)

	self:SetScript("OnUpdate", customOnUpdate)
end

-- TPerl_Options_Custom_CleanupIconDB
function TPerl_Options_Custom_CleanupIconDB(self)
	TPerl_FreeTable(self.iconDB, true)
end

-- TPerl_Options_Custom_ScanForIcons
function TPerl_Options_Custom_ScanForIcons(self)
	local search = TPerl_Custom_ConfigNew_Search:GetText()
	if search and strlen(search) > 2 then
		search = strlower(search)
		local dbname = self.iconDB and self.iconDB
		if dbname then
			local list = TPerl_GetReusableTable()
			--local list = { }
			for id, name in pairs(dbname) do
				if tonumber(search) then
					if id == tonumber(search) then
						tinsert(list, id)
						break
					end
				else
					local success, ret = pcall(strfind, name, search)
					if success and ret then
						tinsert(list, id)
						if #list > 40 then
							break
						end
					end
				end
			end

			if not self.icons.icon then
				self.icons.icon = { }
			end

			local count = min(#list, 40)
			local iconNum = 1
			for i, spellid in ipairs(list) do
				local spellid = list[i]
				local icon = self.icons.icon[iconNum]
				if not icon then
					icon = CreateFrame("Button", "TPerlOptionsCustomIcon"..iconNum, TPerl_Custom_ConfigNew_Icons, "ActionButtonTemplate")
					self.icons.icon[iconNum] = icon
					icon.tex = _G[icon:GetName().."Icon"]

					icon:SetScript("OnClick", function(self)
						if IsModifiedClick("CHATLINK") then
							local link = (C_Spell and C_Spell.GetSpellLink) and C_Spell.GetSpellLink(self.spellid) or (GetSpellLink and GetSpellLink(self.spellid))
							if link then
								ChatEdit_InsertLink(link)
							end
						else
							local zone = TPerl_Custom_ConfigNew_Zone:GetText()
							if zone and zone ~= "" then
								local zones = TPerlDB.custom.zones
								if not zones[zone] then
									zones[zone] = {}
								end
								TPerlDB.custom.zones[zone][self.spellid] = true
								TPerl_Custom_ConfigNew:Hide()
								TPerl_Custom_Config.listzone:FillList()
								TPerl_Custom_Config.listdebuff:FillList()

								if (TPerl_Custom) then
									TPerl_Custom:PLAYER_ENTERING_WORLD()
								end
							end
						end
					end)
					icon:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_TOP")
						local link = (C_Spell and C_Spell.GetSpellLink) and C_Spell.GetSpellLink(self.spellid) or (GetSpellLink and GetSpellLink(self.spellid))
						local spellName, icon
						if C_Spell and C_Spell.GetSpellInfo then
							local spellInfo = C_Spell.GetSpellInfo(self.spellid)
							if spellInfo then
								name = spellInfo.name
								icon = spellInfo.iconID
							end
						else
							local _
							name, _, icon = GetSpellInfo(self.spellid)
						end
						if link then
							if IsClassic then
								local _, _, _, _, _, _, spellID = GetSpellInfo(self.spellid)
								if spellID then
									local newLink = format("spell:%d:0:0:0", spellID)
									GameTooltip:SetHyperlink(newLink)
								end
							else
								GameTooltip:SetHyperlink(link)
							end
						else
							GameTooltip:SetText(name, 1, 1, 1)
						end
					end)
					icon:SetScript("OnLeave", function(self)
						GameTooltip:Hide()
					end)

					if iconNum == 1 then
						icon:SetPoint("TOPLEFT")
					elseif (iconNum == 11) then
						icon:SetPoint("TOPLEFT", self.icons.icon[1], "BOTTOMLEFT", 0, -9)
					elseif (iconNum == 21) then
						icon:SetPoint("TOPLEFT", self.icons.icon[11], "BOTTOMLEFT", 0, -9)
					elseif (iconNum == 31) then
						icon:SetPoint("TOPLEFT", self.icons.icon[21], "BOTTOMLEFT", 0, -9)
					else
						icon:SetPoint("TOPLEFT", self.icons.icon[iconNum - 1], "TOPRIGHT", 9, 0)
					end
				end

				local spellName, icon
				if C_Spell and C_Spell.GetSpellInfo then
					local spellInfo = C_Spell.GetSpellInfo(spellid)
					if spellInfo then
						name = spellInfo.name
						icon = spellInfo.iconID
					end
				else
					local _
					name, _, tex = GetSpellInfo(spellid)
				end
				if tex then
					icon.spellid = spellid
					icon.tex:SetTexture(tex)
					icon:Show()
					if GameTooltip:IsOwned(icon) then
						icon:GetScript("OnEnter")(icon)
					end
					iconNum = iconNum + 1
				end

				if iconNum > 40 then
					break
				end
			end

			for i = #list + 1, 40 do
				local icon = self.icons.icon[i]
				if icon then
					icon:Hide()
				end
			end

			self.icons:Show()

			TPerl_FreeTable(list)
			return
		end
	end

	self.icons:Hide()
end

-- TPerl_Options_Custom_OnDelete
function TPerl_Options_Custom_OnDelete(self)
	local zone = TPerl_Options_Custom_SelectedZone(self)
	local spellid = TPerl_Options_Custom_SelectedDebuff(self)
	if (zone and spellid) then
		local zones = TPerlDB.custom.zones
		if (zones and zones[zone]) then
			zones[zone][spellid] = nil

			if (not next(zones[zone])) then
				zones[zone] = nil
			end

			TPerl_Custom_Config.listzone:FillList()
			TPerl_Custom_Config.listdebuff:FillList()

			TPerl_Options_Custom_Buttons(TPerl_Custom_Config)
		end
	end
end

-- TPerl_Options_Custom_SelectedZone
function TPerl_Options_Custom_SelectedZone(self)
	local sel = self.listzone.selection
	local start = self.listzone.start
	if (sel) then
		local row = self.listzone.line[sel - start + 1]
		if (row) then
			return row:GetText()
		end
	end
end

-- TPerl_Options_Custom_SelectedDebuff
function TPerl_Options_Custom_SelectedDebuff(self)
	if (TPerl_Options_Custom_SelectedZone(self)) then
		local sel = self.listdebuff.selection
		if (sel) then
			local row = self.listdebuff.line[sel]
			if (row) then
				return row.spellid
			end
		end
	end
end

-- TPerl_Options_Custom_Buttons
function TPerl_Options_Custom_Buttons(self)
	local zone = TPerl_Options_Custom_SelectedZone(self)
	local spellid = TPerl_Options_Custom_SelectedDebuff(self)
	if (zone and spellid) then
		TPerl_Custom_ConfigEdit_Delete:Enable()
	else
		TPerl_Custom_ConfigEdit_Delete:Disable()
	end
end


----------------------------------------------
-------------- UPGRADE SETTINGS --------------
----------------------------------------------

if (TPerl_UpgradeSettings) then
	local frameList = {"player", "pet", "target", "targettarget", "pettarget", "focus", "focustarget", "targettargettarget", "party", "partypet"}
	-- UpgradeSettings
	-- For future upgrade of settings from old versions
	local function UpgradeSettings(old, oldVersion)
		if (not old.pet) then
			old.pet = {}
			TPerl_Pet_ConfigDefault(old)
		elseif (not old.pettarget) then
			old.pettarget = {}
			TPerl_TargetTarget_ConfigDefault(old, "pettarget")
		elseif (not old.pet.castBar) then
			old.pet.castBar = {enable = 1}
		end

		local _, playerClass = UnitClass("player")

		if (type(oldVersion) == "string") then
			for k, v in pairs(frameList) do
				if (old[v]) then
					if (not old[v].buffs) then
						old[v].buffs = {enable = 1, size = 20, bigpet = 1, wrap = 1}
					elseif (not old[v].buffs.size) then
						old[v].buffs.size = 20
					end
					if (not old[v].debuffs) then
						old[v].debuffs = {enable = 1, size = 20, bigpet = 1, wrap = 1}
					elseif (not old[v].debuffs.size) then
						old[v].debuffs.size = 20
					end
				end
			end

			if (not old.colour.bar.absorb or old.colour.bar.absorb[1]) then
				old.colour.bar.absorbs = {r = 0.14, g = 0.33, b = 0.7, a = 0.7}
			end

			if (not old.colour.bar.healprediction or old.colour.bar.healprediction[1]) then
				old.colour.bar.healprediction = {r = 0, g = 1, b = 1, a = 1}
			end

			if (not old.colour.bar.hot or old.colour.bar.hot[1]) then
				old.colour.bar.hot = {r = 1, g = 0.72, b = 0.1, a = 0.7}
			end

			if (not old.colour.bar.runic_power or old.colour.bar.runic_power[1]) then
				if (PowerBarColor) then
					old.colour.bar.runic_power = {r = PowerBarColor["RUNIC_POWER"].r, g = PowerBarColor["RUNIC_POWER"].g, b = PowerBarColor["RUNIC_POWER"].b}
				else
					old.colour.bar.runic_power = {r = 1, g = 0.25, b = 1}
				end
			end

			if (not old.colour.bar.insanity or old.colour.bar.insanity[1]) then
				if (PowerBarColor) then
					old.colour.bar.insanity = {r = PowerBarColor["INSANITY"].r, g = PowerBarColor["INSANITY"].g, b = PowerBarColor["INSANITY"].b}
				else
					old.colour.bar.insanity = {r = 0.4, g = 0, b = 0.8}
				end
			end

			if (not old.colour.bar.lunar or old.colour.bar.lunar[1]) then
				if (PowerBarColor) then
					old.colour.bar.lunar = {r = PowerBarColor["LUNAR_POWER"].r, g = PowerBarColor["LUNAR_POWER"].g, b = PowerBarColor["LUNAR_POWER"].b}
				else
					old.colour.bar.lunar = {r = 0.3, g = 0.52, b = 0.9}
				end
			end

			if (not old.colour.bar.maelstrom or old.colour.bar.maelstrom[1]) then
				if (PowerBarColor) then
					old.colour.bar.maelstrom = {r = PowerBarColor["MAELSTROM"].r, g = PowerBarColor["MAELSTROM"].g, b = PowerBarColor["MAELSTROM"].b}
				else
					old.colour.bar.maelstrom = {r = 0, g = 0.5, b = 1}
				end
			end

			if (not old.colour.bar.fury or old.colour.bar.fury[1]) then
				if (PowerBarColor) then
					old.colour.bar.fury = {r = PowerBarColor["FURY"].r, g = PowerBarColor["FURY"].g, b = PowerBarColor["FURY"].b}
				else
					old.colour.bar.fury = {r = 0.788, g = 0.259, b = 0.992}
				end
			end

			if (not old.colour.bar.pain or old.colour.bar.pain[1]) then
				if (PowerBarColor) then
					old.colour.bar.pain = {r = PowerBarColor["PAIN"].r, g = PowerBarColor["PAIN"].g, b = PowerBarColor["PAIN"].b}
				else
					old.colour.bar.pain = {r = 1, g = 0.611, b = 0}
				end
			end

			ValidateClassNames(old.raid)

			if (old.bar and old.bar.texture and old.bar.texture[1] == "TPerl 2") then
				old.bar.texture[1] = "BantoBar"
			end

			if (oldVersion < "3.0.3b") then
				old.buffs.names = true
			end

			if (oldVersion < "3.0.3a") then
				old.target.buffs.bigpet = 1
				old.targettarget.buffs.bigpet = 1
				old.targettargettarget.buffs.bigpet = 1
				old.focus.buffs.bigpet = 1
				old.focustarget.buffs.bigpet = 1
				old.pet.buffs.bigpet = 1
				old.pettarget.buffs.bigpet = 1
				old.party.buffs.bigpet = 1
			end

			if (oldVersion < "3.0.2") then
				old.focus.threat = old.target.threat
				old.focus.threatMode = old.focus.portrait and old.target.threatMode or "nameFrame"
				old.party.threat = old.target.threat
				old.party.threatMode = old.party.portait and old.target.threatMode or "nameFrame"
			end

			if (oldVersion < "3.0.0c") then
				old.target.threat = 1
				old.target.threatMode = "portraitFrame"
				old.focus.threat = 1
				old.focus.threatMode = "portraitFrame"
				old.party.threat = 1
				old.party.threatMode = "portraitFrame"
				old.pet.threat = 1
				old.pet.threatMode = "portraitFrame"
			end

			if (oldVersion < "3.0.0") then
				old.player.showRunes = 1
				old.player.dockRunes = 1
			end

			if (oldVersion < "2.4.2c") then
				old.highlight.sparkles = 1
				old.highlight.POM = old.highlight.HOT
			end

			if (oldVersion <= "2.4.2") then
				if (old.custom) then
					old.custom.alpha = 0.5
					old.custom.blend = "ADD"
				end
			end

			if (not old.custom) then
				old.custom = {
					enable = false,
					alpha = 0.5,
					blend = "ADD"
				}
			end

			if (oldVersion <= "2.4.0c") then
				old.target.ownDamageOnly = true
				old.focus.ownDamageOnly = true
			end

			if (oldVersion <= "2.3.9a") then
				old.player.debuffs.enable = old.player.buffs.enable
			end

			if (oldVersion <= "2.3.9") then
				old.showReadyCheck = 1
			end

			if (oldVersion <= "2.3.6a") then
				old.target.buffs.wrap = 1
				old.targettarget.buffs.wrap = 1
				old.targettargettarget.buffs.wrap = 1
				old.pettarget.buffs.wrap = 1
				old.focus.buffs.wrap = 1
				old.focustarget.buffs.wrap = 1
				old.party.buffs.wrap = 1

				-- These should have been defaulted to OFF, oops
				old.targettarget.debuffs.big = nil
				old.targettargettarget.debuffs.big = nil
				old.focustarget.debuffs.big = nil
				old.pettarget.debuffs.big = nil
			end
			if (oldVersion <= "2.3.6") then
				old.target.debuffs.big = 1
				old.focus.debuffs.big = 1
				old.player.buffs.rows = 2
				old.party.buffs.rows = 2
			end

			if (oldVersion < "2.3.5") then
				old.target.range30yard = nil
				old.focus.range30yard = nil
				old.party.range30yard = nil
				old.raid.manaPercent = 1

				old.highlight.MISSING = nil
				if (playerClass == "PRIEST" or playerClass == "DRUID" or playerClass == "PALADIN" or playerClass == "SHAMAN") then
					old.highlight.HOTCOUNT = 1
				end
			end

			if (oldVersion < "2.3.4a") then
				old.tooltip.enableBuffs = 1
			end

			if (oldVersion < "3.1.0") then
				old.ShowTutorials = nil
				old.TutorialFlags = nil
			end

			if (oldVersion < "3.1.2") then
				old.xperlOldroleicons = 1
			end

			if (oldVersion < "3.7.1") then
				old.raid.sortByRole = nil
			end

			if (oldVersion < "3.7.3") then
				old.raid.precisionPercent = 1
				old.raid.precisionManaPercent = 1
			end

			if (oldVersion < "3.7.5") then
				old.targettargettarget.debuffs.enable = old.targettargettarget.buffs.enable
				old.pettarget.debuffs.enable = old.pettarget.buffs.enable
				old.focustarget.debuffs.enable = old.focustarget.buffs.enable
			end

			if (oldVersion < "4.0.1") then
				old.party.enable = 1
			end

			if (oldVersion < "4.0.2") then
				old.raid.sortByRole = nil
				old.raid.gap = TPerl_Raid_GetGap()
			end

			if (oldVersion < "4.0.3") then
				old.raid.size = { }
				old.raid.size.width = 0
			end

			if (oldVersion < "4.0.5") then
				old.player.healprediction = 1
				old.pet.healprediction = 1
				old.target.healprediction = 1
				old.targettarget.healprediction = 1
				old.focus.healprediction = 1
				old.focustarget.healprediction = 1
				old.party.healprediction = 1
				old.raid.healprediction = 1

				old.player.absorbs = 1
				old.pet.absorbs = 1
				old.target.absorbs = 1
				old.targettarget.absorbs = 1
				old.focus.absorbs = 1
				old.focustarget.absorbs = 1
				old.party.absorbs = 1
				old.raid.absorbs = 1

				-- What the hell was this used for?
				old.raidpet.hunter = nil
				old.raidpet.warlock = nil
			end

			if (oldVersion < "4.1.7") then
				if old.bar.fat == true then
					old.bar.fat = 1
				end
			end

			if (oldVersion < "4.3.2") then
				if old.party.name == true then
					old.party.name = 1
				end
			end

			if not old.target.comboindicator then
				old.target.comboindicator = { }
			end

			if (oldVersion < "5.0.4") then
				old.target.comboindicator = { }
				old.target.comboindicator.enable = 1
			end

			if (oldVersion < "5.0.5") then
				old.target.comboindicator = { }
				old.target.comboindicator.enable = 1
			end

			if (oldVersion < "5.0.6") then
				for i = 1, CLASS_COUNT do
					if not old.raid.group[i] then
						old.raid.group[i] = 1
					end
				end
			end

			if (oldVersion < "5.0.8") then
				old.player.lockRunes = 1
			end

			if (oldVersion < "5.1.6") then
				old.raid.inParty = nil
			end

			if (oldVersion < "5.1.7") then
				old.raid.inParty = nil
			end

			if (oldVersion < "5.4.8") then
				if not old.custom.zones then
					return
				end

				old.custom.zones[EJ_GetInstanceInfo(946)] = {[246220] = true, [248819] = true, [248815] = true, [244768] = true, [244071] = true, [244086] = true, [248861] = true, [248326] = true, [247552] = true, [248068] = true, [253600] = true, [249297] = true, [252760] = true, [246687] = true, [243961] = true, [245586] = true, [245995] = true, [251570] = true, [250669] = true, [255199] = true}
				old.custom.zones[EJ_GetInstanceInfo(875)] = {[236449] = true, [235213] = true, [235240] = true, [240209] = true, [235222] = true, [238429] = true}
			end

			if (oldVersion < "5.8.2") then
				old.pet.happiness = { }
				old.pet.happiness.enable = 1
				old.pet.happiness.onlyWhenSad = 1
				old.pet.happiness.flashWhenSad = 1
			end

			if (oldVersion < "5.8.6") then
				if old.custom.zones then
					for k, v in pairs(old.custom.zones) do
						if type(k) ~= "string" then
							old.custom.zones[k] = nil
						end
					end
				end
			end

			if (oldVersion < "6.2.9") then
				if not old.pet.happiness then
					old.pet.happiness = { }
				end
				if not old.pet.happiness.enable and old.pet.happiness.enabled then
					old.pet.happiness.enable = old.pet.happiness.enabled
					old.pet.happiness.enabled = nil
				end
			end

			if (oldVersion < "7.0.0") then
				if IsRetail then
					old.minimap.radius = 101
				else
					old.minimap.radius = 78
				end
			end

			if (oldVersion < "7.0.3") then
				old.colour.bar.hot = { }
				old.colour.bar.hot.r = 1
				old.colour.bar.hot.g = 0.72
				old.colour.bar.hot.b = 0.1
				old.colour.bar.hot.a = 0.7
				old.player.hotPrediction = 1
				old.pet.hotPrediction = 1
				old.target.hotPrediction = 1
				old.targettarget.hotPrediction = 1
				old.focus.hotPrediction = 1
				old.focustarget.hotPrediction = 1
				old.party.hotPrediction = 1
				old.raid.hotPrediction = 1
				old.raid.disableDefault = 1
				old.raid.role = nil
			end
			if (oldVersion < "7.0.7") then
				old.raid.role = nil
				old.raid.disableDefault = nil
			end
		end
	end

	-- TPerl_Options_UpgradeSettings()
	function TPerl_Options_UpgradeSettings()
		local oldVersion = TPerlConfigNew.ConfigVersion

		-- Global config upgrade checks here:
		if (type(oldVersion) == "string" and oldVersion < "2.3.2d") then
			if (TPerlConfigNew.savedPositions and TPerlConfigNew.savedPositions.current) then
				for name,settings in pairs(TPerlConfigNew.savedPositions) do
					if (name ~= "saved" and name ~= "current") then
						if (not TPerlConfigNew.savedPositions.saved) then
							TPerlConfigNew.savedPositions.saved = {}
						end
						TPerlConfigNew.savedPositions.saved[name] = settings
						TPerlConfigNew.savedPositions[name] = nil
					end
				end

				local realm, name = GetRealmName(), UnitName("player")
				if (not TPerlConfigNew.savedPositions[realm]) then
					TPerlConfigNew.savedPositions[realm] = {}
				end
				TPerlConfigNew.savedPositions[realm][name] = TPerlConfigNew.savedPositions.current
				TPerlConfigNew.savedPositions.current = nil
			end
		end

		for realmName, realmList in pairs(TPerlConfigNew) do
			if (type(realmList) == "table" and realmName ~= "global" and realmName ~= "savedPositions") then
				for playerName, settings in pairs(realmList) do
					if (playerName == "global") then
						-- Fix global settings being put in with realms
						if (not TPerlConfigNew.global) then
							TPerlConfigNew.global = settings
							UpgradeSettings(settings, oldVersion)
						end
						realmList.global = nil
					else
						UpgradeSettings(settings, oldVersion)
					end
				end
			else
				if (type(realmList) == "table" and realmName == "global" and realmName ~= "savedPositions") then
					UpgradeSettings(realmList, oldVersion)
				end
			end
		end

		UpgradeSettings = nil
		TPerl_Options_UpgradeSettings = nil
		frameList = nil
	end
end


local function OptChecked(suffix)
    local btn = _G["TPerl_Options_Player_Options_" .. suffix]
    return btn and btn:GetChecked() or false
end


function TPerl_LockRunes_OnConfigClick(self)
	local checked = OptChecked("LockRunes")

 if TPerlSpecialPowerBarFrame then
  TPerlSpecialPowerBarFrame:EnableMouse(not checked)
	end
	if TPerlSpecialPowerBarFrame2 then
	 TPerlSpecialPowerBarFrame2:EnableMouse(not checked)
	end
	
	
--Old Code
--[[
	-- Apply click-through state to MovableHarmonyBar
	if MovableHarmonyBar then
		MovableHarmonyBar:EnableMouse(not checked)
	end
	if MovableStaggerBar then
		MovableStaggerBar:EnableMouse(not checked)
	end
	if MovableHolyPowerBar then
		MovableHolyPowerBar:EnableMouse(not checked)
	end
	if MovableRuneFrame then
		MovableRuneFrame:EnableMouse(not checked)
	end
	if MovableSoulShardBar then
		MovableSoulShardBar:EnableMouse(not checked)
	end
	if MovableArcaneChargesBar then
		MovableArcaneChargesBar:EnableMouse(not checked)
	end
	if MovableEssenceBar then
		MovableEssenceBar:EnableMouse(not checked)
	end
	if MovableShadowOrbBar then
		MovableShadowOrbBar:EnableMouse(not checked)
	end
	if MovableBalanceBar then
		MovableBalanceBar:EnableMouse(not checked)
	end
	if MovableComboPointBarFrame then
		MovableComboPointBarFrame:EnableMouse(not checked)
	end
	]]--

	-- Preserve old reset behavior
	if TPerl_Player_Reset then
		TPerl_Player_Reset(self)
	end
end

function TPerl_ShowRunes_OnClick(self)
	local checked = OptChecked("ShowRunes")
	
	if checked == false then
		TPerlSpecialPowerBarFrame:Hide()
		if TPerlSpecialPowerBarFrame2 then
		 TPerlSpecialPowerBarFrame2:Hide()
		end
	else
	 TPerlSpecialPowerBarFrame:Show()
		if TPerlSpecialPowerBarFrame2 then
		 TPerlSpecialPowerBarFrame2:Show()
		end
	end
	
	--Old Code
	--[[
	-- Hide Monk Bars
	if MovableHarmonyBar and checked == false then
	 MovableHarmonyBar:Hide()
	elseif MovableHarmonyBar and checked then
	 MovableHarmonyBar:Show()
	end
	if MovableStaggerBar and checked == false then
	 MovableStaggerBar:Hide()
	elseif MovableStaggerBar and checked then
	 MovableStaggerBar:Show()
	end

	-- Hide Paladin Bars
	if MovableHolyPowerBar and checked == false then
	 MovableHolyPowerBar:Hide()
	elseif MovableHolyPowerBar and checked then
	 MovableHolyPowerBar:Show()
	end
	
	-- Hide DK Bars
	if MovableRuneFrame and checked == false then
	 MovableRuneFrame:Hide()
	elseif MovableRuneFrame and checked then
	 MovableRuneFrame:Show()
	end
	
	-- Hide Warlock Bars
	if MovableSoulShardBar and checked == false then
	 MovableSoulShardBar:Hide()
	elseif MovableSoulShardBar and checked then
	 MovableSoulShardBar:Show()
	end
	
	-- Hide Mage Bars
	if MovableArcaneChargesBar and checked == false then
	 MovableArcaneChargesBar:Hide()
	elseif MovableArcaneChargesBar and checked then
	 MovableArcaneChargesBar:Show()
	end
	
	-- Hide Evoker Bars
	if MovableEssenceBar and checked == false then
	 MovableEssenceBar:Hide()
	elseif MovableEssenceBar and checked then
	 MovableEssenceBar:Show()
	end
	
	-- Hide Priest Bars
	if MovableShadowOrbBar and checked == false then
	 MovableShadowOrbBar:Hide()
		PriestBarFrame:Show()
	elseif MovableShadowOrbBar and checked then
	 MovableShadowOrbBar:Show()
		PriestBarFrame:Hide()
	end
	
	-- Hide Druid Bar
	if MovableBalanceBar and checked == false then
	 MovableBalanceBar:Hide()
	elseif MovableBalanceBar and checked then
	 MovableBalanceBar:Show()
	end
	
	-- Hide Druid Combo Point Bar (Retail)
	if MovableComboPointBarFrame and checked == false then
	 MovableComboPointBarFrame:Hide()
	elseif MovableComboPointBarFrame and checked then
	 MovableComboPointBarFrame:Show()
	end
	
	]]--
	
	if TPerl_Player_Reset then
		TPerl_Player_Reset(self)
	end
end


function TPerl_DockRunes_OnClick(self)
    local checked = OptChecked("DockRunes")

			local xOff, yOff = TPerl_NeedsOffset()

    if TPerlSpecialPowerBarFrame then
        TPerlSpecialPowerBarFrame:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
            if TPerl_Player then
																if IsRetail then
																	TPerlSpecialPowerBarFrame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0 + xOff, 0 + yOff)
																elseif IsMistsClassic then
																 -- This bar is taller and needs up further.
																 TPerlSpecialPowerBarFrame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0 + xOff, 0 + yOff)
																end
            else
                TPerlSpecialPowerBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
            end
            TPerlSpecialPowerBarFrame:EnableMouse(false)
            TPerlSpecialPowerBarFrame:Show()
        else
            -- Restore movable saved position
            if TPerlSpecialPowerBarFramePos and TPerlSpecialPowerBarFramePos.point then
                TPerlSpecialPowerBarFrame:SetPoint(
                    TPerlSpecialPowerBarFramePos.point,
                    UIParent,
                    TPerlSpecialPowerBarFramePos.relativePoint,
                    TPerlSpecialPowerBarFramePos.x,
                    TPerlSpecialPowerBarFramePos.y
                )
            else
                TPerlSpecialPowerBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                TPerlSpecialPowerBarFramePos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            TPerlSpecialPowerBarFrame:EnableMouse(true)
            TPerlSpecialPowerBarFrame:Show()
        end
    end


    --Old code
				--[[
    if MovableHarmonyBar then
        MovableHarmonyBar:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
            if TPerl_Player then
																if IsRetail then
																	MovableHarmonyBar:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
																elseif IsMistsClassic then
																 -- This bar is taller and needs up further.
																 MovableHarmonyBar:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 10)
																end
            else
                MovableHarmonyBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
            end
            MovableHarmonyBar:EnableMouse(false)
            MovableHarmonyBar:Show()
        else
            -- Restore movable saved position
            if MovableHarmonyBarPos and MovableHarmonyBarPos.point then
                MovableHarmonyBar:SetPoint(
                    MovableHarmonyBarPos.point,
                    UIParent,
                    MovableHarmonyBarPos.relativePoint,
                    MovableHarmonyBarPos.x,
                    MovableHarmonyBarPos.y
                )
            else
                MovableHarmonyBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableHarmonyBarPos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableHarmonyBar:EnableMouse(true)
            MovableHarmonyBar:Show()
        end
    end
				
				if MovableStaggerBarPos then
        MovableStaggerBarPos:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
            if TPerl_Player then
																if IsRetail then
																	MovableStaggerBarPos:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 0)
																elseif IsMistsClassic then
																 -- This bar is taller and needs up further.
																 MovableStaggerBarPos:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 10)
																end
            else
                MovableStaggerBarPos:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
            end
            MovableStaggerBarPos:EnableMouse(false)
            MovableStaggerBarPos:Show()
        else
            -- Restore movable saved position
            if MovableStaggerBarPosPos and MovableStaggerBarPosPos.point then
                MovableStaggerBarPos:SetPoint(
                    MovableStaggerBarPosPos.point,
                    UIParent,
                    MovableStaggerBarPosPos.relativePoint,
                    MovableStaggerBarPosPos.x,
                    MovableStaggerBarPosPos.y
                )
            else
                MovableStaggerBarPos:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableStaggerBarPosPos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableStaggerBarPos:EnableMouse(true)
            MovableStaggerBarPos:Show()
        end
    end
				
				if MovableHolyPowerBar then
        MovableHolyPowerBar:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
												MovableHolyPowerBar:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 10)
            MovableHolyPowerBar:EnableMouse(false)
            MovableHolyPowerBar:Show()
        else
            -- Restore movable saved position
            if MovableHolyPowerBarPos and MovableHolyPowerBarPos.point then
                MovableHolyPowerBar:SetPoint(
                    MovableHolyPowerBarPos.point,
                    UIParent,
                    MovableHolyPowerBarPos.relativePoint,
                    MovableHolyPowerBarPos.x,
                    MovableHolyPowerBarPos.y
                )
            else
                MovableHolyPowerBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableHolyPowerBarPos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableHolyPowerBar:EnableMouse(true)
            MovableHolyPowerBar:Show()
        end
    end

				if MovableRuneFrame then
        MovableRuneFrame:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
												MovableRuneFrame:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 10)
            MovableRuneFrame:EnableMouse(false)
            MovableRuneFrame:Show()
        else
            -- Restore movable saved position
            if MovableRuneFramePos and MovableRuneFramePos.point then
                MovableRuneFrame:SetPoint(
                    MovableRuneFramePos.point,
                    UIParent,
                    MovableRuneFramePos.relativePoint,
                    MovableRuneFramePos.x,
                    MovableRuneFramePos.y
                )
            else
                MovableRuneFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableRuneFramePos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableRuneFrame:EnableMouse(true)
            MovableRuneFrame:Show()
        end
    end

    if MovableSoulShardBar then
        MovableSoulShardBar:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
												MovableSoulShardBar:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 10)
            MovableSoulShardBar:EnableMouse(false)
            MovableSoulShardBar:Show()
        else
            -- Restore movable saved position
            if MovableSoulShardBarPos and MovableSoulShardBarPos.point then
                MovableSoulShardBar:SetPoint(
                    MovableSoulShardBarPos.point,
                    UIParent,
                    MovableSoulShardBarPos.relativePoint,
                    MovableSoulShardBarPos.x,
                    MovableSoulShardBarPos.y
                )
            else
                MovableSoulShardBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableSoulShardBarPos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableSoulShardBar:EnableMouse(true)
            MovableSoulShardBar:Show()
        end
    end
 				
				if MovableArcaneChargesBar then
        MovableArcaneChargesBar:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
												MovableArcaneChargesBar:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 5)
            MovableArcaneChargesBar:EnableMouse(false)
            MovableArcaneChargesBar:Show()
        else
            -- Restore movable saved position
            if MovableArcaneChargesBarPos and MovableArcaneChargesBarPos.point then
                MovableArcaneChargesBar:SetPoint(
                    MovableArcaneChargesBarPos.point,
                    UIParent,
                    MovableArcaneChargesBarPos.relativePoint,
                    MovableArcaneChargesBarPos.x,
                    MovableArcaneChargesBarPos.y
                )
            else
                MovableArcaneChargesBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableArcaneChargesBarPos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableArcaneChargesBar:EnableMouse(true)
            MovableArcaneChargesBar:Show()
        end
    end
				
				if MovableEssenceBar then
        MovableEssenceBar:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
												MovableEssenceBar:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 5)
            MovableEssenceBar:EnableMouse(false)
            MovableEssenceBar:Show()
        else
            -- Restore movable saved position
            if MovableEssenceBarPos and MovableEssenceBarPos.point then
                MovableEssenceBar:SetPoint(
                    MovableEssenceBarPos.point,
                    UIParent,
                    MovableEssenceBarPos.relativePoint,
                    MovableEssenceBarPos.x,
                    MovableEssenceBarPos.y
                )
            else
                MovableEssenceBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableEssenceBarPos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableEssenceBar:EnableMouse(true)
            MovableEssenceBar:Show()
        end
    end
				
				if MovableShadowOrbBar then
        MovableShadowOrbBar:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
												MovableShadowOrbBar:SetPoint("TOP", TPerl_Player, "BOTTOM", 0, 5)
            MovableShadowOrbBar:EnableMouse(false)
            MovableShadowOrbBar:Show()
        else
            -- Restore movable saved position
            if MovableShadowOrbBarPos and MovableShadowOrbBarPos.point then
                MovableShadowOrbBar:SetPoint(
                    MovableShadowOrbBarPos.point,
                    UIParent,
                    MovableShadowOrbBarPos.relativePoint,
                    MovableShadowOrbBarPos.x,
                    MovableShadowOrbBarPos.y
                )
            else
                MovableShadowOrbBar:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableShadowOrbBarPos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableShadowOrbBar:EnableMouse(true)
            MovableShadowOrbBar:Show()
        end
    end
				
				if MovableComboPointBarFrame then
        MovableComboPointBarFrame:ClearAllPoints()

        if checked then
            -- Dock to TPerl_Player and disable dragging
												MovableComboPointBarFrame:SetPoint("TOP", TPerl_Player, "BOTTOM", 20, 0)
            MovableComboPointBarFrame:EnableMouse(false)
            MovableComboPointBarFrame:Show()
        else
            -- Restore movable saved position
            if MovableComboPointBarFramePos and MovableComboPointBarFramePos.point then
                MovableComboPointBarFrame:SetPoint(
                    MovableComboPointBarFramePos.point,
                    UIParent,
                    MovableComboPointBarFramePos.relativePoint,
                    MovableComboPointBarFramePos.x,
                    MovableComboPointBarFramePos.y
                )
            else
                MovableComboPointBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
                MovableComboPointBarFramePos = {
                    point = "CENTER", relativePoint = "CENTER",
                    x = 0, y = -100,
                }
            end
            MovableComboPointBarFrame:EnableMouse(true)
            MovableComboPointBarFrame:Show()
        end
    end
				]]--
				
    if TPerl_Player_Reset then
        TPerl_Player_Reset(self)
    end
end


function TPerl_PlayerScaleChanged()
    local scale = TPerlDB.player and TPerlDB.player.scale or 1

    -- Saving this block in case its actually needed.

    -- Preserve old reset behavior if defined
    if TPerl_Player_Reset then
        TPerl_Player_Reset()
    end
end


function TPerl_ToggleDemonicFuryText(self)
    local checked = self:GetChecked() and true or false

    TPerlDB.player.SpecialPowerBars.showDemonicFuryText = checked

    -- Update the Demonic Fury bar if it exists
    if DemonicFuryBarFrame and DemonicFuryBarFrame.powerText then
        if checked then
            DemonicFuryBarFrame.powerText:Show()
            DemonicFuryBarFrame.showText = true
            DemonicFuryBarFrame.lockShow = 1
        else
            DemonicFuryBarFrame.powerText:Hide()
            DemonicFuryBarFrame.showText = false
            DemonicFuryBarFrame.lockShow = 0
        end
    end
end

function TPerl_NeedsOffset()
	local _, playerClass = UnitClass("player")
	local playerSpec = TPerl_GetSpec()
	
	--Offsets if on Mists Classic.
	if IsMistsClassic then
	
	 --Paladin has special needs.
		if playerClass == "PALADIN" then
			--Offset for Paladin is:
			return 0, 15
		end
		
		if playerClass == "MAGE" then
			--Offset for Mage is:
			return 0, 15
		end
		
		if playerClass == "PRIEST" then
			--Offset for Priest is:
			return 15, 10
		end
		
		--Warlock has special needs based on spec.
		if playerClass == "WARLOCK" then
			if playerSpec == 2 then
				--Offset for Demo Warlock is:
				return -60, 10
			end
		end
		
	end
	
	--Offsets for if on Retail.
	if IsRetail then
	
	 if playerClass == "DEATHKNIGHT" then
		 return 0, 10
		end
		
	end
	
	--Dont need a special offset so return nothing:
	return 0, 0
end


function TPerl_GetSpec()
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