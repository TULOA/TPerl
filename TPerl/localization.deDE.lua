-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if (GetLocale() == "deDE") then
	TPerl_LongDescription	= "UnitFrame Alternative f\195\188r ein neues Aussehen von Spieler, Begleiter, Gruppe, Ziel, Ziel des Ziels, Fokus und Schlachtzug"

	TPERL_MINIMAP_HELP1		= "|c00FFFFFFLinks-Klick|r, f\195\188r die Optionen (und zum |c0000FF00Entsperren der Fenster|r)"
	TPERL_MINIMAP_HELP2		= "|c00FFFFFFRechts-Klick|r, um das Symbol zu verschieben"
	TPERL_MINIMAP_HELP3		= "\rTats\195\164chliche Schlachtzugsmitglieder: |c00FFFF80%d|r\rTats\195\164chliche Gruppenmitglieder: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4		= "\rDu bist der tats\195\164chliche Gruppen- oder Schlachtzugsleiter"
	TPERL_MINIMAP_HELP5		= "|c00FFFFFFAlt|r, f\195\188r die X-Perl Speicherausnutzung"
	TPERL_MINIMAP_HELP6		= "|c00FFFFFF+Umschalt|r, f\195\188r die X-Perl Speicherausnutzung seit dem Start"

	TPERL_MINIMENU_OPTIONS			= MAIN_MENU
	TPERL_MINIMENU_ASSIST			= "Zeige Assistiert-Frame"
	TPERL_MINIMENU_CASTMON			= "Zeige Casting-Monitor"
	TPERL_MINIMENU_RAIDAD			= "Zeige Schlachtzugs-Admin"
	TPERL_MINIMENU_ITEMCHK			= "Zeige Gegenstands-Checker"
	TPERL_MINIMENU_RAIDBUFF 		= "Schlachtzugsbuffs"
	TPERL_MINIMENU_ROSTERTEXT 		= "Listen-Text"
	TPERL_MINIMENU_RAIDSORT 		= "Sortierung des Schlachtzugs"
	TPERL_MINIMENU_RAIDSORT_GROUP 	= "Nach Gruppe sortieren"
	TPERL_MINIMENU_RAIDSORT_CLASS 	= "Nach Klasse sortieren"

	TPERL_TYPE_NOT_SPECIFIED		= "Nicht spezifiziert"
	TPERL_TYPE_PET					= PET			-- "Begleiter"
	TPERL_TYPE_BOSS 				= BOSS
	TPERL_TYPE_RAREPLUS 			= "Rar+"
	TPERL_TYPE_ELITE				= ELITE
	TPERL_TYPE_RARE 				= "Rar"

-- Zones
	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN 	= "H\195\182hle des Schlangenschreins"
	TPERL_LOC_ZONE_BLACK_TEMPLE 			= "Der Schwarze Tempel"
	TPERL_LOC_ZONE_HYJAL_SUMMIT 			= "Hyjalgipfel"
	TPERL_LOC_ZONE_KARAZHAN 				= "Karazhan"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU 			= "Sonnenbrunnenplateau"
	TPERL_LOC_ZONE_NAXXRAMAS 				= "Naxxramas"
	TPERL_LOC_ZONE_OBSIDIAN_SANCTUM 		= "Das Obsidiansanktum"
	TPERL_LOC_ZONE_EYE_OF_ETERNITY 			= "Das Auge der Ewigkeit"
	TPERL_LOC_ZONE_ULDUAR 					= "Ulduar"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER 	= "Pr\195\188fung des Kreuzfahrers"
	TPERL_LOC_ZONE_ICECROWN_CITADEL 		= "Eiskronenzitadelle"
	TPERL_LOC_ZONE_RUBY_SANCTUM 			= "Das Rubinsanktum"

-- Status
	TPERL_LOC_DEAD			= DEAD			-- "Tot"
	TPERL_LOC_GHOST 		= "Geist"
	TPERL_LOC_FEIGNDEATH	= "Totstellen"
	TPERL_LOC_OFFLINE		= PLAYER_OFFLINE	-- "Offline"
	TPERL_LOC_RESURRECTED	= "Wiederbelebung"
	TPERL_LOC_SS_AVAILABLE	= "SS verf\195\188gbar"
	TPERL_LOC_UPDATING		= "Aktualisierung"
	TPERL_LOC_ACCEPTEDRES	= "Akzeptiert"		-- Wiederbelebung akzeptiert
	TPERL_RAID_GROUP		= "Gruppe %d"
	TPERL_RAID_GROUPSHORT	= "G%d"

	TPERL_LOC_NONEWATCHED	= "nicht beobachtet"

	TPERL_LOC_STATUSTIP 	= "Status Hervorhebungen: " 	-- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "Heilung \195\188ber Zeit",
		AGGRO = "Aggro",
		MISSING = "Dein Klassenbuff fehlt",
		HEAL = "Wird geheilt",
		SHIELD = SHIELDSLOT
	}

	TPERL_OK							= "OK"
	TPERL_CANCEL						= "Abbrechen"

	TPERL_LOC_LARGENUMTAG		= "K"
	TPERL_LOC_HUGENUMTAG		= "M"
	TPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_TPERL 				= TPerl_ProductName
	BINDING_NAME_TPERL_TOGGLERAID 			= "Schalter f\195\188r die Schlachtzugsfenster"
	BINDING_NAME_TPERL_TOGGLERAIDSORT 		= "Schalter f\195\188r Schlachtzug sortieren nach Klasse/Gruppe"
	BINDING_NAME_TPERL_TOGGLERAIDPETS 		= "Schalter f\195\188r Schlachtzugsbegleiter"
	BINDING_NAME_TPERL_TOGGLEOPTIONS 		= "Schalter f\195\188r das Optionenfenster"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE 		= "Schalter f\195\188r Buffs/Debuffs/Keine"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE 	= "Schalter f\195\188r Zauberbar/Heilbar"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR 	= "Teamspeak Monitor"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER 	= "Schalter f\195\188r Reichweiten-Finder"

	TPERL_KEY_NOTICE_RAID_BUFFANY 		= "Alle Buffs/Debuffs anzeigen"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST 	= "Nur zauberbare/heilbare Buffs oder Debuffs anzeigen"
	TPERL_KEY_NOTICE_RAID_BUFFS 		= "Schlachtzug-Buffs anzeigen"
	TPERL_KEY_NOTICE_RAID_DEBUFFS 		= "Schlachtzug-Debuffs anzeigen"
	TPERL_KEY_NOTICE_RAID_NOBUFFS 		= "Keine Schlachtzug-Buffs anzeigen"

	TPERL_DRAGHINT1						= "|c00FFFFFFKlicken|r, zum Skalieren des Fensters"
	TPERL_DRAGHINT2						= "|c00FFFFFFUmschalt+Klick|r, zum Anpassen der Fenstergr\195\182\195\159e"

	-- Usage
	TPerlUsageNameList					= {TPerl = "Core", TPerl_Player = "Player", TPerl_PlayerPet = "Pet", TPerl_Target = "Target", TPerl_TargetTarget = "Target's Target", TPerl_Party = "Party", TPerl_PartyPet = "Party Pets", TPerl_RaidFrames = "Raid Frames", TPerl_RaidHelper = "Raid Helper", TPerl_RaidAdmin = "Raid Admin", TPerl_TeamSpeak = "TS Monitor", TPerl_RaidMonitor = "Raid Monitor", TPerl_RaidPets = "Raid Pets", TPerl_ArcaneBar = "Arcane Bar", TPerl_PlayerBuffs = "Player Buffs", TPerl_GrimReaper = "Grim Reaper"}
	TPERL_USAGE_MEMMAX					= "UI Max. Speicher: %d"
	TPERL_USAGE_MODULES 				= "Module: "
	TPERL_USAGE_NEWVERSION				= "*Neuere Version"
	TPERL_USAGE_AVAILABLE				= "%s |c00FFFFFF%s|r ist zum Download verf\195\188gbar"

	TPERL_CMD_MENU						= "menu"
	TPERL_CMD_OPTIONS					= "options"
	TPERL_CMD_LOCK						= "lock"
	TPERL_CMD_UNLOCK					= "unlock"
	TPERL_CMD_CONFIG					= "config"
	TPERL_CMD_LIST						= "list"
	TPERL_CMD_DELETE					= "delete"
	TPERL_CMD_HELP						= "|c00FFFF80Verwendung: |c00FFFFFF/xperl menu | lock | unlock | config list | config delete <realm> <name>"
	TPERL_CANNOT_DELETE_CURRENT 		= "Die aktuelle Konfiguration kann nicht gel\195\182scht werden"
	TPERL_CONFIG_DELETED				= "Konfiguration gel\195\182scht f\195\188r %s/%s"
	TPERL_CANNOT_FIND_DELETE_TARGET		= "Konfiguration kann nicht zum L\195\182schen gefunden werden (%s/%s)"
	TPERL_CANNOT_DELETE_BADARGS 		= "Bitte einen Realmnamen und Spielernamen angeben"
	TPERL_CONFIG_LIST					= "Konfigurationsliste:"
	TPERL_CONFIG_CURRENT				= " (Aktuell)"

	TPERL_RAID_TOOLTIP_WITHBUFF      	= "Mit Buff: (%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF   	= "Ohne Buff: (%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING		= "%s's %s schwindet in %s"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED			= "Neue Version erkannt:"
end
