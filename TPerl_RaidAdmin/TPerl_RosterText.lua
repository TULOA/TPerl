-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

TPerl_SetModuleRevision("$Revision:  $")

-- onEvent
local function onEvent(self, event, a, b, c)
	self[event](self, a, b, c)
end

local function SortName(a, b)
	return a.name < b.name
end

local function SortNameGroup(a, b)
	return a.group..a.name < b.group..b.name
end

-- doUpdate
local function Update(self)
	local myZone = GetRealZoneText()
	local list = {}

	for unitid, unitName, unitClass, group, zone, online, dead in TPerl_NextMember do
		if (self.group[group]) then
			if (not self.sameZone or (zone == myZone)) then
				tinsert(list, {["group"] = group, name = unitName})
			end
		end
	end

	if (self.sortAlpha) then
		sort(list, SortName)
	else
		sort(list, SortNameGroup)
	end

	local text = ""
	local totals = 0
	for k,v in pairs(list) do
		text = text..v.name.."\r"
		totals = totals + 1
	end

	self.text = text
	self.textFrame.scroll.text:SetText(text)
	self.textFrame.scroll.text:HighlightText()
	--if (self.textFrame.scroll.text.SetCursorPosition) then
	--	self.textFrame.scroll.text:SetCursorPosition(1)			-- WoW 2.3
	--end
	self.textFrame.scroll.text:SetFocus()

	self.totals:SetFormattedText(TPERL_ROSTERTEXT_TOTAL, totals)
end

-- TPerl_RosterText_Init
function TPerl_RosterText_Init(self)

	TPerl_SetChildMembers(self)

	self:OnBackdropLoaded()
	self:SetBackdropColor(0, 0, 0, 0.7)
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	self:RegisterForDrag("LeftButton")

	if (TPerl_SavePosition) then
		TPerl_SavePosition(TPerl_RosterTextAnchor, true)
	end

	TPerl_RegisterScalableFrame(self, TPerl_RosterTextAnchor)

	self.group = {1, 1, 1, 1, 1, nil, nil, nil}
	self.sameZone = nil

	self:SetScript("OnEvent", onEvent)
	self.Update = Update

	self.GROUP_ROSTER_UPDATE = Update
	self.PLAYER_ENTERING_WORLD = Update

	self:SetScript("OnShow", function(self)
		self:RegisterEvent("GROUP_ROSTER_UPDATE")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		Update(self)
	end)
	self:SetScript("OnHide", function(self)
		TPerl_RosterText.text = nil
		self.textFrame.scroll.text:SetText("")
		self:UnregisterAllEvents()
	end)

	self:SetScript("OnLoad", nil)
	TPerl_RosterText_Init = nil
end
