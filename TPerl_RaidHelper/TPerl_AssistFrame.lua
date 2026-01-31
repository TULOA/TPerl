-- TPerl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local conf
TPerl_RequestConfig(function(new)
	conf = new
end, "$Revision:  $")

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local myClass
local playerAggro, petAggro
local doUpdate					-- In cases where we get multiple UNIT_TARGET events in 1 frame, we just set a flag and do during OnUpdate
local friendlyUnitList = {"player", "pet"}
local enemyUnitList = {}			-- Players with mobs targetted that target me
local wholeEnemyUnitList = { }			-- Players with mobs targetted
local currentPlayerAggro = { }

local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers

-- TPerl_Assists_OnLoad(self)
function TPerl_Assists_OnLoad(self)
	if self.SetResizeBounds then
		self:SetResizeBounds(170, 40, 1000, 600)
	else
		self:SetMinResize(170, 40)
		self:SetMaxResize(1000, 600)
	end

	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:SetScript("OnEvent", TPerl_Assists_OnEvent)
	self:SetScript("OnMouseDown", TPerl_Assists_MouseDown)
	self:SetScript("OnMouseUp", TPerl_Assists_MouseUp)

	TPerl_Assists_OnLoad = nil
end

-- TPerl_SetFrameSides
function TPerl_SetFrameSides()
	if (TPerl_Assists_Frame.LastSetView and TPerl_Assists_Frame.LastSetView[1] == TPerlConfigHelper.AssistsFrame and TPerl_Assists_Frame.LastSetView[2] == TPerlConfigHelper.TargettingFrame) then
		-- Frames the same from last time
		return
	end

	if (TPerlConfigHelper.AssistsFrame == 1 or TPerlConfigHelper.TargettingFrame == 1) then
		TPerl_Assists_Frame:Show()

		TPerl_Target_Targetting_ScrollFrame:ClearAllPoints()
		TPerl_Target_Assists_ScrollFrame:ClearAllPoints()

		if (TPerlConfigHelper.AssistsFrame == 1 and TPerlConfigHelper.TargettingFrame == 1) then
			TPerl_Target_Targetting_ScrollFrame:SetPoint("TOPLEFT", 4, -5)
			TPerl_Target_Targetting_ScrollFrame:SetPoint("BOTTOMRIGHT", TPerl_Assists_Frame, "BOTTOM", -0.5, 5)
			TPerl_Target_Targetting_ScrollFrame:Show()

			TPerl_Target_Assists_ScrollFrame:SetPoint("TOPLEFT", TPerl_Assists_Frame, "TOP", 0.5, -5)
			TPerl_Target_Assists_ScrollFrame:SetPoint("BOTTOMRIGHT", -4, 5)
			TPerl_Target_Assists_ScrollFrame:Show()

			TPerlScrollSeperator:Show()
			TPerlScrollSeperator:ClearAllPoints()
			TPerlScrollSeperator:SetPoint("TOPLEFT", TPerl_Target_Targetting_ScrollFrame, "TOPRIGHT", 0, 0)
			TPerlScrollSeperator:SetPoint("BOTTOMRIGHT", TPerl_Target_Assists_ScrollFrame, "BOTTOMLEFT", 0, 0)
		else
			TPerlScrollSeperator:Hide()

			if (TPerlConfigHelper.AssistsFrame == 1) then
				TPerl_Target_Assists_ScrollFrame:SetPoint("TOPLEFT", 4, -5)
				TPerl_Target_Assists_ScrollFrame:SetPoint("BOTTOMRIGHT", -4, 5)
				TPerl_Target_Assists_ScrollFrame:Show()
				TPerl_Target_Targetting_ScrollFrame:Hide()
			else
				TPerl_Target_Targetting_ScrollFrame:SetPoint("TOPLEFT", 4, -5)
				TPerl_Target_Targetting_ScrollFrame:SetPoint("BOTTOMRIGHT", -4, 5)
				TPerl_Target_Targetting_ScrollFrame:Show()
				TPerl_Target_Assists_ScrollFrame:Hide()
			end
		end
	else
		TPerl_Assists_Frame:Hide()
	end

	TPerl_Assists_Frame.LastSetView = {TPerlConfigHelper.AssistsFrame, TPerlConfigHelper.TargettingFrame}
end

-- ToggleAssistsFrame()
function TPerl_ToggleAssistsFrame(param)
	if (param == "assists") then
		if (TPerlConfigHelper.AssistsFrame == 1) then
			TPerlConfigHelper.AssistsFrame = 0
		else
			TPerlConfigHelper.AssistsFrame = 1
		end
	else
		if (TPerlConfigHelper.TargettingFrame == 1) then
			TPerlConfigHelper.TargettingFrame = 0
		else
			TPerlConfigHelper.TargettingFrame = 1
		end
	end
end

-- TPerl_AssistsView_Close
function TPerl_AssistsView_Open()
	TPerlConfigHelper.AssistsFrame = 1
	TPerlConfigHelper.TargettingFrame = 1
	TPerl_SetFrameSides()
	return true
end

function TPerl_AssistsView_Close()
	TPerlConfigHelper.AssistsFrame = 0
	TPerlConfigHelper.TargettingFrame = 0
	TPerl_SetFrameSides()
end

-- SortByClass(t1, t2)
local function SortByClass(t1, t2)
	if (t1[2] == t2[2]) then
		return t1[1] < t2[1]
	else
		local t1c = t1[2]
		local t2c = t2[2]
		if (t1c == myClass) then
			t1c = "A"..t1c
		elseif (t1c ~= "") then
			t1c = "B"..t1c
		else
			t1c = "Z"
		end
		if (t2c == myClass) then
			t2c = "A"..t2c
		elseif (t2c ~= "") then
			t2c = "B"..t2c
		else
			t1c = "Z"
		end

		return t1c..t1[1] < t2c..t2[1]
	end
end

-- TPerl_MakeAssistsString
function TPerl_MakeAssistsString(List, title)
	local text = title

	if (List ~= nil) then
		local lastClass
		local any = false
		local nAssists = #List
		if (nAssists > 0) then
			text = text.." "..nAssists
		end
		text = text.."\13"

		sort(List, SortByClass)

		for i,unit in ipairs(List) do
			if (not any) then
				if (unit[2] == "") then
					text = text.."|c00FF0000"..unit[1]
				else
					text = text..TPerlColourTable[unit[2]]..unit[1]
				end
				lastClass, any = unit[2], true
			else
				if (lastClass) then
					if (unit[2] == "" or lastClass ~= unit[2]) then
						lastClass = unit[2]

						if (unit[2] == "") then
							text = text.."\r|c00FF0000"..unit[1]
						else
							text = text.."\r"..TPerlColourTable[unit[2]]..unit[1]
						end
					else
						text = text.." "..unit[1]
					end
				else
					text = text.." "..unit[1]

					lastClass = unit[2]
				end
			end
		end
	end

	return (text)
end

-- FillList
local function FillList(List, cFrame, title)
	local text = TPerl_MakeAssistsString(List, title)
	_G["TPerl_Target_Assists_ScrollChild_"..cFrame.."Text"]:SetText(text)
end

-- TPerl_ShowAssists()
function TPerl_ShowAssists()
	if (TPerlConfigHelper and (TPerlConfigHelper.AssistsFrame == 1 or TPerlConfigHelper.TargettingFrame == 1)) then
		if (TPerlConfigHelper.AssistsFrame == 1 and TPerl_Assists_Frame.assists ~= nil) then
			FillList(TPerl_Assists_Frame.assists, "Assists", TPERL_TOOLTIP_ASSISTING)
		end

		if (TPerlConfigHelper.TargettingFrame == 1 and TPerl_Assists_Frame.targetting ~= nil) then
			local title
			if (#TPerl_Assists_Frame.targetting > 0 and TPerl_Assists_Frame.targetting[1][2] == "") then
				title = TPERL_TOOLTIP_ENEMYONME
			else
				if (TPerlConfigHelper.TargetCountersSelf == 0) then
					title = TPERL_TOOLTIP_ALLONME
				else
					title = TPERL_TOOLTIP_HEALERS
				end
			end

			FillList(TPerl_Assists_Frame.targetting, "Targetting", title)
		end
	end
end

-- TPerl_Assists_MouseDown
function TPerl_Assists_MouseDown(self, button, param)
	if (button == "LeftButton") then
		if (not TPerlConfigHelper or not TPerlConfigHelper.AssistPinned or (IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown())) then
			--if (param and (param == "TOPLEFT" or param == "BOTTOMLEFT" or param == "BOTTOMRIGHT")) then
			--	self:StartSizing(param)
			--else
				TPerl_Assists_FrameAnchor:StartMoving()
			--end
		end

	elseif (button == "RightButton") then
		local n = self:GetName()
		if (n and strfind (n, "TPerl_Target_Assists_ScrollChild_Targetting")) then
			param = "targetFrame"
		end

		if (param and param == "targetFrame") then
			if (TPerlConfigHelper.TargetCountersSelf == 1) then
				TPerlConfigHelper.TargetCountersSelf = 0
			else
				TPerlConfigHelper.TargetCountersSelf = 1
			end
			TPerl_UpdateAssists()
			TPerl_ShowAssists()
		end
	end
end

-- TPerl_Assists_MouseUp
function TPerl_Assists_MouseUp(self, button)
	--TPerl_Assists_Frame:StopMovingOrSizing()
	TPerl_Assists_FrameAnchor:StopMovingOrSizing()
	if (TPerl_SavePosition) then
		TPerl_SavePosition(TPerl_Assists_FrameAnchor)
	end

	-- TPerl_RegisterScalableFrame(self, TPerl_Assists_FrameAnchor, nil, nil, nil, true, true)
end

-- MakeFriendlyUnitList
local function MakeFriendlyUnitList()
	local start, prefix, total
	if IsInRaid() then
		start, prefix, total = 1, "raid", GetNumGroupMembers()
	else
		start, prefix, total = 0, "party", GetNumSubgroupMembers()
	end

	--friendlyUnitList = {"player", "pet"}
	--TPerl_FreeTable(friendlyUnitList)
	--friendlyUnitList = TPerl_GetReusableTable()
	friendlyUnitList = { }
	tinsert(friendlyUnitList, "player")
	tinsert(friendlyUnitList, "pet")

	local name, petname
	for i = start, total do
		if (i == 0) then
			name, petname = "player", "pet"
		else
			name, petname = prefix..i, prefix.."pet"..i
		end

		if (not UnitIsUnit(name, "player")) then
			if (UnitExists(name)) then
				tinsert(friendlyUnitList, name)
			end
			if (UnitExists(petname)) then
				tinsert(friendlyUnitList, petname)
			end
		end
	end
end

-- Events
function TPerl_Assists_OnEvent(self, event, unit)
	if (event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_TARGET" and not UnitIsUnit(unit, "player"))) then
		doUpdate = true
	elseif (event == "VARIABLES_LOADED") then
		MakeFriendlyUnitList()
		TPerl_UpdateAssists()
		TPerl_ShowAssists()

		TPerl_RegisterScalableFrame(self, TPerl_Assists_FrameAnchor, nil, nil, nil, true, true)
		self.corner.onSizeChanged = function(self, x, y)
			TPerlConfigHelper.sizeAssistsX = x
			TPerlConfigHelper.sizeAssistsY = y
		end
		self.corner.onScaleChanged = function(self, s)
			TPerlConfigHelper.sizeAssistsS = s
		end
		TPerlAssistPin:SetButtonTex()
	elseif (event == "GROUP_ROSTER_UPDATE") then
		MakeFriendlyUnitList()
		doUpdate = true
	elseif (event == "PLAYER_DEAD" or event == "PLAYER_REGEN_ENABLED") then
		--TPerl_FreeTable(currentPlayerAggro)
		--currentPlayerAggro = TPerl_GetReusableTable()
		currentPlayerAggro = { }
		if (TPerl_Highlight) then
			TPerl_Highlight:ClearAll("AGGRO")
		end
		TPerl_UpdateAssists()
		TPerl_ShowAssists()
	elseif (event == "PLAYER_ENTERING_WORLD") then
		if (TPerl_Highlight) then
			TPerl_Highlight:ClearAll("AGGRO")
		end

		if IsRetail then
			TPerlAssistsCloseButton:SetScale(0.66)
			TPerlAssistsCloseButton:SetPoint("TOPRIGHT", -6, -6)
			TPerlAssistPin:SetPoint("RIGHT", TPerlAssistsCloseButton, "LEFT", 0, 0)
		end

		MakeFriendlyUnitList()
		doUpdate = true
	end
end

-- TPerl_Assists_OnUpdate
local UpdateTime = 0
function TPerl_Assists_OnUpdate(self, arg1)
	UpdateTime = arg1 + UpdateTime
	if (doUpdate or UpdateTime >= 0.2) then
		if (doUpdate or #enemyUnitList > 0) then
			doUpdate = false
			TPerl_UpdateAssists()
			TPerl_ShowAssists()
		end
		UpdateTime = 0
	end
end

---------------------------------
-- Targetting counters         --
---------------------------------

local assists
local targetting

-- TPerl_FoundEnemyBefore
local function TPerl_FoundEnemyBefore(FoundEnemy, name)
	for previous in pairs(FoundEnemy) do
		if (UnitIsUnit(previous.."target", name.."target")) then
			return true
		end
	end
	return false
end

-- TPerl_AddEnemy
local function TPerl_AddEnemy(anyEnemy, FoundEnemy, name)
	local namet = name.."target"
	local namett = namet.."target"
	if (not TPerl_FoundEnemyBefore(wholeEnemyUnitList, name)) then
		if (UnitExists(namet)) then
			wholeEnemyUnitList[name] = true

			if (TPerl_Highlight and conf and conf.highlight.AGGRO) then
				if (UnitInRaid(namett) or UnitInParty(namett)) then
					currentPlayerAggro[UnitName(namett)] = UnitGUID(namett)
				end
			end
		end
	end

	if (UnitIsUnit("player", namett)) then
		if (not TPerl_FoundEnemyBefore(FoundEnemy, name)) then
			if (not playerAggro and TPerlConfigHelper.AggroWarning == 1) then
				playerAggro = true
				TPerl_AggroPlayer:Show()
			end

			FoundEnemy[name] = true
			--local n = TPerl_GetReusableTable()
			--[[local n = { }
			n[1] = UnitName(namet)
			n[2] = ""
			tinsert(targetting, n)]]
			tinsert(targetting, {UnitName(namet), ""})
			return true
		end
	-- 1.8.3 Added check to see if mob is targetting our target, and add to that list
	elseif (UnitExists("target") and UnitIsUnit("target", namett)) then
		-- We can still use the FoundEnemy list, because it's not too important if
		-- we're targetting ourself and the mob doesn't show on both self and target lists
		if (not TPerl_FoundEnemyBefore(FoundEnemy, name)) then
			FoundEnemy[name] = true
			--local n = TPerl_GetReusableTable()
			--[[local n = { }
			n[1] = UnitName(namet)
			n[2] = ""]]
			tinsert(assists, {UnitName(namet), ""})
			return true
		end
	elseif (not petAggro and TPerlConfigHelper.AggroWarning == 1 and UnitExists(namett) and UnitIsUnit("pet", namett)) then
		petAggro = true
		--petFadeStart = GetTime()
		TPerl_AggroPet:Show()
	end

	return false
end

local HealerClasses = {PRIEST = true, SHAMAN = true, PALADIN = true, DRUID = true}

-- TPerl_UpdateAssists
function TPerl_UpdateAssists()
	--TPerl_FreeTable(wholeEnemyUnitList)
	--wholeEnemyUnitList = TPerl_GetReusableTable()
	wholeEnemyUnitList = { }

	local oldPlayerAggro = currentPlayerAggro
	--currentPlayerAggro = TPerl_GetReusableTable()
	currentPlayerAggro = { }
	--[[if (TPerl_Highlight) then
		TPerl_Highlight:ClearAll("AGGRO")
	--end]]

	if TPerlConfigHelper and TPerlConfigHelper.TargetCounters == 0 then
		if (TPerl_Target_AssistFrame) then
			TPerl_Target_AssistFrame:Hide()
		end
		if (TPerl_Player_TargettingFrame) then
			TPerl_Player_TargettingFrame:Hide()
		end
		return
	end

	local selfFlag, enemyFlag
	if TPerlConfigHelper then
		selfFlag = TPerlConfigHelper.TargetCountersSelf == 1
		enemyFlag = TPerlConfigHelper.TargetCountersEnemy == 1
	end

	local assistCount, targettingCount, anyEnemy = 0, 0, false
	--local start, i, total, prefix, name, petname

	--local FoundEnemy = TPerl_GetReusableTable()
	local FoundEnemy = { }

	-- Re-use all the old tables from last pass
	--assists = TPerl_Assists_Frame.assists
	--targetting = TPerl_Assists_Frame.targetting
	--[[if (assists) then
		for k, v in pairs(assists) do
			--TPerl_FreeTable(v)
			assists[k] = nil
		end
	end]]
	--[[if (targetting) then
		for k, v in pairs(targetting) do
			--TPerl_FreeTable(v)
			targetting[k] = nil
		end
	end]]
	--TPerl_FreeTable(assists)
	--TPerl_FreeTable(targetting)
	--assists = { }
	--targetting = { }

	-- Get new tables
	--assists = TPerl_GetReusableTable()
	assists = { }
	--targetting = TPerl_GetReusableTable()
	targetting = { }

	playerAggro, petAggro = false, false

	local targetname = UnitName("target")
	for i, name in pairs(friendlyUnitList) do
		if (UnitExists(name.."target") and not UnitIsDeadOrGhost(name)) then
			local _, engClass = UnitClass(name)

			if (targetname) then
				if (UnitIsUnit("target", name.."target")) then
					assistCount = assistCount + 1
					--local n = TPerl_GetReusableTable()
					--[[local n = { }
					n[1] = UnitName(name)
					n[2] = engClass
					tinsert(assists, n)]]
					tinsert(assists, {UnitName(name), engClass})
				end
			end

			-- 0 for Anyone, 1 for Healers
			if (not selfFlag or HealerClasses[engClass]) then
				if (UnitIsUnit("player", name.."target")) then
					targettingCount = targettingCount + 1
					--local n = TPerl_GetReusableTable()
					--[[local n = { }
					n[1] = UnitName(name)
					n[2] = engClass
					tinsert(targetting, n)]]
					tinsert(targetting, {UnitName(name), engClass})
				end
			end

			-- Count enemy targetting us?
			if (enemyFlag) then
				if (UnitCanAttack("player", name.."target")) then	-- not UnitIsFriend("player", name.."target")) then
					if (TPerl_AddEnemy(anyEnemy, FoundEnemy, name)) then
						anyEnemy = true
						targettingCount = targettingCount + 1
					end
				end
			end
		end
	end

	if (enemyFlag) then
		if (not UnitIsFriend("player", "focus")) then
			if (UnitIsUnit("player", "focustarget")) then
				if (TPerl_Highlight and conf and conf.highlight.AGGRO) then
					currentPlayerAggro[UnitName("player")] = UnitGUID("player")
				end

				if (not TPerl_FoundEnemyBefore(FoundEnemy, "focus")) then
					if (not playerAggro and TPerlConfigHelper.AggroWarning == 1) then
						playerAggro = true
						TPerl_AggroPlayer:Show()
					end

					FoundEnemy["focus"] = true
					--local n = TPerl_GetReusableTable()
					--[[local n = { }
					n[1] = UnitName("focus")
					n[2] = ""
					tinsert(targetting, n)]]
					tinsert(targetting, {UnitName("focus"), ""})
					return true
				end
			end
		end
	end

	TPerl_Assists_Frame.assists, TPerl_Assists_Frame.targetting = assists, targetting

	--[[if (GetNumGroupMembers() == 0) then
		-- Don't show it if we're on our own... we know we have aggro..
		playerAggro, petAggro = false, false
	end]]

	if (playerAggro or petAggro) then
		TPerl_Aggro:Show()
	end

	enemyUnitList = FoundEnemy

	if (TPerl_Highlight and conf and conf.highlight.AGGRO) then
		for k, v in pairs(oldPlayerAggro) do
			if (not currentPlayerAggro[k]) then
				TPerl_Highlight:Remove(v, "AGGRO")
			end
		end
		for k, v in pairs(currentPlayerAggro) do
			if (not oldPlayerAggro[k]) then
				TPerl_Highlight:Add(v, "AGGRO", 0)
			end
		end
	end

	if TPerlConfigHelper and TPerlConfigHelper.ShowTargetCounters == 1 then
		if (TPerl_Player_TargettingFrame) then
			if (TPerl_Player) then
				local color = (conf and conf.colour.border) or (TPerlConfigHelper and TPerlConfigHelper.BorderColour) or {r = 0.5, g = 0.5, b = 0.5}

				if (anyEnemy) then
					TPerl_Player_TargettingFrame:SetBackdropBorderColor(1, 0.2, 0.2, color.a)
				else
					TPerl_Player_TargettingFrame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
				end

				if (targettingCount == 0) then
					TPerl_Player_TargettingFrametext:SetTextColor(1, 0.5, 0.5, conf.transparency.text)
				elseif (targettingCount > 5) then
					TPerl_Player_TargettingFrametext:SetTextColor(0.5, 1, 0.5, conf.transparency.text)
				else
					TPerl_Player_TargettingFrametext:SetTextColor(0.5, 0.5, 1, conf.transparency.text)
				end

				TPerl_Player_TargettingFrame:SetText(targettingCount)
				TPerl_Player_TargettingFrame:Show()
			else
				TPerl_Player_TargettingFrame:Hide()
			end
		end

		if (TPerl_Target_AssistFrame) then
			if (TPerl_Target) then
				if (assistCount < 2) then
					TPerl_Target_AssistFrametext:SetTextColor(1, 0.5, 0.5, conf.transparency.text)
				elseif (assistCount > (#friendlyUnitList / 2)) then
					TPerl_Target_AssistFrametext:SetTextColor(0.5, 1, 0.5, conf.transparency.text)
				else
					TPerl_Target_AssistFrametext:SetTextColor(0.5, 0.5, 1, conf.transparency.text)
				end

				if (targetname) then
					TPerl_Target_AssistFrame:SetText(assistCount)
				end
				TPerl_Target_AssistFrame:Show()
			else
				TPerl_Target_AssistFrame:Hide()
			end
		end
	else
		TPerl_Player_TargettingFrame:Hide()
		TPerl_Target_AssistFrame:Hide()
	end

	--TPerl_FreeTable(oldPlayerAggro)
	--TPerl_FreeTable(FoundEnemy)
end

-- TPerl_Assists_GetEnemyUnitList
function TPerl_Assists_GetEnemyUnitList()
	return wholeEnemyUnitList
end

-- TPerl_StartAssists
function TPerl_StartAssists()
	local _
	_, myClass = UnitClass("player")

	TPerlColourTable.pet = "|c008080FF"

	if (TPerl_RegisterPerlFrames) then
		TPerl_RegisterPerlFrames(TPerl_Assists_Frame)
	end

	TPerl_SetFrameSides()
end

-- TPerl_RefreshAggro
function TPerl_RefreshAggro(self)
	if (playerAggro) then
		TPerl_AggroPlayer:SetVertexColor(1, 0, 0, 1)
	else
		if (self.playerFadeStart) then
			local elapsed = GetTime() - self.playerFadeStart
			if (elapsed < 1) then
				TPerl_AggroPlayer:SetVertexColor(0, 1, 0, 1 - elapsed)
			else
				TPerl_AggroPlayer:Hide()
				self.playerFadeStart = nil
				if (not TPerl_AggroPet:IsShown()) then
					self:Hide()
				end
			end
		else
			self.playerFadeStart = GetTime()
		end
	end
	if (petAggro) then
		TPerl_AggroPet:SetVertexColor(1, 0, 0, 1)
	else
		if (self.petFadeStart) then
			local elapsed = GetTime() - self.petFadeStart
			if (elapsed < 1) then
				TPerl_AggroPet:SetVertexColor(0, 1, 0, 1 - elapsed)
			else
				TPerl_AggroPet:Hide()
				self.petFadeStart = nil
				if (not TPerl_AggroPlayer:IsShown()) then
					self:Hide()
				end
			end
		else
			self.petFadeStart = GetTime()
		end
	end
end
