-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local AddonName, Addon = ...

TPerl_SetModuleRevision("$Revision:  $")

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local SavedRoster = nil
local XswapCount = 0
local XmoveCount = 0
local XPendingRosters = 0
local WaitingForRoster

-- AdminCommands
local function AdminCommands(msg)
	local args = {}
	for value in string.gmatch(msg, "[^ ]+") do
		tinsert(args, string.lower(value))
	end

	if (not args[1]) then
			TPerl_AdminFrame:Show()
	else
		if (not TPerl_AdminCommands[args[1]] or not TPerl_AdminCommands[args[1]](args[2], args[3], args[4])) then
			TPerl_AdminCommands.help()
		end
	end
end

-- DefaultVar
local function DefaultVar(name, value)
	if (TPerl_Admin[name] == nil or (type(value) ~= type(TPerl_Admin[name]))) then
		TPerl_Admin[name] = value
	end
end

-- Defaults
local function Defaults()

	if (not TPerl_Admin) then
		TPerl_Admin = {}
	end

	DefaultVar("AutoHideShow",	1)
	DefaultVar("SavedRosters",	{})
	DefaultVar("Transparency",	0.8)

	TPerl_Admin.Scale_ItemCheck = nil
	TPerl_Admin.Scale_Admin = nil
end

-- TPerl_AdminOnLoad
function TPerl_AdminOnLoad(self)
	self:RegisterForDrag("LeftButton")

	TPerl_Admin = { }

	SlashCmdList["TPERLRAIDADMIN"] = AdminCommands
	SLASH_TPERLRAIDADMIN1 = "/rad"
	SLASH_TPERLRAIDADMIN2 = "/xpadmin"
	SLASH_TPERLRAIDADMIN3 = "/xpad"

	--self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	self:OnBackdropLoaded()
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	if IsRetail then
		TPerl_AdminFrame_TitleBar_CloseButton:SetScale(0.66)
		TPerl_AdminFrame_TitleBar_CloseButton:SetPoint("TOPRIGHT", 2, 2)
		TPerl_AdminFrame_TitleBar_Pin:SetPoint("RIGHT", TPerl_AdminFrame_TitleBar_CloseButton, "LEFT", 0, 0)
		TPerl_AdminFrame_TitleBar_LockOpen:SetPoint("RIGHT", TPerl_AdminFrame_TitleBar_Pin, "LEFT", 0, 0)
	end

	self.Expand = function()
		TPerl_AdminFrame_Controls:Show()
		TPerl_AdminFrame_TitleBar_LockOpen:Show()
		self:SetWidth(140)
		self:SetHeight(150)
	end

	self.Collapse = function()
		TPerl_AdminFrame_Controls:Hide()
		TPerl_AdminFrame_TitleBar_LockOpen:Hide()
		self:SetWidth(140)
		self:SetHeight(18)
	end
	self:SetScript("OnEvent", TPerl_AdminOnEvent)

	TPerl_AdminOnLoad = nil
end

-- TPerl_AdminStartup
local function TPerl_AdminStartup(self)
	Defaults()
	TPerl_AdminFrame_TitleBar_Pin:SetButtonTex()

	TPerl_Check_Setup()
	TPerl_AdminSetupFrames()

	if (TPerl_SavePosition) then
		TPerl_SavePosition(TPerl_AdminFrameAnchor, true)
	end

	TPerl_RegisterScalableFrame(self, TPerl_AdminFrameAnchor)
	self.corner:SetParent(TPerl_AdminFrame_Controls)

	self:SetWidth(140)
	self:SetHeight(18)

	TPerl_AdminStartup = nil
end

-- TPerl_SetupFrameSimple
function TPerl_SetupFrameSimple(self, alpha)
	self:OnBackdropLoaded()
	self:SetBackdropColor(0, 0, 0, alpha or 1)
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, alpha or 1)
end

-- TPerl_AdminSetupFrames()
function TPerl_AdminSetupFrames()
	TPerl_SetupFrameSimple(TPerl_Check)
	TPerl_SetupFrameSimple(TPerl_CheckListItems)
	TPerl_SetupFrameSimple(TPerl_CheckListPlayers)

	TPerl_SetupFrameSimple(TPerl_AdminFrame)

	TPerl_Check:SetAlpha(TPerl_Admin.Transparency)
	TPerl_AdminFrame:SetAlpha(TPerl_Admin.Transparency)

	TPerl_AdminSetupFrames = nil
end

-- TPerl_Help
local function TPerl_Help()
	TPerl_Message("/rad [save | load name] [auto]")
end

-- TPerl_AdminCheckMyRank
function TPerl_AdminCheckMyRank()
	if (TPerl_Admin.AutoHideShow == 1) then
		if (IsInRaid()) then
			local me = UnitName("player")
			for i = 1,GetNumGroupMembers() do
				local name, rank = GetRaidRosterInfo(i)
				if (name == me) then
					if (rank > 0) then
						TPerl_AdminFrame:Show()
					else
						TPerl_AdminFrame:Hide()
					end
					break
				end
			end
		else
			TPerl_AdminFrame:Hide()
		end
	end
end

-- TPerl_ToggleAuto
local function TPerl_ToggleAuto()
	if (TPerl_Admin.AutoHideShow == 1) then
		TPerl_Admin.AutoHideShow = 0
	else
		TPerl_Admin.AutoHideShow = 1
	end
	TPerl_AdminCheckMyRank()
end

-- TPerl_SaveRoster
function TPerl_SaveRoster(saveName)

	if (not saveName or saveName == "") then
		local hours, mins = GetGameTime()
		saveName = hours..":"..mins
	end

	local Roster = {}

	for i = 1,GetNumGroupMembers() do
		local name, _, subgroup, _, _, fileName = GetRaidRosterInfo(i)
		Roster[name] = {group = subgroup, class = fileName}
	end

	if (not TPerl_Admin.SavedRosters) then
		TPerl_Admin.SavedRosters = {}
	end
	TPerl_Admin.SavedRosters[saveName] = Roster

	TPerl_Message(format(TPERL_SAVED_ROSTER, saveName))

	return true
end

local function LoadRoster()
	local swapCount = 0
	local moveCount = 0
	local CurrentRoster = {}
	local CurrentGroups = {}
	local FreeFloating = {}

	-- Store the current raid roster, and a list of players in the raid, but not in the saved roster
	for i = 1,GetNumGroupMembers() do
		local name, _, subgroup, _, _, fileName = GetRaidRosterInfo(i)
		CurrentRoster[name] = {index = i, group = subgroup, class = fileName}

		if (not SavedRoster[name]) then
			-- Not in the saved roster, so doesn't matter where
			FreeFloating[name] = {group = subgroup, class = fileName}
		end
	end

	local function Swap(a, b)
	if (CurrentRoster[a] and CurrentRoster[b]) then
		SwapRaidSubgroup(CurrentRoster[a].index, CurrentRoster[b].index)
		local save = CurrentRoster[b].group
		CurrentRoster[b].group = CurrentRoster[a].group
		CurrentRoster[b].moved = true
		CurrentRoster[a].group = save
		CurrentRoster[a].moved = true

		if (FreeFloating[a]) then
			FreeFloating[a].group = CurrentRoster[a].group
		end
		if (FreeFloating[b]) then
			FreeFloating[b].group = CurrentRoster[b].group
		end

		swapCount = swapCount + 1
	end
	end

	local function Move(name, target)
		SetRaidSubgroup(CurrentRoster[name].index, target)
		CurrentRoster[name].group = target
		CurrentRoster[name].moved = true
		if (FreeFloating[name]) then
			FreeFloating[name].group = target
		end

		moveCount = moveCount + 1
	end

	local function GroupCount(grp)
		local count = 0
		for name,entry in pairs(CurrentRoster) do
			if (entry.group == grp) then
				count = count + 1
			end
		end
		return count
	end

	for nameSaved, saved in pairs(SavedRoster) do
	local name = nameSaved
	local group = saved.group

		if (not CurrentRoster[name]) then
		-- Saved player not in raid, so find someone of the same class in the free floater list
		for floaterName,floater in pairs(FreeFloating) do
			if (floater.class == saved.class) then
				name = floaterName
				FreeFloating[name] = nil
				break
			end
		end
	end

		if (CurrentRoster[name] and not CurrentRoster[name].moved) then
			if (CurrentRoster[name].group == group) then
				CurrentRoster[name].moved = true -- They're in right group already
			elseif (not FreeFloating[name]) then
			-- First see if we can directly swap any 2 players
				local swapName
				for name2, saved2 in pairs(SavedRoster) do
					if (name ~= name2) then
						if (CurrentRoster[name] and CurrentRoster[name].group == saved2.group) then
							if (CurrentRoster[name2] and CurrentRoster[name2].group == group) then
								swapName = name2
								break
							end
						end

					end
				end

				if (swapName) then
					Swap(name, swapName)
				--break
				else
				local done
					-- Nothing suitable found to swap, see if target group has space
					if (GroupCount(group) < 5) then
						Move(name, group)
					done = true
						--break
					end

					-- No space in target group, put them anywhere
					if (not done) then
						for i = 1,8 do
							if (CurrentRoster[name].group ~= i and GroupCount(i) < 5) then
								Move(name, i)
							done = true
								break
							end
						end
					end

					if (not done) then
					-- Nothing done yet, see if we can swap a free floater
					local free
					for name2, group in pairs(FreeFloating) do
						if (group ~= CurrentRoster[name2].group) then
							free = name2
							break
						end
					end
						if (free) then
							Swap(CurrentRoster[name].index, CurrentRoster[free].index)
						--break
						else
						-- Couldn't put them anywhere, add them to floater list
							FreeFloating[name] = group
						end
				--else
				--	break
					end
				end
			end
		end

		--if (moveCount > 0) then		-- or swapCount > 0) then
		--	break
		--end
		end

	if (moveCount == 0 and swapCount == 0) then
		--ChatFrame7:AddMessage("Finished!")
		TPerl_StopLoad()
	else
		WaitingForRoster = GetTime()
		XswapCount = XswapCount + swapCount
		XmoveCount = XmoveCount + moveCount
		XPendingRosters = XPendingRosters + swapCount
		XPendingRosters = XPendingRosters + moveCount
	end
	--ChatFrame7:AddMessage("Done arranging (swaps: "..swapCount..")  (moves: "..moveCount..")")
end

-- TPerl_AdminOnEvent
function TPerl_AdminOnEvent(self, event, ...)
	TPerl_AdminCheckMyRank()

	if (event == "GROUP_ROSTER_UPDATE") then
		TPerl_AdminFrame_Controls:Details()

		if (WaitingForRoster) then
			if (not XFinishedLoad) then
				XPendingRosters = XPendingRosters - 1
				if (XPendingRosters < 1) then
					LoadRoster()
				end
			end
		end

	elseif (event == "ADDON_LOADED") then
		local addon = ...

		if addon == AddonName then
			TPerl_AdminStartup(self)

			self:UnregisterEvent(event)
		end
	end
end

-- TPerl_Admin_OnUpdate
function TPerl_Admin_OnUpdate(self, elapsed)
	if (WaitingForRoster) then
		if (GetTime() > WaitingForRoster + 5000) then
			TPerl_StopLoad()
		end
	end
end

-- TPerl_LoadRoster
function TPerl_LoadRoster(loadName)
	if (not TPerl_Admin.SavedRosters) then
		return
	end

	SavedRoster = TPerl_Admin.SavedRosters[loadName]
	if (SavedRoster) then
		TPerl_AdminFrame_Controls_StopLoad:Show()
		TPerl_AdminFrame_Controls_LoadRoster:Hide()

		XFinishedLoad = false
		WaitingForRoster = nil
		XPendingRosters = 0
		LoadRoster()
	else
		if (not loadName) then
			TPerl_Message(TPERL_NO_ROSTER_NAME_GIVEN)
		else
			TPerl_Message(format(TPERL_NO_ROSTER_CALLED, loadName))
		end
	end

	return true
end

-- TPerl_StopLoad
function TPerl_StopLoad()
	TPerl_AdminFrame_Controls_StopLoad:Hide()
	TPerl_AdminFrame_Controls_LoadRoster:Show()

	XFinishedLoad = true
	WaitingForRoster = nil
	SavedRoster = nil
	XPendingRosters = 0

	TPerl_AdminFrame_Controls:Details()
end

function TPerl_Message(...)
	DEFAULT_CHAT_FRAME:AddMessage(TPERL_MSG_PREFIX.."- "..format(...))
end

TPerl_AdminCommands = {
	save = TPerl_SaveRoster,
	load = TPerl_LoadRoster,
	auto = TPerl_ToggleAuto,
	help = TPerl_Help
}

-- TPerl_Admin_CountDifferences
function TPerl_Admin_CountDifferences(rosterName)
	if (not TPerl_Admin.SavedRosters) then
		return
	end

	local count = 0

	SavedRoster = TPerl_Admin.SavedRosters[rosterName]
	if (SavedRoster) then
		for i = 1,GetNumGroupMembers() do
			local name, _, subgroup = GetRaidRosterInfo(i)
			if (SavedRoster[name]) then
				if (SavedRoster[name].group ~= subgroup) then
					count = count + 1
				end
			else
				count = count + 1
			end
		end

		return count
	end
end

function TPerl_Admin_ControlsOnLoad(self)
	self.Details = function(self)
		local name = TPerl_AdminFrame_Controls_Edit:GetText()
		local diff
		if (name) then
			diff = TPerl_Admin_CountDifferences(name)
		end

		if (diff) then
			TPerl_AdminFrame_Controls_DetailsText:SetFormattedText(TPERL_ADMIN_DIFFERENCES, diff)
			TPerl_AdminFrame_Controls_Details:Show()
		else
			TPerl_AdminFrame_Controls_Details:Hide()
		end
	end

	self.MakeList = function(self)
		local index = 1
		local line = 1
		local find = TPerl_AdminFrame_Controls_Edit:GetText()

		local Offset = TPerl_AdminFrame_Controls_RosterScrollBarScrollBar:GetValue() + 1
		for name,roster in pairs(TPerl_Admin.SavedRosters) do
			if (index >= Offset) then
				local f = _G["TPerl_AdminFrame_Controls_Roster"..line]
				if (f) then
					if (name == find) then
						f:LockHighlight()
					else
						f:UnlockHighlight()
					end
					f:SetText(name)
					f:Show()
				end
				line = line + 1
			end
			index = index + 1
		end
		for i = line,5 do
			local f = _G["TPerl_AdminFrame_Controls_Roster"..i]
			if (f) then
				f:SetText("")
				f:UnlockHighlight()
				f:Hide()
			end
		end

		local offset = TPerl_AdminFrame_Controls_RosterScrollBarScrollBar:GetValue()
		if (FauxScrollFrame_Update(TPerl_AdminFrame_Controls_RosterScrollBar, index - 1, 5, 1)) then
			TPerl_AdminFrame_Controls_RosterScrollBar:Show()
		else
			TPerl_AdminFrame_Controls_RosterScrollBar:Hide()
		end

		TPerl_AdminFrame_Controls:Details()
	end

	self.Validate = function(self)
		TPerl_AdminFrame.Valid = false
		TPerl_AdminFrame_Controls_LoadRoster:Disable()
		TPerl_AdminFrame_Controls_DeleteRoster:Disable()

		local index = 1
		local line = 1
		local find = TPerl_AdminFrame_Controls_Edit:GetText()
		local Offset = TPerl_AdminFrame_Controls_RosterScrollBarScrollBar:GetValue()
			for name,roster in pairs(TPerl_Admin.SavedRosters) do
				if (index - 1 >= Offset) then
					local f = _G["TPerl_AdminFrame_Controls_Roster"..line]
					if (not f) then
						break
					end
					if (name == find) then
						f:LockHighlight()
						TPerl_AdminFrame.Valid = true
						if (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
							TPerl_AdminFrame_Controls_LoadRoster:Enable()
						end
						TPerl_AdminFrame_Controls_DeleteRoster:Enable()
					else
						f:UnlockHighlight()
					end
				line = line + 1
			end
		   index = index + 1
		end
	end
end
