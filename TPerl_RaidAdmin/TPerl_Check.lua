-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

TPerl_SetModuleRevision("$Revision:  $")

if type(C_ChatInfo.RegisterAddonMessagePrefix) == "function" then
	C_ChatInfo.RegisterAddonMessagePrefix("CTRA")
end

TPerl_CheckItems = {}

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsCataClassic = WOW_PROJECT_ID == WOW_PROJECT_CATA_CLASSIC
local IsMistsClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

-- Upvalues
local _G = _G
local floor = floor
local format = format
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local sort = sort
local strfind = strfind
local string = string
local strlen = strlen
local strlower = strlower
local strmatch = strmatch
local strsub = strsub
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local type = type
local unpack = unpack

local ChatTypeInfo = ChatTypeInfo
local CheckInteractDistance = CheckInteractDistance
local ClearCursor = ClearCursor
local CursorHasItem = CursorHasItem
local DressUpItemLink = DressUpItemLink
local GetChannelName = GetChannelName
local GetContainerItemLink = GetContainerItemLink
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetRealZoneText = GetRealZoneText
local GetTime = GetTime
local IsControlKeyDown = IsControlKeyDown
local IsInRaid = IsInRaid
local IsShiftKeyDown = IsShiftKeyDown
local SecondsToTime = SecondsToTime
local SendChatMessage = SendChatMessage
local UnitClass = UnitClass
local UnitInRaid = UnitInRaid
local UnitIsConnected = UnitIsConnected
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitName = UnitName

local C_ChatInfo = C_ChatInfo

local TPerl_ItemResults = {["type"] = "item"}
local TPerl_ResistResults = {["type"] = "res", count = 0}
local TPerl_DurResults = {["type"] = "dur", count = 0}
local TPerl_RegResults = {["type"] = "reg", count = 0}
local TPerl_PlayerList = {}
local TPerl_MsgQueue = {}
local SelectedPlayer
local TPerl_ActiveScan
local ActiveScanItem
local ActiveScanTotals
local channelList = nil
local outputChannel = "RAID"
local outputChannelIndex = nil
local outputChannelSelection
local outputChannelColour

local ITEMLISTSIZE = 12
local PLAYERLISTSIZE = 10

-- TPerl_CheckOnLoad
function TPerl_CheckOnLoad(self)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnEvent", TPerl_CheckOnEvent)
	self:SetScript("OnShow", TPerl_CheckOnShow)
	self:SetScript("OnHide", TPerl_CheckOnHide)
	--self:RegisterEvent("CHAT_MSG_ADDON")

	TPerl_CheckListItemsScrollBar.offset = 0
	TPerl_CheckListPlayersScrollBar.offset = 0

	if IsRetail then
		TPerl_CheckTitleBarClose:SetScale(0.66)
		TPerl_CheckTitleBarClose:SetPoint("TOPRIGHT", 2, 2)
		TPerl_CheckTitleBarPin:SetPoint("RIGHT", TPerl_CheckTitleBarClose, "LEFT", 0, 0)
		TPerl_CheckTitleBarLockOpen:SetPoint("RIGHT", TPerl_CheckTitleBarPin, "LEFT", 0, 0)
	end

	if (TPerl_RegisterPerlFrames) then
		TPerl_RegisterPerlFrames(self)
	end

	if (TPerl_SavePosition) then
		TPerl_SavePosition(TPerl_CheckAnchor, true)
	end

	TPerl_RegisterScalableFrame(self, TPerl_CheckAnchor)
	self.corner:SetParent(TPerl_CheckList)

	TPerl_Check:SetWidth(130)
	TPerl_Check:SetHeight(18)

	TPerl_CheckOnLoad = nil
end

if (not TPerl_GetClassColour) then
	TPerl_GetClassColour = function(class)
		if (class) then
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] -- Now using the WoW class color table
			if (color) then
				return color
			end
		end
		return {r = 0.5, g = 0.5, b = 1}
	end
end

if (not TPerlColourTable) then
	TPerlColourTable = setmetatable({},{
		__index = function(self, class)
			local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or {r = 0, g = 0, b = 0}
			return format("|c00%02X%02X%02X", 255 * c.r, 255 * c.g, 255 * c.b)
		end
	})
end

if (not TPerl_ClassPos) then
	local ClassPos = CLASS_BUTTONS
	function TPerl_ClassPos(class)
		local b = ClassPos[class] -- Now using the Blizzard supplied from FrameXML/WorldStateFrame.lua
		if (b) then
			return unpack(b)
		end
		return 0.25, 0.5, 0.5, 0.75
	end
end

-- CTRAItemMsg
local needUpdate
local function CTRAItemMsg(nick, item, count)
	local results = TPerl_ItemResults[item]
	if (results) then
		results.last = GetTime()
		tinsert(results, {name = nick, ["count"] = tonumber(count)})
		needUpdate = true
	end
end

local function ProcessCTRAMessage(unitName, msg)
	--ChatFrame7:AddMessage(unitName..": "..msg)
	if (strfind(msg, "^ITM ")) then
		local numItems, itemName, callPerson = strmatch(msg, "^ITM ([-%d]+) (.+) ([^%s]+)$")

		if (callPerson == UnitName("player")) then		-- Maybe ignore this
			CTRAItemMsg(unitName, itemName, numItems)
		end

	elseif (strfind(msg, "^DUR ")) then
		local currDur, maxDur, brokenItems, callPerson = strmatch(msg, "^DUR (%d+) (%d+) (%d+) ([^%s]+)$")

		if (currDur and maxDur and brokenItems) then
			currDur, maxDur, brokenItems = tonumber(currDur), tonumber(maxDur), tonumber(brokenItems)
			TPerl_DurResults[unitName] = {dur = floor((currDur / maxDur) * 100 + 0.5), broken = brokenItems}
			if (callPerson == UnitName("player")) then
				TPerl_DurResults.count = TPerl_DurResults.count + 1
			end
			TPerl_DurResults.last = GetTime()
			needUpdate = true
		end

	elseif (strfind(msg, "^RST ")) then
		local plrName = strmatch(msg, "^RST %-1 ([^%s]+)$")
		if (not plrName) then
			local FR, NR, FRR, SR, AR, callPerson = strmatch(msg, "^RST (%d+) (%d+) (%d+) (%d+) (%d+) ([^%s]+)$")
			if (FR) then
				TPerl_ResistResults[unitName] = {fr = tonumber(FR), nr = tonumber(NR), frr = tonumber(FRR), sr = tonumber(SR), ar = tonumber(AR)}
				if (callPerson == UnitName("player")) then
					TPerl_ResistResults.count = TPerl_ResistResults.count + 1
				end
				TPerl_ResistResults.last = GetTime()
				needUpdate = true
			end
		end

	elseif (strfind(msg, "^REA ")) then
		local numItems, callPerson = strmatch(msg, "^REA ([^%s]+) ([^%s]+)$")
		if (numItems) then
			TPerl_RegResults[unitName] = {count = tonumber(numItems)}
			if (callPerson == UnitName("player")) then
				TPerl_RegResults.count = TPerl_RegResults.count + 1
			end
			TPerl_RegResults.last = GetTime()
			needUpdate = true
		end
	end
end

-- TPerl_Check_Setup
function TPerl_Check_Setup()
	SlashCmdList["TPERLITEM"] = TPerl_ItemCheck
	SLASH_TPERLITEM1 = "/xpitem"
	SLASH_TPERLITEM2 = "/raitem"
	SLASH_TPERLITEM3 = "/radur"
	SLASH_TPERLITEM4 = "/raresist"
	SLASH_TPERLITEM5 = "/raresists"
	SLASH_TPERLITEM6 = "/rareg"

	SlashCmdList["RAITEM"] = nil
	SLASH_RAITEM1 = nil
	SlashCmdList["RADUR"] = nil
	SLASH_RADUR1 = nil
	SlashCmdList["RARST"] = nil
	SLASH_RARST1 = nil
	SlashCmdList["RAREG"] = nil
	SLASH_RAREG1 = nil

	if (not TPerl_Admin.ResistSort) then
		TPerl_Admin.ResistSort = "fr"
	end
	for k,v in ipairs(TPerl_CheckItems) do
		v.query = nil
	end

	TPerl_CheckTitleBarPin:SetButtonTex()
	TPerl_CheckTitleBarLockOpen:SetButtonTex()

	TPerl_CheckListPlayersTotals:SetHighlightTexture("")
	TPerl_CheckListPlayersTotals:SetScript("OnClick", nil)

	TPerl_Check_ItemsChanged()
	TPerl_Check_UpdatePlayerList()

	TPerl_Check_Setup = nil
end

-- TPerl_CheckOnShow
function TPerl_CheckOnShow(self)
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

-- TPerl_CheckOnHide
function TPerl_CheckOnHide(self)
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

-- TPerl_CheckOnEvent
function TPerl_CheckOnEvent(self, event, a1, a2, a3, a4)
	if (event == "GROUP_ROSTER_UPDATE") then
		if (not IsInRaid()) then
			TPerl_ItemResults = {["type"] = "item"}
			TPerl_ResistResults = {["type"] = "res", count = 0}
			TPerl_DurResults = {["type"] = "dur", count = 0}
			TPerl_RegResults = {["type"] = "reg", count = 0}
		end
		TPerl_Check_ValidateButtons()

	elseif (event == "CHAT_MSG_ADDON") then
		if (a1 == "CTRA" and a3 == "RAID") then
			needUpdate = nil
			TPerl_ParseCTRA(a4, a2, ProcessCTRAMessage)

			if (needUpdate) then
				TPerl_Check_UpdateItemList()
				TPerl_Check_MakePlayerList()
				TPerl_Check_ShowInfo()
			end
		end
	elseif (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_MODEL_CHANGED") then
		local n = UnitName(a1)
		if (TPerl_ActiveScan and TPerl_ActiveScan[n]) then
			TPerl_ActiveScan[n].changed = true
			TPerl_ActiveScan[n].offline = nil
			TPerl_ActiveScan[n].wrongZone = nil
		end
	end
end

-- TPerl_CheckOnUpdate
-- Only active after a query, and only for 10 seconds
local function TPerl_CheckOnUpdate(self, elapsed)
	-- TODO Total Progress indication
	if (#TPerl_MsgQueue > 0) then
		local Time = GetTime()
		local send
		if (not self.lastMsgsent) then
			send = true
		elseif (Time > self.lastMsgsent + 1) then
			send = true
		end

		if (send) then
			self.lastMsgsent = Time

			local count = 0
			local msg = ""

			while (#TPerl_MsgQueue > 0 and count < 4) do
				local sub = TPerl_MsgQueue[1]

				if (strlen(msg..sub) > 220) and UnitInRaid("player") then
					C_ChatInfo.SendAddonMessage("CTRA", msg, "RAID")
					break
				else
					count = count + 1
					tremove(TPerl_MsgQueue, 1)
					if (msg == "") then
						msg = sub
					else
						msg = msg.."#"..sub
					end
				end
			end

			if (msg ~= "") and UnitInRaid("player") then
				C_ChatInfo.SendAddonMessage("CTRA", msg, "RAID")
			end
		end

	elseif (ActiveScanItem) then
		TPerl_Check_ActiveScan()
	else
		if (self.queryStart and GetTime() > self.queryStart + 5) then
			self:SetScript("OnUpdate", nil)
			self.queryStart, self.lastMsgsent = nil, nil

			TPerl_Check_ValidateButtons()
		end
	end
end

-- GetVLinkName
local function GetVLinkName(v)
	local linkName
	if (strsub(v.link, 1, 1) == "|") then
		linkName = strmatch(v.link, "%[(.+)%]")
	else
		linkName = v.link
	end
	return linkName
end

-- ClearSelectedItem
local function ClearSelectedItem()
	for k,v in ipairs(TPerl_CheckItems) do
		v.selected = nil
	end
end

-- TickItemByName
local function TickItemByName(itemName)
	for k,v in ipairs(TPerl_CheckItems) do
		local name = GetVLinkName(v)

		if (name == itemName) then
			if (not v.fixed) then
				v.ticked = true
			end
			v.selected = true
			break
		end
	end
end

-- GotItem
local function GotItem(link)
	local findItem = strmatch(link, "item:(%d+):")
	for k,v in pairs(TPerl_CheckItems) do
		local item = strmatch(v.link, "item:(%d+):")
		if (item == findItem) then
			return true
		end
	end
end

-- GotItem
local function GotItemName(itemName)
	for k,v in pairs(TPerl_CheckItems) do
		local linkName = strmatch(v.link, "%[(.+)%]")
		if (linkName == itemName) then
			return true
		end
	end
end

-- InsertItemLink
local function InsertItemLink(itemLink)
	ClearSelectedItem()

	if (strsub(itemLink, 1, 1) == "|") then
		if (not GotItem(itemLink)) then
			tinsert(TPerl_CheckItems, {link = itemLink, ticked = true, selected = true})
		else
			local linkName = strmatch(itemLink, "%[(.+)%]")
			TickItemByName(linkName)
		end
	else
		if (not GotItemName(itemLink)) then
			tinsert(TPerl_CheckItems, {link = itemLink, ticked = true, selected = true})
		else
			local linkName = strmatch(itemLink, "%[(.+)%]")
			TickItemByName(linkName)
		end
	end
end

-- TPerl_Check_Expand()
function TPerl_Check_Expand(forced)
	TPerl_Check:SetWidth(500)
		TPerl_Check:SetHeight(240)
		TPerl_CheckList:Show()
		TPerl_CheckButton:Show()
	TPerl_Check.forcedOpen = forced
	TPerl_CheckTitleBarLockOpen:Show()
end

-- TPerl_ItemCheck
function TPerl_ItemCheck(itemName)
	local cmd = "/raitem"
	if (DEFAULT_CHAT_FRAME.editBox) then
		local command = DEFAULT_CHAT_FRAME.editBox:GetText()
		if (strlower(strsub(command, 1, 6)) == "/radur") then
			cmd = "/radur"
		elseif (strlower(strsub(command, 1, 9)) == "/raresist") then
			cmd = "/raresist"
		elseif (strlower(strsub(command, 1, 6)) == "/rareg") then
			cmd = "/rareg"
		end
	end

	TPerl_Check:Show()
	TPerl_Check_Expand(true)

	if (cmd == "/raitem") then
		if (not itemName or itemName == "") then
			return
		end

		if (strsub(itemName, 1, 1) == "|") then
			-- TODO search for item in inventory (and LootLink) and use the link
		end

		InsertItemLink(itemName)
	elseif (cmd == "/radur") then
		ClearSelectedItem()
		TickItemByName("dur")

	elseif (cmd == "/rareg") then
		ClearSelectedItem()
		TickItemByName("reg")

	elseif (cmd == "/raresist") then
		ClearSelectedItem()
		TickItemByName("res")
	end

	TPerl_Check_Query()
end

-- TPerl_PickupContainerItem
local PickupBag, PickupSlot
if C_Container then
	hooksecurefunc(C_Container, "PickupContainerItem", function(bagID, slot)
		PickupBag, PickupSlot = bagID, slot
	end)
elseif PickupContainerItem then
	hooksecurefunc("PickupContainerItem", function(bagID, slot)
		PickupBag, PickupSlot = bagID, slot
	end)
end

-- sortItems
-- Fixed entries at top, followed by last current queried, followed by rest. Alphabetical within this.
local function sortItems(i1, i2)
	local itemName1 = GetVLinkName(i1)
	local itemName2 = GetVLinkName(i2)

	local t1, t2, f1, f2, q1, q2
	if (i1.fixed) then f1 = "0" else f1 = "1" end
	if (i2.fixed) then f2 = "0" else f2 = "1" end
	if (i1.ticked) then t1 = "0" else t1 = "1" end
	if (i2.ticked) then t2 = "0" else t2 = "1" end
	if (i1.query) then q1 = "0" else q1 = "1" end
	if (i2.query) then q2 = "0" else q2 = "1" end

	return f1..q1..t1..itemName1 < f2..q2..t2..itemName2
end

-- ItemsChanged
function TPerl_Check_ItemsChanged()
	-- Validate. Make sure we have our fixed entries
	local dur, reg, res
	for k,v in ipairs(TPerl_CheckItems) do
		if (v.link == "res") then
			res = true
		elseif (v.link == "dur") then
			dur = true
		elseif (v.link == "reg") then
			reg = true
		end
	end
	if (not dur) then
		tinsert(TPerl_CheckItems, {fixed = true, link = "dur"})
	end
	if (not res) then
		tinsert(TPerl_CheckItems, {fixed = true, link = "res"})
	end
	if (not reg) then
		tinsert(TPerl_CheckItems, {fixed = true, link = "reg"})
	end

	sort(TPerl_CheckItems, sortItems)

	TPerl_Check_UpdateItemList()
	TPerl_Check_ValidateButtons()
end

-- GetSelectedResults
local function GetSelectedItem()
	for k,v in ipairs(TPerl_CheckItems) do
		if (v.selected) then
			if (v.fixed) then
				if (v.link == "res") then
					return TPerl_ResistResults, "res"
				elseif (v.link == "dur") then
					return TPerl_DurResults, "dur"
				elseif (v.link == "reg") then
					return TPerl_RegResults, "reg"
				end
			else
				local linkName = GetVLinkName(v)
				if (linkName) then
					return TPerl_ItemResults[linkName], "item"
				end
				break
			end
		end
	end
end

-- GetSelectedItemLink
local function GetSelectedItemLink()
	local link
	for k,v in ipairs(TPerl_CheckItems) do
		if (v.selected) then
			return v.link
		end
	end
end

-- GetCursorItem
local function GetCursorItemLink(self)
	local id = self:GetID() + TPerl_CheckListItemsScrollBar.offset
	local item = TPerl_CheckItems[id]
	if (item and not item.fixed) then
		return item.link
	end
	return ""
end

-- SelectClickedTickItem
local function SelectClickedTickItem(self)
	local oldSelection
	for k, v in ipairs(TPerl_CheckItems) do
		if (v.selected) then
			oldSelection = v
			v.selected = nil
		end
	end

	local id
	if ((self.GetFrameType or self.GetObjectType)(self) == "CheckButton") then
		id = self:GetParent():GetID()
	else
		id = self:GetID()
	end

	if (id and id > 0) then
		id = id + TPerl_CheckListItemsScrollBar.offset

		local item = TPerl_CheckItems[id]
		if (item) then
			item.selected = true
		end

		if (oldSelection ~= item) then
			TPerl_Check_StopActiveScan()
			TPerl_ActiveScan = nil
			ActiveScanTotals = nil
		end

		TPerl_Check_UpdateItemList()
		TPerl_Check_MakePlayerList()
		TPerl_Check_ShowInfo()
	end
end

-- TPerl_Check_TickAll
function TPerl_Check_TickAll(all)
	for k, v in ipairs(TPerl_CheckItems) do
		if (not v.fixed) then
			v.ticked = all
		end
	end
	TPerl_Check_ItemsChanged()
end

-- TPerl_Check_TickLastResults
function TPerl_Check_TickLastResults()
	for k, v in ipairs(TPerl_CheckItems) do
		if (not v.fixed) then
			v.ticked = nil

			local linkName = GetVLinkName(v)
			if (linkName) then
				if (TPerl_ItemResults[linkName]) then
					v.ticked = true
				end
			end
		end
	end

	TPerl_Check_ItemsChanged()
end

-- TPerl_Check_OnClickItem
function TPerl_Check_OnClickItem(button)
	if (button == "LeftButton") then
		if (IsShiftKeyDown()) then
			local activeWindow = ChatEdit_GetActiveWindow()
			if ( activeWindow ) then
				activeWindow:Insert(GetCursorItemLink(button))
			end

		elseif (IsControlKeyDown()) then
			DressUpItemLink(GetCursorItemLink(button))

		else
			if (CursorHasItem()) then
				ClearCursor()

				if (PickupBag and PickupSlot) then
					local itemLink = GetContainerItemLink(PickupBag, PickupSlot)

					if (itemLink) then
						InsertItemLink(itemLink)
						TPerl_Check_ItemsChanged()
					end
				end
			end

			TPerl_CheckListPlayersScrollBarScrollBar:SetValue(0)
			TPerl_CheckButtonPlayerPortrait:SetTexture("")	-- SetPortraitTexture(TPerl_CheckButtonPlayerPortrait, "raidx")
			SelectedPlayer = nil
			SelectClickedTickItem(button)
			TPerl_Check_ValidateButtons()
		end
	end
end

local reagentClasses = {
	PRIEST = true,
	MAGE = true,
	DRUID = true,
	WARLOCK = true,
	PALADIN = true,
	SHAMAN = true
}

-- GetOnlineMembers
local function GetOnlineMembers()
	local count = 0
	local reagentCount = 0
	for i = 1,GetNumGroupMembers() do
		if (UnitIsConnected("raid"..i)) then
			local _, class = UnitClass("raid"..i)
			if (reagentClasses[class]) then
				reagentCount = reagentCount + 1
			end

			if (TPerl_Roster) then
				local stats = TPerl_Roster[UnitName("raid"..i)]
				if (stats) then
					if (stats.version) then
						count = count + 1
					end
				end
			else
				count = count + 1
			end
		end
	end
	return count, reagentCount
end

-- SmoothColour
local function SmoothColour(percentage)
	local r, g
	if (percentage < 0.5) then
		g = 2 * percentage
		r = 1
	else
		g = 1
		r = 2 * (1 - percentage)
	end
	if (r < 0) then r = 0 elseif (r > 1) then r = 1 end
	if (g < 0) then g = 0 elseif (g > 1) then g = 1 end
	return r, g, 0
end

-- SmoothBarColor
local function SmoothGuageColor(bar, percentage)
	local r, g, b = SmoothColour(percentage)
	bar:SetVertexColor(r, g, b, 0.75)
end

-- TPerl_Check_UpdateItemList
function TPerl_Check_UpdateItemList()
	local onlineCount, reagentCount = GetOnlineMembers()
	local index = 1
	local i = 0
	for k,v in ipairs(TPerl_CheckItems) do
		if (index > ITEMLISTSIZE) then
			break
		end
		if (i >= TPerl_CheckListItemsScrollBar.offset) then
			local frame = _G["TPerl_CheckListItems"..index]
			local nameFrame = _G["TPerl_CheckListItems"..index.."Name"]
			local countFrame = _G["TPerl_CheckListItems"..index.."Count"]
			local iconFrame = _G["TPerl_CheckListItems"..index.."Icon"]
			local gaugeFrame = _G["TPerl_CheckListItems"..index.."Gauge"]
			local tickFrame = _G["TPerl_CheckListItems"..index.."Tick"]

			frame:Show()
			if (v.selected) then
				frame:LockHighlight()
			else
				frame:UnlockHighlight()
			end

			if (v.fixed) then
				tickFrame:Hide()
				iconFrame:Hide()

				local div
				if (v.link == "res") then
					nameFrame:SetText(RESISTANCE_LABEL)
					countFrame:SetText(TPerl_ResistResults.count)
					if onlineCount == 0 then
						div = 1
					else
						div = TPerl_ResistResults.count / onlineCount
					end

				elseif (v.link == "dur") then
					local dur,c = string.gsub(DURABILITY_TEMPLATE, " %%d / %%d", "")
					if (not dur or c ~= 1) then
						dur = "Durability"
					end
					nameFrame:SetText(dur)
					countFrame:SetText(TPerl_DurResults.count)
					if onlineCount == 0 then
						div = 1
					else
						div = TPerl_DurResults.count / onlineCount
					end

				elseif (v.link == "reg") then
					nameFrame:SetText(TPERL_CHECK_REAGENTS)
					countFrame:SetText(TPerl_RegResults.count)
					if reagentCount == 0 then
						div = 1
					else
						div = TPerl_RegResults.count / reagentCount
					end
				end
				nameFrame:SetTextColor(1, 1, 0.7)

				if (div > 0) then
					if (div > 1) then div = 1 end
					gaugeFrame:SetWidth((countFrame:GetLeft() - nameFrame:GetLeft()) * div)
					gaugeFrame:Show()
					SmoothGuageColor(gaugeFrame, div)
				else
					gaugeFrame:Hide()
				end
			else
				tickFrame:Show()
				tickFrame:SetChecked(v.ticked)

				nameFrame:SetText(v.link)

				local itemId = strmatch(v.link, "item:(%d+):")
				if (itemId) then
					local itemName, itemString, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemId)
					iconFrame:SetTexture(itemTexture)
					iconFrame:Show()
				else
					iconFrame:Hide()
				end

				local linkName = GetVLinkName(v)
				if (linkName) then
					local count = ""
					local result = TPerl_ItemResults[linkName]
					if (result) then
						count = #result

						for k,v in pairs(result) do
							if (v == -1) then
								-- Don't count Blocked ones, it's misleading
								count = count - 1
							end
						end

						local div = count / onlineCount

						if (v.query and div > 0) then
							if (div > 1) then div = 1 end
							gaugeFrame:SetWidth((countFrame:GetLeft() - nameFrame:GetLeft()) * div)
							gaugeFrame:Show()
							SmoothGuageColor(gaugeFrame, div)
						else
							gaugeFrame:Hide()
						end
					else
						gaugeFrame:Hide()
					end
					countFrame:SetText(count)
				else
					gaugeFrame:Hide()
				end
			end

			index = index + 1
		end
		i = i + 1
	end

	for i = index,ITEMLISTSIZE do
			_G["TPerl_CheckListItems"..i]:Hide()
	end

	if (FauxScrollFrame_Update(TPerl_CheckListItemsScrollBar, #TPerl_CheckItems, ITEMLISTSIZE, 1)) then
		TPerl_CheckListItemsScrollBar:Show()
	else
		TPerl_CheckListItemsScrollBar:Hide()
	end
end

-- SortPlayersByCount
local function SortPlayersByCount(p1, p2)
	local c1, c2
	if (p1.broken) then
		if (p1.connected and not p1.noCTRA) then	c1 = p1.broken + (1 - (p1.dur / 100))	else	c1 = -1	end
		if (p2.connected and not p2.noCTRA) then	c2 = p2.broken + (1 - (p2.dur / 100))	else	c2 = -1	end
	else
		if (p1.connected and not p1.noCTRA) then	c1 = p1.count	else	c1 = -1	end
		if (p2.connected and not p2.noCTRA) then	c2 = p2.count	else	c2 = -1	end
	end
	return c1 > c2
end

-- SortPlayersByName
local function SortPlayersByName(p1, p2)
	return p1.name < p2.name
end

-- SortPlayersByClass
local function SortPlayersByClass(p1, p2)
	return p1.class..p1.name < p2.class..p2.name
end

-- ScanOrder
local function ScanOrder(p)
	local s = TPerl_ActiveScan[p.name]
	if (s) then
		if (s.notequipped) then
			return 1
		elseif (s.equipped) then
			if (s.changed) then
				return 2
			else
				return 3
			end
		elseif (s.notinzone) then
			return 4
		elseif (s.offline) then
			return 5
		end
	end
	return 0
end

-- SortPlayersByDur
local function SortPlayersByDur(p1, p2)
	if (p1.dur) then
		local o1, o2 = 0,0
		if (not p1.connected or p1.noCTRA) then o1 = 1000 end
		if (not p2.connected or p2.noCTRA) then o2 = 1000 end
		return p1.dur + o1 < p2.dur + o2
	else
		if (TPerl_ActiveScan) then
			return ScanOrder(p1)..p1.class..p1.name < ScanOrder(p2)..p2.class..p2.name
		else
			return SortPlayersByCount(p1, p2)
		end
	end
end

-- SortPlayersByResist
local function SortPlayersByResist(p1, p2)
	local o1, o2 = 0,0
	if (not p1.connected or p1.noCTRA) then o1 = 1000 end
	if (not p2.connected or p2.noCTRA) then o2 = 1000 end
	return p1[TPerl_Admin.ResistSort] - o1 > p2[TPerl_Admin.ResistSort] - o2
end

-- TPerl_Check_MakePlayerList
function TPerl_Check_MakePlayerList()

	FauxScrollFrame_SetOffset(TPerl_CheckListPlayersScrollBar, 0)

	local function ShowResists(show)
		local r = {"FR", "FRR", "NR", "SR", "AR"}
		for k,v in pairs(r) do
			local title = _G["TPerl_CheckListPlayersTitle"..v]
			local total = _G["TPerl_CheckListPlayersTotals"..v]
			if (show) then
				title:Show()
				total:Show()
			else
				title:Hide()
				total:Hide()
			end
		end
	end

	local function ShowCount(show)
		if (show) then
			TPerl_CheckListPlayersTitleCount:Show()
			TPerl_CheckListPlayersTotalsCount:Show()
		else
			TPerl_CheckListPlayersTitleCount:Hide()
			TPerl_CheckListPlayersTotalsCount:Hide()
		end
	end

	local function ShowDur(show)
		if (show) then
			TPerl_CheckListPlayersTitleDur:Show()
			TPerl_CheckListPlayersTotalsNR:Show()
		else
			TPerl_CheckListPlayersTitleDur:Hide()
			TPerl_CheckListPlayersTotalsNR:Hide()
		end
	end

	TPerl_PlayerList = {}

	local results, resType = GetSelectedItem()
	if (results and results.last) then
		TPerl_CheckListPlayersTitleClass:Show()
		TPerl_CheckListPlayersTitleName:Show()
		TPerl_CheckListPlayersTotalsName:Show()

		if (resType == "item" or resType == "reg") then
			TPerl_CheckListPlayersTotalsName:SetText(TPERL_CHECK_TOTALS)
			TPerl_CheckListPlayersTitleCount:SetText("#")

			ShowCount(true)
			ShowResists(false)
			ShowDur(TPerl_ActiveScan)

			if (TPerl_ActiveScan) then
				TPerl_CheckListPlayersTitleDur:SetText(TPERL_CHECK_EQUIPED)
			end

		elseif (resType == "dur") then
			TPerl_CheckListPlayersTotalsName:SetText(TPERL_CHECK_AVERAGE)

			ShowResists(false)
			ShowCount(true)
			ShowDur(true)

			TPerl_CheckListPlayersTitleCount:SetText(TPERL_CHECK_BROKEN)
			TPerl_CheckListPlayersTitleDur:SetText("%")

		elseif (resType == "res") then
			TPerl_CheckListPlayersTotalsName:SetText(TPERL_CHECK_AVERAGE)

			ShowCount(false)
			ShowDur(false)
			ShowResists(true)
		end

		for i = 1, GetNumGroupMembers() do
			local name = UnitName("raid"..i)
			local _, class = UnitClass("raid"..i)
			local count = 0
			local noCTRA

			if (TPerl_Roster) then
				local stats = TPerl_Roster[name]
				if (stats) then
					if (not stats.version) then
						noCTRA = true
					end
				end
			end

			if (resType == "item") then
				for k,v in ipairs(results) do
					if (v.name == name) then	-- type(v) == "table" and
						count = v.count
						if (count > 0) then
							noCTRA = nil
						end
						break
					end
				end

				tinsert(TPerl_PlayerList, {["name"] = name, unit = "raid"..i, ["count"] = count, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})

			elseif (resType == "reg") then
				if (reagentClasses[class] or results[name]) then
					local p = results[name]
					local reg = 0
					if (p) then
						reg = p.count
						if (reg > 0) then
							noCTRA = nil
						end
					end

					tinsert(TPerl_PlayerList, {["name"] = name, unit = "raid"..i, ["count"] = reg, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})
				end

			elseif (resType == "res") then
				local p = results[name]
				local fr, frr, nr, sr, ar = 0, 0, 0, 0, 0
				if (p) then
					fr, frr, nr, sr, ar = p.fr, p.frr, p.nr, p.sr, p.ar
					if (fr + frr + nr + sr + ar > 0) then
						noCTRA = nil
					end
				end

				tinsert(TPerl_PlayerList, {["name"] = name, unit = "raid"..i, ["fr"] = fr, ["frr"] = frr, ["nr"] = nr, ["sr"] = sr, ["ar"] = ar, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})

			elseif (resType == "dur") then
				local p = results[name]
				local dur, broken = 0, 0
				if (p) then
					dur, broken = p.dur, p.broken
					if (dur + broken > 0) then
						noCTRA = nil
					end
				end

				tinsert(TPerl_PlayerList, {["name"] = name, unit = "raid"..i, ["dur"] = dur, ["broken"] = broken, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})
			end
		end

		if (resType == "item" or resType == "reg") then
			sort(TPerl_PlayerList, SortPlayersByCount)
		elseif (resType == "dur") then
			sort(TPerl_PlayerList, SortPlayersByDur)
		elseif (resType == "res") then
			sort(TPerl_PlayerList, SortPlayersByResist)
		end
	else
		TPerl_CheckListPlayersTitleClass:Hide()
		TPerl_CheckListPlayersTitleName:Hide()
		TPerl_CheckListPlayersTotalsName:Hide()
		ShowCount(false)
		ShowDur(false)
		ShowResists(false)
	end

	TPerl_Check_UpdatePlayerList()
end

-- TPerl_Check_UpdatePlayerList
function TPerl_Check_UpdatePlayerList()
	local onlineCount, tFR, tFRR, tNR, tSR, tAR, tDur, tBroken, tCount = 0, 0, 0, 0, 0, 0, 0, 0, 0

	local results, resType = GetSelectedItem()
	local index = 1

	for i = 1,#TPerl_PlayerList do
		--    + TPerl_CheckListPlayersScrollBar.offset, PLAYERLISTSIZE + TPerl_CheckListPlayersScrollBar.offset do
		local v = TPerl_PlayerList[i]
		if (not v) then
			break
		end

		if (v.fr) then
			tFR = tFR + v.fr
			tFRR = tFRR + v.frr
			tNR = tNR + v.nr
			tSR = tSR + v.sr
			tAR = tAR + v.ar
		elseif (v.dur) then
			tDur = tDur + v.dur
			tBroken = tBroken + v.broken
		else
			if (v.count > 0) then
				tCount = tCount + v.count
			end
		end

		if (v.connected) then
			onlineCount = onlineCount + 1
		end

		if (i >= TPerl_CheckListPlayersScrollBar.offset + 1 and index <= PLAYERLISTSIZE) then
			local frame = _G["TPerl_CheckListPlayers"..index]
			local iconFrame = _G["TPerl_CheckListPlayers"..index.."Icon"]
			local nameFrame = _G["TPerl_CheckListPlayers"..index.."Name"]
			local countFrame = _G["TPerl_CheckListPlayers"..index.."Count"]
			local resFrameFR = _G["TPerl_CheckListPlayers"..index.."FR"]
			local resFrameFRR = _G["TPerl_CheckListPlayers"..index.."FRR"]
			local resFrameNR = _G["TPerl_CheckListPlayers"..index.."NR"]
			local resFrameSR = _G["TPerl_CheckListPlayers"..index.."SR"]
			local resFrameAR = _G["TPerl_CheckListPlayers"..index.."AR"]
			local resFrameEquiped = _G["TPerl_CheckListPlayers"..index.."Equiped"]

			if (v.name == SelectedPlayer) then
				frame:LockHighlight()
			else
				frame:UnlockHighlight()
			end

			nameFrame:SetText(v.name)
			local color = TPerl_GetClassColour(v.class)
			nameFrame:SetTextColor(color.r, color.g, color.b)

			if (v.class) then
				local r, l, t, b = TPerl_ClassPos(v.class)
				iconFrame:SetTexCoord(r, l, t, b)
				iconFrame:Show()
			else
				iconFrame:Hide()
			end

			_G["TPerl_CheckListPlayers"..index]:Show()

			local function ShowScanIcon()
				if (TPerl_ActiveScan) then
					local z = TPerl_ActiveScan[v.name]
					if (z) then
						resFrameEquiped:Show()
						if (z.equipped) then
							if (z.changed) then
								resFrameEquiped:SetTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
							else
								resFrameEquiped:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
							end
							resFrameEquiped:SetTexCoord(0, 1, 0, 1)
						elseif (z.offline) then
							resFrameEquiped:SetTexture("Interface\\CharacterFrame\\Disconnect-Icon")
							resFrameEquiped:SetTexCoord(0.2, 0.8, 0.2, 0.8)
						elseif (z.notequipped) then
							resFrameEquiped:SetTexture("Interface\\Addons\\TPerl_RaidAdmin\\Images\\TPerl_Check")
							if (z.changed) then
								resFrameEquiped:SetTexCoord(0.75, 0.875, 0.25, 0.5)
							else
								resFrameEquiped:SetTexCoord(0.625, 0.75, 0.25, 0.5)
							end
						elseif (z.notinzone) then
							resFrameEquiped:SetTexture("Interface\\GossipFrame\\TaxiGossipIcon")
							resFrameEquiped:SetTexCoord(0, 1, 0, 1)
						else
							resFrameEquiped:Hide()
						end
					else
						resFrameEquiped:Hide()
					end
				else
					resFrameEquiped:Hide()
				end
			end

			if (not v.connected or v.noCTRA) then
				if (not v.connected) then
					countFrame:SetText(TPERL_LOC_OFFLINE)
				end
				countFrame:SetTextColor(0.5, 0.5, 0.5)
				countFrame:Show()

				ShowScanIcon()

				resFrameFR:Hide()
				resFrameFRR:Hide()
				resFrameNR:Hide()
				resFrameSR:Hide()
				resFrameAR:Hide()
			else
				if (v.fr) then
					if (v.fr == -1) then
						countFrame:SetText("Blocked")
						countFrame:SetTextColor(0.5, 0.5, 0.5)
						countFrame:Show()

						resFrameFR:Hide()
						resFrameFRR:Hide()
						resFrameNR:Hide()
						resFrameSR:Hide()
						resFrameAR:Hide()
						resFrameEquiped:Hide()
					else
						resFrameFR:SetText(v.fr)
						resFrameFRR:SetText(v.frr)
						resFrameNR:SetText(v.nr)
						resFrameNR:SetTextColor(0, 1, 0)
						resFrameSR:SetText(v.sr)
						resFrameAR:SetText(v.ar)

						resFrameFR:Show()
						resFrameFRR:Show()
						resFrameNR:Show()
						resFrameSR:Show()
						resFrameAR:Show()
						countFrame:Hide()
						resFrameEquiped:Hide()
					end

				elseif (v.dur) then
					resFrameNR:SetText(v.dur)
					countFrame:SetText(v.broken)

					local r, g, b = SmoothColour(v.dur)
					resFrameNR:SetTextColor(r, g, b)

					countFrame:Show()
					resFrameNR:Show()

					if (v.broken > 0) then
						countFrame:SetTextColor(1, 0, 0)
					else
						countFrame:SetTextColor(0, 1, 0)
					end

					resFrameFR:Hide()
					resFrameFRR:Hide()
					resFrameSR:Hide()
					resFrameAR:Hide()
					resFrameEquiped:Hide()
				else
					if (v.count == -1) then
						countFrame:SetText("Blocked")
						countFrame:SetTextColor(0.5, 0.5, 0.5)
					else
						countFrame:SetText(v.count)
						if (v.count == 0) then
							countFrame:SetTextColor(1, 0, 0)
						else
							countFrame:SetTextColor(0, 1, 0)
						end
					end

					countFrame:Show()

					ShowScanIcon()

					resFrameFR:Hide()
					resFrameFRR:Hide()
					resFrameNR:Hide()
					resFrameSR:Hide()
					resFrameAR:Hide()
				end
			end

			index = index + 1
		end
	end

	for i = index,PLAYERLISTSIZE do
		_G["TPerl_CheckListPlayers"..i]:Hide()
	end

	if (resType == "dur") then
		TPerl_CheckListPlayersTotalsNR:SetText(floor(tDur / onlineCount))
		TPerl_CheckListPlayersTotalsNR:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		TPerl_CheckListPlayersTotalsCount:SetText(tBroken)

		local r, g, b = SmoothColour((tDur / onlineCount) / 100)
		TPerl_CheckListPlayersTotalsNR:SetTextColor(r, g, b)

		if (tBroken > 0) then
			TPerl_CheckListPlayersTotalsCount:SetTextColor(1, 0, 0)
		else
			TPerl_CheckListPlayersTotalsCount:SetTextColor(0, 1, 0)
		end

	elseif (resType == "res") then
		TPerl_CheckListPlayersTotalsFR:SetText(floor(tFR / onlineCount))
		TPerl_CheckListPlayersTotalsNR:SetText(floor(tNR / onlineCount))
		TPerl_CheckListPlayersTotalsNR:SetTextColor(0, 1, 0)
		TPerl_CheckListPlayersTotalsFRR:SetText(floor(tFRR / onlineCount))
		TPerl_CheckListPlayersTotalsSR:SetText(floor(tSR / onlineCount))
		TPerl_CheckListPlayersTotalsAR:SetText(floor(tAR / onlineCount))
	else
		TPerl_CheckListPlayersTotalsCount:SetText(tCount)

		if (tCount == 0) then
			TPerl_CheckListPlayersTotalsNR:SetTextColor(1, 0, 0)
		else
			TPerl_CheckListPlayersTotalsNR:SetTextColor(0, 1, 0)
		end
	end

	if (FauxScrollFrame_Update(TPerl_CheckListPlayersScrollBar, #TPerl_PlayerList, PLAYERLISTSIZE, 1)) then
		TPerl_CheckListPlayersScrollBar:Show()
	else
		TPerl_CheckListPlayersScrollBar:Hide()
	end
end

-- TPerl_Check_ShowInfo
function TPerl_Check_ShowInfo()
	if (ActiveScanTotals) then
		if (ActiveScanTotals.missing > 0) then
			TPerl_CheckButtonInfo:SetFormattedText(TPERL_CHECK_SCAN_MISSING, ActiveScanTotals.missing)
		else
			TPerl_CheckButtonInfo:SetText("")
		end
	else
		local results = GetSelectedItem()

		local t
		if (results and results.last and results.last > 0) then
			t = SecondsToTime(GetTime() - results.last)
		else
			t = ""
		end
		if (t ~= "") then
			TPerl_CheckButtonInfo:SetFormattedText(TPERL_CHECK_LASTINFO, t)
		else
			TPerl_CheckButtonInfo:SetText("")
		end
	end
end

-- TPerl_Check_OnEnter
function TPerl_Check_OnEnter(self)
	local f, anc
	if ((self.GetFrameType or self.GetObjectType)(self) == "CheckButton") then
		f = _G[self:GetParent():GetName().."Name"]
		anc = self:GetParent()
	else
		f = _G[self:GetName().."Name"]
		anc = self
	end
	if (f) then
		local link = f:GetText()
		if (link and strsub(link, 1, 1) == "|") then
			-- Have to strip excess information for the SetHyperlink call
			local itemId = strmatch(link, "item:(%d+):")
			if (itemId) then
				local newLink = format("item:%d:0:0:0", itemId)

				GameTooltip:SetOwner(anc, "ANCHOR_LEFT")
				GameTooltip:SetHyperlink(newLink)
				return
			end
		end
	end

	GameTooltip:SetOwner(TPerl_CheckListItems1, "ANCHOR_LEFT")
	GameTooltip:SetText(TPERL_CHECK_DROPITEMTIP1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	GameTooltip:AddLine(TPERL_CHECK_DROPITEMTIP2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:Show()
end

-- TPerl_Check_OnClickStart
function TPerl_Check_OnClickTick(self)
	local id = self:GetParent():GetID() + TPerl_CheckListItemsScrollBar.offset
	if (TPerl_CheckItems[id]) then
		TPerl_CheckItems[id].ticked = self:GetChecked()
	end
	TPerl_Check_ValidateButtons()
end

-- TPerl_Check_DeleteSelectedItems
function TPerl_Check_DeleteSelectedItems()
	local newList = {}

	for k, v in ipairs(TPerl_CheckItems) do
		if (v.fixed or not v.ticked) then
			tinsert(newList, v)
		else
			local linkName = GetVLinkName(v)
			if (linkName) then
				TPerl_ItemResults[linkName] = nil
			end
		end
	end

	TPerl_CheckItems = newList

	TPerl_Check_ItemsChanged()
end

-- TPerl_Check_Query
function TPerl_Check_Query()
	local oldResults = TPerl_ItemResults
	TPerl_ItemResults = {["type"] = "item"}

	TPerl_CheckListItemsScrollBarScrollBar:SetValue(0)

	tinsert(TPerl_MsgQueue, "DURC")
	tinsert(TPerl_MsgQueue, "RSTC")
	tinsert(TPerl_MsgQueue, "REAC")
	TPerl_ResistResults.count = 0
	TPerl_DurResults.count = 0
	TPerl_RegResults.count = 0

	local msg
	for k, v in ipairs(TPerl_CheckItems) do
		if (v.ticked) then
			v.query = true
			v.ticked = nil

			if (not v.fixed) then
				local linkName = GetVLinkName(v)

				if (linkName) then
					TPerl_ItemResults[linkName] = {last = 0}
					oldResults[linkName] = nil
					tinsert(TPerl_MsgQueue, "ITMC "..linkName)
				end
			end
		else
			v.query = nil
		end
	end

	for k, v in pairs(oldResults) do
		if (type(v) == "table") then
			if (not v.fixed) then
				TPerl_ItemResults[k] = v
			end
		end
	end

	TPerl_Check.queryStart = GetTime()
	TPerl_Check.lastMsgsent = nil
	TPerl_Check:SetScript("OnUpdate", TPerl_CheckOnUpdate)

	TPerl_Check_ItemsChanged()		-- Re-sort and re-show list with ticked items at top
	TPerl_Check_ValidateButtons()
end

-- GetActiveScanItem
local function GetActiveScanItem()
	local item = GetSelectedItemLink()
	local itemId
	if (item and strsub(item, 1, 1) == "|") then
		itemId = strmatch(item, "item:(%d+):")
		if (not itemId) then
			return
		end
	else
		return
	end

	local itemName, itemString, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemId)

	if (not itemEquipLoc or not itemType) then
		return
	end

	if (not (itemType == "Armor" or itemType == "Weapon")) then
		return
	end

	local slots = {	INVTYPE_HEAD = 1,
			INVTYPE_NECK = 2,
			INVTYPE_SHOULDER = 3,
			INVTYPE_BODY = 4,
			INVTYPE_CHEST = 5,
			INVTYPE_ROBE = 5,
			INVTYPE_WAIST = 6,
			INVTYPE_LEGS = 7,
			INVTYPE_FEET = 8,
			INVTYPE_WRIST = 9,
			INVTYPE_HAND = 10,
			INVTYPE_FINGER = {11, 12},
			INVTYPE_TRINKET = {13, 14},
			INVTYPE_CLOAK = 15,
			INVTYPE_2HWEAPON = 16,
			INVTYPE_WEAPONMAINHAND = 16,
			INVTYPE_WEAPON = {16, 17},
			INVTYPE_WEAPONOFFHAND = 17,
			INVTYPE_HOLDABLE = 17,
			INVTYPE_SHIELD = 17,
			INVTYPE_RANGED = 18,
			INVTYPE_RELIC = 18,
			INVTYPE_TABARD = 19}

	local slot = slots[itemEquipLoc]
	if (slot) then
		return tonumber(itemId), slot
	end
end

-- GetSelectedPlayer
local function GetSelectedPlayer()
	if (SelectedPlayer) then
		for k,v in pairs(TPerl_PlayerList) do
			if (v.name == SelectedPlayer) then
				return v
			end
		end
	end
end

-- TPerl_Check_ValidateButtons
function TPerl_Check_ValidateButtons()
	local fixedSelected, regSelected
	local anyTicked
	for k,v in ipairs(TPerl_CheckItems) do
		if (v.selected) then
			if (v.fixed) then
				fixedSelected = true
			end
			if (v.link == "reg") then
				regSelected = true
			end
		end
		if (not v.fixed and v.ticked) then
			anyTicked = true
		end
	end

	local results, resType = GetSelectedItem()

	if (anyTicked and not TPerl_Check.queryStart) then
		TPerl_CheckButtonDelete:Enable()
	else
		TPerl_CheckButtonDelete:Disable()
	end

	if (not TPerl_Check.queryStart and UnitIsGroupAssistant("player")) then
		TPerl_CheckButtonQuery:Enable()
	else
		TPerl_CheckButtonQuery:Disable()
	end

	if (((results and results.last) or TPerl_ActiveScan) and IsInRaid()) then
		TPerl_CheckButtonReport:Enable()
	else
		TPerl_CheckButtonReport:Disable()
	end

	if (results and results.last and not (fixedSelected and not regSelected) and IsInRaid()) then
		TPerl_CheckButtonReportWith:Enable()
		TPerl_CheckButtonReportWithout:Enable()
	else
		TPerl_CheckButtonReportWith:Disable()
		TPerl_CheckButtonReportWithout:Disable()
	end

	if (ActiveScanItem) then
		local tex = TPerl_CheckButtonEquiped:GetNormalTexture()
		tex:SetTexCoord(0.75, 0.875, 0.5, 0.75)
		tex = TPerl_CheckButtonEquiped:GetPushedTexture()
		tex:SetTexCoord(0.875, 1, 0.5, 0.75)

				TPerl_CheckButtonEquiped.tooltipText = "TPERL_CHECK_SCANSTOP_DESC"
	else
		local tex = TPerl_CheckButtonEquiped:GetNormalTexture()
		tex:SetTexCoord(0.375, 0.5, 0.5, 0.75)
		tex = TPerl_CheckButtonEquiped:GetPushedTexture()
		tex:SetTexCoord(0.5, 0.625, 0.5, 0.75)

				TPerl_CheckButtonEquiped.tooltipText = "TPERL_CHECK_SCAN_DESC"
	end

	local myPlayer = GetSelectedPlayer()
	if (((results and results.last) or (TPerl_ActiveScan and TPerl_ActiveScan[SelectedPlayer])) and myPlayer and myPlayer.connected) then
		TPerl_CheckButtonPlayer:Enable()
	else
		TPerl_CheckButtonPlayer:Disable()
	end

	TPerl_CheckButtonEquiped:Hide()
	TPerl_CheckButtonEquiped:Show()

	if (results and not fixedSelected and GetActiveScanItem()) then
		TPerl_CheckButtonEquiped:Enable()
	else
		TPerl_CheckButtonEquiped:Disable()
	end
end

-- TPerl_Check_Players_Sort
function TPerl_Check_Players_Sort(sortType)
	if (sortType == "class") then
		sort(TPerl_PlayerList, SortPlayersByClass)
	elseif (sortType == "name") then
		sort(TPerl_PlayerList, SortPlayersByName)
	elseif (sortType == "count") then
		sort(TPerl_PlayerList, SortPlayersByCount)
	elseif (sortType == "dur") then
		sort(TPerl_PlayerList, SortPlayersByDur)
	elseif (strfind("frrsrnrar", sortType)) then
		TPerl_Admin.ResistSort = sortType
		sort(TPerl_PlayerList, SortPlayersByResist)
	end

	TPerl_Check_UpdatePlayerList()
end

-- TPerl_Check_Report
function TPerl_Check_Report(showNames)
	local function ReportOutput(msg)
		if (msg) then
			SendChatMessage("<X-Perl> "..msg, outputChannel, nil, outputChannelIndex)
		end
	end

	local link = GetSelectedItemLink()
	local msg
	if (link) then
		local myPlayer = GetSelectedPlayer()

		if (link == "res") then
			if (TPerl_ResistResults.last) then
				if (showNames == "player") then
					if (SelectedPlayer) then
						if (myPlayer.connected) then
							msg = format(TPERL_CHECK_REPORT_PRESISTS, SelectedPlayer, myPlayer.fr, myPlayer.nr, myPlayer.frr, myPlayer.sr, myPlayer.ar)
						end
					end
				else
					local fr, frr, nr, sr, ar, count = 0, 0, 0, 0, 0, 0

					for k,v in ipairs(TPerl_PlayerList) do
						if (v.connected) then
							count = count + 1

							fr = fr + v.fr
							frr = frr + v.frr
							nr = nr + v.nr
							sr = sr + v.sr
							ar = ar + v.ar
						end
					end

					fr = fr / count
					frr = frr / count
					nr = nr / count
					sr = sr / count
					ar = ar / count

					msg = format(TPERL_CHECK_REPORT_RESISTS, fr, nr, frr, sr, ar)
				end
				ReportOutput(msg)
			end

		elseif (link == "dur") then
			if (TPerl_DurResults.last) then
				if (showNames == "player") then
					if (SelectedPlayer) then
						if (myPlayer.connected) then
							msg = format(TPERL_CHECK_REPORT_PDURABILITY, SelectedPlayer, myPlayer.dur, myPlayer.broken)
						end
					end
				else
					local dur, broken, brokenPeople, count = 0, 0, 0, 0

					for k,v in ipairs(TPerl_PlayerList) do
						if (v.connected) then
							count = count + 1
							dur = dur + v.dur

							if (v.broken > 0) then
								brokenPeople = brokenPeople + 1
								broken = broken + v.broken
							end
						end
					end

					dur = dur / count

					msg = format(TPERL_CHECK_REPORT_DURABILITY, dur, brokenPeople, broken)
				end
				ReportOutput(msg)
			end
		else
			if (showNames == "player") then
				if (SelectedPlayer) then
					if (myPlayer.connected) then
						if (link == "reg") then
							if (TPerl_RegResults.last) then
								msg = format(TPERL_CHECK_REPORT_PITEM, SelectedPlayer, myPlayer.count, TPERL_REAGENTS[myPlayer.class])
							end
						else
							if (TPerl_ActiveScan and TPerl_ActiveScan[SelectedPlayer]) then
								if (TPerl_ActiveScan[SelectedPlayer].equipped) then
									msg = format(TPERL_CHECK_REPORT_PEQUIPED, SelectedPlayer, link)
								elseif (TPerl_ActiveScan[SelectedPlayer].notequipped) then
									msg = format(TPERL_CHECK_REPORT_PNOTEQUIPED, SelectedPlayer, link)
								end
							else
								msg = format(TPERL_CHECK_REPORT_PITEM, SelectedPlayer, myPlayer.count, link)
							end
						end
						ReportOutput(msg)
					end
				end
			else
				local equipable = ""
				if (strsub(link, 1, 1) == "|") then
					local itemId = strmatch(link, "item:(%d+):")
					local itemName, itemString, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemId)
					if (itemEquipLoc and itemType) then
						if (itemType == "Armor" or itemType == "Weapon") then
							equipable = "_EQ"
						end
					end
				end

				local with = {}
				local without = {}
				local offline = {}
				local totalItems = 0

				for k, v in ipairs(TPerl_PlayerList) do
					if (ActiveScanTotals and ActiveScanTotals.missing == 0) then
						local scan = TPerl_ActiveScan[v.name]
						if (scan.equipped) then
							tinsert(with, v)
						elseif (scan.notequipped) then
							tinsert(without, v)
						elseif (scan.offline) then
							tinsert(offline, v)
						end
					else
						if (v.connected) then
							if (v.count > 0) then
								tinsert(with, v)
								totalItems = totalItems + v.count
							elseif (not v.noCTRA) then
								tinsert(without, v)
							end
						else
							tinsert(offline, v)
						end
					end
				end

				if (ActiveScanTotals and ActiveScanTotals.missing == 0 and ActiveScanTotals.wrongZone == 0 and ActiveScanTotals.notequipped == 0) then
					if (ActiveScanTotals.offline == 0) then
						ReportOutput(format(TPERL_CHECK_REPORT_ALLEQUIPED, link))
					else
						ReportOutput(format(TPERL_CHECK_REPORT_ALLEQUIPEDOFF, link, ActiveScanTotals.offline))
					end
				else
					if (showNames) then
						if (link == "reg") then
							local c
							link, c = string.gsub(SPELL_REAGENTS, ": ", "")
							if (not link or c ~= 1) then
								link = "Reagents"
							end
						end

						local showList
						local showTitle
						if (showNames == "with") then
							if (ActiveScanTotals and ActiveScanTotals.missing == 0) then
								showTitle = link..TPERL_CHECK_REPORT_EQUIPED
							else
								showTitle = link.._G["TPERL_CHECK_REPORT_WITH"..equipable]
							end
							if (#with > 0) then
								showList = with
							end
						elseif (showNames == "without") then
							if (ActiveScanTotals and ActiveScanTotals.missing == 0) then
								showTitle = link..TPERL_CHECK_REPORT_NOTEQUIPED
							else
								showTitle = link.._G["TPERL_CHECK_REPORT_WITHOUT"..equipable]
							end
							if (#without > 0) then
								showList = without
							end
						end

						if (showList) then
							msg = showTitle
							local msgLocal = showTitle
							local first = true

							for k,v in ipairs(showList) do
								local name = TPerlColourTable[v.class]..v.name.."|r"

								if (strlen(msg) + strlen(name) > 240) then
									ReportOutput(msg.."...")
									DEFAULT_CHAT_FRAME:AddMessage("<X-Perl> "..msgLocal)
									msg = "  ... "..v.name
									msgLocal = "  ... "..name
								else
									if (first) then
										msg = msg..v.name
										msgLocal = msgLocal..name
										first = nil
									else
										msg = msg..", "..v.name
										msgLocal = msgLocal..", "..name
									end
								end
							end

							if (msg) then
								ReportOutput(msg)
							end
							if (msgLocal) then
								DEFAULT_CHAT_FRAME:AddMessage("<X-Perl> "..msgLocal)
							end
						elseif (showTitle) then
							DEFAULT_CHAT_FRAME:AddMessage("<X-Perl> "..showTitle..NONE)
						end
					else
						msg = link.." "

						local function Out(txt, num)
							if (num > 0) then
								msg = msg..format(txt, num)
							end
						end

						if (ActiveScanTotals) then	-- and ActiveScanTotals.missing == 0) then
							Out(TPERL_CHECK_REPORT_EQUIPEDSHORT, ActiveScanTotals.equipped)
							Out(TPERL_CHECK_REPORT_NOTEQUIPEDSHORT, ActiveScanTotals.notequipped)
							Out(TPERL_CHECK_REPORT_OFFLINE, ActiveScanTotals.offline)
							Out(TPERL_CHECK_REPORT_NOTSCANNED, ActiveScanTotals.missing + ActiveScanTotals.wrongZone)
						else
							Out(TPERL_CHECK_REPORT_WITHSHORT, #with)
							Out(TPERL_CHECK_REPORT_WITHOUTSHORT, #without)
							Out(" : %d "..TPERL_LOC_OFFLINE, #offline)
						end

						if (link ~= "reg") then
							Out(TPERL_CHECK_REPORT_TOTAL, totalItems)
						end

						ReportOutput(msg)
					end
				end
			end
		end
	end
end

-- TPerl_Check_PlayerOnClick
function TPerl_Check_PlayerOnClick(button)
	local index = button:GetID() + TPerl_CheckListPlayersScrollBar.offset

	if (index < 1 or index > #TPerl_PlayerList) then
		return
	end

	if (SelectedPlayer == TPerl_PlayerList[index].name) then
		SelectedPlayer = nil
	else
		SelectedPlayer = TPerl_PlayerList[index].name
	end

	TPerl_Check_UpdatePlayerList()

	SetPortraitTexture(TPerl_CheckButtonPlayerPortrait, TPerl_PlayerList[index].unit)

	TPerl_Check_ValidateButtons()
end

-- TPerl_Check_StopActiveScan
function TPerl_Check_StopActiveScan()
	TPerl_Check:UnregisterEvent("UNIT_INVENTORY_CHANGED")
	TPerl_Check:UnregisterEvent("UNIT_MODEL_CHANGED")
	ActiveScanItem = nil
end

-- TPerl_Check_StartActiveScan
function TPerl_Check_StartActiveScan()
	if (ActiveScanItem) then
		TPerl_Check_StopActiveScan()
	else
		local itemId, itemSlot = GetActiveScanItem()
		if (itemId) then
			TPerl_ActiveScan = {}

			ActiveScanItem = {id = itemId, slot = itemSlot, missing = GetNumGroupMembers()}
			ActiveScanTotals = {missing = 0, equipped = 0, notequipped = 0, offline = 0, wrongZone = 0}

			TPerl_Check:SetScript("OnUpdate", TPerl_CheckOnUpdate)
			TPerl_Check:RegisterEvent("UNIT_INVENTORY_CHANGED")
			TPerl_Check:RegisterEvent("UNIT_MODEL_CHANGED")

			TPerl_CheckListPlayersTitleDur:SetText(TPERL_CHECK_EQUIPED)
			TPerl_CheckListPlayersTitleDur:Show()
		end
	end

	TPerl_Check_ValidateButtons()
end

-- TPerl_Check_ActiveScan
function TPerl_Check_ActiveScan()
	local function CheckSlot(unit, slot)
		local link = GetInventoryItemLink(unit, slot)
		local eq
		local name = UnitName(unit)

		if (link) then
			local itemId = strmatch(link, "item:(%d+):")
			if (itemId) then
				itemId = tonumber(itemId)

				if (itemId == ActiveScanItem.id) then
					if (not TPerl_ActiveScan[name]) then
						TPerl_ActiveScan[name] = {}
					end

					TPerl_ActiveScan[name].notequipped = nil
					TPerl_ActiveScan[name].equipped = 1
					return true
				end
			end
		end

		if (not TPerl_ActiveScan[name]) then
			TPerl_ActiveScan[name] = {}
		end
		TPerl_ActiveScan[name].equipped = nil
		TPerl_ActiveScan[name].notequipped = 1
	end

	local myZone = GetRealZoneText()

	local any
	local update
	ActiveScanTotals = {missing = 0, equipped = 0, notequipped = 0, offline = 0, wrongZone = 0}

	for i = 1, GetNumGroupMembers() do
		local name, _, _, _, _, _, zone = GetRaidRosterInfo(i)
		local unit = "raid"..i
		local new
		local myScan = TPerl_ActiveScan[name]

		if (not myScan or myScan.changed) then
			if (myScan) then
				myScan.changed = nil
			end
			any = true
			if ((IsCataClassic or IsMistsClassic) and CheckInteractDistance(unit, 1)) then		-- Checks to see if in inspect range
				local eq
				if (type(ActiveScanItem.slot) == "table") then
					for k,v in pairs(ActiveScanItem.slot) do
						if (CheckSlot(unit, v)) then
							eq = true
							break
						end
					end
				else
					eq = CheckSlot(unit, ActiveScanItem.slot)
				end

				if (eq) then
					ActiveScanTotals.equipped = ActiveScanTotals.equipped + 1
				else
					ActiveScanTotals.notequipped = ActiveScanTotals.notequipped + 1
				end
				update = true

			elseif (not UnitIsConnected(unit)) then
				if (not TPerl_ActiveScan[name]) then
					TPerl_ActiveScan[name] = {}
				end

				TPerl_ActiveScan[name].offline = 1
				ActiveScanTotals.offline = ActiveScanTotals.offline + 1
				update = true

			elseif (zone ~= myZone) then
				if (not TPerl_ActiveScan[name]) then
					TPerl_ActiveScan[name] = {}
				end

				TPerl_ActiveScan[name].notinzone = 1
				ActiveScanTotals.wrongZone = ActiveScanTotals.wrongZone + 1
				update = true

			else
				ActiveScanTotals.missing = ActiveScanTotals.missing + 1
			end
		else
			ActiveScanTotals.missing	= ActiveScanTotals.missing	+ (myScan.missing	or 0)
			ActiveScanTotals.equipped	= ActiveScanTotals.equipped	+ (myScan.equipped	or 0)
			ActiveScanTotals.notequipped	= ActiveScanTotals.notequipped	+ (myScan.notequipped	or 0)
			ActiveScanTotals.offline	= ActiveScanTotals.offline	+ (myScan.offline	or 0)
			ActiveScanTotals.wrongZone	= ActiveScanTotals.wrongZone	+ (myScan.notinzone	or 0)
		end
	end

	TPerl_Check_ShowInfo()

	if (update) then
		sort(TPerl_PlayerList, SortPlayersByDur)		-- It's actually by equipped, that's sorted out in sort func
		TPerl_Check_UpdatePlayerList()
		TPerl_Check_ValidateButtons()
	end
end

-- TPerl_GetChannelList
if (not TPerl_GetChannelList) then
local function GetChatColour(name)
	local info = ChatTypeInfo[name]
	local clr = {r = 0.5, g = 0.5, b = 0.5}
	if (info) then
		clr.r = (info.r or 0.5)
		clr.g = (info.g or 0.5)
		clr.b = (info.b or 0.5)
	end
	return clr
end
function TPerl_GetChannelList()
	local cList = {}
	local l = {"RAID", "OFFICER", "GUILD", "PARTY", "SAY"}
	for k,v in pairs(l) do
		tinsert(cList, {display = _G["CHAT_MSG_"..v], channel = v, colour = GetChatColour(v)})
	end

	for i = 1, 10 do
		local c, name = GetChannelName(i)
		if (name and c ~= 0) then
			tinsert(cList, {display = name, channel = "CHANNEL", index = c, colour = GetChatColour("CHANNEL"..c)})
		end
	end

	return cList
end
end

-- TPerl_Check_Channels_OnLoad
function TPerl_Check_Channels_OnLoad(self)
	if (not outputChannelSelection) then
		outputChannelSelection = 1
	end

	local dropdown = MSA_DropDownMenu_Create(self:GetName().."_DropDown", self)
	dropdown:SetAllPoints(self)
	MSA_DropDownMenu_Initialize(dropdown, TPerl_Check_Channels_Initialize)
	MSA_DropDownMenu_SetWidth(dropdown, 100)
	MSA_DropDownMenu_SetSelectedID(dropdown, outputChannelSelection)
	_G[dropdown:GetName().."Text"]:SetTextColor(unpack(outputChannelColour))
end

-- TPerl_Channel_OnClick
local function TPerl_Channel_OnClick(self)
	local v = self.value
	outputChannel = v.channel
	outputChannelIndex = v.index
	outputChannelSelection = self:GetID()
	MSA_DropDownMenu_SetSelectedID(TPerl_CheckButtonChannel, outputChannelSelection)

	TPerl_CheckButtonChannelText:SetTextColor(v.red, v.green, v.blue)
end

-- TPerl_Check_Channels_Initialize
function TPerl_Check_Channels_Initialize()
	channelList = TPerl_GetChannelList()

	for i,entry in pairs(channelList) do
		local r, g, b = entry.colour.r, entry.colour.g, entry.colour.b
		if (entry.channel == outputChannel) then
			if (outputChannel ~= "CHANNEL" or entry.index == outputChannelIndex) then
				outputChannelSelection = i
				outputChannelColour = {r, g, b}
			end
		end

		local info = MSA_DropDownMenu_CreateInfo()
		info.text = entry.display
		info.func = TPerl_Channel_OnClick
		info.value = {channel = entry.channel, index = entry.index, red = r, green = g, blue = b}
		info.colorCode = format("|cFF%02X%02X%02X", r * 255, g * 255, b * 255)
		MSA_DropDownMenu_AddButton(info)
	end
end
