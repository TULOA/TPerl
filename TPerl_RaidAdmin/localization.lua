--[[
	Localisation file
]]

TPERL_ADMIN_TITLE	= TPerl_ShortProductName.." Raid Admin"

TPERL_MSG_PREFIX	= "|c00C05050TPerl|r "

-- Raid Admin
TPERL_BUTTON_ADMIN_PIN		= "Pin Window"
TPERL_BUTTON_ADMIN_LOCKOPEN	= "Lock Window Open"
TPERL_BUTTON_ADMIN_SAVE1	= "Save Roster"
TPERL_BUTTON_ADMIN_SAVE2	= "Saves the current roster layout with the name specified. If no name given, the current time will be used as the name"
TPERL_BUTTON_ADMIN_LOAD1	= "Load Roster"
TPERL_BUTTON_ADMIN_LOAD2	= "Load the selected roster. Any raid members of the saved roster who are no longer in the raid will be replaced by members of the same class who are not saved in the roster"
TPERL_BUTTON_ADMIN_DELETE1	= "Delete Roster"
TPERL_BUTTON_ADMIN_DELETE2	= "Delete the selected roster"
TPERL_BUTTON_ADMIN_STOPLOAD1	= "Stop Load"
TPERL_BUTTON_ADMIN_STOPLOAD2	= "Aborts the roster load procedure"

TPERL_LOAD			= "Load"

TPERL_SAVED_ROSTER		= "Saved roster called '%s'"
TPERL_ADMIN_DIFFERENCES		= "%d differences to current roster"
TPERL_NO_ROSTER_NAME_GIVEN	= "No roster name given"
TPERL_NO_ROSTER_CALLED		= "No roster saved called '%s'"

-- Item Checker
TPERL_CHECK_TITLE		= TPerl_ShortProductName.." Item Check"

TPERL_CHECK_NAME		= "Name"

TPERL_CHECK_DROPITEMTIP1	= "Drop Items"
TPERL_CHECK_DROPITEMTIP2	= "Items can be dropped into this frame and added to the list of queryable items.\rYou may also use the /raitem command as normal and items will also be added here and used in the future."
TPERL_CHECK_QUERY_DESC1		= "Query"
TPERL_CHECK_QUERY_DESC2		= "Performs item check (/raitem) on all ticked items\rQuery always gets current durablity, resistance and reagents information"
TPERL_CHECK_LAST_DESC1		= "Last"
TPERL_CHECK_LAST_DESC2		= "Re-tick the last search items"
TPERL_CHECK_ALL_DESC1		= ALL
TPERL_CHECK_ALL_DESC2		= "Tick all the items"
TPERL_CHECK_NONE_DESC1		= NONE
TPERL_CHECK_NONE_DESC2		= "Un-tick all the items"
TPERL_CHECK_DELETE_DESC1	= DELETE
TPERL_CHECK_DELETE_DESC2	= "Permenantly remove all the ticked items from the list"
TPERL_CHECK_REPORT_DESC1	= "Report"
TPERL_CHECK_REPORT_DESC2	= "Show report of the selected results to the raid chat"
TPERL_CHECK_REPORT_WITH_DESC1	= "With"
TPERL_CHECK_REPORT_WITH_DESC2	= "Report people with the item (or don't have the item equipped) to the raid chat. If an equipment scan has been performed, these results will be shown instead."
TPERL_CHECK_REPORT_WITHOUT_DESC1= "Without"
TPERL_CHECK_REPORT_WITHOUT_DESC2= "Report people without the item (or have the item equipped) to the raid chat"
TPERL_CHECK_SCAN_DESC1		= "Scan"
TPERL_CHECK_SCAN_DESC2		= "Will check anyone in raid within inspect range, to see whether they have the selected item equipped and indicate this on the player list. Move closer (10 yards) to people in the raid until all are checked."
TPERL_CHECK_SCANSTOP_DESC1	= "Stop Scan"
TPERL_CHECK_SCANSTOP_DESC2	= "Stop scanning player's equipment for the selected item"
TPERL_CHECK_REPORTPLAYER_DESC1	= "Report Player"
TPERL_CHECK_REPORTPLAYER_DESC2	= "Report selected player's details for this item or status to the raid chat"

TPERL_CHECK_BROKEN		= "Broken"
TPERL_CHECK_REPORT_DURABILITY	= "Average Raid Durability: %d%% and %d people with a total of %d broken items"
TPERL_CHECK_REPORT_PDURABILITY	= "%s's Durability: %d%% with %d broken items"
TPERL_CHECK_REPORT_RESISTS	= "Average Raid resists: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_PRESISTS	= "%s's Resists: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
TPERL_CHECK_REPORT_WITH		= " - with: "
TPERL_CHECK_REPORT_WITHOUT	= " - without: "
TPERL_CHECK_REPORT_WITH_EQ	= " - with (or not equipped): "
TPERL_CHECK_REPORT_WITHOUT_EQ	= " - without (or equipped): "
TPERL_CHECK_REPORT_EQUIPED	= " : equipped: "
TPERL_CHECK_REPORT_NOTEQUIPED	= " : NOT equipped: "
TPERL_CHECK_REPORT_ALLEQUIPED	= "Everyone has %s equipped"
TPERL_CHECK_REPORT_ALLEQUIPEDOFF= "Everyone has %s equipped, but %d member(s) offline"
TPERL_CHECK_REPORT_PITEM	= "%s has %d %s in inventory"
TPERL_CHECK_REPORT_PEQUIPED	= "%s has %s equipped"
TPERL_CHECK_REPORT_PNOTEQUIPED	= "%s DOES NOT have %s equipped"
TPERL_CHECK_REPORT_DROPDOWN	= "Output Channel"
TPERL_CHECK_REPORT_DROPDOWN_DESC= "Select output channel for Item Checker results"

TPERL_CHECK_REPORT_WITHSHORT	= " : %d with"
TPERL_CHECK_REPORT_WITHOUTSHORT	= " : %d without"
TPERL_CHECK_REPORT_EQUIPEDSHORT	= " : %d equipped"
TPERL_CHECK_REPORT_NOTEQUIPEDSHORT	= " : %d NOT equipped"
TPERL_CHECK_REPORT_OFFLINE	= " : %d offline"
TPERL_CHECK_REPORT_TOTAL	= " : %d Total Items"
TPERL_CHECK_REPORT_NOTSCANNED	= " : %d un-checked"

TPERL_CHECK_LASTINFO		= "Last data received %sago"

TPERL_CHECK_AVERAGE		= "Average"
TPERL_CHECK_TOTALS		= "Total"
TPERL_CHECK_EQUIPED		= "Equipped"

TPERL_CHECK_SCAN_MISSING	= "Scanning inspectable players for item. (%d un-scanned)"

TPERL_REAGENTS			= {PRIEST = "Sacred Candle", MAGE = "Arcane Powder", DRUID = "Wild Thornroot",
					SHAMAN = "Ankh", WARLOCK = "Soul Shard", PALADIN = "Symbol of Divinity",
					ROGUE = "Flash Powder"}

TPERL_CHECK_REAGENTS		= "Reagents"

-- Roster Text
TPERL_ROSTERTEXT_TITLE		= TPerl_ShortProductName.." Roster Text"
TPERL_ROSTERTEXT_GROUP		= "Group %d"
TPERL_ROSTERTEXT_GROUP_DESC	= "Use names from group %d"
TPERL_ROSTERTEXT_SAMEZONE	= "Same Zone Only"
TPERL_ROSTERTEXT_SAMEZONE_DESC	= "Only include names of players in the same zone as yourself"
TPERL_ROSTERTEXT_HELP		= "Press Ctrl-C to copy the text to the clipboard"
TPERL_ROSTERTEXT_TOTAL		= "Total: %d"
TPERL_ROSTERTEXT_SETN		= "%d Man"
TPERL_ROSTERTEXT_SETN_DESC	= "Auto select the groups for a %d man raid"
TPERL_ROSTERTEXT_TOGGLE		= "Toggle"
TPERL_ROSTERTEXT_TOGGLE_DESC	= "Toggle the selected groups"
TPERL_ROSTERTEXT_SORT		= "Sort"
TPERL_ROSTERTEXT_SORT_DESC	= "Sort by name instead of by group+name"
