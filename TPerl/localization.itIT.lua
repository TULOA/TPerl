-- X-Perl UnitFrames
-- Author: TULOA
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if (GetLocale() == "itIT") then
	TPerl_ProductName		= "|cFFD00000X-Perl|r UnitFrames"
	TPerl_ShortProductName	= "|cFFD00000X-Perl|r"
	TPerl_Author			= "|cFFFF8080Zek|r"
	TPerl_Description		= TPerl_ProductName.." di "..TPerl_Author

	TPerl_Version			= TPerl_Description.." - "..TPerl_VersionNumber
	TPerl_LongDescription	= "Sostituzione dell'UnitFrame del Personaggio, Famiglio, Gruppo, Bersaglio, Bersaglio del Bersaglio, Focus e Incursioni"
	TPerl_ModMenuIcon		= "Interface\\Icons\\INV_Misc_Gem_Pearl_02"

	TPERL_MINIMAP_HELP1		= "|c00FFFFFFClick Sinistro|r per le opzioni (e per |c0000FF00sbloccare le finestre|r)"
	TPERL_MINIMAP_HELP2		= "|c00FFFFFFClick Destro|r per spostare questa icona"
	TPERL_MINIMAP_HELP3		= "\rMembri reali dell'incursione: |c00FFFF80%d|r\rMembri reali del gruppo: |c00FFFF80%d|r"
	TPERL_MINIMAP_HELP4		= "\rSei il capogruppo/capoincursione reale"
	TPERL_MINIMAP_HELP5		= "|c00FFFFFFAlt|r per info sull'uso di memoria di X-Perl"
	TPERL_MINIMAP_HELP6		= "|c00FFFFFF+Maiusc|r per l'uso di memoria di X-Perl dall'avvio"

	TPERL_MINIMENU_OPTIONS	= "Opzioni"
	TPERL_MINIMENU_ASSIST	= "Visualizza finestra assist"
	TPERL_MINIMENU_CASTMON	= "Visualizza monitor dei lanci delle magie"
	TPERL_MINIMENU_RAIDAD	= "Visualizza Amministratore Incursione"
	TPERL_MINIMENU_ITEMCHK	= "Visualizza Controllo Oggetti"
	TPERL_MINIMENU_RAIDBUFF = "Buff Incursione"
	TPERL_MINIMENU_ROSTERTEXT="Roster Text"
	TPERL_MINIMENU_RAIDSORT = "Riorganizzazione Incursione"
	TPERL_MINIMENU_RAIDSORT_GROUP = "Organizza per gruppo"
	TPERL_MINIMENU_RAIDSORT_CLASS = "Organizza per classe"

	TPERL_TYPE_NOT_SPECIFIED = "Non specificato"
	TPERL_TYPE_PET		= PET			-- "Pet"
	TPERL_TYPE_BOSS		= "Boss"
	TPERL_TYPE_RAREPLUS = "Raro+"
	TPERL_TYPE_ELITE	= "Elite"
	TPERL_TYPE_RARE		= "Raro"

	-- Zones
	TPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "Serpentshrine Cavern"
	TPERL_LOC_ZONE_BLACK_TEMPLE = "Tempio Nero"
	TPERL_LOC_ZONE_HYJAL_SUMMIT = "Hyjal Summit"
	TPERL_LOC_ZONE_KARAZHAN = "Karazhan"
	TPERL_LOC_ZONE_SUNWELL_PLATEAU = "Sunwell Plateau"
	TPERL_LOC_ZONE_NAXXRAMAS = "Naxxramas"
	TPERL_LOC_ZONE_OBSIDIAN_SANCTUM = "The Obsidian Sanctum"
	TPERL_LOC_ZONE_EYE_OF_ETERNITY = "The Eye of Eternity"
	TPERL_LOC_ZONE_ULDUAR = "Ulduar"
	TPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "Trial of the Crusader"
	TPERL_LOC_ZONE_ICECROWN_CITADEL = "Corona di Ghiaccio"
	TPERL_LOC_ZONE_RUBY_SANCTUM = "The Ruby Sanctum"
	--Any zones 4.x and higher can all be localized from EJ, in 5.0, even these above zones are in EJ which means the rest can go bye bye too

	-- Status
	TPERL_LOC_DEAD		= DEAD			-- "Dead"
	TPERL_LOC_GHOST		= "Spirito"
	TPERL_LOC_FEIGNDEATH	= "Finta morte"
	TPERL_LOC_OFFLINE	= PLAYER_OFFLINE	-- "Offline"
	TPERL_LOC_RESURRECTED	= "Riportato in vita"
	TPERL_LOC_SS_AVAILABLE	= "SS Disponibile"
	TPERL_LOC_UPDATING	= "In aggiornamento"
	TPERL_LOC_ACCEPTEDRES	= "Accettata"		-- Res accepted
	TPERL_RAID_GROUP	= "Gruppo %d"
	TPERL_RAID_GROUPSHORT	= "G%d"

	TPERL_LOC_NONEWATCHED	= "none watched"

	TPERL_LOC_STATUSTIP = "Evidenziaziazione stato: " 	-- Tooltip explanation of status highlight on unit
	TPERL_LOC_STATUSTIPLIST = {
		HOT = "Cure nel Tempo (HOT)",
		AGGRO = "Aggressione",
		MISSING = "Missing your class' buff",
		HEAL = "Sta per essere curato",
		SHIELD = "Shielded"
	}

	TPERL_OK		= "OK"
	TPERL_CANCEL		= "Annulla"

	TPERL_LOC_LARGENUMTAG		= "K"
	TPERL_LOC_HUGENUMTAG		= "M"
	TPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_TPERL = TPerl_ProductName
	BINDING_NAME_TPERL_TOGGLERAID = "Abilita/Disattiva Raid Windows"
	BINDING_NAME_TPERL_TOGGLERAIDSORT = "Abilita/Disattiva riorganizzazione per classe/gruppo"
	BINDING_NAME_TPERL_TOGGLERAIDPETS = "Abilita/Disattiva Raid Pets"
	BINDING_NAME_TPERL_TOGGLEOPTIONS = "Abilita/Disattiva finestra opzioni"
	BINDING_NAME_TPERL_TOGGLEBUFFTYPE = "Abilita/Disattiva Buffs/Debuffs/none"
	BINDING_NAME_TPERL_TOGGLEBUFFCASTABLE = "Abilita/Disattiva Castable/Curable"
	BINDING_NAME_TPERL_TEAMSPEAKMONITOR = "Teamspeak Monitor"
	BINDING_NAME_TPERL_TOGGLERANGEFINDER = "Abilita/Disattiva Range Finder"

	TPERL_KEY_NOTICE_RAID_BUFFANY = "Visualizza tutti i benefici/penalità"
	TPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Visualizza solo benefici lanciabili/curabili o penalità"
	TPERL_KEY_NOTICE_RAID_BUFFS = "Benefici dell'incursione mostrati"
	TPERL_KEY_NOTICE_RAID_DEBUFFS = "Penalità dell'incursione mostrati"
	TPERL_KEY_NOTICE_RAID_NOBUFFS = "Nessun beneficio dell'incursione mostrato"

	TPERL_DRAGHINT1		= "|c00FFFFFFFai Click|r per riscalare la finestra"
	TPERL_DRAGHINT2		= "|c00FFFFFFFai Maiusc+Click|r per ridimensionare la finestra"

	-- Usage
	TPerlUsageNameList	= {TPerl = "Core", TPerl_Player = "Giocatore", TPerl_PlayerPet = "Famiglio", TPerl_Target = "Bersaglio", TPerl_TargetTarget = "Bersaglio del bersaglio", TPerl_Party = "Gruppo", TPerl_PartyPet = "Famigli del gruppo", TPerl_RaidFrames = "Finestre del raid", TPerl_RaidHelper = "Aiutante dell'incursione", TPerl_RaidAdmin = "Amministrazione incursione", TPerl_TeamSpeak = "TS Monitor", TPerl_RaidMonitor = "Monitor dell'incursione", TPerl_RaidPets = "Famigli dell'incursione", TPerl_ArcaneBar = "Barra arcana", TPerl_PlayerBuffs = "Benefici del giocatore", TPerl_GrimReaper = "Grim Reaper"}
	TPERL_USAGE_MEMMAX	= "IU Mem Max: %d"
	TPERL_USAGE_MODULES	= "Moduli: "
	TPERL_USAGE_NEWVERSION	= "*Una nuova versione"
	TPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r è disponibile per il download"

	TPERL_CMD_MENU		= "menu"
	TPERL_CMD_OPTIONS	= "opzioni"
	TPERL_CMD_LOCK		= "blocca"
	TPERL_CMD_UNLOCK	= "sblocca"
	TPERL_CMD_CONFIG	= "configurazioni"
	TPERL_CMD_LIST		= "elenca"
	TPERL_CMD_DELETE	= "elimina"
	TPERL_CMD_HELP		= "|c00FFFF80Utilizzo: |c00FFFFFF/xperl menu | blocca | sblocca | configurazioni elenca | configurazioni elimina <reame> <nome>"
	TPERL_CANNOT_DELETE_CURRENT = "Impossibile cancellare la tua configurazione corrente"
	TPERL_CONFIG_DELETED		= "Configurazione di %s/%s cancellata"
	TPERL_CANNOT_FIND_DELETE_TARGET = "Impossibile trovare configurazione da cancellare (%s/%s)"
	TPERL_CANNOT_DELETE_BADARGS = "Prego scrivi il del reame e quello del personaggio"
	TPERL_CONFIG_LIST		= "Elenco configurazioni:"
	TPERL_CONFIG_CURRENT		= " (In uso)"

	TPERL_RAID_TOOLTIP_WITHBUFF	= "Con buff: (%s)"
	TPERL_RAID_TOOLTIP_WITHOUTBUFF	= "Senza buff: (%s)"
	TPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s ha usato %s che finisce in %s"	-- Name, buff name, time to expire

	TPERL_NEW_VERSION_DETECTED = "Nuova versione rilevata:"
end
